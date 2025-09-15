#!/bin/bash
# =============================================================================
# CLUSTER AI - PADRONIZADOR DE CABEÇALHOS DE SCRIPTS
# =============================================================================
#
# DESCRIÇÃO: Padroniza cabeçalhos de todos os scripts bash do projeto
#
# AUTOR: Sistema de Padronização Automática
# DATA: $(date +%Y-%m-%d)
# VERSÃO: 1.0.0
#
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# CONSTANTES
# -----------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly TEMPLATE_FILE="${PROJECT_ROOT}/scripts/templates/bash_template.sh"

# -----------------------------------------------------------------------------
# CORES PARA OUTPUT
# -----------------------------------------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# -----------------------------------------------------------------------------
# FUNÇÕES DE LOGGING
# -----------------------------------------------------------------------------
log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] ${SCRIPT_NAME}: $*${NC}"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] ${SCRIPT_NAME}: $*${NC}"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] ${SCRIPT_NAME}: $*${NC}"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] ${SCRIPT_NAME}: $*${NC}"
}

# -----------------------------------------------------------------------------
# FUNÇÃO PARA EXTRAIR CABEÇALHO DO TEMPLATE
# -----------------------------------------------------------------------------
extract_template_header() {
    local template_file="$1"

    # Extrair linhas do cabeçalho até a linha de configuração global
    awk '
    BEGIN { in_header = 1 }
    /^# -+$/ && in_header { next }
    /^# CONFIGURAÇÕES GLOBAIS/ { in_header = 0; next }
    in_header { print }
    ' "$template_file"
}

# -----------------------------------------------------------------------------
# FUNÇÃO PARA PADRONIZAR CABEÇALHO DE UM SCRIPT
# -----------------------------------------------------------------------------
standardize_script_header() {
    local script_file="$1"
    local script_name="$(basename "$script_file" .sh)"
    local temp_file="${script_file}.tmp"

    log_info "Padronizando cabeçalho: $script_file"

    # Verificar se o arquivo existe
    if [[ ! -f "$script_file" ]]; then
        log_error "Arquivo não encontrado: $script_file"
        return 1
    fi

    # Criar backup
    cp "$script_file" "${script_file}.backup"

    # Extrair cabeçalho do template
    local template_header
    template_header=$(extract_template_header "$TEMPLATE_FILE")

    # Personalizar cabeçalho para o script específico
    local custom_header
    custom_header=$(cat << EOF
#!/bin/bash
# =============================================================================
# CLUSTER AI - $script_name
# =============================================================================
#
# DESCRIÇÃO: [DESCRIÇÃO DO SCRIPT AQUI]
#
# AUTOR: Sistema de Padronização Automática
# DATA: $(date +%Y-%m-%d)
# VERSÃO: 1.0.0
#
# =============================================================================
EOF
)

    # Ler conteúdo do script original
    local original_content
    original_content=$(cat "$script_file")

    # Verificar se já tem shebang
    if [[ "$original_content" =~ ^#!/ ]]; then
        # Remover shebang antigo e cabeçalho antigo
        local content_without_header
        content_without_header=$(echo "$original_content" | sed '1,/^# =============================================================================/d')
        # Remover linha vazia após o cabeçalho antigo
        content_without_header=$(echo "$content_without_header" | sed '/^$/N;/^\n$/d')
        # Combinar novo cabeçalho com conteúdo
        echo "$custom_header$content_without_header" > "$temp_file"
    else
        # Adicionar shebang e cabeçalho
        echo "$custom_header$original_content" > "$temp_file"
    fi

    # Substituir arquivo original
    mv "$temp_file" "$script_file"

    # Tornar executável se não for
    if [[ ! -x "$script_file" ]]; then
        chmod +x "$script_file"
        log_info "Arquivo tornado executável: $script_file"
    fi

    log_success "Cabeçalho padronizado: $script_file"
}

# -----------------------------------------------------------------------------
# FUNÇÃO PARA ENCONTRAR TODOS OS SCRIPTS BASH
# -----------------------------------------------------------------------------
find_bash_scripts() {
    local search_dir="$1"

    # Encontrar todos os arquivos .sh no diretório, excluindo venv e outros
    find "$search_dir" -name "*.sh" -type f \
        | grep -v "/venv/" \
        | grep -v "/templates/" \
        | grep -v "/\." \
        | grep -v "/node_modules/" \
        | grep -v "/.git/"
}

# -----------------------------------------------------------------------------
# FUNÇÃO PRINCIPAL
# -----------------------------------------------------------------------------
main() {
    log_info "Iniciando padronização de cabeçalhos de scripts"

    # Verificar se template existe
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        log_error "Template não encontrado: $TEMPLATE_FILE"
        exit 1
    fi

    # Encontrar todos os scripts bash
    local scripts
    mapfile -t scripts < <(find_bash_scripts "$PROJECT_ROOT")

    if [[ ${#scripts[@]} -eq 0 ]]; then
        log_warn "Nenhum script bash encontrado"
        exit 0
    fi

    log_info "Encontrados ${#scripts[@]} scripts para padronizar"

    local success_count=0
    local error_count=0

    for script in "${scripts[@]}"; do
        if standardize_script_header "$script"; then
            ((success_count++))
        else
            ((error_count++))
        fi
    done

    log_success "Padronização concluída: $success_count sucesso, $error_count erros"

    if [[ $error_count -gt 0 ]]; then
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# EXECUÇÃO
# -----------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
