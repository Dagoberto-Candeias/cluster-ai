#!/bin/bash
# Instalador Unificado - Cluster AI
# Versão: 1.0 - Instalação modular e unificada

set -e  # Saída em caso de erro

# ==================== CONFIGURAÇÃO INICIAL ====================

# Carregar funções comuns
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/scripts/lib/common.sh"
INSTALL_FUNCTIONS="${SCRIPT_DIR}/scripts/lib/install_functions.sh"

if [ ! -f "$COMMON_SCRIPT" ]; then
    echo "ERRO: Script de funções comuns não encontrado: $COMMON_SCRIPT"
    echo "Execute este script a partir do diretório raiz do projeto"
    exit 1
fi

source "$COMMON_SCRIPT"

if [ ! -f "$INSTALL_FUNCTIONS" ]; then
    error "Script de funções de instalação não encontrado: $INSTALL_FUNCTIONS"
    exit 1
fi

source "$INSTALL_FUNCTIONS"

# Configurações
PROJECT_ROOT="$(pwd)"
CONFIG_FILE="${PROJECT_ROOT}/cluster.conf"
LOG_FILE="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"

# ==================== FUNÇÕES DE INSTALAÇÃO ====================

# Função para mostrar banner
show_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   CLUSTER AI - INSTALADOR                   ║"
    echo "║                Sistema de IA Local e Distribuído            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "Diretório do projeto: $PROJECT_ROOT"
    echo "Log da instalação: $LOG_FILE"
    echo ""
}

# Função para verificar requisitos
check_requirements() {
    section "Verificando Requisitos do Sistema"
    
    # Verificar se não é root
    check_root
    
    # Verificar sistema operacional
    local os=$(detect_os)
    info "Sistema operacional detectado: $os"
    
    # Verificar comandos essenciais
    check_command "curl" "cURL" "sudo apt install curl / sudo yum install curl"
    check_command "git" "Git" "sudo apt install git / sudo yum install git"
    check_command "python3" "Python 3" "sudo apt install python3 / sudo yum install python3"
    check_command "pip" "PIP" "sudo apt install python3-pip / sudo yum install python3-pip"
    
    # Verificar recursos do sistema
    local mem_total=$(free -h | awk '/Mem:/ {print $2}')
    local disk_free=$(df -h . | awk 'NR==2 {print $4}')
    info "Memória total: $mem_total"
    info "Espaço livre em disco: $disk_free"
    
    # Verificações mínimas
    if [ "$(echo "$mem_total" | sed 's/G//')" -lt 4 ]; then
        warn "Memória RAM baixa (mínimo recomendado: 8GB)"
    fi
    
    if [ "$(echo "$disk_free" | sed 's/G//')" -lt 20 ]; then
        warn "Espaço em disco baixo (mínimo recomendado: 50GB)"
    fi
}

# Função para configurar ambiente
setup_environment() {
    section "Configurando Ambiente"
    
    # Criar arquivo de configuração se não existir
    if [ ! -f "$CONFIG_FILE" ]; then
        info "Criando arquivo de configuração..."
        cp "${PROJECT_ROOT}/cluster.conf.example" "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"
        success "Arquivo de configuração criado: $CONFIG_FILE"
    else
        info "Arquivo de configuração já existe: $CONFIG_FILE"
    fi
    
    # Carregar configuração
    if load_config; then
        success "Configuração carregada com sucesso"
    else
        warn "Configuração não pôde ser carregada, usando padrões"
    fi
    
    # Criar diretórios essenciais
    safe_mkdir "$LOG_DIR"
    safe_mkdir "$BACKUP_DIR"
    safe_mkdir "${PROJECT_ROOT}/scripts/runtime"
}

# Função para menu de instalação
show_install_menu() {
    section "Menu de Instalação"
    
    echo "📋 OPÇÕES DISPONÍVEIS:"
    echo ""
    echo "1. Instalação Completa (Recomendado)"
    echo "   - Todas as dependências + Ollama + Dask + OpenWebUI"
    echo ""
    echo "2. Instalação por Componentes"
    echo "   - Escolher quais componentes instalar"
    echo ""
    echo "3. Apenas Dependências do Sistema"
    echo "   - Instalar apenas pacotes do sistema"
    echo ""
    echo "4. Apenas Ambiente Python"
    echo "   - Configurar apenas ambiente virtual Python"
    echo ""
    echo "5. Configurar Papel do Cluster"
    echo "   - Definir função desta máquina no cluster"
    echo ""
    echo "6. Verificar Sistema"
    echo "   - Executar verificações de saúde do sistema"
    echo ""
    echo "7. Sair"
    echo ""
}

