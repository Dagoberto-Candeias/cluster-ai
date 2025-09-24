#!/bin/bash
# Painel de Controle do Cluster AI - Versão Modular
#
# Este script serve como o ponto central para gerenciar todos os serviços
# do ecossistema Cluster AI, incluindo Ollama, Dask e OpenWebUI.
# Gerencia serviços, executa verificações e otimizações.

set -euo pipefail  # Modo estrito: para em erros, variáveis não definidas e falhas em pipelines

# =============================================================================
# INICIALIZAÇÃO E CARREGAMENTO DE MÓDULOS
# =============================================================================

# Este bloco deve vir antes de qualquer definição de função que use os módulos.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
CONFIG_FILE="${PROJECT_ROOT}/cluster.yaml"
PID_DIR="${PROJECT_ROOT}/.pids"

# Carregar módulos na ordem correta (common primeiro)
COMMON_SCRIPT="${SCRIPT_DIR}/scripts/lib/common.sh"
if [ -f "$COMMON_SCRIPT" ]; then
    # shellcheck source=scripts/lib/common.sh
    source "$COMMON_SCRIPT"
else
    # Usando echo aqui pois a função 'error' pode não estar carregada ainda.
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado em '$COMMON_SCRIPT'"
    echo "Verifique se o arquivo existe e se o script manager.sh está sendo executado da raiz do projeto."
    exit 1
done

# Funções de compatibilidade para interface (apelidos)
# As funções já existem em common.sh, então não precisamos redefini-las

# =============================================================================
# FUNÇÕES PRINCIPAIS DO CLUSTER
# =============================================================================

start_cluster() {
    section "INICIANDO CLUSTER AI"

    # Verificar se o usuário está autorizado
    check_user_authorization || {
        error "Acesso negado. Execute o script como usuário autorizado."
        exit 1
    }

    # Verificar se já está rodando
    if pgrep -f "dask-scheduler" > /dev/null; then
        warn "Cluster já está rodando"
        return 0
    fi

    local dask_starter_script="${PROJECT_ROOT}/config/start_dask_cluster.py"
    if [ ! -f "$dask_starter_script" ]; then
        error "Falha ao iniciar: script '${dask_starter_script}' não encontrado."
        error "Verifique a integridade da instalação do projeto."
        return 1
    fi

    # Garante que o diretório de PIDs exista
    mkdir -p "$PID_DIR"

    # Iniciar o Dask LocalCluster (scheduler + workers) em segundo plano
    info "Iniciando Dask LocalCluster (Scheduler + Workers)..."
    # O script python entra em loop, então o executamos em background (&)
    # e redirecionamos a saída para um arquivo de log.
    if nohup python3 "$dask_starter_script" "$PROJECT_ROOT" > "logs/dask_cluster.log" 2>&1 & then
        echo $! > "${PID_DIR}/dask_cluster.pid"
        sleep 2 # Aguarda um momento para o cluster iniciar
        success "Cluster Dask iniciado em segundo plano. Logs em 'logs/dask_cluster.log'."
    else
        error "Falha ao iniciar o cluster Dask."
        return 1
    fi

    # Iniciar serviços web
    info "Iniciando serviços web..."
    if bash scripts/start_cluster_complete_fixed.sh; then
        success "Serviços web iniciados"
    else
        warn "Falha ao iniciar alguns serviços web"
    fi

    success "Cluster AI iniciado com sucesso!"
}

stop_cluster() {
    section "PARANDO CLUSTER AI"

    local dask_pid_file="${PID_DIR}/dask_cluster.pid"
    if [ -f "$dask_pid_file" ]; then
        local pid
        pid=$(cat "$dask_pid_file")
        if ps -p "$pid" > /dev/null; then
            info "Parando processo do Cluster Dask (PID: $pid)..."
            # Envia o sinal de término (SIGTERM), permitindo um encerramento gracioso
            kill "$pid"
            
            # Aguarda até 10 segundos para o processo terminar
            local count=0
            while ps -p "$pid" > /dev/null; do
                if [ $count -ge 10 ]; then
                    warn "Processo $pid não respondeu ao SIGTERM. Forçando (SIGKILL)..."
                    kill -9 "$pid"
                    break
                fi
                sleep 1
                ((count++))
            done
            
            success "Cluster Dask parado."
        else
            info "PID do Dask encontrado, mas o processo não está rodando."
        fi
        rm -f "$dask_pid_file"
    else
        warn "Nenhum arquivo de PID para o Dask encontrado. O cluster pode já estar parado."
        # Fallback para pkill como último recurso, caso o PID tenha se perdido
        pkill -f "dask-scheduler" || true
        pkill -f "dask-worker" || true
    fi

    # Parar serviços web
    info "Parando serviços web..."
    # Assumindo que este script gerencia seu próprio PID ou usa um método seguro
    bash scripts/web_server.sh stop

    success "Cluster AI parado com sucesso!"
}

