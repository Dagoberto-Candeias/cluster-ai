#!/bin/bash
# Script para reiniciar serviços do Cluster AI
# Gerencia todos os serviços relacionados ao sistema

set -euo pipefail

# =============================================================================
# CONFIGURAÇÃO
# =============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_FILE="${PROJECT_ROOT}/logs/service_restart_$(date +%Y%m%d_%H%M%S).log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =============================================================================
# FUNÇÕES UTILITÁRIAS
# =============================================================================

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${CYAN}ℹ️  $1${NC}" | tee -a "$LOG_FILE"
}

# =============================================================================
# VERIFICAÇÃO DE SERVIÇOS
# =============================================================================

check_service_status() {
    local service_name="$1"
    local pid_file="${PROJECT_ROOT}/pids/${service_name}.pid"

    if [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "running"
            return 0
        else
            echo "dead"
            return 1
        fi
    else
        echo "not_running"
        return 1
    fi
}

# =============================================================================
# GERENCIAMENTO DE SERVIÇOS
# =============================================================================

stop_service() {
    local service_name="$1"
    local pid_file="${PROJECT_ROOT}/pids/${service_name}.pid"
    local max_wait=30
    local wait_count=0

    log "Parando serviço: $service_name"

    # Verificar se o serviço está rodando
    local status
    status=$(check_service_status "$service_name")

    if [ "$status" = "not_running" ]; then
        info "Serviço $service_name já está parado"
        return 0
    fi

    # Enviar sinal SIGTERM
    if [ -f "$pid_file" ]; then
        local pid
        pid=$(cat "$pid_file")
        kill -TERM "$pid" 2>/dev/null || true

        # Aguardar até o processo terminar
        while [ $wait_count -lt $max_wait ]; do
            if ! kill -0 "$pid" 2>/dev/null; then
                success "Serviço $service_name parado com sucesso"
                rm -f "$pid_file"
                return 0
            fi
            sleep 1
            ((wait_count++))
        done

        # Se ainda estiver rodando, forçar parada
        warning "Serviço $service_name não respondeu ao SIGTERM, enviando SIGKILL"
        kill -KILL "$pid" 2>/dev/null || true
        sleep 2

        if kill -0 "$pid" 2>/dev/null; then
            error "Falha ao parar serviço $service_name"
            return 1
        else
            success "Serviço $service_name forçado a parar"
            rm -f "$pid_file"
            return 0
        fi
    else
        warning "Arquivo PID não encontrado para $service_name"
        return 0
    fi
}

start_service() {
    local service_name="$1"
    local start_command="$2"
    local pid_file="${PROJECT_ROOT}/pids/${service_name}.pid"

    log "Iniciando serviço: $service_name"

    # Criar diretório de PIDs se não existir
    mkdir -p "${PROJECT_ROOT}/pids"

    # Verificar se já está rodando
    local status
    status=$(check_service_status "$service_name")

    if [ "$status" = "running" ]; then
        info "Serviço $service_name já está rodando"
        return 0
    fi

    # Iniciar serviço em background
    cd "$PROJECT_ROOT"
    eval "$start_command" &
    local pid=$!

    # Aguardar um pouco para o serviço iniciar
    sleep 2

    # Verificar se iniciou corretamente
    if kill -0 "$pid" 2>/dev/null; then
        echo "$pid" > "$pid_file"
        success "Serviço $service_name iniciado (PID: $pid)"
        return 0
    else
        error "Falha ao iniciar serviço $service_name"
        return 1
    fi
}

restart_service() {
    local service_name="$1"
    local start_command="$2"

    log "Reiniciando serviço: $service_name"

    # Parar serviço
    if ! stop_service "$service_name"; then
        error "Falha ao parar serviço $service_name para reinício"
        return 1
    fi

    # Aguardar um pouco
    sleep 2

    # Iniciar serviço
    if ! start_service "$service_name" "$start_command"; then
        error "Falha ao reiniciar serviço $service_name"
        return 1
    fi

    success "Serviço $service_name reiniciado com sucesso"
}

# =============================================================================
# SERVIÇOS ESPECÍFICOS
# =============================================================================

restart_monitor_service() {
    log "Reiniciando serviço de monitoramento..."

    # Parar processos relacionados ao monitoramento
    pkill -f "central_monitor.sh" || true
    pkill -f "monitor.*--daemon" || true

    # Aguardar
    sleep 2

    # Iniciar monitoramento em background
    if [ -x "${PROJECT_ROOT}/scripts/monitoring/central_monitor.sh" ]; then
        bash "${PROJECT_ROOT}/scripts/monitoring/central_monitor.sh" --daemon &
        local monitor_pid=$!
        echo "$monitor_pid" > "${PROJECT_ROOT}/pids/monitor.pid"
        success "Serviço de monitoramento reiniciado (PID: $monitor_pid)"
    else
        warning "Script de monitoramento não encontrado ou não executável"
    fi
}

restart_vscode_service() {
    log "Reiniciando serviço VSCode..."

    # Parar processos VSCode relacionados
    pkill -f "start_vscode_optimized.sh" || true
    pkill -f "vscode.*--daemon" || true

    # Aguardar
    sleep 2

    # Iniciar VSCode otimizado se disponível
    if [ -x "${PROJECT_ROOT}/scripts/maintenance/start_vscode_optimized.sh" ]; then
        bash "${PROJECT_ROOT}/scripts/maintenance/start_vscode_optimized.sh" &
        local vscode_pid=$!
        echo "$vscode_pid" > "${PROJECT_ROOT}/pids/vscode.pid"
        success "Serviço VSCode reiniciado (PID: $vscode_pid)"
    else
        info "Serviço VSCode não configurado para inicialização automática"
    fi
}

restart_update_service() {
    log "Reiniciando serviço de atualização..."

    # Parar processos de atualização
    pkill -f "auto_updater.sh" || true
    pkill -f "update.*--daemon" || true

    # Aguardar
    sleep 2

    # O serviço de atualização geralmente é executado sob demanda
    info "Serviço de atualização configurado para execução sob demanda"
}

restart_security_service() {
    log "Reiniciando serviços de segurança..."

    # Parar processos de segurança
    pkill -f "security_logger.sh" || true
    pkill -f "firewall_manager.sh" || true

    # Aguardar
    sleep 2

    # Reiniciar logger de segurança se disponível
    if [ -x "${PROJECT_ROOT}/scripts/security/security_logger.sh" ]; then
        bash "${PROJECT_ROOT}/scripts/security/security_logger.sh" --daemon &
        local security_pid=$!
        echo "$security_pid" > "${PROJECT_ROOT}/pids/security.pid"
        success "Serviço de segurança reiniciado (PID: $security_pid)"
    else
        info "Serviço de segurança não configurado"
    fi
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    log "Iniciando reinício de serviços do Cluster AI"
    log "=========================================="
    log "Diretório: $PROJECT_ROOT"
    log "Data/Hora: $(date)"
    log ""

    # Criar diretório de logs se não existir
    mkdir -p "${PROJECT_ROOT}/logs"
    mkdir -p "${PROJECT_ROOT}/pids"

    # Lista de serviços para gerenciar
    local services=(
        "monitor_service:restart_monitor_service"
        "vscode_service:restart_vscode_service"
        "update_service:restart_update_service"
        "security_service:restart_security_service"
    )

    local success_count=0
    local total_services=${#services[@]}

    # Reiniciar cada serviço
    for service_info in "${services[@]}"; do
        IFS=':' read -r service_name service_function <<< "$service_info"

        log ""
        log "Processando serviço: $service_name"

        if $service_function; then
            ((success_count++))
        else
            warning "Falha ao reiniciar serviço: $service_name"
        fi
    done

    # Verificar status final
    log ""
    log "=== STATUS FINAL DOS SERVIÇOS ==="
    log "Serviços processados: $total_services"
    log "Sucessos: $success_count"
    log "Falhas: $((total_services - success_count))"

    if [ $success_count -eq $total_services ]; then
        success "Todos os serviços reiniciados com sucesso"
        exit 0
    else
        warning "Alguns serviços falharam ao reiniciar"
        exit 1
    fi
}

# Executar
main "$@"
