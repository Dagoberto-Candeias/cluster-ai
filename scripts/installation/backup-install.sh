#!/bin/bash
set -e

echo "=== Instalador Universal Cluster AI - Com Ollama Integrado ==="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variáveis de configuração
ROLE=""
SERVER_IP=""
MACHINE_NAME=$(hostname)
CURRENT_IP=$(hostname -I | awk '{print $1}')
BACKUP_DIR="$HOME/cluster_backups"
OLLAMA_MODELS=("llama3" "deepseek-coder" "mistral" "llava")

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
info "Nome da máquina: $MACHINE_NAME"
info "IP atual: $CURRENT_IP"

# Função para definir o papel da máquina
define_role() {
    echo -e "\n${BLUE}=== DEFINIÇÃO DO PAPEL DESTA MÁQUINA ===${NC}"
    echo "1. Servidor Principal (Scheduler + Serviços + Worker)"
    echo "2. Estação de Trabalho (Worker + IDEs)"
    echo "3. Apenas Worker (Processamento)"
    echo "4. Transformar Estação em Servidor"
    echo "5. Mostrar ajuda sobre os papéis"
    
    read -p "Selecione o papel desta máquina [1-5]: " role_choice
    
    case $role_choice in
        1)
            ROLE="server"
            SERVER_IP="localhost"
            log "Configurando como SERVIDOR PRINCIPAL (Scheduler + Serviços + Worker)"
            info "Esta máquina será o coordenador do cluster e também participará do processamento."
            ;;
        2)
            ROLE="workstation"
            read -p "Digite o IP do servidor principal: " SERVER_IP
            log "Configurando como ESTAÇÃO DE TRABALHO (Worker + IDEs)"
            info "Esta máquina conectará ao servidor $SERVER_IP e terá ferramentas de desenvolvimento."
            ;;
        3)
            ROLE="worker"
            read -p "Digite o IP do servidor principal: " SERVER_IP
            log "Configurando como APENAS WORKER (Processamento)"
            info "Esta máquina será dedicada apenas ao processamento, conectando-se ao servidor $SERVER_IP."
            ;;
        4)
            ROLE="convert"
            SERVER_IP="localhost"
            log "Transformando estação em SERVIDOR"
            info "Esta máquina será promovida a servidor, mantendo suas funções atuais."
            ;;
        5)
            show_role_help
            define_role
            return
            ;;
        *)
            warn "Opção inválida. Configurando como Estação de Trabalho."
            ROLE="workstation"
            read -p "Digite o IP do servidor principal: " SERVER_IP
            ;;
    esac
    
    # Salvar a configuração do papel
    echo "ROLE=$ROLE" > ~/.cluster_role
    echo "SERVER_IP=$SERVER_IP" >> ~/.cluster_role
    echo "MACHINE_NAME=$MACHINE_NAME" >> ~/.cluster_role
    echo "CURRENT_IP=$CURRENT_IP" >> ~/.cluster_role
    echo "BACKUP_DIR=$BACKUP_DIR" >> ~/.cluster_role
}

# Função para mostrar ajuda sobre os papéis
show_role_help() {
    echo -e "\n${BLUE}=== AJUDA SOBRE OS PAPÉIS ===${NC}"
    echo -e "${CYAN}1. Servidor Principal:${NC}"
    echo "   - Atua como coordenador do cluster (scheduler)"
    echo "   - Hospeda serviços (OpenWebUI, Ollama)"
    echo "   - Também participa do processamento (worker)"
    echo "   - Ideal para máquinas mais potentes ou sempre ligadas"
    echo ""
    echo -e "${CYAN}2. Estação de Trabalho:${NC}"
    echo "   - Conecta-se a um servidor principal"
    echo "   - Participa do processamento (worker)"
    echo "   - Inclui IDEs para desenvolvimento (Spyder, VSCode, PyCharm)"
    echo "   - Ideal para máquinas de desenvolvimento"
    echo ""
    echo -e "${CYAN}3. Apenas Worker:${NC}"
    echo "   - Conecta-se a um servidor principal"
    echo "   - Dedica-se apenas ao processamento"
    echo "   - Não inclui ferramentas de desenvolvimento"
    echo "   - Ideal para máquinas com bom hardware para processamento"
    echo ""
    echo -e "${CYAN}4. Transformar Estação em Servidor:${NC}"
    echo "   - Converte uma estação/work em servidor"
    echo "   - Mantém a função de worker"
    echo "   - Adiciona funções de servidor (scheduler, serviços)"
    echo "   - Útil para expandir o cluster"
    echo ""
    read -p "Pressione Enter para continuar..."
}

