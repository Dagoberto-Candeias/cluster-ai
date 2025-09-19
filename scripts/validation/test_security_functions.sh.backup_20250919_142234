#!/bin/bash
# Script de Teste para as Funções de Segurança Centralizadas

# Navegar para o diretório do script para que os caminhos relativos funcionem
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="$SCRIPT_DIR/../utils"

# Carregar funções comuns
COMMON_SCRIPT_PATH="$UTILS_DIR/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO: Script de funções comuns não encontrado em $COMMON_SCRIPT_PATH" >&2
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# --- Configuração do Teste ---
TEST_COUNT=0
FAIL_COUNT=0

# --- Funções de Teste ---

# Testa se um comando passa (retorna 0)
assert_pass() {
    local description="$1"
    shift
    ((TEST_COUNT++))
    echo -n "  [TEST $TEST_COUNT] $description... "
    # Redirecionar a saída para /dev/null para manter o teste limpo
    if "$@" >/dev/null 2>&1; then
        echo -e "${GREEN}PASSOU${NC}"
    else
        echo -e "${RED}FALHOU${NC}"
        ((FAIL_COUNT++))
    fi
}

# Testa se um comando falha (retorna não-zero)
assert_fail() {
    local description="$1"
    shift
    ((TEST_COUNT++))
    echo -n "  [TEST $TEST_COUNT] $description... "
    if ! "$@" >/dev/null 2>&1; then
        echo -e "${GREEN}PASSOU${NC}"
    else
        echo -e "${RED}FALHOU${NC}"
        ((FAIL_COUNT++))
    fi
}

# --- Execução do Teste ---
echo -e "${BLUE}=== INICIANDO TESTE DA FUNÇÃO 'safe_path_check' ===${NC}"

# 1. Testes que devem PASSAR (caminhos seguros)
echo -e "\n${CYAN}--> Cenários Válidos (devem passar):${NC}"
assert_pass "Testando caminho seguro em /tmp" safe_path_check "/tmp/safe_file"
assert_pass "Testando caminho seguro no diretório home" safe_path_check "$HOME/safe_dir"
assert_pass "Testando caminho permitido em /var/log" safe_path_check "/var/log/test.log"
assert_pass "Testando caminho relativo seguro" safe_path_check "./safe_sub_dir"

# 2. Testes que devem FALHAR (caminhos perigosos)
echo -e "\n${CYAN}--> Cenários Inválidos (devem falhar):${NC}"
assert_fail "Testando caminho vazio" safe_path_check "" "operação de teste"
assert_fail "Testando caminho raiz (/)" safe_path_check "/" "operação de teste"
assert_fail "Testando diretório crítico (/bin)" safe_path_check "/bin" "operação de teste"
assert_fail "Testando diretório crítico (/etc)" safe_path_check "/etc" "operação de teste"
assert_fail "Testando diretório crítico (/usr)" safe_path_check "/usr" "operação de teste"
assert_fail "Testando subdiretório de diretório crítico (/usr/local)" safe_path_check "/usr/local" "operação de teste"
assert_fail "Testando diretório crítico com barra no final (/etc/)" safe_path_check "/etc/" "operação de teste"
assert_fail "Testando caminho com espaços para diretório crítico" safe_path_check " /usr " "operação de teste"

# --- Teste da função 'confirm_operation' ---
echo -e "\n${BLUE}=== INICIANDO TESTE DA FUNÇÃO 'confirm_operation' ===${NC}"

# Exportar a função e variáveis de cor para que sub-shells (bash -c) possam usá-las
export -f confirm_operation
export YELLOW NC

# 3. Testes que devem PASSAR (confirmação 's' ou 'S')
echo -e "\n${CYAN}--> Cenários de Confirmação (devem passar):${NC}"
assert_pass "Testando confirmação com 's'" bash -c "echo 's' | confirm_operation 'Teste de confirmação'"
assert_pass "Testando confirmação com 'S'" bash -c "echo 'S' | confirm_operation 'Teste de confirmação'"

# 4. Testes que devem FALHAR (confirmação 'n', 'N', enter, ou qualquer outra tecla)
echo -e "\n${CYAN}--> Cenários de Negação (devem falhar):${NC}"
assert_fail "Testando negação com 'n'" bash -c "echo 'n' | confirm_operation 'Teste de negação'"
assert_fail "Testando negação com Enter (padrão)" bash -c "echo '' | confirm_operation 'Teste de negação'"
assert_fail "Testando negação com 'qualquer_coisa'" bash -c "echo 'abc' | confirm_operation 'Teste de negação'"

# --- Resumo e Limpeza ---
echo -e "\n${BLUE}=== RESULTADO DO TESTE DE SEGURANÇA ===${NC}"
if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "${GREEN}🎉 Todos os $TEST_COUNT testes de segurança passaram com sucesso!${NC}"
    echo "A função 'safe_path_check' está se comportando como esperado."
else
    echo -e "${RED}❌ $FAIL_COUNT de $TEST_COUNT testes falharam.${NC}"
    echo "A função 'safe_path_check' não está bloqueando todos os cenários perigosos."
fi

# Retornar status de saída apropriado
if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi