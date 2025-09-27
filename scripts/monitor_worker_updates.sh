#!/bin/bash
# =============================================================================
# Sistema de Monitoramento de Atualizações - Cluster AI
# =============================================================================
# Monitora continuamente mudanças no projeto e atualiza workers automaticamente
#
# Autor: Cluster AI Team
# Data: 2025-01-20
# Versão: 1.0.0
# Arquivo: monitor_worker_updates.sh
# =============================================================================

set -euo pipefail

# --- Configuração Inicial ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Carregar funções comuns
if [ ! -f "${SCRIPT_DIR}/lib/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${SCRIPT_DIR}/lib/common.sh"

# Carregar configuração
UPDATE_CONFIG="${PROJECT_ROOT}/config/update.conf"
if [ ! -f "$UPDATE_CONFIG" ]; then
    error "Arquivo de configuração não encontrado: $UPDATE_CONFIG"
    exit 1
fi

# --- Constantes ---
LOG_DIR="${PROJECT_ROOT}/logs"
MONITOR_LOG="${LOG_DIR}/monitor_updates.log"
PID_FILE="${PROJECT_ROOT}/.monitor_updates_pid"

# Criar diretórios necessários
mkdir -p "$LOG_DIR"

# --- Funções ---

# Função para log detalhado
log_monitor() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" >> "$MONITOR_LOG"

    case "$level" in
        "INFO")
            info "$message" ;;
        "WARN")
            warn "$message" ;;
        "ERROR")
            error "$message" ;;
    esac
}

# Função para obter configuração
get_update_config() {
    local default="${3:-}"
    get_config_value "$1" "$2" "$UPDATE_CONFIG" "$default"
}

# Função para verificar se o monitor já está rodando
check_already_running() {
    if [[ -f "$PID_FILE" ]]; then
        local existing_pid
        existing_pid=$(cat "$PID_FILE")

        if ps -p "$existing_pid" >/dev/null 2>&1; then
            log_monitor "WARN" "Monitor já está rodando com PID: $existing_pid"
            return 0
        else
            log_monitor "INFO" "Removendo PID file obsoleto"
            rm -f "$PID_FILE"
        fi
    fi

    return 1
}

# Função para salvar PID
save_pid() {
    echo $$ > "$PID_FILE"
    log_monitor "DEBUG" "PID salvo: $$"
}

# Função para remover PID
remove_pid() {
    if [[ -f "$PID_FILE" ]]; then
        rm -f "$PID_FILE"
        log_monitor "DEBUG" "PID file removido"
    fi
}

# Função para verificar atualizações
check_updates() {
    log_monitor "INFO" "Verificando atualizações..."

    # Executar verificação
    if bash "${SCRIPT_DIR}/../update_checker.sh" >/dev/null 2>&1; then
        log_monitor "DEBUG" "Verificação de atualizações concluída"

        # Verificar se há atualizações disponíveis
        if [[ -f "${PROJECT_ROOT}/logs/update_status.json" ]]; then
            local has_updates
            has_updates=$(jq -r '.updates_available' "${PROJECT_ROOT}/logs/update_status.json" 2>/dev/null || echo "false")

            if [[ "$has_updates" == "true" ]]; then
                log_monitor "INFO" "Atualizações disponíveis detectadas"

                # Obter lista de componentes
                local components
                components=$(jq -r '.components[].type' "${PROJECT_ROOT}/logs/update_status.json" 2>/dev/null || echo "")

                if [[ -n "$components" ]]; then
                    log_monitor "INFO" "Componentes com atualizações: $components"
                    return 0
                fi
            else
                log_monitor "DEBUG" "Nenhuma atualização disponível"
            fi
        fi
    else
        log_monitor "ERROR" "Falha na verificação de atualizações"
    fi

    return 1
}

# Função para notificar sobre atualizações
notify_updates() {
    log_monitor "INFO" "Notificando sobre atualizações disponíveis..."

    if [[ "$(get_update_config "GENERAL" "AUTO_NOTIFY")" == "true" ]]; then
        # Mostrar notificação no sistema
        if command_exists notify-send; then
            notify-send "Cluster AI" "Atualizações disponíveis para o sistema" -i info
        fi

        # Log da notificação
        log_monitor "INFO" "Notificação enviada sobre atualizações disponíveis"
    fi
}

# Função para sincronizar com workers
sync_with_workers() {
    log_monitor "INFO" "Sincronizando com workers..."

    if [[ "$(get_update_config "WORKERS" "WORKER_SYNC_ENABLED")" != "true" ]]; then
        log_monitor "DEBUG" "Sincronização com workers desabilitada"
        return 0
    fi

    # TODO: Implementar sincronização específica com workers
    # Por enquanto, apenas log
    log_monitor "DEBUG" "Sincronização com workers não implementada"
    return 0
}

# Função para aplicar atualizações automáticas
apply_auto_updates() {
    log_monitor "INFO" "Verificando atualizações automáticas..."

    # Verificar se há atualizações
    if ! check_updates; then
        return 0
    fi

    # Obter componentes que podem ser atualizados automaticamente
    local auto_components=()

    # Verificar política de cada componente
    if [[ -f "${PROJECT_ROOT}/logs/update_status.json" ]]; then
        jq -r '.components[] | select(.type == "git") | .type' "${PROJECT_ROOT}/logs/update_status.json" 2>/dev/null | while read -r component; do
            if [[ "$component" == "git" ]]; then
                local policy
                policy=$(get_update_config "REPOSITORY" "GIT_UPDATE_POLICY")
                if [[ "$policy" == "auto" ]]; then
                    auto_components+=("$component")
                fi
            fi
        done

        jq -r '.components[] | select(.type == "docker") | "\(.type):\(.container)"' "${PROJECT_ROOT}/logs/update_status.json" 2>/dev/null | while read -r component; do
            if [[ -n "$component" ]]; then
                local container
                IFS=':' read -r _ container <<< "$component"
                local policy
                policy=$(get_update_config "DOCKER" "DOCKER_UPDATE_POLICY")
                if [[ "$policy" == "auto" ]]; then
                    auto_components+=("$component")
                fi
            fi
        done

        jq -r '.components[] | select(.type == "system") | .type' "${PROJECT_ROOT}/logs/update_status.json" 2>/dev/null | while read -r component; do
            if [[ "$component" == "system" ]]; then
                local policy
                policy=$(get_update_config "SYSTEM" "SYSTEM_UPDATE_POLICY")
                if [[ "$policy" == "auto" ]]; then
                    auto_components+=("$component")
                fi
            fi
        done

        jq -r '.components[] | select(.type == "model") | "\(.type):\(.name)"' "${PROJECT_ROOT}/logs/update_status.json" 2>/dev/null | while read -r component; do
            if [[ -n "$component" ]]; then
                local policy
                policy=$(get_update_config "MODELS" "MODELS_UPDATE_POLICY")
                if [[ "$policy" == "auto" ]]; then
                    auto_components+=("$component")
                fi
            fi
        done
    fi

    # Aplicar atualizações automáticas
    if [[ ${#auto_components[@]} -gt 0 ]]; then
        log_monitor "INFO" "Aplicando ${#auto_components[@]} atualizações automáticas..."

        if bash "${SCRIPT_DIR}/auto_updater.sh" "${auto_components[@]}" 2>/dev/null; then
            log_monitor "INFO" "Atualizações automáticas aplicadas com sucesso"
            return 0
        else
            log_monitor "ERROR" "Falha ao aplicar atualizações automáticas"
            return 1
        fi
    else
        log_monitor "DEBUG" "Nenhuma atualização automática para aplicar"
        return 0
    fi
}

# Função para o loop principal de monitoramento
monitor_loop() {
    local check_interval
    check_interval=$(get_update_config "GENERAL" "CHECK_INTERVAL")

    log_monitor "INFO" "Iniciando monitoramento com intervalo de ${check_interval} minutos"

    local cycle_count=0

    while true; do
        ((cycle_count++))

        log_monitor "DEBUG" "Ciclo de monitoramento #$cycle_count"

        # Verificar atualizações
        if check_updates; then
            # Notificar sobre atualizações
            notify_updates

            # Aplicar atualizações automáticas
            apply_auto_updates

            # Sincronizar com workers
            sync_with_workers
        fi

        # Aguardar próximo ciclo
        log_monitor "DEBUG" "Aguardando ${check_interval} minutos para próximo ciclo"
        sleep $((check_interval * 60))
    done
}

# Função para tratamento de sinais
signal_handler() {
    local signal="$1"
    log_monitor "INFO" "Recebido sinal $signal, encerrando monitoramento..."
    remove_pid
    exit 0
}

# Função para iniciar monitoramento
start_monitoring() {
    log_monitor "INFO" "Iniciando sistema de monitoramento de atualizações..."

    # Verificar se já está rodando
    if check_already_running; then
        error "Monitor já está rodando"
        exit 1
    fi

    # Salvar PID
    save_pid

    # Configurar tratamento de sinais
    trap 'signal_handler INT' INT
    trap 'signal_handler TERM' TERM
    trap 'signal_handler HUP' HUP

    # Iniciar loop de monitoramento
    monitor_loop
}

# Função para parar monitoramento
stop_monitoring() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")

        if ps -p "$pid" >/dev/null 2>&1; then
            log_monitor "INFO" "Parando monitoramento (PID: $pid)..."
            kill "$pid"

            # Aguardar término
            local count=0
            while ps -p "$pid" >/dev/null 2>&1 && [[ $count -lt 10 ]]; do
                sleep 1
                ((count++))
            done

            if ps -p "$pid" >/dev/null 2>&1; then
                log_monitor "WARN" "Processo não respondeu, forçando término..."
                kill -9 "$pid" 2>/dev/null || true
            fi

            remove_pid
            success "Monitoramento parado com sucesso"
        else
            warn "Processo de monitoramento não encontrado"
            remove_pid
        fi
    else
        warn "Arquivo PID não encontrado - monitoramento pode não estar rodando"
    fi
}

# Função para status do monitoramento
status_monitoring() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")

        if ps -p "$pid" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} ${BOLD}Monitoramento rodando${NC} (PID: $pid)"
            echo -e "${GRAY}Log: $MONITOR_LOG${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠${NC} ${BOLD}Monitoramento não está rodando${NC} (PID file obsoleto)"
            remove_pid
            return 1
        fi
    else
        echo -e "${RED}✗${NC} ${BOLD}Monitoramento não está rodando${NC}"
        return 1
    fi
}

# Função principal
main() {
    # Verificar argumentos
    case "${1:-status}" in
        "start")
            start_monitoring
            ;;
        "stop")
            stop_monitoring
            ;;
        "restart")
            stop_monitoring
            sleep 2
            start_monitoring
            ;;
        "status")
            status_monitoring
            ;;
        "check")
            check_updates
            ;;
        *)
            echo "Uso: $0 [start|stop|restart|status|check]"
            echo
            echo "Comandos:"
            echo "  start   - Iniciar monitoramento"
            echo "  stop    - Parar monitoramento"
            echo "  restart - Reiniciar monitoramento"
            echo "  status  - Verificar status"
            echo "  check   - Verificar atualizações manualmente"
            exit 1
            ;;
    esac
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
