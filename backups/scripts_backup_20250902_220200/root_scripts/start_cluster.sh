#!/bin/bash
# Script de Inicialização Rápida do Cluster AI
# Ativa o servidor, descobre nós e inicia monitoramento

set -euo pipefail

# =============================================================================
# Cluster AI - Inicialização Rápida
# =============================================================================

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACTIVATE_SCRIPT="${PROJECT_ROOT}/scripts/deployment/activate_server.sh"
NETWORK_SCRIPT="${PROJECT_ROOT}/scripts/management/network_discovery.sh"
MONITOR_SCRIPT="${PROJECT_ROOT}/scripts/management/monitor_mode.sh"
SETUP_MONITOR_SCRIPT="${PROJECT_ROOT}/scripts/deployment/setup_monitor_service.sh"

# --- Funções ---

# Verifica se estamos no diretório correto
check_project_directory() {
    if [ ! -f "manager.sh" ] || [ ! -d "scripts" ]; then
        echo "❌ ERRO: Execute este script do diretório raiz do projeto Cluster AI"
        echo "📍 Diretório atual: $(pwd)"
        exit 1
    fi
}

# Funções auxiliares para mensagens coloridas e seções
section() {
    echo
    echo "=============================="
    echo " $1"
    echo "=============================="
}

subsection() {
    echo
    echo "---- $1 ----"
}

progress() {
    echo "[...] $1"
}

success() {
    echo "[✔] $1"
}

error() {
    echo "[✘] $1"
}

warn() {
    echo "[!] $1"
}

info() {
    echo "[i] $1"
}

# Mostra banner de inicialização
show_banner() {
    echo
    echo "=================================================================================="
    echo "                    🚀 CLUSTER AI - INICIALIZAÇÃO RÁPIDA 🚀"
    echo "=================================================================================="
    echo
    echo "Este script irá:"
    echo "  ✅ Ativar todos os serviços do servidor"
    echo "  🔍 Descobrir nós disponíveis na rede"
    echo "  📊 Configurar monitoramento contínuo"
    echo
    echo "=================================================================================="
    echo
}

# Menu de opções
show_menu() {
    echo "Escolha o modo de inicialização:"
    echo
    echo "🚀 MODOS RÁPIDOS:"
    echo "1) ⚡ Inicialização completa (recomendado)"
    echo "2) 🏠 Apenas servidor local"
    echo "3) 🌐 Apenas descoberta de rede"
    echo
    echo "🔧 COMPONENTES INDIVIDUAIS:"
    echo "4) ⚙️  Ativar servidor"
    echo "5) 🔍 Descobrir nós"
    echo "6) 📊 Iniciar monitoramento"
    echo "7) 🔄 Configurar serviço automático"
    echo
    echo "📋 UTILITÁRIOS:"
    echo "8) 📈 Status do cluster"
    echo "9) 🧪 Executar testes"
    echo
    echo "0) ❌ Sair"
    echo
}

# Inicialização completa
full_startup() {
    section "🚀 Inicialização Completa do Cluster AI"

    # Passo 1: Ativar servidor
    subsection "Passo 1: Ativando Servidor"
    if [ -f "$ACTIVATE_SCRIPT" ]; then
        progress "Executando ativação do servidor..."
        bash "$ACTIVATE_SCRIPT"
    else
        error "Script de ativação não encontrado: $ACTIVATE_SCRIPT"
        return 1
    fi

    echo
    sleep 2

    # Passo 2: Descobrir nós
    subsection "Passo 2: Descobrindo Nós na Rede"
    if [ -f "$NETWORK_SCRIPT" ]; then
        progress "Executando descoberta de rede..."
        bash "$NETWORK_SCRIPT" auto
    else
        error "Script de descoberta não encontrado: $NETWORK_SCRIPT"
        return 1
    fi

    echo
    sleep 2

    # Passo 3: Configurar monitoramento
    subsection "Passo 3: Configurando Monitoramento"
    if [ -f "$SETUP_MONITOR_SCRIPT" ]; then
        progress "Configurando serviço de monitoramento..."
        echo "y" | sudo bash "$SETUP_MONITOR_SCRIPT" 2>/dev/null || true
    else
        warn "Script de configuração de monitoramento não encontrado"
    fi

    echo
    success "🎉 Inicialização completa realizada com sucesso!"
    echo
    info "Serviços ativos:"
    info "  📊 Dask Dashboard: http://localhost:8787"
    info "  🌐 OpenWebUI: http://localhost:3000"
    info "  📡 Monitoramento: Ctrl+Alt+F8 (TTY8)"
    echo
    info "Para controle completo: ./manager.sh"
    info "Para gerenciamento de rede: ./scripts/management/network_discovery.sh"
}

