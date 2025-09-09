#!/bin/bash
# Local: manager.sh
# Autor: Nome: Dagoberto Candeias. email: betoallnet@gmail.com telefone/whatsapp: +5511951754945

# =============================================================================
# Cluster AI - Gerenciador do Cluster
# =============================================================================
# Este é o painel de controle principal do Cluster AI. Permite iniciar,
# parar, configurar e monitorar todos os componentes do sistema.
#
# ARQUITETURA MODULAR: Este script foi refatorado para usar módulos core
# (common.sh, security.sh, services.sh, workers.sh, ui.sh) para melhor
# organização e manutenção do código.

set -euo pipefail  # Modo estrito: para em erros, variáveis não definidas e falhas em pipelines

# =============================================================================
# INICIALIZAÇÃO
# =============================================================================

# Carrega módulos core
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR" # Assumindo que manager.sh está na raiz
CONFIG_FILE="${PROJECT_ROOT}/cluster.yaml"

# Carregar módulos na ordem correta (common primeiro)
source "${SCRIPT_DIR}/scripts/core/common.sh"
source "${SCRIPT_DIR}/scripts/core/security.sh"
source "${SCRIPT_DIR}/scripts/core/services.sh"
source "${SCRIPT_DIR}/scripts/core/workers.sh"
source "${SCRIPT_DIR}/scripts/core/ui.sh"

# Funções de compatibilidade para interface
section() {
    ui_section "$1"
}

subsection() {
    ui_subsection "$1"
}

# Funções básicas agora fornecidas pelos módulos core
# log(), confirm_operation(), etc. estão disponíveis via common.sh e security.sh

# =============================================================================
# FUNÇÕES DE SEGURANÇA E VALIDAÇÃO (AGORA VIA MÓDULOS CORE)
# =============================================================================
# Funções de segurança, validação e auditoria agora fornecidas pelos módulos core:
# - audit_log() via security.sh
# - validate_input() via security.sh
# - check_user_authorization() via security.sh
# - confirm_critical_operation() via security.sh
# =============================================================================
# FUNÇÕES DE GERENCIAMENTO DE SERVIÇOS (AGORA VIA MÓDULOS CORE)
# =============================================================================
# Funções de gerenciamento de serviços agora fornecidas pelos módulos core:
# - manage_systemd_service() via services.sh
# - manage_docker_container() via services.sh
# - start_background_process() via services.sh
# - stop_background_process() via services.sh

# =============================================================================
# FUNÇÕES DO GERENCIADOR
# =============================================================================

# Exibe banner do gerenciador
show_banner() {
    echo
    echo -e "${CYAN}================================================================================${NC}"
    echo -e "${CYAN}                    🎛️  CLUSTER AI - GERENCIADOR 🎛️${NC}"
    echo -e "${CYAN}================================================================================${NC}"
    echo
    echo -e "${GREEN}Gerencie todos os componentes do Cluster AI em um só lugar${NC}"
    echo
}



# =============================================================================
# FUNÇÃO UNIFICADA DE STATUS
# =============================================================================

# Função unificada para exibir o status do cluster com diferentes níveis de detalhe.
# Argumento: "simple" ou "detailed". Padrão é "simple".
# Esta função lê de um arquivo de cache para ser instantânea.
display_cluster_status() {
    local mode="${1:-simple}"

    if [[ "$mode" == "detailed" ]]; then
        section "Status Detalhado do Cluster"
        # Informações do sistema
        subsection "Sistema"
        echo "📍 Diretório: $(pwd)"
        echo "👤 Usuário: $(whoami)"
        echo "🖥️  Hostname: $(hostname)"
        echo "💻 OS: $(detect_os) $(detect_linux_distro)"
        echo "🔧 CPU: $(nproc) cores"
        echo "🧠 RAM: $(free -h | awk 'NR==2{printf "%.1fGB", $2}')"
        echo
    else
        section "Status do Cluster"
        # echo "🔍 Verificando serviços..."
    fi

    local cache_file="${PROJECT_ROOT}/run/status.cache"
    if [ ! -f "$cache_file" ]; then
        warn "Cache de status não encontrado. Execute a atualização (Opção 'r' no menu)."
        return
    fi

    # Função auxiliar para ler do cache
    get_cache() { grep "^$1=" "$cache_file" 2>/dev/null | cut -d'=' -f2; }

    subsection "Serviços"
    [[ "$(get_cache 'service_docker')" == "online" ]] && success "🐳 Docker: Ativo" || error "🐳 Docker: Inativo"
    [[ "$(get_cache 'service_dask_scheduler')" == "online" ]] && success "📊 Dask Scheduler: Ativo" || warn "📊 Dask Scheduler: Inativo"
    [[ "$(get_cache 'service_dask_dashboard')" == "online" ]] && success "📈 Dask Dashboard: Ativo" || warn "📈 Dask Dashboard: Inativo"
    [[ "$(get_cache 'service_ollama')" == "online" ]] && success "🧠 Ollama: Ativo" || warn "🧠 Ollama: Inativo"
    [[ "$(get_cache 'service_openwebui')" == "online" ]] && success "🌐 OpenWebUI: Ativo" || warn "🌐 OpenWebUI: Inativo"
    [[ "$(get_cache 'service_nginx')" == "online" ]] && success "🌐 Nginx: Ativo" || warn "🌐 Nginx: Inativo"
    echo

    # --- Status dos Workers ---
    subsection "Workers do Cluster"
    local total_workers; total_workers=$(get_cache "workers_total")
    local online_workers; online_workers=$(get_cache "workers_online")
    local offline_workers=$((total_workers - online_workers))

    # Ler e exibir status de cada worker do cache
    grep '^worker_.*_status=' "$cache_file" 2>/dev/null | while IFS='=' read -r key value; do
        local worker_name; worker_name=$(echo "$key" | sed -e 's/^worker_//' -e 's/_status$//')
        local worker_info; worker_info=$(get_cache "worker_${worker_name}_info")
        if [[ "$value" == "online" ]]; then
            echo -e "  ${GREEN}●${NC} $worker_info - ${GREEN}ONLINE${NC}"
        else
            echo -e "  ${RED}●${NC} $worker_info - ${RED}OFFLINE${NC}"
        fi
    done

    # Resumo dos workers
    if [ "${total_workers:-0}" -gt 0 ]; then
        echo
        echo -e "  📊 ${GREEN}Online: ${online_workers:-0}${NC} | ${RED}Offline: ${offline_workers:-0}${NC} | Total: ${total_workers:-0}"
    else
        echo -e "  ${YELLOW}ℹ️  Nenhum worker configurado${NC}"
        echo -e "     Use: ./manager.sh configure"
    fi
    echo

    if [[ "$mode" == "detailed" ]]; then
        # --- Seções Detalhadas ---
        # Recursos do sistema
        subsection "Recursos"
        echo "📊 Uso de CPU: $(uptime | awk -F'load average:' '{ print $2 }' | sed 's/,//g' | awk '{print $1, $2, $3}') Load Average"
        echo "🧠 Uso de RAM: $(free | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
        echo "💾 Uso de Disco: $(df -h . | awk 'NR==2{print $5}')"

        local OLLAMA_MODELS_DIR="$HOME/.ollama"
        if dir_exists "$OLLAMA_MODELS_DIR"; then
            local ollama_size; ollama_size=$(du -sh "$OLLAMA_MODELS_DIR" | awk '{print $1}')
            echo "🧠 Espaço Ollama: $ollama_size"
        else
            echo "🧠 Espaço Ollama: (diretório não encontrado)"
        fi
        echo

        # Portas abertas
        subsection "Portas"
        if command_exists netstat; then
            netstat -tln | grep LISTEN | head -10
        elif command_exists ss; then
            ss -tln | grep LISTEN | head -10
        else
            info "Para mais detalhes, use: ./manager.sh status"
        fi
    local last_update; last_update=$(get_cache "last_update")
    if [ -n "$last_update" ]; then
        info "Última atualização de status: $last_update"
    fi
    fi
}

