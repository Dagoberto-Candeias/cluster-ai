#!/bin/bash
# =============================================================================
# Cluster AI - Run All Tests
# =============================================================================
# Ponto de entrada para todos os tipos de testes: Python, Bash, Linters e Validações.
# Executa suite completa de testes automatizados do Cluster AI.
#
# Projeto: Cluster AI - Sistema Universal de IA Distribuída
# URL: https://github.com/your-org/cluster-ai
#
# Autor: Cluster AI Team
# Data: 2025-01-27
# Versão: 1.0.0
# Arquivo: run_all_tests.sh
# Licença: MIT
# =============================================================================

# Configurações de segurança e robustez
set -euo pipefail  # Exit on error, undefined vars, pipe failures
umask 027         # Secure file permissions
IFS=$'\n\t'       # Safe IFS for word splitting

# Carregar biblioteca comum se disponível
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Carregar common.sh se disponível
if [[ -r "${PROJECT_ROOT}/scripts/lib/common.sh" ]]; then
    # shellcheck disable=SC1091
    source "${PROJECT_ROOT}/scripts/lib/common.sh"
fi

# Fallback para funções essenciais se common.sh não estiver disponível
if ! command -v log >/dev/null 2>&1; then
    log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [LOG] $*"; }
fi
if ! command -v error >/dev/null 2>&1; then
    error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $*" >&2; }
fi
if ! command -v success >/dev/null 2>&1; then
    success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] $*"; }
fi

# Configurações globais
readonly LOG_DIR="${PROJECT_ROOT}/logs"
readonly TEST_LOG="${LOG_DIR}/test_execution.log"

# Criar diretórios necessários
mkdir -p "$LOG_DIR"

# Logging setup
exec > >(tee -a "$TEST_LOG") 2>&1

# Trap para cleanup
cleanup() {
    local exit_code=$?
    # Cleanup code here if needed
    exit $exit_code
}
trap cleanup EXIT INT TERM

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly GRAY='\033[0;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# =============================================================================
# FUNÇÕES AUXILIARES
# =============================================================================

# Exibir uso do script
usage() {
    cat << EOF
Uso: $0 [OPÇÕES]

Executa suite completa de testes do Cluster AI.

OPÇÕES:
    -h, --help          Exibir esta ajuda
    -v, --verbose       Modo verboso
    -q, --quiet         Modo silencioso
    --python-only       Executar apenas testes Python
    --bash-only         Executar apenas testes Bash
    --skip-python       Pular testes Python
    --skip-bash         Pular testes Bash
    --version           Exibir versão

EXEMPLOS:
    $0                    # Executar todos os testes
    $0 --python-only     # Apenas testes Python
    $0 --bash-only       # Apenas testes Bash
    $0 --skip-python     # Pular testes Python

Para mais informações, consulte: https://github.com/your-org/cluster-ai
EOF
}

# Processar argumentos da linha de comando
parse_args() {
    VERBOSE=false
    QUIET=false
    PYTHON_ONLY=false
    BASH_ONLY=false
    SKIP_PYTHON=false
    SKIP_BASH=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            --python-only)
                PYTHON_ONLY=true
                shift
                ;;
            --bash-only)
                BASH_ONLY=true
                shift
                ;;
            --skip-python)
                SKIP_PYTHON=true
                shift
                ;;
            --skip-bash)
                SKIP_BASH=true
                shift
                ;;
            --version)
                echo "$(basename "$0") v1.0.0"
                exit 0
                ;;
            *)
                error "Opção desconhecida: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Verificar dependências
check_dependencies() {
    local deps=("python3")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Dependências faltando: ${missing[*]}"
        exit 1
    fi
}

# Executar testes Python
run_python_tests() {
    if [[ "$SKIP_PYTHON" == true ]]; then
        if [[ "$VERBOSE" == true ]]; then
            log "Pulando testes Python (--skip-python)"
        fi
        return 0
    fi

    if [[ "$QUIET" == false ]]; then
        echo -e "\n${BOLD}${BLUE}EXECUTANDO TESTES PYTHON${NC}"
        echo -e "${BLUE}$(printf '%.0s=' {1..50})${NC}"
    fi

    # Ativar ambiente virtual se existir
    local python_cmd="python3"
    if [[ -d "${PROJECT_ROOT}/cluster-ai-env" ]]; then
        if [[ "$VERBOSE" == true ]]; then
            log "Ativando ambiente virtual: ${PROJECT_ROOT}/cluster-ai-env"
        fi
        # shellcheck disable=SC1091
        source "${PROJECT_ROOT}/cluster-ai-env/bin/activate"
        python_cmd="${PROJECT_ROOT}/cluster-ai-env/bin/python"
    fi

    # Executar testes com pytest
    if [[ "$VERBOSE" == true ]]; then
        log "Executando: $python_cmd -m pytest --maxfail=1 --disable-warnings"
    fi

    if $python_cmd -m pytest --maxfail=1 --disable-warnings -q; then
        if [[ "$QUIET" == false ]]; then
            success "Testes Python concluídos com sucesso"
        fi
        return 0
    else
        error "Falha nos testes Python"
        return 1
    fi
}

