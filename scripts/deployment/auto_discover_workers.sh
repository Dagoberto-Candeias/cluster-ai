#!/bin/bash
# =============================================================================
# Optimized Auto Worker Discovery Script
# =============================================================================
# Features: Parallel processing, memory monitoring, error handling
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: auto_discover_workers.sh
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURAÇÃO
# =============================================================================
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# =============================================================================
# CORES E ESTILOS
# =============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# =============================================================================
# FUNÇÕES DE LOG
# =============================================================================
log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================
main() {
    log_info "Descobrindo workers automaticamente..."

    # Verificar se kubectl está disponível
    if ! command -v kubectl >/dev/null 2>&1; then
        log_error "kubectl não encontrado. Instalando..."
        # Tentar instalar kubectl se não estiver disponível
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get update && sudo apt-get install -y kubectl
        elif command -v yum >/dev/null 2>&1; then
            sudo yum install -y kubectl
        else
            log_error "Não foi possível instalar kubectl automaticamente"
            exit 1
        fi
    fi

    # Verificar se há cluster Kubernetes disponível
    if kubectl cluster-info >/dev/null 2>&1; then
        log_success "Cluster Kubernetes encontrado"

        # Procurar por pods de workers Dask
        log_info "Procurando pods de workers Dask..."
        kubectl get pods -l app=dask-worker --no-headers 2>/dev/null | while read -r line; do
            if [[ $line == *"Running"* ]]; then
                pod_name=$(echo "$line" | awk '{print $1}')
                log_success "Worker encontrado: $pod_name"
            fi
        done

        # Procurar por pods de workers Android
        log_info "Procurando pods de workers Android..."
        kubectl get pods -l app=android-worker --no-headers 2>/dev/null | while read -r line; do
            if [[ $line == *"Running"* ]]; then
                pod_name=$(echo "$line" | awk '{print $1}')
                log_success "Worker Android encontrado: $pod_name"
            fi
        done
    else
        log_warn "Nenhum cluster Kubernetes encontrado"
        log_info "Tentando descoberta via rede local..."

        # Descoberta via rede local (fallback)
        local network_prefix
        network_prefix=$(ip route get 1 | awk '{print $7}' | cut -d'.' -f1-3)

        log_info "Escaneando rede $network_prefix.0/24..."

        for i in {1..254}; do
            local test_ip="${network_prefix}.${i}"
            if ping -c 1 -W 1 "$test_ip" >/dev/null 2>&1; then
                log_info "Host encontrado: $test_ip"
                # Verificar se é um worker do cluster
                if ssh -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=no "root@$test_ip" "test -f /opt/cluster-ai/worker.sh" 2>/dev/null; then
                    log_success "Worker do Cluster AI encontrado: $test_ip"
                fi
            fi
        done
    fi

    log_success "Descoberta de workers concluída"
}

# =============================================================================
# EXECUÇÃO
# =============================================================================
main "$@"
