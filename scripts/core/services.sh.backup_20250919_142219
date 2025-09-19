#!/bin/bash
# =============================================================================
# Cluster AI - Módulo de Gerenciamento de Serviços
# =============================================================================
# Este arquivo contém funções para gerenciamento de serviços systemd,
# containers Docker e outros serviços do sistema.

set -euo pipefail

# Carregar módulos dependentes
if [[ -z "${PROJECT_ROOT:-}" ]]; then
  PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
fi
source "${PROJECT_ROOT}/scripts/core/common.sh"
source "${PROJECT_ROOT}/scripts/core/security.sh"

# =============================================================================
# CONFIGURAÇÃO DE SERVIÇOS
# =============================================================================

# Serviços críticos que requerem confirmação extra
readonly CRITICAL_SERVICES=("sshd" "nginx" "docker" "firewalld" "ufw" "network" "systemd")
readonly DATABASE_SERVICES=("postgres" "mysql" "mongodb" "redis")

# =============================================================================
# GERENCIAMENTO DE SERVIÇOS SYSTEMD
# =============================================================================

# Gerenciar serviço systemd (start/stop/restart/status)
manage_systemd_service() {
    local action="$1"
    local service="$2"
    local quiet="${3:-false}"

    # Validar entrada
    if ! validate_service_name "$service"; then
        audit_log "INVALID_SERVICE_NAME" "ERROR" "Service: $service"
        return 1
    fi

    # Verificar se systemctl está disponível
    if ! command_exists systemctl; then
        audit_log "SYSTEMCTL_NOT_FOUND" "ERROR" "Attempted to manage service: $service"
        [[ "$quiet" != "true" ]] && error "systemctl não encontrado. Este sistema não usa systemd?"
        return 1
    fi

    # Determinar nível de risco
    local risk_level
    if [[ " ${CRITICAL_SERVICES[*]} " =~ " $service " ]]; then
        risk_level="$RISK_HIGH"
    elif [[ " ${DATABASE_SERVICES[*]} " =~ " $service " ]]; then
        risk_level="$RISK_HIGH"
    else
        risk_level="$RISK_MEDIUM"
    fi

    # Confirmar operação crítica
    if [[ "$quiet" != "true" ]]; then
        if ! confirm_critical_operation "Gerenciar serviço systemd: $action $service" "$risk_level" "Ação: $action, Serviço: $service"; then
            return 1
        fi
    fi

    audit_log "SYSTEMD_SERVICE_MANAGEMENT" "INFO" "Action: $action, Service: $service"

    case "$action" in
        start)
            systemd_service_start "$service" "$quiet"
            ;;
        stop)
            systemd_service_stop "$service" "$quiet"
            ;;
        restart)
            systemd_service_restart "$service" "$quiet"
            ;;
        status)
            systemd_service_status "$service" "$quiet"
            ;;
        enable)
            systemd_service_enable "$service" "$quiet"
            ;;
        disable)
            systemd_service_disable "$service" "$quiet"
            ;;
        *)
            [[ "$quiet" != "true" ]] && error "Ação inválida: $action"
            return 1
            ;;
    esac
}

# Iniciar serviço systemd
systemd_service_start() {
    local service="$1"
    local quiet="${2:-false}"

    if ! sudo systemctl is-active --quiet "$service" 2>/dev/null; then
        [[ "$quiet" != "true" ]] && progress "Iniciando serviço $service..."
        if sudo systemctl start "$service" 2>/dev/null; then
            [[ "$quiet" != "true" ]] && success "Serviço $service iniciado com sucesso"
            audit_log "SYSTEMD_SERVICE_STARTED" "SUCCESS" "Service: $service"
            return 0
        else
            [[ "$quiet" != "true" ]] && warn "Falha ao iniciar serviço $service. Pode não estar instalado."
            audit_log "SYSTEMD_SERVICE_START_FAILED" "WARNING" "Service: $service"
            return 1
        fi
    else
        [[ "$quiet" != "true" ]] && info "Serviço $service já está ativo"
        return 0
    fi
}

# Parar serviço systemd
systemd_service_stop() {
    local service="$1"
    local quiet="${2:-false}"

    if sudo systemctl is-active --quiet "$service" 2>/dev/null; then
        [[ "$quiet" != "true" ]] && progress "Parando serviço $service..."
        if sudo systemctl stop "$service" 2>/dev/null; then
            [[ "$quiet" != "true" ]] && success "Serviço $service parado com sucesso"
            audit_log "SYSTEMD_SERVICE_STOPPED" "SUCCESS" "Service: $service"
            return 0
        else
            [[ "$quiet" != "true" ]] && warn "Falha ao parar serviço $service"
            audit_log "SYSTEMD_SERVICE_STOP_FAILED" "WARNING" "Service: $service"
            return 1
        fi
    else
        [[ "$quiet" != "true" ]] && info "Serviço $service já está parado"
        return 0
    fi
}

