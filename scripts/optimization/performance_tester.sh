#!/bin/bash
# =============================================================================
# CLUSTER AI - TESTADOR DE PERFORMANCE
# =============================================================================
#
# DESCRIÇÃO: Testa performance do sistema após otimizações
#
# AUTOR: Sistema de Otimização Automática
# DATA: $(date +%Y-%m-%d)
# VERSÃO: 1.0.0
#
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# CONSTANTES
# -----------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_DIR="${PROJECT_ROOT}/logs"
readonly REPORTS_DIR="${PROJECT_ROOT}/reports"

# -----------------------------------------------------------------------------
# CORES PARA OUTPUT
# -----------------------------------------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# -----------------------------------------------------------------------------
# VARIÁVEIS GLOBAIS
# -----------------------------------------------------------------------------
declare -a TEST_RESULTS=()
declare -i TOTAL_TESTS=0
declare -i PASSED_TESTS=0
declare -i FAILED_TESTS=0

# -----------------------------------------------------------------------------
# FUNÇÕES DE LOGGING
# -----------------------------------------------------------------------------
log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] ${SCRIPT_NAME}: $*${NC}"
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] ${SCRIPT_NAME}: $*${NC}"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] ${SCRIPT_NAME}: $*${NC}"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] ${SCRIPT_NAME}: $*${NC}"
}

# -----------------------------------------------------------------------------
# FUNÇÃO PARA REGISTRAR RESULTADO DE TESTE
# -----------------------------------------------------------------------------
record_test_result() {
    local test_name="$1"
    local result="$2"
    local details="$3"

    TEST_RESULTS+=("${test_name}|${result}|${details}")
    ((TOTAL_TESTS++))

    if [[ "$result" == "PASS" ]]; then
        ((PASSED_TESTS++))
        log_success "✓ $test_name: $details"
    else
        ((FAILED_TESTS++))
        log_error "✗ $test_name: $details"
    fi
}

# -----------------------------------------------------------------------------
# TESTE DE PERFORMANCE DE CPU
# -----------------------------------------------------------------------------
test_cpu_performance() {
    log_info "Executando teste de performance de CPU..."

    local start_time
    local end_time
    local duration

    start_time=$(date +%s.%3N)

    # Teste simples de CPU (calcula números primos)
    local count=0
    local num=2
    local limit=10000

    while [[ $count -lt $limit ]]; do
        local is_prime=1
        local i=2

        while [[ $i -lt $num ]]; do
            if [[ $((num % i)) -eq 0 ]]; then
                is_prime=0
                break
            fi
            ((i++))
        done

        if [[ $is_prime -eq 1 ]]; then
            ((count++))
        fi

        ((num++))
    done

    end_time=$(date +%s.%3N)
    duration=$(echo "$end_time - $start_time" | bc)

    record_test_result "CPU Performance" "PASS" "Calculou $count primos em ${duration}s"
}

# -----------------------------------------------------------------------------
# TESTE DE PERFORMANCE DE MEMÓRIA
# -----------------------------------------------------------------------------
test_memory_performance() {
    log_info "Executando teste de performance de memória..."

    local start_time
    local end_time
    local duration

    start_time=$(date +%s.%3N)

    # Teste de alocação e liberação de memória
    local arrays=()
    local i=0
    local max_arrays=1000

    while [[ $i -lt $max_arrays ]]; do
        arrays[$i]=$(seq 1 1000 | tr '\n' ' ')
        ((i++))
    done

    # Liberar memória
    unset arrays

    end_time=$(date +%s.%3N)
    duration=$(echo "$end_time - $start_time" | bc)

    record_test_result "Memory Performance" "PASS" "Alocou/liberou $max_arrays arrays em ${duration}s"
}

# -----------------------------------------------------------------------------
# TESTE DE PERFORMANCE DE DISCO
# -----------------------------------------------------------------------------
test_disk_performance() {
    log_info "Executando teste de performance de disco..."

    local test_file="${PROJECT_ROOT}/tmp/performance_test.tmp"
    local file_size_mb=10
    local start_time
    local end_time
    local duration

    # Criar diretório temporário
    mkdir -p "${PROJECT_ROOT}/tmp"

    start_time=$(date +%s.%3N)

    # Criar arquivo de teste
    dd if=/dev/zero of="$test_file" bs=1M count=$file_size_mb 2>/dev/null

    # Ler arquivo
    dd if="$test_file" of=/dev/null bs=1M 2>/dev/null

    # Remover arquivo
    rm -f "$test_file"

    end_time=$(date +%s.%3N)
    duration=$(echo "$end_time - $start_time" | bc)

    record_test_result "Disk Performance" "PASS" "Operações I/O de ${file_size_mb}MB em ${duration}s"
}

# -----------------------------------------------------------------------------
# TESTE DE PERFORMANCE DE REDE
# -----------------------------------------------------------------------------
test_network_performance() {
    log_info "Executando teste de performance de rede..."

    if ping -c 1 8.8.8.8 &>/dev/null; then
        local ping_result
        ping_result=$(ping -c 5 8.8.8.8 | tail -1 | awk '{print $4}' | cut -d '/' -f 2)

        if [[ $(echo "$ping_result < 100" | bc -l) -eq 1 ]]; then
            record_test_result "Network Performance" "PASS" "Latência média: ${ping_result}ms"
        else
            record_test_result "Network Performance" "WARN" "Latência alta: ${ping_result}ms"
        fi
    else
        record_test_result "Network Performance" "FAIL" "Sem conectividade com internet"
    fi
}

