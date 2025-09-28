#!/usr/bin/env bats
# =============================================================================
# Testes para health_checker.sh - Cluster AI
# =============================================================================
# Testa as funcionalidades de verificação de saúde do sistema
#
# Autor: Cluster AI Team
# Versão: 1.0.0
# =============================================================================

setup() {
    # Configurar ambiente de teste
    export PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/.." && pwd)"
    export SCRIPT_DIR="${PROJECT_ROOT}/scripts"
    export PID_DIR="${PROJECT_ROOT}/.pids"

    # Criar diretórios necessários
    mkdir -p "${PID_DIR}"
    mkdir -p "${PROJECT_ROOT}/logs"

    # Carregar funções comuns
    source "${SCRIPT_DIR}/lib/common.sh"
}

# Caminho para o script unificado
HEALTH_CHECK_SCRIPT="/home/dcm/Projetos/cluster-ai/scripts/utils/health_check.sh"

teardown() {
    # Limpar arquivos de teste
    rm -rf "${PID_DIR}"
    rm -f "${PROJECT_ROOT}/logs/test.log"
}

@test "health_check.sh status - executa health check completo" {
    run bash "$HEALTH_CHECK_SCRIPT" status
    # status pode ser 0 ou 1 dependendo do ambiente; garantir que houve saída
    [[ -n "$output" ]]
    [[ "$output" =~ "SYSTEM HEALTH CHECK" ]]
}

@test "health_check.sh diag - executa diagnóstico detalhado" {
    run bash "$HEALTH_CHECK_SCRIPT" diag
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DIAGNOSTIC HEALTH CHECK" ]]
    [[ "$output" =~ "Services:" ]]
    [[ "$output" =~ "System Resources:" ]]
}

@test "health_check.sh help - mostra ajuda" {
    run bash "$HEALTH_CHECK_SCRIPT" help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Cluster AI - Health Check Tool" ]]
    [[ "$output" =~ "status" ]]
    [[ "$output" =~ "diag" ]]
}

@test "health_check.sh diag - mostra logs recentes se existir health_log" {
    # Criar log de teste
    mkdir -p "${PROJECT_ROOT}/logs"
    echo "2025-01-27 10:00:00 INFO Test log entry" >> "${PROJECT_ROOT}/logs/health_check.log"
    run bash "$HEALTH_CHECK_SCRIPT" diag
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Recent Logs:" ]]
}

@test "health_check.sh status - roda mesmo com PID de Dask presente/inexistente" {
    # Simular PID do Dask
    echo "$$" > "${PID_DIR}/dask_cluster.pid"

    run bash "$HEALTH_CHECK_SCRIPT" status
    [[ -n "$output" ]]

    # Limpar
    rm -f "${PID_DIR}/dask_cluster.pid"
}

@test "health_check.sh status - executa independente do PID do Web Server" {
    # Simular PID do web server
    echo "$$" > "${PROJECT_ROOT}/.web_server_pid"

    run bash "$HEALTH_CHECK_SCRIPT" status
    [[ -n "$output" ]]

    # Limpar
    rm -f "${PROJECT_ROOT}/.web_server_pid"
}

@test "health_check.sh status - executa com PID files inválidos" {
    # Criar PID file com PID inexistente
    echo "99999" > "${PID_DIR}/dask_cluster.pid"
    echo "99999" > "${PROJECT_ROOT}/.web_server_pid"

    run bash "$HEALTH_CHECK_SCRIPT" status
    [[ -n "$output" ]]
}

@test "health_check.sh - mostra help quando comando inválido" {
    run bash "$HEALTH_CHECK_SCRIPT" invalid
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "health_check.sh - mostra ajuda quando nenhum argumento" {
    run bash "$HEALTH_CHECK_SCRIPT"
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "health_check.sh diag - inclui informações de recursos" {
    run bash "$HEALTH_CHECK_SCRIPT" diag

    [ "$status" -eq 0 ]
    [[ "$output" =~ "System Resources:" ]]
}

@test "health_check.sh services - verifica principais serviços" {
    run bash "$HEALTH_CHECK_SCRIPT" services
    [[ -n "$output" ]]
}
