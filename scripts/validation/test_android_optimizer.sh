#!/bin/bash
# Teste automatizado para o perfil de otimização dinâmico do Android.
# Descrição: Simula diferentes hardwares de dispositivos Android e verifica
#            se o resource_optimizer.sh calcula as configurações corretas.

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"
OPTIMIZER_SCRIPT="${PROJECT_ROOT}/scripts/management/resource_optimizer.sh"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Funções de Mocking (Simulação) ---

# Sobrescreve o comando 'nproc' para retornar um valor controlado
nproc() {
    echo "$MOCK_CPU_CORES"
}

# Sobrescreve o comando 'free' para retornar um valor controlado
free() {
    if [[ "$1" == "-m" ]]; then
        echo "              total        used        free      shared  buff/cache   available"
        echo "Mem:          ${MOCK_MEM_MB}         100         100         100         100         100"
        echo "Swap:             0           0           0"
    else
        command free "$@"
    fi
}

# Exporta as funções para que sejam visíveis em sub-shells
export -f nproc
export -f free

# --- Função de Teste ---

run_test_case() {
    local test_name="$1"
    export MOCK_CPU_CORES="$2"
    export MOCK_MEM_MB="$3"
    local expected_workers="$4"
    local expected_memory_limit="$5"

    subsection "Testando: $test_name (${MOCK_CPU_CORES} Cores, ${MOCK_MEM_MB}MB RAM)"
    
    # Executa o otimizador para obter as configurações calculadas
    local settings
    settings=$(bash "$OPTIMIZER_SCRIPT" get-settings --profile android)

    local actual_workers
    actual_workers=$(echo "$settings" | grep "DASK_WORKERS" | cut -d'=' -f2)
    local actual_memory_limit
    actual_memory_limit=$(echo "$settings" | grep "MEMORY_LIMIT" | cut -d'=' -f2)

    local test_passed=true
    # Validar Workers
    if [ "$actual_workers" == "$expected_workers" ]; then
        success "  -> Dask Workers: OK ($actual_workers)"
    else
        fail "  -> Dask Workers: FALHOU (Esperado: $expected_workers, Recebido: $actual_workers)"
        test_passed=false
    fi

    # Validar Limite de Memória
    if [ "$actual_memory_limit" == "$expected_memory_limit" ]; then
        success "  -> Memory Limit: OK ($actual_memory_limit)"
    else
        fail "  -> Memory Limit: FALHOU (Esperado: $expected_memory_limit, Recebido: $actual_memory_limit)"
        test_passed=false
    fi

    $test_passed
}

# --- Script Principal ---
main() {
    section "Teste do Otimizador de Recursos para Perfil Android"
    
    run_test_case "DOOGEE T20 Ultra (High-End)" 8 32768 4 "7168M"
    run_test_case "Xiaomi Redmi Note 10S (Mid-Range)" 8 6144 4 "768M"
    run_test_case "Dispositivo de Baixo Custo (Low-End)" 4 4096 2 "512M"
}

main "$@"