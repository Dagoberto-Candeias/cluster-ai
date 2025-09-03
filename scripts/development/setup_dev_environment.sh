#!/bin/bash

# --------------------------------------------
# 🧰 Script de Configuração para Dev em Ubuntu
# ✅ Ambiente Universal + Python + Dask + Ollama + VS Code
# 🔧 Compatível com KDE, GNOME ou qualquer desktop
# --------------------------------------------

set -e

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
    exit 1
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
fi

log "Sistema detectado: $OS $OS_VERSION"

echo -e "${BLUE}=== CONFIGURAÇÃO DE AMBIENTE DE DESENVOLVIMENTO CLUSTER AI ===${NC}"

# Verificar se é Ubuntu/Debian
if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
    warn "Este script é otimizado para Ubuntu/Debian. Outras distribuições podem ter comportamento imprevisível."
    read -p "Deseja continuar mesmo assim? (s/n): " confirm
    if [ "$confirm" != "s" ]; then
        log "Instalação cancelada."
        exit 0
    fi
fi

log "Atualizando pacotes do sistema..."
sudo apt update && sudo apt upgrade -y

log "Instalando ferramentas básicas de desenvolvimento..."
sudo apt install -y curl wget git unzip build-essential software-properties-common \
    apt-transport-https ca-certificates gnupg lsb-release zsh openssh-server net-tools \
    htop tree tmux ncdu

log "Instalando Python 3, pip e venv..."
sudo apt install -y python3 python3-pip python3-venv python3-full python3-dev

log "Instalando Docker e Docker Compose..."
if ! command_exists docker; then
    sudo apt remove docker docker-engine docker.io containerd runc -y 2>/dev/null || true
    sudo apt install -y docker.io docker-compose-plugin
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    log "Docker instalado e configurado."
else
    log "Docker já está instalado."
fi

log "Criando ambiente virtual padrão para desenvolvimento..."
if [ ! -d "$HOME/venv" ]; then
    python3 -m venv ~/venv
    log "Ambiente virtual criado em ~/venv"
else
    log "Ambiente virtual já existe em ~/venv"
fi

log "Instalando dependências Python para IA e processamento..."
# Ativar ambiente virtual
source ~/venv/bin/activate

pip install --upgrade pip
pip install fastapi[all] pytest httpx uvicorn \
    numpy pandas scipy matplotlib seaborn plotly \
    jupyterlab notebook ipykernel \
    requests beautifulsoup4 lxml

# Desativar ambiente virtual
deactivate

log "Instalando Visual Studio Code..."
if ! command_exists code; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
    sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    sudo apt update
    sudo apt install -y code
    log "VS Code instalado com sucesso."
else
    log "VS Code já está instalado."
fi

log "Instalando e verificando extensões do VS Code..."

# Lista de extensões otimizadas para desenvolvimento com IA e Cluster
vscode_extensions=(
    # Python e IA
    ms-python.python
    ms-toolsai.jupyter
    ms-python.vscode-pylance
    ms-python.pylint
    ms-python.debugpy
    ms-python.autopep8
    ms-python.yapf
    donjayamanne.python-extension-pack
    donjayamanne.python-environment-manager
    kevinrose.vsc-python-indent
    frhtylcn.pythonsnippets
    
    # Git e GitHub
    eamodio.gitlens
    github.vscode-pull-request-github
    github.copilot
    github.copilot-chat
    github.vscode-github-actions
    
    # Docker e Containers
    ms-azuretools.vscode-docker
    ms-vscode-remote.remote-containers
    
    # IA e Assistants
    continuedev.continue
    danielpyne.codegpt
    sourcegraph.cody-ai
    blackboxapp.blackbox
    askcodi.askcodi
    gemini.google-gemini
    
    # Web Development
    esbenp.prettier-vscode
    bradlc.vscode-tailwindcss
    formulahendry.auto-close-tag
    formulahendry.auto-complete-tag
    formulahendry.auto-rename-tag
    
    # Markdown e Documentação
    yzhang.markdown-all-in-one
    bierner.markdown-preview-github-styles
    tomoki1207.pdf
    
    # Utilitários
    njpwerner.autodocstring
    aaron-bond.better-comments
    alefragnani.bookmarks
    formulahendry.code-runner
    streetsidesoftware.code-spell-checker
    streetsidesoftware.code-spell-checker-portuguese-brazilian
    naumovs.color-highlight
    editorconfig.editorconfig
    usernamehw.errorlens
    dbaeumer.vscode-eslint
    waderyan.gitblame
    donjayamanne.githistory
    ritwickdey.liveserver
    ms-vsliveshare.vsliveshare
    tyriar.lorem-ipsum
    ms-vscode.makefile-tools
    pkief.material-icon-theme
    cweijan.vscode-mysql-client2
    christian-kohler.npm-intellisense
    christian-kohler.path-intellisense
    octref.polacode
    postman.postman-for-vscode
    rvest.vs-code-prettier-eslint
    mechatroner.rainbow-csv
    visualstudioexptteam.vscodeintellicode
    redhat.vscode-yaml
    
    # Temas
    dracula-theme.theme-dracula
    atomiks.moonlight
)

log "Verificando e instalando extensões do VS Code..."
for ext in "${vscode_extensions[@]}"; do
    if ! code --list-extensions | grep -q "$ext"; then
        log "Instalando extensão: $ext"
        code --install-extension "$ext" --force 2>/dev/null || \
        warn "Falha ao instalar extensão: $ext (pode já estar instalada)"
    else
        info "Extensão já instalada: $ext"
    fi
done

log "Configurando ambiente para desenvolvimento com Cluster AI..."

# Criar diretório de scripts de desenvolvimento se não existir
mkdir -p ~/dev_scripts

# Script para ativar ambiente e mostrar status
cat > ~/dev_scripts/cluster_dev_setup.sh << 'EOL'
#!/bin/bash
echo "=== AMBIENTE DE DESENVOLVIMENTO CLUSTER AI ==="
echo "Para ativar o ambiente virtual: source ~/venv/bin/activate"
echo "Serviços disponíveis:"
echo "  - VS Code: code ."
echo "  - Docker: systemctl status docker"
echo "  - Python: python3 --version"
EOL

chmod +x ~/dev_scripts/cluster_dev_setup.sh

log "Configurando aliases úteis..."
# Adicionar aliases ao .bashrc se não existirem
if ! grep -q "alias dev-env" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Aliases para desenvolvimento Cluster AI" >> ~/.bashrc
    echo "alias dev-env='~/dev_scripts/cluster_dev_setup.sh'" >> ~/.bashrc
    echo "alias venv-activate='source ~/venv/bin/activate'" >> ~/.bashrc
    echo "alias code-proj='code .'" >> ~/.bashrc
fi

log "Instalação de ferramentas de monitoramento..."
sudo apt install -y glances bashtop

echo -e "${GREEN}🎉 Configuração de ambiente de desenvolvimento concluída!${NC}"
echo ""
echo -e "${BLUE}📋 PRÓXIMOS PASSOS:${NC}"
echo "1. Reinicie o terminal ou execute: source ~/.bashrc"
echo "2. Use 'dev-env' para ver informações do ambiente"
echo "3. Use 'venv-activate' para ativar o ambiente virtual"
echo "4. Use 'code-proj' para abrir VS Code no diretório atual"
echo ""
echo -e "${YELLOW}💡 DICA:${NC} Para desenvolvimento com Cluster AI, instale também:"
echo "   ./install_cluster.sh --role workstation"
echo ""
echo -e "${GREEN}🚀 Ambiente pronto para desenvolvimento!${NC}"
