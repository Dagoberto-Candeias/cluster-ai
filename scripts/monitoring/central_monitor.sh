#!/bin/bash
# Sistema Central de Monitoramento do Cluster AI

set -euo pipefail

# ==================== CONFIGURAÇÃO ====================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MONITOR_DIR="${PROJECT_ROOT}/scripts/monitoring"
LOGS_DIR="${PROJECT_ROOT}/logs"
METRICS_DIR="${PROJECT_ROOT}/metrics"
ALERTS_DIR="${PROJECT_ROOT}/alerts"

# Arquivos de configuração
MONITOR_CONFIG="${PROJECT_ROOT}/config/monitor.conf"
ALERT_CONFIG="${PROJECT_ROOT}/config/alerts.conf"

# Arquivos de dados
METRICS_FILE="${METRICS_DIR}/cluster_metrics.json"
ALERTS_LOG="${ALERTS_DIR}/alerts.log"
MONITOR_LOG="${LOGS_DIR}/monitor.log"

# Carregar módulos core
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."

# Carregar módulos na ordem correta (common primeiro)
source "${PROJECT_ROOT}/scripts/core/common.sh"
source "${PROJECT_ROOT}/scripts/core/security.sh"

# Carregar utilitários de progresso
if [ ! -f "${PROJECT_ROOT}/scripts/utils/progress_utils.sh" ]; then
    echo "ERRO: Utilitários de progresso não encontrados."
    exit 1
fi
source "${PROJECT_ROOT}/scripts/utils/progress_utils.sh"

# ==================== VARIÁVEIS DE CONTROLE ====================

MONITOR_INTERVAL=30  # segundos
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_DISK=90
ALERT_THRESHOLD_BATTERY=20

# Arrays para armazenar métricas
declare -A CPU_METRICS
declare -A MEMORY_METRICS
declare -A DISK_METRICS
declare -A NETWORK_METRICS
declare -A ANDROID_METRICS

# ==================== FUNÇÕES DE COLETA DE MÉTRICAS ====================

# Coleta métricas de CPU
collect_cpu_metrics() {
    local cpu_usage
    local cpu_temp
    local load_avg

    # Uso de CPU
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

    # Temperatura da CPU (se disponível)
    if command_exists sensors; then
        cpu_temp=$(sensors | grep 'Core 0' | head -1 | awk '{print $3}' | sed 's/+//' | sed 's/°C//')
    else
        cpu_temp="N/A"
    fi

    # Load average
    load_avg=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)

    CPU_METRICS["usage"]=$cpu_usage
    CPU_METRICS["temperature"]=$cpu_temp
    CPU_METRICS["load_average"]=$load_avg
    CPU_METRICS["timestamp"]=$(date +%s)
}

# Coleta métricas de memória
collect_memory_metrics() {
    local total_mem used_mem free_mem available_mem mem_usage

    # Memória em MB
    total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    used_mem=$(free -m | awk 'NR==2{printf "%.0f", $3}')
    free_mem=$(free -m | awk 'NR==2{printf "%.0f", $4}')
    available_mem=$(free -m | awk 'NR==2{printf "%.0f", $7}')

    # Porcentagem de uso
    mem_usage=$(echo "scale=2; ($used_mem / $total_mem) * 100" | bc)

    MEMORY_METRICS["total"]=$total_mem
    MEMORY_METRICS["used"]=$used_mem
    MEMORY_METRICS["free"]=$free_mem
    MEMORY_METRICS["available"]=$available_mem
    MEMORY_METRICS["usage_percent"]=$mem_usage
    MEMORY_METRICS["timestamp"]=$(date +%s)
}

# Coleta métricas de disco
collect_disk_metrics() {
    local disk_usage
    local disk_total
    local disk_used
    local disk_available

    # Uso do disco raiz
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    disk_total=$(df -BG / | tail -1 | awk '{print $2}' | sed 's/G//')
    disk_used=$(df -BG / | tail -1 | awk '{print $3}' | sed 's/G//')
    disk_available=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')

    DISK_METRICS["usage_percent"]=$disk_usage
    DISK_METRICS["total_gb"]=$disk_total
    DISK_METRICS["used_gb"]=$disk_used
    DISK_METRICS["available_gb"]=$disk_available
    DISK_METRICS["timestamp"]=$(date +%s)
}

