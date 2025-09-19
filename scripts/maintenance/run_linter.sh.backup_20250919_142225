#!/bin/bash
# Script para executar o shellcheck em todos os scripts .sh do projeto.
# Descrição: Verifica a qualidade e a sintaxe de todos os scripts shell do projeto usando shellcheck.

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="${PROJECT_ROOT}/scripts/lib"
VENV_PATH="${PROJECT_ROOT}/.venv"

# Carregar funções comuns
if [ ! -f "${LIB_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado em $LIB_DIR."
    exit 1
fi
source "${LIB_DIR}/common.sh"

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

check_black_installed() {
    if [ ! -d "$VENV_PATH" ]; then
        error "Ambiente virtual não encontrado em $VENV_PATH."
        info "Execute o instalador para criar o ambiente e instalar as dependências."
        return 1
    fi

    if ! "$VENV_PATH/bin/python" -m black --version >/dev/null 2>&1; then
        error "Comando 'black' não encontrado no ambiente virtual."
        info "Instale-o com: source .venv/bin/activate && pip install black"
        return 1
    fi
    success "Black (formatador Python) está instalado."
}

run_shellcheck_linter() {
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
    if ! shellcheck "${scripts_to_check[@]}"; then
        issues_found=1
    fi

    if [ "$issues_found" -ne 0 ]; then
        error "ShellCheck encontrou problemas."
        return 1
    else
        success "Nenhum problema encontrado pelo ShellCheck."
        return 0
    fi
}

run_black_linter() {
    section "Executando Linter (Black) em todos os arquivos .py"
    if ! check_black_installed; then
        return 1
    fi

    log "Procurando por arquivos .py no projeto..."
    local files_to_check
    mapfile -t files_to_check < <(find "$PROJECT_ROOT" -type f -name "*.py" -not -path "${VENV_PATH}/*")

    if [ ${#files_to_check[@]} -eq 0 ]; then
        warn "Nenhum arquivo .py encontrado para verificação."
        return 0
    fi

    log "Verificando ${#files_to_check[@]} arquivos Python com Black..."

    if "$VENV_PATH/bin/python" -m black --check "${files_to_check[@]}"; then
        success "Nenhum problema de formatação encontrado pelo Black."
        return 0
    else
        error "Black encontrou problemas de formatação."
        info "Execute o seguinte comando para formatar os arquivos:"
        info "source .venv/bin/activate && black ."
        return 1
    fi
}

# --- Menu Principal ---
main() {
    local shellcheck_status=0
    local black_status=0

    run_shellcheck_linter || shellcheck_status=$?
    run_black_linter || black_status=$?

    section "Resumo Final do Linter"
    if [ "$shellcheck_status" -eq 0 ] && [ "$black_status" -eq 0 ]; then
        success "🎉 Todos os linters passaram com sucesso!"
        exit 0
    else
        error "❌ Foram encontrados problemas. Por favor, revise os logs acima e corrija os arquivos."
        exit 1
    fi
}

main "$@"