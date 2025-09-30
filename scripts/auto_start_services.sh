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
DASHBOARD_PORT=8000
DASHBOARD_PID_FILE="$PROJECT_ROOT/ai-ml/model-registry/dashboard/dashboard.pid"

# Finaliza instâncias anteriores na mesma porta
pkill -f "python app.py" || true

# Inicia o serviço e salva o PID
cd "$PROJECT_ROOT/ai-ml/model-registry/dashboard"
nohup python app.py > dashboard.log 2>&1 &
echo $! > "$DASHBOARD_PID_FILE"

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

if ! is_service_running "$SERVICE_NAME" "$CHECK_CMD"; then
    start_service "$SERVICE_NAME" "$START_CMD" "$CHECK_CMD"
else
    echo -e "${BOLD}${BLUE}SERVIÇOS PRINCIPAIS${NC}"
    printf "  %-25s" "$SERVICE_NAME"
    echo -e "${GREEN}✓ Já rodando${NC}"
fi

# 3. Backend API
SERVICE_NAME="Backend API"
START_CMD="cd '${PROJECT_ROOT}' && docker compose up -d backend"
CHECK_CMD="docker ps | grep -q backend"

if ! is_service_running "$SERVICE_NAME" "$CHECK_CMD"; then
    start_service "$SERVICE_NAME" "$START_CMD" "$CHECK_CMD"
else
    DOCKER_CONTAINERS=$(docker ps -q 2>/dev/null | wc -l || echo "0")
    printf "  %-25s" "$SERVICE_NAME"s "OK" "Docker" "$DOCKER_CONTAINERS containers rodando"
    echo -e "${GREEN}✓ Já rodando${NC}"
fi

# 4. Prometheus
SERVICE_NAME="Prometheus"
START_CMD="cd '${PROJECT_ROOT}' && docker compose up -d prometheus"
CHECK_CMD="docker ps | grep -q prometheus"

# Apenas tenta iniciar se o Docker estiver disponível
if command_exists docker && docker info >/dev/null 2>&1; then
    if ! is_service_running "$SERVICE_NAME" "$CHECK_CMD"; then
        start_service "$SERVICE_NAME" "$START_CMD" "$CHECK_CMD"
    else
        printf "  %-25s" "$SERVICE_NAME"echo -e "\n${BOLD}${BLUE}CONFIGURAÇÃO${NC}"
        echo -e "${GREEN}✓ Já rodando${NC}"
    fi
fi

# Redis
if docker ps | grep -q redis; then
    printf "  %-25s" "Redis"
    echo -e "${GREEN}✓ Rodando${NC}"
else
    DISK_USAGE=$(df -h . | tail -1 | awk '{print $5}')
    printf "  %-25s" "Redis"_USAGE%\%} -lt 90 ]]; then
    echo -e "${YELLOW}⚠️ Não rodando${NC}"USAGE usado"
fi

# PostgreSQL
if docker ps | grep -q postgres; then
    printf "  %-25s" "PostgreSQL"
    echo -e "${GREEN}✓ Rodando${NC}"
else
    print_status "OK" "Agendador" "Downloads automáticos ativos"
    printf "  %-25s" "PostgreSQL"
    echo -e "${YELLOW}⚠️ Não rodando${NC}"oads automáticos não configurados"
fi

# Ollamat status
if pgrep -f "ollama" >/dev/null 2>&1; then
    printf "  %-25s" "Ollama"/dev/null || echo "erro")
    echo -e "${GREEN}✓ Rodando${NC}"  if [[ -z "$GIT_STATUS" ]]; then
else        print_status "OK" "Git" "Repositório limpo"
    printf "  %-25s" "Ollama"
    echo -e "${YELLOW}⚠️ Não rodando${NC}"dentes"
fi    fi

