#!/bin/bash
# Manager Refatorado - Cluster AI
# Versão: 2.0 - Painel de controle central unificado

set -euo pipefail

# ==================== CONFIGURAÇÃO INICIAL ====================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/scripts/lib/common.sh"
MANAGEMENT_SCRIPTS_DIR="${SCRIPT_DIR}/scripts/management"

if [ ! -f "$COMMON_SCRIPT" ]; then
    echo "ERRO: Script de funções comuns não encontrado: $COMMON_SCRIPT"
    exit 1
fi
source "$COMMON_SCRIPT"

PROJECT_ROOT="$SCRIPT_DIR"
CONFIG_FILE="${PROJECT_ROOT}/cluster.conf"
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/manager_$(date +%Y%m%d_%H%M%S).log"

# ==================== FUNÇÕES ====================

show_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   CLUSTER AI - MANAGER                     ║"
    echo "║                Painel de Controle Central                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "Diretório do projeto: $PROJECT_ROOT"
    echo "Log do manager: $LOG_FILE"
    echo ""
}

load_config_safe() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        success "Configuração carregada: $CONFIG_FILE"
    else
        warn "Arquivo de configuração não encontrado. Execute ./install.sh primeiro."
        return 1
    fi
}

show_main_menu() {
    section "Menu Principal"
    echo "🎯 GERENCIAMENTO DO CLUSTER:"
    echo "1. Status do Sistema"
    echo "2. Iniciar Serviços"
    echo "3. Parar Serviços"
    echo "4. Reiniciar Serviços"
    echo "5. Ver Logs"
    echo ""
    echo "🔧 CONFIGURAÇÃO:"
    echo "6. Configurar Cluster"
    echo "7. Editar Configuração"
    echo "8. Otimizar Recursos"
    echo ""
    echo "📦 OPERAÇÕES:"
    echo "9. Backup"
    echo "10. Restaurar Backup"
    echo "11. Instalar Modelos AI"
    echo "12. Limpeza do Sistema"
    echo ""
    echo "❓ AJUDA:"
    echo "13. Verificar Saúde"
    echo "14. Testar Instalação"
    echo "15. Sair"
    echo ""
}

show_status() {
    section "Status do Sistema"
    
    # Informações do sistema
    echo -e "${CYAN}💻 Informações do Sistema:${NC}"
    echo "  Hostname: $(hostname)"
    echo "  IP: $(get_ip)"
    echo "  OS: $(detect_os)"
    echo "  CPU: $(nproc) cores"
    echo "  Memória: $(free -h | awk '/Mem:/ {print $2}') total"
    echo "  Disco: $(df -h / | awk 'NR==2 {print $4}') livre"
    
    # Status dos serviços
    echo -e "\n${CYAN}🔄 Status dos Serviços:${NC}"
    check_service_status "ollama" "Ollama"
    check_service_status "docker" "Docker"
    check_process_status "dask-scheduler" "Dask Scheduler"
    check_process_status "dask-worker" "Dask Worker"
    
    # Portas abertas
    echo -e "\n${CYAN}🚪 Portas Abertas:${NC}"
    check_port_status "$OLLAMA_PORT" "Ollama"
    check_port_status "$DASK_SCHEDULER_PORT" "Dask Scheduler"
    check_port_status "$DASK_DASHBOARD_PORT" "Dask Dashboard"
    check_port_status "$OPENWEBUI_PORT" "OpenWebUI"
}

check_service_status() {
    local service="$1"
    local name="$2"
    if service_active "$service"; then
        echo "  ✅ $name: ${GREEN}ATIVO${NC}"
    else
        echo "  ❌ $name: ${RED}INATIVO${NC}"
    fi
}

check_process_status() {
    local process="$1"
    local name="$2"
    if process_running "$process"; then
        echo "  ✅ $name: ${GREEN}EXECUTANDO${NC}"
    else
        echo "  ❌ $name: ${RED}PARADO${NC}"
    fi
}

check_port_status() {
    local port="$1"
    local name="$2"
    if port_open "$port"; then
        echo "  ✅ $name (porta $port): ${GREEN}ABERTA${NC}"
    else
        echo "  ❌ $name (porta $port): ${RED}FECHADA${NC}"
    fi
}

