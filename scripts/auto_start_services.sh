#!/bin/bash
# =============================================================================
# Script de Inicialização Automática de Serviços - Cluster AI
# =============================================================================

set -euo pipefail
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

# Fallbacks
type command_exists >/dev/null 2>&1 || command_exists() { command -v "$1" >/dev/null 2>&1; }

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

    printf "  %-25s" "$service_name"
    while [[ $attempt -le $MAX_RETRIES ]]; do
        eval "$start_command" >/dev/null 2>&1
        sleep 3
        if is_service_running "$check_command"; then
            echo -e "${GREEN}✓ Iniciado${NC}"
            log_service "$service_name: STARTED on attempt $attempt"
            return 0
        else
            log_service "$service_name: FAILED_TO_VERIFY on attempt $attempt"
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

# 1. Dashboard Model Registry
SERVICE_NAME="Dashboard Model Registry"
DASHBOARD_PID_FILE="${PROJECT_ROOT}/.dashboard_model_registry.pid"
DASHBOARD_PORT=5000

# Finaliza instâncias anteriores na mesma porta
pkill -f "python app.py" || true

# Inicia o serviço e salva o PID
START_CMD="cd '${PROJECT_ROOT}/ai-ml/model-registry/dashboard' && nohup python app.py > dashboard.log 2>&1 & echo \$! > '${DASHBOARD_PID_FILE}'"
CHECK_CMD="curl -fsS --max-time 2 http://127.0.0.1:${DASHBOARD_PORT}/health >/dev/null"

if ! is_service_running "$CHECK_CMD"; then
    start_service "$SERVICE_NAME" "$START_CMD" "$CHECK_CMD"
else
    printf "  %-25s" "$SERVICE_NAME"
    echo -e "${GREEN}✓ Já rodando${NC}"
fi

# 2. Web Dashboard Frontend
SERVICE_NAME="Web Dashboard Frontend"
START_CMD="cd '${PROJECT_ROOT}' && docker compose up -d frontend"
CHECK_CMD="docker ps | grep -q frontend"

if ! is_service_running "$CHECK_CMD"; then
    start_service "$SERVICE_NAME" "$START_CMD" "$CHECK_CMD"
else
    printf "  %-25s" "$SERVICE_NAME"
    echo -e "${GREEN}✓ Já rodando${NC}"
fi

# 3. Backend API
SERVICE_NAME="Backend API"
START_CMD="cd '${PROJECT_ROOT}' && docker compose up -d backend"
CHECK_CMD="docker ps | grep -q backend"

if ! is_service_running "$CHECK_CMD"; then
    start_service "$SERVICE_NAME" "$START_CMD" "$CHECK_CMD"
else
    printf "  %-25s" "$SERVICE_NAME"
    echo -e "${GREEN}✓ Já rodando${NC}"
fi

# 4. Prometheus
SERVICE_NAME="Prometheus"
START_CMD="cd '${PROJECT_ROOT}' && docker compose up -d prometheus"
CHECK_CMD="docker ps | grep -q prometheus"

# Apenas tenta iniciar se o Docker estiver disponível
if command_exists docker && docker info >/dev/null 2>&1; then
    if ! is_service_running "$CHECK_CMD"; then
        start_service "$SERVICE_NAME" "$START_CMD" "$CHECK_CMD"
    else
        printf "  %-25s" "$SERVICE_NAME"
        echo -e "${GREEN}✓ Já rodando${NC}"
    fi
fi

# 5. OpenWebUI
SERVICE_NAME="OpenWebUI"
START_CMD="cd '${PROJECT_ROOT}' && docker compose up -d open-webui"
CHECK_CMD="docker ps | grep -q open-webui"

if command_exists docker && docker info >/dev/null 2>&1; then
    if ! is_service_running "$CHECK_CMD"; then
        start_service "$SERVICE_NAME" "$START_CMD" "$CHECK_CMD"
    else
        printf "  %-25s" "$SERVICE_NAME"
        echo -e "${GREEN}✓ Já rodando${NC}"
    fi
fi

# Start Ollama if installed and not running
if command_exists ollama; then
    if ! pgrep -f "ollama" >/dev/null 2>&1; then
        printf "  %-25s" "Starting Ollama"
        nohup ollama serve > "${LOG_DIR}/ollama.log" 2>&1 &
        sleep 5
        if pgrep -f "ollama" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Iniciado${NC}"
            log_service "Ollama: STARTED"
        else
            echo -e "${RED}✗ Falha${NC}"
            log_service "Ollama: FAILED_TO_START"
        fi
    fi
else
    printf "  %-25s" "Ollama"
    echo -e "${YELLOW}⚠️ Não instalado${NC}"
fi

# Verificar status de outros serviços
echo -e "\n${BOLD}${BLUE}STATUS DE OUTROS SERVIÇOS${NC}"

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
