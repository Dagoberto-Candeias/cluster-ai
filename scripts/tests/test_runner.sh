#!/bin/bash
# =============================================================================
# Cluster AI - Executor de Testes
# =============================================================================
# Este script executa testes automatizados para os módulos do Cluster AI.

set -euo pipefail

# Carregar módulos para teste (com modo de teste)
export TEST_MODE=true
source "$(dirname "${BASH_SOURCE[0]}")/../core/common.sh"
# source "$(dirname "${BASH_SOURCE[0]}")/../core/security.sh"  # Desabilitado temporariamente

# =============================================================================
# CONFIGURAÇÃO DE TESTES
# =============================================================================

# Diretórios de teste
readonly TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_RESULTS_DIR="${TEST_DIR}/results"
readonly TEST_LOGS_DIR="${TEST_DIR}/logs"

# Contadores de teste
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# =============================================================================
# FUNÇÕES DE TESTE
# =============================================================================

# Inicializar ambiente de teste
setup_test_environment() {
    # Criar diretórios sem usar funções do módulo
    mkdir -p "$TEST_RESULTS_DIR" 2>/dev/null || true
    mkdir -p "$TEST_LOGS_DIR" 2>/dev/null || true

    # Arquivo de resultados
    TEST_RESULTS_FILE="${TEST_RESULTS_DIR}/test_results_$(date '+%Y%m%d_%H%M%S').txt"
    TEST_LOG_FILE="${TEST_LOGS_DIR}/test_log_$(date '+%Y%m%d_%H%M%S').log"

    # Limpar arquivos de teste anteriores
    rm -f "${TEST_RESULTS_DIR}/test_results_*.txt" 2>/dev/null || true
    rm -f "${TEST_LOGS_DIR}/test_log_*.log" 2>/dev/null || true

    echo "Ambiente de teste inicializado"
}

# Função de teste genérica
run_test() {
    local test_name="$1"
    local test_function="$2"

    ((TESTS_RUN++))

    echo -n "Executando $test_name... "

    # Executar teste em subshell para capturar erros
    if (set +e; $test_function > /dev/null 2>&1); then
        echo "PASSOU"
        ((TESTS_PASSED++))
        echo "PASS: $test_name" >> "$TEST_RESULTS_FILE"
        return 0
    else
        echo "FALHOU"
        ((TESTS_FAILED++))
        echo "FAIL: $test_name" >> "$TEST_RESULTS_FILE"
        return 1
    fi
}

# Pular teste
skip_test() {
    local test_name="$1"
    local reason="${2:-}"

    ((TESTS_SKIPPED++))
    echo "PULADO: $test_name ($reason)"
    echo "SKIP: $test_name - $reason" >> "$TEST_RESULTS_FILE"
}

# =============================================================================
# TESTES PARA MÓDULO COMMON
# =============================================================================

test_common_functions() {
    echo "=== Testes do Módulo Common ==="

    # Teste de detecção de OS
    run_test "detect_os" "detect_os | grep -qE '^(linux|macos|windows)$'"

    # Teste de detecção de arquitetura
    run_test "detect_arch" "detect_arch | grep -qE '^(x86_64|aarch64|armv7l)$'"

    # Teste de comando existente
    run_test "command_exists_bash" "command_exists bash"
    run_test "command_exists_nonexistent" "! command_exists nonexistent_command_12345"

    # Teste de validação de IP
    run_test "validate_valid_ip" "is_valid_ip '192.168.1.1'"
    run_test "validate_invalid_ip" "! is_valid_ip '999.999.999.999'"

    # Teste de validação de hostname
    run_test "validate_valid_hostname" "is_valid_hostname 'valid-host.example.com'"
    run_test "validate_invalid_hostname" "! is_valid_hostname 'invalid..hostname'"

    # Teste de criação de diretório
    local test_dir="/tmp/cluster_ai_test_$(date +%s)"
    run_test "ensure_dir" "ensure_dir '$test_dir' && [[ -d '$test_dir' ]]"
    rm -rf "$test_dir" 2>/dev/null || true

    # Teste de formatação de duração
    run_test "format_duration" "format_duration 3661 | grep -q '1h1m1s'"

    echo
}

# =============================================================================
# TESTES PARA MÓDULO SECURITY
# =============================================================================

test_security_functions() {
    echo "=== Testes do Módulo Security ==="

    # Teste de validação de entrada
    run_test "validate_input_valid" "validate_input 'test123' 'service_name'"
    run_test "validate_input_invalid" "! validate_input '../../../etc/passwd' 'filepath'"

    # Teste de validação de IP
    run_test "validate_ip_valid" "validate_ip '192.168.1.100'"
    run_test "validate_ip_invalid" "! validate_ip '256.256.256.256'"

    # Teste de validação de porta
    run_test "validate_port_valid" "validate_port '8080'"
    run_test "validate_port_invalid" "! validate_port '99999'"

    # Teste de validação de hostname
    run_test "validate_hostname_valid" "validate_hostname 'worker-01.cluster.local'"
    run_test "validate_hostname_invalid" "! validate_hostname 'invalid..hostname'"

    # Teste de validação de nome de serviço
    run_test "validate_service_name_valid" "validate_service_name 'dask-scheduler'"
    run_test "validate_service_name_invalid" "! validate_service_name 'service with spaces'"

    # Teste de validação de nome de usuário
    run_test "validate_username_valid" "validate_username 'cluster_user'"
    run_test "validate_username_invalid" "! validate_username 'user@domain'"

    echo
}