# =============================================================================
# FUNÇÕES DE GERENCIAMENTO DE WORKERS (AGORA VIA MÓDULOS CORE)
# =============================================================================
# Funções de gerenciamento de workers agora fornecidas pelos módulos core:
# - check_all_workers_status() via workers.sh
# - test_worker_connectivity() via workers.sh
# - manage_remote_workers() via workers.sh
# - manage_auto_registered_workers() via workers.sh

# --- Funções do Sub-menu de Informações do Sistema ---

show_general_system_info() {
    subsection "Informações Gerais do Sistema"
    local os; os=$(detect_os)
    local distro; distro=$(detect_linux_distro)
    local arch; arch=$(detect_arch)
    info "Sistema Operacional: $os"
    info "Distribuição: $distro"
    info "Arquitetura: $arch"
    info "Hostname: $(hostname)"
    info "Kernel: $(uname -r)"
    info "Diretório do Projeto: $PROJECT_ROOT"
}

show_cpu_details() {
    subsection "Detalhes da CPU"
    if command_exists lscpu; then
        lscpu | grep -E 'Architecture|CPU op-mode|CPU\(s\)|Model name|Vendor ID|CPU MHz|L1d cache|L1i cache|L2 cache|L3 cache'
    else
        warn "Comando 'lscpu' não encontrado. Mostrando informações de /proc/cpuinfo."
        grep -E 'model name|vendor_id|cpu cores|cpu MHz' /proc/cpuinfo | uniq
    fi
}

show_memory_details() {
    subsection "Detalhes da Memória"
    if command_exists free; then
        info "Uso de Memória (free -h):"
        free -h
        echo
    fi
    if command_exists vmstat; then
        info "Estatísticas de Memória Virtual (vmstat -s):"
        vmstat -s | head -n 8
    else
        warn "Comandos 'free' ou 'vmstat' não encontrados."
    fi
}

show_disk_details() {
    subsection "Detalhes do Disco"
    if command_exists df; then
        info "Uso do Sistema de Arquivos (df -hT):"
        df -hT --exclude-type=tmpfs --exclude-type=squashfs
        echo
    fi
    if command_exists lsblk; then
        info "Dispositivos de Bloco (lsblk):"
        lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
    else
         warn "Comandos 'df' ou 'lsblk' não encontrados."
    fi
}

# Sub-menu para a opção "Informações do Sistema"
show_system_info_submenu() {
    while true; do
        section "ℹ️  Informações do Sistema"
        echo "1) Informações Gerais"
        echo "2) Detalhes da CPU"
        echo "3) Detalhes da Memória"
        echo "4) Detalhes do Disco"
        echo "5) Processos com Maior Consumo"
        echo "0) Voltar ao Menu Principal"
        echo

        read -p "Digite sua opção: " choice

        case $choice in
            1)
                show_general_system_info
                ;;
            2)
                show_cpu_details
                ;;
            3)
                show_memory_details
                ;;
            4)
                show_disk_details
                ;;
            5)
                # Sub-menu para gerenciamento de processos
                local filter_user=""
                local filter_command=""

                while true; do
                    show_top_processes "$filter_user" "$filter_command"
                    echo

                    if [ -n "$filter_user" ] || [ -n "$filter_command" ]; then
                        echo -e "${YELLOW}Filtros ativos: [Usuário: ${filter_user:-nenhum}] [Comando: ${filter_command:-nenhum}]${NC}"
                    fi

                    echo "Opções:"
                    echo "  'k' - Matar (kill) um processo"
                    echo "  'f' - Filtrar a lista"
                    echo "  'r' - Atualizar a lista"
                    echo "  'c' - Limpar filtros"
                    echo "  'q' - Voltar ao menu anterior"
                    echo

                    read -p "Digite sua opção [k/f/r/c/q]: " action

                    case $action in
                        k|K)
                            kill_process_interactive
                            ;;
                        f|F)
                            subsection "Filtrar Lista de Processos"
                            read -p "Filtrar por nome de usuário (deixe em branco para ignorar): " filter_user
                            read -p "Filtrar por nome de comando (deixe em branco para ignorar): " filter_command
                            info "Filtros aplicados. A lista será atualizada."
                            sleep 1
                            ;;
                        r|R)
                            info "Atualizando lista..."
                            sleep 1
                            continue
                            ;;
                        c|C)
                            if [ -n "$filter_user" ] || [ -n "$filter_command" ]; then
                                filter_user=""
                                filter_command=""
                                info "Filtros limpos."
                            else
                                info "Nenhum filtro ativo para limpar."
                            fi
                            sleep 1
                            ;;
                        q|Q)
                            break
                            ;;
                        *)
                            error "Opção inválida."
                            sleep 1
                            ;;
                    esac
                done
                ;;
            0)
                return
                ;;
            *)
                error "Opção inválida."
                sleep 1
                ;;
        esac

        if [ "$choice" != "0" ]; then
            echo
            read -p "Pressione Enter para continuar..."
        fi
    done
}

