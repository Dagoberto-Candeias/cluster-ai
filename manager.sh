#!/bin/bash
# Local: manager.sh
# Autor: Nome: Dagoberto Candeias. email: betoallnet@gmail.com telefone/whatsapp: +5511951754945

# =============================================================================
# Cluster AI - Gerenciador do Cluster
# =============================================================================
# Este é o painel de controle principal do Cluster AI. Permite iniciar,
# parar, configurar e monitorar todos os componentes do sistema.

set -e  # Para o script em caso de erro

# =============================================================================
# INICIALIZAÇÃO
# =============================================================================

# Carrega funções comuns
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR" # Assumindo que manager.sh está na raiz
source "${SCRIPT_DIR}/scripts/lib/common.sh"

# Função de log adicional (se não estiver definida em common.sh)
log() {
    echo -e "${CYAN}[LOG] $1${NC}"
}

# Função para solicitar confirmação do usuário
confirm_operation() {
    local message="$1"
    read -p "$(echo -e "${YELLOW}AVISO:${NC} $message Deseja continuar? (s/N) ")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        return 0
    else
        return 1
    fi
}
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

# Exibe status do cluster
show_status() {
    section "Status do Cluster"

    # Verifica se configuração existe
    if ! file_exists "$CONFIG_FILE"; then
        warn "Arquivo de configuração não encontrado: $CONFIG_FILE"
        info "Execute ./install.sh primeiro"
        return 1
    fi

    # Carrega configurações usando a nova função
    DASK_SCHEDULER_PORT=$(get_config_value "dask" "scheduler_port" "$CONFIG_FILE" "8786")
    DASK_DASHBOARD_PORT=$(get_config_value "dask" "dashboard_port" "$CONFIG_FILE" "8787")
    OLLAMA_PORT=$(get_config_value "services" "ollama_port" "$CONFIG_FILE" "11434")
    OPENWEBUI_PORT=$(get_config_value "services" "openwebui_port" "$CONFIG_FILE" "3000")

    info "Configurações carregadas do formato INI."

    # Status dos serviços
    echo "🔍 Verificando serviços..."
    echo

    # Docker
    if command_exists docker && docker info >/dev/null 2>&1; then
        success "🐳 Docker: Ativo"
    else
        error "🐳 Docker: Inativo"
    fi

    # Dask Scheduler
    if is_port_open "$DASK_SCHEDULER_PORT"; then
        success "📊 Dask Scheduler: Ativo (porta $DASK_SCHEDULER_PORT)"
    else
        warn "📊 Dask Scheduler: Inativo"
    fi

    # Dask Dashboard
    if is_port_open "$DASK_DASHBOARD_PORT"; then
        success "📈 Dask Dashboard: Ativo (porta $DASK_DASHBOARD_PORT)"
    else
        warn "📈 Dask Dashboard: Inativo"
    fi

    # Ollama
    if is_port_open "$OLLAMA_PORT"; then
        success "🧠 Ollama: Ativo (porta $OLLAMA_PORT)"
    else
        warn "🧠 Ollama: Inativo"
    fi

    # OpenWebUI
    if is_port_open "$OPENWEBUI_PORT"; then
        success "🌐 OpenWebUI: Ativo (porta $OPENWEBUI_PORT)"
    else
        warn "🌐 OpenWebUI: Inativo"
    fi

    # Nginx
    if command_exists nginx && pgrep nginx >/dev/null; then
        success "🌐 Nginx: Ativo"
    else
        warn "🌐 Nginx: Inativo"
    fi

    echo
    info "Para mais detalhes, use: ./manager.sh status"
}

# Menu principal
show_menu() {
    subsection "Menu Principal"

    echo "Escolha uma operação:"
    echo -e "\n${CYAN}🚀 OPERAÇÕES DO CLUSTER${NC}"
    echo " 1) ▶️  Iniciar Cluster"
    echo " 2) ⏹️  Parar Cluster"
    echo " 3) 🔄 Reiniciar Cluster"
    echo " 4) 📈 Status Detalhado do Cluster"
    
    echo -e "\n${YELLOW}🔧 MANUTENÇÃO & DIAGNÓSTICO${NC}"
    echo " 5) 🧹 Limpeza de Arquivos (Logs, PIDs)"
    echo " 6)  Visualizar Logs do Sistema"
    echo " 7) 🔄 Atualizar Sistema (Git Pull)"
    echo " 8) 🧪 Executar Testes & Diagnóstico"
    echo " 9) 💾 Backup e Restauração"
    echo "10) 🗓️  Agendar Limpeza Automática (Cron)"
    echo "11) 🧩 Instalar Dependências (openssl, pv)"

    echo -e "\n${PURPLE}⚙️ CONFIGURAÇÃO & FERRAMENTAS${NC}"
    echo "12)  Configurar Workers (Remoto/Android)"
    echo "13) 💻 Gerenciador VSCode"
    echo "14) 🔒 Ferramentas de Segurança"
    echo "15) ⚡ Otimizador de Performance"
    echo "16) 📊 Monitor Central"
    
    echo -e "\n${BLUE}📚 AJUDA${NC}"
    echo "17) 📚 Documentação (Em desenvolvimento)"
    echo
    echo "0) ❌ Sair"
    echo
}