# Reiniciar serviço systemd
systemd_service_restart() {
    local service="$1"
    local quiet="${2:-false}"

    [[ "$quiet" != "true" ]] && progress "Reiniciando serviço $service..."
    if sudo systemctl restart "$service" 2>/dev/null; then
        [[ "$quiet" != "true" ]] && success "Serviço $service reiniciado com sucesso"
        audit_log "SYSTEMD_SERVICE_RESTARTED" "SUCCESS" "Service: $service"
        return 0
    else
        [[ "$quiet" != "true" ]] && error "Falha ao reiniciar serviço $service"
        audit_log "SYSTEMD_SERVICE_RESTART_FAILED" "ERROR" "Service: $service"
        return 1
    fi
}

# Verificar status do serviço systemd
systemd_service_status() {
    local service="$1"
    local quiet="${2:-false}"

    if sudo systemctl is-active --quiet "$service" 2>/dev/null; then
        [[ "$quiet" != "true" ]] && success "Serviço $service: ATIVO"
        return 0
    else
        [[ "$quiet" != "true" ]] && error "Serviço $service: INATIVO"
        return 1
    fi
}

# Habilitar serviço systemd
systemd_service_enable() {
    local service="$1"
    local quiet="${2:-false}"

    [[ "$quiet" != "true" ]] && progress "Habilitando serviço $service..."
    if sudo systemctl enable "$service" 2>/dev/null; then
        [[ "$quiet" != "true" ]] && success "Serviço $service habilitado com sucesso"
        audit_log "SYSTEMD_SERVICE_ENABLED" "SUCCESS" "Service: $service"
        return 0
    else
        [[ "$quiet" != "true" ]] && error "Falha ao habilitar serviço $service"
        audit_log "SYSTEMD_SERVICE_ENABLE_FAILED" "ERROR" "Service: $service"
        return 1
    fi
}

# Desabilitar serviço systemd
systemd_service_disable() {
    local service="$1"
    local quiet="${2:-false}"

    [[ "$quiet" != "true" ]] && progress "Desabilitando serviço $service..."
    if sudo systemctl disable "$service" 2>/dev/null; then
        [[ "$quiet" != "true" ]] && success "Serviço $service desabilitado com sucesso"
        audit_log "SYSTEMD_SERVICE_DISABLED" "SUCCESS" "Service: $service"
        return 0
    else
        [[ "$quiet" != "true" ]] && error "Falha ao desabilitar serviço $service"
        audit_log "SYSTEMD_SERVICE_DISABLE_FAILED" "ERROR" "Service: $service"
        return 1
    fi
}

# Listar serviços systemd
list_systemd_services() {
    local pattern="${1:-}"

    if [[ -n "$pattern" ]]; then
        systemctl list-units --type=service --state=active,inactive --no-pager | grep "$pattern" || true
    else
        systemctl list-units --type=service --state=active,inactive --no-pager | head -20
    fi
}

# =============================================================================
# GERENCIAMENTO DE CONTAINERS DOCKER
# =============================================================================

# Gerenciar container Docker
manage_docker_container() {
    local action="$1"
    local container="$2"
    local quiet="${3:-false}"

    # Validar entrada
    if ! validate_service_name "$container"; then
        audit_log "INVALID_CONTAINER_NAME" "ERROR" "Container: $container"
        return 1
    fi

    # Verificar se Docker está disponível
    if ! command_exists docker; then
        audit_log "DOCKER_NOT_FOUND" "ERROR" "Attempted to manage container: $container"
        [[ "$quiet" != "true" ]] && error "Docker não encontrado"
        return 1
    fi

    # Verificar se Docker está acessível
    if ! sudo docker info >/dev/null 2>&1; then
        [[ "$quiet" != "true" ]] && error "Docker não está acessível ou não está rodando"
        audit_log "DOCKER_INACCESSIBLE" "ERROR" "Container: $container"
        return 1
    fi

    # Determinar nível de risco
    local risk_level
    if [[ " ${DATABASE_SERVICES[*]} " =~ " $container " ]]; then
        risk_level="$RISK_HIGH"
    else
        risk_level="$RISK_MEDIUM"
    fi

    # Confirmar operação crítica
    if [[ "$quiet" != "true" ]]; then
        if ! confirm_critical_operation "Gerenciar container Docker: $action $container" "$risk_level" "Ação: $action, Container: $container"; then
            return 1
        fi
    fi

    audit_log "DOCKER_CONTAINER_MANAGEMENT" "INFO" "Action: $action, Container: $container"

    case "$action" in
        start)
            docker_container_start "$container" "$quiet"
            ;;
        stop)
            docker_container_stop "$container" "$quiet"
            ;;
        restart)
            docker_container_restart "$container" "$quiet"
            ;;
        status)
            docker_container_status "$container" "$quiet"
            ;;
        logs)
            docker_container_logs "$container" "$quiet"
            ;;
        *)
            [[ "$quiet" != "true" ]] && error "Ação inválida: $action"
            return 1
            ;;
    esac
}

