#!/data/data/com.termux/files/usr/bin/bash
# Script de desinstalação do Worker Android para Cluster AI
# Execute este script no Termux para remover a instalação do worker Android

set -euo pipefail

RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        error "Este script deve ser executado no Termux!"
        exit 1
    fi
    success "Termux detectado"
}

remove_project() {
    if [ -d "$HOME/Projetos/cluster-ai" ]; then
        warn "Removendo diretório do projeto Cluster AI..."
        rm -rf "$HOME/Projetos/cluster-ai"
        success "Diretório do projeto removido."
    else
        warn "Diretório do projeto não encontrado, nada a remover."
    fi
}

stop_ssh() {
    log "Parando serviço SSH..."
    pkill -f sshd || warn "Serviço SSH não estava em execução."
    success "Serviço SSH parado."
}

remove_ssh_keys() {
    if [ -d "$HOME/.ssh" ]; then
        warn "Removendo chaves SSH..."
        rm -rf "$HOME/.ssh"
        success "Chaves SSH removidas."
    else
        warn "Diretório .ssh não encontrado, nada a remover."
    fi
}

main() {
    echo
    echo "🗑️ Desinstalando Worker Android do Cluster AI"
    echo "============================================"
    echo

    check_termux
    stop_ssh
    remove_project
    remove_ssh_keys

    echo
    success "Desinstalação concluída com sucesso!"
    echo
}

main
