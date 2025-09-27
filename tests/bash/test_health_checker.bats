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

# Caminho direto para o health_checker.sh
HEALTH_CHECKER_SCRIPT="/home/dcm/Projetos/cluster-ai/scripts/management/health_checker.sh"

teardown() {
    # Limpar arquivos de teste
    rm -rf "${PID_DIR}"
    rm -f "${PROJECT_ROOT}/logs/test.log"
}

@test "health_checker.sh status - mostra status quando serviços estão parados" {
    run bash "$HEALTH_CHECKER_SCRIPT" status

    [ "$status" -eq 0 ]
    [[ "$output" =~ "STATUS DETALHADO DO CLUSTER AI" ]]
    [[ "$output" =~ "Dask Cluster: Parado" ]]
    [[ "$output" =~ "Web Server: Parado" ]]
}

@test "health_checker.sh diag - executa diagnóstico completo" {
    run bash "$HEALTH_CHECKER_SCRIPT" diag

    [ "$status" -eq 0 ]
    [[ "$output" =~ "DIAGNÓSTICO DO SISTEMA" ]]
    [[ "$output" =~ "OS:" ]]
    [[ "$output" =~ "CPU:" ]]
    [[ "$output" =~ "Memory:" ]]
}

@test "health_checker.sh logs - mostra logs quando não existem" {
    run bash "$HEALTH_CHECKER_SCRIPT" logs

    [ "$status" -eq 0 ]
    [[ "$output" =~ "VISUALIZANDO LOGS DO SISTEMA" ]]
    [[ "$output" =~ "Log principal não encontrado" ]]
}

@test "health_checker.sh logs - mostra logs quando existem" {
    # Criar log de teste
    echo "2025-01-27 10:00:00 INFO Test log entry" > "${PROJECT_ROOT}/logs/cluster_ai.log"

    run bash "$HEALTH_CHECKER_SCRIPT" logs

    [ "$status" -eq 0 ]
    [[ "$output" =~ "ÚLTIMAS 20 LINHAS DO LOG PRINCIPAL" ]]
    [[ "$output" =~ "Test log entry" ]]
}

@test "health_checker.sh status - detecta Dask rodando" {
    # Simular PID do Dask
    echo "$$" > "${PID_DIR}/dask_cluster.pid"

    run bash "$HEALTH_CHECKER_SCRIPT" status

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Dask Cluster.*Rodando" ]]

    # Limpar
    rm -f "${PID_DIR}/dask_cluster.pid"
}

@test "health_checker.sh status - detecta Web Server rodando" {
    # Simular PID do web server
    echo "$$" > "${PROJECT_ROOT}/.web_server_pid"

    run bash "$HEALTH_CHECKER_SCRIPT" status

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Web Server.*Rodando" ]]

    # Limpar
    rm -f "${PROJECT_ROOT}/.web_server_pid"
}

@test "health_checker.sh status - limpa PID files de processos mortos" {
    # Criar PID file com PID inexistente
    echo "99999" > "${PID_DIR}/dask_cluster.pid"
    echo "99999" > "${PROJECT_ROOT}/.web_server_pid"

    run bash "$HEALTH_CHECKER_SCRIPT" status

    [ "$status" -eq 0 ]
    [[ "$output" =~ "Dask Cluster: Parado" ]]
    [[ "$output" =~ "Web Server: Parado" ]]

    # Verificar se os arquivos foram removidos
    [ ! -f "${PID_DIR}/dask_cluster.pid" ]
    [ ! -f "${PROJECT_ROOT}/.web_server_pid" ]
}

@test "health_checker.sh help - mostra ajuda quando comando inválido" {
    run bash "$HEALTH_CHECKER_SCRIPT" invalid

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Uso:" ]]
    [[ "$output" =~ "status" ]]
    [[ "$output" =~ "diag" ]]
    [[ "$output" =~ "logs" ]]
}

@test "health_checker.sh - mostra ajuda quando nenhum argumento" {
    run bash "$HEALTH_CHECKER_SCRIPT"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Uso:" ]]
}

@test "health_checker.sh diag - inclui informações de rede" {
    run bash "$HEALTH_CHECKER_SCRIPT" diag

    [ "$status" -eq 0 ]
    [[ "$output" =~ "NETWORK" ]]
    [[ "$output" =~ "Public IP:" ]]
    [[ "$output" =~ "Local IP:" ]]
}

@test "health_checker.sh diag - inclui informações de hardware" {
    run bash "$HEALTH_CHECKER_SCRIPT" diag

    [ "$status" -eq 0 ]
    [[ "$output" =~ "HARDWARE" ]]
    [[ "$output" =~ "cores" ]]
    [[ "$output" =~ "Memory:" ]]
    [[ "$output" =~ "Disk:" ]]
}