# Função para carregar configuração existente
load_config() {
    if [ -f ~/.cluster_role ]; then
        source ~/.cluster_role
        info "Configuração carregada: $ROLE em $MACHINE_NAME"
        if [ -n "$SERVER_IP" ] && [ "$SERVER_IP" != "localhost" ]; then
            info "Servidor Principal: $SERVER_IP"
        fi
        if [ -n "$BACKUP_DIR" ]; then
            info "Diretório de backup: $BACKUP_DIR"
        fi
        return 0
    else
        return 1
    fi
}

# Função para instalar dependências básicas
install_dependencies() {
    log "Instalando dependências básicas..."
    
    case $OS in
        ubuntu|debian)
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y curl git docker.io docker-compose-plugin \
                python3-venv python3-pip python3-full \
                msmtp msmtp-mta mailutils openmpi-bin libopenmpi-dev \
                ca-certificates gnupg lsof openssh-server \
                software-properties-common apt-transport-https net-tools \
                nvidia-cuda-toolkit  # Para GPU NVIDIA
            ;;
        manjaro)
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm curl git docker python python-pip python-virtualenv \
                msmtp mailutils openmpi lsof openssh wget \
                base-devel libx11 libxext libxrender libxtst freetype2 net-tools \
                cuda  # Para GPU NVIDIA
            ;;
        centos|rhel|fedora)
            sudo yum update -y
            sudo yum install -y curl git docker python3 python3-pip python3-virtualenv \
                msmtp mailutils openmpi-devel lsof openssh-server \
                libX11-devel libXext-devel libXrender-devel libXtst-devel freetype-devel net-tools \
                cuda  # Para GPU NVIDIA
            ;;
    esac
    
    # Inicializar e habilitar Docker
    if command_exists docker; then
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker $USER
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
    pip install "dask[complete]" distributed numpy pandas scipy mpi4py jupyterlab requests
    deactivate
    
    log "Ambiente Python configurado."
}

# Função para configurar SSH
setup_ssh() {
    log "Configurando SSH..."
    
    # Criar diretório .ssh se não existir
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    
    # Gerar chave SSH se não existir
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
        log "Chave SSH gerada."
    else
        log "Chave SSH já existe."
    fi
    
    echo -e "\n${YELLOW}=== CHAVE PÚBLICA SSH ===${NC}"
    echo -e "${BLUE}"
    cat ~/.ssh/id_rsa.pub
    echo -e "${NC}"
    
    echo -e "\nPara adicionar esta chave a outra máquina:"
    echo "1. Acesse a outra máquina"
    echo "2. Adicione este conteúdo ao arquivo ~/.ssh/authorized_keys"
    echo "3. Execute: chmod 600 ~/.ssh/authorized_keys"
    
    read -p "Deseja adicionar chaves de outras máquinas a esta? (s/n): " add_keys
    if [ "$add_keys" = "s" ]; then
        read -p "Cole a chave pública da outra máquina: " pub_key
        if [ ! -z "$pub_key" ]; then
            echo "$pub_key" >> ~/.ssh/authorized_keys
            chmod 600 ~/.ssh/authorized_keys
            log "Chave adicionada ao authorized_keys."
        fi
    fi
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
    
    # Configurar para escutar em todas as interfaces
    sudo mkdir -p /etc/systemd/system/ollama.service.d/
    sudo tee /etc/systemd/system/ollama.service.d/environment.conf > /dev/null << EOL
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_NUM_GPU_LAYERS=35"
EOL
    
    sudo systemctl daemon-reload
    sudo systemctl restart ollama
    
    # Configuração de GPU
    configure_ollama_gpu
    
    log "Ollama instalado e configurado."
}

