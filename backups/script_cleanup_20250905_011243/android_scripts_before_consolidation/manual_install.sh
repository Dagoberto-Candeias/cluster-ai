#!/bin/bash
# =============================================================================
# Instalação Manual do Worker Android - Cluster AI
# =============================================================================
# Use este script quando o download automático falhar
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: manual_install.sh
# =============================================================================

#!/data/data/com.termux/files/usr/bin/bash
# Instalação Manual do Worker Android - Cluster AI
# Use este script quando o download automático falhar

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

# --- Instalação passo a passo ---
main() {
    echo
    echo "🤖 INSTALAÇÃO MANUAL - WORKER ANDROID"
    echo "====================================="
    echo

    check_termux

    # Passo 1: Configurar armazenamento
    log "Passo 1: Configurando armazenamento..."
    if [ ! -d "$HOME/storage" ]; then
        termux-setup-storage
        sleep 3
    fi
    success "Armazenamento configurado"

    # Passo 2: Atualizar pacotes
    log "Passo 2: Atualizando pacotes..."
    log "Isso pode levar alguns minutos na primeira vez..."

    # Atualizar com timeout e mostrar progresso
    if timeout 300 pkg update -y 2>&1; then
        log "Pacotes base atualizados"
    else
        warn "Timeout na atualização de pacotes, continuando..."
    fi

    # Upgrade com timeout
    if timeout 300 pkg upgrade -y 2>&1; then
        success "Pacotes atualizados e atualizados"
    else
        warn "Timeout no upgrade de pacotes, continuando..."
    fi

    # Passo 3: Instalar dependências
    log "Passo 3: Instalando dependências..."
    pkg install -y openssh python git ncurses-utils curl >/dev/null 2>&1
    success "Dependências instaladas"

    # Passo 4: Configurar SSH
    log "Passo 4: Configurando SSH..."
    mkdir -p "$HOME/.ssh"
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        ssh-keygen -t rsa -b 2048 -N "" -f "$HOME/.ssh/id_rsa" >/dev/null 2>&1
    fi
    sshd >/dev/null 2>&1
    success "SSH configurado"

    # Passo 5: Clonar projeto (com fallback)
    log "Passo 5: Baixando projeto Cluster AI..."

    if [ ! -d "$HOME/Projetos/cluster-ai" ]; then
        mkdir -p "$HOME/Projetos"

        # Tentar SSH primeiro
        if git clone git@github.com:Dagoberto-Candeias/cluster-ai.git "$HOME/Projetos/cluster-ai" >/dev/null 2>&1; then
            success "Projeto clonado via SSH"
        else
            warn "SSH falhou, tentando HTTPS..."
            if git clone https://github.com/Dagoberto-Candeias/cluster-ai.git "$HOME/Projetos/cluster-ai" >/dev/null 2>&1; then
                success "Projeto clonado via HTTPS"
            else
                warn "Clone falhou. Você pode:"
                echo "1. Configurar SSH key no GitHub"
                echo "2. Usar token de acesso pessoal"
                echo "3. Baixar manualmente do repositório"
            fi
        fi
    else
        success "Projeto já existe"
    fi

    # Exibir informações
    echo
    echo "=================================================="
    echo "🎉 INSTALAÇÃO CONCLUÍDA!"
    echo "=================================================="
    echo
    echo "🔑 CHAVE SSH PÚBLICA (copie para o servidor principal):"
    echo "--------------------------------------------------"
    cat "$HOME/.ssh/id_rsa.pub"
    echo "--------------------------------------------------"
    echo
    echo "🌐 INFORMAÇÕES DE CONEXÃO:"
    echo "   Usuário: $(whoami)"
    echo "   IP: $(ip route get 1 | awk '{print $7}' | head -1 || echo 'Verifique Wi-Fi')"
    echo "   Porta SSH: 8022"
    echo
    echo "📋 PRÓXIMOS PASSOS:"
    echo "1. Copie a chave SSH acima"
    echo "2. No servidor principal: ./manager.sh"
    echo "3. Escolha: Gerenciar Workers Remotos"
    echo "4. Cole a chave SSH e configure o IP/porta"
    echo
    echo "🧪 Para testar: bash ~/Projetos/cluster-ai/scripts/android/test_android_worker.sh"
    echo
}

# Executar
main
