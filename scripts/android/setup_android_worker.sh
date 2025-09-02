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
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

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
    log "Isso pode levar alguns minutos..."

    # Instalar com timeout para evitar travamentos
    if timeout 300 pkg install -y openssh python git ncurses-utils 2>&1; then
        success "Dependências instaladas com sucesso"
    else
        error "Falha ao instalar dependências"
        exit 1
    fi

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

        # Tentar primeiro com SSH (para repositórios privados)
        log "Tentando clonar via SSH..."
        if git clone git@github.com:Dagoberto-Candeias/cluster-ai.git "$HOME/Projetos/cluster-ai" >/dev/null 2>&1; then
            success "Projeto clonado via SSH"
        else
            warn "Falha no SSH, tentando via HTTPS..."
            # Fallback para HTTPS (público ou com token)
            if git clone https://github.com/Dagoberto-Candeias/cluster-ai.git "$HOME/Projetos/cluster-ai" >/dev/null 2>&1; then
                success "Projeto clonado via HTTPS"
            else
                error "Falha ao clonar repositório"
                echo
                echo "🔧 SOLUÇÕES PARA REPOSITÓRIO PRIVADO:"
                echo "1. Configure sua chave SSH no GitHub:"
                echo "   - Vá em: https://github.com/settings/keys"
                echo "   - Adicione a chave: $(cat $HOME/.ssh/id_rsa.pub)"
                echo
                echo "2. Ou use token de acesso pessoal:"
                echo "   - Crie token em: https://github.com/settings/tokens"
                echo "   - Execute: git clone https://TOKEN@github.com/Dagoberto-Candeias/cluster-ai.git"
                echo
                echo "3. Execute novamente após configurar autenticação"
                exit 1
            fi
        fi
    else
        log "Projeto já existe, atualizando..."
        cd "$HOME/Projetos/cluster-ai"
        if ! git pull >/dev/null 2>&1; then
            warn "Falha ao atualizar, pode precisar de autenticação"
        fi
    fi

    section "Configuração Concluída!"
    success "Seu dispositivo Android está pronto para ser usado como um worker."
    info "No seu servidor principal, adicione a seguinte linha ao arquivo ~/.cluster_config/nodes_list.conf:"
    warn "$(hostname) $ip $user 8022"
    info "Lembre-se de usar a porta 8022 para conexões SSH."
}

main