# Funções auxiliares para gerenciamento de processos
# Uso: show_top_processes <filter_user> <filter_command>
show_top_processes() {
    local filter_user="$1"
    local filter_command="$2"

    echo "Processos do sistema (Top 20 por uso de CPU):"
    echo "PID    USER    %CPU  %MEM    VSZ    RSS  COMMAND"
    echo "------------------------------------------------"

    # Usar ps para listar processos com filtros
    local ps_cmd="ps aux --sort=-%cpu | head -21 | tail -20"

    if [ -n "$filter_user" ]; then
        ps_cmd="ps aux --sort=-%cpu | grep '$filter_user' | head -20"
    fi

    if [ -n "$filter_command" ]; then
        ps_cmd="ps aux --sort=-%cpu | grep '$filter_command' | head -20"
    fi

    eval "$ps_cmd" | while read -r line; do
        echo "$line"
    done
}

# Função para matar processo interativamente
# Uso: kill_process_interactive
kill_process_interactive() {
    echo "Função de matar processo - implementação pendente"
    echo "Esta função precisa ser implementada com lógica para seleção e kill de processos"
    sleep 2
}



# Inicia o cluster
start_cluster() {
    section "Iniciando Cluster AI"
    mkdir -p "${PROJECT_ROOT}/run" "${PROJECT_ROOT}/logs"

    # Verifica configuração
    if ! file_exists "$CONFIG_FILE"; then
        error "Arquivo de configuração não encontrado: $CONFIG_FILE"
        info "Execute ./install.sh primeiro"
        return 1
    fi

    # Inicia Dask (gerenciado por PID)
    local dask_cmd="python3 ${PROJECT_ROOT}/scripts/dask/start_dask_cluster.py $PROJECT_ROOT"
    local dask_pid_file="${PROJECT_ROOT}/run/dask_cluster.pid"
    local dask_log_file="${PROJECT_ROOT}/logs/dask_cluster.log"
    start_background_process "Dask Cluster" "$dask_pid_file" "$dask_cmd" "$dask_log_file"

    # Inicia serviços systemd e Docker
    manage_systemd_service "start" "ollama"
    manage_docker_container "start" "open-webui"
    manage_systemd_service "start" "nginx"

    echo
    success "Comandos de inicialização do cluster enviados."
    echo
    display_cluster_status "simple"
}
# Para o cluster
stop_cluster() {
    section "Parando Cluster AI"

    info "Parando todos os serviços gerenciados..."

    # Para Dask (gerenciado por PID)
    stop_background_process "Dask Cluster" "${PROJECT_ROOT}/run/dask_cluster.pid"

    # Para serviços systemd e Docker
    manage_systemd_service "stop" "ollama"
    manage_docker_container "stop" "open-webui"

    # Para Nginx
    if command_exists nginx && pgrep nginx >/dev/null; then
        progress "Parando Nginx..."
        sudo systemctl stop nginx 2>/dev/null || true
        success "Nginx parado"
    fi

    echo
    success "Cluster parado com sucesso!"
    echo
    display_cluster_status "simple"
}

# Reinicia o cluster
restart_cluster() {
    section "Reiniciando Cluster AI"

    stop_cluster
    sleep 2
    start_cluster
}

# Inicialização rápida (Quick Start)
quick_start_cluster() {
    section "🚀 Inicialização Rápida do Cluster AI"

    local ACTIVATE_SCRIPT="${PROJECT_ROOT}/scripts/deployment/activate_server.sh"
    local NETWORK_SCRIPT="${PROJECT_ROOT}/scripts/management/network_discovery.sh"
    local SETUP_MONITOR_SCRIPT="${PROJECT_ROOT}/scripts/deployment/setup_monitor_service.sh"

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
    subsection "Passo 3: Configurando Monitoramento Contínuo"
    if [ -f "$SETUP_MONITOR_SCRIPT" ]; then
        progress "Configurando serviço de monitoramento em background..."
        info "Será solicitada a senha de superusuário (sudo) para instalar o serviço."
        sudo bash "$SETUP_MONITOR_SCRIPT"
    fi
}

# Mostra status detalhado
show_detailed_status() {
    display_cluster_status "detailed"
}

# Executa testes
run_tests() {
    section "Executando Testes"

    if ! file_exists "scripts/validation/run_tests.sh"; then
        error "Script de testes não encontrado: scripts/validation/run_tests.sh"
        return 1
    fi

    progress "Executando suíte de testes..."
    bash scripts/validation/run_tests.sh
}

# Mostra diagnóstico
show_diagnostics() {
    section "Diagnóstico do Sistema"

    subsection "Verificações Básicas"

    # Python
    if command_exists python3; then
        success "Python 3: $(python3 --version)"
    else
        error "Python 3: Não encontrado"
    fi

    # Pip
    if command_exists pip; then
        success "Pip: $(pip --version | cut -d' ' -f1-2)"
    else
        error "Pip: Não encontrado"
    fi

    # Docker
    if command_exists docker; then
        success "Docker: $(docker --version)"
    else
        error "Docker: Não encontrado"
    fi

    # Ambiente virtual
    if dir_exists ".venv"; then
        success "Ambiente Virtual: OK"
    else
        warn "Ambiente Virtual: Não encontrado"
    fi

    # Configuração
    if file_exists "$CONFIG_FILE"; then
        success "Configuração: OK"
    else
        error "Configuração: Não encontrada"
    fi

    echo
    subsection "Recomendações"

    if ! dir_exists ".venv"; then
        info "• Execute ./install.sh para configurar o ambiente"
    fi

    if ! file_exists "$CONFIG_FILE"; then
        info "• Execute ./install.sh para criar a configuração"
    fi

    if ! command_exists docker; then
        info "• Instale Docker para funcionalidades completas"
    fi
}

