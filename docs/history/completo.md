Cluster AI - Script de Instalação Completo
📋 Parte 1: Cabeçalho e Configurações Iniciais
bash
#!/bin/bash
set -e

echo "=== Instalador Universal Cluster AI - Versão 2.0 ==="
echo "=== Sistema Completo de Processamento Distribuído ==="
echo "=== Com Dask, Ollama, OpenWebUI e Múltiplas IDEs ==="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Variáveis de configuração
ROLE=""
SERVER_IP=""
MACHINE_NAME=$(hostname)
CURRENT_IP=$(hostname -I | awk '{print $1}')
BACKUP_DIR="$HOME/cluster_backups"
OLLAMA_MODELS=("llama3" "deepseek-coder" "mistral" "llava" "phi3" "codellama")
OLLAMA_HOST="0.0.0.0"
OLLAMA_PORT="11434"
CLUSTER_ENV="$HOME/cluster_env"
CLUSTER_SCRIPTS="$HOME/cluster_scripts"
LOG_DIR="$HOME/cluster_logs"

# Configuração de portas
DASK_SCHEDULER_PORT="8786"
DASK_DASHBOARD_PORT="8787"
OPENWEBUI_PORT="8080"
OLLAMA_PORT="11434"

# URLs de download
OPENWEBUI_IMAGE="ghcr.io/open-webui/open-webui:main"
PYCHARM_URL="https://download.jetbrains.com/python/pycharm-community-2023.2.3.tar.gz"

# Configuração de GPU
GPU_TYPE="none"
CUDA_LAYERS=35
ROCm_LAYERS=20

# Função para log colorido
log() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

debug() {
    echo -e "${MAGENTA}[DEBUG]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para verificar permissões de sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        if ! sudo -n true 2>/dev/null; then
            error "Este script requer privilégios de sudo. Execute com sudo ou como root."
            exit 1
        fi
    fi
}

# Função para criar diretórios necessários
create_directories() {
    log "Criando diretórios necessários..."
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$CLUSTER_SCRIPTS"
    mkdir -p "$LOG_DIR"
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
    log "Diretórios criados com sucesso."
}

# Função para detecção de distribuição
detect_os() {
    log "Detectando sistema operacional..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
        OS_NAME=$NAME
    elif [ -f /etc/redhat-release ]; then
        OS="rhel"
        OS_VERSION=$(cat /etc/redhat-release | sed -E 's/.*release ([0-9]+).*/\1/')
        OS_NAME="Red Hat Enterprise Linux"
    elif [ -f /etc/arch-release ]; then
        OS="arch"
        OS_VERSION="rolling"
        OS_NAME="Arch Linux"
    else
        error "Não foi possível detectar o sistema operacional."
        exit 1
    fi

    # Detectar arquitetura
    ARCH=$(uname -m)
    
    # Detectar GPU
    detect_gpu

    log "Sistema detectado: $OS_NAME $OS_VERSION ($ARCH)"
    info "Nome da máquina: $MACHINE_NAME"
    info "IP atual: $CURRENT_IP"
    info "Tipo de GPU: $GPU_TYPE"
}

# Função para detectar GPU
detect_gpu() {
    if lspci | grep -i "nvidia" > /dev/null; then
        GPU_TYPE="nvidia"
        log "GPU NVIDIA detectada."
    elif lspci | grep -i "amd" > /dev/null; then
        GPU_TYPE="amd"
        log "GPU AMD detectada."
    else
        GPU_TYPE="none"
        log "Nenhuma GPU dedicada detectada, usando modo CPU."
    fi
}

# Função para pausar e esperar enter
press_enter() {
    echo -e "\n${BLUE}Pressione Enter para continuar...${NC}"
    read
}

# Função para limpar a tela
clear_screen() {
    clear
}

# Função para exibir banner
show_banner() {
    clear_screen
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   CLUSTER AI INSTALLER                       ║"
    echo "║                   Versão 2.0 - 2024                          ║"
    echo "║                                                              ║"
    echo "║    Sistema Completo de Processamento Distribuído de IA       ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}
📋 Parte 2: Funções de Backup e Restauração
bash
# Função para criar diretório de backups
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        log "Diretório de backups criado: $BACKUP_DIR"
    fi
}