# Executar testes Bash
run_bash_tests() {
    if [[ "$SKIP_BASH" == true ]]; then
        if [[ "$VERBOSE" == true ]]; then
            log "Pulando testes Bash (--skip-bash)"
        fi
        return 0
    fi

    if [[ "$QUIET" == false ]]; then
        echo -e "\n${BOLD}${BLUE}EXECUTANDO TESTES BASH${NC}"
        echo -e "${BLUE}$(printf '%.0s=' {1..50})${NC}"
    fi

    local test_count=0
    local success_count=0
    local fail_count=0

    # Executar scripts de teste bash
    if [[ -d "${PROJECT_ROOT}/scripts/validation" ]]; then
        while IFS= read -r -d '' script; do
            # Pular o próprio script
            if [[ "$(basename "$script")" == "$(basename "$0")" ]]; then
                continue
            fi

            ((test_count++))
            if [[ "$QUIET" == false ]]; then
                echo -n "Executando: $(basename "$script")... "
            fi

            if [[ "$VERBOSE" == true ]]; then
                log "Executando script: $script"
            fi

            if bash "$script" >/dev/null 2>&1; then
                ((success_count++))
                if [[ "$QUIET" == false ]]; then
                    echo -e "${GREEN}PASS${NC}"
                fi
            else
                ((fail_count++))
                if [[ "$QUIET" == false ]]; then
                    echo -e "${RED}FAIL${NC}"
                fi
                if [[ "$VERBOSE" == true ]]; then
                    error "Falha no script: $script"
                fi
            fi
        done < <(find "${PROJECT_ROOT}/scripts/validation" -name "*.sh" -type f -print0)
    fi

    if [[ "$QUIET" == false ]]; then
        echo -e "\n${BOLD}RESUMO TESTES BASH${NC}"
        echo -e "Total: $test_count | Sucesso: ${GREEN}$success_count${NC} | Falha: ${RED}$fail_count${NC}"
    fi

    if [[ $fail_count -gt 0 ]]; then
        return 1
    else
        if [[ "$QUIET" == false ]]; then
            success "Testes Bash concluídos com sucesso"
        fi
        return 0
    fi
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Processar argumentos
    parse_args "$@"

    # Verificações iniciais
    check_dependencies

    # Log de início
    log "Iniciando $(basename "$0")"

    if [[ "$QUIET" == false ]]; then
        echo -e "${BOLD}${CYAN}🚀 INICIANDO SUITE COMPLETA DE TESTES - CLUSTER AI${NC}\n"
    fi

    local exit_code=0

    # Executar testes Python
    if [[ "$BASH_ONLY" == false ]]; then
        if ! run_python_tests; then
            exit_code=1
        fi
    fi

    # Executar testes Bash
    if [[ "$PYTHON_ONLY" == false ]]; then
        if ! run_bash_tests; then
            exit_code=1
        fi
    fi

    # Log de conclusão
    if [[ $exit_code -eq 0 ]]; then
        success "$(basename "$0") concluído com sucesso"
        if [[ "$QUIET" == false ]]; then
            echo -e "\n${BOLD}${GREEN}✅ SUITE DE TESTES CONCLUÍDA COM SUCESSO${NC}"
        fi
    else
        error "$(basename "$0") concluído com falhas"
        if [[ "$QUIET" == false ]]; then
            echo -e "\n${BOLD}${RED}❌ SUITE DE TESTES CONCLUÍDA COM FALHAS${NC}"
        fi
    fi

    return $exit_code
}

# =============================================================================
# EXECUÇÃO
# =============================================================================

# Executar função principal se script for chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

# =============================================================================
# FIM DO SCRIPT
# =============================================================================