# Resolvedor de conectividade de workers
resolve_worker_connectivity() {
    section "🔗 Resolvedor de Conectividade de Workers"

    local resolver_script="${SCRIPT_DIR}/scripts/management/worker_connectivity_resolver.sh"

    if ! file_exists "$resolver_script"; then
        error "Script do resolvedor não encontrado: $resolver_script"
        info "Verifique se o arquivo existe ou execute a instalação completa"
        return 1
    fi

    info "Iniciando resolvedor de conectividade de workers..."
    info "Este utilitário ajuda a diagnosticar e resolver problemas de conectividade com workers"
    echo

    # Executa o script do resolvedor
    bash "$resolver_script"
}

# Mostra ajuda
show_help() {
    section "Ajuda do Gerenciador"

    echo "Uso: ./manager.sh [comando]"
    echo
    echo "Comandos disponíveis:"
    echo "  start      - Inicia todos os serviços do cluster"
    echo "  stop       - Para todos os serviços do cluster"
    echo "  restart    - Reinicia todos os serviços do cluster"
    echo "  status     - Mostra status detalhado do cluster"
    echo "  test       - Executa testes do sistema"
    echo "  quick-start - Ativa servidor, descobre nós e configura monitoramento"
    echo "  diag       - Mostra diagnóstico do sistema"
    echo "  logs       - Visualiza logs do sistema"
    echo "  monitor    - Sistema de monitoramento central"
    echo "  optimize   - Otimizador de performance"
    echo "  vscode     - Gerenciador VSCode"
    echo "  update     - Atualização automática"
    echo "  security   - Ferramentas de segurança"
    echo "  help       - Mostra esta ajuda"
    echo
    echo "Exemplos:"
    echo "  ./manager.sh start"
    echo "  ./manager.sh monitor dashboard"
    echo "  ./manager.sh optimize"
    echo "  ./manager.sh vscode status"
    echo
}

# Sistema de monitoramento central
start_monitor() {
    section "Sistema de Monitoramento Central"

    local monitor_script="${SCRIPT_DIR}/scripts/monitoring/central_monitor.sh"

    if ! file_exists "$monitor_script"; then
        error "Script de monitoramento não encontrado: $monitor_script"
        return 1
    fi

    info "Iniciando sistema de monitoramento..."
    bash "$monitor_script" "$@"
}

# Otimizador de performance
run_optimizer() {
    section "Otimizador de Performance"

    local optimizer_script="${SCRIPT_DIR}/scripts/optimization/performance_optimizer.sh"

    if ! file_exists "$optimizer_script"; then
        error "Script otimizador não encontrado: $optimizer_script"
        return 1
    fi

    info "Executando otimizações de performance..."
    bash "$optimizer_script"
}

# Gerenciador VSCode
manage_vscode() {
    section "Gerenciador VSCode"

    local vscode_script="${SCRIPT_DIR}/scripts/maintenance/vscode_manager.sh"

    if ! file_exists "$vscode_script"; then
        error "Script VSCode não encontrado: $vscode_script"
        return 1
    fi

    info "Iniciando gerenciador VSCode..."
    bash "$vscode_script" "$@"
}

# Atualização automática
run_updater() {
    section "Atualização Automática"

    local updater_script="${SCRIPT_DIR}/scripts/maintenance/auto_updater.sh"

    if ! file_exists "$updater_script"; then
        error "Script de atualização não encontrado: $updater_script"
        return 1
    fi

    info "Iniciando atualização automática..."
    bash "$updater_script"
}

# Ferramentas de segurança
manage_security() {
    section "Ferramentas de Segurança"

    echo "Ferramentas de Segurança Disponíveis:"
    echo "1) Gerenciador de Autenticação"
    echo "2) Gerenciador de Firewall"
    echo "3) Logger de Segurança"
    echo "0) Voltar"
    echo

    read -p "Digite sua opção: " option

    case $option in
        1)
            local auth_script="${SCRIPT_DIR}/scripts/security/auth_manager.sh"
            if file_exists "$auth_script"; then
                bash "$auth_script" "$@"
            else
                error "Script de autenticação não encontrado"
            fi
            ;;
        2)
            local firewall_script="${SCRIPT_DIR}/scripts/security/firewall_manager.sh"
            if file_exists "$firewall_script"; then
                bash "$firewall_script" "$@"
            else
                error "Script de firewall não encontrado"
            fi
            ;;
        3)
            local logger_script="${SCRIPT_DIR}/scripts/security/security_logger.sh"
            if file_exists "$logger_script"; then
                bash "$logger_script" "$@"
            else
                error "Script de logger não encontrado"
            fi
            ;;
        0)
            return
            ;;
        *)
            error "Opção inválida"
            ;;
    esac
}

# Executa o linter de qualidade de código
run_linter() {
    section "🔎 Verificador de Qualidade de Código (Linter)"

    local linter_script="${SCRIPT_DIR}/scripts/maintenance/run_linter.sh"

    if ! file_exists "$linter_script"; then
        error "Script do linter não encontrado: $linter_script"
        return 1
    fi

    info "Executando o linter para Shell e Python..."
    bash "$linter_script"
}

# Gerencia backups e restaurações
manage_backup_restore() {
    section "💾 Gerenciador de Backup e Restauração"
    local verify_script="${SCRIPT_DIR}/scripts/maintenance/verify_backup.sh"
    local backup_script="${SCRIPT_DIR}/scripts/maintenance/backup_manager.sh"
    local restore_script="${SCRIPT_DIR}/scripts/maintenance/restore_manager.sh"

    if ! file_exists "$backup_script" || ! file_exists "$restore_script"; then
        error "Scripts de backup/restauração não encontrados."
        info "Verifique em 'scripts/maintenance/'"
        return 1
    fi

    while true; do
        subsection "Menu de Backup e Restauração"
        echo "1) Realizar um novo Backup"
        echo "2) Restaurar de um Backup"
        echo "3) Listar Backups existentes"
        echo "4) Limpar Backups antigos"
        echo "5) Verificar Integridade de um Backup"
        echo "0) Voltar ao menu principal"
        echo

        read -p "Digite sua opção: " choice

        case $choice in
            1)
                subsection "Tipo de Backup"
                echo "1) Backup Completo (config, modelos, docker)"
                echo "2) Apenas Configurações"
                echo "3) Apenas Modelos Ollama"
                echo "4) Apenas Dados Docker"
                echo "0) Cancelar"
                read -p "Escolha o tipo de backup: " backup_type_choice
                local backup_type=""
                case $backup_type_choice in
                    1) backup_type="full" ;;
                    2) backup_type="config" ;;
                    3) backup_type="models" ;;
                    4) backup_type="docker-data" ;;
                    0) continue ;;
                    *) error "Opção inválida."; continue ;;
                esac

                if [[ -n "$backup_type" ]]; then
                    local encrypt_arg=""
                    if confirm_operation "Deseja criptografar este backup com uma senha?"; then
                        encrypt_arg="--encrypt"
                    fi
                    bash "$backup_script" "$backup_type" "$encrypt_arg"
                fi
                ;;
            2)
                bash "$restore_script"
                ;;
            3)
                bash "$backup_script" list
                ;;
            4)
                bash "$backup_script" cleanup
                ;;
            5)
                bash "$verify_script"
                ;;
            0) return ;;
            *) error "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}
