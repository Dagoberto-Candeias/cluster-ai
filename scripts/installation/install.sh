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

# --- Funções de Orquestração da Instalação ---

INSTALL_STEPS_SUCCESS=()
INSTALL_STEPS_WARNING=()
INSTALL_STEPS_FAILED=()

# Função para executar um passo da instalação e registrar o resultado
# Argumentos: 1:Descrição do Passo, 2:Comando a ser executado, 3:É um passo crítico? (true/false)
run_install_step() {
    local description="$1"
    local command="$2"
    local is_critical="${3:-true}"

    subsection "$description"
    if eval "$command"; then
        success "✅ Concluído: $description"
        INSTALL_STEPS_SUCCESS+=("$description")
        return 0
    else
        if [ "$is_critical" = true ]; then
            error "❌ Falha Crítica: $description. A instalação não pode continuar."
            INSTALL_STEPS_FAILED+=("$description")
            return 1
        else
            warn "⚠️  Aviso: $description falhou ou foi pulado. Continuando a instalação."
            INSTALL_STEPS_WARNING+=("$description")
            return 0 # Não é crítico, então não retorna falha para o orquestrador
        fi
    fi
}

print_installation_summary() {
    section "Resumo da Instalação"
    log "Passos concluídos com sucesso: ${#INSTALL_STEPS_SUCCESS[@]}"
    [ ${#INSTALL_STEPS_SUCCESS[@]} -gt 0 ] && printf "  - %s\n" "${INSTALL_STEPS_SUCCESS[@]}"
    warn "Passos com avisos ou pulados: ${#INSTALL_STEPS_WARNING[@]}"
    [ ${#INSTALL_STEPS_WARNING[@]} -gt 0 ] && printf "  - %s\n" "${INSTALL_STEPS_WARNING[@]}"
    error "Passos que falharam: ${#INSTALL_STEPS_FAILED[@]}"
    [ ${#INSTALL_STEPS_FAILED[@]} -gt 0 ] && printf "  - %s\n" "${INSTALL_STEPS_FAILED[@]}"
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

# --- Funções de Detecção de Papel ---

detect_hardware_for_role() {
    local cpu_cores; cpu_cores=$(nproc 2>/dev/null || echo 4)
    local total_memory_mb; total_memory_mb=$(LC_ALL=C free -m | awk '/^Mem:/{print $2}' 2>/dev/null || echo 4096) # Use LC_ALL=C for consistent output
    local gpu_count=0
    local primary_gpu_vram_mb=0

    if command_exists nvidia-smi; then
        gpu_count=$(nvidia-smi --query-gpu=count --format=csv,noheader 2>/dev/null || echo 0)
        primary_gpu_vram_mb=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n 1 2>/dev/null || echo 0)
    elif command_exists rocm-smi; then
        # Basic detection for AMD, can be expanded
        gpu_count=$(rocm-smi --showid | grep -c "GPU" 2>/dev/null || echo 0)
        # rocm-smi output for VRAM is more complex, this is a simplification
        primary_gpu_vram_mb=$(rocm-smi --showmeminfo vram | grep 'Total' | head -n 1 | awk '{print $3 / 1024 / 1024}' | cut -d. -f1 2>/dev/null || echo 0)
        # Convert from bytes to MB
        primary_gpu_vram_mb=$((primary_gpu_vram_mb * 1024))
    fi

    echo "CPU_CORES=$cpu_cores"
    echo "TOTAL_MEMORY_MB=$total_memory_mb"
    echo "GPU_COUNT=$gpu_count"
    echo "PRIMARY_GPU_VRAM_MB=$primary_gpu_vram_mb"
}

determine_node_role() {
    section "Determinando Papel do Nó com Base no Hardware"
    local resources; resources=$(detect_hardware_for_role)
    
    local cpu_cores; cpu_cores=$(echo "$resources" | grep "CPU_CORES" | cut -d= -f2)
    local total_memory_mb; total_memory_mb=$(echo "$resources" | grep "TOTAL_MEMORY_MB" | cut -d= -f2)
    local gpu_count; gpu_count=$(echo "$resources" | grep "GPU_COUNT" | cut -d= -f2)
    local primary_gpu_vram_mb; primary_gpu_vram_mb=$(echo "$resources" | grep "PRIMARY_GPU_VRAM_MB" | cut -d= -f2)

    subsection "Recursos Detectados"
    info "  - CPU Cores: $cpu_cores"
    info "  - Memória RAM: ${total_memory_mb} MB"
    info "  - GPUs: $gpu_count"
    info "  - VRAM da GPU Primária: ${primary_gpu_vram_mb} MB"

    local suggested_role="Nó Limitado" # Papel padrão

    # Lógica de decisão hierárquica e mais clara
    if [ "$gpu_count" -gt 0 ] && [ "$primary_gpu_vram_mb" -ge 12000 ] && [ "$total_memory_mb" -ge 32000 ] && [ "$cpu_cores" -ge 8 ]; then
        suggested_role="Servidor Principal"
    elif [ "$gpu_count" -gt 0 ] && [ "$primary_gpu_vram_mb" -ge 6000 ]; then
        suggested_role="Worker (GPU)"
    elif [ "$total_memory_mb" -ge 16000 ] && [ "$cpu_cores" -ge 6 ] && [ "$gpu_count" -eq 0 ]; then
        suggested_role="Estação de Trabalho"
    elif [ "$total_memory_mb" -ge 8000 ] && [ "$cpu_cores" -ge 4 ] && [ "$gpu_count" -eq 0 ]; then
        suggested_role="Worker (CPU)"
    fi
    
    subsection "Análise e Sugestão de Papel"
    info "Com base no hardware, o papel sugerido para este nó é: ${YELLOW}${suggested_role}${NC}"
    echo "$suggested_role"
}

register_node_with_server() {
    subsection "Registro do Nó no Servidor Principal"
    if ! confirm_operation "Deseja registrar este nó no servidor principal do cluster?"; then
        warn "Registro pulado. Você pode adicionar este nó manualmente mais tarde."
        return 0
    fi

    read -p "Digite o endereço IP do servidor principal: " server_ip
    read -p "Digite o nome de usuário no servidor principal: " server_user

    if [ -z "$server_ip" ] || [ -z "$server_user" ]; then
        error "IP e usuário do servidor são necessários. Registro falhou."
        return 1
    fi

    local node_hostname; node_hostname=$(hostname)
    local node_ip; node_ip=$(hostname -I | awk '{print $1}')
    local node_user; node_user=$(whoami)
    local node_entry="$node_hostname $node_ip $node_user"

    log "Tentando adicionar a entrada '$node_entry' ao servidor $server_user@$server_ip..."
    ssh "$server_user@$server_ip" "mkdir -p ~/.cluster_config && echo '$node_entry' >> ~/.cluster_config/nodes_list.conf && echo 'Nó registrado com sucesso!'" || { error "Falha ao registrar nó. Verifique a conectividade SSH e as permissões."; return 1; }
}

run_full_installation() {
    local auto_accept_role=false
    if [[ "$1" == "--auto-role" ]]; then
        auto_accept_role=true
        warn "Modo de instalação automática ativado. O papel sugerido será aceito sem confirmação."
    fi

    # Limpar status de instalações anteriores
    INSTALL_STEPS_SUCCESS=()
    INSTALL_STEPS_WARNING=()
    INSTALL_STEPS_FAILED=()

    section "Iniciando Instalação Completa e Automática"
    local node_role; node_role=$(determine_node_role)
    if [ -z "$node_role" ]; then
        error "Não foi possível determinar o papel do nó. Abortando."
        return 1
    fi

    if [ "$auto_accept_role" = false ] && ! confirm_operation "Deseja prosseguir com a instalação usando o papel sugerido '${node_role}'?"; then
        log "Instalação cancelada pelo usuário."
        return 0
    fi

    # Passos comuns a todos os papéis
    run_install_step "Instalando dependências do sistema" \
        "bash '${INSTALL_DIR}/setup_dependencies.sh'" true || { print_installation_summary; return 1; }
    run_install_step "Configurando ambiente Python" \
        "bash '${INSTALL_DIR}/setup_python_env.sh'" true || { print_installation_summary; return 1; }
    run_install_step "Configurando Ollama e baixando modelos" \
        "bash '${INSTALL_DIR}/setup_ollama.sh'" true || { print_installation_summary; return 1; }

    # Passos específicos para cada papel
    case "$node_role" in
        "Servidor Principal")
            log "Instalando como Servidor Principal (todos os componentes)..."
            run_install_step "Configurando drivers de GPU (Opcional)" "sudo bash '${INSTALL_DIR}/gpu_setup.sh'" false
            run_install_step "Instalando IDEs de desenvolvimento (Opcional)" "bash '${DEV_DIR}/setup_vscode.sh' && bash '${DEV_DIR}/setup_pycharm.sh' && bash '${DEV_DIR}/setup_spyder.sh'" false
            run_install_step "Configurando OpenWebUI com limites otimizados" \
                "bash '${INSTALL_DIR}/setup_openwebui.sh'" true || { print_installation_summary; return 1; }
            ;;
        "Worker (GPU)")
            log "Instalando como Worker Dedicado (foco em processamento GPU)..."
            run_install_step "Configurando drivers de GPU (Crítico para este papel)" "sudo bash '${INSTALL_DIR}/gpu_setup.sh'" true || { print_installation_summary; return 1; }
            register_node_with_server
            ;;
        "Estação de Trabalho")
            log "Instalando como Estação de Trabalho (desenvolvimento e processamento CPU)..."
            run_install_step "Configurando drivers de GPU (Opcional)" "sudo bash '${INSTALL_DIR}/gpu_setup.sh'" false
            run_install_step "Instalando IDEs de desenvolvimento (Recomendado)" "bash '${DEV_DIR}/setup_vscode.sh' && bash '${DEV_DIR}/setup_pycharm.sh' && bash '${DEV_DIR}/setup_spyder.sh'" false
            register_node_with_server
            ;;
        "Worker (CPU)")
            log "Instalando como Worker (CPU)..."
            register_node_with_server
            ;;
        "Nó Limitado")
            warn "Este nó tem recursos limitados. A performance pode ser baixa."
            info "Apenas os componentes básicos (dependências, python, ollama) serão instalados."
            ;;
    esac

    # Passos finais comuns
    run_install_step "Configurando scripts de runtime" \
        "mkdir -p '$HOME/cluster_scripts' && cp '${PROJECT_ROOT}/scripts/runtime/start_worker.sh' '$HOME/cluster_scripts/' && chmod +x '$HOME/cluster_scripts/start_worker.sh'" true || { print_installation_summary; return 1; }
    local optimizer_script="${SCRIPTS_DIR}/management/resource_optimizer.sh"
    run_install_step "Otimização Automática de Recursos" "bash '$optimizer_script' optimize" false

    print_installation_summary
    
    if [ ${#INSTALL_STEPS_FAILED[@]} -gt 0 ]; then
        error "A instalação completa falhou."
        return 1
    else
        success "Instalação completa finalizada com sucesso!"
    fi
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
        1) run_full_installation "$2" ;; # Passa argumentos extras
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
    # Verifica se o modo automático foi passado como argumento para o script principal
    if [[ "$1" == "--auto-role" ]]; then
        run_full_installation "--auto-role"
        exit $?
    fi

    show_banner
    check_requirements

    while true; do
        show_install_menu
        read -p "Selecione uma opção [1-5]: " choice
        if process_menu_choice "$choice" ""; then
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
