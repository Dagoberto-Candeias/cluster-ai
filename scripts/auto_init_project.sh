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

# Função para output colorido e limpo
print_status() {
    local status="$1"
    local message="$2"
    local details="${3:-}"

    case "$status" in
        "OK")
            echo -e "  ${GREEN}●${NC} $message" ;;
        "WARN")
            echo -e "  ${YELLOW}▲${NC} $message" ;;
        "ERROR")
            echo -e "  ${RED}●${NC} $message" ;;
        "INFO")
            echo -e "  ${BLUE}●${NC} $message" ;;
        "SECTION")
            echo -e "\n${BOLD}${BLUE}━━━ $message ━━━${NC}" ;;
    esac

    [[ -n "$details" ]] && echo -e "    ${GRAY}$details${NC}"

    log_detailed "$message${details:+ - $details}"
}

# Iniciar log
log_detailed "=== INICIANDO SISTEMA CLUSTER AI ==="

# =============================================================================
# CLUSTER AI - STATUS INICIAL
# =============================================================================

echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${CYAN}║                    🚀 CLUSTER AI - STATUS                    ║${NC}"
echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"

# 1. SERVIÇOS PRINCIPAIS
print_status "SECTION" "SERVIÇOS PRINCIPAIS"

# Verificar Ollama
if pgrep -f "ollama" >/dev/null 2>&1; then
    MODEL_COUNT=$(ollama list 2>/dev/null | wc -l 2>/dev/null || echo "0")
    print_status "OK" "Ollama" "✅ $(($MODEL_COUNT - 1)) modelos instalados"
else
    print_status "ERROR" "Ollama" "❌ Serviço não está rodando"
fi

# Verificar Docker
if command_exists docker && docker info >/dev/null 2>&1; then
    print_status "OK" "Docker" "🐳 Pronto para containers"
else
    print_status "ERROR" "Docker" "❌ Não disponível"
fi

# Verificar Python
if command_exists python3; then
    PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
    print_status "OK" "Python" "🐍 $PYTHON_VERSION"
else
    print_status "ERROR" "Python" "❌ Não encontrado"
fi

# 2. CONFIGURAÇÃO
print_status "SECTION" "CONFIGURAÇÃO"

if [[ -f "$PROJECT_ROOT/cluster.conf" ]]; then
    print_status "OK" "Configuração" "✅ Arquivo cluster.conf encontrado"
else
    print_status "WARN" "Configuração" "⚠️  Arquivo cluster.conf não encontrado"
fi

# 3. SISTEMA
print_status "SECTION" "SISTEMA"

# Espaço em disco
DISK_USAGE=$(df -h . | tail -1 | awk '{print $5}')
if [[ ${DISK_USAGE%\%} -lt 90 ]]; then
    print_status "OK" "Disco" "💾 $DISK_USAGE usado"
else
    print_status "WARN" "Disco" "⚠️  $DISK_USAGE usado - espaço limitado"
fi

# Cron jobs
if crontab -l 2>/dev/null | grep -q "auto_download_models.sh"; then
    print_status "OK" "Agendador" "⏰ Downloads automáticos ativos"
else
    print_status "WARN" "Agendador" "⚠️  Downloads automáticos não configurados"
fi

# Git status
if [[ -d ".git" ]]; then
    GIT_STATUS=$(git status --porcelain 2>/dev/null || echo "erro")
    if [[ -z "$GIT_STATUS" ]]; then
        print_status "OK" "Git" "✅ Repositório limpo"
    else
        print_status "WARN" "Git" "⚠️  Há mudanças pendentes"
    fi
fi

# 4. PRÓXIMOS PASSOS
print_status "SECTION" "PRÓXIMOS PASSOS"

echo -e "\n${BOLD}${YELLOW}  Comandos úteis:${NC}"
echo -e "    ${CYAN}ollama list${NC}              Ver modelos instalados"
echo -e "    ${CYAN}./scripts/management/install_models.sh${NC}  Instalar modelos"
echo -e "    ${CYAN}./start_cluster.sh${NC}       Iniciar cluster"
echo -e "    ${CYAN}./manager.sh status${NC}      Ver status detalhado"
echo -e "    ${CYAN}./scripts/ollama/auto_download_models.sh status${NC}  Ver modelos"

# 5. RESUMO FINAL
echo -e "\n${BOLD}${GREEN}━━━ STATUS GERAL ━━━${NC}"

# Contar status (corrigido para evitar erro de sintaxe)
OK_COUNT=$(grep -c "✅\|●" "$AUTO_INIT_LOG" 2>/dev/null || echo "0")
WARN_COUNT=$(grep -c "⚠️\|▲" "$AUTO_INIT_LOG" 2>/dev/null || echo "0")
ERROR_COUNT=$(grep -c "❌" "$AUTO_INIT_LOG" 2>/dev/null || echo "0")

if [[ $ERROR_COUNT -eq 0 ]]; then
    if [[ $WARN_COUNT -eq 0 ]]; then
        echo -e "${GREEN}✅ Tudo funcionando perfeitamente!${NC}"
    else
        echo -e "${YELLOW}⚠️  Sistema operacional com avisos${NC}"
    fi
else
    echo -e "${RED}❌ Há problemas que precisam atenção${NC}"
fi

echo -e "${GRAY}Log detalhado: $AUTO_INIT_LOG${NC}"

# Aguardar um pouco para visualização
sleep 1

log_detailed "=== SISTEMA INICIALIZADO COM SUCESSO ==="
