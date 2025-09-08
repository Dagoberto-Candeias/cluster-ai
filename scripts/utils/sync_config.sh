#!/bin/bash
#
# Script para sincronizar a configuração de workers de nodes_list.conf para cluster.conf (JSON)
#

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

# Carregar funções comuns, se existirem
if [ -f "${UTILS_DIR}/common.sh" ]; then
    source "${UTILS_DIR}/common.sh"
else
    # Fallback de funções de log
    info() { echo "[INFO] $1"; }
    warn() { echo "[WARN] $1"; }
    error() { echo "[ERROR] $1"; }
    success() { echo "[SUCCESS] $1"; }
fi

# --- Constantes ---
NODES_LIST_FILE="$HOME/.cluster_config/nodes_list.conf"
CLUSTER_CONF_FILE="${PROJECT_ROOT}/cluster.conf"

# --- Função Principal ---
main() {
    if ! command_exists jq; then
        error "Comando 'jq' não encontrado. É necessário para a sincronização de configuração."
        info "Instale-o com: sudo apt install jq (ou equivalente para sua distro)."
        return 1
    fi

    if [ ! -f "$NODES_LIST_FILE" ]; then
        warn "Arquivo de lista de workers não encontrado em '$NODES_LIST_FILE'. Nada para sincronizar."
        return 0
    fi

    info "Sincronizando '$NODES_LIST_FILE' para '$CLUSTER_CONF_FILE'..."

    # Inicia um objeto JSON vazio para os workers
    local workers_json="{}"

    # Lê o arquivo de workers linha por linha
    while IFS= read -r line; do
        # Ignora comentários e linhas vazias
        if [[ "$line" =~ ^# ]] || [[ -z "$line" ]]; then
            continue
        fi

        local hostname alias ip user port status
        read -r hostname alias ip user port status <<< "$line"

        # Pula linhas malformadas
        if [[ -z "$hostname" || -z "$ip" ]]; then
            continue
        fi

        # Define valores padrão
        user="${user:-$USER}"
        port="${port:-22}"
        status="${status:-inactive}"

        # Constrói o objeto JSON para o worker atual e o adiciona ao objeto principal
        workers_json=$(echo "$workers_json" | jq \
            --arg name "$hostname" \
            --arg ip "$ip" \
            --argjson port "$port" \
            --arg user "$user" \
            --arg status "$status" \
            '. + {($name): {ip: $ip, port: $port, user: $user, status: $status}}')

    done < "$NODES_LIST_FILE"

    # Garante que o arquivo cluster.conf exista com um objeto JSON válido
    [ ! -f "$CLUSTER_CONF_FILE" ] && echo "{}" > "$CLUSTER_CONF_FILE"

    # Atualiza a chave "workers" no cluster.conf, preservando o resto do conteúdo
    jq --argjson workers "$workers_json" '.workers = $workers' "$CLUSTER_CONF_FILE" > "${CLUSTER_CONF_FILE}.tmp" && mv "${CLUSTER_CONF_FILE}.tmp" "$CLUSTER_CONF_FILE"

    success "Configuração JSON em '$CLUSTER_CONF_FILE' foi atualizada com sucesso."
}

main "$@"