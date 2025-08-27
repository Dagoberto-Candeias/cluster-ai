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

# [O restante do script permanece igual...]
# As funções existentes (backup_data, restore_backup, define_role, install_dependencies, etc.)
# devem ser mantidas exatamente como estão no script original

# Função principal modificada
main_menu_modified() {
    # Mostrar menu inicial de gerenciamento
    initial_management_menu
    
    # Processar argumentos de linha de comando
    process_arguments "$1" "$2"
    
    # Verificar se já existe configuração
    if ! load_config; then
        info "Nenhuma configuração encontrada. Definindo papel da máquina..."
        define_role
    fi
    
    # [O restante do menu principal permanece igual...]
}

# Criar diretório para scripts
mkdir -p ~/cluster_scripts

# Executar menu principal modificado
main_menu_modified "$1" "$2"

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
