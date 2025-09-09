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
source "${PROJECT_ROOT}/scripts/lib/common.sh"
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

# Arrays para análise de tendências
declare -a CPU_HISTORY
declare -a MEMORY_HISTORY
declare -a DISK_HISTORY
declare -a NETWORK_HISTORY
MAX_HISTORY_LENGTH=50

# ==================== FUNÇÕES DE COLETA DE MÉTRICAS ====================

# Coleta métricas de CPU
collect_cpu_metrics() {
    local cpu_usage
    local cpu_temp
    local load_avg
    local cpu_user cpu_system cpu_idle

    # Uso de CPU
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

    # Detalhes de CPU (user, system, idle)
    cpu_stats=$(top -bn1 | grep "Cpu(s)" | sed 's/Cpu(s)://' | sed 's/%//g')
    cpu_user=$(echo "$cpu_stats" | awk '{print $1}')
    cpu_system=$(echo "$cpu_stats" | awk '{print $3}')
    cpu_idle=$(echo "$cpu_stats" | awk '{print $8}')

    # Temperatura da CPU (se disponível)
    if command_exists sensors; then
        cpu_temp=$(sensors | grep 'Core 0' | head -1 | awk '{print $3}' | sed 's/+//' | sed 's/°C//')
    else
        cpu_temp="N/A"
    fi

    # Load average
    load_avg=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)

    CPU_METRICS["usage"]=$cpu_usage
    CPU_METRICS["user_percent"]=$cpu_user
    CPU_METRICS["system_percent"]=$cpu_system
    CPU_METRICS["idle_percent"]=$cpu_idle
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

