#!/bin/bash
# =============================================================================
# INSTALAÇÃO MANUAL COMPLETA - Worker Android Cluster AI
# =============================================================================
# COPIE E COLE TODO ESTE CONTEÚDO NO TERMUX
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: install_manual.sh
# =============================================================================

#!/data/data/com.termux/files/usr/bin/bash
# INSTALAÇÃO MANUAL COMPLETA - Worker Android Cluster AI
# COPIE E COLE TODO ESTE CONTEÚDO NO TERMUX

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

# --- Configuração de armazenamento ---
setup_storage() {
    log "Configurando armazenamento..."
    if [ ! -d "$HOME/storage" ]; then
        termux-setup-storage
        sleep 3
    fi
    success "Armazenamento configurado"
}

# --- Instalação de dependências ---
install_deps() {
    log "Corrigindo dpkg se necessário..."
    dpkg --configure -a 2>/dev/null || true

    log "Atualizando lista de pacotes..."
    pkg update -y

    log "Instalando dependências..."
    pkg install -y openssh python git ncurses-utils curl

    success "Dependências instaladas"
}

# --- Configuração SSH ---
setup_ssh() {
    log "Configurando SSH..."

    mkdir -p "$HOME/.ssh"

    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        ssh-keygen -t rsa -b 2048 -N "" -f "$HOME/.ssh/id_rsa" -C "$(whoami)@termux"
    fi

    sshd >/dev/null 2>&1

    success "SSH configurado"
}

# --- Download do projeto ---
download_project() {
    log "Baixando projeto Cluster AI..."

    if [ ! -d "$HOME/Projetos/cluster-ai" ]; then
        mkdir -p "$HOME/Projetos"

        # Tentar HTTPS primeiro (público)
        if git clone https://github.com/Dagoberto-Candeias/cluster-ai.git "$HOME/Projetos/cluster-ai" 2>/dev/null; then
            success "Projeto baixado via HTTPS"
        else
            warn "HTTPS falhou - tentando método alternativo"

            # Método alternativo: baixar ZIP
            log "Tentando download via ZIP..."
            cd "$HOME/Projetos"
            if curl -L -o cluster-ai.zip https://github.com/Dagoberto-Candeias/cluster-ai/archive/main.zip; then
                unzip cluster-ai.zip
                mv cluster-ai-main cluster-ai
                rm cluster-ai.zip
                success "Projeto baixado via ZIP"
            else
                error "Falha no download. Tente configurar autenticação primeiro."
                echo
                echo "🔧 SOLUÇÕES:"
                echo "1. Configure SSH: https://github.com/settings/keys"
                echo "2. Ou use token: https://github.com/settings/tokens"
                echo "3. Execute: git clone https://TOKEN@github.com/Dagoberto-Candeias/cluster-ai.git"
                exit 1
            fi
        fi
    else
        success "Projeto já existe"
    fi
}

# --- Exibir informações ---
show_info() {
    echo
    echo "=================================================="
    echo "🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
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
    echo "3. Escolha: Gerenciar Workers Remotos (SSH)"
    echo "4. Cole a chave SSH quando solicitado"
    echo "5. Digite o IP do seu Android"
    echo "6. Porta: 8022"
    echo
    echo "🧪 TESTE DE CONEXÃO:"
    echo "ssh $(whoami)@$(ip route get 1 | awk '{print $7}' | head -1) -p 8022"
    echo
}

# --- Função principal ---
main() {
    echo
    echo "🤖 CLUSTER AI - INSTALAÇÃO MANUAL COMPLETA"
    echo "=========================================="
    echo
    warn "Este script instala tudo automaticamente"
    echo

    check_termux
    setup_storage
    install_deps
    setup_ssh
    download_project
    show_info

    echo "🎊 Pronto! Seu Android é um worker do Cluster AI!"
    echo
}

# Executar
main
