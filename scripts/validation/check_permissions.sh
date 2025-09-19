#!/bin/bash
# =============================================================================
# check_permissions.sh
# =============================================================================
# Script utilitário do Cluster AI
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: check_permissions.sh
# =============================================================================

    
    local non_executable_scripts=()
    
    # Construir os argumentos de exclusão para o comando find
    local find_args=()
    for dir in "${EXCLUDED_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            find_args+=(-not -path "${dir}/*")
        fi
    done

    # Encontrar todos os scripts .sh, aplicando as exclusões
    mapfile -t all_scripts < <(find "$PROJECT_ROOT" -type f -name '*.sh' "${find_args[@]}")

    if [ ${#all_scripts[@]} -eq 0 ]; then
        warn "Nenhum script .sh encontrado para verificação."
