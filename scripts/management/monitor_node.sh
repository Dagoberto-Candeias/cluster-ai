#!/bin/bash
# Script para monitorar status de um nó específico

set -euo pipefail

# --- Configuração ---
TARGET_IP="${1:-192.168.0.18}"
TARGET_HOSTNAME="${2:-pc-dago}"
INTERVAL="${3:-30}"  # Intervalo em segundos

# --- Funções ---
section() {
    echo
    echo "=============================="
    echo " $1"
    echo "=============================="
}

progress() {
    echo "[...] $1"
}

success() {
    echo "[SUCCESS] $1"
}

error() {
    echo "[ERROR] $1"
}

warn() {
    echo "[WARN] $1"
}

info() {
    echo "[INFO] $1"
}

log_status() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_node_status() {
    local ip="$1"
    local hostname="$2"

    log_status "Verificando status do nó $hostname ($ip)..."

    # Teste de ping
    if ping -c 1 -W 2 "$ip" >/dev/null 2>&1; then
        log_status "✅ Nó $hostname está online"

        # Teste SSH
        if timeout 3 ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no "$hostname" "echo 'OK'" 2>/dev/null; then
            log_status "✅ SSH funcionando para $hostname"

            # Verificar se Cluster AI está instalado
            if ssh -o ConnectTimeout=2 "$hostname" "test -d ~/Projetos/cluster-ai" 2>/dev/null; then
                log_status "✅ Cluster AI instalado em $hostname"

                # Verificar se serviços estão rodando
                if ssh -o ConnectTimeout=2 "$hostname" "pgrep -f dask" 2>/dev/null; then
                    log_status "✅ Dask rodando em $hostname"
                else
                    log_status "⚠️  Dask não está rodando em $hostname"
                fi

                if ssh -o ConnectTimeout=2 "$hostname" "pgrep -f ollama" 2>/dev/null; then
                    log_status "✅ Ollama rodando em $hostname"
                else
                    log_status "⚠️  Ollama não está rodando em $hostname"
                fi

            else
                log_status "❌ Cluster AI não instalado em $hostname"
            fi

        else
            log_status "❌ SSH não acessível para $hostname"
        fi

    else
        log_status "❌ Nó $hostname está offline"
    fi
}

show_help() {
    echo "Uso: $0 [IP] [HOSTNAME] [INTERVALO]"
    echo
    echo "Parâmetros:"
    echo "  IP         - Endereço IP do nó (padrão: 192.168.0.18)"
    echo "  HOSTNAME   - Nome do host (padrão: pc-dago)"
    echo "  INTERVALO  - Intervalo entre verificações em segundos (padrão: 30)"
    echo
    echo "Exemplos:"
    echo "  $0                          # Monitora pc-dago a cada 30s"
    echo "  $0 192.168.0.18 pc-dago 60  # Monitora a cada 60s"
    echo "  $0 192.168.0.18 pc-dago 10  # Monitora a cada 10s"
}

main() {
    if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
        show_help
        exit 0
    fi

    section "👀 Monitoramento de Nó"
    info "Monitorando nó: $TARGET_HOSTNAME ($TARGET_IP)"
    info "Intervalo: $INTERVAL segundos"
    info "Pressione Ctrl+C para parar"
    echo

    # Loop de monitoramento
    while true; do
        check_node_status "$TARGET_IP" "$TARGET_HOSTNAME"
        echo
        sleep "$INTERVAL"
    done
}

main "$@"
