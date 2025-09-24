#!/bin/bash
# =============================================================================
# Este script é projetado para ser 'source'd e configura a variável
# CLUSTER_ENV baseada no argumento passado ou no padrão 'development'.
#
# Uso:
#   source set_cluster_env.sh [environment]
#
# Exemplos:
#   source set_cluster_env.sh          # Define CLUSTER_ENV=development
#   source set_cluster_env.sh production # Define CLUSTER_ENV=production
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: set_cluster_env.sh
# =============================================================================

# Função principal
set_cluster_env() {
    local env="${1:-development}"

    # Validação básica do ambiente
    case "$env" in
        development|staging|production)
            export CLUSTER_ENV="$env"
            echo "$env"  # Output para testes
            ;;
        *)
            echo "Erro: Ambiente '$env' não é válido. Use: development, staging, ou production." >&2
            return 1
            ;;
    esac
}

# Executa a função se o script for chamado diretamente (não sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set_cluster_env "$@"
fi
