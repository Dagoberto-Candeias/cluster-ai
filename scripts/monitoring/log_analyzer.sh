#!/bin/bash
# Analisador de Logs do Cluster AI

set -euo pipefail

# ==================== CONFIGURAÇÃO ====================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOGS_DIR="${PROJECT_ROOT}/logs"
ANALYSIS_DIR="${PROJECT_ROOT}/analysis"
REPORTS_DIR="${PROJECT_ROOT}/reports"

# Arquivos de log
MONITOR_LOG="${LOGS_DIR}/monitor.log"
ALERTS_LOG="${PROJECT_ROOT}/alerts/alerts.log"
INSTALL_LOG="${LOGS_DIR}/install.log"
OLLAMA_LOG="${LOGS_DIR}/ollama.log"
DASK_LOG="${LOGS_DIR}/dask.log"

# Carregar funções comuns
if [ ! -f "${PROJECT_ROOT}/scripts/utils/common.sh" ]; then
    echo "ERRO: Script de funções comuns não encontrado."
    exit 1
fi

# Definir variável global de log para common.sh
export CLUSTER_AI_LOG_FILE="${PROJECT_ROOT}/logs/cluster_ai.log"

source "${PROJECT_ROOT}/scripts/utils/common.sh"

# ==================== FUNÇÕES DE ANÁLISE ====================

# Analisa logs de alertas
analyze_alerts() {
    local period="${1:-24h}"
    local report_file="${REPORTS_DIR}/alerts_analysis_$(date +%Y%m%d_%H%M%S).txt"

    section "Análise de Alertas - Últimas $period"

    mkdir -p "$REPORTS_DIR"

    # Estatísticas gerais
    local total_alerts=0
    local critical_alerts=0
    local warning_alerts=0
    local info_alerts=0

    if [ -f "$ALERTS_LOG" ]; then
        # Filtrar por período
        case $period in
            1h)
                local log_data=$(tail -n 1000 "$ALERTS_LOG" | grep "$(date -d '1 hour ago' '+%Y-%m-%d %H')" || true)
                ;;
            24h|1d)
                local log_data=$(tail -n 5000 "$ALERTS_LOG" | grep "$(date -d '1 day ago' '+%Y-%m-%d')" || true)
                ;;
            7d)
                local log_data=$(tail -n 20000 "$ALERTS_LOG" | grep "$(date -d '7 days ago' '+%Y-%m-%d')" || true)
                ;;
            *)
                local log_data=$(cat "$ALERTS_LOG")
                ;;
        esac

        if [ -n "$log_data" ]; then
            total_alerts=$(echo "$log_data" | wc -l)
            critical_alerts=$(echo "$log_data" | grep -c "CRITICAL" || true)
            warning_alerts=$(echo "$log_data" | grep -c "WARNING" || true)
            info_alerts=$((total_alerts - critical_alerts - warning_alerts))
        fi
    fi

    # Gerar relatório
    cat > "$report_file" << EOF
ANÁLISE DE ALERTAS - CLUSTER AI
=====================================

Período: Últimas $period
Data: $(date)
Total de Alertas: $total_alerts

DISTRIBUIÇÃO POR SEVERIDADE:
- Críticos: $critical_alerts
- Avisos: $warning_alerts
- Informativos: $info_alerts

TOP 10 COMPONENTES COM MAIS ALERTAS:
EOF

    if [ -f "$ALERTS_LOG" ] && [ "$total_alerts" -gt 0 ]; then
        echo "$log_data" | awk -F'[][]' '{print $4}' | sort | uniq -c | sort -nr | head -10 >> "$report_file"
    fi

    echo "" >> "$report_file"
    echo "ALERTAS MAIS RECENTES:" >> "$report_file"
    echo "======================" >> "$report_file"

    if [ -f "$ALERTS_LOG" ] && [ "$total_alerts" -gt 0 ]; then
        tail -20 "$ALERTS_LOG" >> "$report_file"
    else
        echo "Nenhum alerta encontrado no período." >> "$report_file"
    fi

    success "Relatório de alertas salvo em: $report_file"

    # Mostrar resumo na tela
    echo ""
    echo "📊 RESUMO DOS ALERTAS:"
    echo "  Total: $total_alerts"
    echo "  Críticos: $critical_alerts"
    echo "  Avisos: $warning_alerts"
    echo "  Informativos: $info_alerts"
}

