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
    log() { echo "[INFO] $1"; }
    warn() { echo "[WARN] $1"; }
    error() { echo "[ERROR] $1"; }
    success() { echo "[SUCCESS] $1"; }
fi

# --- Constantes ---
NODES_LIST_FILE="$HOME/.cluster_config/nodes_list.conf"
CLUSTER_CONF_FILE="${PROJECT_ROOT}/cluster.yaml" # Alterado para .yaml

# --- Função Principal ---
main() {
    if ! command_exists yq; then
        error "Comando 'yq' não encontrado. É necessário para a sincronização de configuração."
        log "Instale-o com: sudo snap install yq (ou equivalente)."
        return 1
    fi

    if [ ! -f "$NODES_LIST_FILE" ]; then
        warn "Arquivo de lista de workers '$NODES_LIST_FILE' não encontrado. Nada para sincronizar."
        return 0
    fi

    log "Sincronizando '$NODES_LIST_FILE' para '$CLUSTER_CONF_FILE' (YAML)..."

    # Cria um arquivo YAML temporário para construir a configuração
    local temp_yaml_file; temp_yaml_file=$(mktemp -p "$PROJECT_ROOT")
    echo "workers: {}" > "$temp_yaml_file"

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

        # Usa yq para adicionar a entrada do worker ao arquivo YAML temporário
        yq e ".workers[\"$hostname\"].ip = \"${ip}\"" -i "$temp_yaml_file"
        yq e ".workers[\"$hostname\"].port = ${port}" -i "$temp_yaml_file"
        yq e ".workers[\"$hostname\"].user = \"${user}\"" -i "$temp_yaml_file"
        yq e ".workers[\"$hostname\"].status = \"${status}\"" -i "$temp_yaml_file"

    done < "$NODES_LIST_FILE"

    # Atualiza o arquivo de configuração principal, preservando outras chaves que possam existir
    # Se o arquivo principal não existir, ele será criado.
    yq eval-all '. as $item ireduce ({}; . * $item)' "$CLUSTER_CONF_FILE" "$temp_yaml_file" > "${CLUSTER_CONF_FILE}.tmp" 2>/dev/null || cp "$temp_yaml_file" "${CLUSTER_CONF_FILE}.tmp"
    mv "${CLUSTER_CONF_FILE}.tmp" "$CLUSTER_CONF_FILE"
    rm -f "$temp_yaml_file"

    success "Configuração YAML em '$CLUSTER_CONF_FILE' foi atualizada com sucesso."
}

main "$@"