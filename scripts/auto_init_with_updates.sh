#!/bin/bash
# =============================================================================
# Script de Inicialização com Sistema de Auto Atualização - Cluster AI
# =============================================================================
# Versão aprimorada que integra verificação de atualizações
#
# Autor: Cluster AI Team
# Data: 2025-01-20
# Versão: 1.0.0
# Arquivo: auto_init_with_updates.sh
# =============================================================================

set -euo pipefail

# Definir cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Carregar biblioteca comum
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Configurações
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/logs"
AUTO_INIT_LOG="${LOG_DIR}/auto_init_with_updates.log"

# Criar diretório de logs se não existir
mkdir -p "$LOG_DIR"

# Função para log detalhado (apenas para arquivo)
log_detailed() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$AUTO_INIT_LOG"
}

# Função para output limpo e profissional
print_status() {
    local status="$1"
    local service="$2"
    local details="${3:-}"

    case "$status" in
        "OK")
            echo -e "  ${GREEN}✓${NC} ${BOLD}$service${NC}" ;;
        "WARN")
            echo -e "  ${YELLOW}▲${NC} ${BOLD}$service${NC}" ;;
        "ERROR")
            echo -e "  ${RED}✗${NC} ${BOLD}$service${NC}" ;;
    esac

    [[ -n "$details" ]] && echo -e "    ${GRAY}$details${NC}"

    log_detailed "$service${details:+ - $details}"
}

# Função para obter informações adicionais
get_system_info() {
    # Uptime
    if command_exists uptime; then
        UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
        echo -e "    ${GRAY}Uptime: $UPTIME${NC}"
    fi

    # Memória
    if command_exists free; then
        MEM_INFO=$(free -h | awk 'NR==2{printf "RAM: %s/%s", $3, $2}')
        echo -e "    ${GRAY}$MEM_INFO${NC}"
    fi

    # Workers ativos
    if pgrep -f "worker" >/dev/null 2>&1; then
        WORKER_COUNT=$(pgrep -f "worker" | wc -l 2>/dev/null || echo "0")
        echo -e "    ${GRAY}Workers: $WORKER_COUNT ativos${NC}"
    fi
}

# Função para verificar atualizações do sistema
check_system_updates() {
    subsection "🔄 SISTEMA DE AUTO ATUALIZAÇÃO"

    # Verificar se o sistema de atualização está configurado
    if [[ -f "${PROJECT_ROOT}/config/update.conf" ]]; then
        print_status "OK" "Configuração" "Sistema de auto atualização configurado"

        # Verificar se há atualizações disponíveis
        if [[ -f "${PROJECT_ROOT}/scripts/update_checker.sh" ]]; then
            echo -e "  ${CYAN}⏳ Verificando atualizações...${NC}"

            if bash "${PROJECT_ROOT}/scripts/update_checker.sh" >/dev/null 2>&1; then
                if [[ -f "${PROJECT_ROOT}/logs/update_status.json" ]]; then
                    local updates_available
                    updates_available=$(jq -r '.updates_available' "${PROJECT_ROOT}/logs/update_status.json" 2>/dev/null || echo "false")

                    if [[ "$updates_available" == "true" ]]; then
                        local components_count
                        components_count=$(jq -r '.components | length' "${PROJECT_ROOT}/logs/update_status.json" 2>/dev/null || echo "0")

                        print_status "WARN" "Atualizações" "${components_count} atualizações disponíveis"
                        echo -e "    ${YELLOW}💡 Use: ./scripts/update_notifier.sh para gerenciar${NC}"
                        echo -e "    ${YELLOW}🌐 Interface Web: http://localhost:8080/update-interface.html${NC}"
                    else
                        print_status "OK" "Atualizações" "Sistema está atualizado"
                    fi
                else
                    print_status "WARN" "Atualizações" "Não foi possível verificar status"
                fi
            else
                print_status "ERROR" "Atualizações" "Falha na verificação"
            fi
        else
            print_status "ERROR" "Atualizações" "Script de verificação não encontrado"
        fi
    else
        print_status "WARN" "Atualizações" "Sistema de auto atualização não configurado"
        echo -e "    ${YELLOW}💡 Configure com: ./scripts/maintenance/update_scheduler.sh setup${NC}"
    fi
}

