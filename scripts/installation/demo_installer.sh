#!/bin/bash
set -e

echo "=== DEMONSTRAÇÃO CLUSTER AI - INSTALADOR SIMPLIFICADO ==="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para log colorido
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detectar distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
else
    error "Não foi possível detectar o sistema operacional."
    exit 1
fi

log "Sistema detectado: $OS $OS_VERSION"
info "Nome da máquina: $(hostname)"
info "IP atual: $(hostname -I | awk '{print $1}')"

# Função para instalar dependências básicas
install_dependencies() {
    log "Instalando dependências básicas..."
    
    case $OS in
        ubuntu|debian)
            sudo apt update && sudo apt upgrade -y
            
            # Remover pacotes conflitantes do Docker primeiro
            sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-ce-rootless-extras || true
            
            # Instalar pacotes necessários
            sudo apt install -y curl git python3-venv python3-pip python3-full \
                ca-certificates gnupg lsof openssh-server net-tools
            
            # Instalar Docker separadamente para evitar conflitos
            if ! command_exists docker; then
                sudo apt install -y docker.io docker-compose-plugin
            fi
            ;;
        manjaro)
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm curl git docker python python-pip python-virtualenv \
                lsof openssh wget base-devel net-tools
            ;;
        centos|rhel|fedora)
            sudo yum update -y
            sudo yum install -y curl git docker python3 python3-pip python3-virtualenv \
                lsof openssh-server net-tools
            ;;
    esac
    
    # Inicializar e habilitar Docker
    if command_exists docker; then
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker $USER
        log "Docker configurado e iniciado"
    fi
}

# Função para configurar ambiente Python
setup_python_env() {
    if [ ! -d "$HOME/cluster_env" ]; then
        log "Criando ambiente virtual em ~/cluster_env"
        python3 -m venv ~/cluster_env
    else
        log "Ambiente virtual já existe."
    fi

    # Instalar dependências no ambiente virtual
    source ~/cluster_env/bin/activate
    pip install --upgrade pip
    pip install "dask[complete]" distributed numpy pandas scipy
    deactivate
    
    log "✅ Ambiente Python configurado com sucesso!"
    log "📦 Dependências Python instaladas"
    log "🐳 Docker configurado e funcionando"
    log "🌐 Cluster Dask pronto para uso"
    echo ""
    log "Para ativar o ambiente: source ~/cluster_env/bin/activate"
    log "Para testar a instalação: python test_installation.py"
    log "Dashboard disponível em: http://127.0.0.1:8787"
}

# Função para instalar e configurar Ollama
install_ollama() {
    log "Instalando Ollama..."
    
    if command_exists ollama; then
        log "Ollama já está instalado."
        return 0
    fi
    
    # Instalar Ollama
    curl -fsSL https://ollama.com/install.sh | sh
    
    # Configurar para iniciar automaticamente
    sudo systemctl enable ollama
    sudo systemctl start ollama
    
    log "Ollama instalado e configurado."
}

# Função para configurar servidor
setup_server() {
    log "Configurando servidor (scheduler)..."
    
    # Obter IP dinâmico
    IP=$(hostname -I | awk '{print $1}')
    log "IP desta máquina: $IP"
    
    # Criar script para iniciar scheduler
    mkdir -p ~/cluster_scripts
    cat > ~/cluster_scripts/start_scheduler.sh << EOL
#!/bin/bash
source ~/cluster_env/bin/activate
dask-scheduler --host 0.0.0.0 --port 8786 --dashboard --dashboard-address 0.0.0.0:8787
EOL
    
    chmod +x ~/cluster_scripts/start_scheduler.sh
    
    # Iniciar scheduler
    pkill -f "dask-scheduler" || true
    nohup ~/cluster_scripts/start_scheduler.sh > ~/scheduler.log 2>&1 &
    
    log "Scheduler iniciado. Dashboard disponível em: http://$IP:8787"
}

# Função para configurar worker
setup_worker() {
    log "Configurando worker..."
    
    # Criar script para iniciar worker
    cat > ~/cluster_scripts/start_worker.sh << EOL
#!/bin/bash
source ~/cluster_env/bin/activate
dask-worker localhost:8786 --nworkers auto --nthreads 2 --name $(hostname)
EOL
    
    chmod +x ~/cluster_scripts/start_worker.sh
    
    # Iniciar worker
    pkill -f "dask-worker" || true
    nohup ~/cluster_scripts/start_worker.sh > ~/worker.log 2>&1 &
    
    log "Worker configurado para conectar ao scheduler local"
}

# Função para mostrar status
show_status() {
    echo -e "\n${BLUE}=== STATUS DO SISTEMA ===${NC}"
    
    # Verificar serviços em execução
    echo -e "${YELLOW}Serviços:${NC}"
    if pgrep -f "dask-scheduler" >/dev/null; then
        echo "✓ Dask Scheduler está em execução"
    else
        echo "✗ Dask Scheduler não está em execução"
    fi
    
    if pgrep -f "dask-worker" >/dev/null; then
        echo "✓ Dask Worker está em execução"
    else
        echo "✗ Dask Worker não está em execução"
    fi
    
    if pgrep -f "ollama" >/dev/null; then
        echo "✓ Ollama está em execução"
    else
        echo "✗ Ollama não está em execução"
    fi
    
    # Verificar IP atual
    IP=$(hostname -I | awk '{print $1}')
    echo -e "\n${YELLOW}IP atual:${NC} $IP"
    
    # Verificar ambiente Python
    echo -e "\n${YELLOW}Ambiente Python:${NC}"
    if [ -d "$HOME/cluster_env" ]; then
        echo "✓ Ambiente virtual existe"
    else
        echo "✗ Ambiente virtual não existe"
    fi
}

# Função principal
main() {
    echo -e "\n${BLUE}=== INSTALAÇÃO AUTOMÁTICA CLUSTER AI ===${NC}"
    
    # Instalar dependências
    install_dependencies
    
    # Configurar ambiente Python
    setup_python_env
    
    # Instalar Ollama
    install_ollama
    
    # Configurar servidor
    setup_server
    
    # Configurar worker
    setup_worker
    
    # Mostrar status
    show_status
    
    echo -e "\n${GREEN}✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!${NC}"
    echo -e "${YELLOW}Serviços disponíveis:${NC}"
    echo "- Dask Dashboard: http://$(hostname -I | awk '{print $1}'):8787"
    echo "- Ollama API: http://localhost:11434"
    echo ""
    echo -e "${YELLOW}Logs:${NC}"
    echo "- Scheduler: ~/scheduler.log"
    echo "- Worker: ~/worker.log"
    echo ""
    echo -e "${YELLOW}Scripts:${NC}"
    echo "- Iniciar scheduler: ~/cluster_scripts/start_scheduler.sh"
    echo "- Iniciar worker: ~/cluster_scripts/start_worker.sh"
}

# Executar instalação
main
