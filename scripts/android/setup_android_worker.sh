#!/data/data/com.termux/files/usr/bin/bash
# Local: scripts/android/setup_android_worker.sh
# Autor: Dagoberto Candeias <betoallnet@gmail.com>
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
    if timeout 300 pkg install -y openssh python git ncurses-utils curl >/dev/null 2>&1; then
        success "Dependências instaladas com sucesso"
    else
        error "Falha ao instalar dependências. Verifique sua conexão com a internet."
        exit 1
    fi

    # 3. Configurar e iniciar o servidor SSH
    section "Configurando Servidor SSH"
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        log "Gerando chave SSH para o dispositivo..."
        ssh-keygen -t rsa -b 4096 -N "" -f "$HOME/.ssh/id_rsa"
    fi

    log "Iniciando o servidor SSH na porta 8022..."
    sshd

    local user; user=$(whoami)
    local ip; ip=$(ip route get 1 | awk '{print $7; exit}')
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
                echo "   - Adicione a chave pública que será exibida no final."
                echo
                echo "2. Ou use token de acesso pessoal:"
                echo "   - Crie token em: https://github.com/settings/tokens"
                echo "   - Execute: git clone https://TOKEN@github.com/Dagoberto-Candeias/cluster-ai.git"
                echo
                echo "3. Execute este script novamente após configurar a autenticação."
                exit 1
            fi
        fi
    else
        log "Projeto já existe, atualizando..."
        cd "$HOME/Projetos/cluster-ai"
        if ! git pull >/dev/null 2>&1; then
            warn "Falha ao atualizar. Pode ser necessário configurar autenticação."
        else
            success "Projeto atualizado com sucesso."
        fi
    fi

    section "Configuração Concluída!"
    success "Seu dispositivo Android está pronto para ser usado como um worker."
    echo
    info "Para registrar este worker no servidor principal, siga os passos:"
    echo
    echo -e "1. ${YELLOW}Copie a chave SSH pública abaixo:${NC}"
    echo "--------------------------------------------------"
    cat "$HOME/.ssh/id_rsa.pub"
    echo "--------------------------------------------------"
    echo
    echo "2. No servidor principal, execute o gerenciador:"
    echo "   ./manager.sh"
    echo
    echo "3. Escolha a opção 'Configurar Cluster' e depois 'Gerenciar Workers Remotos (SSH)'."
    echo
    echo "4. Adicione um novo worker com as seguintes informações:"
    echo -e "   - ${YELLOW}Nome do Worker:${NC} android-$(hostname)"
    echo -e "   - ${YELLOW}IP do Worker:${NC} $ip"
    echo -e "   - ${YELLOW}Usuário SSH:${NC} $user"
    echo -e "   - ${YELLOW}Porta SSH:${NC} 8022"
    echo -e "   - ${YELLOW}Chave Pública:${NC} (Cole a chave que você copiou)"
    echo
    info "Após o registro, o servidor poderá se conectar e gerenciar este worker."
}

main