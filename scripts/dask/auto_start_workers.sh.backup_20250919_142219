#!/bin/bash
# Script para inicialização automática dos workers Dask com SSD externo

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="${PROJECT_ROOT}/scripts/dask"
LOG_DIR="${PROJECT_ROOT}/logs"
WORKER_LOG="${LOG_DIR}/dask_workers_$(date +%Y%m%d_%H%M%S).log"

# Carregar configurações
if [ -f "${PROJECT_ROOT}/cluster.conf" ]; then
    source "${PROJECT_ROOT}/cluster.conf"
fi

# Configurações padrão
EXTERNAL_SSD="${external_mount_point:-/mnt/external_ssd}"
DASK_SPILL_DIR="${dask_spill_dir:-${EXTERNAL_SSD}/dask-spill}"
SCHEDULER_PORT="${scheduler_port:-8786}"
N_WORKERS="${n_workers:-2}"
THREADS_PER_WORKER="${threads_per_worker:-2}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }

# Verificar se SSD externo está montado
check_external_ssd() {
    section "Verificando SSD Externo"

    if [ ! -d "$EXTERNAL_SSD" ]; then
        error "SSD externo não encontrado em: $EXTERNAL_SSD"
        exit 1
    fi

    # Verificar espaço disponível
    local available_space
    available_space=$(df "$EXTERNAL_SSD" | tail -1 | awk '{print $4}')

    if [ "$available_space" -lt 1048576 ]; then  # Menos de 1GB
        warn "Pouco espaço disponível no SSD externo: ${available_space}KB"
    fi

    log "✅ SSD externo OK: $EXTERNAL_SSD"
}

# Preparar diretórios
setup_directories() {
    section "Preparando Diretórios"

    mkdir -p "$DASK_SPILL_DIR"
    mkdir -p "$LOG_DIR"

    # Configurar permissões
    chmod 755 "$DASK_SPILL_DIR"
    chmod 755 "$LOG_DIR"

    log "✅ Diretórios preparados"
    log "   Spill dir: $DASK_SPILL_DIR"
    log "   Log dir: $LOG_DIR"
}

# Verificar se scheduler está rodando
check_scheduler() {
    section "Verificando Scheduler Dask"

    if ! pgrep -f "dask-scheduler" >/dev/null && ! pgrep -f "start_dask_cluster" >/dev/null; then
        warn "Scheduler Dask não está rodando"
        log "Iniciando scheduler..."

        # Tentar iniciar scheduler
        if [ -f "${SCRIPT_DIR}/start_dask_cluster_fixed.py" ]; then
            nohup python3 "${SCRIPT_DIR}/start_dask_cluster_fixed.py" "$PROJECT_ROOT" >> "$WORKER_LOG" 2>&1 &
            sleep 5

            if pgrep -f "start_dask_cluster_fixed.py" >/dev/null; then
                log "✅ Scheduler iniciado com sucesso"
            else
                error "Falha ao iniciar scheduler"
                exit 1
            fi
        else
            error "Script do scheduler não encontrado"
            exit 1
        fi
    else
        log "✅ Scheduler já está rodando"
    fi
}

# Iniciar workers
start_workers() {
    section "Iniciando Workers Dask"

    local worker_count=0

    # Verificar workers existentes
    local existing_workers
    existing_workers=$(pgrep -f "dask-worker" | wc -l)

    if [ "$existing_workers" -ge "$N_WORKERS" ]; then
        log "✅ Já existem $existing_workers workers rodando"
        return
    fi

    # Calcular quantos workers iniciar
    local workers_to_start=$((N_WORKERS - existing_workers))

    log "Iniciando $workers_to_start workers..."

    for ((i=1; i<=workers_to_start; i++)); do
        log "Iniciando worker $i/$workers_to_start"

        # Iniciar worker com configurações otimizadas
        nohup dask-worker \
            --scheduler-port "$SCHEDULER_PORT" \
            --nthreads "$THREADS_PER_WORKER" \
            --memory-limit 4GB \
            --local-directory "$DASK_SPILL_DIR" \
            --preload dask.distributed \
            tcp://localhost:"$SCHEDULER_PORT" \
            >> "$WORKER_LOG" 2>&1 &

        sleep 2
        worker_count=$((worker_count + 1))
    done

    # Verificar se workers iniciaram
    sleep 3
    local final_worker_count
    final_worker_count=$(pgrep -f "dask-worker" | wc -l)

    if [ "$final_worker_count" -ge "$N_WORKERS" ]; then
        log "✅ $final_worker_count workers iniciados com sucesso"
    else
        warn "Apenas $final_worker_count de $N_WORKERS workers iniciados"
    fi
}

# Otimizar sistema para workers
optimize_system() {
    section "Otimizando Sistema"

    # Ajustar limites do sistema
    ulimit -n 65536 2>/dev/null || true

    # Configurar swap no SSD externo se disponível
    if [ -d "$EXTERNAL_SSD" ]; then
        local swap_file="${EXTERNAL_SSD}/swap/swapfile"

        if [ ! -f "$swap_file" ]; then
            log "Criando swap file no SSD externo..."
            mkdir -p "${EXTERNAL_SSD}/swap"
            fallocate -l 8G "$swap_file" 2>/dev/null || dd if=/dev/zero of="$swap_file" bs=1M count=8192
            chmod 600 "$swap_file"
            mkswap "$swap_file"
            swapon "$swap_file"
            log "✅ Swap de 8GB criado no SSD externo"
        fi
    fi

    log "✅ Otimizações aplicadas"
}

# Função principal
main() {
    section "🚀 INICIALIZAÇÃO AUTOMÁTICA DOS WORKERS DASK"

    log "Configurações:"
    log "  SSD Externo: $EXTERNAL_SSD"
    log "  Spill Dir: $DASK_SPILL_DIR"
    log "  Workers: $N_WORKERS"
    log "  Threads/Worker: $THREADS_PER_WORKER"
    log "  Scheduler Port: $SCHEDULER_PORT"

    # Executar etapas
    check_external_ssd
    setup_directories
    optimize_system
    check_scheduler
    start_workers

    section "📊 STATUS FINAL"

    # Mostrar status dos processos
    log "Processos Dask ativos:"
    ps aux | grep -E "(dask-scheduler|dask-worker|start_dask_cluster)" | grep -v grep | while read -r line; do
        echo "   $line"
    done

    # Verificar conectividade
    if command -v curl >/dev/null 2>&1; then
        local dashboard_port
        dashboard_port=$(grep -oP "dashboard_port=\K\d+" "${PROJECT_ROOT}/cluster.conf" 2>/dev/null || echo "8787")

        if curl -s "http://localhost:${dashboard_port}/status" >/dev/null 2>&1; then
            log "✅ Dashboard acessível: http://localhost:${dashboard_port}"
        else
            warn "Dashboard não acessível na porta ${dashboard_port}"
        fi
    fi

    log "✅ Inicialização automática concluída!"
    log "Logs salvos em: $WORKER_LOG"
}

# Executar função principal
main "$@"