# Função para configurar GPU para Ollama
configure_ollama_gpu() {
    log "Configurando GPU para Ollama..."
    
    # Criar diretório de configuração
    mkdir -p ~/.ollama
    
    # Detectar GPU e configurar apropriadamente
    if lspci | grep -i nvidia > /dev/null; then
        log "GPU NVIDIA detectada, configurando para uso com CUDA..."
        cat > ~/.ollama/config.json << EOL
{
    "runners": {
        "nvidia": {
            "url": "https://github.com/ollama/ollama/blob/main/gpu/nvidia/runner.cu"
        }
    },
    "environment": {
        "OLLAMA_NUM_GPU_LAYERS": "35",
        "OLLAMA_MAX_LOADED_MODELS": "3",
        "OLLAMA_KEEP_ALIVE": "24h"
    }
}
EOL
    elif lspci | grep -i amd/ati > /dev/null; then
        log "GPU AMD detectada, configurando para uso com ROCm..."
        cat > ~/.ollama/config.json << EOL
{
    "runners": {
        "rocm": {
            "url": "https://github.com/ollama/ollama/blob/main/gpu/rocm/runner.cc"
        }
    },
    "environment": {
        "OLLAMA_NUM_GPU_LAYERS": "20",
        "OLLAMA_MAX_LOADED_MODELS": "2"
    }
}
EOL
    else
        log "GPU não detectada, usando configuração CPU-only..."
        cat > ~/.ollama/config.json << EOL
{
    "environment": {
        "OLLAMA_MAX_LOADED_MODELS": "1",
        "OLLAMA_KEEP_ALIVE": "1h"
    }
}
EOL
    fi
    
    sudo systemctl restart ollama
}

# Função para baixar modelos Ollama
download_ollama_models() {
    log "Baixando modelos Ollama essenciais..."
    
    for model in "${OLLAMA_MODELS[@]}"; do
        if ollama list | grep -q "$model"; then
            log "Modelo $model já está instalado."
        else
            log "Baixando modelo: $model"
            ollama pull "$model" &
        fi
    done
    
    # Aguardar todos os downloads
    wait
    log "Download de modelos concluído."
}

# Função para verificar saúde do Ollama
health_check_ollama() {
    log "Verificando saúde do Ollama..."
    
    if curl -s http://localhost:11434/api/tags > /dev/null; then
        log "✓ Ollama está respondendo na porta 11434"
        return 0
    else
        error "✗ Ollama não está respondendo"
        
        # Tentativa de reparo
        sudo systemctl restart ollama
        sleep 5
        
        if curl -s http://localhost:11434/api/tags > /dev/null; then
            log "✓ Ollama reparado com sucesso"
            return 0
        else
            error "✗ Falha ao reparar Ollama"
            return 1
        fi
    fi
}

# Função para configurar servidor
setup_server() {
    log "Configurando servidor (scheduler)..."
    
    # Obter IP dinâmico
    IP=$(hostname -I | awk '{print $1}')
    log "IP desta máquina: $IP"
    
    # Criar script para iniciar scheduler
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
    
    # Configurar serviços adicionais
    setup_services
}

# Função para configurar worker
setup_worker() {
    log "Configurando worker..."
    
    if [ -z "$SERVER_IP" ]; then
        read -p "Digite o IP do servidor principal: " SERVER_IP
        echo "SERVER_IP=$SERVER_IP" >> ~/.cluster_role
    fi
    
    # Se SERVER_IP for "localhost", usar o IP atual
    if [ "$SERVER_IP" = "localhost" ]; then
        SERVER_IP=$CURRENT_IP
    fi
    
    # Criar script para iniciar worker
    cat > ~/cluster_scripts/start_worker.sh << EOL
#!/bin/bash
source ~/cluster_env/bin/activate

# Tentar conectar ao scheduler
while true; do
    if nc -z -w 5 $SERVER_IP 8786; then
        echo "Conectando ao scheduler em $SERVER_IP:8786"
        dask-worker $SERVER_IP:8786 --nworkers auto --nthreads 2 --name $MACHINE_NAME
        break
    else
        echo "Scheduler não disponível. Tentando novamente em 10 segundos..."
        sleep 10
    fi
done
EOL
    
    chmod +x ~/cluster_scripts/start_worker.sh
    
    # Iniciar worker
    pkill -f "dask-worker" || true
    nohup ~/cluster_scripts/start_worker.sh > ~/worker.log 2>&1 &
    
    log "Worker configurado para conectar ao scheduler: $SERVER_IP:8786"
}

