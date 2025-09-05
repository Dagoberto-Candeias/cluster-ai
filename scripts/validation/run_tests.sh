#!/bin/bash
# Script Unificado de Testes - Cluster AI
# Executa todos os testes de validação do projeto

set -euo pipefail

# Carregar funções comuns
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# --- Configurações ---
TEST_LOG_DIR="${PROJECT_ROOT}/logs/test_logs"
TEST_LOG_FILE="${TEST_LOG_DIR}/test_run_$(date +%Y%m%d_%H%M%S).log"

# Configurações
TEST_LOG_DIR="${SCRIPT_DIR}/test_logs"
TEST_LOG_FILE="${TEST_LOG_DIR}/test_run_$(date +%Y%m%d_%H%M%S).log"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Criar diretório de logs de teste
mkdir -p "$TEST_LOG_DIR"

show_test_banner() {
    section "🧪 Execução Unificada de Testes - Cluster AI 🧪"
    info "Os resultados detalhados serão salvos em: $TEST_LOG_FILE"
}

# Redireciona toda a saída para o arquivo de log e para o console
setup_logging() {
    exec > >(tee -a "$TEST_LOG_FILE") 2>&1
}

run_test() {
    local test_name="$1"
    local test_script="$2"
    local test_args="${3:-}"
    
    ((TOTAL_TESTS++))
    
    echo -n "🧪 Executando $test_name... "
    local log_file="${TEST_LOG_DIR}/$(echo "$test_name" | tr ' ' '_').log"

    if [ -f "$test_script" ]; then
        if bash "$test_script" $test_args > "$log_file" 2>&1; then
            echo -e "${GREEN}✅ PASSOU${NC}"
            ((PASSED_TESTS++))
            return 0
        else
            echo -e "${RED}❌ FALHOU${NC}"
            echo "   Log detalhado: $log_file"
            ((FAILED_TESTS++))
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  NÃO ENCONTRADO${NC}"
        return 2
    fi
}

run_security_tests() {
    subsection "Testes de Segurança"
    run_test "Teste de Segurança Avançado" "${PROJECT_ROOT}/scripts/validation/test_security_enhanced.sh"
    run_test "Teste de Funções de Segurança" "${PROJECT_ROOT}/scripts/validation/test_security_functions.sh"
}

run_optimizer_tests() {
    subsection "Testes do Otimizador de Recursos"
    run_test "Teste do Otimizador Android" "${PROJECT_ROOT}/scripts/validation/test_android_optimizer.sh"
}

run_installation_tests() {
    subsection "Testes de Instalação"
    run_test "Teste de Instaladores" "${PROJECT_ROOT}/scripts/validation/test_installer_distros.sh"
    run_test "Teste de Ferramentas de Desenvolvimento" "${PROJECT_ROOT}/scripts/validation/test_dev_tools_installer.sh"
}

run_logging_tests() {
    subsection "Testes de Logging"
    run_test "Teste de Sistema de Log" "${PROJECT_ROOT}/scripts/validation/test_logging.sh"
}

run_validation_tests() {
    subsection "Testes de Validação"
    run_test "Validação de Instalação" "${PROJECT_ROOT}/scripts/validation/validate_installation.sh"
    run_test "Validação de Limpeza" "${PROJECT_ROOT}/scripts/validation/validate_cleanup.sh"
}

run_health_check() {
    subsection "Teste de Health Check"
    run_test "Health Check Completo" "${PROJECT_ROOT}/scripts/utils/health_check.sh" "--test"
}

run_backup_tests() {
    subsection "Testes de Backup"
    run_test "Teste de Sistema de Backup" "${PROJECT_ROOT}/scripts/validation/test_backup_system.sh"
}

run_syntax_check() {
    subsection "Verificação de Sintaxe (bash -n)"
    
    local scripts_to_check=(
        "${PROJECT_ROOT}/install_unified.sh"
        "${PROJECT_ROOT}/manager.sh"
        "${PROJECT_ROOT}/scripts/lib/common.sh"
        "${PROJECT_ROOT}/scripts/maintenance/cleanup.sh"
        "${PROJECT_ROOT}/scripts/maintenance/backup_manager.sh"
    )
    
    for script in "${scripts_to_check[@]}"; do
        ((TOTAL_TESTS++))
        echo -n "📝 Verificando sintaxe de $(basename "$script")... "
        if [ -f "$script" ] && bash -n "$script" 2>/dev/null; then
            echo -e "${GREEN}✅ OK${NC}"
            ((PASSED_TESTS++))
        else
            echo -e "${RED}❌ ERRO${NC}"
            ((FAILED_TESTS++))
        fi
    done
}

show_summary() {
    section "📊 Resumo Final dos Testes 📊"
    echo "========================================================================"
    echo -e "  Total de testes executados: ${BLUE}$TOTAL_TESTS${NC}"
    echo -e "  Testes que passaram:      ${GREEN}$PASSED_TESTS${NC}"
    
    if [ "$FAILED_TESTS" -gt 0 ]; then
        echo -e "  Testes que falharam:      ${RED}$FAILED_TESTS${NC}"
    else
        echo -e "  Testes que falharam:      ${GREEN}$FAILED_TESTS${NC}"
    fi
    echo "========================================================================"
    echo

    if [ "$FAILED_TESTS" -eq 0 ]; then
        echo -e "${GREEN}🎉 Todos os testes passaram com sucesso!${NC}"
    else
        echo -e "${RED}❌ $FAILED_TESTS teste(s) falharam.${NC}"
        echo -e "   Consulte os logs individuais em: ${YELLOW}${TEST_LOG_DIR}/${NC}"
    fi
}

main() {
    # Configurar log
    setup_logging
    
    show_test_banner
    
    # Executar todos os testes
    run_syntax_check
    run_security_tests
    run_installation_tests
    run_optimizer_tests
    run_logging_tests
    run_validation_tests
    run_health_check
    run_backup_tests
    
    show_summary
    
    # Retornar código de saída apropriado
    if [ "$FAILED_TESTS" -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# Executar função principal
main "$@"