# =============================================================================
# MENUS E INTERFACE DO USUÁRIO
# =============================================================================

show_cluster_operations_menu() {
    while true; do
        clear; section "🚀 Gerenciamento do Cluster"
        echo "1) ▶️  Iniciar TODOS os serviços do cluster"
        echo "2) ⏹️  Parar TODOS os serviços do cluster"
        echo "3) 🔄 Reiniciar TODOS os serviços do cluster"
        echo "4) 📈 Status Detalhado do Cluster"
        echo "5) ⚡ Quick-Start (Ativa servidor, descobre nós e configura monitor)"
        echo "0) ↩️  Voltar ao Menu Principal"
        echo
        read -p "Sua opção: " sub_choice
        case $sub_choice in
            1) start_cluster ;;
            2) stop_cluster ;;
            3) restart_cluster ;;
            4) show_detailed_status ;;
            5) quick_start_cluster ;;
            0) return ;;
            *) error "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

show_worker_management_menu() {
    while true; do
        clear; section "🌐 Gerenciamento de Workers"
        echo "1) 👨‍💻 Gerenciar Workers Remotos (SSH)"
        echo "2) 🤖 Gerenciar Workers Registrados Automaticamente"
        echo "3) 📡 Descobrir Novos Workers na Rede"
        echo "4) 🔗 Resolvedor de Conectividade de Workers"
        echo "5) 🩺 Health Check de um Worker Específico"
        echo "5) 📱 Instruções para Configurar Worker Android (Termux)"
        echo "0) ↩️  Voltar ao Menu Principal"
        echo
        read -p "Sua opção: " sub_choice
        case $sub_choice in
            1) manage_remote_workers ;;
            2) manage_auto_registered_workers ;;  # Now uses function from workers.sh module
            3) bash "${SCRIPT_DIR}/scripts/management/network_discovery.sh" ;;
            4) resolve_worker_connectivity ;;
            5) run_worker_health_check ;;
            6) show_android_setup_instructions ;;
            0) return ;;
            *) error "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

show_maintenance_menu() {
    while true; do
        clear; section "🛠️ Manutenção e Diagnóstico"
        echo "1) 🩺 Diagnóstico Rápido do Sistema"
        echo "2) ✅ Executar Testes de Validação"
        echo "3) 💾 Gerenciar Backup e Restauração"
        echo "4) 📜 Visualizar Logs do Sistema"
        echo "5) 🔎 Verificador de Qualidade de Código (Linter)"
        echo "6) 🧽 Limpar Todos os Logs"
        echo "7) 🗄️ Arquivar Logs Atuais"
        echo "0) ↩️  Voltar ao Menu Principal"
        echo
        read -p "Sua opção: " sub_choice
        case $sub_choice in
            1) show_diagnostics ;;
            2) run_tests ;;
            3) manage_backup_restore ;;
            4) view_system_logs ;;
            5) run_linter ;;
            6) clear_all_logs ;;
            7) archive_logs ;;
            0) return ;;
            *) error "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

show_config_tools_menu() {
    while true; do
        clear; section "⚙️ Configuração e Ferramentas"
        echo "1) 🚀 Otimizador de Performance"
        echo "2) 🛡️  Ferramentas de Segurança"
        echo "3) 💻 Gerenciador VSCode"
        echo "4) ⏰ Gerenciar Tarefas Agendadas (Cron)"
        echo "5) 🔄 Atualização Automática do Projeto"
        echo "0) ↩️  Voltar ao Menu Principal"
        echo
        read -p "Sua opção: " sub_choice
        case $sub_choice in
            1) run_optimizer ;;
            2) manage_security ;;
            3) manage_vscode ;;
            4) setup_cron_job ;;
            5) run_updater ;;
            0) return ;;
            *) error "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

show_info_help_menu() {
    while true; do
        clear; section "ℹ️ Informações e Ajuda"
        echo "1) 🖥️  Informações do Sistema"
        echo "2) ❓ Ajuda (Comandos da Linha de Comando)"
        echo "0) ↩️  Voltar ao Menu Principal"
        echo
        read -p "Sua opção: " sub_choice
        case $sub_choice in
            1) show_system_info_submenu ;;
            2) show_help ;;
            0) return ;;
            *) error "Opção inválida." ;;
        esac
        # A função show_system_info_submenu já tem sua própria pausa
        if [[ "$sub_choice" != "1" ]]; then
            read -p "Pressione Enter para continuar..."
        fi
    done
}

# Menu principal unificado
show_main_menu() {
    subsection "Menu Principal"
    echo "1) 🚀 Gerenciamento do Cluster (Iniciar, Parar, Status)"
    echo "2) 🌐 Gerenciamento de Workers (Adicionar, Descobrir, Conectar)"
    echo "3) 🛠️  Manutenção e Diagnóstico (Logs, Testes, Backups)"
    echo "4) ⚙️  Configuração e Ferramentas (Otimizador, Segurança, Atualizações)"
    echo "5) ℹ️  Informações e Ajuda"
    echo
    echo "0) ❌ Sair"
    echo
}