# Função para fazer backup
backup_data() {
    create_backup_dir
    
    echo -e "\n${BLUE}=== BACKUP DE DADOS DO CLUSTER ===${NC}"
    echo "1. Backup completo (tudo)"
    echo "2. Backup dos modelos Ollama"
    echo "3. Backup das configurações"
    echo "4. Backup dos dados do OpenWebUI"
    echo "5. Backup do ambiente Python"
    echo "6. Definir diretório de backup personalizado"
    echo "7. Voltar"
    
    read -p "Selecione o tipo de backup [1-7]: " backup_choice
    
    case $backup_choice in
        1)
            backup_complete
            ;;
        2)
            backup_ollama_models
            ;;
        3)
            backup_configurations
            ;;
        4)
            backup_openwebui_data
            ;;
        5)
            backup_python_env
            ;;
        6)
            set_custom_backup_dir
            ;;
        7)
            return
            ;;
        *)
            warn "Opção inválida."
            ;;
    esac
}

# Backup completo
backup_complete() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/cluster_backup_${timestamp}.tar.gz"
    
    log "Iniciando backup completo..."
    
    # Lista de itens para backup
    local items_to_backup=(
        "$HOME/.cluster_role"
        "$CLUSTER_SCRIPTS"
        "$HOME/.ollama"
        "$HOME/open-webui"
        "$HOME/.ssh"
        "$CLUSTER_ENV"
        "$HOME/.msmtprc"
        "$HOME/.gmail_pass.gpg"
        "$LOG_DIR"
    )
    
    # Verificar quais itens existem
    local existing_items=()
    for item in "${items_to_backup[@]}"; do
        if [ -e "$item" ]; then
            existing_items+=("$item")
        else
            warn "Item não encontrado: $item"
        fi
    done
    
    if [ ${#existing_items[@]} -eq 0 ]; then
        error "Nenhum item encontrado para backup."
        return 1
    fi
    
    # Criar backup
    log "Criando arquivo de backup: $backup_file"
    tar -czf "$backup_file" "${existing_items[@]}"
    
    if [ $? -eq 0 ]; then
        log "Backup completo criado com sucesso: $backup_file"
        log "Tamanho do backup: $(du -h "$backup_file" | cut -f1)"
    else
        error "Falha ao criar backup."
        return 1
    fi
}

# Backup dos modelos Ollama
backup_ollama_models() {
    if [ ! -d "$HOME/.ollama" ]; then
        error "Diretório de modelos Ollama não encontrado."
        return 1
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/ollama_models_${timestamp}.tar.gz"
    
    log "Fazendo backup dos modelos Ollama..."
    
    tar -czf "$backup_file" -C "$HOME" .ollama
    
    if [ $? -eq 0 ]; then
        log "Backup dos modelos Ollama criado com sucesso: $backup_file"
        log "Tamanho do backup: $(du -h "$backup_file" | cut -f1)"
    else
        error "Falha ao criar backup dos modelos Ollama."
        return 1
    fi
}

# Backup das configurações
backup_configurations() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/cluster_config_${timestamp}.tar.gz"
    
    log "Fazendo backup das configurações..."
    
    # Itens de configuração para backup
    local config_items=(
        "$HOME/.cluster_role"
        "$CLUSTER_SCRIPTS"
        "$HOME/.ssh"
        "$HOME/.msmtprc"
        "$HOME/.gmail_pass.gpg"
    )
    
    # Verificar quais itens existem
    local existing_items=()
    for item in "${config_items[@]}"; do
        if [ -e "$item" ]; then
            existing_items+=("$item")
        else
            warn "Item não encontrado: $item"
        fi
    done
    
    if [ ${#existing_items[@]} -eq 0 ]; then
        error "Nenhum item de configuração encontrado para backup."
        return 1
    fi
    
    # Criar backup
    tar -czf "$backup_file" "${existing_items[@]}"
    
    if [ $? -eq 0 ]; then
        log "Backup das configurações criado com sucesso: $backup_file"
        log "Tamanho do backup: $(du -h "$backup_file" | cut -f1)"
    else
        error "Falha ao criar backup das configurações."
        return 1
    fi
}

# Backup dos dados do OpenWebUI
backup_openwebui_data() {
    if [ ! -d "$HOME/open-webui" ]; then
        error "Diretório de dados do OpenWebUI não encontrado."
        return 1
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/openwebui_data_${timestamp}.tar.gz"
    
    log "Fazendo backup dos dados do OpenWebUI..."
    
    tar -czf "$backup_file" -C "$HOME" open-webui
    
    if [ $? -eq 0 ]; then
        log "Backup dos dados do OpenWebUI criado com sucesso: $backup_file"
        log "Tamanho do backup: $(du -h "$backup_file" | cut -f1)"
    else
        error "Falha ao criar backup dos dados do OpenWebUI."
        return 1
    fi
}

# Backup do ambiente Python
backup_python_env() {
    if [ ! -d "$CLUSTER_ENV" ]; then
        error "Ambiente Python não encontrado."
        return 1
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/python_env_${timestamp}.tar.gz"
    
    log "Fazendo backup do ambiente Python..."
    
    tar -czf "$backup_file" -C "$HOME" cluster_env
    
    if [ $? -eq 0 ]; then
        log "Backup do ambiente Python criado com sucesso: $backup_file"
        log "Tamanho do backup: $(du -h "$backup_file" | cut -f1)"
    else
        error "Falha ao criar backup do ambiente Python."
        return 1
    fi
}

# Definir diretório de backup personalizado
set_custom_backup_dir() {
    echo -e "\n${YELLOW}Diretório de backup atual: $BACKUP_DIR${NC}"
    read -p "Digite o novo caminho para backups (ou Enter para manter atual): " new_backup_dir
    
    if [ -n "$new_backup_dir" ]; then
        BACKUP_DIR="$new_backup_dir"
        create_backup_dir
        log "Diretório de backup definido para: $BACKUP_DIR"
    else
        log "Mantendo diretório de backup atual: $BACKUP_DIR"
    fi
}

# Função para restaurar backup
restore_backup() {
    create_backup_dir
    
    echo -e "\n${BLUE}=== RESTAURAR BACKUP ===${NC}"
    
    # Listar backups disponíveis
    local backup_files=($(ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null))
    
    if [ ${#backup_files[@]} -eq 0 ]; then
        error "Nenhum arquivo de backup encontrado em $BACKUP_DIR"
        return 1
    fi
    
    echo "Backups disponíveis:"
    local i=1
    for backup_file in "${backup_files[@]}"; do
        echo "$i. $(basename "$backup_file") ($(du -h "$backup_file" | cut -f1))"
        ((i++))
    done
    
    read -p "Selecione o backup para restaurar [1-${#backup_files[@]}]: " backup_choice
    
    if ! [[ "$backup_choice" =~ ^[0-9]+$ ]] || [ "$backup_choice" -lt 1 ] || [ "$backup_choice" -gt ${#backup_files[@]} ]; then
        error "Seleção inválida."
        return 1
    fi
    
    local selected_backup="${backup_files[$((backup_choice-1))]}"
    
    echo -e "\n${YELLOW}AVISO: Esta operação substituirá os arquivos atuais.${NC}"
    read -p "Deseja continuar? (s/N): " confirm_restore
    
    if [[ ! "$confirm_restore" =~ ^[Ss]$ ]]; then
        log "Restauração cancelada."
        return 0
    fi
    
    log "Restaurando backup: $selected_backup"
    
    # Extrair backup
    tar -xzf "$selected_backup" -C "$HOME"
    
    if [ $? -eq 0 ]; then
        log "Backup restaurado com sucesso."
        
        # Verificar se é necessário reiniciar serviços
        if [[ "$selected_backup" == *config* ]] || [[ "$selected_backup" == *complete* ]]; then
            echo -e "\n${YELLOW}Backup de configuração restaurado. Reinicie os serviços para aplicar as mudanças.${NC}"
        fi
    else
        error "Falha ao restaurar backup."
        return 1
    fi
}

# Função para agendar backups automáticos
schedule_automatic_backups() {
    echo -e "\n${BLUE}=== AGENDAMENTO DE BACKUPS AUTOMÁTICOS ===${NC}"
    echo "1. Backup diário (2:00 AM)"
    echo "2. Backup semanal (Domingo 2:00 AM)"
    echo "3. Backup mensal (Dia 1, 2:00 AM)"
    echo "4. Remover agendamento"
    echo "5. Voltar"
    
    read -p "Selecione a frequência [1-5]: " schedule_choice
    
    case $schedule_choice in
        1)
            add_cron_job "0 2 * * *" "diário"
            ;;
        2)
            add_cron_job "0 2 * * 0" "semanal"
            ;;
        3)
            add_cron_job "0 2 1 * *" "mensal"
            ;;
        4)
            remove_cron_jobs
            ;;
        5)
            return
            ;;
        *)
            warn "Opção inválida."
            ;;
    esac
}

