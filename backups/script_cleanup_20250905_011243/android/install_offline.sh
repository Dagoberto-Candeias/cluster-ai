#!/bin/bash
# =============================================================================
# Instalação Offline do Worker Android - Cluster AI
# =============================================================================
# Use quando o download direto falhar
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: install_offline.sh
# =============================================================================

#!/data/data/com.termux/files/usr/bin/bash
# Instalação Offline do Worker Android - Cluster AI
# Use quando o download direto falhar

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
    log "Isso pode levar alguns minutos na primeira vez..."

    # Atualizar com timeout
    if timeout 300 pkg update -y 2>&1; then
        log "Pacotes base atualizados"
    else
        warn "Timeout na atualização, continuando..."
    fi

    # Upgrade com timeout
    if timeout 300 pkg upgrade -y 2>&1; then
        log "Pacotes atualizados"
    else
        warn "Timeout no upgrade, continuando..."
    fi

    log "Instalando dependências..."
    # Instalar com timeout
    if timeout 300 pkg install -y openssh python git ncurses-utils curl 2>&1; then
        success "Dependências instaladas"
    else
        error "Falha ao instalar dependências"
        return 1
    fi
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

# --- Download manual do projeto ---
download_project() {
    log "Download manual do projeto Cluster AI..."

    echo
    echo "📥 DOWNLOAD MANUAL NECESSÁRIO"
    echo "=============================="
    echo
    echo "Como o repositório é privado, você precisa fazer o download manual:"
    echo
    echo "OPÇÃO 1 - Via navegador (Recomendado):"
    echo "1. No seu navegador, acesse:"
    echo "   https://github.com/Dagoberto-Candeias/cluster-ai"
    echo "2. Clique em 'Code' → 'Download ZIP'"
    echo "3. Baixe e extraia o arquivo"
    echo "4. Copie a pasta para: ~/Projetos/cluster-ai"
    echo
    echo "OPÇÃO 2 - Via Git com autenticação:"
    echo "1. Configure SSH ou Token (veja setup_github_auth.sh)"
    echo "2. Execute: git clone https://github.com/Dagoberto-Candeias/cluster-ai.git ~/Projetos/cluster-ai"
    echo
    echo "OPÇÃO 3 - Via SCP do servidor:"
    echo "1. No servidor: scp -r /caminho/cluster-ai usuario@ip_android:~/Projetos/"
    echo

    # Aguardar confirmação do usuário
    while true; do
        read -p "Já fez o download do projeto? (s/n): " resposta
        case $resposta in
            [Ss]* )
                if [ -d "$HOME/Projetos/cluster-ai" ]; then
                    success "Projeto encontrado!"
                    return 0
                else
                    warn "Pasta não encontrada. Tente novamente."
                fi
                ;;
            [Nn]* )
                log "Aguardando download..."
                sleep 5
                ;;
            * )
                warn "Responda 's' para sim ou 'n' para não"
                ;;
        esac
    done
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
    echo "🤖 CLUSTER AI - INSTALAÇÃO OFFLINE WORKER ANDROID"
    echo "================================================"
    echo
    warn "Este script é para quando o download direto falhar"
    echo

    check_termux
    check_storage
    install_deps
    setup_ssh
    download_project
    show_connection_info

    echo "🎊 Pronto! Seu Android agora é um worker do Cluster AI!"
    echo
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