# Função para atualizar o cache de status em background
refresh_status_cache() {
    local cache_updater_script="${PROJECT_ROOT}/scripts/utils/update_status_cache.sh"
    if [ -f "$cache_updater_script" ]; then
        info "🔄 Atualizando status do cluster em background..."
        # Executa em background para não bloquear o menu
        bash "$cache_updater_script" &
    fi
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Verificar autorização do usuário antes de qualquer operação
    if ! check_user_authorization; then
        exit 1
    fi

    audit_log "MANAGER_START" "User: $(whoami), Args: $@"

    # Análise de argumentos para modos especiais como --quiet
    if [[ "${1:-}" == "--quiet" || "${1:-}" == "-q" ]]; then
        # Redefine as funções de log para suprimir a saída, exceto erros.
        # A função 'error' de common.sh continuará a funcionar pois não é sobrescrita.
        info() { :; }
        log() { :; }
        success() { :; }
        warn() { :; }
        progress() { :; }
        section() { :; }
        subsection() { :; }
        show_banner() { :; }

        # Remove a flag para que o resto do script não a processe
        shift
    fi

    # Processa argumentos da linha de comando
    case "${1:-}" in
        start)
            start_cluster
            exit 0
            ;;
        stop)
            stop_cluster
            exit 0
            ;;
        restart)
            restart_cluster
            exit 0
            ;;
        quick-start|quickstart)
            quick_start_cluster
            exit 0
            ;;
        status|--status)
            show_detailed_status
            exit 0
            ;;
        check-workers|workers-status)
            check_all_workers_status
            exit 0
            ;;
        test)
            run_tests
            exit 0
            ;;
        diag)
            show_diagnostics
            exit 0
            ;;
        monitor)
            shift
            start_monitor "$@"
            exit 0
            ;;
        optimize)
            run_optimizer
            exit 0
            ;;
        vscode)
            shift
            manage_vscode "$@"
            exit 0
            ;;
        update)
            run_updater
            exit 0
            ;;
        lint|linter)
            run_linter
            exit 0
            ;;
        security)
            manage_security "$@"
            exit 0
            ;;
        cleanup)
            shift # remove 'cleanup'
            run_cleanup
            exit 0
            ;;
        cleanup-logs)
            clear_all_logs
            exit 0
            ;;
        archive-logs)
            shift # remove 'archive-logs'
            archive_logs "$@"
            exit 0
            ;;
        setup-cron)
            # Renamed to manage_cron_jobs internally
            setup_cron_job
            exit 0
            ;;
        backup)
            manage_backup_restore
            exit 0
            ;;
        logs)
            view_system_logs
            exit 0
            ;;
        help|--help|-h)
            show_help
            exit 0
            ;;
    esac

    # Menu interativo
    while true; do
        clear
        # Atualiza o cache na primeira vez que o menu é exibido
        [ ! -f "${PROJECT_ROOT}/run/status.cache" ] && refresh_status_cache && sleep 2

        show_banner
        display_cluster_status "simple"
        show_main_menu

        read -p "Digite sua opção (0-5): " choice

        case $choice in
            1)
                show_cluster_operations_menu
                ;;
            2)
                show_worker_management_menu
                ;;
            3)
                show_maintenance_menu
                ;;
            4)
                show_config_tools_menu
                ;;
            5)
                show_info_help_menu
                ;;
            "r"|"R")
                refresh_status_cache
                info "Atualização de status iniciada."
                sleep 2
                ;;
            0)
                success "Gerenciador encerrado."
                exit 0
                ;;
            *)
                error "Opção inválida."
                sleep 2
                ;;
        esac

        # Pausa para o usuário ver a saída, a menos que a opção seja sair
        if [[ "$choice" != "0" ]]; then
            echo
            read -p "Pressione Enter para voltar ao menu principal..."
        fi
    done
}

# Instala dependências essenciais como openssl e pv
install_dependencies() {
    section "🧩 Verificador e Instalador de Dependências"

    local deps_to_check=("openssl" "pv")
    local missing_deps=()

    subsection "Verificando dependências..."
    for dep in "${deps_to_check[@]}"; do
        if ! command_exists "$dep"; then
            warn "Dependência não encontrada: $dep"
            missing_deps+=("$dep")
        else
            success "Dependência encontrada: $dep"
        fi
    done

    if [ ${#missing_deps[@]} -eq 0 ]; then
        success "Todas as dependências essenciais já estão instaladas."
        return 0
    fi

    info "As seguintes dependências estão faltando: ${missing_deps[*]}"
    if ! confirm_operation "Deseja tentar instalá-las agora?"; then
        warn "Instalação cancelada."
        return 1
    fi

    local pm; pm=$(detect_package_manager)
    if [ -z "$pm" ]; then
        error "Não foi possível detectar o gerenciador de pacotes do seu sistema."
        info "Por favor, instale as dependências manualmente: sudo <pm> install ${missing_deps[*]}"
        return 1
    fi

    log "Usando '$pm' para instalar..."
    if sudo "$pm" install -y "${missing_deps[@]}"; then
        success "Dependências instaladas com sucesso!"
    else
        error "Falha ao instalar uma ou mais dependências."
        info "Tente instalar manualmente: sudo $pm install -y ${missing_deps[*]}"
        return 1
    fi
}

# Limpa um arquivo de log específico
clear_specific_log() {
    subsection "Limpar Log Específico"
    echo "Qual log você deseja limpar (esvaziar)?"
    echo "1) Log de Ativação do Servidor (server_activation.log)"
    echo "2) Log do Cluster Dask (dask_cluster.log)"
    echo "3) Log de Limpeza Automática (cron_cleanup.log)"
    echo "0) Cancelar"
    echo

    read -p "Digite sua opção: " clear_choice

    local log_to_clear=""
    case $clear_choice in
        1) log_to_clear="${PROJECT_ROOT}/logs/server_activation.log" ;;
        2) log_to_clear="${PROJECT_ROOT}/logs/dask_cluster.log" ;;
        3) log_to_clear="${PROJECT_ROOT}/logs/cron_cleanup.log" ;;
        0) return ;;
        *) error "Opção inválida."; return 1 ;;
    esac

    if [ ! -f "$log_to_clear" ]; then
        error "Arquivo de log não encontrado: $log_to_clear"
        return 1
    fi

    warn "Esta ação irá esvaziar o conteúdo de '$(basename "$log_to_clear")'."
    warn "O arquivo não será removido, apenas seu conteúdo."
    if confirm_operation "Você tem certeza?"; then
        > "$log_to_clear"
        success "Log '$(basename "$log_to_clear")' foi limpo com sucesso."
    else
        info "Operação de limpeza cancelada."
    fi
}

