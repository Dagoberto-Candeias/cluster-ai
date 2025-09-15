#!/bin/bash
# Painel de Controle do Cluster AI - Versão Modular
#
# Este script serve como o ponto central para gerenciar todos os serviços
# do ecossistema Cluster AI, incluindo Ollama, Dask e OpenWebUI.
# Gerencia serviços, executa verificações e otimizações.

set -euo pipefail  # Modo estrito: para em erros, variáveis não definidas e falhas em pipelines

# =============================================================================
# INICIALIZAÇÃO E CARREGAMENTO DE MÓDULOS
# =============================================================================

# Este bloco deve vir antes de qualquer definição de função que use os módulos.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
CONFIG_FILE="${PROJECT_ROOT}/cluster.yaml"

# Carregar módulos na ordem correta (common primeiro)
# Usamos 'source' com verificação para fornecer mensagens de erro melhores.
for module in \
    "${SCRIPT_DIR}/scripts/core/common.sh" \
    "${SCRIPT_DIR}/scripts/core/security.sh" \
    "${SCRIPT_DIR}/scripts/core/services.sh" \
    "${SCRIPT_DIR}/scripts/core/workers.sh" \
    "${SCRIPT_DIR}/scripts/core/ui.sh"; do
    if [ -f "$module" ]; then
        source "$module"
    else
        # Usando echo aqui pois a função 'error' pode não estar carregada ainda.
        echo "ERRO CRÍTICO: Módulo essencial não encontrado: $module"
        exit 1
    fi
done

# Funções de compatibilidade para interface (apelidos)
section() { ui_section "$1"; }
subsection() { ui_subsection "$1"; }

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Se nenhum argumento for passado, inicia o menu interativo
    if [ $# -eq 0 ]; then
        main_menu # Chama o menu principal e unificado do ui.sh
        return
    fi

    # Processa argumentos da linha de comando
    case "${1:-}" in
        start)
            start_cluster
            ;;
        stop)
            stop_cluster
            ;;
        restart)
            restart_cluster
            ;;
        status)
            show_detailed_status
            ;;
        test)
            run_tests
            ;;
        diag)
            show_diagnostics
            ;;
        logs)
            view_system_logs
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Comando inválido: '$1'"
            show_help
            exit 1
            ;;
    esac
}

# EXECUÇÃO
# =============================================================================

# Finalmente, executa a função principal, passando todos os argumentos
main "$@"
