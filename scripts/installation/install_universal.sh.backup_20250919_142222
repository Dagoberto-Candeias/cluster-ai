#!/bin/bash
# Instalador Universal Cluster AI - Ambiente de Desenvolvimento Completo
# Versão: 2.0 - Usando funções unificadas e modularizadas

set -euo pipefail

# ==================== CONFIGURAÇÃO INICIAL ====================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/../utils/common.sh"
INSTALL_FUNCTIONS="${SCRIPT_DIR}/../utils/install_functions.sh"

if [ ! -f "$COMMON_SCRIPT" ]; then
    echo "ERRO: Script de funções comuns não encontrado: $COMMON_SCRIPT"
    exit 1
fi
source "$COMMON_SCRIPT"

if [ ! -f "$INSTALL_FUNCTIONS" ]; then
    error "Script de funções de instalação não encontrado: $INSTALL_FUNCTIONS"
    exit 1
fi
source "$INSTALL_FUNCTIONS"

PROJECT_ROOT="$SCRIPT_DIR"
CONFIG_FILE="${PROJECT_ROOT}/cluster.conf"
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/install_universal_$(date +%Y%m%d_%H%M%S).log"

# ==================== FUNÇÕES ====================

show_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                INSTALADOR UNIVERSAL CLUSTER AI              ║"
    echo "║          Ambiente de Desenvolvimento Completo               ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "Sistema: $(lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1)"
    echo "Usuário: $(whoami)"
    echo "Diretório: $PROJECT_ROOT"
    echo "Log da instalação: $LOG_FILE"
    echo ""
}

check_requirements() {
    section "Verificando Requisitos do Sistema"
    check_root
    
    local os
    os=$(detect_os)
    info "Sistema operacional detectado: $os"

    check_command "curl" "cURL" "sudo apt install curl / sudo yum install curl"
    check_command "git" "Git" "sudo apt install git / sudo yum install git"
    check_command "python3" "Python 3" "sudo apt install python3 / sudo yum install python3"
    check_command "pip" "PIP" "sudo apt install python3-pip / sudo yum install python3-pip"

    local mem_total
    mem_total=$(free -h | awk '/Mem:/ {print $2}')
    local disk_free
    disk_free=$(df -h . | awk 'NR==2 {print $4}')
    info "Memória total: $mem_total"
    info "Espaço livre em disco: $disk_free"

    if [ "$(echo "$mem_total" | sed 's/G//')" -lt 8 ]; then
        warn "Memória RAM baixa (mínimo recomendado: 8GB)"
    fi

    if [ "$(echo "$disk_free" | sed 's/G//')" -lt 50 ]; then
        warn "Espaço em disco baixo (mínimo recomendado: 50GB)"
    fi
}

setup_environment() {
    section "Configurando Ambiente"
    if [ ! -f "$CONFIG_FILE" ]; then
        info "Criando arquivo de configuração padrão..."
        cp "${PROJECT_ROOT}/cluster.conf.example" "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"
        success "Arquivo de configuração criado: $CONFIG_FILE"
    else
        info "Arquivo de configuração já existe: $CONFIG_FILE"
    fi

    if load_config; then
        success "Configuração carregada com sucesso"
    else
        warn "Falha ao carregar configuração, usando padrões"
    fi

    safe_mkdir "$LOG_DIR"
    safe_mkdir "$BACKUP_DIR"
    safe_mkdir "${PROJECT_ROOT}/scripts/runtime"
}

show_menu() {
    section "Menu de Instalação Universal"
    echo "📋 OPÇÕES DISPONÍVEIS:"
    echo "1. Instalação Completa (Recomendado)"
    echo "2. Apenas Dependências do Sistema"
    echo "3. Apenas Ambiente Python"
    echo "4. Apenas Ollama e Modelos de IA"
    echo "5. Apenas Ferramentas de Desenvolvimento"
    echo "6. Configurar Papel do Cluster"
    echo "7. Sair"
    echo ""
}

install_complete() {
    section "Instalação Completa"
    info "Iniciando instalação completa do Cluster AI..."

    install_system_dependencies
    setup_python_environment
    setup_ollama
    setup_docker
    setup_cluster_role
    install_development_tools
    setup_firewall

    success "Instalação completa concluída!"
    show_post_install_info
}

install_development_tools() {
    subsection "Instalando Ferramentas de Desenvolvimento"
    
    if ! command_exists code; then
        info "Instalando Visual Studio Code..."
        local os
        os=$(detect_os)

        case $os in
            debian)
                run_sudo "apt install -y wget gpg" "Instalando dependências"
                run_sudo "wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg" "Baixando chave"
                run_sudo "install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg" "Instalando chave"
                run_sudo "sh -c 'echo \"deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main\" > /etc/apt/sources.list.d/vscode.list'"
                run_sudo "apt update && apt install -y code" "Instalando VSCode"
                ;;
            arch)
                run_sudo "pacman -S --noconfirm code" "Instalando VSCode"
                ;;
            rhel)
                run_sudo "rpm --import https://packages.microsoft.com/keys/microsoft.asc"
                run_sudo "sh -c 'echo -e \"[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\" > /etc/yum.repos.d/vscode.repo'"
                run_sudo "yum install -y code" "Instalando VSCode"
                ;;
        esac

        if command_exists code; then
            success "VSCode instalado"
        else
            warn "Falha ao instalar VSCode"
        fi
    else
        info "VSCode já está instalado"
    fi

    info "Instalando Spyder IDE..."
    run_command "source \"$VENV_DIR/bin/activate\" && pip install spyder" "Instalando Spyder"
    success "Ferramentas de desenvolvimento instaladas"
}

process_menu_choice() {
    local choice="$1"
    case $choice in
        1) install_complete ;;
        2) install_system_dependencies ;;
        3) setup_python_environment ;;
        4) setup_ollama ;;
        5) install_development_tools ;;
        6) setup_cluster_role ;;
        7) info "Saindo..."; exit 0 ;;
        *) warn "Opção inválida"; return 1 ;;
    esac
}

show_post_install_info() {
    section "Próximos Passos"
    echo -e "${GREEN}✅ INSTALAÇÃO CONCLUÍDA COM SUCESSO!${NC}"
    echo ""
    echo "📋 PRÓXIMOS PASSOS:"
    echo "1. Execute o painel de controle: ./manager.sh"
    echo "2. Consulte a documentação: docs/guides/usage.md"
    echo "3. Teste a instalação: ./manager.sh (opção 14)"
    echo ""
    echo "🌐 SERVIÇOS DISPONÍVEIS:"
    echo "• OpenWebUI: http://localhost:3000"
    echo "• Dask Dashboard: http://localhost:8787"
    echo "• Ollama API: http://localhost:11434"
    echo ""
    info "Log completo disponível em: $LOG_FILE"
}

main() {
    exec > >(tee -a "$LOG_FILE") 2>&1
    show_banner
    check_requirements
    setup_environment

    while true; do
        show_menu
        read -p "Selecione uma opção [1-7]: " choice
        if process_menu_choice "$choice"; then
            if confirm "Deseja voltar ao menu principal?" "y"; then
                continue
            else
                break
            fi
        fi
    done

    success "Processo de instalação concluído!"
}

main "$@"
