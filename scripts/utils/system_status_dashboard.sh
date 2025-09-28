#!/bin/bash
# =============================================================================
# Sistema de Status Geral do Cluster AI - Dashboard Consolidado
# =============================================================================
# Este script fornece um resumo completo do estado do sistema, serviços,
# servidores, endereços, workers, hardware e configurações.
#
# Autor: Cluster AI Team
# Data: 2025-01-27
# Versão: 1.0.0
# Arquivo: system_status_dashboard.sh
# =============================================================================

set -euo pipefail

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/logs"
STATUS_LOG="${LOG_DIR}/system_status.log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Criar diretório de logs
mkdir -p "$LOG_DIR"

# =============================================================================
# FUNÇÕES AUXILIARES
# =============================================================================

log_status() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$STATUS_LOG"
}

print_header() {
    local title="$1"
    echo -e "\n${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC} ${BOLD}${title}${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════════╗${NC}"
}

print_section() {
    local title="$1"
    echo -e "\n${BOLD}${CYAN}▶ ${title}${NC}"
    echo -e "${CYAN}$(printf '%.0s─' {1..80})${NC}"
}

status_indicator() {
    local status="$1"
    case "$status" in
        "OK"|"RUNNING"|"ACTIVE"|"HEALTHY")
            echo -e "${GREEN}●${NC} $status"
            ;;
        "WARNING"|"DEGRADED"|"PARTIAL")
            echo -e "${YELLOW}●${NC} $status"
            ;;
        "ERROR"|"FAILED"|"DOWN"|"INACTIVE")
            echo -e "${RED}●${NC} $status"
            ;;
        *)
            echo -e "${BLUE}●${NC} $status"
            ;;
    esac
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# =============================================================================
# INFORMAÇÕES DO SISTEMA
# =============================================================================

get_system_info() {
    print_section "INFORMAÇÕES DO SISTEMA"
    
    echo -e "Hostname: ${BOLD}$(hostname)${NC}"
    echo -e "Sistema Operacional: ${BOLD}$(uname -s)${NC}"
    echo -e "Distribuição: ${BOLD}$(lsb_release -d 2>/dev/null | cut -f2 || echo "N/A")${NC}"
    echo -e "Kernel: ${BOLD}$(uname -r)${NC}"
    echo -e "Arquitetura: ${BOLD}$(uname -m)${NC}"
    echo -e "Uptime: ${BOLD}$(uptime -p 2>/dev/null || uptime)${NC}"
    echo -e "Data/Hora: ${BOLD}$(date)${NC}"
    
    # Timezone
    if [ -f /etc/timezone ]; then
        echo -e "Timezone: ${BOLD}$(cat /etc/timezone)${NC}"
    fi
}

# =============================================================================
# RECURSOS DE HARDWARE
# =============================================================================

get_hardware_info() {
    print_section "RECURSOS DE HARDWARE"
    
    # CPU
    local cpu_cores
    cpu_cores=$(nproc)
    local cpu_model
    cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print 100 - $1}' 2>/dev/null || echo "N/A")
    
    echo -e "CPU: ${BOLD}${cpu_model}${NC}"
    echo -e "Cores: ${BOLD}${cpu_cores}${NC}"
    echo -e "Uso CPU: ${BOLD}${cpu_usage}%${NC}"
    
    # Memória
    if command_exists free; then
        local mem_info
        mem_info=$(free -h | grep "Mem:")
        local mem_total
        mem_total=$(echo "$mem_info" | awk '{print $2}')
        local mem_used
        mem_used=$(echo "$mem_info" | awk '{print $3}')
        local mem_percent
        mem_percent=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        
        echo -e "Memória Total: ${BOLD}${mem_total}${NC}"
        echo -e "Memória Usada: ${BOLD}${mem_used} (${mem_percent}%)${NC}"
    fi
    
    # Disco
    local disk_info
    disk_info=$(df -h . | tail -1)
    local disk_total
    disk_total=$(echo "$disk_info" | awk '{print $2}')
    local disk_used
    disk_used=$(echo "$disk_info" | awk '{print $3}')
    local disk_percent
    disk_percent=$(echo "$disk_info" | awk '{print $5}')
    
    echo -e "Disco Total: ${BOLD}${disk_total}${NC}"
    echo -e "Disco Usado: ${BOLD}${disk_used} (${disk_percent})${NC}"
    
    # GPU (se disponível)
    if command_exists nvidia-smi; then
        local gpu_info
        gpu_info=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits | head -1)
        echo -e "GPU: ${BOLD}${gpu_info}${NC}"
    fi
}

# =============================================================================
# CONFIGURAÇÃO DE REDE
# =============================================================================

