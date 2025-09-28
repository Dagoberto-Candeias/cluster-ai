#!/usr/bin/env bash
# =============================================================================
# Ensure Python Virtual Environment (.venv) - Cluster AI
# =============================================================================
# Creates and maintains a project-local Python virtual environment at .venv
# and installs dependencies from requirements.txt and requirements-dev.txt
# when requested. This script is safe to run multiple times.
#
# Usage:
#   scripts/utils/ensure_venv.sh [--dev]
#     --dev  Also install development dependencies
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$PROJECT_ROOT"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${YELLOW}[ensure_venv]${NC} $1"; }
success() { echo -e "${GREEN}[ensure_venv]${NC} $1"; }
error() { echo -e "${RED}[ensure_venv]${NC} $1" >&2; }

USE_DEV=0
if [[ "${1:-}" == "--dev" ]]; then
  USE_DEV=1
fi

# Detect Python 3
PYTHON_BIN="python3"
if ! command -v "$PYTHON_BIN" >/dev/null 2>&1; then
  error "python3 not found in PATH"
  exit 1
fi

# Create venv if missing
if [[ ! -d .venv ]]; then
  info "Creating virtual environment at ${PROJECT_ROOT}/.venv"
  "$PYTHON_BIN" -m venv .venv
fi

# Upgrade pip/setuptools/wheel
info "Upgrading pip, setuptools, wheel"
"${PROJECT_ROOT}/.venv/bin/python" -m pip install --upgrade pip setuptools wheel

# Install runtime requirements
if [[ -f requirements.txt ]]; then
  info "Installing requirements.txt"
  "${PROJECT_ROOT}/.venv/bin/pip" install -r requirements.txt
else
  info "requirements.txt not found; skipping"
fi

# Optionally install dev requirements
if [[ $USE_DEV -eq 1 ]]; then
  if [[ -f requirements-dev.txt ]]; then
    info "Installing requirements-dev.txt"
    "${PROJECT_ROOT}/.venv/bin/pip" install -r requirements-dev.txt
  else
    info "requirements-dev.txt not found; skipping"
  fi
fi

success "Virtual environment ready at ${PROJECT_ROOT}/.venv"
info "Activate with: source .venv/bin/activate"