# Adicionar trabalho ao cron
add_cron_job() {
    local schedule="$1"
    local frequency="$2"
    
    # Obter o caminho completo do script
    local script_path=$(realpath "$0")
    
    # Adicionar ao crontab
    (crontab -l 2>/dev/null | grep -v "$script_path"; echo "$schedule $script_path --backup --auto") | crontab -
    
    if [ $? -eq 0 ]; then
        log "Backup $frequency agendado com sucesso."
    else
        error "Falha ao agendar backup $frequency."
    fi
}

# Remover trabalhos do cron
remove_cron_jobs() {
    # Obter o caminho completo do script
    local script_path=$(realpath "$0")
    
    # Remover do crontab
    crontab -l 2>/dev/null | grep -v "$script_path" | crontab -
    
    if [ $? -eq 0 ]; then
        log "Agendamentos de backup removidos."
    else
        error "Falha ao remover agendamentos."
    fi
}
📋 Parte 3: Funções de Instalação e Configuração
bash
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
                htop iotop iftop nvtop \
                nvidia-cuda-toolkit nvidia-container-toolkit  # Para GPU NVIDIA
            ;;
        manjaro)
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm curl git docker python python-pip python-virtualenv \
                msmtp mailutils openmpi lsof openssh wget \
                base-devel libx11 libxext libxrender libxtst freetype2 net-tools \
                htop iotop iftop nvtop \
                cuda cudnn  # Para GPU NVIDIA
            ;;
        centos|rhel|fedora)
            sudo yum update -y
            sudo yum install -y curl git docker python3 python3-pip python3-virtualenv \
                msmtp mailutils openmpi-devel lsof openssh-server \
                libX11-devel libXext-devel libXrender-devel libXtst-devel freetype-devel net-tools \
                htop iotop iftop nvtop \
                cuda cudnn  # Para GPU NVIDIA
            ;;
    esac
    
    # Inicializar e habilitar Docker
    if command_exists docker; then
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker $USER
        log "Docker configurado e iniciado."
    else
        error "Falha ao instalar Docker."
        return 1
    fi
    
    log "Dependências básicas instaladas com sucesso."
}

