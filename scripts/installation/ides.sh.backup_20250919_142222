#!/bin/bash
set -e

echo "=== Instalador Universal Cluster AI com IDEs ==="
echo "Suporte para: Ubuntu, Debian, Manjaro, CentOS"
echo "IDEs incluídas: Spyder, VSCode, PyCharm, RStudio, Jamovi, Jupyter"

# Função para instalar IDE específica
install_spyder() {
    echo "Instalando Spyder..."
    source ~/cluster_env/bin/activate
    pip install spyder
    deactivate
}

install_vscode() {
    echo "Instalando VSCode..."
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
}

install_pycharm() {
    echo "Instalando PyCharm..."
    PYCHARM_URL="https://download.jetbrains.com/python/pycharm-community-2023.2.3.tar.gz"
    wget -O /tmp/pycharm.tar.gz $PYCHARM_URL
    sudo tar -xzf /tmp/pycharm.tar.gz -C /opt/
    sudo mv /opt/pycharm-* /opt/pycharm
}

install_rstudio() {
    echo "Instalando RStudio..."
    RSTUDIO_URL="https://download1.rstudio.org/desktop/bionic/amd64/rstudio-2023.06.1-524-amd64.deb"
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        wget -O /tmp/rstudio.deb $RSTUDIO_URL
        sudo dpkg -i /tmp/rstudio.deb || sudo apt-get install -f -y
    else
        echo "Instalação do RStudio não suportada automaticamente para $OS. Instale manualmente."
    fi
}

install_jamovi() {
    echo "Instalando Jamovi..."
    flatpak install flathub org.jamovi.jamovi -y
}

install_jupyter() {
    echo "Instalando Jupyter..."
    source ~/cluster_env/bin/activate
    pip install jupyterlab notebook
    deactivate
}

create_shortcuts() {
    echo "Criando atalhos..."
    mkdir -p ~/.local/share/applications

    # Atalho para Spyder no ambiente virtual (se instalado)
    if [[ " ${INSTALLED_IDES[@]} " =~ " Spyder " ]]; then
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
    fi

    # Atalho para VSCode (se instalado)
    if [[ " ${INSTALLED_IDES[@]} " =~ " VSCode " ]]; then
        cat > ~/.local/share/applications/code.desktop << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=VSCode (Cluster AI)
Exec=code
Icon=code
Comment=Visual Studio Code for Cluster AI
Categories=Development;IDE;
Terminal=false
EOL
    fi

    # Atalho para PyCharm (se instalado)
    if [[ " ${INSTALLED_IDES[@]} " =~ " PyCharm " ]]; then
        cat > ~/.local/share/applications/pycharm.desktop << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=PyCharm
Exec=/opt/pycharm/bin/pycharm.sh
Icon=/opt/pycharm/bin/pycharm.png
Comment=PyCharm IDE
Categories=Development;IDE;
Terminal=false
EOL

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
    fi

    # Atalho para RStudio (se instalado)
    if [[ " ${INSTALLED_IDES[@]} " =~ " RStudio " ]]; then
        cat > ~/.local/share/applications/rstudio-cluster.desktop << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=RStudio (Cluster AI)
Exec=rstudio
Icon=rstudio
Comment=RStudio IDE for Cluster AI
Categories=Development;IDE;
Terminal=false
EOL
    fi

    # Atalho para Jamovi (se instalado)
    if [[ " ${INSTALLED_IDES[@]} " =~ " Jamovi " ]]; then
        cat > ~/.local/share/applications/jamovi.desktop << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Jamovi
Exec=flatpak run org.jamovi.jamovi
Icon=/var/lib/flatpak/exports/share/icons/hicolor/scalable/apps/org.jamovi.jamovi.svg
Comment=Jamovi statistical software
Categories=Development;IDE;Education;Science;Statistics;
Terminal=false
EOL

        cat > ~/.local/share/applications/jamovi-cluster.desktop << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Jamovi (Cluster AI)
Exec=flatpak run org.jamovi.jamovi
Icon=/var/lib/flatpak/exports/share/icons/hicolor/scalable/apps/org.jamovi.jamovi.svg
Comment=Jamovi statistical software for Cluster AI
Categories=Development;IDE;Education;Science;Statistics;
Terminal=false
EOL
    fi

    # Atalho para Jupyter (se instalado)
    if [[ " ${INSTALLED_IDES[@]} " =~ " Jupyter " ]]; then
        cat > ~/.local/share/applications/jupyter-cluster.desktop << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Jupyter (Cluster AI)
Exec=bash -c "source ~/cluster_env/bin/activate && jupyter lab"
Icon=jupyter
Comment=Jupyter Lab with Cluster AI environment
Categories=Development;IDE;
Terminal=false
EOL
    fi

    update-desktop-database ~/.local/share/applications
}

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

