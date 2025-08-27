#!/bin/bash
# Instalador Universal Cluster AI - Ambiente de Desenvolvimento Completo
# Funciona em qualquer distribuição Linux: Ubuntu, Debian, Manjaro, Arch, CentOS, RHEL, Fedora

set -e

echo "=== INSTALADOR UNIVERSAL CLUSTER AI ==="
echo "Preparando ambiente de desenvolvimento completo..."
echo "Distribuição: $(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1)"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detectar distribuição
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif command_exists lsb_release; then
        OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        OS_VERSION=$(lsb_release -sr)
    else
        error "Não foi possível detectar o sistema operacional."
        exit 1
    fi
    
    # Normalizar nomes mas manter debian como distinto
    case $OS in
        ubuntu)
            OS="ubuntu"
            ;;
        debian)
            OS="debian"
            ;;
        manjaro|arch)
            OS="manjaro" 
            ;;
        centos|rhel|fedora)
            OS="centos"
            ;;
        *)
            warn "Distribuição não totalmente suportada: $OS"
            warn "Tentando modo compatível..."
            ;;
    esac
    
    log "Sistema detectado: $OS $OS_VERSION"
}

# Instalar dependências básicas universais
install_universal_dependencies() {
    log "Instalando dependências universais..."
    
    case $OS in
        ubuntu|debian)
            sudo apt update && sudo apt upgrade -y
            # Verificar se estamos no Debian (que não tem software-properties-common)
            if [ "$OS" = "debian" ]; then
                sudo apt install -y curl git wget python3 python3-pip python3-venv \
                    docker.io docker-compose-plugin openssh-server net-tools \
                    build-essential ca-certificates gnupg lsb-release apt-transport-https
            else
                sudo apt install -y curl git wget python3 python3-pip python3-venv \
                    docker.io docker-compose-plugin openssh-server net-tools \
                    build-essential software-properties-common ca-certificates \
                    gnupg lsb-release apt-transport-https
            fi
            ;;
        manjaro)
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm curl git wget python python-pip python-virtualenv \
                docker openssh net-tools base-devel which file grep sed awk
            ;;
        centos)
            if command_exists dnf; then
                sudo dnf update -y
                sudo dnf install -y curl git wget python3 python3-pip python3-virtualenv \
                    docker docker-compose openssh-server net-tools \
                    @development-tools which file grep sed awk
            else
                sudo yum update -y
                sudo yum install -y curl git wget python3 python3-pip python3-virtualenv \
                    docker docker-compose openssh-server net-tools \
                    which file grep sed awk
            fi
            ;;
    esac
    
    # Configurar Docker
    if command_exists docker; then
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker $USER
        log "Docker configurado e iniciado"
    fi
}

# Configurar ambiente Python universal
setup_universal_python() {
    log "Configurando ambiente Python universal..."
    
    if [ ! -d "$HOME/cluster_env" ]; then
        python3 -m venv ~/cluster_env
        log "Ambiente virtual criado em ~/cluster_env"
    else
        log "Ambiente virtual já existe."
    fi

    source ~/cluster_env/bin/activate
    pip install --upgrade pip
    pip install "dask[complete]" distributed numpy pandas scipy \
        jupyterlab requests scikit-learn torch torchvision torchaudio \
        transformers fastapi uvicorn pytest httpx
    deactivate
    
    log "Ambiente Python configurado com sucesso."
}

# Menu de instalação
show_menu() {
    echo -e "\n${BLUE}=== MENU DE INSTALAÇÃO UNIVERSAL ===${NC}"
    echo "1. Instalação Completa (Recomendado)"
    echo "2. Apenas Dependências Básicas"
    echo "3. Apenas Ambiente Python"
    echo "4. Apenas IDEs e Ferramentas Dev"
    echo "5. Configurar Papel do Cluster"
    echo "6. Sair"
    
    read -p "Selecione uma opção [1-6]: " choice
    
    case $choice in
        1)
            install_complete
            ;;
        2)
            install_universal_dependencies
            ;;
        3)
            setup_universal_python
            ;;
        4)
            install_development_tools
            ;;
        5)
            configure_cluster_role
            ;;
        6)
            exit 0
            ;;
        *)
            warn "Opção inválida."
            show_menu
            ;;
    esac
}