# Inicia o cluster
start_cluster() {
    section "Iniciando Cluster AI"

    # Verifica configuração
    if ! file_exists "$CONFIG_FILE"; then
        error "Arquivo de configuração não encontrado"
        info "Execute ./install.sh primeiro"
        return 1
    fi

    # Carrega configurações usando a nova função
    DASK_SCHEDULER_PORT=$(get_config_value "dask" "scheduler_port" "$CONFIG_FILE" "8786")
    OLLAMA_PORT=$(get_config_value "services" "ollama_port" "$CONFIG_FILE" "11434")
    OPENWEBUI_PORT=$(get_config_value "services" "openwebui_port" "$CONFIG_FILE" "3000")


    # Inicia Docker se necessário
    if command_exists docker; then
        progress "Iniciando Docker..."
        sudo systemctl start docker 2>/dev/null || true
    fi

    # Inicia Dask
    progress "Iniciando Dask..."
    if ! is_port_open "$DASK_SCHEDULER_PORT"; then
        # Aqui seria o comando para iniciar Dask
        info "Dask scheduler seria iniciado na porta $DASK_SCHEDULER_PORT"
    fi

    # Inicia Ollama
    progress "Iniciando Ollama..."
    if ! is_port_open "$OLLAMA_PORT"; then
        # Aqui seria o comando para iniciar Ollama
        info "Ollama seria iniciado na porta $OLLAMA_PORT"
    fi

    # Inicia OpenWebUI
    progress "Iniciando OpenWebUI..."
    if ! is_port_open "$OPENWEBUI_PORT"; then
        # Aqui seria o comando para iniciar OpenWebUI
        info "OpenWebUI seria iniciado na porta $OPENWEBUI_PORT"
    fi

    # Inicia Nginx
    progress "Iniciando Nginx..."
    if command_exists nginx; then
        sudo systemctl start nginx 2>/dev/null || true
    fi

    success "Cluster iniciado com sucesso!"
    show_status
}

# Para um processo usando seu arquivo PID
# Uso: stop_process_by_pid <nome_serviço> <arquivo_pid>
stop_process_by_pid() {
    local service_name="$1"
    local pid_file="$2"

    if [ ! -f "$pid_file" ]; then
        info "$service_name não parece estar rodando (arquivo PID não encontrado)."
        return
    fi

    local pid
    pid=$(cat "$pid_file")

    if [ -z "$pid" ]; then
        warn "Arquivo PID para $service_name está vazio."
        rm -f "$pid_file"
        return
    fi

    # Verifica se o processo existe
    if ps -p "$pid" > /dev/null; then
        progress "Parando $service_name (PID: $pid)..."
        # Tenta parar de forma graciosa primeiro (SIGTERM)
        kill -15 "$pid"
        sleep 3

        # Se ainda estiver rodando, força a parada (SIGKILL)
        if ps -p "$pid" > /dev/null; then
            warn "$service_name não parou de forma graciosa. Forçando..."
            kill -9 "$pid"
            sleep 1
        fi
        success "$service_name parado."
    else
        info "$service_name (PID: $pid) já estava parado."
    fi

    rm -f "$pid_file"
}

# Para o cluster
stop_cluster() {
    section "Parando Cluster AI"

    info "Parando todos os serviços gerenciados..."

    # Para Dask Cluster usando seu PID
    stop_process_by_pid "Dask Cluster" "${PROJECT_ROOT}/run/dask.pid"

    # Para Nginx
    if command_exists nginx && pgrep nginx >/dev/null; then
        sudo systemctl stop nginx 2>/dev/null || true
        success "Nginx parado"
    fi

    # Para containers Docker
    if command_exists docker; then
        docker stop $(docker ps -q) 2>/dev/null || true
        success "Containers Docker parados"
    fi

    success "Cluster parado com sucesso!"
}

