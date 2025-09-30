#!/bin/bash
# =============================================================================
# Script de Inicialização Automática de Serviços - Cluster AI
# =============================================================================
# Inicia automaticamente os serviços essenciais:
# - Dashboard Model Registry
# - Web Dashboard Frontend
# - Backend API
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# =============================================================================

# set -euo pipefail
umask 027

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/logs"
SERVICES_LOG="${LOG_DIR}/services_startup.log"

MAX_RETRIES=3
RETRY_DELAY=5 # segundos

mkdir -p "$LOG_DIR"
chmod 750 "$LOG_DIR" 2>/dev/null || true

# Função para log detalhado (apenas para arquivo)
log_service() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$SERVICES_LOG"
}

# Função para verificar se serviço está rodando
is_service_running() {
    local check_command="$1"
    eval "$check_command" >/dev/null 2>&1
}

# Função para iniciar serviço
start_service() {
    local service_name="$1"
    local start_command="$2"
    local check_command="$3"
    local attempt=1

    printf "  %-30s" "$service_name"
    while [[ $attempt -le $MAX_RETRIES ]]; do
        log_service "$service_name: Attempting to start (attempt $attempt)"
        if eval "$start_command" >/dev/null 2>&1; then
            sleep 5  # Wait for service to start
            if is_service_running "$check_command"; then
                echo -e "${GREEN}✓ Iniciado${NC}"
                log_service "$service_name: STARTED successfully on attempt $attempt"
                return 0
            else
                log_service "$service_name: Started but failed verification on attempt $attempt"
            fi
        else
            log_service "$service_name: Failed to execute start command on attempt $attempt"
        fi
        if [[ $attempt -lt $MAX_RETRIES ]]; then
            echo -e "${YELLOW}Falhou. Tentando novamente em ${RETRY_DELAY}s... (${attempt}/${MAX_RETRIES})${NC}"
            sleep "$RETRY_DELAY"
        fi
        ((attempt++))
    done
    echo -e "${RED}✗ Falha após $MAX_RETRIES tentativas${NC}"
    log_service "$service_name: FAILED after $MAX_RETRIES attempts"
    return 1
}

echo -e "\n${BOLD}${CYAN}🚀 INICIANDO SERVIÇOS AUTOMÁTICOS - CLUSTER AI${NC}\n"

log_service "=== STARTING AUTOMATIC SERVICE INITIALIZATION ==="

# 1. Dashboard Model Registry
SERVICE_NAME="Dashboard Model Registry"
DASHBOARD_DIR="${PROJECT_ROOT}/ai-ml/model-registry/dashboard"
DASHBOARD_PID_FILE="${DASHBOARD_DIR}/dashboard.pid"
DASHBOARD_PORT=5000

# Kill any existing instances
if lsof -i :${DASHBOARD_PORT} >/dev/null 2>&1; then
    echo "Port ${DASHBOARD_PORT} is in use, assuming Dashboard Model Registry is running"
else
    pkill -f "python.*app.py" || true
    sleep 2
fi

# Start the service
START_CMD="cd '${DASHBOARD_DIR}' && nohup python3 app.py > dashboard.log 2>&1 & echo \$! > '${DASHBOARD_PID_FILE}'"
CHECK_CMD="curl -fsS --max-time 5 http://127.0.0.1:${DASHBOARD_PORT}/health >/dev/null 2>&1"

if ! is_service_running "$CHECK_CMD"; then
    start_service "$SERVICE_NAME" "$START_CMD" "$CHECK_CMD"
else
    printf "  %-30s" "$SERVICE_NAME"
    echo -e "${GREEN}✓ Já rodando${NC}"
    log_service "$SERVICE_NAME: Already running"
fi

# 2. Web Dashboard Frontend
SERVICE_NAME="Web Dashboard Frontend"
START_CMD="cd '${PROJECT_ROOT}' && docker compose up -d frontend"
CHECK_CMD="docker compose ps frontend | grep -q Up"

if ! is_service_running "$CHECK_CMD"; then
    start_service "$SERVICE_NAME" "$START_CMD" "$CHECK_CMD"
else
    printf "  %-30s" "$SERVICE_NAME"
    echo -e "${GREEN}✓ Já rodando${NC}"
    log_service "$SERVICE_NAME: Already running"
fi

# 3. Backend API
SERVICE_NAME="Backend API"
START_CMD="cd '${PROJECT_ROOT}' && docker compose up -d backend"
CHECK_CMD="docker compose ps backend | grep -q Up"

if ! is_service_running "$CHECK_CMD"; then
    start_service "$SERVICE_NAME" "$START_CMD" "$CHECK_CMD"
else
    printf "  %-30s" "$SERVICE_NAME"
    echo -e "${GREEN}✓ Já rodando${NC}"
    log_service "$SERVICE_NAME: Already running"
fi

echo -e "\n${BOLD}${GREEN}✅ INICIALIZAÇÃO AUTOMÁTICA CONCLUÍDA${NC}"
echo -e "${GRAY}Log detalhado: $SERVICES_LOG${NC}"

log_service "=== AUTOMATIC SERVICE INITIALIZATION COMPLETED ==="