# Carregar script de verificação pré-instalação
PRE_INSTALL_CHECK_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/pre_install_check.sh"
if [ ! -f "$PRE_INSTALL_CHECK_PATH" ]; then
    echo "Script de verificação pré-instalação não encontrado em $PRE_INSTALL_CHECK_PATH"
    exit 1
fi

# Carregar script de verificação de gerenciadores de pacotes
PACKAGE_MANAGERS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/check_package_managers.sh"
if [ ! -f "$PACKAGE_MANAGERS_PATH" ]; then
    echo "Script de verificação de gerenciadores não encontrado em $PACKAGE_MANAGERS_PATH"
    exit 1
fi

install_dependencies() {
    case $OS in
        ubuntu|debian)
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y curl git docker.io \
                python3-venv python3-pip python3-full \
                msmtp msmtp-mta mailutils openmpi-bin libopenmpi-dev \
                ca-certificates gnupg lsof openssh-server \
                apt-transport-https \
                r-base
            ;;
        manjaro)
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm curl git docker python python-pip python-virtualenv \
                msmtp mailutils openmpi lsof openssh wget \
                base-devel libx11 libxext libxrender libxtst freetype2 \
                r
            ;;
        centos|rhel|fedora)
            sudo yum update -y
            sudo yum install -y curl git docker python3 python3-pip python3-virtualenv \
                msmtp mailutils openmpi-devel lsof openssh-server \
                libX11-devel libXext-devel libXrender-devel libXtst-devel freetype-devel \
                R
            ;;
        *)
            echo "Sistema não suportado: $OS"
            exit 1
            ;;
    esac
}

uninstall_spyder() {
    echo "Desinstalando Spyder..."
    source ~/cluster_env/bin/activate
    pip uninstall -y spyder
    deactivate
}

uninstall_vscode() {
    echo "Desinstalando VSCode..."
    case $OS in
        ubuntu|debian)
            sudo apt remove -y code
            ;;
        manjaro)
            sudo pacman -Rns --noconfirm code
            ;;
        centos|rhel|fedora)
            sudo yum remove -y code
            ;;
    esac
}

uninstall_pycharm() {
    echo "Desinstalando PyCharm..."
    sudo rm -rf /opt/pycharm
}

uninstall_rstudio() {
    echo "Desinstalando RStudio..."
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        sudo apt remove -y rstudio
    else
        echo "Remoção automática do RStudio não suportada para $OS. Remova manualmente."
    fi
}

uninstall_jamovi() {
    echo "Desinstalando Jamovi..."
    flatpak uninstall -y org.jamovi.jamovi
}

uninstall_jupyter() {
    echo "Desinstalando Jupyter..."
    source ~/cluster_env/bin/activate
    pip uninstall -y jupyterlab notebook
    deactivate
}

