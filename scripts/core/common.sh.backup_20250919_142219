#!/bin/bash
# =============================================================================
# Cluster AI - Funções Comuns e Utilitários
# =============================================================================
# Este arquivo contém funções utilitárias compartilhadas por todos os módulos
# do sistema Cluster AI.

set -euo pipefail

# =============================================================================
# CONFIGURAÇÃO GLOBAL
# =============================================================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Diretórios importantes
if [[ -z "${PROJECT_ROOT:-}" ]]; then
  # Garante que o caminho seja resolvido corretamente, não importa como o script é chamado.
  PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
fi
CONFIG_FILE="${PROJECT_ROOT}/cluster.yaml"
LOGS_DIR="${PROJECT_ROOT}/logs"
RUN_DIR="${PROJECT_ROOT}/run"
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"

# =============================================================================
# FUNÇÕES DE LOGGING PADRONIZADO
# =============================================================================

# Função de log com timestamp e nível
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${CYAN}[$timestamp] [$level] $message${NC}" >&2
}

# Funções de log específicas
info() {
    log "INFO" "$1"
}

success() {
    log "SUCCESS" "$1"
}

warn() {
    log "WARN" "$1"
}

error() {
    log "ERROR" "$1"
}

debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        log "DEBUG" "$1"
    fi
}

# =============================================================================
# FUNÇÕES DE VALIDAÇÃO DE SISTEMA
# =============================================================================

# Verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detectar sistema operacional
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Detectar distribuição Linux
detect_linux_distro() {
    if command_exists lsb_release; then
        lsb_release -si
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    elif [[ -f /etc/redhat-release ]]; then
        echo "rhel"
    else
        echo "unknown"
    fi
}

# Detectar arquitetura
detect_arch() {
    uname -m
}

# Detectar gerenciador de pacotes
detect_package_manager() {
    if command_exists apt; then
        echo "apt install -y"
    elif command_exists yum; then
        echo "yum install -y"
    elif command_exists dnf; then
        echo "dnf install -y"
    elif command_exists pacman; then
        echo "pacman -S --noconfirm"
    elif command_exists zypper; then
        echo "zypper install -y"
    elif command_exists brew; then
        echo "brew install"
    else
        echo ""
    fi
}

# Obter número de CPUs
get_cpu_count() {
    if command_exists nproc; then
        nproc
    else
        echo "1"
    fi
}

# =============================================================================
# FUNÇÕES DE MANIPULAÇÃO DE ARQUIVOS
# =============================================================================

# Verificar se arquivo existe e é legível
file_exists() {
    [[ -f "$1" && -r "$1" ]]
}

# Verificar se diretório existe
dir_exists() {
    [[ -d "$1" ]]
}

# Criar diretório se não existir
ensure_dir() {
    local dir="$1"
    if ! dir_exists "$dir"; then
        mkdir -p "$dir" || {
            error "Falha ao criar diretório: $dir"
            return 1
        }
    fi
}

# Criar arquivo se não existir
ensure_file() {
    local file="$1"
    local content="${2:-}"

    if ! file_exists "$file"; then
        ensure_dir "$(dirname "$file")"
        echo "$content" > "$file" || {
            error "Falha ao criar arquivo: $file"
            return 1
        }
    fi
}

# Backup de arquivo
backup_file() {
    local file="$1"
    local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"

    if file_exists "$file"; then
        cp "$file" "$backup" || {
            error "Falha ao criar backup: $backup"
            return 1
        }
        info "Backup criado: $backup"
    fi
}

# =============================================================================
# FUNÇÕES DE PROCESSOS
# =============================================================================

# Verificar se processo está rodando
process_running() {
    local pid="$1"
    [[ -n "$pid" ]] && ps -p "$pid" > /dev/null 2>&1
}

# Obter PID de processo por nome
get_pid_by_name() {
    local name="$1"
    pgrep -f "$name" 2>/dev/null | head -1
}

# Matar processo graciosamente
kill_process() {
    local pid="$1"
    local signal="${2:-TERM}"

    if process_running "$pid"; then
        kill -"$signal" "$pid" 2>/dev/null || true
        sleep 2

        # Forçar kill se ainda estiver rodando
        if process_running "$pid"; then
            kill -KILL "$pid" 2>/dev/null || true
            sleep 1
        fi
    fi
}

# =============================================================================
# FUNÇÕES DE REDE
# =============================================================================

# Testar conectividade de rede
test_connectivity() {
    local host="$1"
    local port="${2:-80}"
    local timeout="${3:-5}"

    timeout "$timeout" bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null
}

# Obter IP local
get_local_ip() {
    hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1"
}

# Resolver hostname para IP
resolve_hostname() {
    local hostname="$1"
    getent hosts "$hostname" 2>/dev/null | awk '{print $1}' || echo ""
}

# =============================================================================
# FUNÇÕES DE FORMATAÇÃO
# =============================================================================

# Centralizar texto
center_text() {
    local text="$1"
    local width="${2:-80}"
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%*s%s%*s\n" $padding "" "$text" $padding ""
}

