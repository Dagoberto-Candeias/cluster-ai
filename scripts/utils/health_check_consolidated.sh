#!/bin/bash
# Script Consolidado de Health Check - Cluster AI
# Versão Unificada 2.0 - Combina recursos de health_check.sh e cluster_health_monitor.sh

set -euo pipefail
IFS=$'\n\t'

# ==================== CONFIGURAÇÃO DE SEGURANÇA ====================

# Prevenção de execução como root
if [ "$EUID" -eq 0 ]; then
    echo "ERRO CRÍTICO: Este script NÃO deve ser executado como root."
    echo "Por favor, execute como um usuário normal com privilégios sudo quando necessário."
    exit 1
fi

# Validação do contexto de execução
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
if [ ! -f "$PROJECT_ROOT/README.md" ]; then
    echo "ERRO: Script executado fora do contexto do projeto Cluster AI"
    exit 1
fi

# Carregar funções comuns
COMMON_SCRIPT_PATH="$PROJECT_ROOT/scripts/utils/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns 'common.sh' não encontrado: $COMMON_SCRIPT_PATH"
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# ==================== CONFIGURAÇÕES ====================

# Configurações globais
LOG_FILE="/tmp/cluster_ai_health_check_$(date +%Y%m%d_%H%M%S).log"
REPORT_FILE="/tmp/cluster_health_report_$(date +%Y%m%d_%H%M%S).txt"
OVERALL_HEALTH=true
QUIET_MODE=false
REMOTE_HOST=""
REMOTE_USER=""
MONITOR_MODE=false
MONITOR_INTERVAL=300
