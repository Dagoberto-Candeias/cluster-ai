#!/bin/bash
# Script principal de instalação para Cluster AI
# Consolida instalação de modelos e configuração de worker Android

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/logs"
MAIN_LOG="${LOG_DIR}/main_install_$(date +%Y%m%d_%H%M%S).log"

# Carregar funções comuns
COMMON_SCRIPT_PATH="${PROJECT_ROOT}/scripts/utils/common.sh"
if [ -f "$COMMON_SCRIPT_PATH" ]; then
    source "$COMMON_SCRIPT_PATH"
else
    RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
    error() { echo -e "${RED}[ERROR]${NC} $1"; }
    warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
    log() { echo -e "${GREEN}[INFO]${NC} $1"; }
    success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
    section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
    confirm_operation() {
        read -p "$1 (s/N): " -n 1 -r; echo
        [[ $REPLY =~ ^[Ss]$ ]]
    }
fi

mkdir -p "$LOG_DIR"

show_menu() {
    section "Menu Principal de Instalação - Cluster AI"
    echo "1) Instalar Modelos Adicionais"
    echo "2) Configurar Worker Android"
    echo "3) Instalar Modelos e Configurar Worker Android (Completo)"
    echo "4) Sair"
    echo ""
}

install_models() {
    section "Iniciando instalação de modelos adicionais"
    bash "${PROJECT_ROOT}/scripts/installation/setup_additional_models_improved.sh"
}

setup_android_worker() {
    section "Iniciando configuração do worker Android"
    bash "${PROJECT_ROOT}/scripts/android/setup_android_worker.sh"
}

main() {
    while true; do
        show_menu
        read -p "Escolha uma opção [1-4]: " choice
        case $choice in
            1)
                install_models
                ;;
            2)
                setup_android_worker
                ;;
            3)
                install_models
                setup_android_worker
                ;;
            4)
                log "Saindo do instalador principal."
                exit 0
                ;;
            *)
                warn "Opção inválida, tente novamente."
                ;;
        esac
        echo ""
        read -p "Pressione Enter para continuar ou 'q' para sair: " cont
        if [[ "$cont" =~ ^[Qq]$ ]]; then
            log "Saindo do instalador principal."
            exit 0
        fi
    done
}

main "$@"