# Função para configurar ambiente Python
setup_python_env() {
    if [ ! -d "$CLUSTER_ENV" ]; then
        log "Criando ambiente virtual em $CLUSTER_ENV"
        python3 -m venv "$CLUSTER_ENV"
    else
        log "Ambiente virtual já existe, atualizando..."
    fi

    # Instalar dependências no ambiente virtual
    source "$CLUSTER_ENV/bin/activate"
    pip install --upgrade pip
    pip install "dask[complete]" distributed numpy pandas scipy mpi4py jupyterlab \
                requests dask-ml scikit-learn torch torchvision torchaudio transformers \
                matplotlib seaborn plotly opencv-python pillow flask fastapi uvicorn \
                sqlalchemy psycopg2-binary redis celery flower
    deactivate
    
    log "Ambiente Python configurado com sucesso."
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
    
    read -p "Deseja adicionar chaves de outras máquinas a esta? (s/N): " add_keys
    if [[ "$add_keys" =~ ^[Ss]$ ]]; then
        read -p "Cole a chave pública da outra máquina: " pub_key
        if [ ! -z "$pub_key" ]; then
            echo "$pub_key" >> ~/.ssh/authorized_keys
            chmod 600 ~/.ssh/authorized_keys
            log "Chave adicionada ao authorized_keys."
        fi
    fi
    
    log "SSH configurado com sucesso."
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
    
    log "Ollama instalado e configurado com sucesso."
}