# Iniciar container Docker
docker_container_start() {
    local container="$1"
    local quiet="${2:-false}"

    if ! sudo docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        if sudo docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            [[ "$quiet" != "true" ]] && progress "Iniciando container $container..."
            if sudo docker start "$container" >/dev/null 2>&1; then
                [[ "$quiet" != "true" ]] && success "Container $container iniciado com sucesso"
                audit_log "DOCKER_CONTAINER_STARTED" "SUCCESS" "Container: $container"
                return 0
            else
                [[ "$quiet" != "true" ]] && warn "Falha ao iniciar container $container"
                audit_log "DOCKER_CONTAINER_START_FAILED" "WARNING" "Container: $container"
                return 1
            fi
        else
            [[ "$quiet" != "true" ]] && warn "Container $container não encontrado"
            audit_log "DOCKER_CONTAINER_NOT_FOUND" "WARNING" "Container: $container"
            return 1
        fi
    else
        [[ "$quiet" != "true" ]] && info "Container $container já está rodando"
        return 0
    fi
}

# Parar container Docker
docker_container_stop() {
    local container="$1"
    local quiet="${2:-false}"

    if sudo docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        [[ "$quiet" != "true" ]] && progress "Parando container $container..."
        if sudo docker stop "$container" >/dev/null 2>&1; then
            [[ "$quiet" != "true" ]] && success "Container $container parado com sucesso"
            audit_log "DOCKER_CONTAINER_STOPPED" "SUCCESS" "Container: $container"
            return 0
        else
            [[ "$quiet" != "true" ]] && warn "Falha ao parar container $container"
            audit_log "DOCKER_CONTAINER_STOP_FAILED" "WARNING" "Container: $container"
            return 1
        fi
    else
        [[ "$quiet" != "true" ]] && info "Container $container já está parado"
        return 0
    fi
}

# Reiniciar container Docker
docker_container_restart() {
    local container="$1"
    local quiet="${2:-false}"

    [[ "$quiet" != "true" ]] && progress "Reiniciando container $container..."
    if sudo docker restart "$container" >/dev/null 2>&1; then
        [[ "$quiet" != "true" ]] && success "Container $container reiniciado com sucesso"
        audit_log "DOCKER_CONTAINER_RESTARTED" "SUCCESS" "Container: $container"
        return 0
    else
        [[ "$quiet" != "true" ]] && error "Falha ao reiniciar container $container"
        audit_log "DOCKER_CONTAINER_RESTART_FAILED" "ERROR" "Container: $container"
        return 1
    fi
}

# Verificar status do container Docker
docker_container_status() {
    local container="$1"
    local quiet="${2:-false}"

    if sudo docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        [[ "$quiet" != "true" ]] && success "Container $container: RODANDO"
        return 0
    elif sudo docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        [[ "$quiet" != "true" ]] && warn "Container $container: PARADO"
        return 1
    else
        [[ "$quiet" != "true" ]] && error "Container $container: NÃO ENCONTRADO"
        return 1
    fi
}

# Mostrar logs do container Docker
docker_container_logs() {
    local container="$1"
    local lines="${2:-50}"
    local quiet="${3:-false}"

    if sudo docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        [[ "$quiet" != "true" ]] && info "Logs do container $container (últimas $lines linhas):"
        sudo docker logs --tail="$lines" "$container" 2>&1 || true
        audit_log "DOCKER_CONTAINER_LOGS_VIEWED" "INFO" "Container: $container, Lines: $lines"
    else
        [[ "$quiet" != "true" ]] && error "Container $container não encontrado"
        return 1
    fi
}

# Listar containers Docker
list_docker_containers() {
    local all="${1:-false}"

    if [[ "$all" == "true" ]]; then
        sudo docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    fi
}

