#!/bin/bash
#
# Script para atualizar o cache de status do cluster em background.
# Realiza todas as verificações de rede lentas.
#

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/utils/common.sh"

# --- Constantes ---
CACHE_FILE="${PROJECT_ROOT}/run/status.cache"
REMOTE_WORKERS_CONF="$HOME/.cluster_config/nodes_list.conf"
CONFIG_FILE="${PROJECT_ROOT}/cluster.yaml"

# Função para escrever no cache
set_cache() {
    echo "$1=$2" >> "$CACHE_FILE"
}

# --- Funções de Coleta de Métricas ---

collect_system_metrics() {
    # CPU Load Average (1, 5, 15 min)
    local load_avg; load_avg=$(uptime | awk -F'load average:' '{ print $2 }' | sed 's/^[ \t]*//;s/,//g')
    set_cache "system_load_avg" "$load_avg"

    # Uso de Memória em %
    local mem_usage; mem_usage=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    set_cache "system_mem_usage" "$mem_usage"

    # Uso de Disco em % (partição raiz)
    local disk_usage; disk_usage=$(df -h / | awk 'NR==2{print $5}')
    set_cache "system_disk_usage" "$disk_usage"
}

# --- Função Principal ---
main() {
    # Garante que o diretório de execução exista
    mkdir -p "$(dirname "$CACHE_FILE")"
    # Limpa o cache antigo e começa um novo
    > "$CACHE_FILE"

    # 1. Coletar Métricas do Sistema (CPU, RAM, Disco)
    collect_system_metrics

    # 1. Verificar Serviços Locais
    local DASK_SCHEDULER_PORT; DASK_SCHEDULER_PORT=$(get_config_value "dask.scheduler_port" "$CONFIG_FILE" "8786")
    local DASK_DASHBOARD_PORT; DASK_DASHBOARD_PORT=$(get_config_value "dask.dashboard_port" "$CONFIG_FILE" "8787")
    local OLLAMA_PORT; OLLAMA_PORT=$(get_config_value "services.ollama_port" "$CONFIG_FILE" "11434")
    local OPENWEBUI_PORT; OPENWEBUI_PORT=$(get_config_value "services.openwebui_port" "$CONFIG_FILE" "3000")

    set_cache "service_docker" "$(command_exists docker && docker info >/dev/null 2>&1 && echo 'online' || echo 'offline')"
    set_cache "service_dask_scheduler" "$(port_open "$DASK_SCHEDULER_PORT" && echo 'online' || echo 'offline')"
    set_cache "service_dask_dashboard" "$(port_open "$DASK_DASHBOARD_PORT" && echo 'online' || echo 'offline')"
    set_cache "service_ollama" "$(port_open "$OLLAMA_PORT" && echo 'online' || echo 'offline')"
    set_cache "service_openwebui" "$(port_open "$OPENWEBUI_PORT" && echo 'online' || echo 'offline')"
    set_cache "service_nginx" "$(command_exists nginx && service_active nginx && echo 'online' || echo 'offline')"

    # 2. Verificar Workers Remotos
    if [ ! -f "$REMOTE_WORKERS_CONF" ]; then
        set_cache "workers_total" "0"
        set_cache "workers_online" "0"
        return 0
    fi

    local total_workers=0
    local online_workers=0

    mapfile -t workers < <(grep -vE '^\s*#|^\s*$' "$REMOTE_WORKERS_CONF")

    for worker_line in "${workers[@]}"; do
        local name alias ip user port status
        read -r name alias ip user port status <<< "$worker_line"

        if [[ -z "$name" || -z "$ip" ]]; then continue; fi

        ((total_workers++))

        # Testar conectividade SSH (a verificação mais lenta)
        if timeout 5 ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=no -p "${port:-22}" "${user:-$USER}@$ip" "echo 'OK'" >/dev/null 2>&1; then
            set_cache "worker_${name}_status" "online"
            ((online_workers++))
        else
            set_cache "worker_${name}_status" "offline"
        fi
        set_cache "worker_${name}_info" "$name ($alias) - $ip:${port:-22}"
    done

    set_cache "workers_total" "$total_workers"
    set_cache "workers_online" "$online_workers"
    set_cache "last_update" "$(date '+%Y-%m-%d %H:%M:%S')"
}

main "$@"