get_network_info() {
    print_section "CONFIGURAÇÃO DE REDE"
    
    # IP Local
    local local_ip
    local_ip=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "N/A")
    echo -e "IP Local: ${BOLD}${local_ip}${NC}"
    
    # IP Público
    local public_ip
    public_ip=$(curl -s ifconfig.me 2>/dev/null || echo "N/A")
    echo -e "IP Público: ${BOLD}${public_ip}${NC}"
    
    # Interfaces de rede
    echo -e "Interfaces de Rede:"
    if command_exists ip; then
        ip addr show | grep -E "^[0-9]+:" | awk '{print "  - " $2}' | sed 's/:$//'
    fi
    
    # Conectividade
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo -e "Conectividade Internet: $(status_indicator "OK")"
    else
        echo -e "Conectividade Internet: $(status_indicator "ERROR")"
    fi
}

# =============================================================================
# STATUS DOS SERVIÇOS
# =============================================================================

get_services_status() {
    print_section "STATUS DOS SERVIÇOS"
    
    # Ollama
    if command_exists ollama; then
        if pgrep -f "ollama" >/dev/null 2>&1; then
            local model_count
            model_count=$(ollama list 2>/dev/null | wc -l)
            echo -e "Ollama: $(status_indicator "RUNNING") ($((model_count - 1)) modelos)"
        else
            echo -e "Ollama: $(status_indicator "DOWN")"
        fi
    else
        echo -e "Ollama: $(status_indicator "NOT_INSTALLED")"
    fi
    
    # Docker
    if command_exists docker; then
        if docker info >/dev/null 2>&1; then
            local container_count
            container_count=$(docker ps -q | wc -l)
            echo -e "Docker: $(status_indicator "RUNNING") ($container_count containers)"
        else
            echo -e "Docker: $(status_indicator "DOWN")"
        fi
    else
        echo -e "Docker: $(status_indicator "NOT_INSTALLED")"
    fi
    
    # Python
    if command_exists python3; then
        local python_version
        python_version=$(python3 --version | cut -d' ' -f2)
        echo -e "Python: $(status_indicator "OK") (v${python_version})"
    else
        echo -e "Python: $(status_indicator "NOT_INSTALLED")"
    fi
    
    # Dask
    local dask_pid_file="${PROJECT_ROOT}/.pids/dask_cluster.pid"
    if [ -f "$dask_pid_file" ] && ps -p "$(cat "$dask_pid_file")" >/dev/null 2>&1; then
        echo -e "Dask Cluster: $(status_indicator "RUNNING")"
    else
        echo -e "Dask Cluster: $(status_indicator "DOWN")"
    fi
    
    # Web Server
    local web_pid_file="${PROJECT_ROOT}/.web_server_pid"
    if [ -f "$web_pid_file" ] && ps -p "$(cat "$web_pid_file")" >/dev/null 2>&1; then
        echo -e "Web Server: $(status_indicator "RUNNING")"
    else
        echo -e "Web Server: $(status_indicator "DOWN")"
    fi
}

# =============================================================================
# PORTAS E ENDEREÇOS
# =============================================================================

get_ports_addresses() {
    print_section "PORTAS E ENDEREÇOS DOS SERVIÇOS"
    
    echo -e "Serviços Principais:"
    echo -e "  • Ollama API: ${BOLD}http://localhost:11434${NC}"
    echo -e "  • OpenWebUI: ${BOLD}http://localhost:3000${NC}"
    echo -e "  • Dask Dashboard: ${BOLD}http://localhost:8787${NC}"
    echo -e "  • Dask Scheduler: ${BOLD}tcp://localhost:8786${NC}"
    echo -e "  • Backend API: ${BOLD}http://localhost:8000${NC}"
    echo -e "  • Prometheus: ${BOLD}http://localhost:9090${NC}"
    echo -e "  • Grafana: ${BOLD}http://localhost:3001${NC}"
    
    echo -e "\nPortas em Uso:"
    if command_exists netstat; then
        netstat -tlnp 2>/dev/null | grep -E ":(3000|8000|8786|8787|9090|3001|11434)" | while read -r line; do
            local port
            port=$(echo "$line" | awk '{print $4}' | cut -d: -f2)
            local status
            status=$(echo "$line" | awk '{print $6}')
            echo -e "  • Porta ${port}: ${status}"
        done
    fi
}

# =============================================================================
# WORKERS CONFIGURADOS
# =============================================================================