# Instalação completa
install_complete() {
    log "Iniciando instalação completa..."
    
    detect_os
    install_universal_dependencies
    setup_universal_python
    install_development_tools
    
    echo -e "\n${GREEN}✅ INSTALAÇÃO COMPLETA CONCLUÍDA!${NC}"
    show_post_install_info
}

# Instalar ferramentas de desenvolvimento
install_development_tools() {
    log "Instalando ferramentas de desenvolvimento..."
    
    # Verificar se estamos no diretório do projeto
    if [ -f "scripts/installation/setup_vscode.sh" ]; then
        ./scripts/installation/setup_vscode.sh
    else
        warn "Diretório do projeto não encontrado. Execute este script de dentro do diretório cluster-ai."
        warn "Instalando VSCode básico..."
        install_vscode_basic
    fi
    
    # Instalar Spyder
    if ! command_exists spyder; then
        source ~/cluster_env/bin/activate
        pip install spyder
        deactivate
        log "Spyder instalado."
    fi
}

# Instalação básica do VSCode (fallback)
install_vscode_basic() {
    if ! command_exists code; then
        case $OS in
            ubuntu)
                wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
                sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
                sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
                sudo apt update
                sudo apt install -y code
                ;;
            manjaro)
                sudo pacman -S --noconfirm code
                ;;
            centos)
                sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https极速加速器.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/y极速加速器um.repos.d/vscode.repo'
                if command_exists dnf; then
                    sudo dnf install -y code
                else
                    sudo yum install -y code
                fi
                ;;
        esac
    fi
}

# Configurar papel do cluster
configure_cluster_role() {
    log "Configurando papel do cluster..."
    
    if [ -f "scripts/installation/main.sh" ]; then
        ./scripts/installation/main.sh
    else
        warn "Script principal não encontrado. Execute a instalação completa primeiro."
    fi
}

# Informações pós-instalação
show_post_install_info() {
    echo -e "\n${BLUE}=== PRÓXIMOS PASSOS ===${NC}"
    echo -e "${GREEN}1. Configure o papel do cluster:${NC}"
    echo "   ./scripts/installation/main.sh"
    echo ""
    echo -e "${GREEN}2. Ative o ambiente Python:${NC}"
    echo "   source ~/cluster_env/bin/activate"
    echo ""
    echo -e "${GREEN}3. Teste a instalação:${NC}"
    echo "   python test_installation.py"
    echo ""
    echo -e "${GREEN}4. Execute demonstrações:${NC}"
    echo "   python demo_cluster.py"
    echo "   python simple_demo.py"
    echo ""
    echo -e "${GREEN}5. Acesse o dashboard:${NC}"
    echo "   http://localhost:8787"
    echo ""
    echo -e "${GREEN}6. Desenvolvimento com VS Code:${NC}"
    echo "   code ."
    echo ""
    echo -e "${YELLOW}Documentação completa em:${NC}"
    echo "   README.md e DEMO_README.md"
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}       INSTALADOR UNIVERSAL CLUSTER AI${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo "Sistema: $(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1)"
    echo "Usuário: $(whoami)"
    echo "Diretório: $(pwd)"
    echo ""
    
    # Verificar se é root
    if [ "$EUID" -eq 0 ]; then
        error "Não execute como root! Use seu usuário normal."
        exit 1
    fi
    
    # Mostrar menu
    show_menu
    
    echo -e "\n${GREEN}🎉 Processo concluído!${NC}"
    echo "Seu ambiente de desenvolvimento está pronto."
}

# Executar
main
