#!/bin/bash
# =============================================================================
# Painel de Controle do Cluster AI - Versão Modular
# =============================================================================
# Este script serve como o ponto central para gerenciar todos os serviços
#
# Autor: Cluster AI Team
# Data: 2025-01-27
# Versão: 2.0.0
# Arquivo: manager_fixed.sh
# =============================================================================

set -euo pipefail

# Wrapper de compatibilidade: delega para manager.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "${SCRIPT_DIR}/manager.sh" ]; then
  exec "${SCRIPT_DIR}/manager.sh" "$@"
else
  echo "[ERROR] manager.sh não encontrado em ${SCRIPT_DIR}. Verifique a instalação."
  exit 1
fi