get_workers_status() {
    print_section "STATUS DOS WORKERS"
    
    local worker_config="${PROJECT_ROOT}/cluster.yaml"
    if [ ! -f "$worker_config" ]; then
        echo -e "Configuração de workers: $(status_indicator "NOT_FOUND")"
        return 1
    fi
    
    if ! command_exists yq; then
        echo -e "yq não encontrado: $(status_indicator "ERROR")"
        return 1
    fi
    
    local workers
    mapfile -t workers < <(yq e '.workers | keys | .[]' "$worker_config" 2>/dev/null || echo "")
    
    if [ ${#workers[@]} -eq 0 ]; then
        echo -e "Workers configurados: $(status_indicator "NONE")"
        return 0
    fi
    
    echo -e "Workers Configurados: ${BOLD}${#workers[@]}${NC}"
    
    local healthy=0
    for worker in "${workers[@]}"; do
        local worker_info
        worker_info=$(yq e ".workers[\"$worker\"]" "$worker_config")
        local host
        host=$(echo "$worker_info" | yq e '.host' -)
        local user
        user=$(echo "$worker_info" | yq e '.user' -)
        local port
        port=$(echo "$worker_info" | yq e '.port' -)
        
        echo -n "  • ${worker} (${user}@${host}:${port}): "
        
        if ssh -o ConnectTimeout=5 -o BatchMode=yes -p "$port" "$user@$host" "echo 'OK'" >/dev/null 2>&1; then
            echo -e "$(status_indicator "HEALTHY")"
            ((healthy++))
        else
            echo -e "$(status_indicator "UNREACHABLE")"
        fi
    done
    
    echo -e "Workers Saudáveis: ${BOLD}${healthy}/${#workers[@]}${NC}"
}

# =============================================================================
# MODELOS OLLAMA
# =============================================================================

get_models_status() {
    print_section "MODELOS OLLAMA"
    
    if ! command_exists ollama; then
        echo -e "Ollama: $(status_indicator "NOT_INSTALLED")"
        return 1
    fi
    
    if ! curl -s "http://127.0.0.1:11434/api/tags" >/dev/null 2>&1; then
        echo -e "Ollama API: $(status_indicator "DOWN")"
        return 1
    fi
    
    local models
    models=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' | sort)
    
    if [ -z "$models" ]; then
        echo -e "Modelos instalados: $(status_indicator "NONE")"
        return 0
    fi
    
    local model_count
    model_count=$(echo "$models" | wc -l)
    echo -e "Modelos instalados: ${BOLD}${model_count}${NC}"
    
    echo "$models" | while read -r model; do
        if [ -n "$model" ]; then
            echo -e "  • ${model}"
        fi
    done
}

# =============================================================================
# LOGS RECENTES
# =============================================================================

get_recent_logs() {
    print_section "LOGS RECENTES"
    
    echo -e "Logs do Sistema:"
    
    # Health check log
    if [ -f "${LOG_DIR}/health_check.log" ]; then
        echo -e "\n${CYAN}Health Check (últimas 3 linhas):${NC}"
        tail -3 "${LOG_DIR}/health_check.log" | while read -r line; do
            echo -e "  $line"
        done
    fi
    
    # Cluster log
    if [ -f "${LOG_DIR}/cluster_ai.log" ]; then
        echo -e "\n${CYAN}Cluster AI (últimas 3 linhas):${NC}"
        tail -3 "${LOG_DIR}/cluster_ai.log" | while read -r line; do
            echo -e "  $line"
        done
    fi
    
    # System log
    if [ -f "$STATUS_LOG" ]; then
        echo -e "\n${CYAN}Status do Sistema (últimas 3 linhas):${NC}"
        tail -3 "$STATUS_LOG" | while read -r line; do
            echo -e "  $line"
        done
    fi
}

# =============================================================================
# RESUMO EXECUTIVO
# =============================================================================

get_executive_summary() {
    print_section "RESUMO EXECUTIVO"
    
    local overall_status="OK"
    local issues=()
    
    # Verificar serviços críticos
    if ! pgrep -f "ollama" >/dev/null 2>&1; then
        overall_status="WARNING"
        issues+=("Ollama não está rodando")
    fi
    
    if ! command_exists docker || ! docker info >/dev/null 2>&1; then
        overall_status="WARNING"
        issues+=("Docker não está disponível")
    fi
    
    # Verificar recursos
    local mem_usage
    mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}' 2>/dev/null || echo "0")
    if [ "$mem_usage" -gt 90 ]; then
        overall_status="WARNING"
        issues+=("Uso de memória alto: ${mem_usage}%")
    fi
    
    local disk_usage
    disk_usage=$(df . | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        overall_status="WARNING"
        issues+=("Uso de disco alto: ${disk_usage}%")
    fi
    
    # Resultado final
    echo -e "Status Geral: $(status_indicator "$overall_status")"
    
    if [ ${#issues[@]} -gt 0 ]; then
        echo -e "\nProblemas Identificados:"
        for issue in "${issues[@]}"; do
            echo -e "  • $issue"
        done
    else
        echo -e "\n${GREEN}✓${NC} Todos os sistemas operacionais"
    fi
    
    log_status "INFO" "System status check completed - Overall: $overall_status"
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    cd "$PROJECT_ROOT"
    
    # Cabeçalho principal
    print_header "CLUSTER AI - DASHBOARD DE STATUS DO SISTEMA"
    echo -e "${BOLD}${BLUE}║${NC} Data: $(date)"
    echo -e "${BOLD}${BLUE}║${NC} Projeto: Cluster AI v2.0.0"
    echo -e "${BOLD}${BLUE}║${NC} Localização: $PROJECT_ROOT"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    
    # Executar todas as verificações
    get_system_info
    get_hardware_info
    get_network_info
    get_services_status
    get_ports_addresses
    get_workers_status
    get_models_status
    get_recent_logs
    get_executive_summary
    
    echo -e "\n${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC} Dashboard gerado em: $(date)"
    echo -e "${BOLD}${BLUE}║${NC} Log salvo em: $STATUS_LOG"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
