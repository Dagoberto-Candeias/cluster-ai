#!/bin/bash
# =============================================================================
# Biblioteca de Funções Comuns - Cluster AI
# =============================================================================
# Este arquivo contém funções utilitárias compartilhadas entre todos os scripts
# do projeto Cluster AI. Substitui a biblioteca comum anterior.
#
# Autor: Cluster AI Team
# Data: 2025-01-27
# Versão: 2.0.0
# Arquivo: common_functions.sh
# =============================================================================

# Prevenir execução direta
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Este arquivo deve ser carregado com 'source', não executado diretamente."
    exit 1
fi

# =============================================================================
# CONFIGURAÇÕES GLOBAIS
# =============================================================================

# Cores para output
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export PURPLE='\033[0;35m'
export BOLD='\033[1m'
export NC='\033[0m' # No Color

# Configurações de log
export LOG_LEVEL="${LOG_LEVEL:-INFO}"
export LOG_FORMAT="${LOG_FORMAT:-timestamp}"

# Diretórios padrão
if [ -z "$PROJECT_ROOT" ]; then
    export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
export LOG_DIR="${PROJECT_ROOT}/logs"
export CONFIG_DIR="${PROJECT_ROOT}/config"
export SCRIPTS_DIR="${PROJECT_ROOT}/scripts"

# Criar diretórios necessários
mkdir -p "$LOG_DIR" "$CONFIG_DIR"

# =============================================================================
# FUNÇÕES DE OUTPUT E LOGGING
# =============================================================================

# Função para log com timestamp
log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ "$LOG_FORMAT" == "timestamp" ]]; then
        echo "[$timestamp] [$level] $message" >> "${LOG_DIR}/cluster_ai.log"
    else
        echo "[$level] $message" >> "${LOG_DIR}/cluster_ai.log"
    fi
}

# Gerar senha segura com tamanho especificado
generate_secure_password() {
    local length="${1:-16}"
    # Tentar com openssl
    if command -v openssl >/dev/null 2>&1; then
        # Gera bytes aleatórios, codifica, remove caracteres indesejados e corta no tamanho
        local pw
        pw=$(openssl rand -base64 $((length*2)) 2>/dev/null | tr -dc 'A-Za-z0-9!@#$%^&*' | head -c "$length") || true
        if [ -n "$pw" ]; then
            echo "$pw"
            return 0
        fi
    fi
    # Fallback para /dev/urandom
    tr -dc 'A-Za-z0-9!@#$%^&*' </dev/urandom | head -c "$length" || true
    echo
}

# Função para exibir seções
section() {
    local title="$1"
    echo -e "\n${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC} ${BOLD}${title}${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    log_message "INFO" "Section: $title"
}

# Função para mensagens de sucesso
success() {
    local message="$1"
    echo -e "${GREEN}✓${NC} $message"
    log_message "SUCCESS" "$message"
}

# Função para mensagens de erro
error() {
    local message="$1"
    echo -e "${RED}✗${NC} $message" >&2
    log_message "ERROR" "$message"
}

# Função para mensagens de aviso
warn() {
    local message="$1"
    echo -e "${YELLOW}⚠${NC} $message"
    log_message "WARN" "$message"
}

# Função para mensagens informativas
info() {
    local message="$1"
    echo -e "${CYAN}ℹ${NC} $message"
    log_message "INFO" "$message"
}

# Função para debug (só exibe se DEBUG=1)
debug() {
    local message="$1"
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${PURPLE}🐛${NC} $message"
        log_message "DEBUG" "$message"
    fi
}

# =============================================================================
# FUNÇÕES DE VALIDAÇÃO
# =============================================================================

# Verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validar entrada do usuário
validate_input() {
    local type="$1"
    local value="$2"
    
    case "$type" in
        "ip")
            if [[ "$value" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                return 0
            else
                return 1
            fi
            ;;
        "port")
            if [[ "$value" =~ ^[0-9]+$ ]] && [ "$value" -ge 1 ] && [ "$value" -le 65535 ]; then
                return 0
            else
                return 1
            fi
            ;;
        "email")
            if [[ "$value" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
                return 0
            else
                return 1
            fi
            ;;
        "worker_id")
            if [[ "$value" =~ ^[a-zA-Z0-9_-]{1,50}$ ]]; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            error "Tipo de validação desconhecido: $type"
            return 1
            ;;
    esac
}