# Coleta métricas de rede
collect_network_metrics() {
    local rx_bytes tx_bytes

    # Bytes recebidos e enviados (desde o boot)
    rx_bytes=$(cat /proc/net/dev | grep -E "^[[:space:]]*eth0|^[[:space:]]*wlan0|^[[:space:]]*enp" | head -1 | awk '{print $2}')
    tx_bytes=$(cat /proc/net/dev | grep -E "^[[:space:]]*eth0|^[[:space:]]*wlan0|^[[:space:]]*enp" | head -1 | awk '{print $10}')

    # Converter para MB
    rx_mb=$(echo "scale=2; $rx_bytes / 1024 / 1024" | bc)
    tx_mb=$(echo "scale=2; $tx_bytes / 1024 / 1024" | bc)

    NETWORK_METRICS["rx_mb"]=$rx_mb
    NETWORK_METRICS["tx_mb"]=$tx_mb
    NETWORK_METRICS["timestamp"]=$(date +%s)
}

# Coleta métricas de processos do cluster
collect_cluster_metrics() {
    local ollama_running=0
    local dask_running=0
    local webui_running=0
    local worker_count=0
    local dask_tasks_completed=0
    local dask_tasks_failed=0
    local dask_memory_used=0

    # Verificar processos principais
    if pgrep -f "ollama" >/dev/null 2>&1; then
        ollama_running=1
    fi

    if pgrep -f "dask-scheduler\|dask-worker" >/dev/null 2>&1; then
        dask_running=1
        worker_count=$(pgrep -f "dask-worker" | wc -l)

        # Coletar métricas avançadas do Dask (se disponível)
        if command_exists python3 && [ -f "${PROJECT_ROOT}/.venv/bin/activate" ]; then
            source "${PROJECT_ROOT}/.venv/bin/activate"
            # Tentar coletar métricas via Dask client
            python3 -c "
import dask
from dask.distributed import Client
import time
try:
    client = Client('tls://192.168.0.2:8786', timeout='2s')
    info = client.scheduler_info()
    print(f'tasks_completed:{len([t for t in info.get(\"tasks\", {}).values() if t.get(\"state\") == \"memory\"])}')
    print(f'tasks_failed:{len([t for t in info.get(\"tasks\", {}).values() if t.get(\"state\") == \"erred\"])}')
    workers = info.get('workers', {})
    total_memory = sum(w.get('metrics', {}).get('memory', 0) for w in workers.values())
    print(f'memory_used:{total_memory}')
    client.close()
except Exception as e:
    print('tasks_completed:0')
    print('tasks_failed:0')
    print('memory_used:0')
" 2>/dev/null | while IFS=: read -r key value; do
                case $key in
                    tasks_completed) dask_tasks_completed=$value ;;
                    tasks_failed) dask_tasks_failed=$value ;;
                    memory_used) dask_memory_used=$value ;;
                esac
            done
        fi
    fi

    if pgrep -f "open-webui" >/dev/null 2>&1; then
        webui_running=1
    fi

    CLUSTER_METRICS["ollama_running"]=$ollama_running
    CLUSTER_METRICS["dask_running"]=$dask_running
    CLUSTER_METRICS["webui_running"]=$webui_running
    CLUSTER_METRICS["worker_count"]=$worker_count
    CLUSTER_METRICS["dask_tasks_completed"]=$dask_tasks_completed
    CLUSTER_METRICS["dask_tasks_failed"]=$dask_tasks_failed
    CLUSTER_METRICS["dask_memory_used"]=$dask_memory_used
    CLUSTER_METRICS["timestamp"]=$(date +%s)
}

# Coleta métricas de Android workers (simulado)
collect_android_metrics() {
    # Em um sistema real, isso seria coletado via API dos workers Android
    # Por enquanto, simulamos alguns valores

    local battery_level=$((RANDOM % 100 + 1))
    local cpu_usage=$((RANDOM % 100 + 1))
    local memory_usage=$((RANDOM % 100 + 1))
    local network_latency=$((RANDOM % 200 + 10))

    ANDROID_METRICS["battery_level"]=$battery_level
    ANDROID_METRICS["cpu_usage"]=$cpu_usage
    ANDROID_METRICS["memory_usage"]=$memory_usage
    ANDROID_METRICS["network_latency"]=$network_latency
    ANDROID_METRICS["active_workers"]=3
    ANDROID_METRICS["timestamp"]=$(date +%s)
}

# ==================== FUNÇÕES DE ALERTAS ====================

