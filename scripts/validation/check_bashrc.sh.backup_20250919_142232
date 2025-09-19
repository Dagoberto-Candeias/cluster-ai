#!/bin/bash
#
# 🔎 SCRIPT DE VERIFICAÇÃO DO .BASHRC
# Verifica se o ~/.bashrc contém configurações obsoletas do Cluster AI
# sem fazer nenhuma modificação.
#

set -euo pipefail

# --- Carregar Funções Comuns ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# --- Constantes ---
BASHRC_FILE="$HOME/.bashrc"

# --- Função Principal de Verificação ---

main() {
    section "🔎 Verificação de Configurações Obsoletas no ~/.bashrc"

    if [ ! -f "$BASHRC_FILE" ]; then
        success "Arquivo ~/.bashrc não encontrado. Nenhuma verificação necessária."
        exit 0
    fi

    # Padrões a serem procurados. São os comentários que os scripts antigos adicionavam.
    local patterns_to_check=(
        "# Otimizações para VSCode no Debian"
        "# EMERGENCY MODE - Limites mais restritivos para VSCode"
        "# Aliases para VS Code ultra-seguro"
        "# Aliases para VS Code manual"
        "# Aliases para VS Code anti-crash"
        "# Aliases para VS Code seguro"
        "alias vscode-monitor="
        "alias vscode-ultra="
        "ulimit -u 64"
    )

    local found_issues=0
    local found_patterns=()

    progress "Analisando o arquivo $BASHRC_FILE..."
    for pattern in "${patterns_to_check[@]}"; do
        if grep -qF "$pattern" "$BASHRC_FILE"; then
            ((found_issues++))
            found_patterns+=("$pattern")
        fi
    done

    if [ $found_issues -eq 0 ]; then
        success "🎉 Nenhuma configuração obsoleta do Cluster AI encontrada em seu ~/.bashrc."
        exit 0
    else
        error "❌ Foram encontradas $found_issues configurações obsoletas em seu ~/.bashrc."
        echo
        info "Padrões encontrados:"
        for p in "${found_patterns[@]}"; do
            echo "  - '$p'"
        done
        echo
        warn "É altamente recomendado executar o script de limpeza para remover essas configurações."
        info "Para limpar, execute o comando:"
        echo -e "${CYAN}bash scripts/maintenance/cleanup_bashrc.sh${NC}"
        exit 1
    fi
}

main "$@"