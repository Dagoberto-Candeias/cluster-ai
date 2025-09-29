#!/bin/bash
# =============================================================================
# Script de Verificação de Saúde Consolidado - Cluster AI
# =============================================================================
# Versão unificada com recursos avançados de monitoramento e recuperação
# para serviços, workers, modelos e sistema geral.
#
# Autor: Cluster AI Team
# Data: 2025-01-27
# Versão: 2.0.0
# Arquivo: health_check.sh
# =============================================================================

set -euo pipefail

# Carregar biblioteca comum
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=scripts/utils/common_functions.sh
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common_functions.sh"

# Configurações
LOG_DIR="${PROJECT_ROOT}/logs"
HEALTH_LOG="${LOG_DIR}/health_check.log"
WORKER_CONFIG_FILE="${PROJECT_ROOT}/cluster.yaml"

# Carregar variáveis de ambiente opcionais do projeto (.env)
if [ -f "${PROJECT_ROOT}/.env" ]; then
    # Filtra apenas linhas no formato VAR=VAL com nomes válidos (sem pontos)
    # Evita erros como "xpack.security.enabled=false" ao dar source no arquivo completo
    tmp_env_file=$(mktemp)
    # shellcheck disable=SC2016
    grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "${PROJECT_ROOT}/.env" > "$tmp_env_file" || true
    set -a
    # shellcheck disable=SC1090
    . "$tmp_env_file"
    set +a
    rm -f "$tmp_env_file"
fi

# Carregar variáveis locais opcionais (.env.local) para overrides sem tocar no .env
if [ -f "${PROJECT_ROOT}/.env.local" ]; then
    tmp_env_local=$(mktemp)
    # shellcheck disable=SC2016
    grep -E '^[A-Za-z_][A-Za-z0-9_]*=' "${PROJECT_ROOT}/.env.local" > "$tmp_env_local" || true
    set -a
    # shellcheck disable=SC1090
    . "$tmp_env_local"
    set +a
    rm -f "$tmp_env_local"
fi

# Parâmetros ajustáveis (com defaults seguros)
DISK_WARN_THRESHOLD=${DISK_WARN_THRESHOLD:-80}     # %
DISK_CRIT_THRESHOLD=${DISK_CRIT_THRESHOLD:-90}     # %
MEM_WARN_THRESHOLD=${MEM_WARN_THRESHOLD:-85}       # %
MEM_CRIT_THRESHOLD=${MEM_CRIT_THRESHOLD:-95}       # %
CPU_CRIT_THRESHOLD=${CPU_CRIT_THRESHOLD:-90}       # % (workers)
WORKER_DISK_CRIT_THRESHOLD=${WORKER_DISK_CRIT_THRESHOLD:-95}  # %

# Flags de execução
SKIP_WORKERS=${SKIP_WORKERS:-false}

# Serviços Docker a verificar (separados por espaço)
DOCKER_SERVICES=${DOCKER_SERVICES:-"frontend backend redis prometheus grafana"}

# Utilitários de comparação de floats, com fallback
# Retornam 0 (verdadeiro) quando a comparação é satisfeita
if command_exists awk; then
    float_gt() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a>b)}'; }
    float_ge() { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a>=b)}'; }
elif command_exists bc; then
    # Fallback usando bc se awk não estiver disponível
    float_gt() { echo "$1>$2" | bc -l >/dev/null 2>&1; [ "$(echo "$1>$2" | bc -l)" -eq 1 ]; }
    float_ge() { echo "$1>=$2" | bc -l >/dev/null 2>&1; [ "$(echo "$1>=$2" | bc -l)" -eq 1 ]; }
else
    # Fallback aproximado (inteiro): usa parte inteira para comparar
    float_gt() { local A B; A=${1%%.*}; B=${2%%.*}; [ "${A:-0}" -gt "${B:-0}" ]; }
    float_ge() { local A B; A=${1%%.*}; B=${2%%.*}; [ "${A:-0}" -ge "${B:-0}" ]; }
    warn "awk/bc indisponíveis; comparações de ponto flutuante serão aproximadas (inteiras)"
fi

# Criar diretório de logs
mkdir -p "$LOG_DIR"

# Checagem de dependências (informativa, não bloqueante)
ensure_command() {
    local cmd="$1"
    if ! command_exists "$cmd"; then
        warn "Command not found: $cmd"
        return 1
    fi
    return 0
}

