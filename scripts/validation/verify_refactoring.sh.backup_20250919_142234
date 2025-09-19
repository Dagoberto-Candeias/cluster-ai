#!/bin/bash
#
# 🔎 SCRIPT DE VERIFICAÇÃO DA REFATORAÇÃO
# Garante que a refatoração do projeto foi concluída com sucesso,
# verificando a remoção de scripts antigos e a presença dos novos.
#

set -euo pipefail

# --- Carregar Funções Comuns ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# --- Listas de Scripts ---

# Scripts que deveriam ter sido REMOVIDOS
OBSOLETE_SCRIPTS=(
    "emergency_fix.sh"
    "restart_cluster.sh"
    "start_cluster.sh"
    "stop_cluster.sh"
    "demo_complete_system.sh"
    "demo_intelligent_system.sh"
    "scripts/vscode/clean_vscode_cache.sh"
    "scripts/vscode/clean_vscode_workspace.sh"
    "scripts/vscode/complete_vscode_reset.sh"
    "scripts/vscode/fix_vscode_complete.sh"
    "scripts/vscode/fix_vscode_crash.sh"
    "scripts/vscode/fix_vscode_freeze.sh"
    "scripts/vscode/fix_vscode_gui.sh"
    "scripts/vscode/fix_vscode_network.sh"
    "scripts/vscode/monitor_resources.sh"
    "scripts/vscode/optimize_vscode.sh"
    "scripts/vscode/prepare_vscode_fix.sh"
    "scripts/vscode/restart_vscode_clean.sh"
    "scripts/vscode/terminal_wrapper.sh"
    "scripts/vscode/vscode_optimized_config.sh"
)

# Scripts essenciais que DEVEM existir
ESSENTIAL_SCRIPTS=(
    "manager.sh"
    "install_unified.sh"
    "showcase.sh"
    "scripts/maintenance/vscode_manager.sh"
    "scripts/maintenance/cleanup_bashrc.sh"
    "scripts/lib/common.sh"
)

# --- Função Principal de Verificação ---

main() {
    section "🔎 Verificação da Integridade da Refatoração"
    local errors_found=0

    # 1. Verificar se os scripts obsoletos foram removidos
    subsection "Verificando remoção de scripts obsoletos"
    local obsolete_found=0
    for script in "${OBSOLETE_SCRIPTS[@]}"; do
        if [ -f "${PROJECT_ROOT}/${script}" ]; then
            error "Script obsoleto ainda existe: ${script}"
            ((obsolete_found++))
            ((errors_found++))
        fi
    done

    if [ $obsolete_found -eq 0 ]; then
        success "Todos os ${#OBSOLETE_SCRIPTS[@]} scripts obsoletos foram removidos corretamente."
    else
        warn "$obsolete_found scripts obsoletos ainda precisam ser removidos."
    fi

    # 2. Verificar se os scripts essenciais existem
    subsection "Verificando existência de scripts essenciais"
    for script in "${ESSENTIAL_SCRIPTS[@]}"; do
        if [ -f "${PROJECT_ROOT}/${script}" ]; then
            success "Script essencial encontrado: ${script}"
        else
            error "Script essencial NÃO encontrado: ${script}"
            ((errors_found++))
        fi
    done

    # 3. Relatório final
    section "Resultado da Verificação"
    if [ $errors_found -eq 0 ]; then
        success "🎉 A refatoração do projeto foi concluída com sucesso! Todos os arquivos estão no lugar certo."
        exit 0
    else
        error "❌ Foram encontrados $errors_found erros. A refatoração não está completa. Revise os logs acima."
        exit 1
    fi
}

main "$@"