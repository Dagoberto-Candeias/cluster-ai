#!/bin/bash
# =============================================================================
# Verificador de Saúde e Diagnóstico do Cluster AI
# =============================================================================
# Este script centraliza as funções de status, diagnóstico e visualização de logs.
# É chamado pelo 'manager.sh'.
#
# Autor: Cluster AI Team
# Versão: 1.0.0
# =============================================================================

set -euo pipefail

# Navega para o diretório raiz do projeto para garantir que os caminhos relativos funcionem
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PID_DIR="${PROJECT_ROOT}/.pids"
cd "$PROJECT_ROOT"

# Carregar funções comuns
# shellcheck source=../lib/common.sh
source "scripts/lib/common.sh"

# =============================================================================
# FUNÇÕES DE VERIFICAÇÃO DE SAÚDE
# =============================================================================

show_detailed_status() {
    section "STATUS DETALHADO DO CLUSTER AI"

    echo -e "${CYAN}=== DASK SERVICES ==="${NC}
    local dask_pid_file="${PID_DIR}/dask_cluster.pid"
    if [ -f "$dask_pid_file" ] && ps -p "$(cat "$dask_pid_file")" > /dev/null; then
        echo -e "${GREEN}✓${NC} Dask Cluster (Scheduler + Workers): Rodando (PID: $(cat "$dask_pid_file"))"
    else
        echo -e "${RED}✗${NC} Dask Cluster: Parado"
        # Limpa o arquivo de PID se o processo não estiver rodando
        [ -f "$dask_pid_file" ] && rm -f "$dask_pid_file"
    fi

    echo -e "\n${CYAN}=== WEB SERVICES ==="${NC}
    # Assumindo que web_server.sh cria um .web_server_pid na raiz do projeto
    local web_pid_file="${PROJECT_ROOT}/.web_server_pid"
    if [ -f "$web_pid_file" ] && ps -p "$(cat "$web_pid_file")" > /dev/null; then
        echo -e "${GREEN}✓${NC} Web Server: Rodando (PID: $(cat "$web_pid_file"))"
    else
        echo -e "${RED}✗${NC} Web Server: Parado"
        [ -f "$web_pid_file" ] && rm -f "$web_pid_file"
    fi

    echo -e "\n${CYAN}=== SYSTEM STATUS ==="${NC}
    echo -e "Uptime: $(uptime -p)"
    echo -e "Memory: $(free -h | awk 'NR==2{printf "%.1f%%", $3/$2 * 100.0}')"
    echo -e "Disk: $(df -h . | tail -1 | awk '{print $5}')"
}

show_diagnostics() {
    section "DIAGNÓSTICO DO SISTEMA"

    echo -e "${CYAN}=== SYSTEM INFO ==="${NC}
    echo -e "OS: $(detect_os)"
    echo -e "Distro: $(detect_linux_distro)"
    echo -e "Architecture: $(detect_arch)"
    echo -e "Kernel: $(uname -r)"

    echo -e "\n${CYAN}=== HARDWARE ==="${NC}
    echo -e "CPU: $(nproc) cores"
    echo -e "Memory: $(free -h | awk 'NR==2{printf "%.1fGB/%s", $3/1024, $2}')"
    echo -e "Disk: $(df -h . | tail -1 | awk '{print $3"/"$2" ("$5" usado)"}')"

    echo -e "\n${CYAN}=== NETWORK ==="${NC}
    echo -e "Public IP: $(get_public_ip)"
    echo -e "Local IP: $(hostname -I | awk '{print $1}')"

    echo -e "\n${CYAN}=== SERVICES ==="${NC}
    show_detailed_status
}

view_system_logs() {
    section "VISUALIZANDO LOGS DO SISTEMA"

    if [ -f "logs/cluster_ai.log" ]; then
        echo -e "${CYAN}=== ÚLTIMAS 20 LINHAS DO LOG PRINCIPAL ==="${NC}
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
    echo "  status   - Mostra o status detalhado dos serviços."
    echo "  diag     - Executa um diagnóstico completo do sistema."
    echo "  logs     - Exibe os logs recentes do sistema."
}

# =============================================================================
# PONTO DE ENTRADA DO SCRIPT
# =============================================================================
case "${1:-help}" in
    status) show_detailed_status ;;
    diag) show_diagnostics ;;
    logs) view_system_logs ;;
    *)
      show_health_help
      exit 1
      ;;
esac