# Analisa performance do sistema
analyze_performance() {
    local period="${1:-1h}"
    local report_file="${REPORTS_DIR}/performance_analysis_$(date +%Y%m%d_%H%M%S).txt"

    section "Análise de Performance - Últimas $period"

    mkdir -p "$REPORTS_DIR"

    # Coletar dados de performance atuais
    local cpu_avg=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    local mem_info=$(free | grep Mem)
    local mem_total=$(echo $mem_info | awk '{print $2}')
    local mem_used=$(echo $mem_info | awk '{print $3}')
    local mem_usage=$((mem_used * 100 / mem_total))
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

    # Análise histórica (se disponível)
    local cpu_trend="Estável"
    local mem_trend="Estável"
    local disk_trend="Estável"

    # Gerar relatório
    cat > "$report_file" << EOF
ANÁLISE DE PERFORMANCE - CLUSTER AI
=====================================

Período: Últimas $period
Data: $(date)

MÉTRICAS ATUAIS:
CPU: ${cpu_avg}% (Tendência: $cpu_trend)
Memória: ${mem_usage}% (${mem_used}MB / ${mem_total}MB) (Tendência: $mem_trend)
Disco: ${disk_usage}% (Tendência: $disk_trend)

ANÁLISE DE RECURSOS:
EOF

    # Análise de CPU
    if (( $(echo "$cpu_avg > 80" | bc -l) )); then
        echo "- CPU: USO ELEVADO (>80%) - Considere otimizar processos" >> "$report_file"
    elif (( $(echo "$cpu_avg > 60" | bc -l) )); then
        echo "- CPU: USO MODERADO (60-80%) - Monitorar" >> "$report_file"
    else
        echo "- CPU: USO NORMAL (<60%) - OK" >> "$report_file"
    fi

    # Análise de memória
    if [ "$mem_usage" -gt 85 ]; then
        echo "- Memória: USO ELEVADO (>85%) - Considere aumentar RAM ou otimizar" >> "$report_file"
    elif [ "$mem_usage" -gt 70 ]; then
        echo "- Memória: USO MODERADO (70-85%) - Monitorar" >> "$report_file"
    else
        echo "- Memória: USO NORMAL (<70%) - OK" >> "$report_file"
    fi

    # Análise de disco
    if [ "$disk_usage" -gt 90 ]; then
        echo "- Disco: ESPAÇO CRÍTICO (>90%) - Liberar espaço urgentemente" >> "$report_file"
    elif [ "$disk_usage" -gt 75 ]; then
        echo "- Disco: ESPAÇO BAIXO (75-90%) - Monitorar e limpar" >> "$report_file"
    else
        echo "- Disco: ESPAÇO ADEQUADO (<75%) - OK" >> "$report_file"
    fi

    echo "" >> "$report_file"
    echo "PROCESSOS MAIS CONSUMIDORES DE RECURSOS:" >> "$report_file"
    echo "==========================================" >> "$report_file"

    # Top processos por CPU
    echo "TOP CPU:" >> "$report_file"
    ps aux --sort=-%cpu | head -6 | tail -5 >> "$report_file"

    echo "" >> "$report_file"
    echo "TOP MEMÓRIA:" >> "$report_file"
    ps aux --sort=-%mem | head -6 | tail -5 >> "$report_file"

    success "Relatório de performance salvo em: $report_file"

    # Mostrar resumo na tela
    echo ""
    echo "📊 PERFORMANCE ATUAL:"
    echo "  CPU: ${cpu_avg}%"
    echo "  Memória: ${mem_usage}%"
    echo "  Disco: ${disk_usage}%"
}