# Funções de validação legadas
validate_worker_id() {
    local value="$1"
    validate_input "worker_id" "$value"
}

# Validação de nomes de modelos Ollama
# Permite letras, números, hífens, underscores, pontos e dois-pontos (para tag), até 100 chars
validate_model_name() {
    local name="$1"
    # vazio ou muito longo
    if [ -z "$name" ] || [ ${#name} -gt 100 ]; then
        return 1
    fi
    # caracteres inválidos
    if [[ ! "$name" =~ ^[a-zA-Z0-9._:-]+$ ]]; then
        return 1
    fi
    # não permitir espaços ou caracteres perigosos já filtrados acima
    return 0
}

# Validar se arquivo existe e é legível
validate_file() {
    local file="$1"
    if [ -f "$file" ] && [ -r "$file" ]; then
        return 0
    else
        return 1
    fi
}

# Validar se diretório existe e é acessível
validate_directory() {
    local dir="$1"
    if [ -d "$dir" ] && [ -x "$dir" ]; then
        return 0
    else
        return 1
    fi
}

# =============================================================================
# FUNÇÕES DE SISTEMA
# =============================================================================

# Detectar sistema operacional
detect_os() {
    case "$(uname -s)" in
        Linux*)     echo "Linux";;
        Darwin*)    echo "macOS";;
        CYGWIN*)    echo "Windows";;
        MINGW*)     echo "Windows";;
        *)          echo "Unknown";;
    esac
}

# Detectar distribuição Linux
detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$NAME"
    elif [ -f /etc/redhat-release ]; then
        cat /etc/redhat-release
    elif [ -f /etc/debian_version ]; then
        echo "Debian $(cat /etc/debian_version)"
    else
        echo "Unknown Linux"
    fi
}

# Detectar arquitetura
detect_arch() {
    uname -m
}

# Obter IP público
get_public_ip() {
    curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "N/A"
}

# Verificar se é root
is_root() {
    [ "$EUID" -eq 0 ]
}

# =============================================================================
# FUNÇÕES DE CONFIRMAÇÃO E SEGURANÇA
# =============================================================================

# Solicitar confirmação do usuário
confirm() {
    local message="$1"
    local default="${2:-n}"
    
    if [[ "$default" == "y" ]]; then
        local prompt="$message [Y/n]: "
    else
        local prompt="$message [y/N]: "
    fi
    
    read -p "$prompt" -r response
    
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        [nN][oO]|[nN]) return 1 ;;
        "") 
            if [[ "$default" == "y" ]]; then
                return 0
            else
                return 1
            fi
            ;;
        *) 
            warn "Resposta inválida. Tente novamente."
            confirm "$message" "$default"
            ;;
    esac
}

# Confirmação para operações críticas
confirm_critical() {
    local operation="$1"
    local details="${2:-}"
    
    warn "OPERAÇÃO CRÍTICA: $operation"
    if [ -n "$details" ]; then
        echo -e "${YELLOW}Detalhes: $details${NC}"
    fi
    
    echo -e "${RED}Esta operação pode ser irreversível!${NC}"
    
    if ! confirm "Tem certeza que deseja continuar?"; then
        info "Operação cancelada pelo usuário."
        return 1
    fi
    
    # Segunda confirmação para operações muito críticas
    if ! confirm "Confirma novamente? Digite 'sim' para continuar" "n"; then
        info "Operação cancelada na segunda confirmação."
        return 1
    fi
    
    return 0
}

# =============================================================================
# FUNÇÕES DE AUDITORIA
# =============================================================================

# Log de auditoria
audit_log() {
    local action="$1"
    local details="$2"
    local user="${USER:-unknown}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    local audit_file="${LOG_DIR}/audit.log"
    echo "[$timestamp] USER:$user ACTION:$action DETAILS:$details" >> "$audit_file"
}

# =============================================================================
# FUNÇÕES DE BACKUP E RECUPERAÇÃO
# =============================================================================

