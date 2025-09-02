#!/data/data/com.termux/files/usr/bin/bash
# Script Simplificado para configurar Worker Android - Cluster AI
# Versão: 1.0 - Fácil de usar

set -euo pipefail

# --- Cores para output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Funções auxiliares ---
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# --- Verificações iniciais ---
check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        error "Este script deve ser executado no Termux!"
        exit 1
    fi
    success "Termux detectado"
}

check_storage() {
    if [ ! -d "$HOME/storage" ]; then
        warn "Executando configuração de armazenamento..."
        termux-setup-storage
        sleep 3
    fi
    success "Armazenamento configurado"
}

# --- Instalação de dependências ---
install_deps() {
    log "Atualizando pacotes..."
    pkg update -y >/dev/null 2>&1
    pkg upgrade -y >/dev/null 2>&1

    log "Instalando dependências..."
    pkg install -y openssh python git ncurses-utils curl >/dev/null 2>&1

    success "Dependências instaladas"
}

# --- Configuração SSH ---
setup_ssh() {
    log "Configurando SSH..."

    # Criar diretório .ssh se não existir
    mkdir -p "$HOME/.ssh"

    # Gerar chave SSH se não existir
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        ssh-keygen -t rsa -b 2048 -N "" -f "$HOME/.ssh/id_rsa >/dev/null 2>&1"
    fi

    # Iniciar SSH daemon
    sshd >/dev/null 2>&1

    success "SSH configurado"
}

# --- Clonar projeto ---
clone_project() {
    log "Baixando projeto Cluster AI..."

    if [ ! -d "$HOME/Projetos/cluster-ai" ]; then
        mkdir -p "$HOME/Projetos"
        git clone https://github.com/Dagoberto-Candeias/cluster-ai.git "$HOME/Projetos/cluster-ai" >/dev/null 2>&1
    else
        log "Projeto já existe, atualizando..."
        cd "$HOME/Projetos/cluster-ai"
        git pull >/dev/null 2>&1
    fi

    success "Projeto baixado"
}

# --- Exibir informações de conexão ---
show_connection_info() {
    echo
    echo "=================================================="
    echo "🎉 CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!"
    echo "=================================================="
    echo
    echo "📱 Seu dispositivo Android está pronto para ser worker!"
    echo
    echo "🔑 CHAVE SSH PÚBLICA (copie tudo abaixo):"
    echo "--------------------------------------------------"
    cat "$HOME/.ssh/id_rsa.pub"
    echo "--------------------------------------------------"
    echo
    echo "🌐 INFORMAÇÕES DE CONEXÃO:"
    echo "   Usuário: $(whoami)"
    echo "   IP: $(ip route get 1 | awk '{print $7}' | head -1)"
    echo "   Porta SSH: 8022"
    echo
    echo "📋 PRÓXIMOS PASSOS:"
    echo "1. Copie a chave SSH acima"
    echo "2. No seu servidor principal, execute: ./manager.sh"
    echo "3. Escolha: Gerenciar Workers Remotos"
    echo "4. Cole a chave SSH quando solicitado"
    echo
    echo "💡 DICAS:"
    echo "• Mantenha o Termux aberto em background"
    echo "• Use Wi-Fi estável na mesma rede"
    echo "• Monitore a bateria (>20%)"
    echo
}

# --- Função principal ---
main() {
    echo
    echo "🤖 CLUSTER AI - CONFIGURADOR DE WORKER ANDROID"
    echo "=============================================="
    echo

    check_termux
    check_storage
    install_deps
    setup_ssh
    clone_project
    show_connection_info

    echo "🎊 Pronto! Seu Android agora é um worker do Cluster AI!"
    echo
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
