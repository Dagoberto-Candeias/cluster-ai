#!/bin/bash

# =============================================================================
# Cluster AI - Instalador Unificado
# =============================================================================
# Este é o instalador principal do Cluster AI. Ele detecta automaticamente
# o sistema operacional, instala dependências e configura o ambiente.

set -e  # Para o script em caso de erro

# =============================================================================
# INICIALIZAÇÃO
# =============================================================================

# Carrega funções comuns
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/lib/common.sh"
source "${SCRIPT_DIR}/scripts/lib/install_functions.sh"

# =============================================================================
# FUNÇÕES DO INSTALADOR
# =============================================================================

# Exibe banner do instalador
show_banner() {
    echo
    echo -e "${CYAN}================================================================================${NC}"
    echo -e "${CYAN}                    🚀 CLUSTER AI - INSTALADOR 🚀${NC}"
    echo -e "${CYAN}================================================================================${NC}"
    echo
    echo -e "${GREEN}Bem-vindo ao instalador do Cluster AI!${NC}"
    echo -e "${BLUE}Este instalador irá configurar automaticamente o ambiente completo.${NC}"
    echo
}

# Exibe informações do sistema
show_system_info() {
    subsection "Informações do Sistema"

    local os=$(detect_os)
    local distro=$(detect_linux_distro)
    local arch=$(detect_arch)
    local pm=$(detect_package_manager)

    info "Sistema Operacional: $os"
    info "Distribuição: $distro"
    info "Arquitetura: $arch"
    info "Gerenciador de Pacotes: $pm"
    info "Diretório do Projeto: $PROJECT_ROOT"
    echo
}

# Menu de instalação
show_menu() {
    subsection "Opções de Instalação"

    echo "Escolha o tipo de instalação:"
    echo
    echo "1) 🚀 Instalação Completa (Recomendado)"
    echo "   - Instala todas as dependências do sistema"
    echo "   - Configura ambiente Python"
    echo "   - Configura Docker, Nginx e firewall"
    echo "   - Cria configuração básica do cluster"
    echo
    echo "2) 🔧 Instalação Personalizada"
    echo "   - Escolha quais componentes instalar"
    echo
    echo "3) 🔍 Verificar Instalação Atual"
    echo "   - Verifica status dos componentes instalados"
    echo
    echo "4) 📚 Mostrar Ajuda"
    echo "   - Informações sobre o processo de instalação"
    echo
    echo "0) ❌ Sair"
    echo
}

# Instalação personalizada
custom_install() {
    section "Instalação Personalizada"

    echo "Selecione os componentes para instalar:"
    echo

    # Dependências do sistema
    if confirm "📦 Instalar dependências do sistema?" "y"; then
        install_system_dependencies
    fi

    # Dependências Python
    if confirm "🐍 Instalar dependências Python?" "y"; then
        install_python_dependencies
    fi

    # Docker
    if confirm "🐳 Configurar Docker?" "y"; then
        setup_docker
    fi

    # Nginx
    if confirm "🌐 Configurar Nginx?" "y"; then
        setup_nginx
    fi

    # Firewall
    if confirm "🔥 Configurar firewall?" "y"; then
        setup_firewall
    fi

    # Configuração
    if confirm "⚙️  Criar configuração do cluster?" "y"; then
        create_config
        setup_directories
    fi

    success "Instalação personalizada concluída!"
}

# Mostra ajuda
show_help() {
    section "Ajuda da Instalação"

    echo "O Cluster AI é um sistema de computação distribuída que utiliza:"
    echo "• Python com Dask para processamento paralelo"
    echo "• Ollama para execução de modelos de IA"
    echo "• Docker para conteinerização"
    echo "• Nginx como proxy reverso"
    echo
    echo "Pré-requisitos:"
    echo "• Sistema Linux (Ubuntu/Debian, Fedora/RHEL, Arch)"
    echo "• Pelo menos 4GB RAM e 20GB espaço em disco"
    echo "• Conexão com internet para downloads"
    echo
    echo "Durante a instalação:"
    echo "• Você pode ser solicitado a fornecer senha de sudo"
    echo "• Alguns serviços serão configurados para iniciar automaticamente"
    echo "• Arquivos de configuração serão criados em $PROJECT_ROOT"
    echo
    echo "Após a instalação:"
    echo "• Edite $CONFIG_FILE para personalizar configurações"
    echo "• Execute ./manager.sh para gerenciar o cluster"
    echo "• Consulte a documentação em docs/README.md"
    echo
    confirm "Voltar ao menu principal?" "y" || exit 0
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Verificações iniciais
    if is_root; then
        error "Não execute o instalador como root"
        info "Use: ./install.sh"
        exit 1
    fi

    # Exibe banner
    show_banner

    # Loop principal do menu
    while true; do
        show_system_info
        show_menu

        local choice
        read -p "Digite sua opção (0-4): " choice

        case $choice in
            1)
                # Instalação completa
                if confirm "Iniciar instalação completa do Cluster AI?" "y"; then
                    install_cluster_ai
                    break
                fi
                ;;
            2)
                # Instalação personalizada
                custom_install
                break
                ;;
            3)
                # Verificar instalação
                check_installation
                echo
                if confirm "Voltar ao menu?" "y"; then
                    continue
                else
                    break
                fi
                ;;
            4)
                # Ajuda
                show_help
                ;;
            0)
                # Sair
                info "Instalação cancelada pelo usuário"
                exit 0
                ;;
            *)
                error "Opção inválida. Tente novamente."
                sleep 2
                ;;
        esac
    done

    # Finalização
    echo
    success "🎉 Processo de instalação finalizado!"
    echo
    info "Para começar a usar o Cluster AI:"
    info "1. Configure o ambiente: source .venv/bin/activate"
    info "2. Edite a configuração: nano cluster.conf"
    info "3. Inicie o cluster: ./manager.sh"
    echo
    info "Para obter ajuda: ./manager.sh --help"
    echo
}

# =============================================================================
# EXECUÇÃO
# =============================================================================

# Executa função principal
main "$@"