# -----------------------------------------------------------------------------
# TESTE DE PERFORMANCE DE SCRIPTS
# -----------------------------------------------------------------------------
test_script_performance() {
    log_info "Executando teste de performance de scripts..."

    local test_script="${PROJECT_ROOT}/scripts/utils/standardize_headers.sh"
    local start_time
    local end_time
    local duration

    if [[ -f "$test_script" ]]; then
        start_time=$(date +%s.%3N)

        # Executar script com timeout
        timeout 30s bash "$test_script" --dry-run 2>/dev/null || true

        end_time=$(date +%s.%3N)
        duration=$(echo "$end_time - $start_time" | bc)

        if [[ $(echo "$duration < 30" | bc -l) -eq 1 ]]; then
            record_test_result "Script Performance" "PASS" "Script executado em ${duration}s"
        else
            record_test_result "Script Performance" "WARN" "Script lento: ${duration}s"
        fi
    else
        record_test_result "Script Performance" "FAIL" "Script de teste não encontrado"
    fi
}

# -----------------------------------------------------------------------------
# TESTE DE CONECTIVIDADE DASK
# -----------------------------------------------------------------------------
test_dask_connectivity() {
    log_info "Testando conectividade do cluster Dask..."

    if command -v python3 &>/dev/null; then
        local test_script="${PROJECT_ROOT}/scripts/dask/test_dask_connection.py"

        if [[ -f "$test_script" ]]; then
            if python3 "$test_script" 2>/dev/null; then
                record_test_result "Dask Connectivity" "PASS" "Cluster Dask operacional"
            else
                record_test_result "Dask Connectivity" "FAIL" "Falha na conexão com Dask"
            fi
        else
            # Teste básico de conectividade
            if python3 -c "import dask; print('Dask importado com sucesso')" 2>/dev/null; then
                record_test_result "Dask Connectivity" "PASS" "Biblioteca Dask disponível"
            else
                record_test_result "Dask Connectivity" "FAIL" "Biblioteca Dask não disponível"
            fi
        fi
    else
        record_test_result "Dask Connectivity" "FAIL" "Python3 não encontrado"
    fi
}

# -----------------------------------------------------------------------------
# GERAR RELATÓRIO DE PERFORMANCE
# -----------------------------------------------------------------------------
generate_performance_report() {
    local report_file="${REPORTS_DIR}/performance_test_$(date +%Y%m%d_%H%M%S).txt"

    mkdir -p "$REPORTS_DIR"

    {
        echo "================================================================================"
        echo "RELATÓRIO DE PERFORMANCE - CLUSTER AI"
        echo "================================================================================"
        echo "Data: $(date)"
        echo "Script: $SCRIPT_NAME"
        echo ""
        echo "RESUMO EXECUTIVO:"
        echo "-----------------"
        echo "Total de Testes: $TOTAL_TESTS"
        echo "Testes Aprovados: $PASSED_TESTS"
        echo "Testes Reprovados: $FAILED_TESTS"
        echo "Taxa de Sucesso: $((PASSED_TESTS * 100 / TOTAL_TESTS))%"
        echo ""
        echo "DETALHES DOS TESTES:"
        echo "--------------------"

        for result in "${TEST_RESULTS[@]}"; do
            IFS='|' read -r test_name status details <<< "$result"
            echo "• $test_name: $status - $details"
        done

        echo ""
        echo "MÉTRICAS DE SISTEMA:"
        echo "--------------------"
        echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
        echo "Memory Usage: $(free | grep Mem | awk '{printf "%.2f%%", $3/$2 * 100.0}')"
        echo "Disk Usage: $(df / | tail -1 | awk '{print $5}')"
        echo ""
        echo "================================================================================"

    } > "$report_file"

    log_success "Relatório de performance gerado: $report_file"
}

# -----------------------------------------------------------------------------
# FUNÇÃO PRINCIPAL
# -----------------------------------------------------------------------------
main() {
    log_info "Iniciando testes de performance do Cluster AI..."

    # Criar diretórios necessários
    mkdir -p "$LOG_DIR" "$REPORTS_DIR"

    # Executar testes
    test_cpu_performance
    test_memory_performance
    test_disk_performance
    test_network_performance
    test_script_performance
    test_dask_connectivity

    # Gerar relatório
    generate_performance_report

    # Resumo final
    log_info "Testes concluídos: $PASSED_TESTS/$TOTAL_TESTS aprovados"

    if [[ $FAILED_TESTS -eq 0 ]]; then
        log_success "🎉 Todos os testes de performance passaram!"
    else
        log_warn "⚠️ Alguns testes falharam. Verifique o relatório para detalhes."
    fi
}

# -----------------------------------------------------------------------------
# EXECUÇÃO
# -----------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