# Criar backup de arquivo
backup_file() {
    local file="$1"
    local backup_dir="${2:-${LOG_DIR}/backups}"
    
    if [ ! -f "$file" ]; then
        error "Arquivo não encontrado: $file"
        return 1
    fi
    
    mkdir -p "$backup_dir"
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_name="$(basename "$file").backup_$timestamp"
    local backup_path="$backup_dir/$backup_name"
    
    if cp "$file" "$backup_path"; then
        success "Backup criado: $backup_path"
        audit_log "BACKUP_CREATED" "File: $file -> $backup_path"
        echo "$backup_path"
        return 0
    else
        error "Falha ao criar backup de $file"
        return 1
    fi
}

# Restaurar backup
restore_backup() {
    local backup_file="$1"
    local target_file="$2"
    
    if [ ! -f "$backup_file" ]; then
        error "Arquivo de backup não encontrado: $backup_file"
        return 1
    fi
    
    if confirm_critical "Restaurar backup" "De: $backup_file Para: $target_file"; then
        if cp "$backup_file" "$target_file"; then
            success "Backup restaurado: $target_file"
            audit_log "BACKUP_RESTORED" "From: $backup_file To: $target_file"
            return 0
        else
            error "Falha ao restaurar backup"
            return 1
        fi
    else
        info "Restauração cancelada"
        return 1
    fi
}

# =============================================================================
# FUNÇÕES DE REDE E CONECTIVIDADE
# =============================================================================

