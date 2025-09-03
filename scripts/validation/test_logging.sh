#!/bin/bash
# Script de Teste para o Sistema de Log Centralizado

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
TEST_LOG_FILE="/tmp/test_cluster_ai_logging_$(date +%s).log"
TEST_COUNT=0
FAIL_COUNT=0

# --- Funções de Teste ---
assert_log_contains() {
    local pattern="$1"
    ((TEST_COUNT++))
    echo -n "  [TEST $TEST_COUNT] Verificando se o log contém '$pattern'... "
    if grep -q "$pattern" "$TEST_LOG_FILE"; then
        echo -e "${GREEN}PASSOU${NC}"
    else
        echo -e "${RED}FALHOU${NC}"
        ((FAIL_COUNT++))
    fi
}

assert_log_not_contains() {
    local pattern="$1"
    ((TEST_COUNT++))
    echo -n "  [TEST $TEST_COUNT] Verificando se o log NÃO contém '$pattern'... "
    if ! grep -q "$pattern" "$TEST_LOG_FILE"; then
        echo -e "${GREEN}PASSOU${NC}"
    else
        echo -e "${RED}FALHOU${NC}"
        ((FAIL_COUNT++))
    fi
}

# --- Execução do Teste ---
echo -e "${BLUE}=== INICIANDO TESTE DO SISTEMA DE LOG ===${NC}"
echo "Arquivo de log para o teste: $TEST_LOG_FILE"

# 1. Testar com a variável CLUSTER_AI_LOG_FILE definida
echo -e "\n${CYAN}--> Fase 1: Testando com log em arquivo ATIVADO${NC}"
export CLUSTER_AI_LOG_FILE="$TEST_LOG_FILE"

log "Mensagem de info para o arquivo."
warn "Mensagem de aviso para o arquivo."
error "Mensagem de erro para o arquivo."

# 2. Testar com a variável CLUSTER_AI_LOG_FILE indefinida
echo -e "\n${CYAN}--> Fase 2: Testando com log em arquivo DESATIVADO${NC}"
unset CLUSTER_AI_LOG_FILE

log "Esta mensagem de info NÃO deve ir para o arquivo."
warn "Este aviso NÃO deve ir para o arquivo."

# --- Validação ---
echo -e "\n${CYAN}--> Fase 3: Validando o conteúdo do arquivo de log${NC}"

if [ ! -f "$TEST_LOG_FILE" ]; then
    error "ARQUIVO DE LOG NÃO FOI CRIADO. Teste falhou catastroficamente."
    exit 1
fi

assert_log_contains "\[INFO\].*Mensagem de info para o arquivo\."
assert_log_contains "\[WARN\].*Mensagem de aviso para o arquivo\."
assert_log_contains "\[ERROR\].*Mensagem de erro para o arquivo\."
assert_log_not_contains "NÃO deve ir para o arquivo"

# --- Resumo e Limpeza ---
echo -e "\n${BLUE}=== RESULTADO DO TESTE ===${NC}"
if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "${GREEN}🎉 Todos os $TEST_COUNT testes passaram com sucesso!${NC}"
else
    echo -e "${RED}❌ $FAIL_COUNT de $TEST_COUNT testes falharam.${NC}"
fi

echo "Limpando arquivo de log de teste..."
rm -f "$TEST_LOG_FILE"
echo "Limpeza concluída."

# Retornar status de saída apropriado
if [ "$FAIL_COUNT" -gt 0 ]; then
    exit 1
else
    exit 0
fi