# Reinicia o cluster
restart_cluster() {
    section "Reiniciando Cluster AI"

    stop_cluster
    sleep 2
    start_cluster
}

# Mostra status detalhado
show_detailed_status() {
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

    # Status dos serviços
    subsection "Serviços"
    show_status
    echo

    # Recursos do sistema
    subsection "Recursos"
    echo "📊 Uso de CPU: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
    echo "🧠 Uso de RAM: $(free | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
    echo "💾 Uso de Disco: $(df -h . | awk 'NR==2{print $5}')"
    echo

    # Portas abertas
    subsection "Portas"
    if command_exists netstat; then
        netstat -tln | grep LISTEN | head -10
    elif command_exists ss; then
        ss -tln | grep LISTEN | head -10
    fi
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
                bash "$backup_script" "$backup_type"

                local encrypt_arg=""
                if confirm_operation "Deseja criptografar este backup com uma senha?"; then
                    encrypt_arg="--encrypt"
                fi
                bash "$backup_script" "$backup_type" "$encrypt_arg"
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
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
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
        status)
            show_detailed_status
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
        security)
            manage_security
            exit 0
            ;;
        cleanup)
            shift # remove 'cleanup'
            run_cleanup
            exit 0
            ;;
        setup-cron)
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
        show_banner
        show_status
        show_menu

        local choice
        read -p "Digite sua opção (0-17): " choice

        case $choice in
            1) start_cluster ;;
            2) stop_cluster ;;
            3) restart_cluster ;;
            4) show_detailed_status ;;
            5) run_cleanup ;;
            6) view_system_logs ;;
            7) run_updater ;;
            8) run_tests ;;
            9) manage_backup_restore ;;
            10) setup_cron_job ;;
            11) install_dependencies ;;
            12) configure_cluster ;;
            13) manage_vscode ;;
            14) manage_security ;;
            15) run_optimizer ;;
            16) start_monitor ;;
            17) warn "Documentação - Em desenvolvimento" ;;
            0)
                info "Gerenciador encerrado"
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

# Visualiza logs do sistema
view_system_logs() {
    section "📋 Visualizador de Logs do Sistema"

    while true; do
        subsection "Selecione o log que deseja visualizar"
        echo "1) Log de Ativação do Servidor (server_activation.log)"
        echo "2) Log do Cluster Dask (dask_cluster.log)"
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
            2) log_file="${PROJECT_ROOT}/logs/dask_cluster.log" ;;
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

# =============================================================================
# FUNÇÃO PARA GERENCIAR WORKERS REMOTOS (SSH)
# =============================================================================

