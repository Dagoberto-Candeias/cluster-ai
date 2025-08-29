#!/bin/bash
# Instalador Universal Cluster AI - Ambiente de Desenvolvimento Completo
# Funciona em qualquer distribuição Linux: Ubuntu, Debian, Manjaro, Arch, CentOS, RHEL, Fedora

set -e

echo "=== INSTALADOR UNIVERSAL CLUSTER AI ==="
echo "Preparando ambiente de desenvolvimento completo..."
echo "Distribuição: $(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1)"
echo ""

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
}

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detectar distribuição
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif command_exists lsb_release; then
        OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        OS_VERSION=$(lsb_release -sr)
    else
        error "Não foi possível detectar o sistema operacional."
        exit 1
    fi
    
    # Normalizar nomes mas manter debian como distinto
    case $OS in
        ubuntu)
            OS="ubuntu"
            ;;
        debian)
            OS="debian"
            ;;
        manjaro|arch)
            OS="manjaro" 
            ;;
        centos|rhel|fedora)
            OS="centos"
            ;;
        *)
            warn "Distribuição não totalmente suportada: $OS"
            warn "Tentando modo compatível..."
            ;;
    esac
    
    log "Sistema detectado: $OS $OS_VERSION"
}

# Instalar dependências básicas universais
install_dependencies() {
    local setup_script="scripts/installation/setup_dependencies.sh"

    if [ -f "$setup_script" ]; then
        log "Executando script de configuração de dependências: $setup_script"
        # Exporta a variável OS para que o script filho possa usá-la
        export OS
        bash "$setup_script"
    else
        warn "Script de setup de dependências '$setup_script' não encontrado. Pulando esta etapa."
    fi
}

# Configurar ambiente Python universal
setup_python_environment() {
    local setup_script="scripts/installation/setup_python_env.sh"

    if [ -f "$setup_script" ]; then
        log "Executando script de configuração do ambiente Python: $setup_script"
        bash "$setup_script"
    else
        warn "Script de setup do Python '$setup_script' não encontrado. Pulando esta etapa."
    fi
}

# Instala e configura o serviço Ollama
install_ollama_service() {
    local setup_script="scripts/installation/setup_ollama.sh"

    if [ -f "$setup_script" ]; then
        log "Executando script de configuração do Ollama: $setup_script"
        bash "$setup_script"
    else
        warn "Script de setup do Ollama '$setup_script' não encontrado. Pulando esta etapa."
    fi
}

# Menu de instalação
show_menu() {
    echo -e "\n${BLUE}=== MENU DE INSTALAÇÃO UNIVERSAL ===${NC}"
    echo "1. Instalação Completa (Recomendado)"
    echo "2. Apenas Dependências Básicas"
    echo "3. Apenas Ambiente Python"
    echo "4. Apenas Ollama e Modelos de IA"
    echo "5. Apenas IDEs e Ferramentas Dev"
    echo "6. Configurar Papel do Cluster"
    echo "7. Sair"
    
    read -p "Selecione uma opção [1-7]: " choice
    
    case $choice in
        1)
            install_complete
            ;;
        2)
            install_dependencies
            ;;
        3)
            setup_python_environment
            ;;
        4)
            install_ollama_service
            ;;
        5)
            install_development_tools
            ;;
        6)
            configure_cluster_role
            ;;
        7)
            exit 0
            ;;
        *)
            warn "Opção inválida."
            show_menu
            ;;
    esac
}

# Instalação completa
install_complete() {
    log "Iniciando instalação completa..."
    install_dependencies
    setup_python_environment
    install_ollama_service
    install_development_tools
    
    echo -e "\n${GREEN}✅ INSTALAÇÃO COMPLETA CONCLUÍDA!${NC}"
    show_post_install_info
}

# Instala as ferramentas de desenvolvimento, orquestrando as instalações individuais.
install_development_tools() {
    log "Iniciando instalação das ferramentas de desenvolvimento..."
    local setup_script="scripts/development/setup_vscode.sh"

    if [ -f "$setup_script" ]; then
        log "Executando script de configuração do ambiente de desenvolvimento: $setup_script"
        # A variável $OS é detectada no início do install_universal.sh e estará disponível para o script filho.
        bash "$setup_script"
    else
        warn "Script de setup de desenvolvimento '$setup_script' não encontrado. Pulando esta etapa."
    fi

    install_spyder

}

# Instala a IDE Spyder chamando seu script de setup dedicado.
install_spyder() {
    local setup_script="scripts/development/setup_spyder.sh"

    if [ -f "$setup_script" ]; then
        log "Executando script de configuração do Spyder: $setup_script"
        bash "$setup_script"
    else
        warn "Script de setup do Spyder '$setup_script' não encontrado. Pulando esta etapa."
    fi
}

# Configurar papel do cluster
configure_cluster_role() {
    log "Configurando papel do cluster..."

    local setup_script="scripts/cluster/setup_cluster_role.sh"
    if [ -f "$setup_script" ]; then
        log "Executando script de configuração de papel do cluster: $setup_script"
        bash "$setup_script"
    else
        warn "Script de configuração de papel '$setup_script' não encontrado. Pulando esta etapa."
    fi
}

# Informações pós-instalação
show_post_install_info() {
    echo -e "\n${BLUE}=== PRÓXIMOS PASSOS ===${NC}"
    echo -e "${GREEN}1. Configure o papel do cluster:${NC}"
    echo "   ./scripts/installation/main.sh"
    echo ""
    echo -e "${GREEN}2. Ative o ambiente Python:${NC}"
    echo "   source ~/cluster_env/bin/activate"
    echo ""
    echo -e "${GREEN}3. Teste a instalação:${NC}"
    echo "   python test_installation.py"
    echo ""
    echo -e "${GREEN}4. Execute demonstrações:${NC}"
    echo "   python demo_cluster.py"
    echo "   python simple_demo.py"
    echo ""
    echo -e "${GREEN}5. Acesse o dashboard:${NC}"
    echo "   http://localhost:8787"
    echo ""
    echo -e "${GREEN}6. Desenvolvimento com VS Code:${NC}"
    echo "   code ."
    echo ""
    echo -e "${YELLOW}Documentação completa em:${NC}"
    echo "   README.md e DEMO_README.md"
}

# Main execution
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}       INSTALADOR UNIVERSAL CLUSTER AI${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo "Sistema: $(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1)"
    echo "Usuário: $(whoami)"
    echo "Diretório: $(pwd)"
    echo ""
    
    # Verificar se é root
    if [ "$EUID" -eq 0 ]; then
        error "Não execute como root! Use seu usuário normal."
        exit 1
    fi
    
    # Detecta o OS no início para que a variável esteja sempre disponível
    detect_os

    # Mostrar menu
    show_menu
    
    echo -e "\n${GREEN}🎉 Processo concluído!${NC}"
    echo "Seu ambiente de desenvolvimento está pronto."
}

# Executar
main