# Verifica alertas de CPU
check_cpu_alerts() {
    local cpu_usage=${CPU_METRICS["usage"]}

    if (( $(echo "$cpu_usage > $ALERT_THRESHOLD_CPU" | bc -l) )); then
        create_alert "CRITICAL" "CPU" "Uso de CPU alto: ${cpu_usage}% (threshold: ${ALERT_THRESHOLD_CPU}%)"
        return 1
    elif (( $(echo "$cpu_usage > $((ALERT_THRESHOLD_CPU - 10))" | bc -l) )); then
        create_alert "WARNING" "CPU" "Uso de CPU elevado: ${cpu_usage}%"
        return 0
    fi

    return 0
}

# Verifica alertas de memória
check_memory_alerts() {
    local mem_usage=${MEMORY_METRICS["usage_percent"]}

    if (( $(echo "$mem_usage > $ALERT_THRESHOLD_MEMORY" | bc -l) )); then
        create_alert "CRITICAL" "MEMORY" "Uso de memória alto: ${mem_usage}% (threshold: ${ALERT_THRESHOLD_MEMORY}%)"
        return 1
    elif (( $(echo "$mem_usage > $((ALERT_THRESHOLD_MEMORY - 10))" | bc -l) )); then
        create_alert "WARNING" "MEMORY" "Uso de memória elevado: ${mem_usage}%"
        return 0
    fi

    return 0
}

# Verifica alertas de disco
check_disk_alerts() {
    local disk_usage=${DISK_METRICS["usage_percent"]}

    if [ "$disk_usage" -gt "$ALERT_THRESHOLD_DISK" ]; then
        create_alert "CRITICAL" "DISK" "Uso de disco alto: ${disk_usage}% (threshold: ${ALERT_THRESHOLD_DISK}%)"
        return 1
    elif [ "$disk_usage" -gt "$((ALERT_THRESHOLD_DISK - 10))" ]; then
        create_alert "WARNING" "DISK" "Uso de disco elevado: ${disk_usage}%"
        return 0
    fi

    return 0
}

# Verifica alertas de bateria (Android)
check_battery_alerts() {
    local battery_level=${ANDROID_METRICS["battery_level"]}

    if [ "$battery_level" -lt "$ALERT_THRESHOLD_BATTERY" ]; then
        create_alert "CRITICAL" "BATTERY" "Bateria baixa em workers Android: ${battery_level}% (threshold: ${ALERT_THRESHOLD_BATTERY}%)"
        return 1
    elif [ "$battery_level" -lt "$((ALERT_THRESHOLD_BATTERY + 10))" ]; then
        create_alert "WARNING" "BATTERY" "Bateria baixa em workers Android: ${battery_level}%"
        return 0
    fi

    return 0
}

# Cria alerta
create_alert() {
    local severity="$1"
    local component="$2"
    local message="$3"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Log do alerta
    echo "[$timestamp] [$severity] [$component] $message" >> "$ALERTS_LOG"

    # Exibe alerta na tela se for crítico
    if [ "$severity" = "CRITICAL" ]; then
        error "🚨 ALERTA CRÍTICO: $component - $message"
    elif [ "$severity" = "WARNING" ]; then
        warn "⚠️ ALERTA: $component - $message"
    fi

    # Aqui poderia ser integrada com sistema de notificações (email, Slack, etc.)
}

# ==================== FUNÇÕES DE DASHBOARD ====================

