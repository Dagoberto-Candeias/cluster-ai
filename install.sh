#!/bin/bash
# Instalador Unificado Refatorado - Cluster AI
# Versão: 3.0 - Orquestrador de scripts modulares

set -euo pipefail

# ==================== CONFIGURAÇÃO INICIAL ====================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
UTILS_DIR="${SCRIPTS_DIR}/utils"
INSTALL_DIR="${SCRIPTS_DIR}/installation"
DEV_DIR="${SCRIPTS_DIR}/development"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado em ${UTILS_DIR}/common.sh"
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# Configuração de Log
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"

# Criar diretório de logs se não existir
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

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
}

check_requirements() {
    section "Verificando Requisitos do Sistema"
    local pre_check_script="${INSTALL_DIR}/pre_install_check.sh"

    if [ -f "$pre_check_script" ]; then
        log "Executando verificação pré-instalação..."
        if ! bash "$pre_check_script"; then
            error "A verificação pré-instalação falhou com erros críticos."
            if ! confirm_operation "Deseja tentar continuar mesmo assim?"; then
                log "Instalação cancelada pelo usuário."
                exit 0
            fi
        else
            success "Verificação pré-instalação concluída com sucesso."
        fi
    else
        error "Script de verificação pré-instalação não encontrado em $pre_check_script"
        error "A instalação não pode continuar."
        exit 1
    fi
}

show_install_menu() {
    section "Menu de Instalação - Cluster AI"
    echo "1. 🚀 Instalação Completa (Recomendado)"
    echo "2. 🧩 Instalar Componentes (Avançado)"
    echo "3. 🩺 Verificar Saúde do Sistema"
    echo "4. 🗑️  Desinstalar Ambiente"
    echo "---"
    echo "5. 🚪 Sair"
    echo ""
}

run_full_installation() {
    section "Iniciando Instalação Completa"

    log "Passo 1: Instalando dependências do sistema..."
    bash "${INSTALL_DIR}/setup_dependencies.sh" || { error "Falha ao instalar dependências do sistema."; return 1; }

    log "Passo 2: Configurando ambiente Python..."
    bash "${INSTALL_DIR}/setup_python_env.sh" || { error "Falha ao configurar ambiente Python."; return 1; }

    log "Passo 3: Configurando Ollama e baixando modelos..."
    bash "${INSTALL_DIR}/setup_ollama.sh" || { error "Falha ao configurar Ollama."; return 1; }

    log "Passo 4: Configurando drivers de GPU (Opcional)..."
    if confirm_operation "Deseja tentar configurar os drivers de GPU (NVIDIA/AMD)?"; then
        sudo bash "${INSTALL_DIR}/gpu_setup.sh" || warn "Configuração de GPU falhou ou foi pulada. Continuando..."
    fi

    log "Passo 5: Instalando IDEs de desenvolvimento (Opcional)..."
    if confirm_operation "Deseja instalar as IDEs recomendadas (VSCode, PyCharm, Spyder)?"; then
        bash "${DEV_DIR}/setup_vscode.sh" || warn "Falha ao instalar VSCode."
        bash "${DEV_DIR}/setup_pycharm.sh" || warn "Falha ao instalar PyCharm."
        bash "${DEV_DIR}/setup_spyder.sh" || warn "Falha ao instalar Spyder."
    fi

    log "Passo 6: Configurando scripts de runtime..."
    local runtime_dir="${PROJECT_ROOT}/scripts/runtime"
    local target_dir="$HOME/cluster_scripts"
    mkdir -p "$target_dir"
    cp "${runtime_dir}/start_worker.sh" "$target_dir/"
    chmod +x "${target_dir}/start_worker.sh"
    success "Scripts de runtime configurados em $target_dir"

    log "Passo 7: Otimização Automática de Recursos (Opcional)..."
    local optimizer_script="${SCRIPTS_DIR}/management/resource_optimizer.sh"
    if [ -f "$optimizer_script" ] && confirm_operation "Deseja executar o otimizador de recursos para ajustar as configurações de performance (Ollama, Dask) ao seu hardware?"; then
        bash "$optimizer_script" optimize || warn "Otimizador de recursos encontrou um problema. Verifique os logs."
        success "Otimização de recursos concluída."
    fi

    success "Instalação completa finalizada com sucesso!"
}

show_components_menu() {
    subsection "Menu de Instalação por Componentes"
    echo "1. 📦 Dependências do Sistema"
    echo "2. 🐍 Ambiente Python (.venv)"
    echo "3. 🧠 Ollama e Modelos de IA"
    echo "4. 🎮 Drivers de GPU (NVIDIA/AMD)"
    echo "5. 💻 IDEs de Desenvolvimento (VSCode, PyCharm, Spyder)"
    echo "---"
    echo "6. ↩️  Voltar ao Menu Principal"
    echo ""
}

process_components_menu_choice() {
    local choice="$1"
    case $choice in
        1) bash "${INSTALL_DIR}/setup_dependencies.sh" ;;
        2) bash "${INSTALL_DIR}/setup_python_env.sh" ;;
        3) bash "${INSTALL_DIR}/setup_ollama.sh" ;;
        4) sudo bash "${INSTALL_DIR}/gpu_setup.sh" || warn "Configuração de GPU falhou ou foi pulada." ;;
        5) 
           subsection "Instalando IDEs"
           bash "${DEV_DIR}/setup_vscode.sh" && \
           bash "${DEV_DIR}/setup_pycharm.sh" && \
           bash "${DEV_DIR}/setup_spyder.sh"
           ;;
        *) warn "Opção inválida"; return 1 ;;
    esac
}

run_components_installation_menu() {
    while true; do
        show_components_menu
        read -p "Selecione um componente para instalar [1-6]: " choice

        if [[ "$choice" == "6" ]]; then
            break
        fi

        if process_components_menu_choice "$choice"; then
            success "Instalação do componente concluída."
            read -p "Pressione Enter para instalar outro componente ou 'q' para voltar: " continue_choice
            if [[ "$continue_choice" == "q" || "$continue_choice" == "Q" ]]; then
                break
            fi
        else
            warn "Operação falhou, foi cancelada ou opção inválida."
            sleep 2
        fi
    done
}

process_menu_choice() {
    local choice="$1"
    case $choice in
        1) run_full_installation ;;
        2) run_components_installation_menu ;;
        3) bash "${UTILS_DIR}/health_check.sh" || warn "Health check encontrou problemas." ;;
        4) 
           warn "Esta ação removerá os artefatos do Cluster AI (ambiente virtual, logs, etc.)."
           warn "Dependências de sistema e modelos Ollama NÃO serão removidos."
           if confirm_operation "Deseja prosseguir com a desinstalação?"; then
               bash "${PROJECT_ROOT}/uninstall.sh"
               log "Desinstalação concluída. Saindo do instalador."
               exit 0
           fi
           ;;
        5) log "Saindo..."; exit 0 ;;
        *) warn "Opção inválida"; return 1 ;;
    esac
}

main() {
    show_banner
    check_requirements

    while true; do
        show_install_menu
        read -p "Selecione uma opção [1-5]: " choice
        if process_menu_choice "$choice"; then
            success "Operação concluída."
        else
            warn "Operação falhou ou foi cancelada."
        fi

        echo ""
        read -p "Pressione Enter para voltar ao menu ou 'q' para sair: " continue_choice
        if [[ "$continue_choice" == "q" || "$continue_choice" == "Q" ]]; then
            break
        fi
    done

    section "Finalizado"
    info "Log completo disponível em: $LOG_FILE"
}

main "$@"
