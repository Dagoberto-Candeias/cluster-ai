#!/bin/bash
# =============================================================================
# Painel de Controle do Cluster AI - Versão Modular
# =============================================================================
# Este script serve como o ponto central para gerenciar todos os serviços
#
# Autor: Cluster AI Team
# Data: 2025-01-27
# Versão: 2.0.0
# Arquivo: manager.sh
# =============================================================================

set -euo pipefail

# Carregar biblioteca comum
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
source "${PROJECT_ROOT}/scripts/utils/common_functions.sh"

# Inicializar ambiente
init_script_environment "manager.sh"

# =============================================================================
# CONFIGURAÇÕES
# =============================================================================

MENU_TITLE="CLUSTER AI - PAINEL DE CONTROLE PRINCIPAL"
VERSION="2.0.0"

# =============================================================================
# FUNÇÕES DO MENU
# =============================================================================

show_header() {
    clear
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC} ${BOLD}${MENU_TITLE}${NC}"
    echo -e "${BOLD}${BLUE}║${NC} Versão: ${VERSION} | Data: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${BOLD}${BLUE}║${NC} Projeto: ${PROJECT_ROOT}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
}

show_main_menu() {
    echo -e "\n${BOLD}${CYAN}MENU PRINCIPAL${NC}"
    echo -e "${CYAN}$(printf '%.0s─' {1..50})${NC}"
    echo -e "${GREEN}1.${NC} Status do Sistema"
    echo -e "${GREEN}2.${NC} Gerenciar Serviços"
    echo -e "${GREEN}3.${NC} Gerenciar Workers"
    echo -e "${GREEN}4.${NC} Gerenciar Modelos Ollama"
    echo -e "${GREEN}5.${NC} Monitoramento e Logs"
    echo -e "${GREEN}6.${NC} Configurações"
    echo -e "${GREEN}7.${NC} Manutenção e Backup"
    echo -e "${GREEN}8.${NC} Testes e Diagnósticos"
    echo -e "${GREEN}9.${NC} Documentação e Ajuda"
    echo -e "${RED}0.${NC} Sair"
    echo -e "\n${YELLOW}Escolha uma opção [0-9]:${NC} "
}

# =============================================================================
# FUNÇÕES DE AÇÃO
# =============================================================================

handle_system_status() {
    section "STATUS DO SISTEMA"
    
    echo -e "${CYAN}Escolha uma opção:${NC}"
    echo -e "${GREEN}1.${NC} Dashboard Completo"
    echo -e "${GREEN}2.${NC} Status Rápido"
    echo -e "${GREEN}3.${NC} Health Check Detalhado"
    echo -e "${GREEN}4.${NC} Informações do Hardware"
    echo -e "${RED}0.${NC} Voltar"
    
    read -p "Opção: " choice
    
    case $choice in
        1) "${PROJECT_ROOT}/scripts/utils/system_status_dashboard.sh" ;;
        2) "${PROJECT_ROOT}/scripts/utils/health_check.sh" status ;;
        3) "${PROJECT_ROOT}/scripts/utils/health_check.sh" diag ;;
        4) "${PROJECT_ROOT}/scripts/utils/health_check.sh" diag ;;
        0) return ;;
        *) error "Opção inválida!" ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