# Analisa logs de erro
analyze_errors() {
    local period="${1:-24h}"
    local report_file="${REPORTS_DIR}/error_analysis_$(date +%Y%m%d_%H%M%S).txt"

    section "Análise de Erros - Últimas $period"

    mkdir -p "$REPORTS_DIR"

    # Procurar por erros em todos os logs
    local error_patterns=("ERROR" "CRITICAL" "FATAL" "Exception" "Traceback" "Failed" "Error")
    local total_errors=0
    local error_summary=""

    # Analisar cada arquivo de log
    for log_file in "$MONITOR_LOG" "$INSTALL_LOG" "$OLLAMA_LOG" "$DASK_LOG"; do
        if [ -f "$log_file" ]; then
            local log_name=$(basename "$log_file" .log)

            # Filtrar por período
            local log_content=""
            case $period in
                1h)
                    log_content=$(grep "$(date '+%Y-%m-%d %H')" "$log_file" 2>/dev/null || true)
                    ;;
                24h|1d)
                    log_content=$(grep "$(date -d '1 day ago' '+%Y-%m-%d')" "$log_file" 2>/dev/null || true)
                    ;;
                7d)
                    log_content=$(grep "$(date -d '7 days ago' '+%Y-%m-%d')" "$log_file" 2>/dev/null || true)
                    ;;
                *)
                    log_content=$(cat "$log_file" 2>/dev/null || true)
                    ;;
            esac

            if [ -n "$log_content" ]; then
                local errors_found=0
                for pattern in "${error_patterns[@]}"; do
                    local count=$(echo "$log_content" | grep -c "$pattern" 2>/dev/null || true)
                    errors_found=$((errors_found + count))
                done

                if [ "$errors_found" -gt 0 ]; then
                    error_summary="${error_summary}${log_name}: ${errors_found} erros\n"
                    total_errors=$((total_errors + errors_found))
                fi
            fi
        fi
    done

    # Gerar relatório
    cat > "$report_file" << EOF
ANÁLISE DE ERROS - CLUSTER AI
==============================

Período: Últimas $period
Data: $(date)
Total de Erros: $total_errors

DISTRIBUIÇÃO POR COMPONENTE:
$error_summary

PATRÕES DE ERRO MAIS COMUNS:
EOF

    # Analisar padrões de erro mais comuns
    if [ "$total_errors" -gt 0 ]; then
        for log_file in "$MONITOR_LOG" "$INSTALL_LOG" "$OLLAMA_LOG" "$DASK_LOG"; do
            if [ -f "$log_file" ]; then
                echo "" >> "$report_file"
                echo "=== $(basename "$log_file") ===" >> "$report_file"

                # Filtrar logs por período e contar padrões
                local filtered_logs=""
                case $period in
                    1h)
                        filtered_logs=$(grep "$(date '+%Y-%m-%d %H')" "$log_file" 2>/dev/null || true)
                        ;;
                    24h|1d)
                        filtered_logs=$(grep "$(date -d '1 day ago' '+%Y-%m-%d')" "$log_file" 2>/dev/null || true)
                        ;;
                    7d)
                        filtered_logs=$(grep "$(date -d '7 days ago' '+%Y-%m-%d')" "$log_file" 2>/dev/null || true)
                        ;;
                    *)
                        filtered_logs=$(cat "$log_file" 2>/dev/null || true)
                        ;;
                esac

                if [ -n "$filtered_logs" ]; then
                    echo "$filtered_logs" | grep -E "(ERROR|CRITICAL|FATAL|Exception|Traceback|Failed|Error)" | \
                        sed 's/.*\(ERROR\|CRITICAL\|FATAL\|Exception\|Traceback\|Failed\|Error\).*/\1/' | \
                        sort | uniq -c | sort -nr | head -5 >> "$report_file"
                fi
            fi
        done
    fi

    echo "" >> "$report_file"
    echo "ÚLTIMOS ERROS DETECTADOS:" >> "$report_file"
    echo "=========================" >> "$report_file"

    # Mostrar últimos erros de todos os logs
    for log_file in "$MONITOR_LOG" "$INSTALL_LOG" "$OLLAMA_LOG" "$DASK_LOG"; do
        if [ -f "$log_file" ]; then
            echo "" >> "$report_file"
            echo "=== $(basename "$log_file") ===" >> "$report_file"
            tail -5 "$log_file" 2>/dev/null | grep -E "(ERROR|CRITICAL|FATAL|Exception|Traceback|Failed|Error)" >> "$report_file" || true
        fi
    done

    success "Relatório de erros salvo em: $report_file"

    # Mostrar resumo na tela
    echo ""
    echo "🚨 RESUMO DE ERROS:"
    echo "  Total: $total_errors"
    if [ "$total_errors" -gt 0 ]; then
        echo "  Distribuição:"
        echo -e "$error_summary" | sed 's/^/    /'
    fi
}

