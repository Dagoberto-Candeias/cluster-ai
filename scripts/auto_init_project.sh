#!/bin/bash
# =============================================================================
# Script de Inicialização Automática do Projeto Cluster AI
# =============================================================================
# Garante que todos os serviços sejam inicializados corretamente
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: auto_init_project.sh
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
AUTO_INIT_LOG="${LOG_DIR}/auto_init.log"

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

# Função para iniciar serviço automaticamente
start_service_auto() {
    local service_name="$1"
    local check_cmd="$2"
    local start_cmd="$3"

    if eval "$check_cmd" >/dev/null 2>&1; then
        return 0  # Já rodando
    fi

    echo -e "  ${YELLOW}Iniciando $service_name...${NC}"
    log_detailed "Starting $service_name"

    if eval "$start_cmd" >/dev/null 2>&1; then
        sleep 10
        if eval "$check_cmd" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓ $service_name iniciado com sucesso${NC}"
            log_detailed "$service_name started successfully"
            return 0
        else
            echo -e "  ${RED}✗ Falha ao verificar $service_name${NC}"
            log_detailed "$service_name failed to verify"
            return 1
        fi
    else
        echo -e "  ${RED}✗ Falha ao iniciar $service_name${NC}"
        log_detailed "$service_name failed to start"
        return 1
    fi
}

# Iniciar log
log_detailed "=== INICIANDO SISTEMA CLUSTER AI ==="

# =============================================================================
# CLUSTER AI - STATUS DO SISTEMA
# =============================================================================

echo -e "\n${BOLD}${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
echo -e "${BOLD}${CYAN}│                    🚀 CLUSTER AI STATUS                    │${NC}"
echo -e "${BOLD}${CYAN}└─────────────────────────────────────────────────────────────┘${NC}\n"

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

if [[ -f "$PROJECT_ROOT/config/cluster.conf" ]]; then
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

# VERIFICAÇÃO DE ATUALIZAÇÕES
echo -e "\n${BOLD}${BLUE}VERIFICAÇÃO DE ATUALIZAÇÕES${NC}"

# Verificar atualizações do sistema
if command_exists apt-get && sudo -n apt-get update >/dev/null 2>&1; then
    UPDATES_AVAILABLE=$(apt-get -s upgrade | grep -c "^Inst" 2>/dev/null || echo "0")
    if [ "${UPDATES_AVAILABLE:-0}" -gt 0 ] 2>/dev/null; then
        print_status "WARN" "Sistema" "$UPDATES_AVAILABLE pacotes para atualizar"
    else
        print_status "OK" "Sistema" "Atualizado"
    fi
else
    print_status "WARN" "Sistema" "Verificação não disponível"
fi

# Verificar atualizações do Git
if [[ -d ".git" ]]; then
    git fetch --quiet >/dev/null 2>&1
    BEHIND_COUNT=$(git rev-list HEAD...origin/main --count 2>/dev/null || git rev-list HEAD...origin/master --count 2>/dev/null || echo "0")
    if [ "${BEHIND_COUNT:-0}" -gt 0 ] 2>/dev/null; then
        print_status "WARN" "Git" "$BEHIND_COUNT commits atrás da origem"
    else
        print_status "OK" "Git" "Sincronizado com origem"
    fi
fi

# Verificar atualizações de containers Docker
if command_exists docker && docker info >/dev/null 2>&1; then
    DOCKER_UPDATES=$(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}" | grep -v "<none>" | wc -l 2>/dev/null || echo "0")
    if [ "${DOCKER_UPDATES:-0}" -gt 0 ] 2>/dev/null; then
        print_status "OK" "Docker" "Imagens disponíveis para atualização"
    else
        print_status "OK" "Docker" "Imagens atualizadas"
    fi
else
    print_status "WARN" "Docker" "Não disponível para verificação"
fi

# Verificar atualizações de modelos IA (Ollama)
if command_exists ollama; then
    MODEL_UPDATES=$(ollama list 2>/dev/null | grep -c "pull" || echo "0")
    if [ "${MODEL_UPDATES:-0}" -gt 0 ] 2>/dev/null; then
        print_status "WARN" "Modelos IA" "Atualizações disponíveis"
    else
        print_status "OK" "Modelos IA" "Modelos atualizados"
    fi
else
    print_status "WARN" "Modelos IA" "Ollama não disponível"
fi

# INICIANDO SERVIÇOS AUTOMATICAMENTE
echo -e "\n${BOLD}${BLUE}INICIANDO SERVIÇOS AUTOMATICAMENTE${NC}"

# Iniciar Ollama se não estiver rodando
if ! pgrep -f "ollama" >/dev/null 2>&1; then
    start_service_auto "Ollama" "pgrep -f 'ollama'" "ollama serve > /dev/null 2>&1 &"
else
    echo -e "  ${GREEN}✓ Ollama já está rodando${NC}"
fi

# Iniciar Dashboard Model Registry se não estiver rodando
if ! pgrep -f "app.py" >/dev/null 2>&1; then
    start_service_auto "Dashboard Model Registry" "pgrep -f 'app.py'" "cd ai-ml/model-registry/dashboard && /home/dcm/Projetos/cluster-ai/cluster-ai-env/bin/python app.py > /dev/null 2>&1 &"
else
    echo -e "  ${GREEN}✓ Dashboard Model Registry já está rodando${NC}"
fi

