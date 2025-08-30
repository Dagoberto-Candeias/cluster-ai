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

# --- Iniciar Worker ---
SCHEDULER_ADDRESS="${1:-127.0.0.1:8786}" # Usa localhost como padrão se nenhum IP for fornecido

echo "Iniciando Dask Worker e conectando a: $SCHEDULER_ADDRESS"
echo "Configurações: Workers=$DASK_WORKERS, Threads=$DASK_THREADS, Limite de Memória=$DASK_MEMORY_LIMIT"

dask-worker "$SCHEDULER_ADDRESS" \
    --nworkers "$DASK_WORKERS" \
    --nthreads "$DASK_THREADS" \
    --memory-limit "$DASK_MEMORY_LIMIT" \
    --name "worker-$(hostname)-$(date +%s)"