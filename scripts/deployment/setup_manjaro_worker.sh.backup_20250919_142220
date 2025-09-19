#!/bin/bash
# Script simplificado para configurar nó worker no Manjaro

set -euo pipefail

# --- Configuração ---
REPO_URL="${1:-https://github.com/seu-usuario/cluster-ai.git}"
SCHEDULER_IP="${2:-192.168.0.6}"

# --- Funções ---
section() {
    echo
    echo "=============================="
    echo " $1"
    echo "=============================="
}

progress() {
    echo "[...] $1"
}

success() {
    echo "[SUCCESS] $1"
}

error() {
    echo "[ERROR] $1"
}

warn() {
    echo "[WARN] $1"
}

info() {
    echo "[INFO] $1"
}

# Verificar se está rodando como root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        error "Não execute este script como root!"
        exit 1
    fi
}

# Instalar dependências
install_dependencies() {
    section "Instalando Dependências"

    info "Atualizando sistema..."
    sudo pacman -Syu --noconfirm

    info "Instalando pacotes necessários..."
    sudo pacman -S --noconfirm \
        docker \
        python \
        python-pip \
        git \
        nmap \
        curl \
        openssh \
        base-devel

    success "Dependências instaladas"
}

# Configurar Docker
setup_docker() {
    section "Configurando Docker"

    info "Habilitando serviço Docker..."
    sudo systemctl enable docker
    sudo systemctl start docker

    info "Adicionando usuário ao grupo docker..."
    sudo usermod -aG docker "$USER"

    success "Docker configurado"
    warn "Reinicie a sessão ou execute: newgrp docker"
}

# Clonar repositório
clone_repository() {
    section "Clonando Repositório"

    local repo_dir="$HOME/Projetos/cluster-ai"

    if [ -d "$repo_dir" ]; then
        info "Diretório já existe, atualizando..."
        cd "$repo_dir"
        git pull
    else
        info "Clonando repositório..."
        mkdir -p "$HOME/Projetos"
        cd "$HOME/Projetos"
        git clone "$REPO_URL" cluster-ai
        cd cluster-ai
    fi

    success "Repositório clonado/atualizado"
}

# Configurar SSH
setup_ssh() {
    section "Configurando SSH"

    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        info "Gerando chave SSH..."
        ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N ""
    else
        info "Chave SSH já existe"
    fi

    # Adicionar chave ao known_hosts local
    info "Adicionando host local ao known_hosts..."
    ssh-keyscan -H localhost >> "$HOME/.ssh/known_hosts" 2>/dev/null || true
    ssh-keyscan -H "$(hostname)" >> "$HOME/.ssh/known_hosts" 2>/dev/null || true

    success "SSH configurado"
}

# Criar arquivos de configuração básicos
create_basic_config() {
    section "Criando Configuração Básica"

    local config_dir="$HOME/.cluster_config"
    mkdir -p "$config_dir"

    # Criar cluster.conf básico
    cat > "$config_dir/cluster.conf" << EOF
# Configuração básica do Cluster AI - Worker
NODE_TYPE=worker
SCHEDULER_IP=$SCHEDULER_IP
NODE_IP=$(hostname -I | awk '{print $1}')
NODE_HOSTNAME=$(hostname)
WORKER_THREADS=4
WORKER_MEMORY=4GB
EOF

    success "Configuração criada em $config_dir/cluster.conf"
}

# Instalar Python dependencies
install_python_deps() {
    section "Instalando Dependências Python"

    cd "$HOME/Projetos/cluster-ai"

    if [ -f "requirements.txt" ]; then
        info "Instalando requirements.txt..."
        pip install -r requirements.txt
    fi

    # Instalar dask e distributed
    info "Instalando Dask..."
    pip install dask distributed

    success "Dependências Python instaladas"
}

# Testar configuração
test_setup() {
    section "Testando Configuração"

    info "Testando Docker..."
    if docker --version >/dev/null 2>&1; then
        success "Docker OK"
    else
        warn "Docker pode precisar de reinicialização da sessão"
    fi

    info "Testando Python..."
    if python --version >/dev/null 2>&1; then
        success "Python OK"
    fi

    info "Testando Git..."
    if git --version >/dev/null 2>&1; then
        success "Git OK"
    fi

    info "Testando conectividade com scheduler..."
    if ping -c 2 "$SCHEDULER_IP" >/dev/null 2>&1; then
        success "Conectividade com scheduler OK"
    else
        warn "Scheduler não está acessível: $SCHEDULER_IP"
    fi
}

# Mostrar instruções finais
show_final_instructions() {
    section "🎉 Configuração Concluída!"

    echo "Para iniciar o nó worker, execute:"
    echo
    echo "1. Reinicialize a sessão (ou execute: newgrp docker)"
    echo "2. Navegue até o projeto:"
    echo "   cd ~/Projetos/cluster-ai"
    echo
    echo "3. Inicie como worker:"
    echo "   ./start_cluster.sh --worker --scheduler-ip $SCHEDULER_IP"
    echo
    echo "4. Verifique o status:"
    echo "   ./manager.sh status"
    echo
    echo "5. No servidor principal, verifique:"
    echo "   ./scripts/management/test_node_connectivity.sh $(hostname -I | awk '{print $1}') $(hostname)"
    echo
    warn "IMPORTANTE: Execute os comandos acima em uma nova sessão do terminal"
}

main() {
    section "🚀 Configuração do Nó Worker - Manjaro"

    check_root
    install_dependencies
    setup_docker
    clone_repository
    setup_ssh
    create_basic_config
    install_python_deps
    test_setup
    show_final_instructions

    section "✅ Configuração Finalizada"
    info "Reinicie o terminal e siga as instruções acima para iniciar o worker"
}

# Verificar argumentos
if [ $# -eq 0 ]; then
    info "Uso: $0 [REPO_URL] [SCHEDULER_IP]"
    info "Exemplo: $0 https://github.com/user/cluster-ai.git 192.168.0.6"
    echo
fi

main "$@"