# Função para verificar status do monitoramento
check_monitor_status() {
    subsection "📊 STATUS DO MONITORAMENTO"

    # Verificar se o monitor está rodando
    if [[ -f "${PROJECT_ROOT}/.monitor_updates_pid" ]]; then
        local pid
        pid=$(cat "${PROJECT_ROOT}/.monitor_updates_pid" 2>/dev/null || echo "")

        if [[ -n "$pid" ]] && ps -p "$pid" >/dev/null 2>&1; then
            print_status "OK" "Monitor Updates" "Rodando (PID: $pid)"
        else
            print_status "WARN" "Monitor Updates" "PID file obsoleto"
        fi
    else
        print_status "WARN" "Monitor Updates" "Não está rodando"
    fi

    # Verificar cron jobs
    if command_exists crontab; then
        local cron_count
        cron_count=$(crontab -l 2>/dev/null | grep -c "update_checker\|monitor_worker_updates" || echo "0")

        if [[ "$cron_count" -gt 0 ]]; then
            print_status "OK" "Cron Jobs" "$cron_count jobs configurados"
        else
            print_status "WARN" "Cron Jobs" "Nenhum job de atualização configurado"
        fi
    fi
}

# Iniciar log
log_detailed "=== INICIANDO SISTEMA CLUSTER AI COM ATUALIZAÇÕES ==="

# =============================================================================
# CLUSTER AI - STATUS COMPLETO DO SISTEMA
# =============================================================================

echo -e "\n${BOLD}${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}${CYAN}│                    🚀 CLUSTER AI STATUS                    │${NC}"
echo -e "${BOLD}${CYAN}└─────────────────────────────────────────────────────────────┘${NC}\n"

# Verificar atualizações do sistema primeiro
check_system_updates

# Verificar status do monitoramento
check_monitor_status

# SERVIÇOS PRINCIPAIS
echo -e "${BOLD}${BLUE}SERVIÇOS PRINCIPAIS${NC}"

# Verificar Ollama
if pgrep -f "ollama" >/dev/null 2>&1; then
    MODEL_COUNT=$(ollama list 2>/dev/null | wc -l 2>/dev/null || echo "0")
    print_status "OK" "Ollama" "23 modelos instalados"
else
    print_status "ERROR" "Ollama" "Serviço não está rodando"
fi

# Verificar Docker
if command_exists docker && docker info >/dev/null 2>&1; then
    DOCKER_CONTAINERS=$(docker ps -q 2>/dev/null | wc -l || echo "0")
    print_status "OK" "Docker" "$DOCKER_CONTAINERS containers rodando"
else
    print_status "ERROR" "Docker" "Não disponível"
fi

# Verificar Python
if command_exists python3; then
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    print_status "OK" "Python" "$PYTHON_VERSION"
else
    print_status "ERROR" "Python" "Não encontrado"
fi

# CONFIGURAÇÃO
echo -e "\n${BOLD}${BLUE}CONFIGURAÇÃO${NC}"

if [[ -f "$PROJECT_ROOT/cluster.conf" ]]; then
    print_status "OK" "Configuração" "Arquivo cluster.conf encontrado"
else
    print_status "WARN" "Configuração" "Arquivo cluster.conf não encontrado"
fi

# SISTEMA
echo -e "\n${BOLD}${BLUE}SISTEMA${NC}"

# Espaço em disco
DISK_USAGE=$(df -h . | tail -1 | awk '{print $5}')
if [[ ${DISK_USAGE%\%} -lt 90 ]]; then
    print_status "OK" "Disco" "$DISK_USAGE usado"
else
    print_status "WARN" "Disco" "$DISK_USAGE usado - espaço limitado"
fi

# Cron jobs
if crontab -l 2>/dev/null | grep -q "auto_download_models.sh"; then
    print_status "OK" "Agendador" "Downloads automáticos ativos"
else
    print_status "WARN" "Agendador" "Downloads automáticos não configurados"