# Exibe dashboard em tempo real
show_dashboard() {
    clear
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                           CLUSTER AI MONITOR                              ║"
    echo "╠══════════════════════════════════════════════════════════════════════════════╣"
    echo "║ $(date '+%Y-%m-%d %H:%M:%S')                                               ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo ""

    # CPU
    echo "🔥 CPU"
    echo "   Uso: ${CPU_METRICS["usage"]}%"
    echo "   Temperatura: ${CPU_METRICS["temperature"]}°C"
    echo "   Load Average: ${CPU_METRICS["load_average"]}"
    echo ""

    # Memória
    echo "🧠 MEMÓRIA"
    echo "   Uso: ${MEMORY_METRICS["usage_percent"]}%"
    echo "   Total: ${MEMORY_METRICS["total"]}MB"
    echo "   Usado: ${MEMORY_METRICS["used"]}MB"
    echo "   Disponível: ${MEMORY_METRICS["available"]}MB"
    echo ""

    # Disco
    echo "💾 DISCO"
    echo "   Uso: ${DISK_METRICS["usage_percent"]}%"
    echo "   Total: ${DISK_METRICS["total_gb"]}GB"
    echo "   Usado: ${DISK_METRICS["used_gb"]}GB"
    echo "   Disponível: ${DISK_METRICS["available_gb"]}GB"
    echo ""

    # Rede
    echo "🌐 REDE"
    echo "   Recebido: ${NETWORK_METRICS["rx_mb"]}MB"
    echo "   Enviado: ${NETWORK_METRICS["tx_mb"]}MB"
    echo ""

    # Cluster
    echo "⚙️ CLUSTER"
    echo "   Ollama: $([ "${CLUSTER_METRICS["ollama_running"]}" = "1" ] && echo "✅ Rodando" || echo "❌ Parado")"
    echo "   Dask: $([ "${CLUSTER_METRICS["dask_running"]}" = "1" ] && echo "✅ Rodando" || echo "❌ Parado")"
    echo "   WebUI: $([ "${CLUSTER_METRICS["webui_running"]}" = "1" ] && echo "✅ Rodando" || echo "❌ Parado")"
    echo "   Workers: ${CLUSTER_METRICS["worker_count"]}"
    echo "   Tarefas Concluídas: ${CLUSTER_METRICS["dask_tasks_completed"]}"
    echo "   Tarefas Falhadas: ${CLUSTER_METRICS["dask_tasks_failed"]}"
    echo "   Memória Dask: ${CLUSTER_METRICS["dask_memory_used"]} bytes"
    echo ""

    # Android Workers
    echo "🤖 ANDROID WORKERS"
    echo "   Workers Ativos: ${ANDROID_METRICS["active_workers"]}"
    echo "   Bateria Média: ${ANDROID_METRICS["battery_level"]}%"
    echo "   CPU Médio: ${ANDROID_METRICS["cpu_usage"]}%"
    echo "   Memória Média: ${ANDROID_METRICS["memory_usage"]}%"
    echo "   Latência Rede: ${ANDROID_METRICS["network_latency"]}ms"
    echo ""

    # Status dos alertas
    echo "🚨 ÚLTIMOS ALERTAS"
    if [ -f "$ALERTS_LOG" ]; then
        tail -5 "$ALERTS_LOG" | while read -r line; do
            echo "   $line"
        done
    else
        echo "   Nenhum alerta registrado"
    fi
}

# ==================== FUNÇÕES DE RELATÓRIOS ====================

# Gera relatório de métricas
generate_metrics_report() {
    local report_file="$METRICS_DIR/report_$(date +%Y%m%d_%H%M%S).json"

    # Cria estrutura JSON das métricas
    cat > "$report_file" << EOF
{
  "timestamp": "$(date +%s)",
  "date": "$(date)",
  "system_metrics": {
    "cpu": {
      "usage_percent": "${CPU_METRICS["usage"]}",
      "temperature": "${CPU_METRICS["temperature"]}",
      "load_average": "${CPU_METRICS["load_average"]}"
    },
    "memory": {
      "total_mb": "${MEMORY_METRICS["total"]}",
      "used_mb": "${MEMORY_METRICS["used"]}",
      "free_mb": "${MEMORY_METRICS["free"]}",
      "available_mb": "${MEMORY_METRICS["available"]}",
      "usage_percent": "${MEMORY_METRICS["usage_percent"]}"
    },
    "disk": {
      "usage_percent": "${DISK_METRICS["usage_percent"]}",
      "total_gb": "${DISK_METRICS["total_gb"]}",
      "used_gb": "${DISK_METRICS["used_gb"]}",
      "available_gb": "${DISK_METRICS["available_gb"]}"
    },
    "network": {
      "rx_mb": "${NETWORK_METRICS["rx_mb"]}",
      "tx_mb": "${NETWORK_METRICS["tx_mb"]}"
    }
  },
  "cluster_metrics": {
    "ollama_running": "${CLUSTER_METRICS["ollama_running"]}",
    "dask_running": "${CLUSTER_METRICS["dask_running"]}",
    "webui_running": "${CLUSTER_METRICS["webui_running"]}",
    "worker_count": "${CLUSTER_METRICS["worker_count"]}"
  },
  "android_metrics": {
    "active_workers": "${ANDROID_METRICS["active_workers"]}",
    "battery_level": "${ANDROID_METRICS["battery_level"]}",
    "cpu_usage": "${ANDROID_METRICS["cpu_usage"]}",
    "memory_usage": "${ANDROID_METRICS["memory_usage"]}",
    "network_latency": "${ANDROID_METRICS["network_latency"]}"
  }
}
EOF

    success "Relatório de métricas salvo em: $report_file"
}