# Coleta métricas de I/O de disco
collect_disk_io_metrics() {
    local disk_reads disk_writes disk_read_bytes disk_write_bytes

    # Métricas de I/O do disco (usando /proc/diskstats)
    # Para o disco principal (sda ou nvme0n1)
    if [ -f /proc/diskstats ]; then
        # Tentar diferentes nomes de dispositivo
        local disk_stats
        disk_stats=$(grep -E "sda |nvme0n1 |vda " /proc/diskstats | head -1)

        if [ -n "$disk_stats" ]; then
            # Campos: reads_completed reads_merged sectors_read_ms read_time_ms
            # writes_completed writes_merged sectors_written_ms write_time_ms
            disk_reads=$(echo "$disk_stats" | awk '{print $4}')
            disk_writes=$(echo "$disk_stats" | awk '{print $8}')
            disk_read_bytes=$(echo "$disk_stats" | awk '{print $6 * 512}')  # setores * 512 bytes
            disk_write_bytes=$(echo "$disk_stats" | awk '{print $10 * 512}')
        else
            disk_reads=0
            disk_writes=0
            disk_read_bytes=0
            disk_write_bytes=0
        fi
    else
        disk_reads=0
        disk_writes=0
        disk_read_bytes=0
        disk_write_bytes=0
    fi

    # Calcular taxas (comparado com coleta anterior se disponível)
    local current_time=$(date +%s)
    local time_diff=1

    if [ -n "${DISK_IO_METRICS['timestamp']}" ]; then
        time_diff=$((current_time - DISK_IO_METRICS['timestamp']))
        if [ $time_diff -gt 0 ]; then
            local read_rate=$(( (disk_read_bytes - DISK_IO_METRICS['read_bytes']) / time_diff / 1024 ))  # KB/s
            local write_rate=$(( (disk_write_bytes - DISK_IO_METRICS['write_bytes']) / time_diff / 1024 ))  # KB/s
            DISK_IO_METRICS["read_rate_kbps"]=$read_rate
            DISK_IO_METRICS["write_rate_kbps"]=$write_rate
        fi
    fi

    DISK_IO_METRICS["reads"]=$disk_reads
    DISK_IO_METRICS["writes"]=$disk_writes
    DISK_IO_METRICS["read_bytes"]=$disk_read_bytes
    DISK_IO_METRICS["write_bytes"]=$disk_write_bytes
    DISK_IO_METRICS["timestamp"]=$current_time
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

# ==================== FUNÇÕES DE ANÁLISE DE TENDÊNCIAS ====================

# Atualizar histórico de métricas
update_metrics_history() {
    # CPU
    if [ -n "${CPU_METRICS['usage']}" ]; then
        CPU_HISTORY+=("${CPU_METRICS['usage']}")
        if [ ${#CPU_HISTORY[@]} -gt $MAX_HISTORY_LENGTH ]; then
            CPU_HISTORY=("${CPU_HISTORY[@]:1}")
        fi
    fi

    # Memória
    if [ -n "${MEMORY_METRICS['usage_percent']}" ]; then
        MEMORY_HISTORY+=("${MEMORY_METRICS['usage_percent']}")
        if [ ${#MEMORY_HISTORY[@]} -gt $MAX_HISTORY_LENGTH ]; then
            MEMORY_HISTORY=("${MEMORY_HISTORY[@]:1}")
        fi
    fi

    # Disco
    if [ -n "${DISK_METRICS['usage_percent']}" ]; then
        DISK_HISTORY+=("${DISK_METRICS['usage_percent']}")
        if [ ${#DISK_HISTORY[@]} -gt $MAX_HISTORY_LENGTH ]; then
            DISK_HISTORY=("${DISK_HISTORY[@]:1}")
        fi
    fi

    # Rede
    if [ -n "${NETWORK_METRICS['rx_mb']}" ]; then
        NETWORK_HISTORY+=("${NETWORK_METRICS['rx_mb']}")
        if [ ${#NETWORK_HISTORY[@]} -gt $MAX_HISTORY_LENGTH ]; then
            NETWORK_HISTORY=("${NETWORK_HISTORY[@]:1}")
        fi
    fi
}

# Analisar tendências de métricas
analyze_performance_trends() {
    local trend_analysis=""

    # Análise de CPU
    if [ ${#CPU_HISTORY[@]} -gt 5 ]; then
        local cpu_recent_avg cpu_old_avg
        cpu_recent_avg=$(echo "scale=2; (${CPU_HISTORY[-1]} + ${CPU_HISTORY[-2]} + ${CPU_HISTORY[-3]}) / 3" | bc 2>/dev/null || echo "0")
        cpu_old_avg=$(echo "scale=2; (${CPU_HISTORY[-4]} + ${CPU_HISTORY[-5]} + ${CPU_HISTORY[-6]:-${CPU_HISTORY[-4]:-0}}) / 3" | bc 2>/dev/null || echo "0")

        if (( $(echo "$cpu_recent_avg > $cpu_old_avg + 10" | bc -l 2>/dev/null || echo "0") )); then
            trend_analysis="${trend_analysis}CPU usage increasing significantly (+$(echo "scale=1; $cpu_recent_avg - $cpu_old_avg" | bc)%); "
        elif (( $(echo "$cpu_old_avg > $cpu_recent_avg + 10" | bc -l 2>/dev/null || echo "0") )); then
            trend_analysis="${trend_analysis}CPU usage decreasing significantly ($(echo "scale=1; $cpu_recent_avg - $cpu_old_avg" | bc)%); "
        fi
    fi

    # Análise de Memória
    if [ ${#MEMORY_HISTORY[@]} -gt 5 ]; then
        local mem_recent_avg mem_old_avg
        mem_recent_avg=$(echo "scale=2; (${MEMORY_HISTORY[-1]} + ${MEMORY_HISTORY[-2]} + ${MEMORY_HISTORY[-3]}) / 3" | bc 2>/dev/null || echo "0")
        mem_old_avg=$(echo "scale=2; (${MEMORY_HISTORY[-4]} + ${MEMORY_HISTORY[-5]} + ${MEMORY_HISTORY[-6]:-${MEMORY_HISTORY[-4]:-0}}) / 3" | bc 2>/dev/null || echo "0")

        if (( $(echo "$mem_recent_avg > $mem_old_avg + 5" | bc -l 2>/dev/null || echo "0") )); then
            trend_analysis="${trend_analysis}Memory usage increasing (+$(echo "scale=1; $mem_recent_avg - $mem_old_avg" | bc)%); "
        fi
    fi

    # Análise de Disco
    if [ ${#DISK_HISTORY[@]} -gt 5 ]; then
        local disk_recent_avg disk_old_avg
        disk_recent_avg=$(echo "scale=2; (${DISK_HISTORY[-1]} + ${DISK_HISTORY[-2]} + ${DISK_HISTORY[-3]}) / 3" | bc 2>/dev/null || echo "0")
        disk_old_avg=$(echo "scale=2; (${DISK_HISTORY[-4]} + ${DISK_HISTORY[-5]} + ${DISK_HISTORY[-6]:-${DISK_HISTORY[-4]:-0}}) / 3" | bc 2>/dev/null || echo "0")

        if (( $(echo "$disk_recent_avg > $disk_old_avg + 2" | bc -l 2>/dev/null || echo "0") )); then
            trend_analysis="${trend_analysis}Disk usage increasing (+$(echo "scale=1; $disk_recent_avg - $disk_old_avg" | bc)%); "
        fi
    fi

    if [ -n "$trend_analysis" ]; then
        create_alert "WARNING" "TREND_ANALYSIS" "Performance trends detected: $trend_analysis"
    fi
}

# Detectar anomalias de performance
detect_performance_anomalies() {
    # Detectar spikes de CPU
    if [ ${#CPU_HISTORY[@]} -gt 3 ]; then
        local cpu_avg cpu_std cpu_current
        cpu_current=${CPU_HISTORY[-1]}

        # Calcular média e desvio padrão simples
        local sum=0 count=0
        for val in "${CPU_HISTORY[@]: -10}"; do  # Últimos 10 valores
            sum=$(echo "$sum + $val" | bc 2>/dev/null || echo "$sum")
            ((count++))
        done

        if [ $count -gt 0 ]; then
            cpu_avg=$(echo "scale=2; $sum / $count" | bc 2>/dev/null || echo "0")

            # Calcular desvio padrão simples
            local variance_sum=0
            for val in "${CPU_HISTORY[@]: -10}"; do
                local diff=$(echo "$val - $cpu_avg" | bc 2>/dev/null || echo "0")
                local squared=$(echo "$diff * $diff" | bc 2>/dev/null || echo "0")
                variance_sum=$(echo "$variance_sum + $squared" | bc 2>/dev/null || echo "$variance_sum")
            done

            local variance=$(echo "scale=2; $variance_sum / $count" | bc 2>/dev/null || echo "0")
            local std_dev=$(echo "scale=2; sqrt($variance)" | bc -l 2>/dev/null || echo "0")

            # Detectar anomalia se valor atual > média + 2*desvio
            local threshold=$(echo "scale=2; $cpu_avg + 2 * $std_dev" | bc 2>/dev/null || echo "100")

            if (( $(echo "$cpu_current > $threshold" | bc -l 2>/dev/null || echo "0") )); then
                create_alert "WARNING" "ANOMALY_DETECTION" "CPU anomaly detected: ${cpu_current}% (threshold: ${threshold}%)"
            fi
        fi
    fi

    # Detectar vazamentos de memória
    if [ ${#MEMORY_HISTORY[@]} -gt 10 ]; then
        local mem_trend=0
        local consecutive_increases=0

        # Verificar se memória está aumentando consistentemente
        for ((i=${#MEMORY_HISTORY[@]}-1; i>=${#MEMORY_HISTORY[@]}-5; i--)); do
            if [ $i -gt 0 ]; then
                local current=${MEMORY_HISTORY[$i]}
                local previous=${MEMORY_HISTORY[$((i-1))]}

                if (( $(echo "$current > $previous + 1" | bc -l 2>/dev/null || echo "0") )); then
                    ((consecutive_increases++))
                else
                    break
                fi
            fi
        done

        if [ $consecutive_increases -ge 4 ]; then
            create_alert "WARNING" "MEMORY_LEAK" "Potential memory leak detected: $consecutive_increases consecutive increases"
        fi
    fi
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

# Verifica alertas de I/O de disco
check_disk_io_alerts() {
    local read_rate=${DISK_IO_METRICS["read_rate_kbps"]:-0}
    local write_rate=${DISK_IO_METRICS["write_rate_kbps"]:-0}

    # Thresholds para I/O (valores em KB/s)
    local READ_THRESHOLD=50000   # 50 MB/s
    local WRITE_THRESHOLD=30000  # 30 MB/s

    if [ "$read_rate" -gt "$READ_THRESHOLD" ]; then
        create_alert "WARNING" "DISK_IO" "I/O de leitura alta: ${read_rate} KB/s (threshold: ${READ_THRESHOLD} KB/s)"
        return 1
    fi

    if [ "$write_rate" -gt "$WRITE_THRESHOLD" ]; then
        create_alert "WARNING" "DISK_IO" "I/O de escrita alta: ${write_rate} KB/s (threshold: ${WRITE_THRESHOLD} KB/s)"
        return 1
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
    echo "   Uso Total: ${CPU_METRICS["usage"]}%"
    echo "   User: ${CPU_METRICS["user_percent"]:-0}% | System: ${CPU_METRICS["system_percent"]:-0}% | Idle: ${CPU_METRICS["idle_percent"]:-0}%"
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
    echo "   I/O Leitura: ${DISK_IO_METRICS["read_rate_kbps"]:-0} KB/s"
    echo "   I/O Escrita: ${DISK_IO_METRICS["write_rate_kbps"]:-0} KB/s"
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
    local compression_enabled=true

    subsection "Rotacionando Logs"

    # Remove logs antigos
    find "$LOGS_DIR" -name "*.log" -mtime +$max_age_days -delete 2>/dev/null || true
    find "$METRICS_DIR" -name "*.json" -mtime +$max_age_days -delete 2>/dev/null || true
    find "$ALERTS_DIR" -name "*.log" -mtime +$max_age_days -delete 2>/dev/null || true

    # Compress logs before rotation if enabled
    if [ "$compression_enabled" = true ]; then
        find "$LOGS_DIR" -name "*.log" -mtime +7 -not -name "*.gz" -exec gzip {} \; 2>/dev/null || true
        find "$ALERTS_DIR" -name "*.log" -mtime +7 -not -name "*.gz" -exec gzip {} \; 2>/dev/null || true
    fi

    # Limita número de arquivos (considerando arquivos comprimidos)
    find "$LOGS_DIR" -name "*.log*" -type f -printf '%T@ %p\n' | sort -n | head -n -$max_files | cut -d' ' -f2- | xargs -r rm 2>/dev/null || true
    find "$METRICS_DIR" -name "*.json" -type f -printf '%T@ %p\n' | sort -n | head -n -$max_files | cut -d' ' -f2- | xargs -r rm 2>/dev/null || true

    success "Rotação de logs concluída com compressão"
}

# ==================== FUNÇÕES DE CACHE DE DISCO ====================

# Implementa estratégias de cache de disco
setup_disk_cache() {
    local cache_dir="$HOME/.cache/cluster-ai"
    local cache_size_gb=10
    local cleanup_threshold=80  # % de uso para limpeza

    subsection "Configurando Cache de Disco"

    # Criar diretório de cache
    mkdir -p "$cache_dir/metrics" "$cache_dir/logs" "$cache_dir/temp"

    # Configurar cache de métricas
    if [ ! -f "$cache_dir/cache.conf" ]; then
        cat > "$cache_dir/cache.conf" << EOF
CACHE_DIR=$cache_dir
CACHE_SIZE_GB=$cache_size_gb
CLEANUP_THRESHOLD=$cleanup_threshold
METRICS_CACHE_TTL=3600
LOGS_CACHE_TTL=86400
TEMP_CACHE_TTL=1800
EOF
    fi

    # Configurar limpeza automática de cache
    setup_cache_cleanup "$cache_dir" "$cleanup_threshold"

    success "Cache de disco configurado"
}

# Limpeza automática de cache
setup_cache_cleanup() {
    local cache_dir="$1"
    local threshold="$2"

    # Verificar uso do disco e limpar se necessário
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

    if [ "$disk_usage" -gt "$threshold" ]; then
        subsection "Limpando Cache de Disco (Uso: ${disk_usage}%)"

        # Limpar arquivos temporários antigos
        find "$cache_dir/temp" -type f -mmin +30 -delete 2>/dev/null || true

        # Limpar métricas antigas
        find "$cache_dir/metrics" -name "*.json" -mmin +60 -delete 2>/dev/null || true

        # Limpar logs antigos do cache
        find "$cache_dir/logs" -name "*.log" -mtime +7 -delete 2>/dev/null || true

        # Limpar cache de build se existir
        if [ -d "$cache_dir/build" ]; then
            find "$cache_dir/build" -name "*.tmp" -mmin +60 -delete 2>/dev/null || true
        fi

        success "Cache limpo automaticamente"
    fi
}

# Cache de métricas para reduzir I/O
cache_metrics() {
    local cache_dir="$HOME/.cache/cluster-ai/metrics"
    local cache_file="$cache_dir/$(date +%Y%m%d_%H).json"

    # Salvar métricas em cache
    mkdir -p "$cache_dir"

    cat > "$cache_file" << EOF
{
  "timestamp": "$(date +%s)",
  "cpu": ${CPU_METRICS["usage"]:-0},
  "memory": ${MEMORY_METRICS["usage_percent"]:-0},
  "disk": ${DISK_METRICS["usage_percent"]:-0},
  "network_rx": ${NETWORK_METRICS["rx_mb"]:-0},
  "network_tx": ${NETWORK_METRICS["tx_mb"]:-0}
}
EOF
}

# Cache de logs para reduzir escrita em disco
cache_logs() {
    local cache_dir="$HOME/.cache/cluster-ai/logs"
    local cache_file="$cache_dir/$(date +%Y%m%d).log"

    mkdir -p "$cache_dir"

    # Adicionar entrada ao cache de logs
    echo "[$(date)] CPU: ${CPU_METRICS["usage"]:-0}% | MEM: ${MEMORY_METRICS["usage_percent"]:-0}% | DISK: ${DISK_METRICS["usage_percent"]:-0}%" >> "$cache_file"
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
                collect_disk_io_metrics
                collect_network_metrics
                collect_cluster_metrics
                collect_android_metrics

                # Verificar alertas
                check_cpu_alerts
                check_memory_alerts
                check_disk_alerts
                check_disk_io_alerts
                check_battery_alerts

                # Salvar métricas
                generate_metrics_report

                # Cache de métricas e logs para reduzir I/O
                cache_metrics
                cache_logs

                # Configurar cache de disco na primeira execução
                if [ ! -f "$HOME/.cache/cluster-ai/.initialized" ]; then
                    setup_disk_cache
                    touch "$HOME/.cache/cluster-ai/.initialized"
                fi

                # Limpeza automática de cache
                setup_cache_cleanup "$HOME/.cache/cluster-ai" 80

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
