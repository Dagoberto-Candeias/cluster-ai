#!/bin/bash
# Instalador Universal para Cluster AI - Suporte a múltiplas distribuições Linux

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[UNIVERSAL-INSTALL]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[UNIVERSAL-WARN]${NC} $1"
}

error() {
    echo -e "${RED}[UNIVERSAL-ERROR]${NC} $1"
    exit 1
}

# Configuração
LOG_DIR="/var/log/cluster_ai_install"
mkdir -p "$LOG_DIR"

# Função para detectar distribuição
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        error "Não foi possível detectar a distribuição Linux"
    fi
}

# Função para verificar sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        error "Este script requer privilégios sudo"
    fi
}

# Função para instalar em Debian/Ubuntu
install_debian_ubuntu() {
    log "Instalando no Debian/Ubuntu..."
    
    # Atualizar sistema
    apt update && apt upgrade -y
    
    # Instalar dependências básicas
    apt install -y curl wget git unzip build-essential \
        software-properties-common apt-transport-https \
        ca-certificates gnupg lsb-release openssh-server \
        net-tools htop tree tmux ncdu
    
    # Instalar Python
    apt install -y python3 python3-pip python3-venv python3-full python3-dev
    
    log "Instalação Debian/Ubuntu concluída"
}

# Função para instalar em Arch/Manjaro
install_arch_manjaro() {
    log "Instalando no Arch/Manjaro..."
    
    # Atualizar sistema
    pacman -Syu --noconfirm
    
    # Instalar dependências básicas
    pacman -S --noconfirm curl wget git unzip base-devel \
        which htop tree tmux ncdu openssh
    
    # Instalar Python
    pacman -S --noconfirm python python-pip
    
    log "Instalação Arch/Manjaro concluída"
}

# Função para instalar em Fedora/CentOS/RHEL
install_fedora_centos() {
    log "Instalando no Fedora/CentOS/RHEL..."
    
    # Atualizar sistema
    dnf update -y
    
    # Instalar dependências básicas
    dnf install -y curl wget git unzip make gcc gcc-c++ \
        kernel-devel openssl-devel htop tree tmux ncdu \
        openssh-server net-tools
    
    # Instalar Python
    dnf install -y python3 python3-pip python3-devel
    
    log "Instalação Fedora/CentOS/RHEL concluída"
}

# Função para instalar Docker universalmente
install_docker_universal() {
    log "Instalando Docker..."
    
    local distro=$1
    
    case $distro in
        ubuntu|debian)
            apt install -y docker.io docker-compose-plugin
            ;;
        arch|manjaro)
            pacman -S --noconfirm docker docker-compose
            ;;
        fedora|centos|rhel)
            dnf install -y docker docker-compose
            ;;
    esac
    
    # Configurar Docker
    systemctl enable --now docker
    usermod -aG docker "$SUDO_USER"
    
    log "Docker instalado e configurado"
}

# Função para instalar CUDA
install_cuda() {
    log "Instalando CUDA..."
    
    # Verificar se o script existe localmente
    if [ -f "scripts/installation/install_cuda.sh" ]; then
        bash "scripts/installation/install_cuda.sh"
    else
        warn "Script de instalação do CUDA não encontrado localmente"
    fi
}

# Função para instalar ROCm
install_rocm() {
    log "Instalando ROCm..."
    
    # Verificar se o script existe localmente
    if [ -f "scripts/installation/install_rocm.sh" ]; then
        bash "scripts/installation/install_rocm.sh"
    else
        warn "Script de instalação do ROCm não encontrado localmente"
    fi
}

# Função principal
main() {
    check_sudo
    
    echo -e "${BLUE}=== INSTALADOR UNIVERSAL CLUSTER AI ===${NC}"
    echo "Log detalhado: $LOG_DIR/universal_install.log"
    exec > >(tee -a "$LOG_DIR/universal_install.log") 2>&1
    
    local distro=$(detect_distro)
    log "Distribuição detectada: $distro"
    
    # Instalar dependências básicas baseadas na distro
    case $distro in
        ubuntu|debian)
            install_debian_ubuntu
            ;;
        arch|manjaro)
            install_arch_manjaro
            ;;
        fedora|centos|rhel)
            install_fedora_centos
            ;;
        *)
            warn "Distribuição não totalmente suportada: $distro"
            warn "Tentando instalação genérica..."
            # Tentativa genérica - instalar apenas o essencial
            if command -v apt >/dev/null 2>&1; then
                install_debian_ubuntu
            elif command -v pacman >/dev/null 2>&1; then
                install_arch_manjaro
            elif command -v dnf >/dev/null 2>&1; then
                install_fedora_centos
            else
                error "Distribuição não suportada: $distro"
            fi
            ;;
    esac
    
    # Instalar Docker (universal)
    install_docker_universal "$distro"
    
    # Instalar CUDA e ROCm
    install_cuda
    install_rocm
    
    # Mensagem de sucesso
    echo -e "${GREEN}🎉 Instalação universal concluída com sucesso!${NC}"
    echo ""
    echo -e "${BLUE}📋 PRÓXIMOS PASSOS:${NC}"
    echo "1. Configure a GPU: sudo ./scripts/installation/gpu_setup.sh"
    echo "2. Instale o VSCode otimizado: sudo ./scripts/installation/vscode_optimized.sh"
    echo "3. Configure o ambiente virtual: ./scripts/installation/venv_setup.sh"
    echo "4. Execute a instalação completa: ./install_cluster.sh"
    echo ""
    echo -e "${YELLOW}💡 DICA:${NC} Use './scripts/utils/health_check.sh' para verificar o sistema"
}

# Executar
main "$@"