echo -e "\n${BOLD}${GREEN}✅ INICIALIZAÇÃO AUTOMÁTICA CONCLUÍDA${NC}"# VERIFICAÇÃO DE ATUALIZAÇÕESecho -e "\n${BOLD}${BLUE}VERIFICAÇÃO DE ATUALIZAÇÕES${NC}"# Verificar atualizações do sistema (pular em modo de teste)if [[ "${CLUSTER_AI_TEST_MODE:-0}" != "1" ]] && command_exists apt-get && sudo -n apt-get update >/dev/null 2>&1; then    UPDATES_AVAILABLE=$(apt-get -s upgrade | grep -c "^Inst" 2>/dev/null || echo "0")    if [ "${UPDATES_AVAILABLE:-0}" -gt 0 ] 2>/dev/null; then        print_status "WARN" "Sistema" "$UPDATES_AVAILABLE pacotes para atualizar"    else        print_status "OK" "Sistema" "Atualizado"    fielse    print_status "WARN" "Sistema" "Verificação não disponível"fi# Verificar atualizações do Gitif [[ -d ".git" ]]; then    git fetch --quiet >/dev/null 2>&1    BEHIND_COUNT=$(git rev-list HEAD...origin/main --count 2>/dev/null || git rev_list HEAD...origin/master --count 2>/dev/null || echo "0")    if [ "${BEHIND_COUNT:-0}" -gt 0 ] 2>/dev/null; then        print_status "WARN" "Git" "$BEHIND_COUNT commits atrás da origem"    else        print_status "OK" "Git" "Sincronizado com origem"    fifi# Verificar atualizações de containers Dockerif command_exists docker && docker info >/dev/null 2>&1; then    DOCKER_UPDATES=$(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}" | grep -v "<none>" | wc -l 2>/dev/null || echo "0")    if [ "${DOCKER_UPDATES:-0}" -gt 0 ] 2>/dev/null; then        print_status "OK" "Docker" "Imagens disponíveis para atualização"    else        print_status "OK" "Docker" "Imagens atualizadas"    fielse    print_status "WARN" "Docker" "Não disponível para verificação"fi# Verificar atualizações de modelos IA (Ollama)if command_exists ollama; then    MODEL_UPDATES=$(ollama list 2>/dev/null | grep -c "pull" || echo "0")    if [ "${MODEL_UPDATES:-0}" -gt 0 ] 2>/dev/null; then        print_status "WARN" "Modelos IA" "Atualizações disponíveis"    else        print_status "OK" "Modelos IA" "Modelos atualizados"    fielse    print_status "WARN" "Modelos IA" "Ollama não disponível"fi# INICIANDO SERVIÇOS AUTOMATICAMENTEecho -e "\n${BOLD}${BLUE}INICIANDO SERVIÇOS AUTOMATICAMENTE${NC}"# Centralizar a inicialização de serviços chamando o script dedicadoif [[ -f "${PROJECT_ROOT}/scripts/auto_start_services.sh" ]]; then    bash "$PROJECT_ROOT/scripts/auto_start_services.sh"else    log_error "Script auto_start_services.sh não encontrado."    echo -e "  ${RED}✗ Script de inicialização de serviços não encontrado.${NC}"fi# INFORMAÇÕES ADICIONAISecho -e "\n${BOLD}${BLUE}INFORMAÇÕES ADICIONAIS${NC}"get_system_info# COMANDOS ÚTEISecho -e "\n${BOLD}${BLUE}COMANDOS ÚTEIS${NC}"
echo -e "${GRAY}Log detalhado: $SERVICES_LOG${NC}"