# Agenda a limpeza automática de logs usando cron
# Agora é um menu para gerenciar todas as tarefas agendadas
setup_cron_job() {
    if ! command_exists crontab; then
        error "Comando 'crontab' não encontrado. Não é possível agendar tarefas."
        info "Instale o cliente cron do seu sistema (ex: sudo apt install cron)."
        return 1
    fi

    while true; do
        section "🗓️ Gerenciador de Tarefas Agendadas (Cron)"
        echo "1) Agendar Arquivamento Semanal de Logs (Recomendado)"
        echo "2) Agendar Limpeza Semanal de Logs"
        echo "3) Remover Tarefa Agendada"
        echo "4) Ver Tarefas Agendadas do Cluster AI"
        echo "0) Voltar"
        echo
        read -p "Digite sua opção: " choice

        case $choice in
            1)
                local archive_cmd="cd \"${PROJECT_ROOT}\" && ./manager.sh archive-logs --force >> \"${PROJECT_ROOT}/logs/cron_cleanup.log\" 2>&1"
                local archive_schedule="0 3 * * 0" # Domingo às 3h
                add_cron_job "Arquivamento Semanal de Logs" "$archive_cmd" "$archive_schedule"
                ;;
            2)
                local cleanup_cmd="cd \"${PROJECT_ROOT}\" && ./manager.sh cleanup-logs --force >> \"${PROJECT_ROOT}/logs/cron_cleanup.log\" 2>&1"
                local cleanup_schedule="0 4 * * 0" # Domingo às 4h
                add_cron_job "Limpeza Semanal de Logs" "$cleanup_cmd" "$cleanup_schedule"
                ;;
            3)
                remove_cron_job
                ;;
            4)
                view_cron_jobs
                ;;
            0) return ;;
            *) error "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

# Função auxiliar para adicionar uma tarefa ao cron
add_cron_job() {
    local job_name="$1"
    local cron_command="$2"
    local cron_schedule="$3"
    local cron_job="${cron_schedule} ${cron_command}"

    subsection "Agendando: $job_name"

    if crontab -l 2>/dev/null | grep -qF -- "$cron_command"; then
        success "A tarefa '$job_name' já está agendada."
        return
    fi

    if ! confirm_operation "Deseja adicionar a tarefa '$job_name' ao seu agendador?"; then
        info "Agendamento cancelado."
        return
    fi

    (crontab -l 2>/dev/null; echo "# Tarefa do Cluster AI: $job_name"; echo "$cron_job") | crontab -

    if crontab -l | grep -qF -- "$cron_command"; then
        success "🎉 Tarefa '$job_name' agendada com sucesso!"
    else
        error "Falha ao agendar a tarefa '$job_name'."
    fi
}

