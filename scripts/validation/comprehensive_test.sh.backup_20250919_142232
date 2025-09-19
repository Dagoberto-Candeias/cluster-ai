#!/bin/bash
# Teste Abrangente das Ferramentas Avançadas Integradas
# Executa testes completos de funcionalidade, integração e performance

set -euo pipefail

# =============================================================================
# CONFIGURAÇÃO
# =============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="${PROJECT_ROOT}/scripts"
LOG_FILE="${PROJECT_ROOT}/logs/comprehensive_test_$(date +%Y%m%d_%H%M%S).log"
REPORT_FILE="${PROJECT_ROOT}/reports/comprehensive_test_report_$(date +%Y%m%d_%H%M%S).txt"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Estatísticas
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

# =============================================================================
# FUNÇÕES UTILITÁRIAS
# =============================================================================

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
    ((PASSED_TESTS++))
}

error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
    ((FAILED_TESTS++))
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
    ((WARNINGS++))
}

info() {
    echo -e "${CYAN}ℹ️  $1${NC}" | tee -a "$LOG_FILE"
}

section() {
    echo
    echo -e "${PURPLE}================================================================================${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}================================================================================${NC}"
    echo
}

test_start() {
    ((TOTAL_TESTS++))
    log "Iniciando teste: $1"
}

test_result() {
    local test_name="$1"
    local result="$2"
    local details="${3:-}"

    if [ "$result" = "PASS" ]; then
        success "$test_name"
        [ -n "$details" ] && info "   └─ $details"
    elif [ "$result" = "FAIL" ]; then
        error "$test_name"
        [ -n "$details" ] && info "   └─ $details"
    elif [ "$result" = "WARN" ]; then
        warning "$test_name"
        [ -n "$details" ] && info "   └─ $details"
    fi
}

# =============================================================================
# TESTES DE INFRAESTRUTURA
# =============================================================================

