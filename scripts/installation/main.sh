#!/bin/bash
set -e

echo "=== Instalador Universal Cluster AI - Com Backup e Ollama Otimizado ==="

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
PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
CURRENT_IP=$(hostname -I | awk '{print $1}')
BACKUP_DIR="$PROJECT_ROOT/backups"
CONFIG_FILE="$PROJECT_ROOT/.cluster_config"
VENV_DIR="$PROJECT_ROOT/.venv"
RUNTIME_SCRIPTS_DIR="$PROJECT_ROOT/scripts/runtime"
OLLAMA_MODELS=("llama3.1:8b" "llama3:8b" "mixtral:8x7b" "deepseek-coder" "mistral" "llava" "phi3" "gemma2:9b" "codellama")
OLLAMA_HOST="0.0.0.0"
OLLAMA_PORT="11434"
LOG_DIR="$PROJECT_ROOT/logs"
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

# Função para criar diretório de backups
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        # O diretório de backup fica fora do diretório principal do projeto para não ser incluído em si mesmo.
        BACKUP_DIR="$PROJECT_ROOT/../cluster_ai_backups"
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
    echo "5. Definir diretório de backup personalizado"
    echo "6. Voltar"
    
    read -p "Selecione o tipo de backup [1-6]: " backup_choice
    
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
            set_custom_backup_dir
            ;;
        6)
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
        "$CONFIG_FILE"
        "$RUNTIME_SCRIPTS_DIR"
        "$HOME/.ollama"
        "$HOME/open-webui"
        "$HOME/.ssh"
        "$VENV_DIR"
        "$HOME/.msmtprc"
        "$HOME/.gmail_pass.gpg"
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
        "$CONFIG_FILE"
        "$RUNTIME_SCRIPTS_DIR"
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
    read -p "Deseja continuar? (s/n): " confirm_restore
    
    if [ "$confirm_restore" != "s" ]; then
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
    echo "1. Backup diário"
    echo "2. Backup semanal"
    echo "3. Backup mensal"
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
    echo -e "${BLUE}=== AJUDA - CLUSTER AI BACKUP ===${NC}"
    echo "Uso: $0 [OPÇÃO]"
    echo ""
    echo "Opções:"
    echo "  --backup          Executar backup interativo"
    echo "  --backup --auto   Executar backup automático (para cron)"
    echo "  --restore         Restaurar backup"
    echo "  --schedule        Agendar backups automáticos"
    echo "  --help            Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 --backup       # Backup interativo"
    echo "  $0 --restore      # Restaurar backup"
    echo "  $0 --schedule     # Agendar backups automáticos"
}

# Função para definir o papel da máquina
define_role() {
    echo -e "\n${BLUE}=== DEFINIÇÃO DO PAPEL DESTA MÁQUINA ===${NC}"
    echo "1. Servidor Principal (Scheduler + Serviços + Worker)"
    echo "2. Estação de Trabalho (Worker + IDEs)"
    echo "3. Apenas Worker (Processamento)"
    echo "4. Transformar Estação em Servidor"
    echo "5. Mostrar ajuda sobre os papéis"
    echo "6. Cancelar"
    
    read -p "Selecione o papel desta máquina [1-6]: " role_choice
    
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
    echo "ROLE=$ROLE" > "$CONFIG_FILE"
    echo "SERVER_IP=$SERVER_IP" >> "$CONFIG_FILE"
    echo "MACHINE_NAME=$MACHINE_NAME" >> "$CONFIG_FILE"
    echo "CURRENT_IP=$CURRENT_IP" >> "$CONFIG_FILE"
    echo "BACKUP_DIR=$BACKUP_DIR" >> "$CONFIG_FILE"
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
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
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
                nvidia-cuda-toolkit nvidia-container-toolkit  # Para GPU NVIDIA
            ;;
        manjaro)
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm curl git docker python python-pip python-virtualenv \
                msmtp mailutils openmpi lsof openssh wget \
                base-devel libx11 libxext libxrender libxtst freetype2 net-tools \
                cuda cudnn  # Para GPU NVIDIA
            ;;
        centos|rhel|fedora)
            sudo yum update -y
            sudo yum install -y curl git docker python3 python3-pip python3-virtualenv \
                msmtp mailutils openmpi-devel lsof openssh-server \
                libX11-devel libXext-devel libXrender-devel libXtst-devel freetype-devel net-tools \
                cuda cudnn  # Para GPU NVIDIA
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
    if [ ! -d "$VENV_DIR" ]; then
        log "Criando ambiente virtual em $VENV_DIR"
        python3 -m venv "$VENV_DIR"
    else
        log "Ambiente virtual já existe."
    fi

    # Instalar dependências no ambiente virtual
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip
    pip install "dask[complete]" distributed numpy pandas scipy mpi4py jupyterlab requests dask-ml scikit-learn torch torchvision torchaudio transformers
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
    cat > "$RUNTIME_SCRIPTS_DIR/start_scheduler.sh" << EOL
#!/bin/bash
source "$VENV_DIR/bin/activate"
dask-scheduler --host 0.0.0.0 --port 8786 --dashboard --dashboard-address 0.0.0.0:8787
EOL
    
    chmod +x "$RUNTIME_SCRIPTS_DIR/start_scheduler.sh"
    
    # Iniciar scheduler
    pkill -f "dask-scheduler" || true
    nohup "$RUNTIME_SCRIPTS_DIR/start_scheduler.sh" > "$LOG_DIR/scheduler.log" 2>&1 &
    
    log "Scheduler iniciado. Dashboard disponível em: http://$IP:8787"
    
    # Configurar serviços adicionais
    setup_services
}

