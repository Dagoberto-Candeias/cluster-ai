#!/bin/bash
# =============================================================================
# Inicialização Robusta do Cluster AI
# =============================================================================
# Script que verifica e inicia automaticamente todos os serviços necessários
#
# Autor: Cluster AI Team
# Data: 2025-01-20
# Versão: 1.0.0
# Arquivo: start_cluster_robust.sh
# =============================================================================

set -euo pipefail

# --- Cores e Estilos ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- Configuração Inicial ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Carregar funções comuns
if [ ! -f "${SCRIPT_DIR}/lib/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${SCRIPT_DIR}/lib/common.sh"

# --- Constantes ---
LOG_DIR="${PROJECT_ROOT}/logs"
COMPLETE_LOG="${LOG_DIR}/cluster_complete.log"
WEB_PORT=8080

# Criar diretórios necessários
mkdir -p "$LOG_DIR"
mkdir -p "$PROJECT_ROOT/web"

# --- Funções ---

# Função para log detalhado
log_complete() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" >> "$COMPLETE_LOG"

    case "$level" in
        "INFO")
            info "$message" ;;
        "WARN")
            warn "$message" ;;
        "ERROR")
            error "$message" ;;
    esac
}

# Função para verificar e iniciar serviços automaticamente
check_and_start_service() {
    local service_name="$1"
    local check_command="$2"
    local start_command="$3"
    local description="${4:-$service_name}"

    log_complete "INFO" "Verificando $description..."

    if eval "$check_command" >/dev/null 2>&1; then
        success "$description já está rodando"
        return 0
    else
        warn "$description não está rodando, iniciando automaticamente..."
        if eval "$start_command"; then
            success "$description iniciado com sucesso"
            return 0
        else
            error "Falha ao iniciar $description"
            return 1
        fi
    fi
}

# Função para configurar sistema de auto atualização
setup_auto_updates() {
    log_complete "INFO" "Configurando sistema de auto atualização..."

    if [[ ! -f "${PROJECT_ROOT}/config/update.conf" ]]; then
        warn "Sistema de auto atualização não configurado"
        if confirm_operation "Deseja configurar o sistema de auto atualização agora?"; then
            if bash "${SCRIPT_DIR}/maintenance/update_scheduler.sh" setup; then
                success "Sistema de auto atualização configurado"
            else
                error "Falha ao configurar sistema de auto atualização"
                return 1
            fi
        fi
    else
        success "Sistema de auto atualização já configurado"
    fi
}

# Função para iniciar servidor web
start_web_server() {
    log_complete "INFO" "Iniciando servidor web..."

    # Verificar se já está rodando
    if [[ -f "${PROJECT_ROOT}/.web_server_pid" ]]; then
        local pid=$(cat "${PROJECT_ROOT}/.web_server_pid" 2>/dev/null || echo "")
        if [[ -n "$pid" ]] && ps -p "$pid" >/dev/null 2>&1; then
            success "Servidor web já está rodando (PID: $pid)"
            return 0
        fi
    fi

    # Verificar arquivos web
    if [[ ! -f "${PROJECT_ROOT}/web/index.html" ]] || [[ ! -f "${PROJECT_ROOT}/web/update-interface.html" ]] || [[ ! -f "${PROJECT_ROOT}/web/backup-manager.html" ]]; then
        warn "Arquivos web não encontrados. Criando arquivos básicos..."
        # Criar arquivos básicos se não existirem
        cat > "${PROJECT_ROOT}/web/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Cluster AI - Central de Interfaces</title></head>
<body><h1>Cluster AI - Central de Interfaces</h1></body>
</html>
EOF
        cat > "${PROJECT_ROOT}/web/update-interface.html" << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Sistema de Atualizações</title></head>
<body><h1>Sistema de Atualizações</h1></body>
</html>
EOF
        cat > "${PROJECT_ROOT}/web/backup-manager.html" << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Gerenciador de Backups</title></head>
<body><h1>Gerenciador de Backups</h1></body>
</html>
EOF
    fi

    # Iniciar servidor web
    if bash "${SCRIPT_DIR}/web_server.sh" start "$WEB_PORT"; then
        success "Servidor web iniciado na porta $WEB_PORT"
        return 0
    else
        error "Falha ao iniciar servidor web"
        return 1
    fi
}

# Função para iniciar monitoramento de atualizações
start_update_monitor() {
    log_complete "INFO" "Iniciando monitoramento de atualizações..."

    # Verificar se já está rodando
    if [[ -f "${PROJECT_ROOT}/.monitor_updates_pid" ]]; then
        local pid=$(cat "${PROJECT_ROOT}/.monitor_updates_pid" 2>/dev/null || echo "")
        if [[ -n "$pid" ]] && ps -p "$pid" >/dev/null 2>&1; then
            success "Monitoramento de atualizações já está rodando (PID: $pid)"
            return 0
        fi
    fi

    if bash "${SCRIPT_DIR}/monitor_worker_updates.sh" start; then
        success "Monitoramento de atualizações iniciado"
        return 0
    else
        warn "Falha ao iniciar monitoramento de atualizações"
        return 1
    fi
}

