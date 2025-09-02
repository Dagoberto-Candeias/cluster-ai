#!/bin/bash
# Instalador One-Click para Worker Android
# Baixa e executa o script de configuração automaticamente

set -euo pipefail

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${BLUE}[INSTALLER]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# Verificar se está no Termux
check_environment() {
    if [[ ! -d "/data/data/com.termux" ]]; then
        echo -e "${RED}[ERRO]${NC} Este script deve ser executado no Termux!"
        echo "Instale o Termux: https://termux.dev/"
        exit 1
    fi
    success "Ambiente Termux detectado"
}

# Baixar script de configuração
download_script() {
    log "Baixando script de configuração..."

    if ! curl -fsSL -o setup_worker.sh \
        "https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker_simple.sh"; then
        error "Falha ao baixar o script"
        exit 1
    fi

    success "Script baixado com sucesso"
}

# Executar configuração
run_setup() {
    log "Executando configuração..."

    if [[ ! -x "setup_worker.sh" ]]; then
        chmod +x setup_worker.sh
    fi

    # Executar o script
    ./setup_worker.sh

    # Limpar arquivo temporário
    rm -f setup_worker.sh
}

# Função principal
main() {
    echo
    echo "🤖 CLUSTER AI - INSTALADOR ONE-CLICK"
    echo "====================================="
    echo
    warn "Este script irá configurar seu Android como worker"
    echo

    check_environment
    download_script
    run_setup

    echo
    success "Instalação concluída! 🎉"
    echo
}

# Executar
main