# Criar linha separadora
separator() {
    local char="${1:--}"
    local width="${2:-80}"
    printf '%*s\n' "$width" '' | tr ' ' "$char"
}

# =============================================================================
# FUNÇÕES DE PROGRESSO
# =============================================================================

# Barra de progresso simples
progress_bar() {
    local current="$1"
    local total="$2"
    local width="${3:-50}"
    local char="${4:-#}"

    local percentage=$(( current * 100 / total ))
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))

    printf "\r[%-${width}s] %d%%" "$(printf "${char}%.0s" $(seq 1 $filled))" "$percentage"
}

# Spinner de carregamento
spinner() {
    local pid="$1"
    local message="${2:-Processando...}"

    local spin_chars="/-\|"
    local i=0

    while process_running "$pid"; do
        printf "\r%s %s" "${spin_chars:i%4:1}" "$message"
        sleep 0.1
        ((i++))
    done

    printf "\r%s\n" "$(printf ' %.0s' {1..50})" # Limpar linha
}

# Função de progresso simples (compatibilidade com manager.sh)
progress() {
    info "[...] $1"
}

# =============================================================================
# FUNÇÕES DE VALIDAÇÃO DE ENTRADA
# =============================================================================

# Validar se é número
is_number() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

# Validar se é IP válido
is_valid_ip() {
    local ip="$1"
    [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && {
        IFS='.' read -ra octets <<< "$ip"
        for octet in "${octets[@]}"; do
            (( octet >= 0 && octet <= 255 ))
        done
    }
}

# Validar se é hostname válido
is_valid_hostname() {
    local hostname="$1"
    [[ "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?$ ]] && \
    [[ ! "$hostname" =~ \.\. ]] && \
    [[ ! "$hostname" =~ ^[-.] ]] && \
    [[ ! "$hostname" =~ [-.]$ ]]
}

# =============================================================================
# FUNÇÕES DE TEMPO
# =============================================================================

# Converter segundos para formato legível
format_duration() {
    local seconds="$1"
    local hours=$(( seconds / 3600 ))
    local minutes=$(( (seconds % 3600) / 60 ))
    local secs=$(( seconds % 60 ))

    if (( hours > 0 )); then
        printf "%dh%dm%ds" $hours $minutes $secs
    elif (( minutes > 0 )); then
        printf "%dm%ds" $minutes $secs
    else
        printf "%ds" $secs
    fi
}

# Timestamp atual
current_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Timestamp para arquivos
file_timestamp() {
    date '+%Y%m%d_%H%M%S'
}

# =============================================================================
# FUNÇÕES DE LIMPEZA
# =============================================================================

# Limpar arquivos temporários
cleanup_temp_files() {
    local temp_dir="${1:-/tmp}"
    local pattern="${2:-cluster_ai_*}"
    local max_age="${3:-7}" # dias

    find "$temp_dir" -name "$pattern" -type f -mtime +$max_age -delete 2>/dev/null || true
}

# Limpar logs antigos
cleanup_old_logs() {
    local log_dir="$1"
    local max_age="${2:-30}" # dias
    local max_size="${3:-100}" # MB

    if dir_exists "$log_dir"; then
        # Remover logs antigos
        find "$log_dir" -name "*.log" -type f -mtime +$max_age -delete 2>/dev/null || true

        # Comprimir logs grandes
        find "$log_dir" -name "*.log" -type f -size +${max_size}M -exec gzip {} \; 2>/dev/null || true
    fi
}

# =============================================================================
# INICIALIZAÇÃO
# =============================================================================

# Inicializar ambiente
init_environment() {
    # Criar diretórios necessários
    ensure_dir "$LOGS_DIR"
    ensure_dir "$RUN_DIR"

    # Configurar umask para segurança
    umask 0027

    # Exportar variáveis globais
    export PROJECT_ROOT
    export CONFIG_FILE
    export LOGS_DIR
    export RUN_DIR
    export SCRIPTS_DIR
}

# Verificar dependências essenciais
check_dependencies() {
    local deps=("bash" "grep" "sed" "awk" "find" "ps" "kill")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        error "Dependências faltando: ${missing[*]}"
        return 1
    fi

    return 0
}

# =============================================================================
# FINALIZAÇÃO
# =============================================================================

# Cleanup ao sair
cleanup() {
    # Limpar arquivos temporários
    cleanup_temp_files

    # Log de saída
    info "Finalizando módulo common.sh"
}

# Registrar cleanup (apenas se não estiver em modo de teste)
if [[ "${TEST_MODE:-false}" != "true" ]]; then
    trap cleanup EXIT
fi

# Inicializar se executado diretamente (apenas se não estiver em modo de teste)
if [[ "${BASH_SOURCE[0]}" == "${0}" && "${TEST_MODE:-false}" != "true" ]]; then
    init_environment
    check_dependencies || exit 1
    info "Módulo common.sh carregado com sucesso"
fi
