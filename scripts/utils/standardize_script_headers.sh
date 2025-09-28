#!/bin/bash
# =============================================================================
# PADRONIZADOR DE CABEÇALHOS DE SCRIPTS - CLUSTER AI
# =============================================================================
# Script para padronizar cabeçalhos de todos os scripts bash do projeto
# seguindo o template oficial do Cluster AI
#
# Autor: Sistema de Padronização Automática
# Data: $(date +%Y-%m-%d)
# Versão: 1.0.0
# Dependências: find, sed, grep
# =============================================================================

# =============================================================================
# CONFIGURAÇÃO GLOBAL
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATE_FILE="$PROJECT_ROOT/docs/templates/script_comments_template.sh"
LOG_FILE="$PROJECT_ROOT/logs/script_standardization_$(date +%Y%m%d_%H%M%S).log"

# Contadores
TOTAL_SCRIPTS=0
PROCESSED_SCRIPTS=0
STANDARDIZED_SCRIPTS=0
ERROR_SCRIPTS=0

# =============================================================================
# FUNÇÕES UTILITÁRIAS
# =============================================================================

# Função: log_message
# Descrição: Registra mensagens no log com timestamp
log_message() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Função: show_progress
# Descrição: Mostra progresso da padronização
show_progress() {
    local current="$1"
    local total="$2"
    local percentage=$((current * 100 / total))
    echo -ne "\rProgresso: $current/$total ($percentage%)"
}

# =============================================================================
# FUNÇÕES PRINCIPAIS
# =============================================================================

# Função: extract_script_info
# Descrição: Extrai informações básicas do script para o cabeçalho
extract_script_info() {
    local script_path="$1"
    local script_name
    script_name=$(basename "$script_path")

    # Tentar extrair título do comentário existente
    local title
    title=$(grep -E "^#\s*[A-Z].*" "$script_path" | head -1 | sed 's/^#\s*//')
    if [ -z "$title" ]; then
        title="$script_name"
    fi

    # Extrair descrição se existir
    local description
    description=$(grep -A 5 "^#\s*$title" "$script_path" | grep -E "^#\s*[A-Z].*" | head -2 | tail -1 | sed 's/^#\s*//')
    if [ -z "$description" ]; then
        description="Script utilitário do Cluster AI"
    fi

    echo "$title|$description|$script_name"
}

# Função: generate_standard_header
# Descrição: Gera cabeçalho padronizado para o script
generate_standard_header() {
    local script_path="$1"
    local info
    info=$(extract_script_info "$script_path")
    local title
    title=$(echo "$info" | cut -d'|' -f1)
    local description
    description=$(echo "$info" | cut -d'|' -f2)
    local script_name
    script_name=$(echo "$info" | cut -d'|' -f3)

    cat << EOF
#!/bin/bash
# =============================================================================
# $title
# =============================================================================
# $description
#
# Autor: Cluster AI Team
# Data: $(date +%Y-%m-%d)
# Versão: 1.0.0
# Arquivo: $script_name
# =============================================================================
EOF
}

# Função: has_standard_header
# Descrição: Verifica se o script já tem cabeçalho padronizado
has_standard_header() {
    local script_path="$1"

    # Verifica se tem o padrão de cabeçalho
    if grep -q "^# =============================================================================$" "$script_path" && \
       grep -q "^# Autor: Cluster AI Team$" "$script_path" && \
       grep -q "^# =============================================================================$" "$script_path"; then
        return 0
    else
        return 1
    fi
}

# Função: standardize_script
# Descrição: Padroniza um script específico
standardize_script() {
    local script_path="$1"
    local backup_path
    backup_path="${script_path}.backup_$(date +%Y%m%d_%H%M%S)"

    log_message "INFO" "Processando: $script_path"

    # Verificar se já tem cabeçalho padronizado
    if has_standard_header "$script_path"; then
        log_message "INFO" "Script já padronizado: $script_path"
        return 0
    fi

    # Criar backup
    if ! cp "$script_path" "$backup_path"; then
        log_message "ERROR" "Falha ao criar backup: $script_path"
        return 1
    fi

    # Gerar novo cabeçalho
    local new_header
    new_header=$(generate_standard_header "$script_path")

    # Ler conteúdo atual
    local content
    content=$(cat "$script_path")

    # Verificar se começa com #!/bin/bash
    if echo "$content" | grep -q "^#!/bin/bash"; then
        # Substituir apenas o cabeçalho
        local temp_file
        temp_file=$(mktemp)
        echo "$new_header" > "$temp_file"
        echo "$content" | sed '1,/^#!/bin\/bash$/d' >> "$temp_file"

        mv "$temp_file" "$script_path"
    else
        # Adicionar cabeçalho no início
        local temp_file
        temp_file=$(mktemp)
        echo "$new_header" > "$temp_file"
        echo "" >> "$temp_file"
        echo "$content" >> "$temp_file"

        mv "$temp_file" "$script_path"
    fi

    # Tornar executável se não for
    if [ ! -x "$script_path" ]; then
        chmod +x "$script_path"
    fi

    log_message "INFO" "Script padronizado com sucesso: $script_path"
    return 0
}

