#!/bin/bash
set -e

echo "=== Instalador Universal Cluster AI com IDEs ==="
echo "Suporte para: Ubuntu, Debian, Manjaro, CentOS"
echo "IDEs incluídas: Spyder, VSCode, PyCharm"

# Detectar distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
else
    echo "Não foi possível detectar o sistema operacional."
    exit 1
fi

echo "Sistema detectado: $OS $OS_VERSION"

# Função para instalar em diferentes distribuições
install_dependencies() {
    case $OS in
        ubuntu|debian)
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y curl git docker.io docker-compose-plugin \
                python3-venv python3-pip python3-full \
                msmtp msmtp-mta mailutils openmpi-bin libopenmpi-dev \
                ca-certificates gnupg lsof openssh-server \
                software-properties-common apt-transport-https
            ;;
        manjaro)
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm curl git docker python python-pip python-virtualenv \
                msmtp mailutils openmpi lsof openssh wget \
                base-devel libx11 libxext libxrender libxtst freetype2
            ;;
        centos|rhel|fedora)
            sudo yum update -y
            sudo yum install -y curl git docker python3 python3-pip python3-virtualenv \
                msmtp mailutils openmpi-devel lsof openssh-server \
                libX11-devel libXext-devel libXrender-devel libXtst-devel freetype-devel
            ;;
        *)
            echo "Sistema não suportado: $OS"
            exit 1
            ;;
    esac
}

# Função para instalar IDEs
install_ides() {
    echo "Instalando IDEs..."
    
    # Spyder
    source ~/cluster_env/bin/activate
    pip install spyder
    deactivate
    
    # VSCode
    case $OS in
        ubuntu|debian)
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
            sudo apt update
            sudo apt install -y code
            ;;
        manjaro)
            sudo pacman -S --noconfirm code
            ;;
        centos|rhel|fedora)
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            sudo yum install -y code
            ;;
    esac
    
    # PyCharm Community
    PYCHARM_URL="https://download.jetbrains.com/python/pycharm-community-2023.2.3.tar.gz"
    wget -O /tmp/pycharm.tar.gz $PYCHARM_URL
    sudo tar -xzf /tmp/pycharm.tar.gz -C /opt/
    sudo mv /opt/pycharm-* /opt/pycharm
    
    # Criar atalhos para as IDEs
    mkdir -p ~/.local/share/applications
    
    # Atalho para Spyder no ambiente virtual
    cat > ~/.local/share/applications/spyder-cluster.desktop << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Spyder (Cluster AI)
Exec=bash -c "source ~/cluster_env/bin/activate && spyder"
Icon=spyder
Comment=Spyder IDE with Cluster AI environment
Categories=Development;IDE;
Terminal=false
EOL
    
    # Atalho para PyCharm
    cat > ~/.local/share/applications/pycharm-cluster.desktop << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=PyCharm (Cluster AI)
Exec=/opt/pycharm/bin/pycharm.sh
Icon=/opt/pycharm/bin/pycharm.png
Comment=PyCharm IDE for Cluster AI development
Categories=Development;IDE;
Terminal=false
EOL
    
    echo "IDEs instaladas: Spyder, VSCode e PyCharm"
}

# Função para configurar o ambiente de desenvolvimento
setup_development_environment() {
    echo "Configurando ambiente de desenvolvimento..."
    
    # Configurar VSCode para usar o ambiente virtual
    mkdir -p ~/.config/Code/User
    cat > ~/.config/Code/User/settings.json << EOL
{
    "python.defaultInterpreterPath": "$HOME/cluster_env/bin/python",
    "python.terminal.activateEnvironment": true,
    "python.analysis.extraPaths": [
        "$HOME/cluster_env/lib/python3.*/site-packages"
    ],
    "jupyter.notebookFileRoot": "$HOME",
    "python.formatting.autopep8Path": "$HOME/cluster_env/bin/autopep8",
    "python.linting.flake8Path": "$HOME/cluster_env/bin/flake8",
    "python.linting.pylintPath": "$HOME/cluster_env/bin/pylint"
}
EOL

    # Instalar extensões úteis no VSCode
    code --install-extension ms-python.python
    code --install-extension ms-toolsai.jupyter
    code --install-extension formulahendry.code-runner
    code --install-extension ms-vscode.cpptools
    
    # Configurar PyCharm para detectar o ambiente virtual
    # (Será necessário configurar manualmente no primeiro uso)
}

# Instalação principal
install_dependencies

# Inicializar e habilitar Docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Configuração comum a todas as distribuições
if [ ! -d "$HOME/cluster_env" ]; then
    echo "Criando ambiente virtual em ~/cluster_env"
    python3 -m venv ~/cluster_env
fi

# Instalar dependências no ambiente virtual
source ~/cluster_env/bin/activate
pip install --upgrade pip
pip install "dask[complete]" distributed numpy pandas scipy mpi4py jupyterlab
deactivate

# Configuração do SSH para cluster
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Gerando chave SSH..."
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
fi

echo "Chave pública SSH:"
cat ~/.ssh/id_rsa.pub
echo "Adicione esta chave às outras máquinas do cluster em ~/.ssh/authorized_keys"

# Instalar IDEs
install_ides

# Configurar ambiente de desenvolvimento
setup_development_environment

# Scripts de gerenciamento do cluster
mkdir -p ~/cluster_scripts

cat > ~/cluster_scripts/start_scheduler.sh << 'EOL'
#!/bin/bash
source ~/cluster_env/bin/activate
dask-scheduler --host 0.0.0.0 --port 8786
EOL

cat > ~/cluster_scripts/start_worker.sh << 'EOL'
#!/bin/bash
source ~/cluster_env/bin/activate

if [ -z "$1" ]; then
    echo "Uso: ./start_worker.sh <endereço-do-scheduler>"
    exit 1
fi

dask-worker $1:8786 --nworkers auto --nthreads 2
EOL

chmod +x ~/cluster_scripts/*.sh

echo "=== Instalação concluída! ==="
echo "IDEs disponíveis: Spyder, VSCode e PyCharm"
echo "Ambiente virtual em: ~/cluster_env"
echo "Scripts de gerenciamento em: ~/cluster_scripts"