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

# Configurações padrão
MEM_THRESHOLD=85
CPU_THRESHOLD="2.0"
DISK_THRESHOLD=90
INTERVAL=5
AUTO_HEALING=true
WORKER_OPTIMIZATION=true
CLEANUP=true

# Funções de monitoramento
get_memory_usage() { LC_ALL=C free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}'; }
get_cpu_load() {
    local cores=$(nproc 2>/dev/null || echo "1")
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    echo "scale=2; $load / $cores" | bc 2>/dev/null || echo "0"
}
get_disk_usage() { df / 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//'; }

# Sistema de alertas
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
}

# Loop principal
trap 'echo -e "\n"; log "Monitoramento interrompido."; exit 0' SIGINT

section "🚀 MONITOR AVANÇADO DE RECURSOS - CLUSTER AI"
log "Intervalo: ${INTERVAL}s | Limites: Mem=${MEM_THRESHOLD}% CPU=${CPU_THRESHOLD} Disco=${DISK_THRESHOLD}%"
echo ""

while true; do
    # Coletar métricas
    mem=$(get_memory_usage)
    cpu=$(get_cpu_load)
    disk=$(get_disk_usage)

    # Status em tempo real
    echo -ne "📊 [$(date +%H:%M:%S)] Mem:${mem}% CPU:${cpu} Disk:${disk}% \r"

    # Verificar alertas
    alert_triggered=false

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

    # Intervalo
    if [ "$alert_triggered" = true ]; then
        sleep $((INTERVAL * 3))
    else
        sleep "$INTERVAL"
    fi
done