# ==================== FUNÇÕES DE LOG ROTATION ====================

# Rotaciona logs antigos
rotate_logs() {
    local max_age_days=30
    local max_files=100

    subsection "Rotacionando Logs"

    # Remove logs antigos
    find "$LOGS_DIR" -name "*.log" -mtime +$max_age_days -delete 2>/dev/null || true
    find "$METRICS_DIR" -name "*.json" -mtime +$max_age_days -delete 2>/dev/null || true
    find "$ALERTS_DIR" -name "*.log" -mtime +$max_age_days -delete 2>/dev/null || true

    # Limita número de arquivos
    find "$LOGS_DIR" -name "*.log" -type f -printf '%T@ %p\n' | sort -n | head -n -$max_files | cut -d' ' -f2- | xargs -r rm 2>/dev/null || true
    find "$METRICS_DIR" -name "*.json" -type f -printf '%T@ %p\n' | sort -n | head -n -$max_files | cut -d' ' -f2- | xargs -r rm 2>/dev/null || true

    success "Rotação de logs concluída"
}

# ==================== FUNÇÃO PRINCIPAL ====================

main() {
    # Criar diretórios necessários
    mkdir -p "$METRICS_DIR" "$ALERTS_DIR"

    # Importar funções UI do módulo core ui.sh
    source "${PROJECT_ROOT}/scripts/core/ui.sh"

    case "${1:-monitor}" in
        monitor)
            section "Iniciando Monitoramento do Cluster AI"

            # Loop principal de monitoramento
            while true; do
                # Coletar todas as métricas
                collect_cpu_metrics
                collect_memory_metrics
                collect_disk_metrics
                collect_network_metrics
                collect_cluster_metrics
                collect_android_metrics

                # Verificar alertas
                check_cpu_alerts
                check_memory_alerts
                check_disk_alerts
                check_battery_alerts

                # Salvar métricas
                generate_metrics_report

                # Rotacionar logs periodicamente (a cada 24 horas)
                if [ $(( $(date +%s) % 86400 )) -eq 0 ]; then
                    rotate_logs
                fi

                # Aguardar próximo ciclo
                sleep "$MONITOR_INTERVAL"
            done
            ;;
        dashboard)
            section "Dashboard de Monitoramento em Tempo Real"

            # Loop do dashboard
            while true; do
                # Coletar métricas
                collect_cpu_metrics
                collect_memory_metrics
                collect_disk_metrics
                collect_network_metrics
                collect_cluster_metrics
                collect_android_metrics

                # Exibir dashboard
                show_dashboard

                # Aguardar entrada do usuário ou timeout
                echo ""
                echo "Pressione 'q' para sair ou aguarde atualização automática..."
                read -t "$MONITOR_INTERVAL" -n 1 input
                if [ "$input" = "q" ]; then
                    break
                fi
            done
            ;;
        alerts)
            section "Sistema de Alertas"

            if [ -f "$ALERTS_LOG" ]; then
                echo "🚨 ÚLTIMOS ALERTAS:"
                echo ""
                tail -20 "$ALERTS_LOG" | nl
            else
                echo "Nenhum alerta registrado ainda."
            fi
            ;;
        report)
            section "Gerando Relatório de Métricas"

            # Coletar métricas atuais
            collect_cpu_metrics
            collect_memory_metrics
            collect_disk_metrics
            collect_network_metrics
            collect_cluster_metrics
            collect_android_metrics

            # Gerar relatório
            generate_metrics_report
            ;;
        rotate)
            rotate_logs
            ;;
        *)
            echo "Uso: $0 [monitor|dashboard|alerts|report|rotate]"
            echo ""
            echo "Comandos:"
            echo "  monitor   - Inicia monitoramento contínuo"
            echo "  dashboard - Exibe dashboard em tempo real"
            echo "  alerts    - Mostra histórico de alertas"
            echo "  report    - Gera relatório de métricas atual"
            echo "  rotate    - Rotaciona logs antigos"
            ;;
    esac
}

main "$@"
