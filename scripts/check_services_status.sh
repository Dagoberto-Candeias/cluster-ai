#!/bin/bash
# =============================================================================
# Script de Verificação de Status de Serviços - Cluster AI (Desenvolvimento)
# =============================================================================
# Verifica o status dos serviços e fornece orientações para inicialização
# Adaptado para ambiente de desenvolvimento com SQLite
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.1
# Arquivo: check_services_status.sh
# =============================================================================

set -euo pipefail

# Verificar se o terminal suporta cores
if [[ -t 1 ]] && [[ -n "${TERM:-}" ]] && [[ "${TERM}" != "dumb" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    GRAY='\033[0;37m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    GRAY=''
    BOLD=''
    NC=''
fi

# Carregar biblioteca comum
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Configurações
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/logs"
STATUS_LOG="${LOG_DIR}/services_status.log"

# Criar diretório de logs se não existir
mkdir -p "$LOG_DIR"

# Função para log
log_status() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$STATUS_LOG"
}

# Função para verificar serviço
check_service() {
    local service_name="$1"
    local check_command="$2"
    local start_command="$3"

    printf "  %-25s" "$service_name"

    if eval "$check_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Rodando${NC}"
        log_status "$service_name: RUNNING"
        return 0
    else
        echo -e "${RED}✗ Parado${NC}"
        echo -e "    ${CYAN}Para iniciar: $start_command${NC}"
        log_status "$service_name: STOPPED"
        return 1
    fi
}

# Função para verificar serviço de desenvolvimento (sempre "ok")
check_dev_service() {
    local service_name="$1"
    local note="$2"

    printf "  %-25s" "$service_name"
    echo -e "${GREEN}✓ $note${NC}"
    log_status "$service_name: $note"
    return 0
}

# Iniciar log
log_status "=== VERIFICAÇÃO DE STATUS DOS SERVIÇOS ==="

echo -e "\n${BOLD}${CYAN}🔍 VERIFICANDO STATUS DOS SERVIÇOS - CLUSTER AI${NC}\n"

stopped_services=0

# Verificar serviços principais
echo -e "${BOLD}${BLUE}SERVIÇOS PRINCIPAIS${NC}"

# Dashboard Model Registry
if ! check_service "Dashboard Model Registry" \
    "curl -s --max-time 2 http://localhost:5000 > /dev/null 2>&1" \
    "cd ai-ml/model-registry/dashboard && python app.py"; then
    ((stopped_services++))
fi

# Web Dashboard Frontend
if ! check_service "Web Dashboard Frontend" \
    "docker ps | grep -q frontend" \
    "docker compose up -d frontend"; then
    ((stopped_services++))
fi

# Backend API
if ! check_service "Backend API" \
    "docker ps | grep -q backend" \
    "docker compose up -d backend"; then
    ((stopped_services++))
fi

# Verificar serviços essenciais
echo -e "\n${BOLD}${BLUE}SERVIÇOS ESSENCIAIS${NC}"

# Redis
if ! check_service "Redis" \
    "docker ps | grep -q redis" \
    "docker compose up -d redis"; then
    ((stopped_services++))
fi

# PostgreSQL (desabilitado em desenvolvimento - usa SQLite)
check_dev_service "PostgreSQL (Dev)" "SQLite em uso"

# Ollama
if ! check_service "Ollama" \
    "pgrep -f 'ollama' > /dev/null 2>&1" \
    "ollama serve"; then
    ((stopped_services++))
fi

# Status final
echo -e "\n${BOLD}${BLUE}STATUS GERAL${NC}"

if [ $stopped_services -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} ${BOLD}Todos os serviços essenciais estão rodando!${NC}"
    log_status "ALL_SERVICES_RUNNING"
else
    echo -e "  ${YELLOW}⚠️${NC}  ${BOLD}$stopped_services serviço(s) parado(s)${NC}"
    echo -e "  ${CYAN}💡 Execute os comandos sugeridos acima para iniciar${NC}"
    log_status "SERVICES_STOPPED: $stopped_services"
fi

echo -e "\n${GRAY}Log detalhado: $STATUS_LOG${NC}"
echo -e "${GRAY}Ambiente: Desenvolvimento (SQLite)${NC}"

log_status "=== VERIFICAÇÃO CONCLUÍDA ==="
