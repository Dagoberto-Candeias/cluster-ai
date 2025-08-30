#!/bin/bash
# Painel de Controle do Cluster AI - Versão Modular
# Gerencia serviços, executa verificações e otimizações.

set -euo pipefail

# ==================== CONFIGURAÇÃO INICIAL ====================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
UTILS_DIR="${SCRIPTS_DIR}/utils"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado em ${UTILS_DIR}/common.sh"
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# ==================== FUNÇÕES DE GERENCIAMENTO ====================

show_menu() {
    section "Painel de Controle - Cluster AI"
    echo "--- Ações em Massa ---"
    echo "1. 🚀 Iniciar TODOS os serviços"
    echo "2. 🛑 Parar TODOS os serviços"
    echo "3. 🔄 Reiniciar TODOS os serviços"
    echo "--- Gerenciamento e Diagnóstico ---"
    echo "4. 🧩 Gerenciar serviços individuais"
    echo "5. 📊 Mostrar status geral"
    echo "6. 🩺 Executar verificação de saúde (Health Check)"
    echo "7. 🛠️  Executar otimizador de recursos"
    echo "8. ⚙️  Acessar instalador/configurador"
    echo "---"
    echo "9. 🚪 Sair"
}

# --- Funções Granulares de Serviço ---

start_ollama() {
    if command_exists ollama; then
        if ! service_active ollama; then
            log "Iniciando serviço Ollama..."
            sudo systemctl start ollama && success "Serviço Ollama iniciado." || error "Falha ao iniciar serviço Ollama."
        else
            success "Serviço Ollama já está ativo."
        fi
    else
        warn "Ollama não está instalado. Pulando."
    fi
}

stop_ollama() {
    if command_exists ollama && service_active ollama; then
        log "Parando serviço Ollama..."
        sudo systemctl stop ollama && success "Serviço Ollama parado." || error "Falha ao parar serviço Ollama."
    else
        log "Serviço Ollama não estava ativo."
    fi
}

start_dask() {
    if ! pgrep -f "dask-scheduler" > /dev/null; then
        log "Iniciando Dask Scheduler..."
        # Ativar venv se existir
        [ -f "${PROJECT_ROOT}/.venv/bin/activate" ] && source "${PROJECT_ROOT}/.venv/bin/activate"
        nohup dask-scheduler --port 8786 --dashboard-address :8787 > "${PROJECT_ROOT}/logs/dask_scheduler.log" 2>&1 &
        sleep 2
        if pgrep -f "dask-scheduler" > /dev/null; then success "Dask Scheduler iniciado."; else error "Falha ao iniciar Dask Scheduler."; fi
    else
        success "Dask Scheduler já está em execução."
    fi
}

stop_dask() {
    pkill -f "dask-scheduler" && success "Dask Scheduler parado." || log "Dask Scheduler não estava em execução."
    pkill -f "dask-worker" && success "Dask Workers parados." || log "Dask Workers não estavam em execução."
}

start_openwebui() {
    if command_exists docker && docker ps -a --format '{{.Names}}' | grep -q 'open-webui'; then
        if ! docker ps --format '{{.Names}}' | grep -q 'open-webui'; then
            log "Iniciando container OpenWebUI..."
            if docker start open-webui; then success "Container OpenWebUI iniciado."; else error "Falha ao iniciar OpenWebUI."; fi
        else
            success "Container OpenWebUI já está em execução."
        fi
    else
        warn "Container OpenWebUI não encontrado. Use o instalador para configurá-lo."
    fi
}

stop_openwebui() {
    if command_exists docker && docker ps --format '{{.Names}}' | grep -q 'open-webui'; then
        log "Parando container OpenWebUI..."
        if docker stop open-webui; then success "Container OpenWebUI parado."; else error "Falha ao parar OpenWebUI."; fi
    else
        log "Container OpenWebUI não estava em execução."
    fi
}


# --- Funções de Ações em Massa (Orquestradores) ---

start_all_services() {
    section "Iniciando TODOS os Serviços"
    subsection "Iniciando serviço Ollama"
    start_ollama
    subsection "Iniciando cluster Dask"
    start_dask
    subsection "Iniciando container OpenWebUI"
    start_openwebui
}

stop_all_services() {
    section "Parando TODOS os Serviços"
    subsection "Parando cluster Dask"
    stop_dask
    subsection "Parando serviço Ollama"
    stop_ollama
    subsection "Parando container OpenWebUI"
    stop_openwebui
}

restart_all_services() {
    section "Reiniciando todos os serviços"
    stop_all_services
    echo ""
    start_all_services
}

# --- Funções de Sub-Menu ---

