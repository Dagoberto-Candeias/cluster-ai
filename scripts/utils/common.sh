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
    if [ -n "${CLUSTER_AI_LOG_FILE:-}" ] && [ -w "$(dirname "$CLUSTER_AI_LOG_FILE")" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $message" >> "$CLUSTER_AI_LOG_FILE"
    fi
}

log() {
    local message="$1"
    echo -e "${GREEN}[INFO]${NC} $message"
    if [ -n "${CLUSTER_AI_LOG_FILE:-}" ] && [ -w "$(dirname "$CLUSTER_AI_LOG_FILE")" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO]    $message" >> "$CLUSTER_AI_LOG_FILE"
    fi
}

warn() {
    local message="$1"
    echo -e "${YELLOW}[WARN]${NC} $message"
    if [ -n "${CLUSTER_AI_LOG_FILE:-}" ] && [ -w "$(dirname "$CLUSTER_AI_LOG_FILE")" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN]    $message" >> "$CLUSTER_AI_LOG_FILE"
    fi
}

fail() {
    local message="$1"
    echo -e "${RED}[FAIL]${NC} $message" >&2
    if [ -n "${CLUSTER_AI_LOG_FILE:-}" ] && [ -w "$(dirname "$CLUSTER_AI_LOG_FILE")" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [FAIL]    $message" >> "$CLUSTER_AI_LOG_FILE"
    fi
}

error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message" >&2
    if [ -n "${CLUSTER_AI_LOG_FILE:-}" ] && [ -w "$(dirname "$CLUSTER_AI_LOG_FILE")" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR]   $message" >> "$CLUSTER_AI_LOG_FILE"
    fi
}

# Funções de formatação de output
section() {
    local message="$1"
    echo -e "\n${BLUE}=== $message ===${NC}"
    if [ -n "${CLUSTER_AI_LOG_FILE:-}" ] && [ -w "$(dirname "$CLUSTER_AI_LOG_FILE")" ]; then
        echo -e "\n[$(date '+%Y-%m-%d %H:%M:%S')] [SECTION] === $message ===" >> "$CLUSTER_AI_LOG_FILE"
    fi
}

subsection() {
    local message="$1"
    echo -e "\n${CYAN}➤ $message${NC}"
}

# Função para detectar sistema operacional
detect_os() {
    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
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

    # Verificar se o caminho está vazio ou contém apenas espaços
    if [ -z "$path" ] || [[ "$path" =~ ^[[:space:]]*$ ]]; then
        error "ERRO CRÍTICO: Caminho vazio fornecido para a $operation."
        return 1
    fi

    # Remover espaços do início e fim do caminho
    path=$(echo "$path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    # Resolver o caminho absoluto para uma verificação mais segura
    local resolved_path
    if command_exists realpath; then
        resolved_path=$(realpath -m "$path" 2>/dev/null)
    else
        # Fallback para sistemas sem realpath
        resolved_path=$(readlink -m "$path" 2>/dev/null || echo "$path")
    fi

    # Verificar se o caminho resolvido é válido
    if [ -z "$resolved_path" ]; then
        error "ERRO CRÍTICO: Caminho inválido fornecido para a $operation."
        return 1
    fi

    # Verificar se é exatamente o diretório raiz
    if [ "$resolved_path" = "/" ]; then
        error "ERRO CRÍTICO: Tentativa de $operation no diretório raiz (/). Operação abortada."
        return 1
    fi

    # Lista de diretórios críticos do sistema
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

# ==================== FUNÇÕES DE VALIDAÇÃO E SEGURANÇA ====================

# Função para validar endereço IP
validate_ip() {
    local ip="$1"
    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        # Verificar se cada octeto está entre 0-255
        local IFS='.'
        read -ra octets <<< "$ip"
        for octet in "${octets[@]}"; do
            if (( octet < 0 || octet > 255 )); then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# Função para validar hostname
validate_hostname() {
    local hostname="$1"
    # Regex para hostname válido (RFC 1123)
    if [[ $hostname =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    fi
    return 1
}

# Função para validar nome de usuário (sem caracteres especiais perigosos)
validate_username() {
    local username="$1"
    # Permitir apenas letras, números, underscore e hífen
    if [[ $username =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 0
    fi
    return 1
}

# Função para sanitizar entrada de usuário (remover caracteres perigosos)
sanitize_input() {
    local input="$1"
    # Remover caracteres de controle, pipes, ponto-e-vírgula, etc.
    echo "$input" | sed 's/[;&|`$()<>]//g' | tr -d '\n\r\t'
}

# Função para validar porta SSH
validate_port() {
    local port="$1"
    if [[ $port =~ ^[0-9]+$ ]] && (( port >= 1 && port <= 65535 )); then
        return 0
    fi
    return 1
}

# Função para validar caminho de arquivo (prevenção de path traversal)
validate_file_path() {
    local path="$1"
    # Verificar se não contém ".." ou começa com "/"
    if [[ $path == *".. "* ]] || [[ $path == /* ]]; then
        return 1
    fi
    return 0
}

# Função para log de auditoria de segurança
security_audit_log() {
    local action="$1"
    local details="$2"
    local user="${USER:-unknown}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [ -n "${CLUSTER_AI_LOG_FILE:-}" ] && [ -w "$(dirname "$CLUSTER_AI_LOG_FILE")" ]; then
        echo "[$timestamp] [SECURITY] [USER:$user] [ACTION:$action] $details" >> "$CLUSTER_AI_LOG_FILE"
    fi
}

# Função para verificar se está rodando como root (com mensagem customizada)
check_root_user() {
    local script_name="${1:-script}"
    if [ "$EUID" -eq 0 ]; then
        error "ERRO DE SEGURANÇA: $script_name não deve ser executado como root (sudo)."
        log "Execute como usuário normal para maior segurança."
        security_audit_log "ROOT_EXECUTION_ATTEMPT" "Script: $script_name"
        return 1
    fi
    return 0
}