check_prereqs() {
    log_health "INFO" "Checking script prerequisites"
    local cmds=(awk grep sed date df free ping docker yq ssh ss curl pgrep tail wc timeout)
    local missing=()
    for c in "${cmds[@]}"; do
        ensure_command "$c" || missing+=("$c")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        warn "Missing commands: ${missing[*]} (some checks may be skipped or approximated)"
    else
        success "All prerequisite commands available"
    fi
}

# Função para log de saúde
log_health() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$HEALTH_LOG"
}

# =============================================================================
# VERIFICAÇÕES DE SERVIÇOS PRINCIPAIS
# =============================================================================

# Verificar Ollama
check_ollama() {
    log_health "INFO" "Checking Ollama service"
    if ! command_exists ollama; then
        error "Ollama not available"
        return 1
    fi
    if pgrep -f "ollama" >/dev/null 2>&1; then
        local model_count
        model_count=$(ollama list 2>/dev/null | wc -l 2>/dev/null || echo "0")
        success "Ollama running ($((model_count - 1)) models)"
        return 0
    else
        error "Ollama not running"
        return 1
    fi
}

# Verificar Docker
check_docker() {
    log_health "INFO" "Checking Docker service"
    if command_exists docker && docker info >/dev/null 2>&1; then
        local container_count
        container_count=$(docker ps -q 2>/dev/null | wc -l || echo "0")
        success "Docker running ($container_count containers)"
        return 0
    else
        error "Docker not available"
        return 1
    fi
}

# Verificar Python e dependências
check_python() {
    log_health "INFO" "Checking Python environment"
    if command_exists python3; then
        local python_version
        python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        success "Python $python_version available"
        return 0
    else
        error "Python3 not found"
        return 1
    fi
}

