#!/bin/bash
# Script para monitorar o uso de memória e CPU em tempo real e alertar o usuário.

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
    section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
fi

# Configurações padrão
DEFAULT_MEM_THRESHOLD=85
DEFAULT_CPU_THRESHOLD="2.0"
DEFAULT_DISK_THRESHOLD=90
DEFAULT_INTERVAL=5 # em segundos

# Função de ajuda
show_help() {
    echo "Uso: $0 [-m MEM_THRESHOLD] [-c CPU_THRESHOLD] [-d DISK_THRESHOLD] [-i INTERVAL] [-l LOG_FILE]"
    echo "Monitora o uso de memória, CPU e disco em tempo real."
    echo ""
    echo "Opções:"
    echo "  -m, --mem-threshold   Percentual de uso de memória para disparar o alerta (padrão: ${DEFAULT_MEM_THRESHOLD}%)"
    echo "  -c, --cpu-threshold   Carga média de CPU por núcleo para disparar o alerta (padrão: ${DEFAULT_CPU_THRESHOLD})"
    echo "  -d, --disk-threshold  Percentual de uso de disco para disparar o alerta (padrão: ${DEFAULT_DISK_THRESHOLD}%)"
    echo "  -i, --interval    Intervalo de verificação em segundos (padrão: ${DEFAULT_INTERVAL}s)"
    echo "  -l, --log-file      Arquivo para registrar os alertas."
    echo "  -h, --help        Mostrar esta ajuda"
}

# Parse de argumentos da linha de comando
MEM_THRESHOLD=$DEFAULT_MEM_THRESHOLD
CPU_THRESHOLD=$DEFAULT_CPU_THRESHOLD
DISK_THRESHOLD=$DEFAULT_DISK_THRESHOLD
LOG_FILE=""
INTERVAL=$DEFAULT_INTERVAL

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -m|--mem-threshold) MEM_THRESHOLD="$2"; shift ;;
        -c|--cpu-threshold) CPU_THRESHOLD="$2"; shift ;;
        -l|--log-file) LOG_FILE="$2"; shift ;;
        -i|--interval) INTERVAL="$2"; shift ;;
        -d|--disk-threshold) DISK_THRESHOLD="$2"; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Opção desconhecida: $1"; show_help; exit 1 ;;
    esac
    shift
done

# Validar se o diretório do arquivo de log existe e é gravável
if [ -n "$LOG_FILE" ]; then
    LOG_DIR=$(dirname "$LOG_FILE")
    if [ ! -d "$LOG_DIR" ] || [ ! -w "$LOG_DIR" ]; then
        error "Diretório do arquivo de log não existe ou não tem permissão de escrita: $LOG_DIR"
        exit 1
    fi
fi

# Validar thresholds
if ! [[ "$MEM_THRESHOLD" =~ ^[0-9]+$ ]] || [ "$MEM_THRESHOLD" -gt 100 ] || [ "$MEM_THRESHOLD" -lt 1 ]; then
    error "Threshold de memória inválido. Deve ser um número entre 1 e 100."
    exit 1
fi
if ! [[ "$CPU_THRESHOLD" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    error "Threshold de CPU inválido. Deve ser um número (ex: 2.0)."
    exit 1
fi
if ! [[ "$DISK_THRESHOLD" =~ ^[0-9]+$ ]] || [ "$DISK_THRESHOLD" -gt 100 ] || [ "$DISK_THRESHOLD" -lt 1 ]; then
    error "Threshold de disco inválido. Deve ser um número entre 1 e 100."
    exit 1
fi

# Verificar se 'bc' está instalado, pois é necessário para cálculos de float
if ! command -v bc &> /dev/null; then
    error "Comando 'bc' não encontrado. É necessário para cálculos de CPU."
    echo "   💡 Execute: sudo apt-get install bc"
    exit 1
fi

# Função para capturar o uso de memória
get_memory_usage() {
    # Usar LC_ALL=C para garantir que a saída de 'free' seja padronizada
    # Calcula (used / total) * 100
    LC_ALL=C free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}'
}

# Função para capturar a carga da CPU por núcleo
get_cpu_load() {
    # Get number of cores
    local cpu_cores
    cpu_cores=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "1")
    # Get 1-minute load average
    local cpu_load
    cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    # Calculate load per core using bc
    local cpu_load_per_core
    cpu_load_per_core=$(echo "scale=2; $cpu_load / $cpu_cores" | bc)
    echo "$cpu_load_per_core"
}

