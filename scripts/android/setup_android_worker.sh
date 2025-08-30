#!/data/data/com.termux/files/usr/bin/bash
# Script para configurar um dispositivo Android como um Worker do Cluster AI via Termux.
#
# INSTRUÇÕES:
# 1. Instale o Termux no seu dispositivo Android.
# 2. Execute o comando: termux-setup-storage
# 3. Execute este script colando o seguinte comando no Termux:
#    curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker.sh | bash

set -euo pipefail

# --- Cores para o output ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

section() {
    echo ""
    echo -e "${GREEN}=================================================${NC}"
    echo -e "${GREEN} $1 ${NC}"
    echo -e "${GREEN}=================================================${NC}"
}

main() {
    section "Configurador de Worker Android para Cluster AI"

    # 1. Atualizar pacotes do Termux
    log "Atualizando pacotes do Termux..."
    pkg update -y && pkg upgrade -y

    # 2. Instalar dependências essenciais
    log "Instalando dependências: openssh, python, git, ncurses-utils..."
    pkg install -y openssh python git ncurses-utils

    # 3. Configurar e iniciar o servidor SSH
    section "Configurando Servidor SSH"
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        log "Gerando chave SSH para o dispositivo..."
        ssh-keygen -t rsa -b 4096 -N "" -f "$HOME/.ssh/id_rsa"
    fi
    
    log "Para se conectar a este worker a partir do seu servidor, você precisará da chave pública:"
    warn "Copie a chave abaixo e adicione ao arquivo ~/.ssh/authorized_keys no seu servidor principal."
    echo -e "${YELLOW}"
    cat "$HOME/.ssh/id_rsa.pub"
    echo -e "${NC}"
    
    read -p "Pressione Enter após copiar a chave para continuar..."

    log "Iniciando o servidor SSH na porta 8022..."
    sshd
    
    local user; user=$(whoami)
    local ip; ip=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n 1)
    success "Servidor SSH iniciado! Conecte-se com: ssh $user@$ip -p 8022"

    # 4. Clonar o repositório do Cluster AI
    section "Clonando o Projeto Cluster AI"
    if [ ! -d "$HOME/Projetos/cluster-ai" ]; then
        mkdir -p "$HOME/Projetos"
        git clone https://github.com/Dagoberto-Candeias/cluster-ai.git "$HOME/Projetos/cluster-ai"
    else
        log "Diretório do projeto já existe. Pulando clone."
    fi

    section "Configuração Concluída!"
    success "Seu dispositivo Android está pronto para ser usado como um worker."
    info "No seu servidor principal, adicione a seguinte linha ao arquivo ~/.cluster_config/nodes_list.conf:"
    warn "$(hostname) $ip $user 8022"
    info "Lembre-se de usar a porta 8022 para conexões SSH."
}

main