# Função auxiliar para remover uma tarefa do cron
remove_cron_job() {
    subsection "Removendo Tarefa Agendada"
    local cron_jobs
    mapfile -t cron_jobs < <(crontab -l 2>/dev/null | grep 'Cluster AI')

    if [ ${#cron_jobs[@]} -eq 0 ]; then
        warn "Nenhuma tarefa do Cluster AI encontrada para remover."
        return
    fi

    info "Selecione a tarefa para remover:"
    select job in "${cron_jobs[@]}" "Cancelar"; do
        if [[ "$job" == "Cancelar" ]]; then
            info "Remoção cancelada."
            break
        elif [ -n "$job" ]; then
            (crontab -l | grep -vF "$job") | crontab -
            success "Tarefa removida com sucesso."
            break
        else
            error "Seleção inválida."
        fi
    done
}

# Função para visualizar tarefas agendadas
view_cron_jobs() {
    subsection "Tarefas Agendadas do Cluster AI"
    if ! crontab -l 2>/dev/null | grep -q 'Cluster AI'; then
        warn "Nenhuma tarefa do Cluster AI agendada."
    else
        crontab -l | grep --color=always -E 'Cluster AI|$'
    fi
}

# Limpa todos os arquivos de log
clear_all_logs() {
    local force_mode=false
    if [[ "$1" == "--force" ]]; then
        force_mode=true
    fi

    section "🧽 Limpeza de Todos os Logs"
    local log_dir="${PROJECT_ROOT}/logs"

    if [ ! -d "$log_dir" ]; then
        warn "Diretório de logs não encontrado em '$log_dir'."
        return 1
    fi

    # Usar find para ser mais robusto com nomes de arquivos
    local log_files
    mapfile -t log_files < <(find "$log_dir" -maxdepth 1 -type f -name "*.log")

    if [ ${#log_files[@]} -eq 0 ]; then
        success "Nenhum arquivo .log para limpar em '$log_dir'."
        return 0
    fi

    info "Os seguintes arquivos de log serão ESVAZIADOS (não removidos):"
    for file in "${log_files[@]}"; do
        echo "  - $(basename "$file") ($(du -h "$file" | cut -f1))"
    done
    echo

    if [[ "$force_mode" == true ]] || confirm_operation "Você tem certeza que deseja limpar todos esses logs?"; then
        progress "Limpando logs..."
        for file in "${log_files[@]}"; do
            > "$file"
        done
        success "Todos os arquivos de log foram limpos."
    else
        info "Operação de limpeza cancelada."
    fi
}

# Arquiva e limpa todos os arquivos de log
archive_logs() {
    local force_mode=false
    if [[ "$1" == "--force" ]]; then
        force_mode=true
    fi

    section "🗄️ Arquivamento de Logs"
    local log_dir="${PROJECT_ROOT}/logs"
    local backup_dir="${PROJECT_ROOT}/backups"
    mkdir -p "$backup_dir"

    if [ ! -d "$log_dir" ]; then
        warn "Diretório de logs não encontrado em '$log_dir'."
        return 1
    fi

    local log_files
    mapfile -t log_files < <(find "$log_dir" -maxdepth 1 -type f -name "*.log")

    if [ ${#log_files[@]} -eq 0 ]; then
        success "Nenhum arquivo .log para arquivar em '$log_dir'."
        return 0
    fi

    local archive_name="logs_archive_$(date +%Y-%m-%d_%H%M%S).tar.gz"
    local archive_path="${backup_dir}/${archive_name}"

    info "Os seguintes arquivos de log serão arquivados e depois limpos:"
    for file in "${log_files[@]}"; do
        echo "  - $(basename "$file") ($(du -h "$file" | cut -f1))"
    done
    echo
    info "O arquivo de arquivamento será salvo em: ${backup_dir}/${archive_name}"

    if [[ "$force_mode" == true ]] || confirm_operation "Você tem certeza que deseja arquivar e limpar esses logs?"; then
        progress "Criando arquivo de arquivamento..."
        if tar -czf "$archive_path" -C "$log_dir" $(for file in "${log_files[@]}"; do echo "$(basename "$file")"; done); then
            success "Arquivo de arquivamento criado com sucesso: $archive_path"
            progress "Limpando arquivos de log originais..."
            for file in "${log_files[@]}"; do > "$file"; done
            success "Arquivos de log originais foram limpos."
        else
            error "Falha ao criar o arquivo de arquivamento. Os logs não foram limpos."
        fi
    else
        info "Operação de arquivamento cancelada."
    fi
}

# Visualiza logs do sistema
view_system_logs() {
    section "📋 Visualizador de Logs do Sistema"

    while true; do
        subsection "Selecione o log que deseja visualizar"
        echo "1) Log de Ativação do Servidor (server_activation.log)"
        echo "2) 🚀 Log Principal do Cluster Dask (dask_cluster.log)"
        echo "3) Log do Ollama (via journalctl ou docker)"
        echo "4) Log do OpenWebUI (via docker)"
        echo "5) Log de Limpeza Automática (cron_cleanup.log)"
        echo "6) Logs do Nginx (access.log e error.log)"
        echo "7) 🛡️  Log de Auditoria (audit.log)"
        echo
        echo "8) 🧽 Limpar um log específico"
        echo "0) Voltar ao menu principal"
        echo

        read -p "Digite sua opção: " choice

        local log_file=""
        local log_cmd=""

        case $choice in
            1) log_file="${PROJECT_ROOT}/logs/server_activation.log" ;;
            2) log_file="${PROJECT_ROOT}/logs/dask_cluster.log" ;; # Log principal do Dask
            3)
                if command_exists journalctl && sudo journalctl -u ollama -n 1 >/dev/null 2>&1; then
                    log_cmd="sudo journalctl -u ollama -f -n 200"
                elif command_exists docker && docker ps -q --filter "name=ollama" | grep -q .; then
                    log_cmd="docker logs -f ollama"
                else
                    error "Não foi possível encontrar os logs do Ollama (nem via journalctl, nem via Docker)."
                fi
                ;;
            4)
                if command_exists docker && docker ps -q --filter "name=open-webui" | grep -q .; then
                    log_cmd="docker logs -f open-webui"
                else
                    error "Container Docker 'open-webui' não encontrado ou não está em execução."
                fi
                ;;
            5) log_file="${PROJECT_ROOT}/logs/cron_cleanup.log" ;;
            6)
                info "O Nginx possui dois logs principais. Qual deseja ver?"
                echo "1) access.log (requisições)"
                echo "2) error.log (erros)"
                read -p "Escolha [1-2]: " nginx_choice
                if [[ "$nginx_choice" == "1" ]]; then
                    log_file="/var/log/nginx/access.log"
                elif [[ "$nginx_choice" == "2" ]]; then
                    log_file="/var/log/nginx/error.log"
                fi
                log_cmd="sudo tail -f -n 200 $log_file"
                ;;
            7)
                log_file="${PROJECT_ROOT}/logs/audit.log"
                # Usar 'less' para logs de auditoria, pois permite navegar facilmente
                log_cmd="less -R $log_file"
                ;;
            8) clear_specific_log; continue ;;
            0) return ;;
            *) error "Opção inválida."; continue ;;
        esac

        if [ -n "$log_file" ] && [ ! -f "$log_file" ]; then
            error "Arquivo de log não encontrado: $log_file"
        elif [ -n "$log_file" ] && [ -z "$log_cmd" ]; then
            log_cmd="tail -f -n 200 $log_file"
        fi

        if [ -n "$log_cmd" ]; then
            if [[ "$log_cmd" == tail* ]]; then
                info "Pressione CTRL+C para parar de visualizar o log."
            else
                info "Pressione 'q' para sair do visualizador de log."
        fi
            sleep 2
            (set -x; $log_cmd)
        fi
        read -p "Pressione Enter para continuar..."
    done
}

# Função test_worker_connection_interactive() removida - usar test_worker_connectivity() do módulo workers.sh
# =============================================================================
# FUNÇÃO PARA GERENCIAR WORKERS REMOTOS (AGORA VIA MÓDULOS CORE)
# =============================================================================
# Função manage_remote_workers() removida - usar função equivalente do módulo workers.sh

# =============================================================================
# FUNÇÃO PARA INSTRUÇÕES DO WORKER ANDROID
# =============================================================================

show_android_setup_instructions() {
    section "Instruções para Configurar Worker Android (Termux)"

    info "Este processo automatiza a configuração do seu dispositivo Android como um worker."
    echo
    echo "PASSO 1: No seu dispositivo Android, abra o aplicativo Termux."
    echo
    echo "PASSO 2: Copie e cole o comando abaixo no Termux e pressione Enter."
    echo "         Este comando fará o download e executará o script de configuração automática."
    echo
    echo -e "${YELLOW}--------------------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker.sh | bash${NC}"
    echo -e "${YELLOW}--------------------------------------------------------------------------------${NC}"
    echo
    echo "PASSO 3: Siga as instruções no Termux."
    echo "         Ao final, o script exibirá a ${GREEN}chave SSH pública${NC} e o ${GREEN}IP${NC} do seu dispositivo."
    echo
    echo "PASSO 4: Volte para este menu e use a opção 'Gerenciar Workers Remotos (SSH)' para"
    echo "         adicionar o novo worker usando as informações fornecidas pelo script."
    echo
    success "Após esses passos, seu worker Android estará pronto para ser usado!"
}

# =============================================================================
# FUNÇÃO PARA GERENCIAR WORKERS REGISTRADOS AUTOMATICAMENTE
# =============================================================================

# =============================================================================
# FUNÇÃO PARA GERENCIAR WORKERS REGISTRADOS AUTOMATICAMENTE (AGORA VIA MÓDULOS CORE)
# =============================================================================
# Função manage_auto_registered_workers() removida - usar função equivalente do módulo workers.sh

# EXECUÇÃO
# =============================================================================

main "$@"