# Função para configurar GPU para Ollama
configure_ollama_gpu() {
    log "Configurando GPU para Ollama..."
    
    # Criar diretório de configuração
    mkdir -p ~/.ollama
    
    # Detectar GPU e configurar apropriadamente
    if [ "$GPU_TYPE" = "nvidia" ]; then
        log "Configurando para GPU NVIDIA com CUDA..."
        cat > ~/.ollama/config.json << EOL
{
    "runners": {
        "nvidia": {
            "url": "https://github.com/ollama/ollama/blob/main/gpu/nvidia/runner.cu"
        }
    },
    "environment": {
        "OLLAMA_NUM_GPU_LAYERS": "$CUDA_LAYERS",
        "OLLAMA_MAX_LOADED_MODELS": "3",
        "OLLAMA_KEEP_ALIVE": "24h"
    }
}
EOL
    elif [ "$GPU_TYPE" = "amd" ]; then
        log "Configurando para GPU AMD com ROCm..."
        cat > ~/.ollama/config.json << EOL
{
    "runners": {
        "rocm": {
            "url": "https://github.com/ollama/ollama/blob/main/gpu/rocm/runner.cc"
        }
    },
    "environment": {
        "OLLAMA_NUM_GPU_LAYERS": "$ROCm_LAYERS",
        "OLLAMA_MAX_LOADED_MODELS": "2"
    }
}
EOL
    else
        log "Configurando para modo CPU-only..."
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
    log "Configuração de GPU concluída."
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

## 📋 Parte 4: Configuração do Servidor, Workers e Serviços
```bash
# Função para configurar servidor
setup_server() {
    log "Configurando servidor (scheduler)..."
    
    # Obter IP dinâmico
    IP=$(hostname -I | awk '{print $1}')
    log "IP desta máquina: $IP"
    
    # Criar script para iniciar scheduler
    cat > "$CLUSTER_SCRIPTS/start_scheduler.sh" << EOL
#!/bin/bash
source "$CLUSTER_ENV/bin/activate"
dask-scheduler --host 0.0.0.0 --port $DASK_SCHEDULER_PORT --dashboard --dashboard-address 0.0.0.0:$DASK_DASHBOARD_PORT
EOL
    
    chmod +x "$CLUSTER_SCRIPTS/start_scheduler.sh"
    
    # Iniciar scheduler
    pkill -f "dask-scheduler" || true
    nohup "$CLUSTER_SCRIPTS/start_scheduler.sh" > "$LOG_DIR/scheduler.log" 2>&1 &
    
    log "Scheduler iniciado. Dashboard disponível em: http://$IP:$DASK_DASHBOARD_PORT"
    
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
    cat > "$CLUSTER_SCRIPTS/start_worker.sh" << EOL
#!/bin/bash
source "$CLUSTER_ENV/bin/activate"
# Tentar conectar ao scheduler
while true; do
    if nc -z -w 5 $SERVER_IP $DASK_SCHEDULER_PORT; then
        echo "Conectando ao scheduler em $SERVER_IP:$DASK_SCHEDULER_PORT"
        dask-worker $SERVER_IP:$DASK_SCHEDULER_PORT --nworkers auto --nthreads 2 --name $MACHINE_NAME
        break
    else
        echo "Scheduler não disponível. Tentando novamente em 10 segundos..."
        sleep 10
    fi
done
EOL
    
    chmod +x "$CLUSTER_SCRIPTS/start_worker.sh"
    
    # Iniciar worker
    pkill -f "dask-worker" || true
    nohup "$CLUSTER_SCRIPTS/start_worker.sh" > "$LOG_DIR/worker.log" 2>&1 &
    
    log "Worker configurado para conectar ao scheduler: $SERVER_IP:$DASK_SCHEDULER_PORT"
}
# Função para configurar serviços
setup_services() {
    log "Configurando serviços adicionais..."
    
    # OpenWebUI
    if sudo docker ps -a --format '{{.Names}}' | grep -q '^open-webui$'; then
        log "OpenWebUI já está instalado."
    else
        sudo docker run -d --name open-webui -p $OPENWEBUI_PORT:8080 -v $HOME/open-webui:/app/data $OPENWEBUI_IMAGE
        log "OpenWebUI instalado. Acesse: http://$(hostname -I | awk '{print $1}'):$OPENWEBUI_PORT"
    fi
}
# Função para instalar IDEs
install_ides() {
    log "Instalando IDEs..."
    
    # Spyder
    if ! command_exists spyder; then
        source "$CLUSTER_ENV/bin/activate"
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
        sudo ufw allow $DASK_SCHEDULER_PORT/tcp  # Dask Scheduler
        sudo ufw allow $DASK_DASHBOARD_PORT/tcp  # Dask Dashboard
        sudo ufw allow $OPENWEBUI_PORT/tcp  # OpenWebUI
        sudo ufw allow $OLLAMA_PORT/tcp # Ollama API
        
        # Se for servidor, permite conexões de entrada
        if [ "$ROLE" = "server" ] || [ "$ROLE" = "both" ]; then
            sudo ufw allow from any to any port $OLLAMA_PORT proto tcp
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
```
## 📋 Parte 5: Funções de Status, Menu e Processamento de Argumentos
```bash
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
    if [ -d "$CLUSTER_ENV" ]; then
        echo "✓ Ambiente virtual existe"
    else
        echo "✗ Ambiente virtual não existe"
    fi
    
    # Verificar Ollama
    echo -e "\n${YELLOW}Ollama:${NC}"
    if curl -s http://localhost:$OLLAMA_PORT/api/tags > /dev/null; then
        echo "✓ API do Ollama está respondendo"
        echo "Modelos instalados:"
        ollama list
    else
        echo "✗ API do Ollama não está respondendo"
    fi
}
# Função para processar argumentos de linha de comando
process_arguments() {
    case "$1" in
        "--backup")
            if [ "$2" == "--auto" ]; then
                # Modo automático (usado pelo cron)
                create_backup_dir
                backup_complete
                exit $?
            else
                backup_data
                exit $?
            fi
            ;;
        "--restore")
            restore_backup
            exit $?
            ;;
        "--schedule")
            schedule_automatic_backups
            exit $?
            ;;
        "--update")
            update_system
            exit $?
            ;;
        "--status")
            show_status
            exit $?
            ;;
        "--help")
            show_help
            exit 0
            ;;
        *)
            # Nenhum argumento especial, continuar com menu normal
            ;;
    esac
}
# Função para mostrar ajuda
show_help() {
    echo -e "${BLUE}=== AJUDA - CLUSTER AI ===${NC}"
    echo "Uso: $0 [OPÇÃO]"
    echo ""
    echo "Opções:"
    echo "  --backup          Executar backup interativo"
    echo "  --backup --auto   Executar backup automático (para cron)"
    echo "  --restore         Restaurar backup"
    echo "  --schedule        Agendar backups automáticos"
    echo "  --update          Atualizar o sistema Cluster AI"
    echo "  --status          Mostrar status do sistema"
    echo "  --help            Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 --backup       # Backup interativo"
    echo "  $0 --restore      # Restaurar backup"
    echo "  $0 --schedule     # Agendar backups automáticos"
    echo "  $0 --status       # Mostrar status do cluster"
}
# Função para atualizar o sistema
update_system() {
    log "Iniciando atualização do Cluster AI..."
    
    # Atualizar dependências do sistema
    case $OS in
        ubuntu|debian)
            sudo apt update && sudo apt upgrade -y
            ;;
        manjaro)
            sudo pacman -Syu --noconfirm
            ;;
        centos|rhel|fedora)
            sudo yum update -y
            ;;
    esac
    
    # Atualizar ambiente Python
    if [ -d "$CLUSTER_ENV" ]; then
        source "$CLUSTER_ENV/bin/activate"
        pip install --upgrade pip
        pip install --upgrade "dask[complete]" distributed numpy pandas scipy
        deactivate
    fi
    
    # Atualizar Ollama
    if command_exists ollama; then
        curl -fsSL https://ollama.com/install.sh | sh
    fi
    
    # Atualizar OpenWebUI
    sudo docker pull $OPENWEBUI_IMAGE
    sudo docker stop open-webui || true
    sudo docker rm open-webui || true
    sudo docker run -d --name open-webui -p $OPENWEBUI_PORT:8080 -v $HOME/open-webui:/app/data $OPENWEBUI_IMAGE
    
    log "Atualização concluída."
}
# Função para menu de backup
backup_menu() {
    while true; do
        echo -e "\n${BLUE}=== MENU DE BACKUP E RESTAURAÇÃO ===${NC}"
        echo "1. Fazer backup"
        echo "2. Restaurar backup"
        echo "3. Agendar backups automáticos"
        echo "4. Definir diretório de backup"
        echo "5. Voltar"
        
        read -p "Selecione uma opção [1-5]: " backup_choice
        
        case $backup_choice in
            1) backup_data ;;
            2) restore_backup ;;
            3) schedule_automatic_backups ;;
            4) set_custom_backup_dir ;;
            5) break ;;
            *) warn "Opção inválida. Tente novamente." ;;
        esac
    done
}
# Função para menu principal
main_menu() {
    # Processar argumentos de linha de comando
    process_arguments "$1" "$2"
    
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
        echo "9. Atualizar sistema"
        echo "10. Sair"
        
        read -p "Selecione uma opção [1-10]: " choice
        
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
            9)
                update_system
                ;;
            10) break ;;
            *) warn "Opção inválida. Tente novamente." ;;
        esac
    done
}
# Função principal
main() {
    show_banner
    check_sudo
    detect_os
    create_directories
    
    # Executar menu principal
    main_menu "$1" "$2"
    
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
    echo "Scripts de gerenciamento: $CLUSTER_SCRIPTS/"
    echo "Diretório de backup: $BACKUP_DIR"
    echo "Arquivo de configuração: ~/.cluster_role"
    echo "Logs: $LOG_DIR/"
    echo -e "\n${GREEN}=== URLs DE ACESSO ===${NC}"
    echo "OpenWebUI: http://$CURRENT_IP:$OPENWEBUI_PORT"
    echo "Dask Dashboard: http://$CURRENT_IP:$DASK_DASHBOARD_PORT"
    echo "Ollama API: http://$CURRENT_IP:$OLLAMA_PORT"
}
# Executar função principal
main "$1" "$2"
```
Agora, o script completo está dividido em partes. Para usar, basta juntar todas as partes em um único arquivo, por exemplo `install_cluster_ai.sh`, e torná-lo executável com `chmod +x install_cluster_ai.sh`.
Este script agora inclui:
- Instalação automatizada para Ubuntu/Debian, Manjaro e CentOS/RHEL
- Configuração de GPU automática (NVIDIA, AMD ou CPU)
- Sistema de backup e restauração
- Agendamento de backups
- Atualização do sistema
- Menu interativo
- Suporte a múltiplos papéis (servidor, workstation, worker)
Para executar, use:
```bash
./install_cluster_ai.sh
```
Ou para opções específicas:
```bash
./install_cluster_ai.sh --backup
./install_cluster_ai.sh --status
./install_cluster_ai.sh --update
```
Lembre-se de que o script requer privilégios de sudo para instalar pacotes do sistema.