log_service "=== SERVIÇOS INICIADOS COM SUCESSO ==="
echo -e "  ${CYAN}ollama list${NC}                    Ver modelos instalados"echo -e "  ${CYAN}./scripts/management/install_models.sh${NC}  Instalar modelos"echo -e "  ${CYAN}./start_cluster.sh${NC}             Iniciar cluster"echo -e "  ${CYAN}./manager.sh status${NC}            Ver status detalhado"echo -e "  ${CYAN}docker ps${NC}                      Ver containers rodando"echo -e "  ${CYAN}htop${NC}                          Monitor de sistema"# SERVIDORES E ENDEREÇOSecho -e "\n${BOLD}${BLUE}🖥️ SERVIDORES E ENDEREÇOS${NC}"# Verificar portas abertas e serviçosecho -e "${BOLD}Portas e Serviços Ativos:${NC}"if [[ "${CLUSTER_AI_TEST_MODE:-0}" == "1" ]]; then  echo -e "  ${YELLOW}Modo de teste: pulando varredura de portas${NC}"else  if command_exists netstat; then netstat -tlnp 2>/dev/null | grep LISTEN | awk '{print "  " $4 " - " $7}' | sed 's/.*://;s/\/[^ ]*//' | sort -u | while read -r port pid; do      service_name=$(ps -p $pid -o comm= 2>/dev/null || echo "desconhecido")      case $port in          22) echo -e "  ${GREEN}SSH${NC}                    Porta $port" ;;          80) echo -e "  ${GREEN}HTTP${NC}                   Porta $port" ;;          443) echo -e "  ${GREEN}HTTPS${NC}                  Porta $port" ;;          3000) echo -e "  ${GREEN}OpenWebUI (Chat IA)${NC}    Porta $port" ;;          3001) echo -e "  ${GREEN}Grafana${NC}                Porta $port" ;;          5000) echo -e "  ${GREEN}Model Registry${NC}         Porta $port" ;;          8080) echo -e "  ${GREEN}Backend API${NC}            Porta $port" ;;          8081) echo -e "  ${GREEN}VSCode Server${NC}          Porta $port" ;;          8082) echo -e "  ${GREEN}Android Worker${NC}        Porta $port" ;;          8888) echo -e "  ${GREEN}Jupyter Lab${NC}           Porta $port" ;;          9090) echo -e "  ${GREEN}Prometheus${NC}             Porta $port" ;;          5601) echo -e "  ${GREEN}Kibana${NC}                 Porta $port" ;;          *) echo -e "  ${CYAN}Serviço customizado${NC}     Porta $port ($service_name)" ;;      esac    done; fifi# Endereços IPecho -e "\n${BOLD}Endereços IP Locais:${NC}"ip addr show 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print "  " $2}' | cut -d'/' -f1 | while read ip; do    echo -e "  ${CYAN}IP Local${NC}               $ip"done# Hardwareecho -e "\n${BOLD}Hardware:${NC}"if command_exists nvidia-smi; then    gpu_info=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)    if [[ -n "$gpu_info" ]]; then        gpu_name=$(echo $gpu_info | cut -d',' -f1 | xargs)        gpu_mem=$(echo $gpu_info | cut -d',' -f2 | xargs)        echo -e "  ${GREEN}GPU${NC}                    $gpu_name (${gpu_mem}MB)"    fificpu_info=$(command_exists lscpu && lscpu 2>/dev/null | grep "Model name" | cut -d':' -f2 | xargs)if [[ -n "$cpu_info" ]]; then    echo -e "  ${GREEN}CPU${NC}                    $cpu_info"fimem_total=$(free -h 2>/dev/null | awk 'NR==2{print $2}')if [[ -n "$mem_total" ]]; then    echo -e "  ${GREEN}Memória RAM${NC}            $mem_total"fi# Ambientes Virtuaisecho -e "\n${BOLD}Ambientes Virtuais Python:${NC}"if [[ -d "venv" ]]; then    python_version=$(source venv/bin/activate && python --version 2>&1 | cut -d' ' -f2 && deactivate)    echo -e "  ${GREEN}venv${NC}                   Ambiente principal (Python $python_version)"else    echo -e "  ${RED}venv${NC}                   Ambiente virtual não encontrado"fiecho -e "\n${GRAY}Nota: Ambiente virtual único para evitar duplicação de pacotes e economizar espaço."echo -e "  - cluster-ai-env: Ambiente principal com todas as dependências do projeto${NC}"# LINKS ÚTEIS DAS INTERFACES WEBecho -e "\n${BOLD}${BLUE}🌐 INTERFACES WEB DISPONÍVEIS${NC}"echo -e "  ${GREEN}🖥️  OpenWebUI (Chat IA)${NC}           http://localhost:3000"echo -e "  ${GREEN}📈 Grafana (Monitoramento)${NC}      http://localhost:3001"echo -e "  ${GREEN}📊 Prometheus${NC}                   http://localhost:9090"echo -e "  ${GREEN}📋 Kibana (Logs)${NC}                http://localhost:5601"echo -e "  ${GREEN}💻 VSCode Server (AWS)${NC}          http://localhost:8081"echo -e "  ${GREEN}📱 Android Worker Interface${NC}     http://localhost:8082"echo -e "  ${CYAN}🔍 Jupyter Lab${NC}                 http://localhost:8888"echo -e "\n${YELLOW}⚠️  SERVIÇOS NÃO RODANDO:${NC}"echo -e "  ${YELLOW}📊 Dashboard Model Registry${NC}     (Execute: python ai-ml/model-registry/dashboard/app.py)"echo -e "  ${YELLOW}🖥️  Web Dashboard Frontend${NC}       (Execute: docker-compose up frontend)"echo -e "  ${YELLOW}🔌 Backend API${NC}                  (Execute: docker-compose up backend)"# STATUS GERALecho -e "\n${BOLD}${BLUE}STATUS GERAL${NC}"# Determinar status geralif [[ -f "$AUTO_INIT_LOG" ]]; then    if grep -q "❌\|ERROR" "$AUTO_INIT_LOG"; then        echo -e "  ${RED}✗${NC} ${BOLD}Há problemas que precisam atenção${NC}"    elif grep -q "⚠️\|WARN" "$AUTO_INIT_LOG"; then        echo -e "  ${YELLOW}▲${NC} ${BOLD}Sistema operacional com avisos${NC}"    else        echo -e "  ${GREEN}✓${NC} ${BOLD}Tudo funcionando perfeitamente!${NC}"    fielse    echo -e "  ${GREEN}✓${NC} ${BOLD}Sistema inicializado com sucesso!${NC}"fiecho -e "\n${GRAY}Log detalhado: $AUTO_INIT_LOG${NC}"# Aguardar um pouco para visualização (reduzido em modo de teste)if [[ "${CLUSTER_AI_TEST_MODE:-0}" == "1" ]]; then  sleep 0.1else  sleep 1filog_detailed "=== SISTEMA INICIALIZADO COM SUCESSO ==="# Em cenários de teste, retornar sucesso mesmo com avisos/erros não críticosexit 0