# =============================================================================
# GERENCIAMENTO DE PROCESSOS
# =============================================================================

# Iniciar processo em background
start_background_process() {
    local service_name="$1"
    local pid_file="$2"
    local command="$3"
    local log_file="$4"
    local venv_path="${5:-${PROJECT_ROOT}/.venv}"

    # Criar diretório para PID se não existir
    ensure_dir "$(dirname "$pid_file")"

    # Verificar se processo já está rodando
    if file_exists "$pid_file" && process_running "$(cat "$pid_file")"; then
        info "$service_name já está em execução (PID: $(cat "$pid_file"))"
        return 0
    fi

    progress "Iniciando $service_name..."

    # Ativar ambiente virtual se existir
    if dir_exists "$venv_path"; then
        source "${venv_path}/bin/activate"
    fi

    # Executar comando em background
    nohup $command > "$log_file" 2>&1 &
    local pid=$!

    # Desativar ambiente virtual
    if dir_exists "$venv_path"; then
        deactivate 2>/dev/null || true
    fi

    # Salvar PID
    echo "$pid" > "$pid_file"
    sleep 2

    # Verificar se processo iniciou corretamente
    if process_running "$pid"; then
        success "$service_name iniciado com sucesso (PID: $pid)"
        audit_log "PROCESS_STARTED" "SUCCESS" "Service: $service_name, PID: $pid"
        return 0
    else
        error "Falha ao iniciar $service_name. Verifique o log: $log_file"
        audit_log "PROCESS_START_FAILED" "ERROR" "Service: $service_name"
        return 1
    fi
}

# Parar processo por PID
stop_background_process() {
    local service_name="$1"
    local pid_file="$2"

    if ! file_exists "$pid_file"; then
        info "$service_name não parece estar rodando (arquivo PID não encontrado)"
        return 0
    fi

    local pid
    pid=$(cat "$pid_file")

    if [[ -z "$pid" ]]; then
        warn "Arquivo PID para $service_name está vazio"
        rm -f "$pid_file"
        return 0
    fi

    if ! process_running "$pid"; then
        info "$service_name (PID: $pid) já estava parado"
        rm -f "$pid_file"
        return 0
    fi

    progress "Parando $service_name (PID: $pid)..."

    # Tentar parada graciosa primeiro (SIGTERM)
    kill -TERM "$pid" 2>/dev/null || true
    sleep 3

    # Forçar parada se ainda estiver rodando (SIGKILL)
    if process_running "$pid"; then
        warn "$service_name não parou de forma graciosa. Forçando parada..."
        kill -KILL "$pid" 2>/dev/null || true
        sleep 1
    fi

    if process_running "$pid"; then
        error "Falha ao parar $service_name"
        audit_log "PROCESS_STOP_FAILED" "ERROR" "Service: $service_name, PID: $pid"
        return 1
    else
        success "$service_name parado com sucesso"
        rm -f "$pid_file"
        audit_log "PROCESS_STOPPED" "SUCCESS" "Service: $service_name, PID: $pid"
        return 0
    fi
}

# Listar processos do cluster
list_cluster_processes() {
    local pattern="${1:-}"

    echo "Processos do Cluster AI:"
    echo "PID    CPU%  MEM%  COMMAND"
    echo "------ ----- ----- ----------------"

    if [[ -n "$pattern" ]]; then
        ps aux | grep -E "$pattern" | grep -v grep | head -10 | \
        awk '{printf "%-6s %-5s %-5s %s\n", $2, $3, $4, $11}'
    else
        ps aux | grep -E "(dask|ollama|python|docker)" | grep -v grep | head -10 | \
        awk '{printf "%-6s %-5s %-5s %s\n", $2, $3, $4, $11}'
    fi
}

# =============================================================================
# VERIFICAÇÃO DE SAÚDE DOS SERVIÇOS
# =============================================================================

