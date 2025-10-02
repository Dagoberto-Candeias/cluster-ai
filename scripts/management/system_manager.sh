#!/bin/bash
# =============================================================================
# Gerenciador de Sistema e Manutenção do Cluster AI
# =============================================================================
# Centraliza tarefas de manutenção como atualizações, otimizações e segurança.
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
# FUNÇÕES DE MANUTENÇÃO
# =============================================================================

# Função genérica para executar um script de manutenção com verificações robustas.
run_maintenance_script() {
    local script_path="$1"
    local script_name
    script_name=$(basename "$script_path")
    shift # Remove o caminho do script da lista de argumentos

    if [ ! -f "$script_path" ]; then
        error "Script de manutenção '$script_name' não encontrado em '$script_path'."
        return 127 # Código de erro para "comando não encontrado"
    fi

    if [ ! -x "$script_path" ]; then
        error "Script de manutenção '$script_name' não é executável."
        info "Dica: Conceda permissão de execução com 'chmod +x $script_path'"
        return 126 # Código de erro para "comando não executável"
    fi

    # Executa o script passando os argumentos restantes
    bash "$script_path" "$@"
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        error "O script '$script_name' terminou com erro (código: $exit_code)."
        return $exit_code
    fi

    return 0
}

manage_vscode() {
    local vscode_manager_script="${PROJECT_ROOT}/scripts/maintenance/vscode_manager.sh"
    shift
    run_maintenance_script "$vscode_manager_script" "$@"
}

run_auto_updater() {
    local auto_updater_script="${PROJECT_ROOT}/scripts/maintenance/auto_updater.sh"
    section "ATUALIZANDO PROJETO CLUSTER AI"
    run_maintenance_script "$auto_updater_script"
}

run_performance_optimizer() {
    local optimizer_script="${PROJECT_ROOT}/scripts/optimization/performance_optimizer.sh"
    section "OTIMIZANDO PERFORMANCE DO SISTEMA"
    run_maintenance_script "$optimizer_script"
}

manage_security() {
    local security_script="${PROJECT_ROOT}/scripts/security/security_manager.sh"
    shift
    run_maintenance_script "$security_script" "$@"
}

show_system_help() {
    echo "Uso: $0 [comando]"
    echo
    echo "Comandos de gerenciamento do sistema:"
    echo -e "  ${GREEN}vscode [...]${NC}  - Gerencia o ambiente VSCode (use 'vscode help' para subcomandos)."
    echo -e "  ${GREEN}update${NC}        - Verifica e aplica atualizações para o projeto."
    echo -e "  ${GREEN}optimize${NC}      - Executa o otimizador de performance do sistema."
    echo -e "  ${GREEN}security [...]${NC}  - Gerencia a segurança do cluster (use 'security help' para subcomandos)."
    echo -e "  ${GREEN}help${NC}           - Mostra esta ajuda."
}

# =============================================================================
# PONTO DE ENTRADA DO SCRIPT
# =============================================================================
case "${1:-help}" in
    vscode)
        manage_vscode "$@"
        ;;
    update)
        run_auto_updater
        ;;
    optimize)
        run_performance_optimizer
        ;;
    security)
        manage_security "$@"
        ;;
    *)
      error "Comando de sistema inválido: '${1:-}'"
      show_system_help
      exit 1
      ;;
esac