handle_services() {
    section "GERENCIAR SERVIÇOS"
    
    echo -e "${CYAN}Escolha uma opção:${NC}"
    echo -e "${GREEN}1.${NC} Iniciar Todos os Serviços"
    echo -e "${GREEN}2.${NC} Parar Todos os Serviços"
    echo -e "${GREEN}3.${NC} Reiniciar Serviços"
    echo -e "${GREEN}4.${NC} Status dos Serviços"
    echo -e "${GREEN}5.${NC} Docker Compose"
    echo -e "${RED}0.${NC} Voltar"
    
    read -p "Opção: " choice
    
    case $choice in
        1) 
            info "Iniciando todos os serviços..."
            "${PROJECT_ROOT}/scripts/auto_start_services.sh"
            ;;
        2) 
            if confirm_critical "Parar todos os serviços"; then
                "${PROJECT_ROOT}/stop_cluster.sh"
            fi
            ;;
        3) 
            if confirm "Reiniciar todos os serviços?"; then
                "${PROJECT_ROOT}/restart_cluster.sh"
            fi
            ;;
        4) 
            "${PROJECT_ROOT}/scripts/utils/health_check.sh" services
            ;;
        5) 
            echo -e "${CYAN}Docker Compose:${NC}"
            echo -e "${GREEN}a.${NC} Iniciar (docker compose up -d)"
            echo -e "${GREEN}b.${NC} Parar (docker compose down)"
            echo -e "${GREEN}c.${NC} Status (docker compose ps)"
            read -p "Opção: " docker_choice
            case $docker_choice in
                a) docker compose up -d ;;
                b) docker compose down ;;
                c) docker compose ps ;;
                *) error "Opção inválida!" ;;
            esac
            ;;
        0) return ;;
        *) error "Opção inválida!" ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

handle_workers() {
    section "GERENCIAR WORKERS"
    
    echo -e "${CYAN}Escolha uma opção:${NC}"
    echo -e "${GREEN}1.${NC} Listar Workers"
    echo -e "${GREEN}2.${NC} Adicionar Worker"
    echo -e "${GREEN}3.${NC} Remover Worker"
    echo -e "${GREEN}4.${NC} Health Check Workers"
    echo -e "${GREEN}5.${NC} Monitor de Performance"
    echo -e "${GREEN}6.${NC} Auto-scaling"
    echo -e "${RED}0.${NC} Voltar"
    
    read -p "Opção: " choice
    
    case $choice in
        1) "${PROJECT_ROOT}/scripts/management/worker_manager.sh" list ;;
        2) "${PROJECT_ROOT}/scripts/management/worker_manager.sh" add ;;
        3) "${PROJECT_ROOT}/scripts/management/worker_manager.sh" remove ;;
        4) "${PROJECT_ROOT}/scripts/management/worker_manager.sh" health-all ;;
        5) 
            read -p "Nome do worker: " worker_name
            "${PROJECT_ROOT}/scripts/management/worker_manager.sh" monitor "$worker_name"
            ;;
        6) "${PROJECT_ROOT}/scripts/management/worker_manager.sh" auto-scale ;;
        0) return ;;
        *) error "Opção inválida!" ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

handle_models() {
    section "GERENCIAR MODELOS OLLAMA"
    
    echo -e "${CYAN}Escolha uma opção:${NC}"
    echo -e "${GREEN}1.${NC} Listar Modelos Instalados"
    echo -e "${GREEN}2.${NC} Instalar Modelo"
    echo -e "${GREEN}3.${NC} Remover Modelo"
    echo -e "${GREEN}4.${NC} Atualizar Modelos"
    echo -e "${GREEN}5.${NC} Categorias de Modelos"
    echo -e "${GREEN}6.${NC} Health Check Modelos"
    echo -e "${RED}0.${NC} Voltar"
    
    read -p "Opção: " choice
    
    case $choice in
        1) ollama list ;;
        2) 
            read -p "Nome do modelo (ex: llama3): " model_name
            ollama pull "$model_name"
            ;;
        3) 
            read -p "Nome do modelo para remover: " model_name
            if confirm_critical "Remover modelo $model_name"; then
                ollama rm "$model_name"
            fi
            ;;
        4) "${PROJECT_ROOT}/scripts/ollama/model_manager.sh" update-all ;;
        5) "${PROJECT_ROOT}/scripts/ollama/model_manager.sh" categories ;;
        6) "${PROJECT_ROOT}/scripts/utils/health_check.sh" models ;;
        0) return ;;
        *) error "Opção inválida!" ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