# Analisa uso de recursos por componente
analyze_resource_usage() {
    local report_file="${REPORTS_DIR}/resource_usage_$(date +%Y%m%d_%H%M%S).txt"

    section "Análise de Uso de Recursos por Componente"

    mkdir -p "$REPORTS_DIR"

    # Gerar relatório
    cat > "$report_file" << EOF
ANÁLISE DE USO DE RECURSOS - CLUSTER AI
========================================

Data: $(date)

COMPONENTES ATIVOS:
EOF

    # Verificar status dos componentes
    local components_status=""

    # Ollama
    if pgrep -f "ollama" >/dev/null 2>&1; then
        local ollama_pid=$(pgrep -f "ollama")
        local ollama_cpu=$(ps -o pcpu= -p "$ollama_pid" | xargs)
        local ollama_mem=$(ps -o pmem= -p "$ollama_pid" | xargs)
        components_status="${components_status}Ollama: ATIVO (CPU: ${ollama_cpu}%, Mem: ${ollama_mem}%)\n"
    else
        components_status="${components_status}Ollama: INATIVO\n"
    fi

    # Dask
    if pgrep -f "dask-scheduler" >/dev/null 2>&1; then
        local dask_pid=$(pgrep -f "dask-scheduler")
        local dask_cpu=$(ps -o pcpu= -p "$dask_pid" | xargs)
        local dask_mem=$(ps -o pmem= -p "$dask_pid" | xargs)
        local worker_count=$(pgrep -f "dask-worker" | wc -l)
        components_status="${components_status}Dask Scheduler: ATIVO (CPU: ${dask_cpu}%, Mem: ${dask_mem}%, Workers: ${worker_count})\n"
    else
        components_status="${components_status}Dask Scheduler: INATIVO\n"
    fi

    # Open WebUI
    if pgrep -f "open-webui" >/dev/null 2>&1; then
        local webui_pid=$(pgrep -f "open-webui")
        local webui_cpu=$(ps -o pcpu= -p "$webui_pid" | xargs)
        local webui_mem=$(ps -o pmem= -p "$webui_pid" | xargs)
        components_status="${components_status}Open WebUI: ATIVO (CPU: ${webui_cpu}%, Mem: ${webui_mem}%)\n"
    else
        components_status="${components_status}Open WebUI: INATIVO\n"
    fi

    # Docker
    if command_exists docker && docker info >/dev/null 2>&1; then
        local container_count=$(docker ps | wc -l)
        local container_running=$((container_count - 1))
        components_status="${components_status}Docker: ATIVO (Containers: ${container_running})\n"
    else
        components_status="${components_status}Docker: INATIVO\n"
    fi

    echo -e "$components_status" >> "$report_file"

    echo "" >> "$report_file"
    echo "TOP PROCESSOS POR RECURSOS:" >> "$report_file"
    echo "============================" >> "$report_file"

    echo "Por CPU:" >> "$report_file"
    ps aux --sort=-%cpu | head -11 | tail -10 >> "$report_file"

    echo "" >> "$report_file"
    echo "Por Memória:" >> "$report_file"
    ps aux --sort=-%mem | head -11 | tail -10 >> "$report_file"

    echo "" >> "$report_file"
    echo "Por Disco:" >> "$report_file"
    if command_exists iotop; then
        timeout 5 iotop -b -n 1 | head -11 | tail -10 >> "$report_file" 2>/dev/null || echo "iotop não disponível" >> "$report_file"
    else
        echo "iotop não instalado - instale para análise de I/O" >> "$report_file"
    fi

    success "Relatório de uso de recursos salvo em: $report_file"

    # Mostrar resumo na tela
    echo ""
    echo "🔧 STATUS DOS COMPONENTES:"
    echo -e "$components_status" | sed 's/^/  /'
}

