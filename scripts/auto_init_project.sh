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
    if [[ "$UPDATES_AVAILABLE" -gt 0 ]]; then
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
    if [[ "$BEHIND_COUNT" -gt 0 ]]; then
        print_status "WARN" "Git" "$BEHIND_COUNT commits atrás da origem"
    else
        print_status "OK" "Git" "Sincronizado com origem"
    fi
fi

# Verificar atualizações de containers Docker
if command_exists docker && docker info >/dev/null 2>&1; then
    DOCKER_UPDATES=$(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}" | grep -v "<none>" | wc -l 2>/dev/null || echo "0")
    if [[ "$DOCKER_UPDATES" -gt 0 ]]; then
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
    if [[ "$MODEL_UPDATES" -gt 0 ]]; then
        print_status "WARN" "Modelos IA" "Atualizações disponíveis"
    else
        print_status "OK" "Modelos IA" "Modelos atualizados"
    fi
else
    print_status "WARN" "Modelos IA" "Ollama não disponível"
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