# Apenas servidor local
server_only() {
    section "🏠 Ativando Apenas Servidor Local"

    if [ -f "$ACTIVATE_SCRIPT" ]; then
        bash "$ACTIVATE_SCRIPT"
    else
        error "Script de ativação não encontrado: $ACTIVATE_SCRIPT"
    fi
}

# Apenas descoberta de rede
network_only() {
    section "🌐 Executando Apenas Descoberta de Rede"

    if [ -f "$NETWORK_SCRIPT" ]; then
        bash "$NETWORK_SCRIPT"
    else
        error "Script de descoberta não encontrado: $NETWORK_SCRIPT"
    fi
}

# Status do cluster
show_cluster_status() {
    section "📈 Status do Cluster"

    if [ -f "manager.sh" ]; then
        bash manager.sh status
    else
        error "Script manager.sh não encontrado"
    fi
}

# Executar testes
run_cluster_tests() {
    section "🧪 Executando Testes do Cluster"

    if [ -f "scripts/validation/run_tests.sh" ]; then
        bash scripts/validation/run_tests.sh
    else
        error "Script de testes não encontrado"
    fi
}

# Função principal
main() {
    # Verificar diretório do projeto
    check_project_directory

    # Processar argumentos da linha de comando
    case "${1:-}" in
        full|--full)
            show_banner
            full_startup
            exit 0
            ;;
        server|--server)
            server_only
            exit 0
            ;;
        network|--network)
            network_only
            exit 0
            ;;
        status|--status)
            show_cluster_status
            exit 0
            ;;
        test|--test)
            run_cluster_tests
            exit 0
            ;;
    esac

    # Menu interativo
    while true; do
        show_banner
        show_menu

        local choice
        read -p "Digite sua opção (0-9): " choice

        case $choice in
            1) full_startup ;;
            2) server_only ;;
            3) network_only ;;
            4)
                if [ -f "$ACTIVATE_SCRIPT" ]; then
                    bash "$ACTIVATE_SCRIPT"
                else
                    error "Script não encontrado"
                fi
                ;;
            5)
                if [ -f "$NETWORK_SCRIPT" ]; then
                    bash "$NETWORK_SCRIPT"
                else
                    error "Script não encontrado"
                fi
                ;;
            6)
                if [ -f "$MONITOR_SCRIPT" ]; then
                    bash "$MONITOR_SCRIPT"
                else
                    error "Script não encontrado"
                fi
                ;;
            7)
                if [ -f "$SETUP_MONITOR_SCRIPT" ]; then
                    sudo bash "$SETUP_MONITOR_SCRIPT"
                else
                    error "Script não encontrado"
                fi
                ;;
            8) show_cluster_status ;;
            9) run_cluster_tests ;;
            0)
                info "Inicialização cancelada"
                exit 0
                ;;
            *)
                error "Opção inválida. Tente novamente."
                sleep 2
                ;;
        esac

        echo
        read -p "Pressione Enter para continuar..."
        clear
    done
}

# Executar função principal
main "$@"
