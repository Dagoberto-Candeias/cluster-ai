#!/bin/bash
#
# Script de Health Check para ser executado em um worker remoto.
# Coleta informações sobre o sistema, recursos e processos Dask.
#

set -euo pipefail

# --- Funções de Formatação ---

# Cores (verificar se o terminal suporta)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    GREEN=''
    YELLOW=''
    RED=''
    BLUE=''
    NC=''
fi

header() {
    echo -e "\n${BLUE}--- $1 ---${NC}"
}

check_ok() {
    echo -e "${GREEN}✅ OK${NC} - $1"
}

check_warn() {
    echo -e "${YELLOW}⚠️  WARN${NC} - $1"
}

check_fail() {
    echo -e "${RED}❌ FAIL${NC} - $1"
}

echo "============================================="
echo "🩺 Health Check do Worker: $(hostname)"
echo "============================================="
echo "Data: $(date)"

# 1. Informações do Sistema
header "Informações do Sistema"
echo "Hostname: $(hostname)"
echo "OS: $(uname -s -r)"
echo "Uptime: $(uptime -p 2>/dev/null || uptime)"

# 2. Recursos do Sistema
header "Recursos do Sistema"
# CPU
cpu_cores=$(nproc 2>/dev/null || echo 1)
load_avg=$(uptime | awk -F'load average: ' '{print $2}')
echo "CPU Cores: $cpu_cores"
echo "Carga Média (1m, 5m, 15m): $load_avg"

# Memória
if command -v free >/dev/null; then
    mem_total=$(free -m | awk '/Mem:/ {print $2}')
    mem_used=$(free -m | awk '/Mem:/ {print $3}')
    if [ "$mem_total" -gt 0 ]; then
        mem_perc=$((mem_used * 100 / mem_total))
        echo "Memória: ${mem_used}MB / ${mem_total}MB (${mem_perc}%)"
        if [ "$mem_perc" -gt 90 ]; then
            check_fail "Uso de memória muito alto."
        elif [ "$mem_perc" -gt 80 ]; then
            check_warn "Uso de memória alto."
        else
            check_ok "Uso de memória normal."
        fi
    fi
fi

# Disco
disk_usage=$(df -h / | awk 'NR==2 {print $5}')
disk_perc=$(echo "$disk_usage" | tr -d '%')
echo "Uso de Disco (raiz): $disk_usage"
if [ "$disk_perc" -gt 95 ]; then
    check_fail "Uso de disco crítico."
elif [ "$disk_perc" -gt 85 ]; then
    check_warn "Uso de disco alto."
else
    check_ok "Uso de disco normal."
fi

# 3. Processos do Cluster AI
header "Processos do Cluster"
dask_worker_count=$(pgrep -fc dask-worker)
    if [ "$dask_worker_count" -gt 0 ]; then
        check_ok "$dask_worker_count processo(s) 'dask-worker' em execução."
        pids=$(pgrep -f dask-worker | tr '\n' ' ')
        ps -f -p $pids | tail -n +2
    else
        check_warn "Nenhum processo 'dask-worker' encontrado."
    fi

echo -e "\n${GREEN}Health Check concluído.${NC}"
