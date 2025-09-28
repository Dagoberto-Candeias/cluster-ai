#!/bin/bash
# =============================================================================
# Configurações Comuns - Worker Multi-Plataforma
# =============================================================================
# Arquivo de configuração compartilhado por todos os scripts de worker
#
# Autor: Cluster AI Team
# Data: 2025-09-23
# Versão: 1.0.0
# Arquivo: worker_config.sh
# =============================================================================

# --- Configurações globais ---
readonly WORKER_VERSION="1.0.0"
readonly CLUSTER_AI_REPO="https://github.com/Dagoberto-Candeias/cluster-ai.git"
readonly DEFAULT_SSH_PORT="8022"
readonly DEFAULT_DASK_PORT="8786"
readonly DEFAULT_DASHBOARD_PORT="8787"

# --- Configurações de timeout ---
readonly TIMEOUT_SSH_TEST=5
readonly TIMEOUT_NETWORK_TEST=5
readonly TIMEOUT_SERVICE_START=10
readonly TIMEOUT_PACKAGE_INSTALL=300
readonly TIMEOUT_GIT_CLONE=120

# --- Configurações de Dask ---
readonly DASK_MEMORY_LIMIT="2GB"
readonly DASK_THREADS="2"
readonly DASK_DASHBOARD="true"

# --- Configurações de rede ---
readonly NETWORK_TEST_HOST="8.8.8.8"
readonly NETWORK_TEST_TIMEOUT="5"

# --- Configurações de logging ---
readonly LOG_LEVEL="INFO"
readonly LOG_FORMAT="%(asctime)s - %(levelname)s - %(message)s"

# --- Função para obter configuração ---
get_config() {
    local key="$1"
    local platform="${2:-$(bash -c 'source scripts/workers/detect_platform.sh && detect_platform')}"

    case "$key" in
        "worker_version")
            echo "$WORKER_VERSION"
            ;;
        "ssh_port")
            echo "$DEFAULT_SSH_PORT"
            ;;
        "dask_port")
            echo "$DEFAULT_DASK_PORT"
            ;;
        "dashboard_port")
            echo "$DEFAULT_DASHBOARD_PORT"
            ;;
        "memory_limit")
            echo "$DASK_MEMORY_LIMIT"
            ;;
        "threads")
            echo "$DASK_THREADS"
            ;;
        "repo_url")
            echo "$CLUSTER_AI_REPO"
            ;;
        "log_level")
            echo "$LOG_LEVEL"
            ;;
        "log_format")
            echo "$LOG_FORMAT"
            ;;
        "timeout_ssh")
            echo "$TIMEOUT_SSH_TEST"
            ;;
        "timeout_network")
            echo "$TIMEOUT_NETWORK_TEST"
            ;;
        "timeout_install")
            echo "$TIMEOUT_PACKAGE_INSTALL"
            ;;
        "timeout_clone")
            echo "$TIMEOUT_GIT_CLONE"
            ;;
        "platform")
            echo "$platform"
            ;;
        *)
            echo ""
            ;;
    esac
}

# --- Função para validar configuração ---
validate_config() {
    local platform="${1:-$(bash -c 'source scripts/workers/detect_platform.sh && detect_platform')}"

    log_info "Validando configurações para plataforma: $platform"

    # Verificar se a plataforma é suportada
    case "$platform" in
        "termux"|"debian"|"ubuntu"|"manjaro"|"arch"|"centos"|"linux")
            log_success "Plataforma suportada: $platform"
            ;;
        *)
            log_error "Plataforma não suportada: $platform"
            return 1
            ;;
    esac

    # Verificar configurações críticas
    if [ -z "$(get_config ssh_port)" ]; then
        log_error "Porta SSH não configurada"
        return 1
    fi

    if [ -z "$(get_config dask_port)" ]; then
        log_error "Porta Dask não configurada"
        return 1
    fi

    log_success "Configurações validadas com sucesso"
    return 0
}

# --- Função para exibir configurações ---
show_config() {
    local platform="${1:-$(bash -c 'source scripts/workers/detect_platform.sh && detect_platform')}"

    echo -e "${BLUE}=== CONFIGURAÇÕES DO WORKER ===${NC}"
    echo "Versão do Worker: $(get_config worker_version)"
    echo "Plataforma: $platform"
    echo "Porta SSH: $(get_config ssh_port)"
    echo "Porta Dask: $(get_config dask_port)"
    echo "Porta Dashboard: $(get_config dashboard_port)"
    echo "Limite de Memória: $(get_config memory_limit)"
    echo "Threads: $(get_config threads)"
    echo "Timeout SSH: $(get_config timeout_ssh)s"
    echo "Timeout Rede: $(get_config timeout_network)s"
    echo "Timeout Instalação: $(get_config timeout_install)s"
    echo "Timeout Clone: $(get_config timeout_clone)s"
    echo
}

# --- Executar se chamado diretamente ---
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_config "$@"
fi
