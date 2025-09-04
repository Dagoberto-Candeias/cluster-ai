#!/bin/bash
# Validador de Integração das Ferramentas Avançadas
# Autor: Sistema Cluster AI
# Descrição: Valida se todas as integrações estão funcionando corretamente

set -euo pipefail

# =============================================================================
# CONFIGURAÇÃO
# =============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="${PROJECT_ROOT}/scripts"
VALIDATION_LOG="${PROJECT_ROOT}/logs/validation_$(date +%Y%m%d_%H%M%S).log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =============================================================================
# FUNÇÕES UTILITÁRIAS
# =============================================================================

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1" | tee -a "$VALIDATION_LOG"
}

success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$VALIDATION_LOG"
}

error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$VALIDATION_LOG"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$VALIDATION_LOG"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}" | tee -a "$VALIDATION_LOG"
}

# =============================================================================
# VALIDAÇÕES INDIVIDUAIS
# =============================================================================

validate_script_exists() {
    local script_path="$1"
    local description="$2"

    if [ -f "$script_path" ]; then
        success "$description - Script encontrado"
        return 0
    else
        error "$description - Script NÃO encontrado: $script_path"
        return 1
    fi
}

validate_script_executable() {
    local script_path="$1"
    local description="$2"

    if [ -x "$script_path" ]; then
        success "$description - Executável"
        return 0
    else
        warning "$description - Não executável, tentando chmod +x"
        if chmod +x "$script_path" 2>/dev/null; then
            success "$description - Permissões corrigidas"
            return 0
        else
            error "$description - Falha ao definir permissões"
            return 1
        fi
    fi
}

validate_manager_command() {
    local command="$1"
    local description="$2"

    if ./manager.sh "$command" --help >/dev/null 2>&1; then
        success "$description - Comando funcional"
        return 0
    else
        error "$description - Comando falhou"
        return 1
    fi
}

validate_script_syntax() {
    local script_path="$1"
    local description="$2"

    if bash -n "$script_path" 2>/dev/null; then
        success "$description - Sintaxe OK"
        return 0
    else
        error "$description - Erro de sintaxe"
        return 1
    fi
}

# =============================================================================
# VALIDAÇÕES PRINCIPAIS
# =============================================================================

validate_manager_integration() {
    section "Validando Integração no Manager"

    local passed=0
    local total=0

    # Verificar se manager existe e é executável
    ((total++))
    if validate_script_exists "$PROJECT_ROOT/manager.sh" "Manager principal"; then
        ((passed++))
    fi

    ((total++))
    if validate_script_executable "$PROJECT_ROOT/manager.sh" "Manager principal"; then
        ((passed++))
    fi

    # Verificar sintaxe do manager
    ((total++))
    if validate_script_syntax "$PROJECT_ROOT/manager.sh" "Manager principal"; then
        ((passed++))
    fi

    # Verificar comandos das ferramentas avançadas
    local commands=("monitor" "optimize" "vscode" "update" "security")
    for cmd in "${commands[@]}"; do
        ((total++))
        if validate_manager_command "$cmd" "Manager $cmd"; then
            ((passed++))
        fi
    done

    log "Manager: $passed/$total validações passaram"
    return $((total - passed))
}

validate_advanced_scripts() {
    section "Validando Scripts Avançados"

    local passed=0
    local total=0

    # Lista de scripts a validar
    declare -A scripts=(
        ["scripts/monitoring/central_monitor.sh"]="Monitor Central"
        ["scripts/optimization/performance_optimizer.sh"]="Otimizador"
        ["scripts/maintenance/vscode_manager.sh"]="VSCode Manager"
        ["scripts/maintenance/auto_updater.sh"]="Auto Updater"
        ["scripts/security/auth_manager.sh"]="Auth Manager"
        ["scripts/security/firewall_manager.sh"]="Firewall Manager"
        ["scripts/security/security_logger.sh"]="Security Logger"
    )

    for script in "${!scripts[@]}"; do
        local description="${scripts[$script]}"
        local script_path="$PROJECT_ROOT/$script"

        # Verificar existência
        ((total++))
        if validate_script_exists "$script_path" "$description"; then
            ((passed++))

            # Verificar executabilidade
            ((total++))
            if validate_script_executable "$script_path" "$description"; then
                ((passed++))
            fi

            # Verificar sintaxe
            ((total++))
            if validate_script_syntax "$script_path" "$description"; then
                ((passed++))
            fi
        else
            ((total += 2)) # Conta as validações que não puderam ser feitas
        fi
    done

    log "Scripts: $passed/$total validações passaram"
    return $((total - passed))
}