# Função para verificar status de todos os serviços
check_all_services() {
    log_complete "INFO" "Verificando status de todos os serviços..."

    local services_ok=0
    local services_total=0

    # Verificar servidor web
    ((services_total++))
    if [[ -f "${PROJECT_ROOT}/.web_server_pid" ]]; then
        local pid=$(cat "${PROJECT_ROOT}/.web_server_pid" 2>/dev/null || echo "")
        if [[ -n "$pid" ]] && ps -p "$pid" >/dev/null 2>&1; then
            ((services_ok++))
        fi
    fi

    # Verificar monitoramento de atualizações
    ((services_total++))
    if [[ -f "${PROJECT_ROOT}/.monitor_updates_pid" ]] && ps -p "$(cat "${PROJECT_ROOT}/.monitor_updates_pid" 2>/dev/null)" >/dev/null 2>&1; then
        ((services_ok++))
    fi

    # Verificar cron jobs
    ((services_total++))
    if command_exists crontab && crontab -l 2>/dev/null | grep -q "update_checker\|monitor_worker_updates"; then
        ((services_ok++))
    fi

    echo -e "${BOLD}${BLUE}STATUS DOS SERVIÇOS:${NC}"
    echo -e "  ${GREEN}✓${NC} ${services_ok}/${services_total} serviços funcionando"

    if [[ $services_ok -eq $services_total ]]; then
        success "Todos os serviços estão funcionando!"
    elif [[ $services_ok -gt 0 ]]; then
        warn "Alguns serviços precisam atenção"
    else
        error "Nenhum serviço está funcionando"
    fi
}

# Função para mostrar interfaces disponíveis
show_interfaces() {
    echo -e "\n${BOLD}${BLUE}🌐 INTERFACES WEB DISPONÍVEIS:${NC}"
    echo -e "  ${GREEN}📱 Central de Interfaces${NC}     http://localhost:$WEB_PORT/"
    echo -e "  ${GREEN}🔄 Sistema de Atualizações${NC}  http://localhost:$WEB_PORT/update-interface.html"
    echo -e "  ${GREEN}💾 Gerenciador de Backups${NC}   http://localhost:$WEB_PORT/backup-manager.html"
    echo
    echo -e "${BOLD}${BLUE}📱 OUTRAS INTERFACES:${NC}"
    echo -e "  ${CYAN}🖥️  OpenWebUI (Chat IA)${NC}           http://localhost:3000"
    echo -e "  ${CYAN}📈 Grafana (Monitoramento)${NC}      http://localhost:3001"
    echo -e "  ${CYAN}📊 Prometheus${NC}                   http://localhost:9090"
    echo -e "  ${CYAN}📋 Kibana (Logs)${NC}                http://localhost:5601"
    echo -e "  ${CYAN}💻 VSCode Server (AWS)${NC}          http://localhost:8081"
    echo -e "  ${CYAN}📱 Android Worker Interface${NC}     http://localhost:8082"
    echo -e "  ${CYAN}🔍 Jupyter Lab${NC}                 http://localhost:8888"
}

# Função para comandos rápidos
show_quick_commands() {
    echo -e "\n${BOLD}${BLUE}⚡ COMANDOS RÁPIDOS:${NC}"
    echo -e "  ${CYAN}./scripts/auto_init_with_updates.sh${NC}  Status completo do sistema"
    echo -e "  ${CYAN}./scripts/update_checker.sh${NC}           Verificar atualizações"
    echo -e "  ${CYAN}./scripts/update_notifier.sh${NC}          Interface de atualizações"
    echo -e "  ${CYAN}./scripts/backup_manager.sh${NC}           Gerenciar backups"
    echo -e "  ${CYAN}./scripts/web_server.sh status${NC}        Status do servidor web"
    echo -e "  ${CYAN}./scripts/maintenance/update_scheduler.sh status${NC}  Status do agendamento"
}

# Função principal
main() {
    log_complete "INFO" "=== INICIANDO CLUSTER AI COMPLETO ==="

    echo -e "${BOLD}${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BOLD}${CYAN}│                 🚀 CLUSTER AI - INICIALIZAÇÃO               │${NC}"
    echo -e "${BOLD}${CYAN}└─────────────────────────────────────────────────────────────┘${NC}\n"

    # Configurar sistema de auto atualização
    setup_auto_updates

    # Iniciar servidor web (com verificação automática)
    start_web_server

    # Iniciar monitoramento de atualizações (com verificação automática)
    start_update_monitor

    # Verificar status de todos os serviços
    check_all_services

    # Mostrar interfaces disponíveis
    show_interfaces

    # Mostrar comandos rápidos
    show_quick_commands

    echo -e "\n${BOLD}${GREEN}✅ CLUSTER AI INICIALIZADO COM SUCESSO!${NC}"
    echo -e "${GRAY}Log detalhado: $COMPLETE_LOG${NC}"

    log_complete "INFO" "=== CLUSTER AI INICIALIZADO COM SUCESSO ==="
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