restart_cluster() {
    section "REINICIANDO CLUSTER AI"

    stop_cluster
    sleep 2
    start_cluster

    success "Cluster AI reiniciado com sucesso!"
}

run_tests() {
    section "EXECUTANDO TESTES"

    if python3 -m pytest tests/ -v --tb=short; then
        success "Todos os testes passaram!"
    else
        error "Alguns testes falharam"
        return 1
    fi
}

show_help() {
    echo -e "${BOLD}${CYAN}CLUSTER AI MANAGER - AJUDA${NC}"
    echo -e "${BOLD}Uso:${NC} $0 [comando]"
    echo
    echo -e "${BOLD}Comandos disponíveis:${NC}"
    echo -e "  ${GREEN}start${NC}          Iniciar cluster"
    echo -e "  ${GREEN}stop${NC}           Parar cluster"
    echo -e "  ${GREEN}restart${NC}        Reiniciar cluster"
    echo -e "  ${GREEN}status${NC}         Mostrar status detalhado"
    echo -e "  ${GREEN}test${NC}           Executar testes"
    echo -e "  ${GREEN}diag${NC}           Mostrar diagnóstico"
    echo -e "  ${GREEN}logs${NC}           Visualizar logs do sistema"
    echo -e "  ${GREEN}worker${NC}         Gerenciar workers (use 'worker help' para subcomandos)"
    echo -e "  ${GREEN}system${NC}         Manutenção do sistema (use 'system help' para subcomandos)"
    echo -e "  ${GREEN}models${NC}         Gerenciar modelos Ollama (use 'models help' para subcomandos)"
    echo -e "  ${GREEN}help${NC}           Mostrar esta ajuda geral"
    echo
    echo -e "${BOLD}Exemplo:${NC} $0 start"
}

# =============================================================================
# FUNÇÕES DE VERIFICAÇÃO DE SAÚDE (DELEGADAS)
# =============================================================================

run_health_checks() {
    local health_checker_script="${SCRIPT_DIR}/scripts/management/health_checker.sh"
    if [ ! -f "$health_checker_script" ]; then
        error "Script do verificador de saúde não encontrado em $health_checker_script"
        return 1
    fi
    bash "$health_checker_script" "$@"
}

# =============================================================================
# FUNÇÕES DE MONITORAMENTO E ATUALIZAÇÃO DE WORKERS
# =============================================================================

manage_workers() {
    local worker_manager_script="${SCRIPT_DIR}/scripts/management/worker_manager.sh"
    if [ ! -f "$worker_manager_script" ]; then
        error "Script do gerenciador de workers não encontrado em $worker_manager_script"
        return 1
    fi

    local sub_command="${1:-help}"
    # Lista de subcomandos válidos para o worker_manager.sh
    local valid_commands=("add" "remove" "list" "start-monitor" "stop-monitor" "status-monitor" "update-all" "help")

    # Verifica se o subcomando é válido
    if ! printf '%s\n' "${valid_commands[@]}" | grep -q -w "$sub_command"; then
        error "Subcomando de worker inválido: '$sub_command'"
        # Mostra a ajuda do worker_manager.sh
        bash "$worker_manager_script" "help"
        return 1
    fi

    local sub_command="${1:-help}"
    # Lista de subcomandos válidos para o worker_manager.sh
    local valid_commands=("add" "remove" "list" "start-monitor" "stop-monitor" "status-monitor" "update-all" "help")

    # Verifica se o subcomando é válido
    if ! printf '%s\n' "${valid_commands[@]}" | grep -q -w "$sub_command"; then
        error "Subcomando de worker inválido: '$sub_command'"
        # Mostra a ajuda do worker_manager.sh
        bash "$worker_manager_script" "help"
        return 1
    fi

    # Passa todos os argumentos (exceto o primeiro 'worker') para o script
    bash "$worker_manager_script" "${@}"
}
# =============================================================================
# FUNÇÕES DE GERENCIAMENTO AVANÇADO (VSCODE, UPDATES, ETC.)
# =============================================================================