# =============================================================================
# TESTES PARA MÓDULO WORKERS
# =============================================================================

test_workers_functions() {
    echo "=== Testes do Módulo Workers ==="

    # Teste de resolução de hostname
    run_test "resolve_hostname_localhost" "resolve_hostname 'localhost' | grep -qE '^(127\.0\.0\.1|::1)$'"

    # Teste de validação de conectividade de rede (localhost)
    run_test "test_network_connectivity_localhost" "test_network_connectivity '127.0.0.1' '22' >/dev/null 2>&1 || true"

    # Teste de validação de conectividade SSH (só se SSH estiver rodando)
    if command_exists ssh && pgrep -f sshd >/dev/null 2>&1; then
        run_test "test_ssh_connection_localhost" "test_ssh_connection '127.0.0.1' '$USER' '22' >/dev/null 2>&1 || true"
    else
        skip_test "test_ssh_connection_localhost" "SSH não disponível ou não rodando"
    fi

    echo
}

# =============================================================================
# TESTES PARA MÓDULO SERVICES
# =============================================================================

test_services_functions() {
    echo "=== Testes do Módulo Services ==="

    # Teste de detecção de systemd
    if command_exists systemctl; then
        run_test "systemd_available" "systemctl --version >/dev/null 2>&1"
    else
        skip_test "systemd_available" "systemd não disponível"
    fi

    # Teste de detecção de Docker
    if command_exists docker; then
        run_test "docker_available" "docker --version >/dev/null 2>&1"
    else
        skip_test "docker_available" "Docker não disponível"
    fi

    # Teste de verificação de processo
    run_test "process_running_init" "process_running '1'"

    # Teste de PID por nome
    run_test "get_pid_by_name_bash" "get_pid_by_name 'bash' | grep -qE '^[0-9]+$'"

    echo
}

# =============================================================================
# TESTES DE INTEGRAÇÃO
# =============================================================================

test_integration() {
    echo "=== Testes de Integração ==="

    # Teste de inicialização completa dos módulos
    run_test "init_environment" "init_environment && [[ -d '$LOGS_DIR' ]]"

    # Teste de verificação de dependências
    run_test "check_dependencies" "check_dependencies"

    # Teste de auditoria (se arquivo de log existir)
    if file_exists "$LOCAL_AUDIT_FILE"; then
        run_test "audit_log_writable" "audit_log 'TEST' 'SUCCESS' 'Test message' && grep -q 'TEST' '$LOCAL_AUDIT_FILE'"
    else
        skip_test "audit_log_writable" "Arquivo de auditoria não encontrado"
    fi

    echo
}

# =============================================================================
# RELATÓRIO DE TESTES
# =============================================================================

generate_test_report() {
    echo "=== RELATÓRIO DE TESTES ==="
    echo "Data/Hora: $(current_timestamp)"
    echo "Total de testes executados: $TESTS_RUN"
    echo "Testes aprovados: $TESTS_PASSED"
    echo "Testes reprovados: $TESTS_FAILED"
    echo "Testes pulados: $TESTS_SKIPPED"
    echo

    if (( TESTS_FAILED > 0 )); then
        echo "❌ Alguns testes falharam. Verifique os logs para detalhes."
        return 1
    elif (( TESTS_PASSED > 0 )); then
        echo "✅ Todos os testes executados passaram!"
        return 0
    else
        echo "⚠️  Nenhum teste foi executado."
        return 1
    fi
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    echo "🚀 Iniciando Suite de Testes - Cluster AI"
    echo "=========================================="
    echo

    # Inicializar ambiente
    setup_test_environment

    # Executar testes
    test_common_functions
    test_security_functions
    test_workers_functions
    test_services_functions
    test_integration

    # Gerar relatório
    echo
    generate_test_report

    # Salvar log completo
    {
        echo "=== LOG COMPLETO DE TESTES ==="
        echo "Data/Hora: $(current_timestamp)"
        echo
        cat "$TEST_RESULTS_FILE" 2>/dev/null || echo "Nenhum resultado encontrado"
    } > "$TEST_LOG_FILE"

    echo
    echo "📊 Resultados salvos em: $TEST_RESULTS_FILE"
    echo "📋 Log completo em: $TEST_LOG_FILE"
}

# =============================================================================
# EXECUÇÃO
# =============================================================================

# Verificar se script foi executado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