show_service_management_menu() {
    subsection "Gerenciamento de Serviços Individuais"
    
    # Status do Ollama
    if service_active ollama; then
        echo -e "1. Ollama          (Status: ${GREEN}ATIVO${NC}   | Ação: Parar)"
    else
        echo -e "1. Ollama          (Status: ${RED}INATIVO${NC}  | Ação: Iniciar)"
    fi

    # Status do Dask
    if pgrep -f "dask-scheduler" > /dev/null; then
        echo -e "2. Dask            (Status: ${GREEN}ATIVO${NC}   | Ação: Parar)"
    else
        echo -e "2. Dask            (Status: ${RED}INATIVO${NC}  | Ação: Iniciar)"
    fi

    # Status do OpenWebUI
    if command_exists docker && docker ps --format '{{.Names}}' | grep -q 'open-webui'; then
        echo -e "3. OpenWebUI (Docker) (Status: ${GREEN}ATIVO${NC}   | Ação: Parar)"
    else
        echo -e "3. OpenWebUI (Docker) (Status: ${RED}INATIVO${NC}  | Ação: Iniciar)"
    fi

    echo "---"
    echo "4. Voltar ao menu principal"
}

run_service_management_menu() {
    while true; do
        clear
        show_service_management_menu
        read -p "Selecione uma opção [1-4]: " choice
        case $choice in
            1) 
               if service_active ollama; then
                   confirm_operation "Ollama está ATIVO. Deseja pará-lo?" && stop_ollama
               else
                   confirm_operation "Ollama está INATIVO. Deseja iniciá-lo?" && start_ollama
               fi
               ;;
            2)
               if pgrep -f "dask-scheduler" > /dev/null; then
                   confirm_operation "Dask está ATIVO. Deseja pará-lo?" && stop_dask
               else
                   confirm_operation "Dask está INATIVO. Deseja iniciá-lo?" && start_dask
               fi
               ;;
            3)
               if command_exists docker && docker ps --format '{{.Names}}' | grep -q 'open-webui' 2>/dev/null; then
                   confirm_operation "OpenWebUI está ATIVO. Deseja pará-lo?" && stop_openwebui
               else
                   confirm_operation "OpenWebUI está INATIVO. Deseja iniciá-lo?" && start_openwebui
               fi
               ;;
            4) break ;;
            *) warn "Opção inválida." ;;
        esac
        echo ""
        read -p "Pressione Enter para continuar..."
    done
}

# --- Funções Principais ---
show_status() {
    section "Status Geral do Cluster"
    
    subsection "Serviço Ollama"
    if command_exists ollama; then
        if service_active ollama; then
            success "Ollama: Ativo"
            ollama ps 2>/dev/null | head -n 5
        else
            warn "Ollama: Inativo"
        fi
    else
        log "Ollama: Não instalado"
    fi

    subsection "Cluster Dask"
    if pgrep -f "dask-scheduler" > /dev/null; then
        success "Dask Scheduler: Ativo"
    else
        warn "Dask Scheduler: Inativo"
    fi
    local worker_count
    worker_count=$(pgrep -f "dask-worker" | wc -l)
    if [ "$worker_count" -gt 0 ]; then
        success "Dask Workers: $worker_count ativos"
    else
        warn "Dask Workers: Nenhum ativo"
    fi

    subsection "Containers Docker"
    if command_exists docker && docker info >/dev/null 2>&1; then
        log "Containers em execução:"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    else
        warn "Docker: Daemon não está em execução ou não está instalado."
    fi
}

run_health_check() {
    section "Running Health Check"
    bash "${UTILS_DIR}/health_check.sh"
}

run_optimizer() {
    local optimizer_script="${SCRIPTS_DIR}/management/resource_optimizer.sh"
    if [ -f "$optimizer_script" ]; then
        section "Executando Otimizador de Recursos"
        bash "$optimizer_script" status
        if confirm_operation "Deseja executar a otimização automática?"; then
            bash "$optimizer_script" optimize
        fi
    else
        error "Script do otimizador não encontrado em $optimizer_script"
    fi
}

run_installer() {
    section "Acessando Instalador/Configurador"
    log "Iniciando o script de instalação principal..."
    bash "${PROJECT_ROOT}/install.sh"
}

main() {
    while true; do
        # clear # Removido para manter o contexto visível após uma ação
        show_menu
        read -p "Selecione uma opção [1-9]: " choice
        case $choice in
            1) start_all_services ;;
            2) stop_all_services ;;
            3) restart_all_services ;;
            4) run_service_management_menu ;;
            5) show_status ;;
            6) run_health_check ;;
            7) run_optimizer ;;
            8) run_installer; break ;; # Sai do manager após rodar o instalador
            9) log "Saindo..."; exit 0 ;;
            *) warn "Opção inválida";;
        esac
        echo ""
        read -p "Pressione Enter para voltar ao menu..."
    done
}

main "$@"