validate_documentation() {
    section "Validando Documentação"

    local passed=0
    local total=0

    # Verificar arquivos de documentação
    local docs=(
        "docs/guides/ADVANCED_TOOLS.md"
        "TODO_INTEGRATION.md"
    )

    for doc in "${docs[@]}"; do
        ((total++))
        if validate_script_exists "$PROJECT_ROOT/$doc" "Documentação $doc"; then
            ((passed++))
        fi
    done

    log "Documentação: $passed/$total validações passaram"
    return $((total - passed))
}

validate_functionality() {
    section "Validando Funcionalidades"

    local passed=0
    local total=0

    # Testar funcionalidades básicas
    local tests=(
        "help:Ajuda do manager"
        "status:Status do cluster"
        "diag:Diagnóstico"
    )

    for test in "${tests[@]}"; do
        IFS=':' read -r cmd description <<< "$test"
        ((total++))
        if ./manager.sh "$cmd" >/dev/null 2>&1; then
            success "Funcionalidade $description - OK"
            ((passed++))
        else
            error "Funcionalidade $description - Falhou"
        fi
    done

    # Testar ferramentas avançadas (modo help apenas)
    local advanced_tests=(
        "monitor --help:Monitor help"
        "optimize --help:Optimize help"
        "vscode --help:VSCode help"
        "update --help:Update help"
        "security --help:Security help"
    )

    for test in "${advanced_tests[@]}"; do
        IFS=':' read -r cmd description <<< "$test"
        ((total++))
        if eval "./manager.sh $cmd" >/dev/null 2>&1; then
            success "Funcionalidade $description - OK"
            ((passed++))
        else
            error "Funcionalidade $description - Falhou"
        fi
    done

    log "Funcionalidades: $passed/$total validações passaram"
    return $((total - passed))
}

# =============================================================================
# RELATÓRIO FINAL
# =============================================================================

generate_report() {
    section "Relatório Final de Validação"

    local total_passed=0
    local total_tests=0

    # Calcular estatísticas
    while IFS= read -r line; do
        if [[ $line == *"✅"* ]]; then
            ((total_passed++))
        fi
        if [[ $line == *"✅"* ]] || [[ $line == *"❌"* ]] || [[ $line == *"⚠️"* ]]; then
            ((total_tests++))
        fi
    done < "$VALIDATION_LOG"

    local success_rate=0
    if [ $total_tests -gt 0 ]; then
        success_rate=$(( (total_passed * 100) / total_tests ))
    fi

    echo
    echo "📊 RESULTADO FINAL:"
    echo "=================="
    echo "✅ Validações Aprovadas: $total_passed"
    echo "📋 Total de Testes: $total_tests"
    echo "🎯 Taxa de Sucesso: ${success_rate}%"
    echo
    echo "📝 Log detalhado: $VALIDATION_LOG"
    echo

    if [ $success_rate -ge 90 ]; then
        success "🎉 VALIDAÇÃO APROVADA! Sistema pronto para uso."
        return 0
    elif [ $success_rate -ge 75 ]; then
        warning "⚠️  VALIDAÇÃO COM ALERTAS. Revisar pontos críticos."
        return 1
    else
        error "❌ VALIDAÇÃO REPROVADA. Correções necessárias."
        return 2
    fi
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Criar diretório de logs se não existir
    mkdir -p "$PROJECT_ROOT/logs"

    log "Iniciando Validação de Integração - Cluster AI"
    log "=============================================="
    log "Data/Hora: $(date)"
    log "Diretório: $PROJECT_ROOT"
    log ""

    local exit_code=0

    # Executar validações
    validate_manager_integration
    local manager_result=$?

    validate_advanced_scripts
    local scripts_result=$?

    validate_documentation
    local docs_result=$?

    validate_functionality
    local func_result=$?

    # Calcular resultado geral
    if [ $manager_result -ne 0 ] || [ $scripts_result -ne 0 ] || [ $docs_result -ne 0 ] || [ $func_result -ne 0 ]; then
        exit_code=1
    fi

    # Gerar relatório
    generate_report
    local report_result=$?

    if [ $report_result -eq 2 ]; then
        exit_code=2
    fi

    log ""
    log "Validação concluída com código de saída: $exit_code"

    return $exit_code
}

# =============================================================================
# UTILITÁRIOS
# =============================================================================

section() {
    echo
    echo -e "${BLUE}================================================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================================================================${NC}"
    echo
}

# Executar
main "$@"
