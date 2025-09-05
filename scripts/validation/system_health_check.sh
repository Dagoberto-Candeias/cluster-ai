#!/bin/bash
# Script de verificação geral da saúde do sistema Cluster AI

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar se estamos no diretório correto
check_project_structure() {
    log "Verificando estrutura do projeto..."

    required_files=(
        "README.md"
        "manager.sh"
        "install_unified.sh"
        "requirements.txt"
        "cluster.conf"
    )

    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "Arquivo encontrado: $file"
        else
            log_error "Arquivo não encontrado: $file"
            return 1
        fi
    done

    required_dirs=(
        "scripts"
        "tests"
        "docs"
        ".vscode"
    )

    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_success "Diretório encontrado: $dir"
        else
            log_error "Diretório não encontrado: $dir"
            return 1
        fi
    done
}

# Verificar permissões de arquivos críticos
check_file_permissions() {
    log "Verificando permissões de arquivos críticos..."

    critical_files=(
        "manager.sh"
        "install_unified.sh"
        "scripts/security/test_security_improvements.sh"
    )

    for file in "${critical_files[@]}"; do
        if [[ -f "$file" && -x "$file" ]]; then
            log_success "Arquivo executável: $file"
        else
            log_error "Arquivo não executável ou não encontrado: $file"
            return 1
        fi
    done
}

# Verificar dependências Python
check_python_dependencies() {
    log "Verificando dependências Python..."

    if ! command -v python3 &> /dev/null; then
        log_error "Python3 não encontrado"
        return 1
    fi

    if ! command -v pip &> /dev/null; then
        log_error "pip não encontrado"
        return 1
    fi

    log_success "Python3 encontrado: $(python3 --version)"
    log_success "pip encontrado: $(pip --version)"

    # Verificar requirements.txt
    if [[ -f "requirements.txt" ]]; then
        log "Verificando requirements.txt..."
        while IFS= read -r line; do
            if [[ ! -z "$line" && ! "$line" =~ ^# ]]; then
                package=$(echo "$line" | cut -d'=' -f1 | cut -d'>' -f1 | cut -d'<' -f1 | xargs)
                if python3 -c "import $package" 2>/dev/null; then
                    log_success "Pacote instalado: $package"
                else
                    log_warning "Pacote não instalado: $package"
                fi
            fi
        done < requirements.txt
    fi
}

# Verificar Docker
check_docker() {
    log "Verificando Docker..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker não encontrado"
        return 1
    fi

    log_success "Docker encontrado: $(docker --version)"

    # Verificar se Docker está rodando
    if docker info &> /dev/null; then
        log_success "Docker daemon está rodando"
    else
        log_error "Docker daemon não está rodando"
        return 1
    fi
}

# Executar testes básicos
run_basic_tests() {
    log "Executando testes básicos..."

    if ! command -v pytest &> /dev/null; then
        log_error "pytest não encontrado"
        return 1
    fi

    # Executar apenas testes de segurança básicos (mais rápidos)
    if pytest tests/security/test_cluster_security.py -q --tb=no; then
        log_success "Testes de segurança básicos passaram"
    else
        log_error "Testes de segurança básicos falharam"
        return 1
    fi

    # Executar testes de integração
    if pytest tests/integration/test_manager_integration.py -q --tb=no; then
        log_success "Testes de integração passaram"
    else
        log_error "Testes de integração falharam"
        return 1
    fi
}

# Verificar configuração
check_configuration() {
    log "Verificando configuração..."

    if [[ -f "cluster.conf" ]]; then
        log_success "Arquivo de configuração encontrado"

        # Verificar se contém configurações básicas
        if grep -q "\[services\]" cluster.conf; then
            log_success "Seção [services] encontrada"
        else
            log_warning "Seção [services] não encontrada"
        fi
    else
        log_error "Arquivo cluster.conf não encontrado"
        return 1
    fi
}

# Verificar scripts de segurança
check_security_scripts() {
    log "Verificando scripts de segurança..."

    security_scripts=(
        "scripts/security/test_security_improvements.sh"
        "scripts/security/security_audit.sh"
        "scripts/security/check_permissions.sh"
    )

    for script in "${security_scripts[@]}"; do
        if [[ -f "$script" && -x "$script" ]]; then
            log_success "Script de segurança encontrado: $script"
        else
            log_warning "Script de segurança não encontrado ou não executável: $script"
        fi
    done
}

# Verificar documentação
check_documentation() {
    log "Verificando documentação..."

    doc_files=(
        "README.md"
        "docs/INDEX.md"
        "SECURITY_IMPROVEMENTS.md"
    )

    for doc in "${doc_files[@]}"; do
        if [[ -f "$doc" ]]; then
            log_success "Arquivo de documentação encontrado: $doc"
        else
            log_warning "Arquivo de documentação não encontrado: $doc"
        fi
    done
}

# Função principal
main() {
    log "🚀 Iniciando verificação de saúde do sistema Cluster AI"
    echo

    local checks_passed=0
    local total_checks=0

    # Array de funções de verificação
    checks=(
        check_project_structure
        check_file_permissions
        check_python_dependencies
        check_docker
        run_basic_tests
        check_configuration
        check_security_scripts
        check_documentation
    )

    # Executar todas as verificações
    for check in "${checks[@]}"; do
        ((total_checks++))
        if $check; then
            ((checks_passed++))
        fi
        echo
    done

    # Resultado final
    log "📊 Resultado da verificação:"
    echo "Verificações passadas: $checks_passed/$total_checks"

    if [[ $checks_passed -eq $total_checks ]]; then
        log_success "🎉 Sistema Cluster AI está saudável!"
        return 0
    else
        log_warning "⚠️  Algumas verificações falharam. Verifique os logs acima."
        return 1
    fi
}

# Executar função principal
main "$@"
