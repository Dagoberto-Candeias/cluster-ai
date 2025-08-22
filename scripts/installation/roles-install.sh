#!/bin/bash
set -e

echo "=== Instalador Universal Cluster AI - Com Backup ==="

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

# [As funções restantes permanecem as mesmas: install_dependencies, setup_python_env, etc.]
# [...] (O resto do script permanece igual, apenas adicionamos as funções de backup acima)

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

# Criar diretório para scripts
mkdir -p ~/cluster_scripts

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
echo "Scripts de gerenciamento: ~/cluster_scripts/"
echo "Diretório de backup: $BACKUP_DIR"
echo "Arquivo de configuração: ~/.cluster_role"