# Iniciar serviços Docker se disponíveis
if command_exists docker && docker info >/dev/null 2>&1; then
    # Frontend
    if ! docker ps | grep -q frontend; then
        start_service_auto "Web Dashboard Frontend" "docker ps | grep -q frontend" "docker compose up -d frontend"
    else
        echo -e "  ${GREEN}✓ Web Dashboard Frontend já está rodando${NC}"
    fi

    # Backend
    if ! docker ps | grep -q backend; then
        start_service_auto "Backend API" "docker ps | grep -q backend" "docker compose up -d backend"
    else
        echo -e "  ${GREEN}✓ Backend API já está rodando${NC}"
    fi

    # Redis
    if ! docker ps | grep -q redis; then
        start_service_auto "Redis" "docker ps | grep -q redis" "docker compose up -d redis"
    else
        echo -e "  ${GREEN}✓ Redis já está rodando${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠️ Docker não disponível para iniciar serviços${NC}"
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

# SERVIDORES E ENDEREÇOS
echo -e "\n${BOLD}${BLUE}🖥️ SERVIDORES E ENDEREÇOS${NC}"

# Verificar portas abertas e serviços
echo -e "${BOLD}Portas e Serviços Ativos:${NC}"
netstat -tlnp 2>/dev/null | grep LISTEN | awk '{print "  " $4 " - " $7}' | sed 's/.*://;s/\/.*//' | sort -u | while read port pid; do
    service_name=$(ps -p $pid -o comm= 2>/dev/null || echo "desconhecido")
    case $port in
        22) echo -e "  ${GREEN}SSH${NC}                    Porta $port" ;;
        80) echo -e "  ${GREEN}HTTP${NC}                   Porta $port" ;;
        443) echo -e "  ${GREEN}HTTPS${NC}                  Porta $port" ;;
        3000) echo -e "  ${GREEN}OpenWebUI (Chat IA)${NC}    Porta $port" ;;
        3001) echo -e "  ${GREEN}Grafana${NC}                Porta $port" ;;
        5000) echo -e "  ${GREEN}Model Registry${NC}         Porta $port" ;;
        8080) echo -e "  ${GREEN}Backend API${NC}            Porta $port" ;;
        8081) echo -e "  ${GREEN}VSCode Server${NC}          Porta $port" ;;
        8082) echo -e "  ${GREEN}Android Worker${NC}        Porta $port" ;;
        8888) echo -e "  ${GREEN}Jupyter Lab${NC}           Porta $port" ;;
        9090) echo -e "  ${GREEN}Prometheus${NC}             Porta $port" ;;
        5601) echo -e "  ${GREEN}Kibana${NC}                 Porta $port" ;;
        *) echo -e "  ${CYAN}Serviço customizado${NC}     Porta $port ($service_name)" ;;
    esac
done

# Endereços IP
echo -e "\n${BOLD}Endereços IP Locais:${NC}"
ip addr show 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print "  " $2}' | cut -d'/' -f1 | while read ip; do
    echo -e "  ${CYAN}IP Local${NC}               $ip"
done

# Hardware
echo -e "\n${BOLD}Hardware:${NC}"
if command_exists nvidia-smi; then
    gpu_info=$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1)
    if [[ -n "$gpu_info" ]]; then
        gpu_name=$(echo $gpu_info | cut -d',' -f1 | xargs)
        gpu_mem=$(echo $gpu_info | cut -d',' -f2 | xargs)
        echo -e "  ${GREEN}GPU${NC}                    $gpu_name (${gpu_mem}MB)"
    fi
fi

cpu_info=$(lscpu 2>/dev/null | grep "Model name" | cut -d':' -f2 | xargs)
if [[ -n "$cpu_info" ]]; then
    echo -e "  ${GREEN}CPU${NC}                    $cpu_info"
fi

mem_total=$(free -h 2>/dev/null | awk 'NR==2{print $2}')
if [[ -n "$mem_total" ]]; then
    echo -e "  ${GREEN}Memória RAM${NC}            $mem_total"
fi

# Ambientes Virtuais
echo -e "\n${BOLD}Ambientes Virtuais Python:${NC}"
if [[ -d "cluster-ai-env" ]]; then
    python_version=$(source cluster-ai-env/bin/activate && python --version 2>&1 | cut -d' ' -f2)
    echo -e "  ${GREEN}cluster-ai-env${NC}         Ambiente principal (Python $python_version)"
else
    echo -e "  ${RED}cluster-ai-env${NC}         Ambiente virtual não encontrado"
fi

echo -e "\n${GRAY}Nota: Ambiente virtual único para evitar duplicação de pacotes e economizar espaço."
echo -e "  - cluster-ai-env: Ambiente principal com todas as dependências do projeto${NC}"

# LINKS ÚTEIS DAS INTERFACES WEB
echo -e "\n${BOLD}${BLUE}🌐 INTERFACES WEB DISPONÍVEIS${NC}"
echo -e "  ${GREEN}🖥️  OpenWebUI (Chat IA)${NC}           http://localhost:3000"
echo -e "  ${GREEN}📈 Grafana (Monitoramento)${NC}      http://localhost:3001"
echo -e "  ${GREEN}📊 Prometheus${NC}                   http://localhost:9090"
echo -e "  ${GREEN}📋 Kibana (Logs)${NC}                http://localhost:5601"
echo -e "  ${GREEN}💻 VSCode Server (AWS)${NC}          http://localhost:8081"
echo -e "  ${GREEN}📱 Android Worker Interface${NC}     http://localhost:8082"
echo -e "  ${CYAN}🔍 Jupyter Lab${NC}                 http://localhost:8888"
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
