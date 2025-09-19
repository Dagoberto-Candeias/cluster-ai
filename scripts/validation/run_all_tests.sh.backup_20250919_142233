#!/bin/bash
#
# 🚀 EXECUTOR DE TESTES UNIFICADO - CLUSTER AI
# Ponto de entrada para todos os tipos de testes: Python, Bash e Linters.
#

set -euo pipefail

# --- Configuração ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

PYTHON_TESTS_DIR="${PROJECT_ROOT}/tests"
BASH_TESTS_DIR="${PROJECT_ROOT}/tests/bash"
REPORTS_DIR="${PROJECT_ROOT}/tests/reports"

FAILED_SUITES=0

# --- Funções Auxiliares ---

# Executa uma suíte de testes e verifica o resultado
run_suite() {
    local title="$1"
    shift
    local command=("$@")

    subsection "▶ $title"
    
    local start_time; start_time=$(date +%s)
    local output_log; output_log=$(mktemp)
    
    if "${command[@]}" > "$output_log" 2>&1; then
        local end_time; end_time=$(date +%s)
        local duration=$((end_time - start_time))
        success "✅ Passou em ${duration} segundos"
    else
        local end_time; end_time=$(date +%s)
        local duration=$((end_time - start_time))
        error "❌ Falhou em ${duration} segundos"
        ((FAILED_SUITES++))
        
        # Exibe a saída do log em caso de falha
        if [ -s "$output_log" ]; then
            echo -e "${YELLOW}--- LOG DE SAÍDA ---${NC}"
            cat "$output_log" | sed 's/^/  /'
            echo -e "${YELLOW}--------------------${NC}"
        fi
    fi
    rm -f "$output_log"
    echo
}

# --- Execução das Suítes de Teste ---

main() {
    section "🧪 Executando Suíte de Testes Completa do Cluster AI"
    mkdir -p "$REPORTS_DIR"

    # 1. Testes Python (Pytest) por marcador
    if command_exists pytest; then
        run_suite "TESTES DE PERFORMANCE (PYTEST)" pytest -m performance --html="$REPORTS_DIR/performance_tests.html"
        run_suite "TESTES DE SEGURANÇA (PYTEST)" pytest -m security --html="$REPORTS_DIR/security_tests.html"
        run_suite "TESTES DE FUMAÇA (PYTEST)" pytest -m smoke --html="$REPORTS_DIR/smoke_tests.html"
        run_suite "TESTES DE INTEGRAÇÃO (PYTEST)" pytest -m integration --html="$REPORTS_DIR/integration_tests.html"
    else
        warn "Pytest não encontrado. Pulando testes de Python."
    fi

    # 2. Testes de Scripts Bash (BATS)
    if ! command_exists bats; then
        warn "BATS não encontrado. Tentando instalar..."
        if sudo apt-get update && sudo apt-get install -y bats; then
            success "BATS instalado com sucesso."
        else
            error "Falha ao instalar BATS. Pulando testes de Bash."
            ((FAILED_SUITES++))
        fi
    fi
    
    if command_exists bats; then
        if [ -d "$BASH_TESTS_DIR" ]; then
            run_suite "TESTES DE SCRIPTS BASH (BATS)" bats "$BASH_TESTS_DIR"
        else
            info "Diretório de testes BATS não encontrado em '$BASH_TESTS_DIR'. Pulando."
        fi
    fi

    # 3. Verificação de Código (Linter)
    local linter_script="${PROJECT_ROOT}/scripts/maintenance/run_linter.sh"
    if [ -f "$linter_script" ]; then
        run_suite "VERIFICAÇÃO DE CÓDIGO (LINTER)" bash "$linter_script"
    else
        info "Script de linter não encontrado. Pulando."
    fi

    # --- Resumo Final ---
    section "🏁 Resumo Final da Execução 🏁"
    if [ "$FAILED_SUITES" -eq 0 ]; then
        success "🎉 Todas as suítes de teste passaram com sucesso!"
        exit 0
    else
        error "🚨 $FAILED_SUITES suíte(s) de teste falharam. Verifique os logs acima."
        exit 1
    fi
}

main "$@"

```

### 2. Falha na Instalação do BATS

**Problema:**
A instalação do `bats` está falhando porque um dos seus repositórios configurados no `apt` (o do ROCm da AMD) está com problemas e não consegue encontrar um arquivo `Release`. Isso impede que o `apt-get update` seja concluído com sucesso.

**Solução:**
A melhor abordagem é corrigir a lista de repositórios do seu sistema. O repositório do ROCm para Debian parece estar mal configurado. Você pode comentá-lo temporariamente para permitir que o `apt` funcione.

Execute o seguinte comando para fazer um backup e desativar a linha problemática:

```bash
sudo sed -i.bak 's|^deb.*repo.radeon.com/rocm/apt/debian|# &|' /etc/apt/sources.list.d/rocm.list
