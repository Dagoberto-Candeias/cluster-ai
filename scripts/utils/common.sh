#!/bin/bash
# Biblioteca de funções comuns para os scripts do Cluster AI

# --- Configuração de Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Funções de Log ---
log() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

fail() {
    echo -e "${RED}❌ $1${NC}"
}

# --- Funções de Verificação ---

# Verifica se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verifica se um serviço systemd está ativo
service_active() {
    systemctl is-active --quiet "$1"
}

# Verifica se um processo está rodando (usando pgrep)
process_running() {
    pgrep -f "$1" >/dev/null
}