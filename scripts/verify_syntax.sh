#!/bin/bash
# =============================================================================
# Script de Verificação de Sintaxe - Cluster AI
# =============================================================================
# Verifica a sintaxe de todos os scripts bash e Python do projeto
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# =============================================================================

set -euo pipefail

# Verificar se o terminal suporta cores
if [[ -t 1 ]] && [[ -n "${TERM:-}" ]] && [[ "${TERM}" != "dumb" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    GRAY='\033[0;37m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    GRAY=''
    BOLD=''
    NC=''
fi

# Configurações
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/logs"
SYNTAX_LOG="${LOG_DIR}/syntax_check.log"

# Criar diretório de logs se não existir
mkdir -p "$LOG_DIR"

# Função para log
log_syntax() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$SYNTAX_LOG"
}

# Função para verificar sintaxe bash
check_bash_syntax() {
    local file="$1"
    local relative_path="${file#$PROJECT_ROOT/}"

    printf "  %-50s" "$relative_path"

    if bash -n "$file" 2>/dev/null; then
        echo -e "${GREEN}✓ OK${NC}"
        log_syntax "BASH_OK: $relative_path"
        return 0
    else
        echo -e "${RED}✗ ERROR${NC}"
        log_syntax "BASH_ERROR: $relative_path"
        return 1
    fi
}

# Função para verificar sintaxe Python
check_python_syntax() {
    local file="$1"
    local relative_path="${file#$PROJECT_ROOT/}"

    printf "  %-50s" "$relative_path"

    if python3 -m py_compile "$file" 2>/dev/null; then
        echo -e "${GREEN}✓ OK${NC}"
        log_syntax "PYTHON_OK: $relative_path"
        return 0
    else
        echo -e "${RED}✗ ERROR${NC}"
        log_syntax "PYTHON_ERROR: $relative_path"
        return 1
    fi
}

# Iniciar log
log_syntax "=== VERIFICAÇÃO DE SINTAXE INICIADA ==="

echo -e "\n${BOLD}${CYAN}🔍 VERIFICANDO SINTAXE DOS ARQUIVOS - CLUSTER AI${NC}\n"

bash_errors=0
python_errors=0
total_bash=0
total_python=0

# Verificar scripts bash
echo -e "${BOLD}${BLUE}SCRIPTS BASH (.sh)${NC}"

while IFS= read -r -d '' file; do
    ((total_bash++))
    if ! check_bash_syntax "$file"; then
        ((bash_errors++))
    fi
done < <(find "$PROJECT_ROOT" -name "*.sh" -type f -print0)

# Verificar arquivos Python
echo -e "\n${BOLD}${BLUE}ARQUIVOS PYTHON (.py)${NC}"

while IFS= read -r -d '' file; do
    ((total_python++))
    if ! check_python_syntax "$file"; then
        ((python_errors++))
    fi
done < <(find "$PROJECT_ROOT" -name "*.py" -type f -print0)

# Verificar requirements.txt
echo -e "\n${BOLD}${BLUE}DEPENDÊNCIAS PYTHON${NC}"

printf "  %-50s" "requirements.txt"
if [[ -f "$PROJECT_ROOT/requirements.txt" ]]; then
    if python3 -c "import pkg_resources; [pkg_resources.Requirement.parse(line.strip()) for line in open('$PROJECT_ROOT/requirements.txt') if line.strip() and not line.startswith('#')]" 2>/dev/null; then
        echo -e "${GREEN}✓ OK${NC}"
        log_syntax "REQUIREMENTS_OK"
    else
        echo -e "${RED}✗ ERROR${NC}"
        log_syntax "REQUIREMENTS_ERROR"
    fi
else
    echo -e "${YELLOW}⚠️ Não encontrado${NC}"
    log_syntax "REQUIREMENTS_MISSING"
fi

# Status final
echo -e "\n${BOLD}${BLUE}RESULTADO FINAL${NC}"

echo "  Scripts Bash: $total_bash arquivos verificados"
if [ $bash_errors -eq 0 ]; then
    echo -e "    ${GREEN}✓ Todos os scripts bash estão OK${NC}"
else
    echo -e "    ${RED}✗ $bash_errors script(s) bash com erro(s)${NC}"
fi

echo "  Arquivos Python: $total_python arquivos verificados"
if [ $python_errors -eq 0 ]; then
    echo -e "    ${GREEN}✓ Todos os arquivos Python estão OK${NC}"
else
    echo -e "    ${RED}✗ $python_errors arquivo(s) Python com erro(s)${NC}"
fi

total_errors=$((bash_errors + python_errors))

if [ $total_errors -eq 0 ]; then
    echo -e "\n${GREEN}🎉 SINTAXE VERIFICADA COM SUCESSO!${NC}"
    log_syntax "SYNTAX_CHECK_SUCCESS"
else
    echo -e "\n${RED}⚠️ ENCONTRADOS $total_errors ERRO(S) DE SINTAXE${NC}"
    echo -e "${CYAN}Verifique o log detalhado: $SYNTAX_LOG${NC}"
    log_syntax "SYNTAX_CHECK_FAILED: $total_errors errors"
fi

echo -e "\n${GRAY}Log detalhado: $SYNTAX_LOG${NC}"

log_syntax "=== VERIFICAÇÃO DE SINTAXE CONCLUÍDA ==="
