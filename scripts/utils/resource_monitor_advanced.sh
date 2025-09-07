#!/bin/bash
# Script avançado para monitorar recursos do sistema e otimizar workers do Cluster AI
# Inclui auto-healing inteligente, otimização de recursos e limpeza automática

# Carregar funções comuns se disponíveis
COMMON_SCRIPT_PATH="$(dirname "${BASH_SOURCE[0]}")/common.sh"
if [ -f "$COMMON_SCRIPT_PATH" ]; then
    # shellcheck source=./common.sh
    source "$COMMON_SCRIPT_PATH"
else
    # Fallback para cores e logs se common.sh não for encontrado
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m'
    error() { echo -e "${RED}[ERROR]${NC} $1"; }
    warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
    log() { echo -e "${GREEN}[INFO]${NC} $1"; }
    success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
    section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
fi

# Configurações padrão aprimoradas
DEFAULT_MEM_THRESHOLD=85
DEFAULT_CPU_THRESHOLD="2.0"
DEFAULT_DISK_THRESHOLD=90
DEFAULT_INTERVAL=5
DEFAULT_AUTO_HEALING=true
DEFAULT_WORKER_OPTIMIZATION=true
DEFAULT_CLEANUP=true

# Função de ajuda
show_help() {
    echo "Uso: $0 [opções]"
    echo "Monitor avançado de recursos com otimização automática do Cluster AI."
    echo ""
    echo "Opções:"
    echo "  -m, --mem-threshold PCT    Threshold de memória (%) - padrão: ${DEFAULT_MEM_THRESHOLD}"
    echo "  -c, --cpu-threshold LOAD   Threshold de CPU por núcleo - padrão: ${DEFAULT_CPU_THRESHOLD}"
    echo "  -d, --disk-threshold PCT   Threshold de disco (%) - padrão: ${DEFAULT_DISK_THRESHOLD}"
    echo "  -i, --interval SEC         Intervalo de verificação - padrão: ${DEFAULT_INTERVAL}s"
    echo "  -l, --log-file FILE        Arquivo de log"
    echo "  -e, --email EMAIL          Email para alertas"
    echo "  --no-auto-heal            Desabilitar auto-healing"
    echo "  --no-worker-opt           Desabilitar otimização de workers"
    echo "  --no-cleanup              Desabilitar limpeza automática"
    echo "  -h, --help                Mostrar esta ajuda"
}

# Parse de argumentos
MEM_THRESHOLD=$DEFAULT_MEM_THRESHOLD
CPU_THRESHOLD=$DEFAULT_CPU_THRESHOLD
DISK_THRESHOLD=$DEFAULT_DISK_THRESHOLD
INTERVAL=$DEFAULT_INTERVAL
AUTO_HEALING=$DEFAULT_AUTO_HEALING
WORKER_OPTIMIZATION=$DEFAULT_WORKER_OPTIMIZATION
CLEANUP=$DEFAULT_CLEANUP
LOG_FILE=""
EMAIL_RECIPIENT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--mem-threshold) MEM_THRESHOLD="$2"; shift ;;
        -c|--cpu-threshold) CPU_THRESHOLD="$2"; shift ;;
        -d|--disk-threshold) DISK_THRESHOLD="$2"; shift ;;
        -i|--interval) INTERVAL="$2"; shift ;;
        -l|--log-file) LOG_FILE="$2"; shift ;;
        -e|--email) EMAIL_RECIPIENT="$2"; shift ;;
        --no-auto-heal) AUTO_HEALING=false ;;
        --no-worker-opt) WORKER_OPTIMIZATION=false ;;
        --no-cleanup) CLEANUP=false ;;
        -h|--help) show_help; exit 0 ;;
        *) error "Opção desconhecida: $1"; show_help; exit 1 ;;
    esac
    shift
done

# Validações
if ! [[ "$MEM_THRESHOLD" =~ ^[0-9]+$ ]] || [ "$MEM_THRESHOLD" -gt 100 ]; then
    error "Threshold de memória inválido (1-100)"; exit 1
fi

