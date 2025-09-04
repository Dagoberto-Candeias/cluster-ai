#!/bin/bash
# Script para registrar um novo worker (Linux ou Android) no servidor principal.
# Descrição: Adiciona a chave SSH do worker e o registra no nodes_list.conf.

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Constantes ---
NODES_LIST_FILE="$HOME/.cluster_config/nodes_list.conf"
AUTHORIZED_KEYS_FILE="$HOME/.ssh/authorized_keys"

# --- Funções ---

add_node_to_list() {
    local hostname="$1"
    local user="$2"
    local port="$3"
    
    log "Adicionando nó à lista de workers conhecidos..."
    local ip
    ip=$(ssh -p "$port" "$user@$hostname" "ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print \$2}' | head -n 1" 2>/dev/null || echo "IP_N/A")

    if [ "$ip" == "IP_N/A" ]; then
        error "Não foi possível obter o IP do nó remoto. Adicione-o manualmente."
        return 1
    fi

    mkdir -p "$(dirname "$NODES_LIST_FILE")"
    touch "$NODES_LIST_FILE"

    if grep -q -E "($hostname|$ip)" "$NODES_LIST_FILE"; then
        info "Nó '$hostname' ($ip) já existe na lista."
    else
        echo "$hostname $ip $user $port" >> "$NODES_LIST_FILE"
        success "Nó '$hostname' ($ip) adicionado a $NODES_LIST_FILE."
    fi
}

# --- Script Principal ---
main() {
    section "Registrador de Novo Worker"
    
    read -p "Digite o nome de usuário do novo worker: " remote_user
    read -p "Digite o hostname ou IP do novo worker: " remote_host
    read -p "Digite a porta SSH do worker (padrão: 8022 para Android, 22 para Linux): " remote_port
    remote_port=${remote_port:-8022}

    echo ""
    warn "Agora, cole a chave SSH pública completa do worker (geralmente começa com 'ssh-rsa' ou 'ssh-ed25519'):"
    read -p "> " public_key

    if [ -z "$remote_user" ] || [ -z "$remote_host" ] || [ -z "$public_key" ]; then
        error "Usuário, host e chave pública são obrigatórios. Abortando."
        return 1
    fi

    subsection "1. Adicionando Chave SSH ao Servidor"
    mkdir -p "$(dirname "$AUTHORIZED_KEYS_FILE")"
    touch "$AUTHORIZED_KEYS_FILE"
    if grep -qF -- "$public_key" "$AUTHORIZED_KEYS_FILE"; then
        info "A chave pública já existe em authorized_keys."
    else
        echo "$public_key" >> "$AUTHORIZED_KEYS_FILE"
        success "Chave pública adicionada com sucesso."
    fi

    subsection "2. Testando Conexão e Registrando Nó"
    add_node_to_list "$remote_host" "$remote_user" "$remote_port"

    echo ""
    success "🎉 Worker '$remote_host' registrado no cluster!"
}

main "$@"