# Gera relatório completo
generate_full_report() {
    local report_file="${REPORTS_DIR}/full_analysis_$(date +%Y%m%d_%H%M%S).txt"

    section "Gerando Relatório Completo de Análise"

    mkdir -p "$REPORTS_DIR"

    cat > "$report_file" << EOF
RELATÓRIO COMPLETO DE ANÁLISE - CLUSTER AI
============================================

Data: $(date)
Hostname: $(hostname)
Uptime: $(uptime -p)

RESUMO EXECUTIVO:
================
EOF

    # Coletar métricas básicas para o resumo
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    local mem_info=$(free | grep Mem)
    local mem_total=$(echo $mem_info | awk '{print $2}')
    local mem_used=$(echo $mem_info | awk '{print $3}')
    local mem_usage=$((mem_used * 100 / mem_total))
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

    echo "Sistema:" >> "$report_file"
    echo "  CPU: ${cpu_usage}%" >> "$report_file"
    echo "  Memória: ${mem_usage}% (${mem_used}MB / ${mem_total}MB)" >> "$report_file"
    echo "  Disco: ${disk_usage}%" >> "$report_file"
    echo "" >> "$report_file"

    # Status dos serviços
    echo "Serviços:" >> "$report_file"
    if pgrep -f "ollama" >/dev/null 2>&1; then
        echo "  Ollama: ATIVO" >> "$report_file"
    else
        echo "  Ollama: INATIVO" >> "$report_file"
    fi

    if pgrep -f "dask-scheduler" >/dev/null 2>&1; then
        echo "  Dask: ATIVO" >> "$report_file"
    else
        echo "  Dask: INATIVO" >> "$report_file"
    fi

    if pgrep -f "open-webui" >/dev/null 2>&1; then
        echo "  WebUI: ATIVO" >> "$report_file"
    else
        echo "  WebUI: INATIVO" >> "$report_file"
    fi

    echo "" >> "$report_file"
    echo "Para relatórios detalhados, execute:" >> "$report_file"
    echo "  ./log_analyzer.sh alerts    - Análise de alertas" >> "$report_file"
    echo "  ./log_analyzer.sh performance - Análise de performance" >> "$report_file"
    echo "  ./log_analyzer.sh errors    - Análise de erros" >> "$report_file"
    echo "  ./log_analyzer.sh resources - Análise de recursos" >> "$report_file"

    success "Relatório completo salvo em: $report_file"
}

# ==================== FUNÇÃO PRINCIPAL ====================

main() {
    case "${1:-help}" in
        alerts)
            analyze_alerts "${2:-24h}"
            ;;
        performance)
            analyze_performance "${2:-1h}"
            ;;
        errors)
            analyze_errors "${2:-24h}"
            ;;
        resources)
            analyze_resource_usage
            ;;
        full)
            generate_full_report
            ;;
        *)
            echo "Uso: $0 [comando] [período]"
            echo ""
            echo "Comandos:"
            echo "  alerts [período]     - Análise de alertas (1h, 24h, 7d)"
            echo "  performance [período] - Análise de performance (1h, 24h, 7d)"
            echo "  errors [período]     - Análise de erros (1h, 24h, 7d)"
            echo "  resources            - Análise de uso de recursos"
            echo "  full                 - Relatório completo"
            echo ""
            echo "Períodos disponíveis: 1h, 24h, 7d"
            echo ""
            echo "Exemplos:"
            echo "  $0 alerts 24h"
            echo "  $0 performance 1h"
            echo "  $0 errors 7d"
            ;;
    esac
}

main "$@"
