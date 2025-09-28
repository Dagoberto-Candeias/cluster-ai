#!/bin/bash
# =============================================================================
# Cluster Health Monitor - Integração do Health Check com Workers
# =============================================================================
# Versão: 1.0 - Monitoramento Integrado
#
# Autor: Cluster AI Team
# Data: 2025-01-27
# Versão: 2.0.0
# Arquivo: cluster_health_monitor.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

HEALTH_SCRIPT="${PROJECT_ROOT}/scripts/utils/health_check.sh"

if [ ! -f "$HEALTH_SCRIPT" ]; then
  echo "[ERROR] Health check script não encontrado em $HEALTH_SCRIPT"
  exit 1
fi

case "${1:-status}" in
  status) exec "$HEALTH_SCRIPT" status ;;
  diag|diagnostic) exec "$HEALTH_SCRIPT" diag ;;
  services) exec "$HEALTH_SCRIPT" services ;;
  workers) exec "$HEALTH_SCRIPT" workers ;;
  models) exec "$HEALTH_SCRIPT" models ;;
  system) exec "$HEALTH_SCRIPT" system ;;
  help|*)
    echo "Cluster AI - Cluster Health Monitor (wrapper)"
    echo ""
    echo "Uso: $0 [acao]"
    echo "Acoes: status | diag | services | workers | models | system"
    ;;
esac