# Verificar Dashboard Model Registry (Flask)
check_dashboard() {
    log_health "INFO" "Checking Dashboard Model Registry"
    if ! command_exists curl; then
        warn "curl not available to check dashboard"
        return 1
    fi
    local url
    url=${DASHBOARD_HEALTH_URL:-http://127.0.0.1:5000/health}
    local timeout
    timeout=${DASHBOARD_HEALTH_TIMEOUT:-3}
    if curl -fsS --max-time "$timeout" "$url" >/dev/null 2>&1; then
        success "Dashboard healthy ($url)"
        return 0
    else
        error "Dashboard not responding ($url)"
        return 1
    fi
}

# Verificar serviços Docker Compose
check_docker_services() {
    log_health "INFO" "Checking Docker Compose services"
    if ! command_exists docker || ! docker info >/dev/null 2>&1; then
        warn "Docker not available for service check"
        return 1
    fi

    # Tentar detectar por nomes de containers, agnóstico ao COMPOSE_PROJECT_NAME
    local failed_services=()
    local containers
    containers=$(docker ps --format '{{.Names}}' 2>/dev/null || true)

    for service in ${DOCKER_SERVICES}; do
        if ! echo "$containers" | grep -qE "(^|[-_])${service}([-_]|$)"; then
            failed_services+=("$service")
        fi
    done

    if [ ${#failed_services[@]} -eq 0 ]; then
        success "All Docker services running"
        return 0
    else
        error "Failed services: ${failed_services[*]}"
        return 1
    fi
}

# =============================================================================
# VERIFICAÇÕES DE WORKERS
# =============================================================================

# Health check para um worker específico
health_check_worker() {
    local worker_name="$1"
    log_health "INFO" "Health check for worker: $worker_name"

    if ! command_exists yq >/dev/null; then
        error "yq not found for worker config"
        return 1
    fi
    if ! command_exists ssh >/dev/null; then
        error "ssh not available for worker checks"
        return 1
    fi

    # Obter informações do worker
    local worker_info
    worker_info=$(yq e ".workers[\"$worker_name\"]" "$WORKER_CONFIG_FILE" 2>/dev/null)

    if [[ "$worker_info" == "null" ]]; then
        error "Worker '$worker_name' not found in config"
        return 1
    fi

    local host user port
    # Suporte a legado: usar .host ou fallback para .ip
    host=$(echo "$worker_info" | yq e '.host // .ip' -)
    user=$(echo "$worker_info" | yq e '.user' -)
    port=$(echo "$worker_info" | yq e '.port' -)

    local health_status="HEALTHY"
    local issues=()

    # 1. Verificar conectividade SSH
    if ! ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 -o BatchMode=yes -p "$port" "$user@$host" "echo 'OK'" >/dev/null 2>&1; then
        health_status="UNHEALTHY"
        issues+=("SSH connection failed")
    fi

    # 2. Verificar recursos se SSH OK
    if [[ "$health_status" == "HEALTHY" ]]; then
        # CPU
        local cpu_usage
        cpu_usage=$(ssh -o StrictHostKeyChecking=accept-new -p "$port" "$user@$host" "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print 100 - \$1}'" 2>/dev/null || echo "N/A")
        if [[ "$cpu_usage" != "N/A" ]] && float_gt "$cpu_usage" "$CPU_CRIT_THRESHOLD"; then
            health_status="UNHEALTHY"
            issues+=("High CPU: ${cpu_usage}%")
        fi

        # Memory
        local mem_usage
        mem_usage=$(ssh -o StrictHostKeyChecking=accept-new -p "$port" "$user@$host" "free | grep Mem | awk '{printf \"%.1f\", \$3/\$2 * 100.0}'" 2>/dev/null || echo "N/A")
        if [[ "$mem_usage" != "N/A" ]] && float_gt "$mem_usage" "$MEM_CRIT_THRESHOLD"; then
            health_status="UNHEALTHY"
            issues+=("High memory: ${mem_usage}%")
        fi

        # Disk
        local disk_usage
        disk_usage=$(ssh -o StrictHostKeyChecking=accept-new -p "$port" "$user@$host" "df / | tail -1 | awk '{print \$5}' | sed 's/%//'" 2>/dev/null || echo "N/A")
        if [[ "$disk_usage" != "N/A" ]] && [ "$disk_usage" -gt "$WORKER_DISK_CRIT_THRESHOLD" ]; then
            health_status="UNHEALTHY"
            issues+=("High disk: ${disk_usage}%")
        fi

        # Dask processes
        local dask_count
        dask_count=$(ssh -o StrictHostKeyChecking=accept-new -p "$port" "$user@$host" "pgrep -f dask | wc -l" 2>/dev/null || echo "0")
        if [ "$dask_count" -eq 0 ]; then
            issues+=("No Dask processes")
        fi
    fi

    # Resultado
    if [[ "$health_status" == "HEALTHY" ]]; then
        success "Worker $worker_name: HEALTHY"
        log_health "INFO" "Worker $worker_name health check passed"
        return 0
    else
        error "Worker $worker_name: UNHEALTHY (${issues[*]})"
        log_health "ERROR" "Worker $worker_name health check failed: ${issues[*]}"
        return 1
    fi
}

# Health check para todos os workers
health_check_all_workers() {
    log_health "INFO" "Health check for all workers"

    if ! command_exists yq >/dev/null; then
        error "yq not found for worker config"
        return 1
    fi

    local workers
    mapfile -t workers < <(yq e '.workers | keys | .[]' "$WORKER_CONFIG_FILE" 2>/dev/null || echo "")

    if [ ${#workers[@]} -eq 0 ]; then
        warn "No workers configured"
        return 0
    fi

    local healthy=0
    local unhealthy=0
    local skipped=0

    for worker in "${workers[@]}"; do
        # Verificar se há host definido antes de tentar
        local host_present
        host_present=$(yq e ".workers[\"$worker\"].host // .workers[\"$worker\"].ip // \"\"" "$WORKER_CONFIG_FILE" 2>/dev/null || echo "")
        if [[ -z "$host_present" ]]; then
            warn "Worker '$worker' skipped (missing host in cluster.yaml)"
            log_health "WARN" "Worker $worker skipped: missing host"
            ((skipped++))
            continue
        fi
        # Respeitar status do worker (default: active)
        local status
        status=$(yq e ".workers[\"$worker\"].status // \"active\"" "$WORKER_CONFIG_FILE" 2>/dev/null | tr 'A-Z' 'a-z')
        if [[ "$status" != "active" ]]; then
            warn "Worker '$worker' skipped (status=$status)"
            log_health "WARN" "Worker $worker skipped: status=$status"
            ((skipped++))
            continue
        fi
        if health_check_worker "$worker" >/dev/null 2>&1; then
            ((healthy++))
        else
            ((unhealthy++))
        fi
    done

    if [ $unhealthy -eq 0 ]; then
        if [ $healthy -gt 0 ]; then
            success "All workers healthy ($healthy total)"
            log_health "INFO" "All workers healthy: $healthy"
        else
            warn "All workers skipped (no host configured). Configure cluster.yaml to enable checks."
            log_health "WARN" "All workers skipped: $skipped"
        fi
        return 0
    else
        error "$unhealthy workers unhealthy (healthy: $healthy, skipped: $skipped)"
        log_health "ERROR" "$unhealthy workers unhealthy"
        return 1
    fi
}

# =============================================================================
# VERIFICAÇÕES DE MODELOS
# =============================================================================

# Health check para modelos Ollama
health_check_models() {
    log_health "INFO" "Health check for Ollama models"

    if ! command_exists ollama; then
        error "Ollama not available"
        return 1
    fi

    if ! curl -s "http://127.0.0.1:11434/api/tags" >/dev/null 2>&1; then
        error "Ollama API not responding"
        return 1
    fi

    local models
    models=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' | sort)

    if [[ -z "$models" ]]; then
        warn "No models installed"
        return 0
    fi

    local healthy=0
    local unhealthy=0

    for model in $models; do
        if timeout 10 ollama show "$model" >/dev/null 2>&1; then
            ((healthy++))
        else
            ((unhealthy++))
            log_health "WARN" "Unhealthy model: $model"
        fi
    done

    if [ $unhealthy -eq 0 ]; then
        success "All models healthy ($healthy total)"
        log_health "INFO" "All models healthy: $healthy"
        return 0
    else
        error "$unhealthy models unhealthy (healthy: $healthy)"
        log_health "ERROR" "$unhealthy models unhealthy"
        return 1
    fi
}

# =============================================================================
# VERIFICAÇÕES DE SISTEMA
# =============================================================================

# Verificar espaço em disco
check_disk_space() {
    log_health "INFO" "Checking disk space"
    local disk_usage
    disk_usage=$(df . | tail -1 | awk '{print $5}' | sed 's/%//')

    if [ "$disk_usage" -gt "$DISK_CRIT_THRESHOLD" ]; then
        error "Disk usage critical: ${disk_usage}%"
        return 1
    elif [ "$disk_usage" -gt "$DISK_WARN_THRESHOLD" ]; then
        warn "Disk usage high: ${disk_usage}%"
        return 0
    else
        success "Disk space OK: ${disk_usage}%"
        return 0
    fi
}

# Verificar memória
check_memory() {
    log_health "INFO" "Checking memory"
    if ! command_exists free; then
        warn "free command not available"
        return 0
    fi

    local mem_usage
    mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')

    if float_gt "$mem_usage" "$MEM_CRIT_THRESHOLD"; then
        error "Memory usage critical: ${mem_usage}%"
        return 1
    elif float_gt "$mem_usage" "$MEM_WARN_THRESHOLD"; then
        warn "Memory usage high: ${mem_usage}%"
        return 0
    else
        success "Memory OK: ${mem_usage}%"
        return 0
    fi
}

# Verificar conectividade de rede
check_network() {
    log_health "INFO" "Checking network connectivity"
    if ! command_exists ping; then
        warn "ping command not available"
        return 0
    fi
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        success "Network connectivity OK"
        return 0
    else
        error "Network connectivity failed"
        return 1
    fi
}

# =============================================================================
# FUNÇÕES PRINCIPAIS
# =============================================================================

# Health check completo do sistema
system_health_check() {
    section "SYSTEM HEALTH CHECK - CLUSTER AI"

    local overall_status="OK"
    local issues=()

    echo -e "${BOLD}${BLUE}SERVICES${NC}"
    check_ollama || { overall_status="ERROR"; issues+=("Ollama"); }
    check_docker || { overall_status="ERROR"; issues+=("Docker"); }
    check_python || { overall_status="WARN"; issues+=("Python"); }
    check_dashboard || { overall_status="ERROR"; issues+=("Dashboard"); }
    check_docker_services || { overall_status="ERROR"; issues+=("Docker Services"); }

    echo -e "\n${BOLD}${BLUE}WORKERS${NC}"
    if [[ "$SKIP_WORKERS" == "true" ]]; then
        warn "Workers check skipped (--skip-workers)"
    else
        health_check_all_workers || { overall_status="ERROR"; issues+=("Workers"); }
    fi

    echo -e "\n${BOLD}${BLUE}MODELS${NC}"
    health_check_models || { overall_status="WARN"; issues+=("Models"); }

    echo -e "\n${BOLD}${BLUE}SYSTEM${NC}"
    check_disk_space || { overall_status="ERROR"; issues+=("Disk"); }
    check_memory || { overall_status="ERROR"; issues+=("Memory"); }
    check_network || { overall_status="ERROR"; issues+=("Network"); }

    echo -e "\n${BOLD}${BLUE}OVERALL STATUS${NC}"
    if [[ "$overall_status" == "OK" ]]; then
        success "All systems healthy"
        log_health "INFO" "System health check passed"
        return 0
    else
        error "Issues found: ${issues[*]}"
        log_health "ERROR" "System health check failed: ${issues[*]}"
        return 1
    fi
}

# Health check de diagnóstico
diagnostic_health_check() {
    section "DIAGNOSTIC HEALTH CHECK"

    echo -e "${BOLD}${BLUE}DETAILED DIAGNOSTICS${NC}"

    # Serviços com detalhes
    echo -e "\n${CYAN}Services:${NC}"
    if pgrep -f "ollama" >/dev/null 2>&1; then
        echo "  ✓ Ollama: Running"
    else
        echo "  ✗ Ollama: Not running"
    fi

    if command_exists docker && docker info >/dev/null 2>&1; then
        local containers
        containers=$(docker ps -q | wc -l)
        echo "  ✓ Docker: Running ($containers containers)"
    else
        echo "  ✗ Docker: Not available"
    fi

    # Sistema
    echo -e "\n${CYAN}System Resources:${NC}"
    local disk
    disk=$(df . | tail -1 | awk '{print $5}')
    echo "  Disk usage: $disk"

    local mem
    mem=$(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')
    echo "  Memory usage: $mem"

    # Logs recentes
    echo -e "\n${CYAN}Recent Logs:${NC}"
    if [ -f "$HEALTH_LOG" ]; then
        tail -5 "$HEALTH_LOG" | while read -r line; do
            echo "  $line"
        done
    else
        echo "  No health logs found"
    fi

    log_health "INFO" "Diagnostic health check completed"
}

# Health check de status (simples)
status_health_check() {
    local quiet="${1:-false}"

    if [[ "$quiet" == "true" ]]; then
        # Modo quiet para scripts
        system_health_check >/dev/null 2>&1
        return $?
    else
        system_health_check
        return $?
    fi
}

# Saída JSON agregada (silenciosa)
json_health_check() {
    # Executa cada verificação suprimindo saída e compõe um JSON simples
    local s_ollama s_docker s_python s_compose
    local s_dashboard
    local s_workers s_models s_disk s_mem s_net

    check_ollama >/dev/null 2>&1; s_ollama=$?
    check_docker >/dev/null 2>&1; s_docker=$?
    check_python >/dev/null 2>&1; s_python=$?
    check_dashboard >/dev/null 2>&1; s_dashboard=$?
    check_docker_services >/dev/null 2>&1; s_compose=$?

    if [[ "$SKIP_WORKERS" == "true" ]]; then
        s_workers=0
    else
        health_check_all_workers >/dev/null 2>&1; s_workers=$?
    fi
    health_check_models >/dev/null 2>&1; s_models=$?

    check_disk_space >/dev/null 2>&1; s_disk=$?
    check_memory >/dev/null 2>&1; s_mem=$?
    check_network >/dev/null 2>&1; s_net=$?

    local services_ok workers_ok models_ok system_ok overall
    services_ok=$(( s_ollama==0 && s_docker==0 && s_python==0 && s_dashboard==0 && s_compose==0 ? 0 : 1 ))
    workers_ok=$(( s_workers==0 ? 0 : 1 ))
    models_ok=$(( s_models==0 ? 0 : 1 ))
    system_ok=$(( s_disk==0 && s_mem==0 && s_net==0 ? 0 : 1 ))
    overall=$(( services_ok==0 && workers_ok==0 && models_ok==0 && system_ok==0 ? 0 : 1 ))

    # Imprime JSON
    printf '{"services":{"ollama":%s,"docker":%s,"python":%s,"dashboard":%s,"compose":%s},' \
      "$([ $s_ollama -eq 0 ] && echo true || echo false)" \
      "$([ $s_docker -eq 0 ] && echo true || echo false)" \
      "$([ $s_python -eq 0 ] && echo true || echo false)" \
      "$([ $s_dashboard -eq 0 ] && echo true || echo false)" \
      "$([ $s_compose -eq 0 ] && echo true || echo false)"
    printf '"workers":{"healthy":%s},' "$([ $s_workers -eq 0 ] && echo true || echo false)"
    printf '"models":{"healthy":%s},' "$([ $s_models -eq 0 ] && echo true || echo false)"
    printf '"system":{"disk":%s,"memory":%s,"network":%s},' \
      "$([ $s_disk -eq 0 ] && echo true || echo false)" \
      "$([ $s_mem -eq 0 ] && echo true || echo false)" \
      "$([ $s_net -eq 0 ] && echo true || echo false)"
    printf '"overall":"%s"}' "$([ $overall -eq 0 ] && echo OK || echo ERROR)"

    return $overall
}

# Alias para compatibilidade
health_check() {
    status_health_check "$@"
}

# =============================================================================
# PONTO DE ENTRADA
# =============================================================================

main() {
    cd "$PROJECT_ROOT"

    # Criar log
    touch "$HEALTH_LOG"

    # Verificar pré-requisitos
    check_prereqs

    # Caminho rápido para ambientes de teste/CI: evitar operações pesadas e timeouts
    if [[ "${CLUSTER_AI_TEST_MODE:-0}" == "1" ]]; then
        log_health "INFO" "Fast path enabled (CLUSTER_AI_TEST_MODE=1)"
        # Reduzir timeouts e pular partes pesadas
        SKIP_WORKERS=true
        DASHBOARD_HEALTH_TIMEOUT=1
        DOCKER_SERVICES=""

        echo -e "${BOLD}${BLUE}FAST STATUS (TEST MODE)${NC}"
        # Executar apenas checagens leves e não bloqueantes
        check_python >/dev/null 2>&1 || true
        check_disk_space >/dev/null 2>&1 || true
        check_memory >/dev/null 2>&1 || true

        echo -e "${YELLOW}Test mode:${NC} pulando verificações de Docker, Ollama, Dashboard, Workers e Network"
        log_health "INFO" "Fast status completed"
        return 0
    fi

    # Parse de opções (permite override de serviços via CLI)
    local action="status"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --services)
                if [[ -n "${2:-}" ]]; then
                    DOCKER_SERVICES="$2"
                    shift 2
                    continue
                else
                    echo "Erro: --services requer um argumento (lista separada por espaço)" >&2
                    exit 1
                fi
                ;;
            --dashboard-url)
                if [[ -n "${2:-}" ]]; then
                    DASHBOARD_HEALTH_URL="$2"
                    shift 2
                    continue
                else
                    echo "Erro: --dashboard-url requer uma URL" >&2
                    exit 1
                fi
                ;;
            --dashboard-timeout)
                if [[ -n "${2:-}" ]]; then
                    DASHBOARD_HEALTH_TIMEOUT="$2"
                    shift 2
                    continue
                else
                    echo "Erro: --dashboard-timeout requer um valor (segundos)" >&2
                    exit 1
                fi
                ;;
            --skip-workers)
                SKIP_WORKERS=true
                shift
                continue
                ;;
            status|diag|diagnostic|json|--json|services|workers|models|system)
                action="$1"
                shift
                continue
                ;;
            *)
                # Ignora argumentos desconhecidos para manter compatibilidade
                shift
                continue
                ;;
        esac
    done

    case "$action" in
        "status")
            status_health_check ;;
        "diag"|"diagnostic")
            diagnostic_health_check ;;
        "json"|"--json")
            json_health_check ;;
        "services")
            echo -e "${BOLD}${BLUE}SERVICE CHECK${NC}"
            check_ollama
            check_docker
            check_python
            check_docker_services ;;
        "workers")
            health_check_all_workers ;;
        "models")
            health_check_models ;;
        "system")
            echo -e "${BOLD}${BLUE}SYSTEM CHECK${NC}"
            check_disk_space
            check_memory
            check_network ;;
        "help"|*)
            echo "Cluster AI - Health Check Tool"
            echo ""
            echo "Usage: $0 [action]"
            echo ""
            echo "Actions:"
            echo "  status     - Complete system health check"
            echo "  diag       - Detailed diagnostic information"
            echo "  services   - Check main services (Ollama, Docker, etc.)"
            echo "  workers    - Check all configured workers"
            echo "  models     - Check Ollama models integrity"
            echo "  system     - Check system resources"
            echo ""
            echo "Options:"
            echo "  --services  \"<list>\"   Override Docker services substrings for detection"
            echo "  --dashboard-url <url>       Override dashboard health URL (default: ${DASHBOARD_HEALTH_URL:-http://127.0.0.1:5000/health})"
            echo "  --dashboard-timeout <secs>  Override dashboard health timeout in seconds (default: ${DASHBOARD_HEALTH_TIMEOUT:-3})"
            echo "  --skip-workers          Skip workers checks (treat as WARN, no impact on overall)"
            echo "  help       - Show this help"
            echo ""
            echo "Log file: $HEALTH_LOG"
            ;;
    esac
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
