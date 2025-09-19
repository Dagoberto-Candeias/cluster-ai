#!/bin/bash
# Validação Rápida e Segura das Integrações
# Versão simplificada que não executa comandos interativos

set -euo pipefail

# =============================================================================
# CONFIGURAÇÃO
# =============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="${PROJECT_ROOT}/scripts"

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
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# =============================================================================
# VALIDAÇÕES BÁSICAS (NÃO INTERATIVAS)
# =============================================================================

validate_file_exists() {
    local file_path="$1"
    local description="$2"

    if [ -f "$file_path" ]; then
        success "$description - Arquivo encontrado"
        return 0
    else
        error "$description - Arquivo NÃO encontrado: $file_path"
        return 1
    fi
}

validate_file_executable() {
    local file_path="$1"
    local description="$2"

    if [ -x "$file_path" ]; then
        success "$description - Executável"
        return 0
    else
        warning "$description - Não executável"
        return 1
    fi
}

validate_file_readable() {
    local file_path="$1"
    local description="$2"

    if [ -r "$file_path" ]; then
        success "$description - Legível"
        return 0
    else
        error "$description - Não legível"
        return 1
    fi
}

validate_directory_exists() {
    local dir_path="$1"
    local description="$2"

    if [ -d "$dir_path" ]; then
        success "$description - Diretório encontrado"
        return 0
    else
        error "$description - Diretório NÃO encontrado: $dir_path"
        return 1
    fi
}

# =============================================================================
# VALIDAÇÕES ESPECÍFICAS
# =============================================================================

validate_manager_structure() {
    section "Validando Estrutura do Manager"

    local passed=0
    local total=0

    # Verificar manager.sh
    ((total++))
    if validate_file_exists "$PROJECT_ROOT/manager.sh" "Manager principal"; then
        ((passed++))
    fi

    ((total++))
    if validate_file_executable "$PROJECT_ROOT/manager.sh" "Manager principal"; then
        ((passed++))
    fi

    ((total++))
    if validate_file_readable "$PROJECT_ROOT/manager.sh" "Manager principal"; then
        ((passed++))
    fi

    # Verificar se contém as funções das ferramentas avançadas
    if grep -q "function monitor()" "$PROJECT_ROOT/manager.sh"; then
        ((total++))
        success "Manager - Função monitor encontrada"
        ((passed++))
    else
        ((total++))
        error "Manager - Função monitor NÃO encontrada"
    fi

    if grep -q "function optimize()" "$PROJECT_ROOT/manager.sh"; then
        ((total++))
        success "Manager - Função optimize encontrada"
        ((passed++))
    else
        ((total++))
        error "Manager - Função optimize NÃO encontrada"
    fi

    if grep -q "function vscode()" "$PROJECT_ROOT/manager.sh"; then
        ((total++))
        success "Manager - Função vscode encontrada"
        ((passed++))
    else
        ((total++))
        error "Manager - Função vscode NÃO encontrada"
    fi

    log "Manager: $passed/$total validações passaram"
    return $((total - passed))
}

