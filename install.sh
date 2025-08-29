#!/bin/bash
# Instalador Unificado Refatorado - Cluster AI
# Versão: 2.0 - Modular, clara e alinhada ao plano de refatoração

set -euo pipefail

# ==================== CONFIGURAÇÃO INICIAL ====================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
COMMON_SCRIPT="${PROJECT_ROOT}/scripts/lib/common.sh"
INSTALL_FUNCTIONS="${PROJECT_ROOT}/scripts/lib/install_functions.sh"

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

CONFIG_FILE="${PROJECT_ROOT}/cluster.conf"
LOG_DIR="${PROJECT_ROOT}/logs"
BACKUP_DIR="${PROJECT_ROOT}/backups"
LOG_FILE="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"

# Criar diretório de logs se não existir
mkdir -p "$LOG_DIR"

# ==================== FUNÇÕES ====================

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

show_install_menu() {
    section "Menu de Instalação"
    echo "📋 OPÇÕES DISPONÍVEIS:"
    echo "1. Instalação Completa (Recomendado)"
    echo "2. Instalação por Componentes (em desenvolvimento)"
    echo "3. Apenas Dependências do Sistema"
    echo "4. Apenas Ambiente Python"
    echo "5. Configurar Papel do Cluster"
    echo "6. Verificar Sistema (em desenvolvimento)"
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
    setup_services
    setup_firewall
    validate_installation

    success "Instalação completa concluída!"
}

process_menu_choice() {
    local choice="$1"
    case $choice in
        1) install_complete ;;
        2) info "Instalação por componentes ainda não implementada" ;;
        3) install_system_dependencies ;;
        4) setup_python_environment ;;
        5) setup_cluster_role ;;
        6) info "Verificação do sistema ainda não implementada" ;;
        7) info "Saindo..."; exit 0 ;;
        *) warn "Opção inválida"; return 1 ;;
    esac
}

main() {
    exec > >(tee -a "$LOG_FILE") 2>&1
    show_banner
    check_requirements
    setup_environment

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

main "$@"