# Verificar saúde de todos os serviços
check_services_health() {
    local detailed="${1:-false}"

    section "Verificação de Saúde dos Serviços"

    # Serviços systemd
    subsection "Serviços Systemd"
    local systemd_services=("docker" "nginx" "sshd")
    for service in "${systemd_services[@]}"; do
        if command_exists systemctl; then
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                success "✅ $service: OK"
            else
                warn "❌ $service: FALHA"
            fi
        fi
    done

    # Containers Docker
    if command_exists docker && sudo docker info >/dev/null 2>&1; then
        subsection "Containers Docker"
        local containers=("open-webui" "ollama")
        for container in "${containers[@]}"; do
            if sudo docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
                success "✅ $container: OK"
            else
                warn "❌ $container: FALHA"
            fi
        done
    fi

    # Processos em background
    subsection "Processos em Background"
    local pid_files=("${RUN_DIR}/dask_cluster.pid" "${RUN_DIR}/ollama.pid")
    for pid_file in "${pid_files[@]}"; do
        if file_exists "$pid_file"; then
            local pid=$(cat "$pid_file")
            local service_name=$(basename "$pid_file" .pid)
            if process_running "$pid"; then
                success "✅ $service_name: OK (PID: $pid)"
            else
                warn "❌ $service_name: FALHA (PID: $pid)"
            fi
        fi
    done

    if [[ "$detailed" == "true" ]]; then
        subsection "Recursos do Sistema"
        echo "CPU: $(uptime | awk -F'load average:' '{ print $2 }' | sed 's/,//g')"
        echo "Memória: $(free -h | awk 'NR==2{printf "%.1fGB usada de %.1fGB", $3/1024, $2/1024}')"
        echo "Disco: $(df -h . | awk 'NR==2{print $4 " disponível de " $2}')"
    fi
}

# =============================================================================
# FUNÇÕES DE SETUP DE SERVIÇOS
# =============================================================================

# Cria o arquivo de serviço para o Dask Scheduler
create_dask_scheduler_service() {
    local service_file="/etc/systemd/system/dask-scheduler.service"
    local user_exec="${SUDO_USER:-$(whoami)}"
    local venv_path="${PROJECT_ROOT}/.venv/bin"

    info "Criando arquivo de serviço em $service_file"
    
    local service_content="[Unit]
Description=Dask Scheduler for Cluster AI
After=network.target

[Service]
User=$user_exec
Group=$(id -gn "$user_exec")
WorkingDirectory=$PROJECT_ROOT
ExecStart=${venv_path}/dask-scheduler --host 0.0.0.0 --port 8786 --dashboard-address :8787
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target"

    echo "$service_content" | sudo tee "$service_file" > /dev/null
    success "Arquivo de serviço do Dask Scheduler criado."
}

# Cria o arquivo de serviço para o Dask Worker
create_dask_worker_service() {
    local service_file="/etc/systemd/system/dask-worker.service"
    local user_exec="${SUDO_USER:-$(whoami)}"
    local venv_path="${PROJECT_ROOT}/.venv/bin"

    info "Criando arquivo de serviço em $service_file"

    local service_content="[Unit]
Description=Dask Local Worker for Cluster AI
After=dask-scheduler.service
Requires=dask-scheduler.service

[Service]
User=$user_exec
Group=$(id -gn "$user_exec")
WorkingDirectory=$PROJECT_ROOT
ExecStart=${venv_path}/dask-worker tcp://127.0.0.1:8786 --nthreads 2 --memory-limit 4GB
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target"

    echo "$service_content" | sudo tee "$service_file" > /dev/null
    success "Arquivo de serviço do Dask Worker criado."
    warn "NOTA: O worker está configurado com 2 threads e 4GB de RAM. Edite $service_file para ajustar."
}

# Função principal para robustecer a instalação do Dask
run_dask_service_setup() {
    section "Robustecendo Instalação do Dask com systemd"
    if ! confirm_critical_operation "Criar serviços systemd para Dask" "$RISK_MEDIUM" "Isso criará arquivos em /etc/systemd/system/"; then
        return 1
    fi

    create_dask_scheduler_service
    create_dask_worker_service
    
    progress "Recarregando daemon do systemd e habilitando serviços..."
    sudo systemctl daemon-reload && sudo systemctl enable dask-scheduler.service && sudo systemctl enable dask-worker.service
    success "Serviços Dask configurados! Use './manager.sh start' para iniciá-los."
}

# =============================================================================
# INICIALIZAÇÃO DO MÓDULO
# =============================================================================

# Inicializar módulo de serviços
init_services_module() {
    # Verificar se Docker está disponível
    if command_exists docker; then
        info "Docker detectado - funcionalidades de container disponíveis"
    else
        warn "Docker não encontrado - funcionalidades de container limitadas"
    fi

    # Verificar se systemd está disponível
    if command_exists systemctl; then
        info "systemd detectado - gerenciamento de serviços disponível"
    else
        warn "systemd não encontrado - gerenciamento de serviços limitado"
    fi

    audit_log "SERVICES_MODULE_INITIALIZED" "SUCCESS" "Services module loaded"
}

# Verificar se módulo foi carregado corretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_environment
    init_security_module
    init_services_module
    info "Módulo services.sh carregado com sucesso"
fi