# Funções de monitoramento
get_memory_usage() { LC_ALL=C free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}'; }
get_cpu_load() {
    local cores=$(nproc 2>/dev/null || echo "1")
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    echo "scale=2; $load / $cores" | bc 2>/dev/null || echo "0"
}
get_disk_usage() { df / 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//'; }

# Auto-healing para serviços
auto_heal_service() {
    local service="$1"
    local check_cmd="$2"
    local restart_cmd="$3"

    if [ "$AUTO_HEALING" = false ]; then return; fi

    if ! eval "$check_cmd" >/dev/null 2>&1; then
        warn "Serviço $service com problemas. Tentando reiniciar..."
        if eval "$restart_cmd" >/dev/null 2>&1; then
            log "✅ Serviço $service reiniciado com sucesso"
            [ -n "$LOG_FILE" ] && echo "[$(date)] [HEAL] $service reiniciado" >> "$LOG_FILE"
        else
            error "❌ Falha ao reiniciar $service"
        fi
    fi
}

# Otimização de workers Dask
optimize_workers() {
    if [ "$WORKER_OPTIMIZATION" = false ]; then return; fi

    local mem_usage=$(get_memory_usage)
    local cpu_load=$(get_cpu_load)

    if [ "$mem_usage" -gt 90 ] || (( $(echo "$cpu_load > 3.0" | bc -l 2>/dev/null || echo "0") )); then
        warn "Recursos altos detectados. Otimizando workers..."

        # Reduzir prioridade dos workers
        pgrep -f "dask-worker" | while read -r pid; do
            if sudo renice 10 "$pid" >/dev/null 2>&1; then
                log "Prioridade do worker PID $pid ajustada"
            fi
        done

        [ -n "$LOG_FILE" ] && echo "[$(date)] [OPTIMIZE] Workers otimizados" >> "$LOG_FILE"
    fi
}

# Limpeza automática
auto_cleanup() {
    if [ "$CLEANUP" = false ]; then return; fi

    local disk_usage=$(get_disk_usage)
    if [ "$disk_usage" -gt 80 ]; then
        warn "Disco cheio. Executando limpeza automática..."

        # Limpar caches
        sudo apt-get clean >/dev/null 2>&1
        sudo apt-get autoclean >/dev/null 2>&1
        pip cache purge >/dev/null 2>&1 2>/dev/null || true

        # Limpar temporários
        sudo find /tmp -type f -atime +7 -delete >/dev/null 2>&1

        log "✅ Limpeza automática concluída"
        [ -n "$LOG_FILE" ] && echo "[$(date)] [CLEANUP] Limpeza executada" >> "$LOG_FILE"
    fi
}

# Sistema de alertas aprimorado
send_alert() {
    local type="$1" value="$2" threshold="$3" unit="$4"
    local message="🚨 ALERTA: $type em ${value}${unit} (limite: ${threshold}${unit})"

    echo -e "\a"
    echo ""
    error "$message"

    # Top processos
    case $type in
        "Memória") ps aux --sort=-%mem | head -6 ;;
        "CPU") ps aux --sort=-%cpu | head -6 ;;
        "Disco") du -sh "$HOME"/* 2>/dev/null | sort -rh | head -5 ;;
    esac

    # Log
    [ -n "$LOG_FILE" ] && echo "[$(date)] ALERTA: $message" >> "$LOG_FILE"

    # Notificações
    command -v notify-send >/dev/null 2>&1 && notify-send -u critical "Alerta de Recursos" "$message"

    # Email
    if [ -n "$EMAIL_RECIPIENT" ]; then
        echo -e "$message\n\nHost: $(hostname)\nData: $(date)" | mail -s "Alerta de Recursos: $type" "$EMAIL_RECIPIENT"
    fi
}

# Loop principal
trap 'echo -e "\n"; log "Monitoramento interrompido."; exit 0' SIGINT

section "🚀 MONITOR AVANÇADO DE RECURSOS - CLUSTER AI"
log "Intervalo: ${INTERVAL}s | Limites: Mem=${MEM_THRESHOLD}% CPU=${CPU_THRESHOLD} Disco=${DISK_THRESHOLD}%"
[ "$AUTO_HEALING" = true ] && log "🔧 Auto-healing: ATIVADO"
[ "$WORKER_OPTIMIZATION" = true ] && log "⚡ Otimização workers: ATIVADO"
[ "$CLEANUP" = true ] && log "🧹 Limpeza automática: ATIVADO"
echo ""

while true; do
    # Coletar métricas
    mem=$(get_memory_usage)
    cpu=$(get_cpu_load)
    disk=$(get_disk_usage)

    # Auto-healing
    auto_heal_service "Ollama" \
        "curl -s http://localhost:11434/api/tags >/dev/null" \
        "sudo systemctl restart ollama"

    auto_heal_service "Docker" \
        "systemctl is-active docker >/dev/null" \
        "sudo systemctl restart docker"

    # Otimizações
    optimize_workers
    auto_cleanup

    # Status em tempo real
    echo -ne "📊 [$(date +%H:%M:%S)] Mem:${mem}% CPU:${cpu} Disk:${disk}% \r"

    # Verificar alertas
    local alert_triggered=false

    if [ "$mem" -ge "$MEM_THRESHOLD" ]; then
        send_alert "Memória" "$mem" "$MEM_THRESHOLD" "%"
        alert_triggered=true
    fi

    if (( $(echo "$cpu >= $CPU_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        send_alert "CPU" "$cpu" "$CPU_THRESHOLD" ""
        alert_triggered=true
    fi

    if [ "$disk" -ge "$DISK_THRESHOLD" ]; then
        send_alert "Disco" "$disk" "$DISK_THRESHOLD" "%"
        alert_triggered=true
    fi

    # Intervalo ajustado
    if [ "$alert_triggered" = true ]; then
        sleep $((INTERVAL * 3))
    else
        sleep "$INTERVAL"
    fi
done