validate_advanced_scripts() {
    section "Validando Scripts Avançados"

    local passed=0
    local total=0

    # Lista de scripts esperados
    declare -A scripts=(
        ["scripts/monitoring/central_monitor.sh"]="Monitor Central"
        ["scripts/optimization/performance_optimizer.sh"]="Otimizador de Performance"
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
        if validate_file_exists "$script_path" "$description"; then
            ((passed++))

            # Verificar executabilidade
            ((total++))
            if validate_file_executable "$script_path" "$description"; then
                ((passed++))
            fi

            # Verificar se é legível
            ((total++))
            if validate_file_readable "$script_path" "$description"; then
                ((passed++))
            fi
        else
            ((total += 2)) # Conta as validações que não puderam ser feitas
        fi
    done

    log "Scripts: $passed/$total validações passaram"
    return $((total - passed))
}

validate_directories() {
    section "Validando Estrutura de Diretórios"

    local passed=0
    local total=0

    # Diretórios esperados
    local dirs=(
        "scripts/monitoring"
        "scripts/optimization"
        "scripts/maintenance"
        "scripts/security"
        "scripts/management"
        "scripts/vscode"
        "docs/guides"
        "logs"
        "tests/unit"
    )

    for dir in "${dirs[@]}"; do
        ((total++))
        if validate_directory_exists "$PROJECT_ROOT/$dir" "Diretório $dir"; then
            ((passed++))
        fi
    done

    log "Diretórios: $passed/$total validações passaram"
    return $((total - passed))
}

validate_documentation() {
    section "Validando Documentação"

    local passed=0
    local total=0

    # Arquivos de documentação esperados
    local docs=(
        "docs/guides/ADVANCED_TOOLS.md"
        "TODO_INTEGRATION.md"
        "README.md"
    )

    for doc in "${docs[@]}"; do
        ((total++))
        if validate_file_exists "$PROJECT_ROOT/$doc" "Documentação $doc"; then
            ((passed++))

            ((total++))
            if validate_file_readable "$PROJECT_ROOT/$doc" "Documentação $doc"; then
                ((passed++))
            fi
        else
            ((total++)) # Conta a validação de legibilidade que não pôde ser feita
        fi
    done

    log "Documentação: $passed/$total validações passaram"
    return $((total - passed))
}

validate_test_files() {
    section "Validando Arquivos de Teste"

    local passed=0
    local total=0

    # Arquivos de teste esperados
    local test_files=(
        "tests/unit/test_demo_cluster.py"
        "tests/conftest.py"
        "pytest.ini"
    )

    for test_file in "${test_files[@]}"; do
        ((total++))
        if validate_file_exists "$PROJECT_ROOT/$test_file" "Arquivo de teste $test_file"; then
            ((passed++))

            ((total++))
            if validate_file_readable "$PROJECT_ROOT/$test_file" "Arquivo de teste $test_file"; then
                ((passed++))
            fi
        else
            ((total++)) # Conta a validação de legibilidade que não pôde ser feita
        fi
    done

    log "Testes: $passed/$total validações passaram"
    return $((total - passed))
}

# =============================================================================
# RELATÓRIO FINAL
# =============================================================================

generate_report() {
    section "Relatório Final de Validação"

    echo
    echo "📊 RESULTADO FINAL DA VALIDAÇÃO RÁPIDA:"
    echo "========================================"
    echo
    echo "Esta validação verificou apenas a existência e permissões dos arquivos."
    echo "Nenhum comando foi executado para evitar travamentos."
    echo
    echo "Para uma validação completa das funcionalidades, execute:"
    echo "  ./manager.sh help"
    echo "  ./manager.sh monitor --help"
    echo "  ./manager.sh optimize --help"
    echo "  ./manager.sh vscode --help"
    echo "  ./manager.sh update --help"
    echo "  ./manager.sh security --help"
    echo
    echo "Ou execute testes unitários:"
    echo "  python -m pytest tests/unit/test_demo_cluster.py -v"
    echo
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    log "Iniciando Validação Rápida - Cluster AI"
    log "======================================"
    log "Data/Hora: $(date)"
    log "Diretório: $PROJECT_ROOT"
    log ""

    local exit_code=0

    # Executar validações (todas não-interativas)
    validate_manager_structure
    local manager_result=$?

    validate_advanced_scripts
    local scripts_result=$?

    validate_directories
    local dirs_result=$?

    validate_documentation
    local docs_result=$?

    validate_test_files
    local tests_result=$?

    # Calcular resultado geral
    if [ $manager_result -ne 0 ] || [ $scripts_result -ne 0 ] || [ $dirs_result -ne 0 ] || [ $docs_result -ne 0 ] || [ $tests_result -ne 0 ]; then
        exit_code=1
    fi

    # Gerar relatório
    generate_report

    log ""
    log "Validação rápida concluída com código de saída: $exit_code"

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