# Função para capturar o uso de disco
get_disk_usage() {
    # df no diretório raiz, pega a segunda linha, quinta coluna e remove o '%'
    # Compatível com Linux e macOS
    df / 2>/dev/null | awk 'NR==2 {print $5}' | sed 's/%//'
}

# Função para enviar alerta
send_alert() {
    local type="$1" # "Memória", "CPU" ou "Disco"
    local value="$2"
    local threshold="$3"
    local unit="$4" # "%" or "/núcleo"
    local message="Uso de ${type} atingiu ${value}${unit} (Limite: ${threshold}${unit})"

    # Alerta no terminal com som (bell)
    echo -e "\a"
    # Adiciona uma nova linha para não sobrescrever a linha de status
    echo ""
    error "ALERTA DE RECURSOS! ${message}"

    local top_processes_header=""
    local top_processes_data=""

    # Se o alerta for de memória, mostrar os 5 processos que mais consomem
    if [ "$type" = "Memória" ]; then
        top_processes_header="Top 5 processos por uso de memória:"
        warn "$top_processes_header"
        # O comando 'ps' lista os processos, '--sort=-%mem' ordena por memória decrescente,
        # e 'head -n 6' pega o cabeçalho e as 5 primeiras linhas.
        top_processes_data=$(ps aux --sort=-%mem | head -n 6)
        echo "$top_processes_data" | while IFS= read -r line; do echo -e "   ${YELLOW}$line${NC}"; done
    elif [ "$type" = "CPU" ]; then
        top_processes_header="Top 5 processos por uso de CPU:"
        warn "$top_processes_header"
        top_processes_data=$(ps aux --sort=-%cpu | head -n 6)
        echo "$top_processes_data" | while IFS= read -r line; do echo -e "   ${YELLOW}$line${NC}"; done
    fi

    # Registrar no arquivo de log, se especificado
    if [ -n "$LOG_FILE" ]; then
        {
            echo "---"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERTA: $message"
            [ -n "$top_processes_data" ] && echo "$top_processes_header" && echo "$top_processes_data"
            echo "---"
        } >> "$LOG_FILE"
    fi

    # Alerta de desktop (se disponível)
    if command -v notify-send &> /dev/null; then
        notify-send -u critical "Alerta Crítico de Recursos" "$message"
    fi
}

# Função para lidar com a interrupção (Ctrl+C)
cleanup() {
    echo -e "\n" # Nova linha para não sobrescrever a última linha de status
    log "Monitoramento de recursos interrompido pelo usuário."
    exit 0
}

# Capturar o sinal de interrupção
trap cleanup SIGINT

# Início do monitoramento
section "MONITOR DE RECURSOS EM TEMPO REAL"
log "Pressione Ctrl+C para parar."
log "Limites: Memória: ${MEM_THRESHOLD}% | CPU: ${CPU_THRESHOLD}/núcleo | Disco: ${DISK_THRESHOLD}%"
if [ -n "$LOG_FILE" ]; then
    log "Registrando alertas em: $LOG_FILE"
fi
log "Intervalo de verificação: ${INTERVAL} segundos"
echo ""

# Loop principal de monitoramento
while true; do
    mem_usage=$(get_memory_usage)
    cpu_load=$(get_cpu_load)
    disk_usage=$(get_disk_usage)

    # Atualiza a linha de status
    echo -ne "Status [$(date '+%H:%M:%S')] | Memória: ${mem_usage}% | CPU: ${cpu_load}/núcleo | Disco: ${disk_usage}% \r"

    alert_triggered=false

    # Verificar alerta de memória
    if [ "$mem_usage" -ge "$MEM_THRESHOLD" ]; then
        send_alert "Memória" "$mem_usage" "$MEM_THRESHOLD" "%"
        alert_triggered=true
    fi

    # Verificar alerta de CPU
    # Usamos 'bc' para comparar números de ponto flutuante
    if (( $(echo "$cpu_load >= $CPU_THRESHOLD" | bc -l) )); then
        send_alert "CPU" "$cpu_load" "$CPU_THRESHOLD" "/núcleo"
        alert_triggered=true
    fi

    # Verificar alerta de disco
    if [ "$disk_usage" -ge "$DISK_THRESHOLD" ]; then
        send_alert "Disco" "$disk_usage" "$DISK_THRESHOLD" "%"
        alert_triggered=true
    fi

    # Se um alerta foi disparado, espera um pouco mais antes da próxima verificação
    if [ "$alert_triggered" = true ]; then
        sleep $((INTERVAL * 3))
    else
        sleep "$INTERVAL"
    fi
done