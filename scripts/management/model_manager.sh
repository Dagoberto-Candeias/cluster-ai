#!/bin/bash
# =============================================================================
# Gerenciador de Modelos Ollama do Cluster AI
# =============================================================================
# Este script centraliza as funções para instalar e remover modelos Ollama.
# É chamado pelo 'manager.sh'.
#
# Autor: Cluster AI Team
# Versão: 1.0.0
# =============================================================================

set -euo pipefail

# Navega para o diretório raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$PROJECT_ROOT"

# Carregar funções comuns (biblioteca consolidada)
# shellcheck source=../utils/common_functions.sh
source "scripts/utils/common_functions.sh"

# =============================================================================
# FUNÇÕES DE GERENCIAMENTO DE MODELOS
# =============================================================================

# Função genérica para executar um script de manutenção com verificações robustas.
run_model_script() {
    local script_path="$1"
    local script_name
    script_name=$(basename "$script_path")

    if [ ! -f "$script_path" ]; then
        error "Script de gerenciamento de modelo '$script_name' não encontrado em '$script_path'."
        return 127
    fi

    if [ ! -x "$script_path" ]; then
        error "Script '$script_name' não é executável."
        info "Dica: Conceda permissão de execução com 'chmod +x $script_path'"
        return 126
    fi

    bash "$script_path"
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        error "O script '$script_name' terminou com erro (código: $exit_code)."
        return $exit_code
    fi

    return 0
}

install_models() {
    local install_script="scripts/management/install_models.sh"
    info "Iniciando o instalador de modelos interativo..."
    run_model_script "$install_script"
}

remove_models() {
    local remove_script="scripts/management/remove_models.sh"
    info "Iniciando o removedor de modelos interativo..."
    run_model_script "$remove_script"
}

show_model_help() {
    echo "Uso: $0 [comando]"
    echo
    echo "Comandos de gerenciamento de modelos:"
    echo -e "  ${GREEN}install${NC}   - Abre o menu interativo para instalar modelos Ollama."
    echo -e "  ${GREEN}remove${NC}    - Abre o menu interativo para remover modelos Ollama."
    echo -e "  ${GREEN}help${NC}      - Mostra esta ajuda."
}

# =============================================================================
# PONTO DE ENTRADA DO SCRIPT
# =============================================================================
case "${1:-help}" in
    install) install_models ;;
    remove) remove_models ;;
    help) show_model_help ;;
    *)
      error "Comando de modelos inválido: '${1:-}'"
      show_model_help
      exit 1
      ;;
esac