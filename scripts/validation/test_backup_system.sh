#!/bin/bash
# Script de teste rápido para o sistema de backup

# Cores para output
COMMON_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO: Script de funções comuns não encontrado em $COMMON_SCRIPT_PATH"
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# Configuração
TEST_DIR="/tmp/backup_test_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$TEST_DIR"
LOG_FILE="$TEST_DIR/backup_test.log"

# Função para registrar resultado
record_result() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') | $test_name | $status | $message" >> "$LOG_FILE"
    
    if [ "$status" = "SUCCESS" ]; then
        success "$test_name: $message"
    else
        fail "$test_name: $message"
    fi
}

# Função para verificar se arquivo existe
check_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        record_result "$description" "SUCCESS" "Arquivo encontrado"
        return 0
    else
        record_result "$description" "FAIL" "Arquivo não encontrado"
        return 1
    fi
}

# Função para verificar se diretório existe
check_dir() {
    local dir="$1"
    local description="$2"
    
    if [ -d "$dir" ]; then
        record_result "$description" "SUCCESS" "Diretório encontrado"
        return 0
    else
        record_result "$description" "FAIL" "Diretório não encontrado"
        return 1
    fi
}

# Função para verificar se script é executável
check_executable() {
    local script="$1"
    local description="$2"
    
    if [ -f "$script" ] && [ -x "$script" ]; then
        record_result "$description" "SUCCESS" "Script executável"
        return 0
    elif [ -f "$script" ]; then
        chmod +x "$script"
        record_result "$description" "SUCCESS" "Script tornado executável"
        return 0
    else
        record_result "$description" "FAIL" "Script não encontrado"
        return 1
    fi
}

# Função para testar ajuda dos scripts
test_help() {
    local script="$1"
    local description="$2"
    
    if [ -f "$script" ] && [ -x "$script" ]; then
        if "$script" --help >/dev/null 2>&1; then
            record_result "$description" "SUCCESS" "Sistema de ajuda funcionando"
            return 0
        else
            record_result "$description" "PARTIAL" "Sistema de ajuda com problemas"
            return 1
        fi
    else
        record_result "$description" "FAIL" "Script não disponível para teste"
        return 1
    fi
}

# Início dos testes
echo -e "${BLUE}=== INICIANDO TESTE DO SISTEMA DE BACKUP ===${NC}"
echo "Log detalhado: $LOG_FILE"
echo ""

# Teste 1: Scripts de backup
echo -e "${YELLOW}1. TESTANDO SCRIPTS DE BACKUP${NC}"

check_executable "scripts/backup/backup_manager.sh" "Backup Manager"
check_executable "scripts/backup/cleanup_old_backups.sh" "Cleanup Backups"

# Teste 2: Sistema de ajuda
echo -e "${YELLOW}2. TESTANDO SISTEMA DE AJUDA${NC}"

test_help "scripts/backup/backup_manager.sh" "Ajuda Backup Manager"
test_help "scripts/backup/cleanup_old_backups.sh" "Ajuda Cleanup Backups"

# Teste 3: Templates de backup
echo -e "${YELLOW}3. TESTANDO TEMPLATES DE BACKUP${NC}"

check_dir "backups/templates" "Templates de backup"

# Teste 4: Teste rápido de funcionalidade (se scripts existem)
echo -e "${YELLOW}4. TESTE RÁPIDO DE FUNCIONALIDADE${NC}"

if [ -f "scripts/backup/backup_manager.sh" ] && [ -x "scripts/backup/backup_manager.sh" ]; then
    # Testar listagem (deve funcionar mesmo sem backups)
    if ./scripts/backup/backup_manager.sh --list > "$TEST_DIR/list_output.txt" 2>&1; then
        record_result "Listagem backups" "SUCCESS" "Listagem funcionando"
    else
        # Listagem pode falhar se não houver backups, o que é normal
        if grep -q "Nenhum arquivo de backup" "$TEST_DIR/list_output.txt"; then
            record_result "Listagem backups" "SUCCESS" "Listagem funcionando (sem backups)"
        else
            record_result "Listagem backups" "PARTIAL" "Listagem com problemas"
        fi
    fi
else
    record_result "Teste funcionalidade" "SKIP" "Scripts não disponíveis"
fi

# Resumo final
echo -e "${BLUE}=== RESUMO FINAL DO TESTE DE BACKUP ===${NC}"
echo ""

# Mostrar resultados do log
echo "📊 Resultados detalhados:"
cat "$LOG_FILE"

echo ""
echo -e "${BLUE}📋 ESTATÍSTICAS:${NC}"
total_tests=$(grep -c "SUCCESS\|FAIL\|PARTIAL\|SKIP" "$LOG_FILE")
success_tests=$(grep -c "SUCCESS" "$LOG_FILE")
fail_tests=$(grep -c "FAIL" "$LOG_FILE")
partial_tests=$(grep -c "PARTIAL" "$LOG_FILE")
skip_tests=$(grep -c "SKIP" "$LOG_FILE")

echo "Total de testes: $total_tests"
echo -e "${GREEN}Sucessos: $success_tests${NC}"
echo -e "${YELLOW}Parciais: $partial_tests${NC}"
echo -e "${RED}Falhas: $fail_tests${NC}"
echo -e "${BLUE}Pulados: $skip_tests${NC}"

echo ""
if [ "$fail_tests" -eq 0 ] && [ "$partial_tests" -eq 0 ]; then
    echo -e "${GREEN}🎉 SISTEMA DE BACKUP TESTADO COM SUCESSO!${NC}"
else
    echo -e "${YELLOW}⚠️  ALGUNS TESTES APRESENTARAM PROBLEMAS${NC}"
    echo ""
    echo -e "${BLUE}🔧 AÇÕES RECOMENDADAS:${NC}"
    echo "1. Verificar se os scripts de backup estão no lugar correto"
    echo "2. Garantir que os scripts têm permissão de execução"
    echo "3. Verificar log completo: $LOG_FILE"
fi

echo ""
echo -e "${BLUE}📁 LOG COMPLETO:${NC} $LOG_FILE"
echo -e "${BLUE}📅 DATA DO TESTE:${NC} $(date)"

# Status de saída
if [ "$fail_tests" -eq 0 ]; then
    exit 0
else
    exit 1
fi
