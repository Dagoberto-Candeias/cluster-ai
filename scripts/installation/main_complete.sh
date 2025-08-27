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
CURRENT_IP=$(hostname -I | awk '{print $1}')
BACKUP_DIR="$HOME/cluster_backups"
OLLAMA_MODELS=("llama3.1:8b" "llama3:8b" "mixtral:8x7b" "deepseek-coder" "mistral" "llava" "phi3" "gemma2:9b" "codellama")
OLLAMA_HOST="0.0.0.0"
OLLAMA_PORT="11434"

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

# Função para limpar ambiente completamente
clean_environment() {
    echo -e "\n${RED}=== LIMPEZA COMPLETA DO AMBIENTE ===${NC}"
    echo -e "${YELLOW}AVISO: Esta operação removerá TODOS os dados do cluster!${NC}"
    read -p "Tem certeza que deseja continuar? (s/n): " confirm_clean
    
    if [ "$confirm_clean" != "s" ]; then
        log "Limpeza cancelada."
        return 0
    fi
    
    log "Iniciando limpeza completa do ambiente..."
    
    # Parar todos os serviços
    pkill -f "dask-scheduler" || true
    pkill -f "dask-worker" || true
    pkill -f "ollama" || true
    
    # Remover containers Docker
    sudo docker rm -f open-webui 2>/dev/null || true
    
    # Remover arquivos e diretórios
    rm -rf ~/.cluster_role
    rm -rf ~/cluster_scripts
    rm -rf ~/.ollama
    rm -rf ~/open-webui
    rm -rf ~/cluster_env
    rm -rf ~/cluster_backups
    rm -rf ~/scheduler.log
    rm -rf ~/worker.log
    
    # Remover configurações específicas
    rm -rf /etc/systemd/system/ollama.service.d/
    
    log "Ambiente completamente limpo. Todos os dados foram removidos."
}

# Função para resetar configurações
reset_configuration() {
    echo -e "\n${YELLOW}=== RESET DE CONFIGURAÇÕES ===${NC}"
    echo "1. Reset completo (limpar tudo e reinstalar)"
    echo "2. Reset apenas das configurações (manter dados)"
    echo "3. Voltar"
    
    read -p "Selecione o tipo de reset [1-3]: " reset_choice
    
    case $reset_choice in
        1)
            clean_environment
            log "Ambiente resetado. Execute a instalação novamente."
            exit 0
            ;;
        2)
            rm -rf ~/.cluster_role
            rm -rf ~/cluster_scripts/*.sh
            log "Configurações resetadas. Papel da máquina será redefinido."
            ;;
        3)
            return
            ;;
        *)
            warn "Opção inválida."
            ;;
    esac
}

# Função para reconfigurar ambiente
reconfigure_environment() {
    echo -e "\n${BLUE}=== RECONFIGURAÇÃO DO AMBIENTE ===${NC}"
    echo "1. Alterar papel da máquina"
    echo "2. Reconfigurar serviços existentes"
    echo "3. Reinstalar dependências"
    echo "4. Voltar"
    
    read -p "Selecione a opção de reconfiguração [1-4]: " reconf_choice
    
    case $reconf_choice in
        1)
            define_role
            setup_based_on_role
            ;;
        2)
            pkill -f "dask-scheduler" || true
            pkill -f "dask-worker" || true
            pkill -f "ollama" || true
            setup_based_on_role
            ;;
        3)
            install_dependencies
            setup_python_env
            ;;
        4)
            return
            ;;
        *)
            warn "Opção inválida."
            ;;
    esac
}

# Função para reaproveitar configuração existente
reuse_existing_config() {
    echo -e "\n${GREEN}=== REAPROVEITAR CONFIGURAÇÃO EXISTENTE ===${NC}"
    
    if [ -f ~/.cluster_role ]; then
        source ~/.cluster_role
        log "Configuração existente detectada:"
        echo "Papel: $ROLE"
        echo "Servidor: $SERVER_IP"
        echo "Máquina: $MACHINE_NAME"
        
        read -p "Deseja reaproveitar esta configuração? (s/n): " reuse_choice
        
        if [ "$reuse_choice" = "s" ]; then
            log "Configuração existente será reaproveitada."
            return 0
        else
            log "Configuração existente será ignorada."
            rm -f ~/.cluster_role
            return 1
        fi
    else
        log "Nenhuma configuração existente encontrada."
        return 1
    fi
}

# Função para menu inicial de gerenciamento
initial_management_menu() {
    echo -e "\n${BLUE}=== GERENCIAMENTO DO CLUSTER AI ===${NC}"
    echo "1. Instalação/Configuração Normal"
    echo "2. Resetar/Reinstalar Tudo"
    echo "3. Reconfigurar Ambiente Existente"
    echo "4. Reaproveitar Configuração Existente"
    echo "5. Limpar Tudo (Remover Completamente)"
    echo "6. Sair"
    
    read -p "Selecione uma opção [1-6]: " initial_choice
    
    case $initial_choice in
        1)
            # Continua com instalação normal
            ;;
        2)
            reset_configuration
            exit 0
            ;;
        3)
            reconfigure_environment
            exit 0
            ;;
        4)
            if reuse_existing_config; then
                log "Continuando com configuração reaproveitada..."
            else
                log "Iniciando configuração do zero..."
                define_role
            fi
            ;;
        5)
            clean_environment
            exit 0
            ;;
        6)
            exit 0
            ;;
        *)
            warn "Opção inválida. Continuando com instalação normal."
            ;;
    esac
}

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
        "$HOME/.cluster_role"
        "$HOME/cluster_scripts"
        "$HOME/.ollama"
        "$HOME/open-webui"
        "$HOME/.ssh"
        "$HOME/cluster_env"
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
        "$HOME/.cluster_role"
        "$HOME/cluster_scripts"
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
    if [ ! -d "$HOME/cluster_env" ]; then
        log "Criando ambiente virtual em ~/cluster_env"
        python3 -m venv ~/cluster_env
    else
        log "Ambiente virtual já existe."
    fi

    # Instalar dependências no ambiente virtual
    source ~/cluster_env/bin/activate
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
        log "GPU NVIDIA detectada, configurando para uso