# Função: find_all_scripts
# Descrição: Encontra todos os scripts bash no projeto
find_all_scripts() {
    local exclude_dirs="backups|node_modules|\.git"

    find "$PROJECT_ROOT" -type f -name "*.sh" \
        -not -path "*/$exclude_dirs/*" \
        -not -name "*.backup_*" \
        | sort
}

# =============================================================================
# VALIDAÇÃO E VERIFICAÇÕES
# =============================================================================

# Função: validate_environment
# Descrição: Valida se o ambiente necessário está disponível
validate_environment() {
    # Verificar dependências
    for cmd in find sed grep mktemp; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_message "ERROR" "Comando requerido não encontrado: $cmd"
            return 1
        fi
    done

    # Verificar template
    if [ ! -f "$TEMPLATE_FILE" ]; then
        log_message "ERROR" "Template não encontrado: $TEMPLATE_FILE"
        return 1
    fi

    # Criar diretório de logs se não existir
    mkdir -p "$(dirname "$LOG_FILE")"

    return 0
}

# =============================================================================
# EXECUÇÃO PRINCIPAL
# =============================================================================

main() {
    log_message "INFO" "=== INICIANDO PADRONIZAÇÃO DE SCRIPTS ==="
    log_message "INFO" "Diretório do projeto: $PROJECT_ROOT"
    log_message "Arquivo de log: $LOG_FILE"

    # Validação inicial
    if ! validate_environment; then
        log_message "ERROR" "Ambiente de execução inválido"
        exit 1
    fi

    # Encontrar todos os scripts
    log_message "INFO" "Procurando scripts bash..."
    local scripts
    scripts=$(find_all_scripts)
    TOTAL_SCRIPTS=$(echo "$scripts" | wc -l)

    if [ "$TOTAL_SCRIPTS" -eq 0 ]; then
        log_message "WARNING" "Nenhum script bash encontrado"
        exit 0
    fi

    log_message "INFO" "Encontrados $TOTAL_SCRIPTS scripts para processar"

    # Processar cada script
    local counter=1
    while IFS= read -r script; do
        if [ -n "$script" ]; then
            show_progress "$counter" "$TOTAL_SCRIPTS"

            if standardize_script "$script"; then
                ((STANDARDIZED_SCRIPTS++))
            else
                ((ERROR_SCRIPTS++))
                log_message "ERROR" "Falha ao processar: $script"
            fi

            ((PROCESSED_SCRIPTS++))
            ((counter++))
        fi
    done <<< "$scripts"

    echo "" # Nova linha após progresso

    # Relatório final
    log_message "INFO" "=== PADRONIZAÇÃO CONCLUÍDA ==="
    log_message "INFO" "Total de scripts encontrados: $TOTAL_SCRIPTS"
    log_message "INFO" "Scripts processados: $PROCESSED_SCRIPTS"
    log_message "INFO" "Scripts padronizados: $STANDARDIZED_SCRIPTS"
    log_message "INFO" "Scripts com erro: $ERROR_SCRIPTS"

    # Verificar se algum script foi alterado
    if [ "$STANDARDIZED_SCRIPTS" -gt 0 ]; then
        log_message "SUCCESS" "Padronização concluída com sucesso!"
        log_message "INFO" "Backups criados em: *.backup_$(date +%Y%m%d_%H%M%S)"
    else
        log_message "INFO" "Nenhum script precisou ser padronizado"
    fi

    return 0
}

# =============================================================================
# EXECUÇÃO
# =============================================================================

# Trap para cleanup
trap 'echo ""; log_message "WARNING" "Execução interrompida pelo usuário"' INT TERM

# Executar função principal
main "$@"