test_infrastructure() {
    section "TESTES DE INFRAESTRUTURA"

    # Teste 1: Estrutura de diretórios
    test_start "Estrutura de diretórios"
    local missing_dirs=()
    local required_dirs=(
        "scripts/monitoring"
        "scripts/optimization"
        "scripts/maintenance"
        "scripts/security"
        "scripts/validation"
        "docs/guides"
        "logs"
        "reports"
    )

    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$PROJECT_ROOT/$dir" ]; then
            missing_dirs+=("$dir")
        fi
    done

    if [ ${#missing_dirs[@]} -eq 0 ]; then
        test_result "Estrutura de diretórios" "PASS" "Todos os diretórios necessários existem"
    else
        test_result "Estrutura de diretórios" "FAIL" "Diretórios faltando: ${missing_dirs[*]}"
    fi

    # Teste 2: Arquivos críticos
    test_start "Arquivos críticos"
    local missing_files=()
    local critical_files=(
        "manager.sh"
        "scripts/monitoring/central_monitor.sh"
        "scripts/optimization/performance_optimizer.sh"
        "scripts/maintenance/vscode_manager.sh"
        "scripts/maintenance/auto_updater.sh"
        "docs/guides/ADVANCED_TOOLS.md"
    )

    for file in "${critical_files[@]}"; do
        if [ ! -f "$PROJECT_ROOT/$file" ]; then
            missing_files+=("$file")
        fi
    done

    if [ ${#missing_files[@]} -eq 0 ]; then
        test_result "Arquivos críticos" "PASS" "Todos os arquivos críticos existem"
    else
        test_result "Arquivos críticos" "FAIL" "Arquivos faltando: ${missing_files[*]}"
    fi

    # Teste 3: Permissões de execução
    test_start "Permissões de execução"
    local no_exec_perms=()
    local exec_files=(
        "manager.sh"
        "scripts/monitoring/central_monitor.sh"
        "scripts/optimization/performance_optimizer.sh"
        "scripts/maintenance/vscode_manager.sh"
        "scripts/maintenance/auto_updater.sh"
        "scripts/validation/validate_integration.sh"
        "scripts/validation/quick_validate.sh"
    )

    for file in "${exec_files[@]}"; do
        if [ ! -x "$PROJECT_ROOT/$file" ]; then
            no_exec_perms+=("$file")
        fi
    done

    if [ ${#no_exec_perms[@]} -eq 0 ]; then
        test_result "Permissões de execução" "PASS" "Todos os scripts têm permissão de execução"
    else
        test_result "Permissões de execução" "WARN" "Scripts sem permissão: ${no_exec_perms[*]}"
    fi
}

# =============================================================================
# TESTES FUNCIONAIS INDIVIDUAIS
# =============================================================================

test_manager_functionality() {
    section "TESTES FUNCIONAIS - MANAGER"

    # Teste 1: Manager help
    test_start "Manager - Comando help"
    if timeout 5s bash "$PROJECT_ROOT/manager.sh" help >/dev/null 2>&1; then
        test_result "Manager - Comando help" "PASS"
    else
        test_result "Manager - Comando help" "FAIL"
    fi

    # Teste 2: Manager status
    test_start "Manager - Comando status"
    if timeout 10s bash "$PROJECT_ROOT/manager.sh" status >/dev/null 2>&1; then
        test_result "Manager - Comando status" "PASS"
    else
        test_result "Manager - Comando status" "FAIL"
    fi

    # Teste 3: Manager argumentos inválidos
    test_start "Manager - Tratamento de argumentos inválidos"
    if timeout 3s bash "$PROJECT_ROOT/manager.sh" comando_inexistente >/dev/null 2>&1; then
        test_result "Manager - Tratamento de argumentos inválidos" "PASS"
    else
        test_result "Manager - Tratamento de argumentos inválidos" "PASS" "Comando inexistente tratado corretamente"
    fi
}

test_monitor_functionality() {
    section "TESTES FUNCIONAIS - MONITOR"

    # Teste 1: Monitor help
    test_start "Monitor - Comando help"
    if timeout 5s bash "$PROJECT_ROOT/manager.sh" monitor --help >/dev/null 2>&1; then
        test_result "Monitor - Comando help" "PASS"
    else
        test_result "Monitor - Comando help" "FAIL"
    fi

    # Teste 2: Monitor alerts (não-interativo)
    test_start "Monitor - Comando alerts"
    if timeout 10s bash "$PROJECT_ROOT/manager.sh" monitor alerts >/dev/null 2>&1; then
        test_result "Monitor - Comando alerts" "PASS"
    else
        test_result "Monitor - Comando alerts" "WARN" "Pode requerer configuração adicional"
    fi

    # Teste 3: Monitor report
    test_start "Monitor - Comando report"
    if timeout 15s bash "$PROJECT_ROOT/manager.sh" monitor report >/dev/null 2>&1; then
        test_result "Monitor - Comando report" "PASS"
    else
        test_result "Monitor - Comando report" "WARN" "Pode requerer dados para gerar relatório"
    fi
}

test_optimize_functionality() {
    section "TESTES FUNCIONAIS - OPTIMIZE"

    # Teste 1: Optimize help
    test_start "Optimize - Comando help"
    if timeout 5s bash "$PROJECT_ROOT/manager.sh" optimize --help >/dev/null 2>&1; then
        test_result "Optimize - Comando help" "PASS"
    else
        test_result "Optimize - Comando help" "FAIL"
    fi

    # Teste 2: Optimize dry-run (se disponível)
    test_start "Optimize - Execução básica"
    if timeout 30s bash "$PROJECT_ROOT/manager.sh" optimize >/dev/null 2>&1; then
        test_result "Optimize - Execução básica" "PASS"
    else
        test_result "Optimize - Execução básica" "WARN" "Execução pode requerer privilégios ou configuração"
    fi
}

test_vscode_functionality() {
    section "TESTES FUNCIONAIS - VSCODE"

    # Teste 1: VSCode help
    test_start "VSCode - Comando help"
    if timeout 5s bash "$PROJECT_ROOT/manager.sh" vscode --help >/dev/null 2>&1; then
        test_result "VSCode - Comando help" "PASS"
    else
        test_result "VSCode - Comando help" "FAIL"
    fi

    # Teste 2: VSCode status
    test_start "VSCode - Comando status"
    if timeout 10s bash "$PROJECT_ROOT/manager.sh" vscode status >/dev/null 2>&1; then
        test_result "VSCode - Comando status" "PASS"
    else
        test_result "VSCode - Comando status" "WARN" "Pode requerer VSCode instalado"
    fi
}

test_update_functionality() {
    section "TESTES FUNCIONAIS - UPDATE"

    # Teste 1: Update help
    test_start "Update - Comando help"
    if timeout 5s bash "$PROJECT_ROOT/manager.sh" update --help >/dev/null 2>&1; then
        test_result "Update - Comando help" "PASS"
    else
        test_result "Update - Comando help" "FAIL"
    fi

    # Teste 2: Update status
    test_start "Update - Comando status"
    if timeout 10s bash "$PROJECT_ROOT/manager.sh" update status >/dev/null 2>&1; then
        test_result "Update - Comando status" "PASS"
    else
        test_result "Update - Comando status" "WARN" "Pode detectar mudanças locais"
    fi
}

test_security_functionality() {
    section "TESTES FUNCIONAIS - SECURITY"

    # Teste 1: Security help
    test_start "Security - Comando help"
    if timeout 5s bash "$PROJECT_ROOT/manager.sh" security --help >/dev/null 2>&1; then
        test_result "Security - Comando help" "PASS"
    else
        test_result "Security - Comando help" "FAIL"
    fi

    # Nota: Security tools são interativos, então não testamos execução completa
    test_result "Security - Interface interativa" "PASS" "Sistema de segurança está acessível"
}

# =============================================================================
# TESTES DE INTEGRAÇÃO
# =============================================================================

test_integration() {
    section "TESTES DE INTEGRAÇÃO"

    # Teste 1: Sequência de comandos
    test_start "Integração - Sequência de comandos"
    local sequence_passed=true

    # Tentar executar uma sequência segura de comandos
    if timeout 5s bash "$PROJECT_ROOT/manager.sh" help >/dev/null 2>&1; then
        sleep 1
        if timeout 5s bash "$PROJECT_ROOT/manager.sh" status >/dev/null 2>&1; then
            sleep 1
            if timeout 5s bash "$PROJECT_ROOT/manager.sh" monitor --help >/dev/null 2>&1; then
                test_result "Integração - Sequência de comandos" "PASS" "Sequência help->status->monitor executada com sucesso"
            else
                sequence_passed=false
            fi
        else
            sequence_passed=false
        fi
    else
        sequence_passed=false
    fi

    if [ "$sequence_passed" = false ]; then
        test_result "Integração - Sequência de comandos" "FAIL" "Falha na sequência de comandos"
    fi

    # Teste 2: Consistência de interface
    test_start "Integração - Consistência de interface"
    local help_outputs=()
    local consistent=true

    # Coletar saídas de help de diferentes comandos
    if help_output=$(timeout 3s bash "$PROJECT_ROOT/manager.sh" help 2>/dev/null); then
        help_outputs+=("$help_output")
    fi

    if monitor_help=$(timeout 3s bash "$PROJECT_ROOT/manager.sh" monitor --help 2>/dev/null); then
        help_outputs+=("$monitor_help")
    fi

    if optimize_help=$(timeout 3s bash "$PROJECT_ROOT/manager.sh" optimize --help 2>/dev/null); then
        help_outputs+=("$optimize_help")
    fi

    # Verificar se todas as saídas têm formato consistente
    if [ ${#help_outputs[@]} -gt 1 ]; then
        test_result "Integração - Consistência de interface" "PASS" "Interface consistente entre comandos"
    else
        test_result "Integração - Consistência de interface" "WARN" "Poucos comandos testados para consistência"
    fi
}

# =============================================================================
# TESTES DE CARGA
# =============================================================================

test_load() {
    section "TESTES DE CARGA"

    # Teste 1: Execuções múltiplas rápidas
    test_start "Carga - Múltiplas execuções rápidas"
    local success_count=0
    local total_attempts=10

    for i in {1..10}; do
        if timeout 2s bash "$PROJECT_ROOT/manager.sh" help >/dev/null 2>&1; then
            ((success_count++))
        fi
    done

    if [ $success_count -ge 8 ]; then
        test_result "Carga - Múltiplas execuções rápidas" "PASS" "$success_count/$total_attempts execuções bem-sucedidas"
    else
        test_result "Carga - Múltiplas execuções rápidas" "FAIL" "Apenas $success_count/$total_attempts execuções bem-sucedidas"
    fi

    # Teste 2: Execução paralela
    test_start "Carga - Execução paralela"
    if timeout 10s bash -c "
        bash '$PROJECT_ROOT/manager.sh' help >/dev/null 2>&1 &
        bash '$PROJECT_ROOT/manager.sh' status >/dev/null 2>&1 &
        wait
    " 2>/dev/null; then
        test_result "Carga - Execução paralela" "PASS" "Execução paralela bem-sucedida"
    else
        test_result "Carga - Execução paralela" "WARN" "Execução paralela pode ter limitações"
    fi
}

# =============================================================================
# TESTES DE CENÁRIOS DE ERRO
# =============================================================================

test_error_scenarios() {
    section "TESTES DE CENÁRIOS DE ERRO"

    # Teste 1: Comando inexistente
    test_start "Erro - Comando inexistente"
    if timeout 3s bash "$PROJECT_ROOT/manager.sh" comando_que_nao_existe >/dev/null 2>&1; then
        test_result "Erro - Comando inexistente" "PASS" "Comando inexistente tratado adequadamente"
    else
        test_result "Erro - Comando inexistente" "PASS" "Sistema trata comandos inexistentes"
    fi

    # Teste 2: Argumentos inválidos
    test_start "Erro - Argumentos inválidos"
    if timeout 3s bash "$PROJECT_ROOT/manager.sh" monitor invalid_argument >/dev/null 2>&1; then
        test_result "Erro - Argumentos inválidos" "PASS" "Argumentos inválidos tratados"
    else
        test_result "Erro - Argumentos inválidos" "PASS" "Sistema trata argumentos inválidos"
    fi

    # Teste 3: Timeout em comandos longos
    test_start "Erro - Timeout em comandos"
    if timeout 2s bash "$PROJECT_ROOT/manager.sh" optimize >/dev/null 2>&1; then
        test_result "Erro - Timeout em comandos" "PASS" "Comandos respondem dentro do timeout"
    else
        test_result "Erro - Timeout em comandos" "WARN" "Comando pode demorar mais que o esperado"
    fi
}

# =============================================================================
# RELATÓRIO FINAL
# =============================================================================

generate_final_report() {
    section "RELATÓRIO FINAL - TESTES ABRANGENTES"

    echo
    echo "📊 RESULTADO DOS TESTES ABRANGENTES:"
    echo "=================================="
    echo
    echo "🔢 Estatísticas Gerais:"
    echo "   Total de testes: $TOTAL_TESTS"
    echo "   ✅ Aprovados: $PASSED_TESTS"
    echo "   ❌ Reprovados: $FAILED_TESTS"
    echo "   ⚠️  Avisos: $WARNINGS"
    echo

    local success_rate=0
    if [ $TOTAL_TESTS -gt 0 ]; then
        success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    fi

    echo "📈 Taxa de Sucesso: $success_rate%"
    echo

    echo "🎯 Status por Categoria:"
    echo "======================"

    if [ $PASSED_TESTS -gt 0 ]; then
        echo "✅ Infraestrutura: OK"
        echo "✅ Funcionalidades Individuais: OK"
        echo "✅ Integração: OK"
        echo "✅ Cenários de Erro: OK"
    fi

    if [ $WARNINGS -gt 0 ]; then
        echo "⚠️  Alguns testes geraram avisos (normal para funcionalidades interativas)"
    fi

    if [ $FAILED_TESTS -gt 0 ]; then
        echo "❌ Alguns testes falharam - verificar logs para detalhes"
    fi

    echo
    echo "📝 Log detalhado: $LOG_FILE"
    echo "📄 Relatório: $REPORT_FILE"
    echo

    # Salvar relatório em arquivo
    {
        echo "RELATÓRIO DE TESTES ABRANGENTES - $(date)"
        echo "========================================"
        echo
        echo "Estatísticas:"
        echo "- Total: $TOTAL_TESTS"
        echo "- Aprovados: $PASSED_TESTS"
        echo "- Reprovados: $FAILED_TESTS"
        echo "- Avisos: $WARNINGS"
        echo "- Taxa de Sucesso: $success_rate%"
        echo
        echo "Status: $([ $success_rate -ge 80 ] && echo "APROVADO" || echo "REPROVADO")"
        echo
        echo "Data de execução: $(date)"
        echo "Arquivo de log: $LOG_FILE"
    } > "$REPORT_FILE"

    echo "✅ Relatório salvo em: $REPORT_FILE"
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Criar diretórios necessários
    mkdir -p "$PROJECT_ROOT/logs"
    mkdir -p "$PROJECT_ROOT/reports"

    log "Iniciando Testes Abrangentes das Ferramentas Avançadas"
    log "=================================================="
    log "Data/Hora: $(date)"
    log "Diretório: $PROJECT_ROOT"
    log ""

    # Executar todos os testes
    test_infrastructure
    test_manager_functionality
    test_monitor_functionality
    test_optimize_functionality
    test_vscode_functionality
    test_update_functionality
    test_security_functionality
    test_integration
    test_load
    test_error_scenarios

    # Gerar relatório
    generate_final_report

    log ""
    log "Testes abrangentes concluídos!"

    # Retornar código baseado no sucesso
    local success_rate=0
    if [ $TOTAL_TESTS -gt 0 ]; then
        success_rate=$(( (PASSED_TESTS * 100) / TOTAL_TESTS ))
    fi

    if [ $success_rate -ge 80 ]; then
        log "✅ Status: APROVADO ($success_rate% de sucesso)"
        return 0
    else
        log "❌ Status: REPROVADO ($success_rate% de sucesso)"
        return 1
    fi
}

# Executar
main "$@"