manage_system() {
    local system_manager_script="${SCRIPT_DIR}/scripts/management/system_manager.sh"
    if [ ! -f "$system_manager_script" ]; then
        error "Script do gerenciador de sistema não encontrado em $system_manager_script"
        return 1
    fi

    local sub_command="${1:-help}"
    # Lista de subcomandos válidos para o system_manager.sh
    local valid_commands=("vscode" "update" "optimize" "security" "help")

    # Verifica se o subcomando é válido
    if ! printf '%s\n' "${valid_commands[@]}" | grep -q -w "$sub_command"; then
        error "Subcomando de sistema inválido: '$sub_command'"
        # Mostra a ajuda do system_manager.sh
        bash "$system_manager_script" "help"
        return 1
    fi

    local sub_command="${1:-help}"
    # Lista de subcomandos válidos para o system_manager.sh
    local valid_commands=("vscode" "update" "optimize" "security" "help")

    # Verifica se o subcomando é válido
    if ! printf '%s\n' "${valid_commands[@]}" | grep -q -w "$sub_command"; then
        error "Subcomando de sistema inválido: '$sub_command'"
        # Mostra a ajuda do system_manager.sh
        bash "$system_manager_script" "help"
        return 1
    fi

    # Passa todos os argumentos (exceto o primeiro 'system') para o script
    bash "$system_manager_script" "${@}"
}

manage_models() {
    local model_manager_script="${SCRIPT_DIR}/scripts/management/model_manager.sh"
    if [ ! -f "$model_manager_script" ]; then
        error "Script do gerenciador de modelos não encontrado em '$model_manager_script'"
        return 1
    fi

    local sub_command="${1:-help}"
    # Lista de subcomandos válidos para o model_manager.sh
    local valid_commands=("install" "remove" "help")

    # Verifica se o subcomando é válido
    if ! printf '%s\n' "${valid_commands[@]}" | grep -q -w "$sub_command"; then
        error "Subcomando de modelos inválido: '$sub_command'"
        # Mostra a ajuda do model_manager.sh
        bash "$model_manager_script" "help"
        return 1
    fi

    local sub_command="${1:-help}"
    # Lista de subcomandos válidos para o model_manager.sh
    local valid_commands=("install" "remove" "help")

    # Verifica se o subcomando é válido
    if ! printf '%s\n' "${valid_commands[@]}" | grep -q -w "$sub_command"; then
        error "Subcomando de modelos inválido: '$sub_command'"
        # Mostra a ajuda do model_manager.sh
        bash "$model_manager_script" "help"
        return 1
    fi

    # Passa todos os argumentos (exceto o primeiro 'models') para o script
    bash "$model_manager_script" "${@}"
}


# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

show_interactive_menu() {
    if ! command -v whiptail > /dev/null; then
        error "O comando 'whiptail' é necessário para o menu interativo, mas não foi encontrado."
        info "Para instalar, use: sudo apt-get install whiptail (Debian/Ubuntu) ou sudo dnf install newt (Fedora/CentOS)."
        exit 1
    fi

    local menu_script="${SCRIPT_DIR}/scripts/ui/interactive_menu.sh"
    if [ ! -f "$menu_script" ]; then
        error "Script do menu interativo não encontrado em '$menu_script'."
        exit 1
    fi
    bash "$menu_script"
}

main() {
    # Se nenhum argumento for passado, inicia o menu interativo
    if [ $# -eq 0 ]; then
        show_interactive_menu
        return
    fi

    # Processa argumentos da linha de comando
    case "${1:-help}" in
        start)
            start_cluster
            ;;
        stop)
            stop_cluster
            ;;
        restart)
            restart_cluster
            ;;
        status)
            run_health_checks status
            ;;
        test)
            run_tests
            ;;
        diag)
            run_health_checks diag
            ;;
        logs)
            run_health_checks logs
            ;;
        worker)
            shift # Remove 'worker'
            manage_workers "$@"
            ;;
        system)
            shift # Remove 'system'
            manage_system "$@"
            ;;
        models)
            shift # Remove 'models'
            manage_models "$@"
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Comando inválido: '$1'"
            show_help
            exit 1
            ;;
    esac
}

# EXECUÇÃO
# =============================================================================

# Finalmente, executa a função principal, passando todos os argumentos
main "$@"
