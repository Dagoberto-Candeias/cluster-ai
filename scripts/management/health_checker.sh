#!/bin/bash
# =============================================================================
# Verificador de Saúde e Diagnóstico do Cluster AI (DEPRECADO)
# =============================================================================
# Este script foi substituído pelos utilitários unificados:
#  - scripts/utils/health_check.sh
#  - scripts/utils/system_status_dashboard.sh
# Mantido como wrapper para compatibilidade, imprimindo aviso e encaminhando
# os comandos para os scripts consolidados.
#
# Autor: Cluster AI Team
# Versão: 2.0.0 (wrapper)
# =============================================================================

set -euo pipefail

# Navega para o diretório raiz do projeto para garantir que os caminhos relativos funcionem
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PID_DIR="${PROJECT_ROOT}/.pids"
cd "$PROJECT_ROOT"

# Carregar funções comuns (biblioteca consolidada)
# shellcheck source=../utils/common_functions.sh
source "scripts/utils/common_functions.sh"

deprecation_notice() {
    echo -e "${YELLOW}⚠ Este script foi deprecado. Use:${NC}"
    echo -e "  ${BOLD}scripts/utils/health_check.sh${NC} ou ${BOLD}scripts/utils/system_status_dashboard.sh${NC}"
}

# Verificar saúde do Ollama
check_ollama_health() {
    deprecation_notice
    bash "scripts/utils/health_check.sh" services || true
}

# Verificar saúde dos workers
check_workers_health() {
    deprecation_notice
    bash "scripts/utils/health_check.sh" workers || true
}

# Executar benchmarks de performance
run_performance_benchmarks() {
    deprecation_notice
    warn "benchmark: funcionalidade será migrada para um módulo dedicado."
}

# Verificar latência dos workers
check_worker_latency() {
    deprecation_notice
    warn "latency: funcionalidade será migrada para módulo dedicado."
}

show_detailed_status() {
    deprecation_notice
    # Header expected by legacy tests
    echo -e "${BOLD}${CYAN}STATUS DETALHADO DO CLUSTER AI${NC}"
    bash "scripts/utils/system_status_dashboard.sh" || true
}

show_diagnostics() {
    deprecation_notice
    # Header expected by legacy tests
    echo -e "${BOLD}${CYAN}DIAGNÓSTICO DO SISTEMA${NC}"
    bash "scripts/utils/health_check.sh" diag || true
}

view_system_logs() {
    deprecation_notice
    if [ -f "logs/cluster_ai.log" ]; then
        tail -20 logs/cluster_ai.log
    else
        warn "Log principal não encontrado"
    fi

    if [ -f "logs/dask_scheduler.log" ]; then
        echo -e "\n${CYAN}=== ÚLTIMAS 10 LINHAS DO LOG DO SCHEDULER ==="${NC}
        tail -10 logs/dask_scheduler.log
    fi
}

show_health_help() {
    echo "Uso: $0 [comando]"
    echo
    echo "Comandos de verificação de saúde:"
    echo "  status        - Mostra o status detalhado dos serviços."
    echo "  diag          - Executa um diagnóstico completo do sistema."
    echo "  logs          - Exibe os logs recentes do sistema."
    echo "  ollama        - Verifica a saúde do serviço Ollama."
    echo "  workers       - Verifica a saúde de todos os workers."
    echo "  benchmark     - Executa benchmarks de performance do sistema."
    echo "  latency       - Verifica latência de conexão com workers."
}

# =============================================================================
# PONTO DE ENTRADA DO SCRIPT
# =============================================================================
case "${1:-help}" in
    status) show_detailed_status ;;
    diag) show_diagnostics ;;
    logs) view_system_logs ;;
    ollama) check_ollama_health ;;
    workers) check_workers_health ;;
    benchmark) run_performance_benchmarks ;;
    latency) check_worker_latency ;;
    *)
      show_health_help
      exit 1
      ;;
esac