# Testar conectividade SSH
test_ssh_connection() {
    local host="$1"
    local user="$2"
    local port="${3:-22}"
    local timeout="${4:-10}"
    
    debug "Testando SSH: $user@$host:$port (timeout: ${timeout}s)"
    
    if ssh -o ConnectTimeout="$timeout" -o BatchMode=yes -o StrictHostKeyChecking=no -p "$port" "$user@$host" "echo 'SSH_OK'" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Verificar se porta está aberta
check_port() {
    local host="$1"
    local port="$2"
    local timeout="${3:-5}"
    
    if command_exists nc; then
        nc -z -w "$timeout" "$host" "$port" >/dev/null 2>&1
    elif command_exists telnet; then
        timeout "$timeout" telnet "$host" "$port" >/dev/null 2>&1
    else
        # Fallback usando /dev/tcp
        timeout "$timeout" bash -c "echo >/dev/tcp/$host/$port" >/dev/null 2>&1
    fi
}

# =============================================================================
# FUNÇÕES DE PROCESSO E SERVIÇO
# =============================================================================

# Verificar se processo está rodando
is_process_running() {
    local process_name="$1"
    pgrep -f "$process_name" >/dev/null 2>&1
}

# Obter PID de processo
get_process_pid() {
    local process_name="$1"
    pgrep -f "$process_name" | head -1
}

# Parar processo graciosamente
stop_process_graceful() {
    local process_name="$1"
    local timeout="${2:-30}"
    
    local pid
    pid=$(get_process_pid "$process_name")
    
    if [ -z "$pid" ]; then
        debug "Processo não encontrado: $process_name"
        return 0
    fi
    
    info "Parando processo $process_name (PID: $pid)..."
    
    # Tentar SIGTERM primeiro
    kill -TERM "$pid" 2>/dev/null
    
    # Aguardar até timeout
    local count=0
    while [ $count -lt "$timeout" ] && kill -0 "$pid" 2>/dev/null; do
        sleep 1
        ((count++))
    done
    
    # Se ainda estiver rodando, usar SIGKILL
    if kill -0 "$pid" 2>/dev/null; then
        warn "Processo não respondeu ao SIGTERM, usando SIGKILL..."
        kill -KILL "$pid" 2>/dev/null
        sleep 2
    fi
    
    if ! kill -0 "$pid" 2>/dev/null; then
        success "Processo $process_name parado com sucesso"
        audit_log "PROCESS_STOPPED" "Process: $process_name PID: $pid"
        return 0
    else
        error "Falha ao parar processo $process_name"
        return 1
    fi
}

# =============================================================================
# FUNÇÕES DE CLEANUP E MANUTENÇÃO
# =============================================================================

# Limpar logs antigos
cleanup_old_logs() {
    local days="${1:-30}"
    local log_dir="${2:-$LOG_DIR}"
    
    if [ ! -d "$log_dir" ]; then
        debug "Diretório de logs não existe: $log_dir"
        return 0
    fi
    
    info "Limpando logs com mais de $days dias em $log_dir..."
    
    local count
    count=$(find "$log_dir" -name "*.log" -type f -mtime +$days | wc -l)
    
    if [ "$count" -gt 0 ]; then
        find "$log_dir" -name "*.log" -type f -mtime +$days -delete
        success "Removidos $count arquivos de log antigos"
        audit_log "LOG_CLEANUP" "Removed $count files older than $days days"
    else
        debug "Nenhum log antigo encontrado para limpeza"
    fi
}

# Verificar espaço em disco
check_disk_space() {
    local path="${1:-.}"
    local threshold="${2:-90}"
    
    local usage
    usage=$(df "$path" | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [ "$usage" -gt "$threshold" ]; then
        warn "Uso de disco alto: ${usage}% (limite: ${threshold}%)"
        return 1
    else
        debug "Uso de disco OK: ${usage}%"
        return 0
    fi
}

# =============================================================================
# FUNÇÕES DE INICIALIZAÇÃO
# =============================================================================

# Inicializar ambiente do script
init_script_environment() {
    local script_name="$1"
    
    # Definir variáveis de ambiente se não existirem
    export SCRIPT_NAME="${script_name:-$(basename "${BASH_SOURCE[1]}")}"
    export SCRIPT_PID="$$"
    export SCRIPT_START_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
    
    # Log de início
    log_message "INFO" "Script iniciado: $SCRIPT_NAME (PID: $SCRIPT_PID)"
    
    # Configurar trap para cleanup
    trap 'cleanup_on_exit' EXIT INT TERM
}

# Cleanup ao sair do script
cleanup_on_exit() {
    local exit_code=$?
    log_message "INFO" "Script finalizado: $SCRIPT_NAME (Exit code: $exit_code)"
}

# =============================================================================
# VERIFICAÇÃO DE DEPENDÊNCIAS
# =============================================================================

# Verificar dependências necessárias
check_dependencies() {
    local deps=("$@")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        error "Dependências não encontradas: ${missing[*]}"
        info "Instale as dependências necessárias antes de continuar."
        return 1
    else
        debug "Todas as dependências estão disponíveis"
        return 0
    fi
}

# =============================================================================
# FUNÇÕES DE CONFIGURAÇÃO
# =============================================================================

# Carregar configuração de arquivo
load_config() {
    local config_file="$1"
    
    if [ ! -f "$config_file" ]; then
        warn "Arquivo de configuração não encontrado: $config_file"
        return 1
    fi
    
    # Carregar apenas se for um arquivo bash válido
    if bash -n "$config_file" 2>/dev/null; then
        source "$config_file"
        debug "Configuração carregada: $config_file"
        return 0
    else
        error "Arquivo de configuração inválido: $config_file"
        return 1
    fi
}

# =============================================================================
# MENSAGEM DE INICIALIZAÇÃO
# =============================================================================

# Exibir informações da biblioteca quando carregada
if [[ "${BASH_SOURCE[1]}" != "${0}" ]]; then
    debug "Biblioteca comum carregada: $(basename "${BASH_SOURCE[0]}")"
    debug "Projeto: $PROJECT_ROOT"
    debug "Logs: $LOG_DIR"
fi

# Marcar biblioteca como carregada
export COMMON_FUNCTIONS_LOADED=1

# =============================================================================
# FUNÇÕES DE COMPATIBILIDADE (LEGACY SHIMS)
# =============================================================================

# Alguns scripts antigos usam nomes diferentes. Mantemos aliases para compatibilidade.

# Alias para log -> info
log() {
    info "$1"
}

# Alias para confirmação simples
confirm_operation() {
    local message="$1"
    confirm "$message"
}

# Alias para confirmação crítica com nível (ignora nível e usa confirmação crítica)
confirm_critical_operation() {
    local message="$1"
    # nível "$2" é ignorado nesta implementação
    confirm_critical "$message"
}
