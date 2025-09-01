#!/bin/bash
# Script para descobrir nós na rede local e popular o arquivo de configuração.

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

# --- Funções ---

check_dependencies() {
    if ! command_exists nmap; then
        error "Comando 'nmap' não encontrado. É necessário para a descoberta de nós."
        info "Instale-o com: sudo apt install nmap (ou equivalente para sua distro)."
        return 1
    fi
    return 0
}

discover_nodes() {
    section "Descoberta de Nós na Rede"
    if ! check_dependencies; then return 1; fi

    read -p "Digite a faixa de IP a ser escaneada (ex: 192.168.1.0/24): " ip_range
    if [ -z "$ip_range" ]; then
        error "Faixa de IP não pode ser vazia."
        return 1
    fi

    log "Escaneando a rede em busca de máquinas com a porta 22 (SSH) aberta..."
    # -sn: Ping scan, -T4: Agressive timing, -oG -: Grepable output
    local discovered_hosts
    discovered_hosts=$(sudo nmap -sn "$ip_range" | awk '/Up$/{print $2}')

    if [ -z "$discovered_hosts" ]; then
        warn "Nenhum host ativo encontrado na faixa especificada."
        return 0
    fi

    log "Hosts ativos encontrados. Tentando resolver nomes e adicionar à lista..."
    mkdir -p "$(dirname "$NODES_LIST_FILE")"
    touch "$NODES_LIST_FILE"

    for ip in $discovered_hosts; do
        local hostname; hostname=$(nslookup "$ip" | awk -F'=' '/name =/{print $2}' | sed 's/\.$//; s/ //g' || echo "$ip")
        
        # Verificar se a entrada já existe (por IP ou hostname)
        if grep -q -E "($hostname|$ip)" "$NODES_LIST_FILE"; then
            info "Nó '$hostname' ($ip) já existe na lista. Pulando."
            continue
        fi

        if confirm_operation "Encontrado: '$hostname' ($ip). Deseja adicionar ao cluster?"; then
            read -p "  -> Digite o nome de usuário para SSH neste nó: " ssh_user
            if [ -n "$ssh_user" ]; then
                echo "$hostname $ip $ssh_user" >> "$NODES_LIST_FILE"
                success "Nó '$hostname' adicionado com sucesso."
            else
                warn "Nome de usuário vazio. Nó não adicionado."
            fi
        fi
    done

    success "Descoberta de nós concluída."
    log "Arquivo de nós atualizado em: $NODES_LIST_FILE"
    cat "$NODES_LIST_FILE"
}

# --- Menu Principal ---
main() {
    discover_nodes
}

main "$@"