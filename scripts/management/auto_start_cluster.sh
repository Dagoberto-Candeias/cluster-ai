#!/bin/bash
# Script para iniciar automaticamente o servidor e os workers Dask na mesma rede

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REMOTE_WORKER_MANAGER="${PROJECT_ROOT}/scripts/management/remote_worker_manager.sh"
DISCOVER_NODES="${PROJECT_ROOT}/scripts/management/discover_nodes.sh"
ACTIVATE_SERVER="${PROJECT_ROOT}/scripts/deployment/activate_server.sh"
NODES_LIST_FILE="$HOME/.cluster_config/nodes_list.conf"

# Função para iniciar o servidor
start_server() {
    echo "Iniciando servidor (scheduler e serviços)..."
    bash "$ACTIVATE_SERVER"
}

# Função para descobrir nós na rede e atualizar lista
discover_and_update_nodes() {
    echo "Descobrindo nós na rede e atualizando lista de workers..."
    # Executa descoberta de nós em modo automático (sem interação)
    # Usa faixa de IP fixa para rede local para evitar erro de entrada do usuário
    local ip_range="192.168.0.0/24"
    if bash "$DISCOVER_NODES" auto "$ip_range"; then
        echo "Descoberta concluída."
    else
        echo "Falha na descoberta de nós."
        return 1
    fi
}

# Função para iniciar workers remotamente
start_workers() {
    if [ ! -f "$NODES_LIST_FILE" ]; then
        echo "Arquivo de lista de nós não encontrado: $NODES_LIST_FILE"
        return 1
    fi

    # Extrair IP ou hostname do scheduler do cluster.conf
    SCHEDULER_ADDR=$(grep '^NODE_IP=' "$PROJECT_ROOT/cluster.conf" | cut -d'=' -f2)
    if [ -z "$SCHEDULER_ADDR" ]; then
        echo "Não foi possível obter o endereço do scheduler do cluster.conf"
        return 1
    fi

    echo "Iniciando workers remotos conectando ao scheduler em $SCHEDULER_ADDR:8786"
    bash "$REMOTE_WORKER_MANAGER" start "$SCHEDULER_ADDR"
}

# Função principal
main() {
    start_server
    discover_and_update_nodes
    start_workers
    echo "Cluster AI iniciado com servidor e workers."
}

main "$@"
