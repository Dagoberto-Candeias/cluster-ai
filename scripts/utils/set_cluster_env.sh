#!/bin/bash
#
# set_cluster_env.sh
#
# Este script é projetado para ser 'source'd e configura a variável
# de ambiente CLUSTER_ENV.

set -euo pipefail

setup_environment() {
    local mode="${1:-development}"

    if [[ "$mode" == "production" ]]; then
        export CLUSTER_ENV="production"
        echo "Ambiente configurado para PRODUÇÃO."
    else
        export CLUSTER_ENV="development"
        echo "Ambiente configurado para DESENVOLVIMENTO."
    fi
}

setup_environment "$@"