manage_remote_workers() {
    section "Gerenciamento de Workers Remotos (SSH)"

    local config_file="$HOME/.cluster_config/nodes_list.conf"

    # Criar arquivo de configuração se não existir
    if [ ! -f "$config_file" ]; then
        mkdir -p "$HOME/.cluster_config"

cat > "$config_file" <<EOF
# =============================================================================
# Configuração de Workers Remotos para Cluster AI
# Formato: hostname IP user port status
# Exemplo: android-worker 192.168.1.100 u0_a249 8022 active

# Adicione seus workers remotos aqui:
EOF
        success "Arquivo de configuração criado: $config_file"
    fi

    while true; do
        echo
        echo "Workers Remotos - Menu:"
        echo "1) Listar Workers Configurados"
        echo "2) Adicionar Novo Worker"
        echo "3) Testar Conexão com Worker"
        echo "4) Remover Worker"
        echo "5) Atualizar Status dos Workers"
        echo "0) Voltar"
        echo

        read -p "Digite sua opção: " option

        case $option in
            1)
                # Listar workers
                section "Workers Configurados"
                if [ -s "$config_file" ] && grep -v '^#' "$config_file" | grep -q .; then
                    echo "Workers encontrados:"
                    echo
                    awk 'NR>1 && !/^#/ {print NR-1 ") " $1 " - " $2 ":" $4 " (" $3 ") - " ($5 ? $5 : "unknown")}' "$config_file"
                else
                    warn "Nenhum worker configurado ainda."
                    info "Use a opção 2 para adicionar um worker."
                fi
                ;;
            2)
                # Adicionar worker
                section "Adicionando Novo Worker"
                echo "Digite as informações do worker:"
                read -p "Nome do worker (ex: android-worker): " worker_name
                read -p "IP do worker: " worker_ip
                read -p "Usuário SSH: " worker_user
                # Forçar porta 22 para o worker Android
                if [[ "$worker_name" == "android-worker" ]]; then
                    worker_port=22
                    info "Porta SSH forçada para 22 para o worker Android"
                else
                    read -p "Porta SSH (padrão 22): " worker_port
                fi

                # Valores padrão
                worker_port=${worker_port:-22}
                worker_user=${worker_user:-$USER}

                # Opção para configurar chave SSH
                echo
                if confirm_operation "Deseja configurar autenticação SSH sem senha para este worker?"; then
                    echo "Para configurar a autenticação SSH sem senha, você precisa:"
                    echo "1) Ter a chave SSH pública do worker (gerada no Termux)"
                    echo "2) Adicionar esta chave ao authorized_keys do servidor"
                    echo
                    echo "Cole a chave SSH pública do worker abaixo (geralmente começa com 'ssh-rsa' ou 'ssh-ed25519'):"
                    echo "Ou pressione Enter se não tiver a chave agora."
                    read -p "Chave SSH pública: " ssh_key

                    if [ -n "$ssh_key" ]; then
                        # Adicionar chave ao authorized_keys
                        mkdir -p ~/.ssh
                        echo "$ssh_key" >> ~/.ssh/authorized_keys
                        chmod 600 ~/.ssh/authorized_keys
                        chmod 700 ~/.ssh
                        success "Chave SSH adicionada ao authorized_keys"
                        info "Agora você pode conectar ao worker sem senha"
                    else
                        warn "Chave SSH não fornecida. Você precisará configurar autenticação manualmente."
                    fi
                fi

                # Adicionar ao arquivo
                echo "$worker_name $worker_ip $worker_user $worker_port active" >> "$config_file"
                success "Worker '$worker_name' adicionado à configuração"
                ;;
            3)
                # Testar conexão
                section "Testando Conexão"
                if [ -s "$config_file" ] && grep -v '^#' "$config_file" | grep -q .; then
                    echo "Workers disponíveis:"
                    awk 'NR>1 && !/^#/ {print NR-1 ") " $1 " - " $2 ":" $4 " (" $3 ")"}' "$config_file"
                    echo
                    read -p "Digite o número do worker para testar: " worker_num

                    local worker_info=$(awk "NR==$((worker_num+1)) && !/^#/ {print \$1,\$2,\$3,\$4}" "$config_file")
                    if [ -n "$worker_info" ]; then
                        local name ip user port
                        read name ip user port <<< "$worker_info"
                        echo "Testando conexão com $name ($ip:$port)..."
                        info "Tentando conectar via SSH..."
                        log "DEBUG: IP=$ip, PORT=$port, USER=$user"

                        # Verifica se o IP é válido
                        if ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                            error "❌ IP inválido: $ip"
                            sed -i "s/^$name $ip $user $port .*/$name $ip $user $port inactive/" "$config_file"
                            return 1
                        fi

                        # Verifica conectividade básica (ping)
                        log "DEBUG: Testando conectividade básica com ping..."
                        if ping -c 1 -W 2 "$ip" >/dev/null 2>&1; then
                            success "✅ Ping para $ip: OK"
                        else
                            warn "⚠️  Ping para $ip falhou - pode ser bloqueado por firewall"
                        fi

                        # Verifica se a porta está aberta
                        log "DEBUG: Verificando se porta $port está aberta..."
                        if timeout 5 bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null; then
                            success "✅ Porta $port está aberta"
                        else
                            error "❌ Porta $port não está acessível"
                            warn "Verifique se o SSH está rodando no worker Android"
                            sed -i "s/^$name $ip $user $port .*/$name $ip $user $port inactive/" "$config_file"
                            return 1
                        fi

                        # Adiciona a chave do host ao known_hosts para segurança
                        log "DEBUG: Adicionando chave do host ao known_hosts..."
                        ssh-keyscan -p "$port" -H "$ip" >> ~/.ssh/known_hosts 2>/dev/null

                        # Testa conexão com timeout e opções mais seguras
                        log "DEBUG: Executando comando SSH..."
                        log "DEBUG: Comando: ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=15 -o BatchMode=yes -p $port $user@$ip 'echo SSH OK - Worker $name respondendo'"

                        ssh_output=$(ssh -o StrictHostKeyChecking=no \
                               -o UserKnownHostsFile=/dev/null \
                               -o ConnectTimeout=15 \
                               -o BatchMode=yes \
                               -p "$port" \
                               "$user@$ip" \
                               "echo 'SSH OK - Worker $name respondendo'" 2>&1)

                        ssh_exit_code=$?

                        log "DEBUG: Código de saída SSH: $ssh_exit_code"
                        log "DEBUG: Saída do SSH: $ssh_output"

                        if [ $ssh_exit_code -eq 0 ]; then
                            success "✅ Conexão SSH estabelecida com sucesso!"
                            success "Worker $name está acessível e funcionando"
                            info "Resposta do worker: $ssh_output"
                            # Atualizar status
                            sed -i "s/^$name $ip $user $port .*/$name $ip $user $port active/" "$config_file"
                        else
                            error "❌ Falha na conexão SSH com $name (código: $ssh_exit_code)"
                            warn "Saída do comando SSH:"
                            echo "$ssh_output" | while IFS= read -r line; do
                                warn "  $line"
                            done
                            warn "Possíveis causas:"
                            warn "  • Worker não está acessível no IP $ip:$port"
                            warn "  • SSH não está rodando no worker"
                            warn "  • Chave SSH não está configurada corretamente"
                            warn "  • Autenticação falhou (verifique usuário/senha)"
                            warn "  • Firewall bloqueando a conexão"
                            info "Verifique se o Termux está rodando e o SSH está ativo"
                            info "Tente: ssh -p $port $user@$ip"
                            # Atualizar status
                            sed -i "s/^$name $ip $user $port .*/$name $ip $user $port inactive/" "$config_file"
                        fi
                    else
                        error "Worker não encontrado"
                    fi
                else
                    warn "Nenhum worker configurado."
                fi
                ;;
            4)
                # Remover worker
                section "Removendo Worker"
                if [ -s "$config_file" ] && grep -v '^#' "$config_file" | grep -q .; then
                    echo "Workers disponíveis:"
                    awk 'NR>1 && !/^#/ {print NR-1 ") " $1 " - " $2 ":" $4 " (" $3 ")"}' "$config_file"
                    echo
                    read -p "Digite o número do worker para remover: " worker_num

                    local line_num=$((worker_num+1))
                    if [ $line_num -gt 1 ] && sed -n "${line_num}p" "$config_file" | grep -q .; then
                        local worker_name=$(sed -n "${line_num}p" "$config_file" | awk '{print $1}')
                        sed -i "${line_num}d" "$config_file"
                        success "Worker '$worker_name' removido"
                    else
                        error "Worker não encontrado"
                    fi
                else
                    warn "Nenhum worker configurado."
                fi
                ;;
            5)
                # Atualizar status
                section "Atualizando Status dos Workers"
                if [ -s "$config_file" ] && grep -v '^#' "$config_file" | grep -q .; then
                    log "Verificando status de todos os workers..."
                    local updated=0

                    while IFS= read -r line; do
                        if [[ $line =~ ^# ]] || [ -z "$line" ]; then
                            continue
                        fi

                        local name ip user port status
                        read name ip user port status <<< "$line"

                        # Adiciona a chave do host ao known_hosts para segurança
                        ssh-keyscan -p "$port" -H "$ip" >> ~/.ssh/known_hosts 2>/dev/null
                        if ssh -o StrictHostKeyChecking=no \
                               -o UserKnownHostsFile=/dev/null \
                               -o ConnectTimeout=10 \
                               -o BatchMode=yes \
                               -p "$port" \
                               "$user@$ip" \
                               "echo 'OK'" >/dev/null 2>&1; then
                            sed -i "s/^$name $ip $user $port .*/$name $ip $user $port active/" "$config_file"
                            ((updated++))
                        else
                            sed -i "s/^$name $ip $user $port .*/$name $ip $user $port inactive/" "$config_file"
                        fi
                    done < "$config_file"

                    success "Status atualizado para $updated workers"
                else
                    warn "Nenhum worker configurado."
                fi
                ;;
            0)
                return
                ;;
            *)
                error "Opção inválida"
                ;;
        esac

        echo
        read -p "Pressione Enter para continuar..."
    done
}

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
# FUNÇÃO PARA CONFIGURAR CLUSTER (IMPLEMENTAÇÃO DA OPÇÃO 7)
# =============================================================================

configure_cluster() {
    section "Configuração do Cluster"

    echo "Opções de Configuração:"
    echo "1) Gerenciar Workers Remotos (SSH)"
    echo "2) Configurar Worker Android (Termux)"
    echo "0) Voltar ao Menu Principal"
    echo

    read -p "Digite sua opção: " option

    case $option in
        1)
            manage_remote_workers
            ;;
        2)
            show_android_setup_instructions
            ;;
        0)
            return
            ;;
        *)
            error "Opção inválida."
            ;;
    esac

    echo
    read -p "Pressione Enter para continuar..."
    clear
}
# EXECUÇÃO
# =============================================================================

main "$@"
