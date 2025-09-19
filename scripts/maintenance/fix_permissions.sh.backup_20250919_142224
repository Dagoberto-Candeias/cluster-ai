#!/bin/bash
#
# 🛠️ SCRIPT DE CORREÇÃO DE PERMISSÕES
# Aplica permissão de execução (+x) a todos os scripts .sh do projeto,
# respeitando os diretórios de exclusão.
#

set -euo pipefail

# --- Carregar Funções Comuns ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# --- Constantes ---
EXCLUDED_DIRS=(
    "${PROJECT_ROOT}/.venv"
    "${PROJECT_ROOT}/backups"
    "${PROJECT_ROOT}/logs"
    "${PROJECT_ROOT}/coverage"
    "${PROJECT_ROOT}/node_modules"
)

# --- Função Principal de Correção ---

main() {
    section "🛠️ Corrigindo Permissões de Execução (+x) para Scripts .sh"

    # Construir os argumentos de exclusão para o comando find
    local find_args=()
    for dir in "${EXCLUDED_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            find_args+=(-not -path "${dir}/*")
        fi
    done

    # Encontrar todos os scripts .sh, aplicando as exclusões
    local scripts_to_fix
    mapfile -t scripts_to_fix < <(find "$PROJECT_ROOT" -type f -name '*.sh' "${find_args[@]}")

    if [ ${#scripts_to_fix[@]} -eq 0 ]; then
        success "Nenhum script .sh encontrado para corrigir."
        exit 0
    fi

    local fixed_count=0
    progress "Verificando e corrigindo ${#scripts_to_fix[@]} scripts..."
    for script in "${scripts_to_fix[@]}"; do
        if [ ! -x "$script" ]; then
            chmod +x "$script"
            info "Permissão +x adicionada a: ./${script#"$PROJECT_ROOT/"}"
            ((fixed_count++))
        fi
    done

    if [ $fixed_count -eq 0 ]; then
        success "Todos os scripts já tinham a permissão de execução correta."
    else
        success "🎉 Permissões corrigidas para $fixed_count script(s)."
    fi
}

main "$@"