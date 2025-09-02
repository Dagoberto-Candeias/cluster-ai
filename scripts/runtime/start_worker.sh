#!/bin/bash
# Script para iniciar um Dask Worker com configurações otimizadas.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# --- Carregar Configurações ---
CONFIG_FILE="$HOME/.cluster_config/dask.conf"

# Valores padrão
DASK_WORKERS="auto"
DASK_THREADS=2
DASK_MEMORY_LIMIT="auto"
DASK_WORKER_CLASS="dask.distributed.Nanny"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# --- Ativar Ambiente Virtual ---
VENV_PATH="${PROJECT_ROOT}/.venv"
if [ -f "${VENV_PATH}/bin/activate" ]; then
    source "${VENV_PATH}/bin/activate"
    echo "Ambiente virtual ativado."
else
    echo "AVISO: Ambiente virtual não encontrado em ${VENV_PATH}. Usando python do sistema."
fi

# --- Função para escolher scheduler ativo ---
choose_scheduler() {
    local primary_ip="${1:-192.168.0.2}"
    local primary_port="${DASK_SCHEDULER_PORT:-8786}"
    local secondary_ip="${DASK_SCHEDULER_SECONDARY_IP:-192.168.0.3}"
    local secondary_port="${DASK_SCHEDULER_SECONDARY_PORT:-8788}"

    # Verificar scheduler primário
    if timeout 5 bash -c "echo >/dev/tcp/$primary_ip/$primary_port" 2>/dev/null; then
        echo "tls://${primary_ip}:${primary_port}"
        return 0
    fi

    # Verificar scheduler secundário
    if timeout 5 bash -c "echo >/dev/tcp/$secondary_ip/$secondary_port" 2>/dev/null; then
        echo "tls://${secondary_ip}:${secondary_port}"
        return 0
    fi

    # Fallback para primário
    echo "tls://${primary_ip}:${primary_port}"
}

# --- Iniciar Worker ---
SCHEDULER_ADDRESS=$(choose_scheduler "${1:-192.168.0.2}")

# Configurações de segurança
CERT_FILE="${PROJECT_ROOT}/certs/dask_cert.pem"
AUTH_TOKEN="secure_token_12345"

echo "Iniciando Dask Worker com segurança e conectando a: $SCHEDULER_ADDRESS"
echo "Configurações: Workers=$DASK_WORKERS, Threads=$DASK_THREADS, Limite de Memória=$DASK_MEMORY_LIMIT"
echo "Classe do Worker: $DASK_WORKER_CLASS"
echo "Certificado: $CERT_FILE"

if [[ "$DASK_WORKER_CLASS" == "dask_cuda.CUDAWorker" ]] && command -v dask-cuda-worker >/dev/null 2>&1; then
    echo "Modo GPU detectado. Usando dask-cuda-worker com segurança."
    # dask-cuda-worker gerencia automaticamente a atribuição de GPUs
    dask-cuda-worker "$SCHEDULER_ADDRESS" \
        --tls-ca-file "$CERT_FILE" \
        --auth-token "$AUTH_TOKEN" \
        --nworkers "$DASK_WORKERS" \
        --memory-limit "$DASK_MEMORY_LIMIT" \
        --name "gpu-worker-$(hostname)-$(date +%s)"
else
    echo "Modo CPU. Usando dask-worker padrão com segurança."
    dask-worker "$SCHEDULER_ADDRESS" \
        --tls-ca-file "$CERT_FILE" \
        --auth-token "$AUTH_TOKEN" \
        --nworkers "$DASK_WORKERS" \
        --nthreads "$DASK_THREADS" \
        --memory-limit "$DASK_MEMORY_LIMIT" \
        --name "cpu-worker-$(hostname)-$(date +%s)"
fi