# Função para configurar worker
setup_worker() {
    log "Configurando worker..."
    
    if [ -z "$SERVER_IP" ]; then
        read -p "Digite o IP do servidor principal: " SERVER_IP
        echo "SERVER_IP=$SERVER_IP" >> "$CONFIG_FILE"
    fi
    
    # Se SERVER_IP for "localhost", usar o IP atual
    if [ "$SERVER_IP" = "localhost" ]; then
        SERVER_IP=$CURRENT_IP
    fi
    
    # Criar script para iniciar worker
    cat > "$RUNTIME_SCRIPTS_DIR/start_worker.sh" << EOL
#!/bin/bash
source "$VENV_DIR/bin/activate"

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
    
    chmod +x "$RUNTIME_SCRIPTS_DIR/start_worker.sh"
    
    # Iniciar worker
    pkill -f "dask-worker" || true
    nohup "$RUNTIME_SCRIPTS_DIR/start_worker.sh" > "$LOG_DIR/worker.log" 2>&1 &
    
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
        source "$VENV_DIR/bin/activate"
        pip install spyder
        deactivate
        log "Spyder instalado."
    else
        log "Spyder já está instalado."
    fi
    
    # VSCode com instalação otimizada
    log "Instalando VSCode com extensões essenciais..."
    if [ -f "scripts/installation/setup_vscode.sh" ]; then
        chmod +x scripts/installation/setup_vscode.sh
        ./scripts/installation/setup_vscode.sh
    else
        warn "Script de instalação do VSCode não encontrado. Instalando versão básica..."
        install_vscode_basic
    fi
    
    # PyCharm (opcional)
    install_pycharm_optional
}

# Função para instalação básica do VSCode (fallback)
install_vscode_basic() {
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
                if command_exists dnf; then
                    sudo dnf install -y code
                else
                    sudo yum install -y code
                fi
                ;;
        esac
        
        if command_exists code; then
            log "VSCode instalado (versão básica)."
            warn "Execute 'scripts/installation/setup_vscode.sh' para instalar extensões essenciais."
        else
            error "Falha ao instalar VSCode."
        fi
    else
        log "VSCode já está instalado."
    fi
}

# Função para instalação opcional do PyCharm
install_pycharm_optional() {
    read -p "Deseja instalar o PyCharm Community? (s/N): " install_pycharm
    if [[ "$install_pycharm" =~ ^[Ss]$ ]]; then
        if [ ! -d "/opt/pycharm" ] && [ ! -d "$HOME/pycharm" ]; then
            log "Instalando PyCharm Community Edition..."
            
            # URL mais recente do PyCharm
            PYCHARM_URL="https://download.jetbrains.com/python/pycharm-community-2024.1.tar.gz"
            
            # Tentar baixar
            if wget -O /tmp/pycharm.tar.gz "$PYCHARM_URL"; then
                # Extrair para home do usuário (não requer sudo)
                tar -xzf /tmp/pycharm.tar.gz -C "$HOME/"
                mv "$HOME"/pycharm-* "$HOME/pycharm"
                
                # Criar atalho
                cat > ~/.local/share/applications/pycharm-cluster.desktop << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=PyCharm (Cluster AI)
Exec=$HOME/pycharm/bin/pycharm.sh
Icon=$HOME/pycharm/bin/pycharm.png
Comment=PyCharm IDE for Cluster AI development
Categories=Development;IDE;
Terminal=false
EOL
                
                # Tornar executável
                chmod +x ~/.local/share/applications/pycharm-cluster.desktop
                chmod +x "$HOME/pycharm/bin/pycharm.sh"
                
                log "PyCharm instalado em: $HOME/pycharm"
                log "Atalho criado no menu de aplicações"
            else
                warn "Falha ao baixar PyCharm. Você pode instalá-lo manualmente depois."
            fi
        else
            log "PyCharm já está instalado."
        fi
    else
        log "Instalação do PyCharm pulada."
    fi
}

# Função para converter estação em servidor
convert_to_server() {
    warn "Transformando esta estação em servidor..."
    ROLE="server"
    SERVER_IP="localhost"
    echo "ROLE=server" > "$CONFIG_FILE"
    echo "SERVER_IP=localhost" >> "$CONFIG_FILE"
    echo "MACHINE_NAME=$MACHINE_NAME" >> "$CONFIG_FILE"
    echo "CURRENT_IP=$CURRENT_IP" >> "$CONFIG_FILE"
    
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

# Função para verificar e instalar modelos Ollama
check_and_install_models() {
    echo -e "\n${BLUE}=== VERIFICAÇÃO DE MODELOS OLLAMA ===${NC}"
    ./scripts/utils/check_models.sh
}

# Verificar recursos apenas se solicitado ou durante a instalação
# (removida a execução automática para não interferir com o menu)

# Função principal de configuração
setup_based_on_role() {
    check_and_install_models
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
    if [ -d "$VENV_DIR" ]; then
        echo "✓ Ambiente virtual existe em $VENV_DIR"
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
mkdir -p "$RUNTIME_SCRIPTS_DIR"
# Criar diretório para logs
mkdir -p "$LOG_DIR"
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
echo "Scripts de gerenciamento: $RUNTIME_SCRIPTS_DIR"
echo "Diretório de backup: $BACKUP_DIR"
echo "Arquivo de configuração: $CONFIG_FILE"