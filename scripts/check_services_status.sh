#!/bin/bash
# =============================================================================
# Script de Verificação de Status de Serviços - DEPRECADO
# =============================================================================
# Este script foi substituído por:
#  - scripts/utils/system_status_dashboard.sh (visão geral)
#  - scripts/utils/health_check.sh services (serviços)
# Mantido como wrapper para compatibilidade, com aviso claro.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$PROJECT_ROOT"

YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

echo -e "${YELLOW}⚠ Este script foi deprecado. Use:${NC}"
echo -e "  ${BOLD}scripts/utils/system_status_dashboard.sh${NC} (visão geral)"
echo -e "  ${BOLD}scripts/utils/health_check.sh services${NC} (serviços)"

case "${1:-dashboard}" in
  services)
    bash "scripts/utils/health_check.sh" services || true
    ;;
  *)
    bash "scripts/utils/system_status_dashboard.sh" || true
    ;;
esac
