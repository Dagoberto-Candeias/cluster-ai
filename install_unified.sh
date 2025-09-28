#!/bin/bash
# =============================================================================
# Local: install_unified.sh
# =============================================================================
# Autor: Dagoberto Candeias <betoallnet@gmail.com>
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: install_unified.sh
# =============================================================================

# --- Funções de Verificação ---

# Verifica se há espaço suficiente em disco
# Uso: check_disk_space [required_space_gb]
check_disk_space() {
    local required_gb="${1:-10}"  # Padrão: 10GB
    local required_kb=$((required_gb * 1024 * 1024))

    # Obtém espaço disponível na partição raiz
    local available_kb
    available_kb=$(df / | tail -1 | awk '{print $4}')

    if [ "$available_kb" -ge "$required_kb" ]; then
        echo "Espaço em disco suficiente: ${available_kb} KB disponível (requerido: ${required_kb} KB)"
        return 0
    else
        echo "Espaço em disco insuficiente: ${available_kb} KB disponível (requerido: ${required_kb} KB)"
        return 1
    fi
}
