#!/bin/bash
#
# run_coverage.sh - Gera um relatório de cobertura de código para os scripts shell.
# Pode opcionalmente verificar se a cobertura atinge um limite mínimo.

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="${PROJECT_ROOT}/scripts/lib"
COVERAGE_DIR="${PROJECT_ROOT}/coverage"
MIN_COVERAGE_THRESHOLD="${1:-0}" # Pega o primeiro argumento como limite, ou 0 se não for passado

# Carregar funções comuns
source "${LIB_DIR}/common.sh"

section "Gerando Relatório de Cobertura de Código com kcov"

if ! command_exists kcov || ! command_exists jq; then
    local missing_tools=""
    if ! command_exists kcov; then missing_tools+="kcov "; fi
    if ! command_exists jq; then missing_tools+="jq "; fi

    error "Ferramentas necessárias não encontradas: $missing_tools"
    info "Instale-as com: sudo apt install kcov jq (ou equivalente)."
    exit 1
fi

progress "Limpando relatórios antigos..."
rm -rf "$COVERAGE_DIR"
mkdir -p "$COVERAGE_DIR"

progress "Executando testes BATS sob o kcov..."

# Executa kcov, focando apenas nos scripts do projeto
kcov --include-pattern="${PROJECT_ROOT}/scripts,${PROJECT_ROOT}/manager.sh" \
     --exclude-pattern="/tests/" \
     "$COVERAGE_DIR" \
     bats "${PROJECT_ROOT}/tests/bash/"

local coverage_summary_file="${COVERAGE_DIR}/kcov-merged/coverage.json"
if [ -f "$coverage_summary_file" ]; then
    local total_coverage
    total_coverage=$(jq '.percent_covered' "$coverage_summary_file" | cut -d'.' -f1)
    
    success "Relatório de cobertura gerado com sucesso!"
    # A linha abaixo é crucial para a integração com GitLab CI
    info "Cobertura Total (Coverage): ${total_coverage}%"

    # VERIFICAÇÃO DO LIMITE DE COBERTURA
    if [ "$MIN_COVERAGE_THRESHOLD" -gt 0 ]; then
        if [ "$total_coverage" -lt "$MIN_COVERAGE_THRESHOLD" ]; then
            error "A cobertura de código (${total_coverage}%) está abaixo do limite de ${MIN_COVERAGE_THRESHOLD}%."
            exit 1
        else
            success "A cobertura de código (${total_coverage}%) atende ao limite de ${MIN_COVERAGE_THRESHOLD}%."
        fi
    fi
else
    error "Arquivo de resumo da cobertura não foi gerado pelo kcov."
fi

info "Abra o seguinte arquivo no seu navegador para ver o resultado:"
info "  file://${COVERAGE_DIR}/index.html"