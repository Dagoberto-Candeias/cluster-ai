#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funções de log
success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $message"
    if [ -n "$CLUSTER_AI_LOG_FILE" ] && [ -w "$(dirname "$CLUSTER_AI_LOG_FILE")" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $message" >> "$CLUSTER_AI_LOG_FILE"
    fi
}

log() {
    local message="$1"
    echo -e "${GREEN}[INFO]${NC} $message"
    if [ -n "$CLUSTER_AI_LOG_FILE" ] && [ -w "$(dirname "$CLUSTER_AI_LOG_FILE")" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]    $message" >> "$CLUSTER_AI_LOG_FILE"
    fi
}

warn() {
    local message="$1"
    echo -e "${YELLOW}[WARN]${NC} $message"
    if [ -n "$CLUSTER_AI_LOG_FILE" ] && [ -w "$(dirname "$CLUSTER_AI_LOG_FILE")" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN]    $message" >> "$CLUSTER_AI_LOG_FILE"
    fi
}

fail() {
    local message="$1"
    echo -e "${RED}[FAIL]${NC} $message" >&2
    if [ -n "$CLUSTER_AI_LOG_FILE" ] && [ -w "$(dirname "$CLUSTER_AI_LOG_FILE")" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [FAIL]    $message" >> "$CLUSTER_AI_LOG_FILE"
    fi
}

error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message" >&2
    if [ -n "$CLUSTER_AI_LOG_FILE" ] && [ -w "$(dirname "$CLUSTER_AI_LOG_FILE")" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR]   $message" >> "$CLUSTER_AI_LOG_FILE"
    fi
}

# Funções de formatação de output
section() {
    local message="$1"
    echo -e "\n${BLUE}=== $message ===${NC}"
    if [ -n "$CLUSTER_AI_LOG_FILE" ] && [ -w "$(dirname "$CLUSTER_AI_LOG_FILE")" ]; then
        echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] [SECTION] === $message ===" >> "$CLUSTER_AI_LOG_FILE"
    fi
}

subsection() {
    local message="$1"
    echo -e "\n${CYAN}➤ $message${NC}"
}

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para verificar se um serviço está ativo
service_active() {
    systemctl is-active --quiet "$1"
}

# Função de validação de caminhos seguros
safe_path_check() {
    local path="$1"
    local operation="${2:-"operação de arquivo"}"

    if [ -z "$path" ]; then
        error "ERRO CRÍTICO: Caminho vazio fornecido para a $operation."
        return 1
    fi

    # Resolve o caminho absoluto para uma verificação mais segura
    local resolved_path
    resolved_path=$(realpath -m "$path")

    if [ "$resolved_path" = "/" ]; then
        error "ERRO CRÍTICO: Tentativa de $operation no diretório raiz (/). Operação abortada."
        return 1
    fi

    local critical_dirs=("/bin" "/boot" "/dev" "/etc" "/lib" "/lib64" "/proc" "/root" "/run" "/sbin" "/sys" "/usr" "/var")
    for dir in "${critical_dirs[@]}"; do
        # Verifica se o caminho é exatamente um diretório crítico ou um subdiretório dele
        if [[ "$resolved_path" == "$dir" || "$resolved_path" == "$dir/"* ]]; then
            # Permite operações em subdiretórios específicos e seguros, como /var/log
            if [[ "$resolved_path" == "/var/log"* ]]; then
                continue
            fi
            error "ERRO CRÍTICO: Tentativa de $operation em um diretório de sistema protegido ($resolved_path). Operação abortada."
            return 1
        fi
    done

    return 0
}

# Função para solicitar confirmação do usuário
confirm_operation() {
    local message="$1"
    read -p "$(echo -e "${YELLOW}AVISO:${NC} $message Deseja continuar? (s/N) ")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        return 0
    else
        return 1
    fi
}