# Função para configurar serviços
setup_services() {
    log "Configurando serviços adicionais..."
    
    # OpenWebUI
    if sudo docker ps -a --format '{{.Names}}' | grep -q '^open-webui$'; then
        log "OpenWebUI já está instalado."
    else
        sudo docker run -d --name open-webui -p 8080:8080 -v $HOME/open-webui:/app/data ghcr.io/open-webui/open-webui:main
        log "OpenWebUI instalado. Acesse: http://$(hostname -I | awk '{print $1}'):8080"
    fi
}

# Função para instalar IDEs
install_ides() {
    log "Instalando IDEs..."
    
    # Spyder
    if ! command_exists spyder; then
        source ~/cluster_env/bin/activate
        pip install spyder
        deactivate
        log "Spyder instalado."
    else
        log "Spyder já está instalado."
    fi
    
    # VSCode
    if ! command_exists code; then
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
        log "VSCode instalado."
    else
        log "VSCode já está instalado."
    fi
    
    # PyCharm
    if [ ! -d "/opt/pycharm" ]; then
        PYCHARM_URL="https://download.jetbrains.com/python/pycharm-community-2023.2.3.tar.gz"
        wget -O /tmp/pycharm.tar.gz $PYCHARM_URL
        sudo tar -xzf /tmp/pycharm.tar.gz -C /opt/
        sudo mv /opt/pycharm-* /opt/pycharm
        
        # Criar atalho
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
        
        log "PyCharm instalado."
    else
        log "PyCharm já está instalado."
    fi
}

# Função para converter estação em servidor
convert_to_server() {
    warn "Transformando esta estação em servidor..."
    ROLE="server"
    SERVER_IP="localhost"
    echo "ROLE=server" > ~/.cluster_role
    echo "SERVER_IP=localhost" >> ~/.cluster_role
    echo "MACHINE_NAME=$MACHINE_NAME" >> ~/.cluster_role
    echo "CURRENT_IP=$CURRENT_IP" >> ~/.cluster_role
    
    # Parar worker se estiver executando
    pkill -f "dask-worker" || true
    
    # Configurar como servidor
    setup_server
    
    # Configurar como worker também
    setup_worker
    
    log "Conversão concluída. Esta máquina agora é um servidor completo."
}

# Função para configurar firewall
configure_firewall() {
    log "Configurando firewall para o cluster..."
    
    if command_exists ufw; then
        sudo ufw allow 22/tcp    # SSH
        sudo ufw allow 8786/tcp  # Dask Scheduler
        sudo ufw allow 8787/tcp  # Dask Dashboard
        sudo ufw allow 8080/tcp  # OpenWebUI
        sudo ufw allow 11434/tcp # Ollama API
        
        # Se for servidor, permite conexões de entrada
        if [ "$ROLE" = "server" ] || [ "$ROLE" = "both" ]; then
            sudo ufw allow from any to any port 11434 proto tcp
        fi
        
        sudo ufw --force enable
        log "Firewall configurado."
    else
        warn "UFW não disponível, pulando configuração de firewall."
    fi
}

# Função principal de configuração
setup_based_on_role() {
    case $ROLE in
        "server")
            install_ollama
            download_ollama_models
            setup_server
            setup_worker  # Servidor também é um worker
            ;;
        "workstation")
            install_ollama
            download_ollama_models
            install_ides
            setup_worker
            ;;
        "worker")
            install_ollama
            setup_worker
            ;;
        "convert")
            install_ollama
            download_ollama_models
            convert_to_server
            ;;
        *)
            warn "Papel não reconhecido: $ROLE"
            ;;
    esac
    
    # Configurar firewall
    configure_firewall
    
    # Verificar saúde do Ollama
    health_check_ollama
}

