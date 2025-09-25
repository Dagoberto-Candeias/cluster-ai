#!/bin/bash
# =============================================================================
# Script de Inicialização Automática de Serviços - Cluster AI
# =============================================================================
# Inicia automaticamente os serviços necessários quando o projeto é aberto
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: auto_start_services.sh
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
SERVICES_LOG="${LOG_DIR}/services_startup.log"

# Criar diretório de logs se não existir
mkdir -p "$LOG_DIR"

# Função para log
log_service() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$SERVICES_LOG"
}

# Função para verificar se serviço está rodando
is_service_running() {
    local service_name="$1"
    local check_command="$2"

    if eval "$check_command" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Função para iniciar serviço
start_service() {
    local service_name="$1"
    local start_command="$2"
    local check_command="$3"

    printf "  %-25s" "$service_name"

    if eval "$start_command" >/dev/null 2>&1; then
        sleep 3  # Aumentar tempo de espera para containers
        if is_service_running "$service_name" "$check_command"; then
            echo -e "${GREEN}✓ Iniciado${NC}"
            log_service "$service_name: STARTED"
            return 0
        else
            echo -e "${RED}✗ Falha na verificação${NC}"
            log_service "$service_name: FAILED_TO_VERIFY"
            return 1
        fi
    else
        echo -e "${RED}✗ Falha ao iniciar${NC}"
        log_service "$service_name: FAILED_TO_START"
        return 1
    fi
}

# Iniciar log
log_service "=== INICIANDO SERVIÇOS AUTOMÁTICOS ==="

echo -e "\n${BOLD}${CYAN}🚀 INICIANDO SERVIÇOS AUTOMÁTICOS - CLUSTER AI${NC}\n"

# 1. Dashboard Model Registry
SERVICE_NAME="Dashboard Model Registry"
START_CMD="cd ai-ml/model-registry/dashboard && python app.py > /dev/null 2>&1 &"
CHECK_CMD="pgrep -f 'python.*app.py.*model-registry'"

if ! is_service_running "$SERVICE_NAME" "$CHECK_CMD"; then
    start_service "$SERVICE_NAME" "$START_CMD" "$CHECK_CMD"
else
    printf "  %-25s" "$SERVICE_NAME"
    echo -e "${GREEN}✓ Já rodando${NC}"
fi

# 2. Web Dashboard Frontend
SERVICE_NAME="Web Dashboard Frontend"
START_CMD="docker compose up -d frontend"
CHECK_CMD="docker ps | grep -q frontend"

if ! is_service_running "$SERVICE_NAME" "$CHECK_CMD"; then
    start_service "$SERVICE_NAME" "$START_CMD" "$CHECK_CMD"
else
    printf "  %-25s" "$SERVICE_NAME"
    echo -e "${GREEN}✓ Já rodando${NC}"
fi

# 3. Backend API
SERVICE_NAME="Backend API"
START_CMD="docker compose up -d backend"
CHECK_CMD="docker ps | grep -q backend"

if ! is_service_running "$SERVICE_NAME" "$CHECK_CMD"; then
    start_service "$SERVICE_NAME" "$START_CMD" "$CHECK_CMD"
else
    printf "  %-25s" "$SERVICE_NAME"
    echo -e "${GREEN}✓ Já rodando${NC}"
fi

# 4. Verificar se outros serviços essenciais estão rodando
echo -e "\n${BOLD}${BLUE}VERIFICANDO SERVIÇOS ESSENCIAIS${NC}"

# Redis
if docker ps | grep -q redis; then
    printf "  %-25s" "Redis"
    echo -e "${GREEN}✓ Rodando${NC}"
else
    printf "  %-25s" "Redis"
    echo -e "${YELLOW}⚠️ Não rodando${NC}"
fi

# PostgreSQL
if docker ps | grep -q postgres; then
    printf "  %-25s" "PostgreSQL"
    echo -e "${GREEN}✓ Rodando${NC}"
else
    printf "  %-25s" "PostgreSQL"
    echo -e "${YELLOW}⚠️ Não rodando${NC}"
fi

# Ollama
if pgrep -f "ollama" >/dev/null 2>&1; then
    printf "  %-25s" "Ollama"
    echo -e "${GREEN}✓ Rodando${NC}"
else
    printf "  %-25s" "Ollama"
    echo -e "${YELLOW}⚠️ Não rodando${NC}"
fi

echo -e "\n${BOLD}${GREEN}✅ INICIALIZAÇÃO AUTOMÁTICA CONCLUÍDA${NC}"
echo -e "${GRAY}Log detalhado: $SERVICES_LOG${NC}"

log_service "=== SERVIÇOS INICIADOS COM SUCESSO ==="