start_services() {
    section "Iniciando Serviços"
    load_config_safe || return 1
    
    case "$CLUSTER_ROLE" in
        server)
            start_server_services
            ;;
        workstation|worker)
            start_client_services
            ;;
        *)
            error "Papel do cluster desconhecido: $CLUSTER_ROLE"
            return 1
            ;;
    esac
}

start_server_services() {
    info "Iniciando serviços do servidor..."
    
    # Ollama
    if service_active ollama; then
        info "Ollama já está rodando"
    else
        run_sudo "systemctl start ollama" "Iniciando Ollama"
    fi
    
    # Dask Scheduler
    if ! process_running "dask-scheduler"; then
        run_command "dask scheduler --port $DASK_SCHEDULER_PORT --dashboard-address :$DASK_DASHBOARD_PORT > ${LOG_DIR}/dask_scheduler.log 2>&1 &" "Iniciando Dask Scheduler"
        sleep 2
    fi
    
    # Dask Worker local
    if ! process_running "dask-worker"; then
        run_command "dask worker tcp://localhost:$DASK_SCHEDULER_PORT --nworkers $DASK_NUM_WORKERS --nthreads $DASK_NUM_THREADS > ${LOG_DIR}/dask_worker.log 2>&1 &" "Iniciando Dask Worker local"
        sleep 2
    fi
    
    success "Serviços do servidor iniciados"
}

start_client_services() {
    info "Iniciando serviços do cliente..."
    info "Verificando conectividade com servidor: $CLUSTER_SERVER_IP"
    
    if ! ping -c 1 -W 2 "$CLUSTER_SERVER_IP" >/dev/null 2>&1; then
        error "Servidor inacessível: $CLUSTER_SERVER_IP"
        return 1
    fi
    
    # Dask Worker
    if ! process_running "dask-worker"; then
        run_command "dask worker tcp://${CLUSTER_SERVER_IP}:${DASK_SCHEDULER_PORT} --nworkers $DASK_NUM_WORKERS --nthreads $DASK_NUM_THREADS > ${LOG_DIR}/dask_worker.log 2>&1 &" "Iniciando Dask Worker"
        sleep 2
    fi
    
    success "Serviços do cliente iniciados"
}

stop_services() {
    section "Parando Serviços"
    
    # Parar Dask workers
    if process_running "dask-worker"; then
        run_command "pkill -f \"dask-worker\"" "Parando Dask Workers"
        sleep 1
    fi
    
    # Parar Dask scheduler
    if process_running "dask-scheduler"; then
        run_command "pkill -f \"dask-scheduler\"" "Parando Dask Scheduler"
        sleep 1
    fi
    
    # Parar Ollama
    if service_active ollama; then
        run_sudo "systemctl stop ollama" "Parando Ollama"
    fi
    
    success "Serviços parados"
}

restart_services() {
    section "Reiniciando Serviços"
    stop_services
    sleep 2
    start_services
}

show_logs() {
    section "Visualização de Logs"
    echo "📋 LOGS DISPONÍVEIS:"
    echo "1. Logs de Instalação"
    echo "2. Logs do Ollama"
    echo "3. Logs do Dask"
    echo "4. Logs do Sistema"
    echo "5. Logs em Tempo Real"
    echo "6. Voltar"
    echo ""
    
    read -p "Selecione uma opção [1-6]: " choice
    case $choice in
        1) tail -n 20 "${LOG_DIR}/install_"* 2>/dev/null || echo "Nenhum log de instalação encontrado" ;;
        2) journalctl -u ollama -n 20 --no-pager ;;
        3) tail -n 20 "${LOG_DIR}/dask_"*.log 2>/dev/null || echo "Nenhum log do Dask encontrado" ;;
        4) journalctl -n 20 --no-pager ;;
        5) tail -f "${LOG_DIR}/"*.log ;;
        6) return ;;
        *) warn "Opção inválida" ;;
    esac
}

configure_cluster() {
    section "Configurar Papel do Cluster"
    if [ -f "${SCRIPT_DIR}/scripts/lib/install_functions.sh" ]; then
        source "${SCRIPT_DIR}/scripts/lib/install_functions.sh"
        setup_cluster_role
    else
        error "Funções de instalação não encontradas"
    fi
}