handle_monitoring() {
    section "MONITORAMENTO E LOGS"
    
    echo -e "${CYAN}Escolha uma opção:${NC}"
    echo -e "${GREEN}1.${NC} Ver Logs do Sistema"
    echo -e "${GREEN}2.${NC} Monitoramento em Tempo Real"
    echo -e "${GREEN}3.${NC} Métricas de Performance"
    echo -e "${GREEN}4.${NC} Alertas e Notificações"
    echo -e "${GREEN}5.${NC} Limpar Logs Antigos"
    echo -e "${RED}0.${NC} Voltar"
    
    read -p "Opção: " choice
    
    case $choice in
        1) "${PROJECT_ROOT}/scripts/utils/health_check.sh" logs ;;
        2)
            info "Abrindo dashboards de monitoramento..."
            echo -e "Grafana: ${CYAN}http://localhost:3001${NC}"
            echo -e "Prometheus: ${CYAN}http://localhost:9090${NC}"
            echo -e "Dask Dashboard: ${CYAN}http://localhost:8787${NC}"
            ;;
        3) "${PROJECT_ROOT}/scripts/utils/health_check.sh" diag ;;
        4) "${PROJECT_ROOT}/scripts/monitoring/central_monitor.sh" alerts ;;
        5)
            if confirm "Limpar logs com mais de 30 dias?"; then
                cleanup_old_logs 30
            fi
            ;;
        0) return ;;
        *) error "Opção inválida!" ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

handle_configuration() {
    section "CONFIGURAÇÕES"
    
    echo -e "${CYAN}Escolha uma opção:${NC}"
    echo -e "${GREEN}1.${NC} Configurações do Cluster"
    echo -e "${GREEN}2.${NC} Configurações de Rede"
    echo -e "${GREEN}3.${NC} Configurações de Segurança"
    echo -e "${GREEN}4.${NC} Variáveis de Ambiente"
    echo -e "${GREEN}5.${NC} Backup de Configurações"
    echo -e "${RED}0.${NC} Voltar"
    
    read -p "Opção: " choice
    
    case $choice in
        1) "${PROJECT_ROOT}/scripts/management/config_manager.sh" cluster ;;
        2) "${PROJECT_ROOT}/scripts/management/config_manager.sh" network ;;
        3) "${PROJECT_ROOT}/scripts/security/auth_manager.sh" config ;;
        4) 
            echo -e "${CYAN}Variáveis de ambiente principais:${NC}"
            env | grep -E "(CLUSTER|OLLAMA|DASK)" || echo "Nenhuma variável específica encontrada"
            ;;
        5) "${PROJECT_ROOT}/scripts/backup/backup_manager.sh" config ;;
        0) return ;;
        *) error "Opção inválida!" ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

handle_maintenance() {
    section "MANUTENÇÃO E BACKUP"
    
    echo -e "${CYAN}Escolha uma opção:${NC}"
    echo -e "${GREEN}1.${NC} Backup Completo"
    echo -e "${GREEN}2.${NC} Restaurar Backup"
    echo -e "${GREEN}3.${NC} Limpeza do Sistema"
    echo -e "${GREEN}4.${NC} Atualizações"
    echo -e "${GREEN}5.${NC} Verificar Integridade"
    echo -e "${RED}0.${NC} Voltar"
    
    read -p "Opção: " choice
    
    case $choice in
        1) "${PROJECT_ROOT}/scripts/backup/backup_manager.sh" full ;;
        2) "${PROJECT_ROOT}/scripts/backup/backup_manager.sh" restore ;;
        3) "${PROJECT_ROOT}/scripts/management/cleanup_manager_secure.sh" ;;
        4) "${PROJECT_ROOT}/scripts/maintenance/auto_updater.sh" ;;
        5) "${PROJECT_ROOT}/scripts/validation/integrity_checker.sh" ;;
        0) return ;;
        *) error "Opção inválida!" ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