# Função para instalação completa
install_complete() {
    section "Instalação Completa"
    
    info "Iniciando instalação completa do Cluster AI..."
    
    # Instalar dependências do sistema
    install_system_dependencies
    
    # Configurar ambiente Python
    setup_python_environment
    
    # Instalar e configurar Ollama
    setup_ollama
    
    # Configurar Docker
    setup_docker
    
    # Configurar cluster baseado no papel
    setup_cluster_role
    
    # Configurar serviços
    setup_services
    
    # Configurar firewall
    setup_firewall
    
    # Verificar instalação
    validate_installation
    
    success "Instalação completa concluída!"
}

# Função para instalar dependências do sistema
install_system_dependencies() {
    subsection "Instalando Dependências do Sistema"
    
    local os=$(detect_os)
    
    case $os in
        debian)
            run_sudo "apt update && apt upgrade -y" "Atualizando sistema"
            run_sudo "apt install -y curl git docker.io docker-compose-plugin python3-venv python3-pip python3-full msmtp msmtp-mta mailutils openmpi-bin libopenmpi-dev ca-certificates gnupg lsof openssh-server software-properties-common apt-transport-https net-tools" "Instalando pacotes Debian/Ubuntu"
            ;;
        arch)
            run_sudo "pacman -Syu --noconfirm" "Atualizando sistema"
            run_sudo "pacman -S --noconfirm curl git docker python python-pip python-virtualenv msmtp mailutils openmpi lsof openssh wget base-devel libx11 libxext libxrender libxtst freetype2 net-tools" "Instalando pacotes Arch/Manjaro"
            ;;
        rhel)
            run_sudo "yum update -y" "Atualizando sistema"
            run_sudo "yum install -y curl git docker python3 python3-pip python3-virtualenv msmtp mailutils openmpi-devel lsof openssh-server libX11-devel libXext-devel libXrender-devel libXtst-devel freetype-devel net-tools" "Instalando pacotes RHEL/CentOS/Fedora"
            ;;
        *)
            error "Sistema operacional não suportado: $os"
            return 1
            ;;
    esac
    
    # Configurar e iniciar Docker
    if command_exists docker; then
        run_sudo "systemctl enable docker" "Habilitando Docker"
        run_sudo "systemctl start docker" "Iniciando Docker"
        run_sudo "usermod -aG docker $USER" "Adicionando usuário ao grupo Docker"
        success "Docker configurado e iniciado"
    fi
    
    success "Dependências do sistema instaladas"
}

# Função para configurar ambiente Python
setup_python_environment() {
    subsection "Configurando Ambiente Python"
    
    load_config
    
    if [ ! -d "$VENV_DIR" ]; then
        run_command "python3 -m venv \"$VENV_DIR\"" "Criando ambiente virtual"
        success "Ambiente virtual criado: $VENV_DIR"
    else
        info "Ambiente virtual já existe: $VENV_DIR"
    fi
    
    # Instalar dependências Python
    run_command "source \"$VENV_DIR/bin/activate\" && pip install --upgrade pip" "Atualizando pip"
    run_command "source \"$VENV_DIR/bin/activate\" && pip install \"dask[complete]\" distributed numpy pandas scipy mpi4py jupyterlab requests dask-ml scikit-learn torch torchvision torchaudio transformers" "Instalando dependências Python"
    
    success "Ambiente Python configurado"
}

# Função para validar instalação (placeholder)
validate_installation() {
    subsection "Validando Instalação"
    info "Função validate_installation será implementada em scripts/validation/"
    # Esta função será movida para scripts de validação
}

# Função para processar escolha do menu
process_menu_choice() {
    local choice="$1"
    
    case $choice in
        1)
            install_complete
            ;;
        2)
            info "Instalação por componentes será implementada"
            ;;
        3)
            install_system_dependencies
            ;;
        4)
            setup_python_environment
            ;;
        5)
            setup_cluster_role
            ;;
        6)
            info "Verificação do sistema será implementada"
            ;;
        7)
            info "Saindo..."
            exit 0
            ;;
        *)
            warn "Opção inválida"
            return 1
            ;;
    esac
}

# ==================== FUNÇÃO PRINCIPAL ====================

main() {
    # Configurar log
    exec > >(tee -a "$LOG_FILE") 2>&1
    
    # Mostrar banner
    show_banner
    
    # Verificar requisitos
    check_requirements
    
    # Configurar ambiente
    setup_environment
    
    # Loop principal do menu
    while true; do
        show_install_menu
        read -p "Selecione uma opção [1-7]: " choice
        
        if process_menu_choice "$choice"; then
            if confirm "Deseja voltar ao menu principal?" "n"; then
                continue
            else
                break
            fi
        fi
    done
    
    section "Instalação Concluída"
    success "Cluster AI configurado com sucesso!"
    echo ""
    info "Próximos passos:"
    echo "  - Execute './manager.sh' para gerenciar o cluster"
    echo "  - Consulte 'docs/guides/usage.md' para começar"
    echo "  - Execute './run_tests.sh' para validar a instalação"
    echo ""
    info "Log completo disponível em: $LOG_FILE"
}

# Executar função principal
main "$@"