manage_ides() {
    echo "Escolha a ação:"
    echo "1) Instalar IDEs"
    echo "2) Desinstalar IDEs"
    read -p "Digite sua escolha (1 ou 2): " action_choice

    if [ "$action_choice" = "1" ]; then
        echo "Escolha o tipo de instalação:"
        echo "1) Instalar todas as IDEs"
        echo "2) Escolher IDEs específicas"
        read -p "Digite sua escolha (1 ou 2): " install_choice

        # Executar verificação pré-instalação
        bash "$PRE_INSTALL_CHECK_PATH" || echo "Aviso: pré-verificação falhou, prosseguindo com a instalação..."

        # Verificar e instalar gerenciadores de pacotes
        source "$PACKAGE_MANAGERS_PATH"
        install_snap

        INSTALLED_IDES=()

        if [ "$install_choice" = "1" ]; then
            echo "Instalando todas as IDEs..."
            install_spyder && INSTALLED_IDES+=("Spyder")
            install_vscode && INSTALLED_IDES+=("VSCode")
            install_pycharm && INSTALLED_IDES+=("PyCharm")
            install_rstudio && INSTALLED_IDES+=("RStudio")
            install_jamovi && INSTALLED_IDES+=("Jamovi")
            install_jupyter && INSTALLED_IDES+=("Jupyter")
        else
            echo "Escolha as IDEs para instalar (digite os números separados por espaço):"
            echo "1) Spyder"
            echo "2) VSCode"
            echo "3) PyCharm"
            echo "4) RStudio"
            echo "5) Jamovi"
            echo "6) Jupyter"
            read -p "Digite os números: " -a selected_ides

            for ide in "${selected_ides[@]}"; do
                case $ide in
                    1) install_spyder && INSTALLED_IDES+=("Spyder") ;;
                    2) install_vscode && INSTALLED_IDES+=("VSCode") ;;
                    3) install_pycharm && INSTALLED_IDES+=("PyCharm") ;;
                    4) install_rstudio && INSTALLED_IDES+=("RStudio") ;;
                    5) install_jamovi && INSTALLED_IDES+=("Jamovi") ;;
                    6) install_jupyter && INSTALLED_IDES+=("Jupyter") ;;
                    *) echo "Opção inválida: $ide" ;;
                esac
            done
        fi

        # Criar atalhos apenas para as IDEs instaladas
        create_shortcuts

        echo "IDEs instaladas: ${INSTALLED_IDES[*]}"
    elif [ "$action_choice" = "2" ]; then
        echo "Escolha as IDEs para desinstalar (digite os números separados por espaço):"
        echo "1) Spyder"
        echo "2) VSCode"
        echo "3) PyCharm"
        echo "4) RStudio"
        echo "5) Jamovi"
        echo "6) Jupyter"
        read -p "Digite os números: " -a selected_ides

        for ide in "${selected_ides[@]}"; do
            case $ide in
                1) uninstall_spyder ;;
                2) uninstall_vscode ;;
                3) uninstall_pycharm ;;
                4) uninstall_rstudio ;;
                5) uninstall_jamovi ;;
                6) uninstall_jupyter ;;
                *) echo "Opção inválida: $ide" ;;
            esac
        done

        echo "Desinstalação concluída."
    else
        echo "Opção inválida. Saindo."
        exit 1
    fi
}

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

    # Configurar Jupyter
    mkdir -p ~/.jupyter
    cat > ~/.jupyter/jupyter_lab_config.py << EOL
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.root_dir = '$HOME'
c.ServerApp.allow_origin = '*'
c.ServerApp.allow_credentials = True
EOL
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

# Gerenciar IDEs (instalar/desinstalar)
manage_ides

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
echo "IDEs disponíveis: Spyder, VSCode, PyCharm, RStudio, Jamovi e Jupyter"
echo "Ambiente virtual em: ~/cluster_env"
echo "Scripts de gerenciamento em: ~/cluster_scripts"

# Perguntar qual IDE usar para conectar ao cluster
echo "Qual IDE deseja usar para conectar ao cluster?"
select ide_choice in "Spyder" "VSCode" "PyCharm" "RStudio" "Jamovi" "Jupyter" "Nenhuma"; do
    case $ide_choice in
        Spyder)
            echo "Iniciando Spyder com ambiente Cluster AI..."
            source ~/cluster_env/bin/activate
            spyder
            break
            ;;
        VSCode)
            echo "Iniciando VSCode..."
            code
            break
            ;;
        PyCharm)
            echo "Iniciando PyCharm..."
            /opt/pycharm/bin/pycharm.sh
            break
            ;;
        RStudio)
            echo "Iniciando RStudio..."
            rstudio
            break
            ;;
        Jamovi)
            echo "Iniciando Jamovi..."
            flatpak run org.jamovi.jamovi
            break
            ;;
        Jupyter)
            echo "Iniciando Jupyter Lab..."
            source ~/cluster_env/bin/activate
            jupyter lab
            break
            ;;
        Nenhuma)
            echo "Nenhuma IDE selecionada. Finalizando."
            break
            ;;
        *)
            echo "Opção inválida. Tente novamente."
            ;;
    esac
done
