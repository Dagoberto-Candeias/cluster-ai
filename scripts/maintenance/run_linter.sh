#!/bin/bash
# Script para executar o shellcheck em todos os scripts .sh do projeto.
# Descrição: Verifica a qualidade e a sintaxe de todos os scripts shell do projeto usando shellcheck.

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Constantes ---
# Diretórios a serem ignorados na verificação
EXCLUDED_DIRS=(
    "${PROJECT_ROOT}/.venv"
    "${PROJECT_ROOT}/backups"
    "${PROJECT_ROOT}/logs"
    "${PROJECT_ROOT}/test_logs"
)

# --- Funções ---

check_shellcheck_installed() {
    if ! command_exists shellcheck; then
        error "Comando 'shellcheck' não encontrado."
        info "É necessário para verificar a qualidade do código dos scripts."
        info "Instale-o com: sudo apt install shellcheck (ou equivalente para sua distro)."
        return 1
    fi
    success "Shellcheck está instalado."
    return 0
}

run_linter() {
    section "Executando Linter (ShellCheck) em todos os scripts .sh"
    if ! check_shellcheck_installed; then
        return 1
    fi

    log "Procurando por arquivos .sh no projeto..."
    
    local find_cmd="find \"${PROJECT_ROOT}\" -type f -name '*.sh'"
    for dir in "${EXCLUDED_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            find_cmd+=" -not -path \"${dir}/*\""
        fi
    done

    local scripts_to_check
    mapfile -t scripts_to_check < <(eval "$find_cmd")

    if [ ${#scripts_to_check[@]} -eq 0 ]; then
        warn "Nenhum script .sh encontrado para verificação."
        return 0
    fi

    log "Verificando ${#scripts_to_check[@]} scripts..."
    
    local issues_found=0
    shellcheck "${scripts_to_check[@]}" || issues_found=$?

    echo -e "\n---"
    section "Resumo do Linter"
    if [ "$issues_found" -ne 0 ]; then
        error "Foram encontrados problemas em um ou mais scripts. Por favor, corrija-os."
        return 1
    else
        success "🎉 Todos os scripts passaram na verificação do shellcheck!"
        return 0
    fi
}

# --- Menu Principal ---
main() {
    run_linter
}

main "$@"