handle_diagnostics() {
    section "TESTES E DIAGNÓSTICOS"
    
    echo -e "${CYAN}Escolha uma opção:${NC}"
    echo -e "${GREEN}1.${NC} Teste Completo do Sistema"
    echo -e "${GREEN}2.${NC} Teste de Conectividade"
    echo -e "${GREEN}3.${NC} Benchmark de Performance"
    echo -e "${GREEN}4.${NC} Validação de Configurações"
    echo -e "${GREEN}5.${NC} Teste de Segurança"
    echo -e "${RED}0.${NC} Voltar"
    
    read -p "Opção: " choice
    
    case $choice in
        1) "${PROJECT_ROOT}/scripts/tests/run_all_tests.sh" ;;
        2) "${PROJECT_ROOT}/scripts/management/worker_manager.sh" validate-ssh ;;
        3) "${PROJECT_ROOT}/scripts/utils/health_check.sh" diag ;;
        4) "${PROJECT_ROOT}/scripts/validation/config_validator.sh" ;;
        5) "${PROJECT_ROOT}/scripts/security/security_audit.sh" ;;
        0) return ;;
        *) error "Opção inválida!" ;;
    esac
    
    read -p "Pressione Enter para continuar..."
}

handle_help() {
    section "DOCUMENTAÇÃO E AJUDA"

    echo -e "${CYAN}Escolha uma opção:${NC}"
    echo -e "${GREEN}1.${NC} Manual de Instalação"
    echo -e "${GREEN}2.${NC} Guia Rápido"
    echo -e "${GREEN}3.${NC} Troubleshooting"
    echo -e "${GREEN}4.${NC} Documentação Técnica"
    echo -e "${GREEN}5.${NC} Sobre o Projeto"
    echo -e "${RED}0.${NC} Voltar"

    read -p "Opção: " choice

    case $choice in
        1)
            if [ -f "${PROJECT_ROOT}/docs/manuals/INSTALACAO.md" ]; then
                less "${PROJECT_ROOT}/docs/manuals/INSTALACAO.md"
            else
                info "Abrindo README principal..."
                less "${PROJECT_ROOT}/README.md"
            fi
            ;;
        2)
            if [ -f "${PROJECT_ROOT}/docs/guides/QUICK_START.md" ]; then
                less "${PROJECT_ROOT}/docs/guides/QUICK_START.md"
            else
                info "Consulte o README.md para início rápido"
            fi
            ;;
        3)
            if [ -f "${PROJECT_ROOT}/docs/guides/TROUBLESHOOTING.md" ]; then
                less "${PROJECT_ROOT}/docs/guides/TROUBLESHOOTING.md"
            else
                info "Execute: ./scripts/utils/health_check.sh diag"
            fi
            ;;
        4) less "${PROJECT_ROOT}/docs/TECHNICAL_DOCUMENTATION.md" ;;
        5)
            echo -e "${BOLD}${BLUE}CLUSTER AI v${VERSION}${NC}"
            echo -e "Sistema Universal de IA Distribuída"
            echo -e "Desenvolvido pela Cluster AI Team"
            echo -e "Licença: MIT"
            echo -e "Repositório: https://github.com/cluster-ai"
            ;;
        0) return ;;
        *) error "Opção inválida!" ;;
    esac

    read -p "Pressione Enter para continuar..."
}



# =============================================================================
# LOOP PRINCIPAL
# =============================================================================

main_loop() {
    while true; do
        show_header
        show_main_menu
        
        read -r choice
        
        case $choice in
            1) handle_system_status ;;
            2) handle_services ;;
            3) handle_workers ;;
            4) handle_models ;;
            5) handle_monitoring ;;
            6) handle_configuration ;;
            7) handle_maintenance ;;
            8) handle_diagnostics ;;
            9) handle_help ;;
            0)
                info "Encerrando Cluster AI Manager..."
                audit_log "MANAGER_EXIT" "User exited manager interface"
                exit 0
                ;;
            *)
                error "Opção inválida! Escolha um número de 0 a 10."
                sleep 2
                ;;
        esac
    done
}

# =============================================================================
# PONTO DE ENTRADA
# =============================================================================

main() {
    # Verificar dependências básicas
    if ! check_dependencies "docker" "python3"; then
        error "Dependências críticas não encontradas!"
        exit 1
    fi
    
    # Verificar se estamos no diretório correto
    if [ ! -f "${PROJECT_ROOT}/README.md" ]; then
        error "Execute este script a partir do diretório raiz do projeto!"
        exit 1
    fi
    
    # Log de início
    audit_log "MANAGER_START" "Manager interface started"
    
    # Iniciar loop principal
    main_loop
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
