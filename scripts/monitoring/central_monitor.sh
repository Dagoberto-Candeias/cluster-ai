#!/bin/bash
# -*- coding: utf-8 -*-
#
# Cluster AI - Central Monitor Script
# Monitor centralizado do Cluster AI
#
# Projeto: Cluster AI
# Autor: Sistema de consolidação automática
# Data: 2024-12-19
# Versão: 1.0.0
#
# Descrição:
#   Script responsável pelo monitoramento centralizado de todos os componentes
#   do Cluster AI. Coleta métricas, detecta anomalias, gera alertas e
#   fornece relatórios consolidados. Suporta monitoramento em tempo real
#   e modo batch para relatórios.
#
# Uso:
#   ./scripts/monitoring/central_monitor.sh [opções]
#
# Dependências:
#   - bash
#   - curl, wget
#   - jq (para parsing JSON)
#   - bc (para cálculos)
#   - mail (para alertas por email)
#
# Changelog:
#   v1.0.0 - 2024-12-19: Criação inicial com funcionalidades completas
#
# ============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório base
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
CENTRAL_LOG="$LOG_DIR/central_monitor.log"

# Configurações
MONITOR_INTERVAL=10
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_DISK=90
EMAIL_ALERTS="admin@cluster-ai.local"
MAX_LOG_FILES=50

# Arrays para controle
ACTIVE_ALERTS=()
MONITORING_DATA=()
SERVICES_STATUS=()

# Funções utilitárias
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar dependências
check_dependencies() {
    log_info "Verificando dependências do monitor central..."

    local missing_deps=()
    local required_commands=(
        "curl"
        "jq"
        "bc"
        "mail"
        "ps"
        "netstat"
    )

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Dependências faltando: ${missing_deps[*]}"
        log_info "Instale as dependências necessárias e tente novamente"
        return 1
    fi

    log_success "Dependências verificadas"
    return 0
}

# Função para coletar métricas detalhadas
collect_detailed_metrics() {
    local timestamp=$(date +%s)

    # Métricas de sistema
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    local mem_info=$(free | grep Mem)
    local mem_total=$(echo "$mem_info" | awk '{print $2}')
    local mem_used=$(echo "$mem_info" | awk '{print $3}')
    local mem_usage=$(echo "scale=2; $mem_used * 100 / $mem_total" | bc)
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

    # Processos
    local total_processes=$(ps aux | wc -l)
    local dask_processes=$(ps aux | grep -c dask)
    local ollama_processes=$(ps aux | grep -c ollama)
    local webui_processes=$(ps aux | grep -c openwebui)

    # Rede
    local net_info=$(cat /proc/net/dev | grep eth0)
    local net_rx=$(echo "$net_info" | awk '{print $2}')
    local net_tx=$(echo "$net_info" | awk '{print $10}')

    # Temperatura (se disponível)
    local temperature="N/A"
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        temperature=$(($(cat /sys/class/thermal/thermal_zone0/temp) / 1000))
    fi

    # Criar objeto de métricas
    local metrics="{\"timestamp\":$timestamp,\"cpu\":$cpu_usage,\"memory\":$mem_usage,\"disk\":$disk_usage,\"processes\":{\"total\":$total_processes,\"dask\":$dask_processes,\"ollama\":$ollama_processes,\"webui\":$webui_processes},\"network\":{\"rx\":$net_rx,\"tx\":$net_tx},\"temperature\":$temperature}"

    MONITORING_DATA+=("$metrics")

    echo "$metrics"
}

# Função para verificar status de todos os serviços
check_all_services() {
    local services=(
        "dask-scheduler:tcp://localhost:8786"
        "dask-dashboard:http://localhost:8787"
        "ollama:http://localhost:11434"
        "openwebui:http://localhost:3000"
        "nginx:http://localhost:80"
        "prometheus:http://localhost:9090"
        "grafana:http://localhost:3001"
        "postgres:tcp://localhost:5432"
    )

    local status_report=""

    for service in "${services[@]}"; do
        local name=$(echo "$service" | cut -d: -f1)
        local endpoint=$(echo "$service" | cut -d: -f2-)

        if [[ "$endpoint" == http* ]]; then
            if curl -s --connect-timeout 5 "$endpoint" > /dev/null 2>&1; then
                status_report+="$name: 🟢 ONLINE\n"
            else
                status_report+="$name: 🔴 OFFLINE\n"
                ACTIVE_ALERTS+=("$name service is not responding on $endpoint")
            fi
        elif [[ "$endpoint" == tcp* ]]; then
            local host=$(echo "$endpoint" | sed 's/tcp:\/\///' | cut -d: -f1)
            local port=$(echo "$endpoint" | sed 's/tcp:\/\///' | cut -d: -f2)
            if nc -z "$host" "$port" 2>/dev/null; then
                status_report+="$name: 🟢 ONLINE\n"
            else
                status_report+="$name: 🔴 OFFLINE\n"
                ACTIVE_ALERTS+=("$name service is not responding on $host:$port")
            fi
        fi
    done

    echo -e "$status_report"
}