edit_config() {
    section "Editar Configuração"
    if [ ! -f "$CONFIG_FILE" ]; then
        error "Arquivo de configuração não encontrado. Execute ./install.sh primeiro."
        return 1
    fi
    
    if command_exists nano; then
        nano "$CONFIG_FILE"
    elif command_exists vim; then
        vim "$CONFIG_FILE"
    elif command_exists vi; then
        vi "$CONFIG_FILE"
    else
        error "Nenhum editor de texto encontrado (nano, vim, vi)"
        return 1
    fi
    
    info "Configuração editada. Reinicie os serviços para aplicar as mudanças."
}

optimize_resources() {
    section "Otimizar Recursos"
    if [ -f "${SCRIPT_DIR}/scripts/utils/resource_optimizer.sh" ]; then
        bash "${SCRIPT_DIR}/scripts/utils/resource_optimizer.sh" optimize
    else
        error "Otimizador de recursos não encontrado"
    fi
}

run_backup() {
    section "Backup do Sistema"
    if [ -f "${SCRIPT_DIR}/scripts/backup/backup_manager.sh" ]; then
        bash "${SCRIPT_DIR}/scripts/backup/backup_manager.sh"
    else
        error "Script de backup não encontrado"
    fi
}

install_ai_models() {
    section "Instalar Modelos AI"
    if [ -f "${SCRIPT_DIR}/scripts/lib/install_functions.sh" ]; then
        source "${SCRIPT_DIR}/scripts/lib/install_functions.sh"
        install_ollama_models
    else
        error "Funções de instalação não encontradas"
    fi
}

cleanup_system() {
    section "Limpeza do Sistema"
    if [ -f "${SCRIPT_DIR}/scripts/utils/resource_optimizer.sh" ]; then
        bash "${SCRIPT_DIR}/scripts/utils/resource_optimizer.sh" clean-disk
    else
        error "Otimizador de recursos não encontrado"
    fi
}

check_health() {
    section "Verificar Saúde do Sistema"
    if [ -f "${SCRIPT_DIR}/scripts/utils/health_check.sh" ]; then
        bash "${SCRIPT_DIR}/scripts/utils/health_check.sh"
    else
        error "Script de verificação de saúde não encontrado"
    fi
}

run_tests() {
    section "Testar Instalação"
    if [ -f "${SCRIPT_DIR}/run_tests.sh" ]; then
        bash "${SCRIPT_DIR}/run_tests.sh"
    else
        warn "Script de testes não encontrado. Criando em scripts/validation/"
    fi
}

process_menu_choice() {
    local choice="$1"
    case $choice in
        1) show_status ;;
        2) start_services ;;
        3) stop_services ;;
        4) restart_services ;;
        5) show_logs ;;
        6) configure_cluster ;;
        7) edit_config ;;
        8) optimize_resources ;;
        9) run_backup ;;
        10) info "Restaurar backup será implementado" ;;
        11) install_ai_models ;;
        12) cleanup_system ;;
        13) check_health ;;
        14) run_tests ;;
        15) info "Saindo..."; exit 0 ;;
        *) warn "Opção inválida"; return 1 ;;
    esac
}

main() {
    exec > >(tee -a "$LOG_FILE") 2>&1
    show_banner
    
    if [ ! -f "$CONFIG_FILE" ]; then
        warn "Arquivo de configuração não encontrado. Execute ./install.sh primeiro."
        if confirm "Deseja executar o instalador agora?" "y"; then
            bash "${SCRIPT_DIR}/install.sh"
        else
            exit 1
        fi
    fi
    
    load_config_safe || exit 1
    
    while true; do
        show_main_menu
        read -p "Selecione uma opção [1-15]: " choice
        if process_menu_choice "$choice"; then
            if confirm "Deseja voltar ao menu principal?" "y"; then
                continue
            else
                break
            fi
        fi
    done
    
    section "Manager Finalizado"
    success "Operações concluídas com sucesso!"
    info "Log completo disponível em: $LOG_FILE"
}

main "$@"