# Função para mostrar status
show_status() {
    echo -e "\n${BLUE}=== STATUS DO SISTEMA ===${NC}"
    echo -e "Papel: ${CYAN}$ROLE${NC}"
    echo -e "Máquina: ${CYAN}$MACHINE_NAME${NC}"
    
    if [ -n "$SERVER_IP" ]; then
        if [ "$SERVER_IP" = "localhost" ]; then
            echo -e "Servidor: ${CYAN}Esta máquina${NC}"
        else
            echo -e "Servidor: ${CYAN}$SERVER_IP${NC}"
        fi
    fi
    
    # Verificar serviços em execução
    echo -e "\n${YELLOW}Serviços:${NC}"
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
    
    if sudo docker ps -a --format '{{.Names}}' | grep -q '^open-webui$'; then
        echo "✓ OpenWebUI está instalado"
    else
        echo "✗ OpenWebUI não está instalado"
    fi
    
    # Verificar IP atual
    IP=$(hostname -I | awk '{print $1}')
    echo -e "\n${YELLOW}IP atual:${NC} $IP"
    
    # Verificar chaves SSH
    echo -e "\n${YELLOW}Chaves SSH:${NC}"
    if [ -f ~/.ssh/id_rsa.pub ]; then
        echo "✓ Chave SSH existe"
        echo "Chave pública: $(cat ~/.ssh/id_rsa.pub | awk '{print $3}')"
    else
        echo "✗ Chave SSH não existe"
    fi
    
    # Verificar ambiente Python
    echo -e "\n${YELLOW}Ambiente Python:${NC}"
    if [ -d "$HOME/cluster_env" ]; then
        echo "✓ Ambiente virtual existe"
    else
        echo "✗ Ambiente virtual não existe"
    fi
    
    # Verificar Ollama
    echo -e "\n${YELLOW}Ollama:${NC}"
    if curl -s http://localhost:11434/api/tags > /dev/null; then
        echo "✓ API do Ollama está respondendo"
        echo "Modelos instalados:"
        ollama list
    else
        echo "✗ API do Ollama não está respondendo"
    fi
}

# Função para menu principal
main_menu() {
    # Verificar se já existe configuração
    if ! load_config; then
        info "Nenhuma configuração encontrada. Definindo papel da máquina..."
        define_role
    fi
    
    while true; do
        echo -e "\n${BLUE}=== MENU PRINCIPAL - $MACHINE_NAME ($ROLE) ===${NC}"
        echo "1. Instalar dependências básicas"
        echo "2. Configurar ambiente Python"
        echo "3. Configurar SSH e trocar chaves"
        echo "4. Executar configuração baseada no papel"
        echo "5. Alterar papel desta máquina"
        echo "6. Ver status do sistema"
        echo "7. Reiniciar serviços"
        echo "8. Backup e Restauração"
        echo "9. Sair"
        
        read -p "Selecione uma opção [1-9]: " choice
        
        case $choice in
            1) install_dependencies ;;
            2) setup_python_env ;;
            3) setup_ssh ;;
            4) setup_based_on_role ;;
            5) 
                define_role
                setup_based_on_role
                ;;
            6) show_status ;;
            7)
                pkill -f "dask-scheduler" || true
                pkill -f "dask-worker" || true
                pkill -f "ollama" || true
                setup_based_on_role
                ;;
            8)
                backup_menu
                ;;
            9) break ;;
            *) warn "Opção inválida. Tente novamente." ;;
        esac
    done
}

# Criar diretório para scripts
mkdir -p ~/cluster_scripts

# Executar menu principal
main_menu

log "Instalação e configuração concluídas!"
echo -e "\n${GREEN}=== RESUMO DA CONFIGURAÇÃO ===${NC}"
echo "Papel: $ROLE"
echo "Máquina: $MACHINE_NAME"
if [ -n "$SERVER_IP" ]; then
    if [ "$SERVER_IP" = "localhost" ]; then
        echo "Servidor: Esta máquina"
    else
        echo "Servidor: $SERVER_IP"
    fi
fi
echo "Scripts de gerenciamento: ~/cluster_scripts/"
echo "Diretório de backup: $BACKUP_DIR"
echo "Arquivo de configuração: ~/.cluster_role"