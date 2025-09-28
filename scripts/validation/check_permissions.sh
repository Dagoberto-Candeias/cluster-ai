#!/bin/bash
# =============================================================================
# check_permissions.sh
# =============================================================================
# Script utilitário do Cluster AI
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: check_permissions.sh
# =============================================================================

# Carregar biblioteca comum
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ -f "$SCRIPT_DIR/../lib/common.sh" ]; then
    source "$SCRIPT_DIR/../lib/common.sh"
else
    echo "Erro: Biblioteca common.sh não encontrada"
    exit 1
fi

# Diretórios a excluir da verificação
EXCLUDED_DIRS=(
    ".git"
    "node_modules"
    "venv"
    "__pycache__"
    ".pytest_cache"
    "logs"
    "temp"
    "backups"
)

check_permissions() {
    local non_executable_scripts=()
    
    # Construir os argumentos de exclusão para o comando find
    local find_args=()
    for dir in "${EXCLUDED_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            find_args+=(-not -path "${dir}/*")
        fi
    done

    # Encontrar todos os scripts .sh aplicando as exclusões
    mapfile -t all_scripts < <(find "$PROJECT_ROOT" -type f -name '*.sh' "${find_args[@]}")

    if [ ${#all_scripts[@]} -eq 0 ]; then
        warn "Nenhum script .sh encontrado para verificação."
        return 1
    fi

    info "Verificando permissões de ${#all_scripts[@]} scripts .sh..."

    for script in "${all_scripts[@]}"; do
        # Verificar se o script tem permissão de execução
        if [ ! -x "$script" ]; then
            non_executable_scripts+=("$script")
        fi
    done

    if [ ${#non_executable_scripts[@]} -eq 0 ]; then
        success "Todos os scripts têm permissões corretas."
        return 0
    else
        warn "Encontrados ${#non_executable_scripts[@]} scripts sem permissão de execução:"
        for script in "${non_executable_scripts[@]}"; do
            echo "  - $script"
        done
        
        # Perguntar se deseja corrigir
        if confirm_operation "Deseja adicionar permissão de execução aos scripts listados?"; then
            for script in "${non_executable_scripts[@]}"; do
                chmod +x "$script"
                success "Permissão adicionada: $script"
            done
            success "Permissões corrigidas com sucesso."
        else
            info "Permissões não foram alteradas."
        fi
        return 1
    fi
}

# Execução principal
main() {
    section "VERIFICAÇÃO DE PERMISSÕES DOS SCRIPTS"
    
    if check_permissions; then
        success "Verificação de permissões concluída com sucesso."
        exit 0
    else
        error "Problemas encontrados na verificação de permissões."
        exit 1
    fi
}

# Executar apenas se o script for chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