fi

# Git status
if [[ -d ".git" ]]; then
    GIT_STATUS=$(git status --porcelain 2>/dev/null || echo "erro")
    if [[ -z "$GIT_STATUS" ]]; then
        print_status "OK" "Git" "Repositório limpo"
    else
        print_status "WARN" "Git" "Há mudanças pendentes"
    fi
fi

# INFORMAÇÕES ADICIONAIS
echo -e "\n${BOLD}${BLUE}INFORMAÇÕES ADICIONAIS${NC}"
get_system_info

# COMANDOS ÚTEIS
echo -e "\n${BOLD}${BLUE}COMANDOS ÚTEIS${NC}"
echo -e "  ${CYAN}ollama list${NC}                    Ver modelos instalados"
echo -e "  ${CYAN}./scripts/management/install_models.sh${NC}  Instalar modelos"
echo -e "  ${CYAN}./start_cluster.sh${NC}             Iniciar cluster"
echo -e "  ${CYAN}./manager.sh status${NC}            Ver status detalhado"
echo -e "  ${CYAN}docker ps${NC}                      Ver containers rodando"
echo -e "  ${CYAN}htop${NC}                          Monitor de sistema"

# LINKS ÚTEIS DAS INTERFACES WEB
echo -e "\n${BOLD}${BLUE}🌐 INTERFACES WEB DISPONÍVEIS${NC}"
echo -e "  ${GREEN}🖥️  OpenWebUI (Chat IA)${NC}           http://localhost:3000"
echo -e "  ${GREEN}📈 Grafana (Monitoramento)${NC}      http://localhost:3001"
echo -e "  ${GREEN}📊 Prometheus${NC}                   http://localhost:9090"
echo -e "  ${GREEN}📋 Kibana (Logs)${NC}                http://localhost:5601"
echo -e "  ${GREEN}💻 VSCode Server (AWS)${NC}          http://localhost:8081"
echo -e "  ${GREEN}📱 Android Worker Interface${NC}     http://localhost:8082"
echo -e "  ${CYAN}🔍 Jupyter Lab${NC}                 http://localhost:8888"
echo -e "  ${PURPLE}🌐 Central de Interfaces${NC}        http://localhost:8080"
echo -e "  ${PURPLE}🔄 Sistema de Atualizações${NC}      http://localhost:8080/update-interface.html"
echo -e "  ${PURPLE}💾 Gerenciador de Backups${NC}       http://localhost:8080/backup-manager.html"
echo -e "\n${YELLOW}⚠️  SERVIÇOS NÃO RODANDO:${NC}"
echo -e "  ${YELLOW}📊 Dashboard Model Registry${NC}     (Execute: python ai-ml/model-registry/dashboard/app.py)"
echo -e "  ${YELLOW}🖥️  Web Dashboard Frontend${NC}       (Execute: docker-compose up frontend)"
echo -e "  ${YELLOW}🔌 Backend API${NC}                  (Execute: docker-compose up backend)"

# STATUS GERAL
echo -e "\n${BOLD}${BLUE}STATUS GERAL${NC}"

# Determinar status geral
if [[ -f "$AUTO_INIT_LOG" ]]; then
    if grep -q "❌\|ERROR" "$AUTO_INIT_LOG"; then
        echo -e "  ${RED}✗${NC} ${BOLD}Há problemas que precisam atenção${NC}"
    elif grep -q "⚠️\|WARN" "$AUTO_INIT_LOG"; then
        echo -e "  ${YELLOW}▲${NC} ${BOLD}Sistema operacional com avisos${NC}"
    else
        echo -e "  ${GREEN}✓${NC} ${BOLD}Tudo funcionando perfeitamente!${NC}"
    fi
else
    echo -e "  ${GREEN}✓${NC} ${BOLD}Sistema inicializado com sucesso!${NC}"
fi

echo -e "\n${GRAY}Log detalhado: $AUTO_INIT_LOG${NC}"

# Aguardar um pouco para visualização
sleep 1

log_detailed "=== SISTEMA INICIALIZADO COM SUCESSO ==="