# Função para detectar anomalias
detect_anomalies() {
    local current_metrics="$1"

    # Extrair valores atuais
    local cpu=$(echo "$current_metrics" | jq -r '.cpu')
    local memory=$(echo "$current_metrics" | jq -r '.memory')
    local disk=$(echo "$current_metrics" | jq -r '.disk')

    # Verificar thresholds
    if (( $(echo "$cpu > $ALERT_THRESHOLD_CPU" | bc -l) )); then
        ACTIVE_ALERTS+=("High CPU usage: $cpu% (threshold: $ALERT_THRESHOLD_CPU%)")
    fi

    if (( $(echo "$memory > $ALERT_THRESHOLD_MEMORY" | bc -l) )); then
        ACTIVE_ALERTS+=("High memory usage: $memory% (threshold: $ALERT_THRESHOLD_MEMORY%)")
    fi

    if [ "$disk" -gt "$ALERT_THRESHOLD_DISK" ]; then
        ACTIVE_ALERTS+=("High disk usage: $disk% (threshold: $ALERT_THRESHOLD_DISK%)")
    fi

    # Verificar tendências (comparar com média dos últimos 5 minutos)
    if [ ${#MONITORING_DATA[@]} -ge 5 ]; then
        local recent_metrics=("${MONITORING_DATA[@]: -5}")
        local avg_cpu=0
        local avg_memory=0

        for metric in "${recent_metrics[@]}"; do
            avg_cpu=$(echo "$avg_cpu + $(echo "$metric" | jq -r '.cpu')" | bc)
            avg_memory=$(echo "$avg_memory + $(echo "$metric" | jq -r '.memory')" | bc)
        done

        avg_cpu=$(echo "scale=2; $avg_cpu / 5" | bc)
        avg_memory=$(echo "scale=2; $avg_memory / 5" | bc)

        # Detectar picos
        if (( $(echo "$cpu > $avg_cpu + 20" | bc -l) )); then
            ACTIVE_ALERTS+=("CPU spike detected: $cpu% (average: $avg_cpu%)")
        fi

        if (( $(echo "$memory > $avg_memory + 15" | bc -l) )); then
            ACTIVE_ALERTS+=("Memory spike detected: $memory% (average: $avg_memory%)")
        fi
    fi
}

# Função para enviar alertas por email
send_email_alerts() {
    if [ ${#ACTIVE_ALERTS[@]} -eq 0 ]; then
        return 0
    fi

    local subject="Cluster AI - Alertas de Monitoramento"
    local body="Alertas ativos no Cluster AI:\n\n"

    for alert in "${ACTIVE_ALERTS[@]}"; do
        body+="- $alert\n"
    done

    body+="\nTimestamp: $(date -Iseconds)"
    body+="\nMonitor: Central Monitor"

    # Tentar enviar email
    if echo -e "$body" | mail -s "$subject" "$EMAIL_ALERTS" >> "$CENTRAL_LOG" 2>&1; then
        log_success "Alertas enviados por email"
    else
        log_warning "Falha ao enviar alertas por email"
    fi
}

# Função para gerar relatório consolidado
generate_consolidated_report() {
    local report_file="$LOG_DIR/central_monitor_report_$(date +%Y%m%d_%H%M%S).json"

    # Calcular estatísticas
    local uptime=$(uptime -p)
    local load_avg=$(uptime | awk -F'load average:' '{print $2}')
    local total_memory=$(free -h | grep Mem | awk '{print $2}')
    local used_memory=$(free -h | grep Mem | awk '{print $3}')

    cat > "$report_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "system_info": {
        "uptime": "$uptime",
        "load_average": "$load_avg",
        "total_memory": "$total_memory",
        "used_memory": "$used_memory"
    },
    "monitoring_data": [$(printf '"%s",' "${MONITORING_DATA[@]}" | sed 's/,$//')],
    "services_status": "$(check_all_services | tr '\n' ' ')",
    "active_alerts": ["$(printf '"%s",' "${ACTIVE_ALERTS[@]}" | sed 's/,$//')"],
    "thresholds": {
        "cpu": $ALERT_THRESHOLD_CPU,
        "memory": $ALERT_THRESHOLD_MEMORY,
        "disk": $ALERT_THRESHOLD_DISK
    }
}
EOF

    log_success "Relatório consolidado gerado: $report_file"
    echo "$report_file"
}

# Função para modo de monitoramento contínuo
run_continuous_monitoring() {
    log_info "Iniciando monitoramento contínuo (Ctrl+C para parar)..."

    while true; do
        local metrics=$(collect_detailed_metrics)
        local services=$(check_all_services)

        detect_anomalies "$metrics"

        clear
        echo "=== Cluster AI - Central Monitor ==="
        echo "$(date)"
        echo ""

        echo "📊 Métricas Atuais:"
        echo "$metrics" | jq '.'
        echo ""

        echo "🔧 Status dos Serviços:"
        echo -e "$services"
        echo ""

        echo "⚠️  Alertas Ativos:"
        if [ ${#ACTIVE_ALERTS[@]} -eq 0 ]; then
            echo "✅ Nenhum alerta ativo"
        else
            printf '  - %s\n' "${ACTIVE_ALERTS[@]}"
        fi

        echo ""
        echo "📈 Estatísticas de Coleta:"
        echo "  - Dados coletados: ${#MONITORING_DATA[@]}"
        echo "  - Próxima coleta em $MONITOR_INTERVAL segundos"
        echo ""

        # Enviar alertas se necessário
        send_email_alerts

        sleep $MONITOR_INTERVAL
    done
}

# Função para modo batch (relatório único)
run_batch_monitoring() {
    log_info "Executando monitoramento em modo batch..."

    collect_detailed_metrics
    check_all_services

    # Simular algumas coletas para dados mais ricos
    for i in {1..4}; do
        sleep 2
        collect_detailed_metrics
    done

    local report_file=$(generate_consolidated_report)

    echo "=== Relatório de Monitoramento Consolidado ==="
    echo "Arquivo gerado: $report_file"
    echo ""
    echo "Resumo:"
    echo "- Métricas coletadas: ${#MONITORING_DATA[@]}"
    echo "- Alertas ativos: ${#ACTIVE_ALERTS[@]}"
    echo "- Status dos serviços verificado"
}

# Função para limpar logs antigos
cleanup_old_logs() {
    log_info "Limpando logs antigos..."

    local log_files=($(ls -t "$LOG_DIR"/central_monitor*.log 2>/dev/null))

    if [ ${#log_files[@]} -gt $MAX_LOG_FILES ]; then
        local files_to_remove=("${log_files[@]:$MAX_LOG_FILES}")
        for file in "${files_to_remove[@]}"; do
            rm -f "$file"
        done
        log_success "Logs antigos removidos"
    fi
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    # Criar diretório de logs
    mkdir -p "$LOG_DIR"
    touch "$CENTRAL_LOG"

    local mode="${1:-continuous}"

    case "$mode" in
        "continuous")
            check_dependencies || exit 1
            cleanup_old_logs
            run_continuous_monitoring
            ;;
        "batch")
            check_dependencies || exit 1
            run_batch_monitoring
            ;;
        "report")
            check_dependencies || exit 1
            generate_consolidated_report
            ;;
        "alerts")
            check_dependencies || exit 1
            collect_detailed_metrics
            check_all_services
            send_email_alerts
            ;;
        "cleanup")
            cleanup_old_logs
            ;;
        "help"|*)
            echo "Cluster AI - Central Monitor Script"
            echo ""
            echo "Uso: $0 [modo]"
            echo ""
            echo "Modos:"
            echo "  continuous    - Monitoramento contínuo (padrão)"
            echo "  batch         - Relatório único consolidado"
            echo "  report        - Gerar relatório JSON"
            echo "  alerts        - Enviar alertas por email"
            echo "  cleanup       - Limpar logs antigos"
            echo "  help          - Mostra esta mensagem"
            echo ""
            echo "Configurações:"
            echo "  - Intervalo de monitoramento: $MONITOR_INTERVAL segundos"
            echo "  - Threshold CPU: $ALERT_THRESHOLD_CPU%"
            echo "  - Threshold Memória: $ALERT_THRESHOLD_MEMORY%"
            echo "  - Threshold Disco: $ALERT_THRESHOLD_DISK%"
            echo "  - Email para alertas: $EMAIL_ALERTS"
            echo "  - Máximo de logs: $MAX_LOG_FILES"
            echo ""
            echo "Exemplos:"
            echo "  $0 continuous"
            echo "  $0 batch"
            echo "  $0 report"
            echo "  $0 alerts"
            ;;
    esac
}

# Executar função principal
main "$@"
