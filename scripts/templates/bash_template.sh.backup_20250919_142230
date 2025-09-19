#!/bin/bash
# =============================================================================
# CLUSTER AI - TEMPLATE PADRÃO PARA SCRIPTS BASH
# =============================================================================
#
# DESCRIÇÃO: Template padronizado para todos os scripts bash do projeto
#
# AUTOR: Sistema de Padronização Automática
# DATA: $(date +%Y-%m-%d)
# VERSÃO: 1.0.0
#
# =============================================================================

# -----------------------------------------------------------------------------
# CONFIGURAÇÕES GLOBAIS
# -----------------------------------------------------------------------------
set -euo pipefail  # Exit on error, undefined vars, pipe failures
IFS=$'\n\t'       # Internal Field Separator seguro

# -----------------------------------------------------------------------------
# CONSTANTES
# -----------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_DIR="${PROJECT_ROOT}/logs"
readonly CONFIG_DIR="${PROJECT_ROOT}/config"
readonly BACKUP_DIR="${PROJECT_ROOT}/backups"

# -----------------------------------------------------------------------------
# CORES PARA OUTPUT (ANSI)
# -----------------------------------------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# FUNÇÕES DE LOGGING PADRONIZADAS
# -----------------------------------------------------------------------------
log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] ${SCRIPT_NAME}: $*${NC}" >&2
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] ${SCRIPT_NAME}: $*${NC}" >&2
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] ${SCRIPT_NAME}: $*${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] ${SCRIPT_NAME}: $*${NC}" >&2
}

# -----------------------------------------------------------------------------
# FUNÇÃO DE LOG PARA ARQUIVO
# -----------------------------------------------------------------------------
log_to_file() {
    local level="$1"
    local message="$2"
    local log_file="${LOG_DIR}/${SCRIPT_NAME%.sh}.log"

    # Criar diretório de logs se não existir
    mkdir -p "${LOG_DIR}"

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [${level}] ${SCRIPT_NAME}: ${message}" >> "${log_file}"
}

# -----------------------------------------------------------------------------
# FUNÇÃO DE VALIDAÇÃO DE DEPENDÊNCIAS
# -----------------------------------------------------------------------------
check_dependencies() {
    local deps=("$@")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Dependências faltando: ${missing_deps[*]}"
        log_error "Por favor, instale as dependências necessárias e tente novamente."
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# FUNÇÃO DE VALIDAÇÃO DE ARQUIVOS/DIRETÓRIOS
# -----------------------------------------------------------------------------
validate_path() {
    local path="$1"
    local path_type="$2"  # "file" ou "directory"

    if [ "$path_type" = "file" ]; then
        if [ ! -f "$path" ]; then
            log_error "Arquivo não encontrado: $path"
            return 1
        fi
    elif [ "$path_type" = "directory" ]; then
        if [ ! -d "$path" ]; then
            log_error "Diretório não encontrado: $path"
            return 1
        fi
    fi

    return 0
}

# -----------------------------------------------------------------------------
# FUNÇÃO DE BACKUP
# -----------------------------------------------------------------------------
create_backup() {
    local source_path="$1"
    local backup_name="${2:-$(basename "$source_path").backup.$(date +%Y%m%d_%H%M%S)}"
    local backup_path="${BACKUP_DIR}/${backup_name}"

    log_info "Criando backup: $source_path -> $backup_path"

    if [ -f "$source_path" ]; then
        cp "$source_path" "$backup_path"
    elif [ -d "$source_path" ]; then
        cp -r "$source_path" "$backup_path"
    else
        log_error "Caminho de origem não encontrado: $source_path"
        return 1
    fi

    log_success "Backup criado com sucesso: $backup_path"
    return 0
}

# -----------------------------------------------------------------------------
# FUNÇÃO DE LIMPEZA DE ARQUIVOS TEMPORÁRIOS
# -----------------------------------------------------------------------------
cleanup_temp_files() {
    local temp_dir="${1:-/tmp/${SCRIPT_NAME%.sh}_temp}"

    if [ -d "$temp_dir" ]; then
        log_info "Limpando arquivos temporários: $temp_dir"
        rm -rf "$temp_dir"
    fi
}

# -----------------------------------------------------------------------------
# TRAP PARA LIMPEZA AUTOMÁTICA
# -----------------------------------------------------------------------------
trap 'cleanup_temp_files' EXIT

# -----------------------------------------------------------------------------
# FUNÇÃO DE VALIDAÇÃO DE INPUT DO USUÁRIO
# -----------------------------------------------------------------------------
validate_input() {
    local input="$1"
    local pattern="$2"
    local error_msg="${3:-"Input inválido"}"

    if [[ ! "$input" =~ $pattern ]]; then
        log_error "$error_msg: $input"
        return 1
    fi

    return 0
}

# -----------------------------------------------------------------------------
# FUNÇÃO DE CONFIRMAÇÃO DO USUÁRIO
# -----------------------------------------------------------------------------
confirm_action() {
    local message="$1"
    local default="${2:-n}"

    local prompt
    if [ "$default" = "y" ]; then
        prompt="${message} (Y/n): "
    else
        prompt="${message} (y/N): "
    fi

    read -p "$prompt" -n 1 -r
    echo

    if [ "$default" = "y" ]; then
        [[ ! $REPLY =~ ^[Nn]$ ]]
    else
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# -----------------------------------------------------------------------------
# FUNÇÃO PRINCIPAL (A SER IMPLEMENTADA PELOS SCRIPTS)
# -----------------------------------------------------------------------------
main() {
    # Exemplo de uso das funções padronizadas
    log_info "Iniciando ${SCRIPT_NAME}"

    # Verificar dependências
    check_dependencies "bash" "mkdir" "cp"

    # Criar diretórios necessários
    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}"

    # Log da execução
    log_to_file "INFO" "Script iniciado"

    # TODO: Implementar lógica específica do script aqui

    log_success "${SCRIPT_NAME} concluído com sucesso"
    log_to_file "INFO" "Script concluído com sucesso"
}

# -----------------------------------------------------------------------------
# EXECUÇÃO PRINCIPAL
# -----------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Verificar se está sendo executado como root (se necessário)
    # if [[ $EUID -eq 0 ]]; then
    #     log_error "Este script não deve ser executado como root"
    #     exit 1
    # fi

    # Executar função principal
    main "$@"
fi

# =============================================================================
# FIM DO TEMPLATE
# =============================================================================
