#!/bin/bash
# Script Unificado de Testes - Cluster AI
# Executa todos os testes de validação do projeto

set -euo pipefail

# Carregar funções comuns
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SCRIPT="${SCRIPT_DIR}/../utils/common.sh"

if [ ! -f "$COMMON_SCRIPT" ]; then
    echo "ERRO: Script de funções comuns não encontrado: $COMMON_SCRIPT"
    exit 1
fi
source "$COMMON_SCRIPT"

# Configurações
TEST_LOG_DIR="${SCRIPT_DIR}/test_logs"
TEST_LOG_FILE="${TEST_LOG_DIR}/test_run_$(date +%Y%m%d_%H%M%S).log"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Criar diretório de logs de teste
mkdir -p "$TEST_LOG_DIR"

show_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                   CLUSTER AI - TESTES                       ║"
    echo "║                Execução Unificada de Testes                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo "Diretório do projeto: $SCRIPT_DIR"
    echo "Log de testes: $TEST_LOG_FILE"
    echo ""
}

run_test() {
    local test_name="$1"
    local test_script="$2"
    local test_args="${3:-}"
    
    ((TOTAL_TESTS++))
    
    echo -n "🧪 Executando $test_name... "
    
    if [ -f "$test_script" ]; then
        if bash "$test_script" $test_args > "${TEST_LOG_DIR}/${test_name}.log" 2>&1; then
            echo -e "${GREEN}✅ PASSOU${NC}"
            ((PASSED_TESTS++))
            return 0
        else
            echo -e "${RED}❌ FALHOU${NC}"
            echo "   Log detalhado: ${TEST_LOG_DIR}/${test_name}.log"
            ((FAILED_TESTS++))
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  NÃO ENCONTRADO${NC}"
        return 2
    fi
}

run_security_tests() {
    section "Testes de Segurança"
    run_test "Teste de Segurança Avançado" "scripts/validation/test_security_enhanced.sh"
    run_test "Teste de Funções de Segurança" "scripts/validation/test_security_functions.sh"
}

run_optimizer_tests() {
    section "Testes do Otimizador de Recursos"
    run_test "Teste do Otimizador Android" "scripts/validation/test_android_optimizer.sh"
}

run_installation_tests() {
    section "Testes de Instalação"
    run_test "Teste de Instaladores" "scripts/validation/test_installer_distros.sh"
    run_test "Teste de Ferramentas de Desenvolvimento" "scripts/validation/test_dev_tools_installer.sh"
}

run_logging_tests() {
    section "Testes de Logging"
    run_test "Teste de Sistema de Log" "scripts/validation/test_logging.sh"
}

run_validation_tests() {
    section "Testes de Validação"
    run_test "Validação de Instalação" "scripts/validation/validate_installation.sh"
    run_test "Validação de Limpeza" "scripts/validation/validate_cleanup.sh"
}

run_health_check() {
    section "Teste de Health Check"
    run_test "Health Check Completo" "scripts/utils/health_check.sh" "--test"
}

run_backup_tests() {
    section "Testes de Backup"
    run_test "Teste de Sistema de Backup" "scripts/validation/test_backup_system.sh"
}

run_syntax_check() {
    section "Verificação de Sintaxe"
    
    local scripts_to_check=(
        "install.sh"
        "manager.sh"
        "scripts/lib/common.sh"
        "scripts/lib/install_functions.sh"
        "scripts/utils/health_check.sh"
        "scripts/management/memory_manager.sh"
        "scripts/management/resource_optimizer.sh"
        "scripts/backup/backup_manager.sh"
    )
    
    for script in "${scripts_to_check[@]}"; do
        ((TOTAL_TESTS++))
        echo -n "📝 Verificando sintaxe de $script... "
        if bash -n "$script" 2>/dev/null; then
            echo -e "${GREEN}✅ OK${NC}"
            ((PASSED_TESTS++))
        else
            echo -e "${RED}❌ ERRO${NC}"
            ((FAILED_TESTS++))
        fi
    done
}

show_summary() {
    section "Resumo dos Testes"
    echo "📊 RESULTADO FINAL:"
    echo "   Total de testes: $TOTAL_TESTS"
    echo -e "   Testes passando: ${GREEN}$PASSED_TESTS${NC}"
    
    if [ "$FAILED_TESTS" -gt 0 ]; then
        echo -e "   Testes falhando: ${RED}$FAILED_TESTS${NC}"
    else
        echo -e "   Testes falhando: ${GREEN}$FAILED_TESTS${NC}"
    fi
    
    if [ "$FAILED_TESTS" -eq 0 ]; then
        echo -e "${GREEN}🎉 Todos os testes passaram com sucesso!${NC}"
    else
        echo -e "${RED}❌ $FAILED_TESTS teste(s) falharam.${NC}"
        echo "   Consulte os logs em: $TEST_LOG_DIR"
    fi
    
    echo ""
    echo "📋 Logs detalhados disponíveis em:"
    echo "   $TEST_LOG_DIR"
}

main() {
    # Configurar log
    exec > >(tee -a "$TEST_LOG_FILE") 2>&1
    
    show_banner
    
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
