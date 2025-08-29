#!/bin/bash
# Script de teste completo do Cluster AI
# Executa validação de todas as funcionalidades principais

# Cores para output
COMMON_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO: Script de funções comuns não encontrado em $COMMON_SCRIPT_PATH"
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# Configuração
TEST_DIR="/tmp/cluster_ai_test"
LOG_FILE="$TEST_DIR/test_results_$(date +%Y%m%d_%H%M%S).log"
OVERALL_SUCCESS=true

# Criar diretório de teste
mkdir -p "$TEST_DIR"

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
        OVERALL_SUCCESS=false
    fi
}

# Função para testar porta
test_port() {
    local port="$1"
    if timeout 2 bash -c "echo > /dev/tcp/localhost/$port" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Função para testar HTTP
test_http() {
    local url="$1"
    if curl -s --head "$url" >/dev/null; then
        return 0
    else
        return 1
    fi
}

# Início dos testes
echo -e "${BLUE}=== INICIANDO TESTE COMPLETO CLUSTER AI ===${NC}"
echo "Log detalhado: $LOG_FILE"
echo ""

# Teste 1: Dependências básicas
echo -e "${YELLOW}1. TESTANDO DEPENDÊNCIAS BÁSICAS${NC}"
if command_exists docker; then
    record_result "Docker" "SUCCESS" "Docker instalado"
else
    record_result "Docker" "FAIL" "Docker não instalado"
fi

if command_exists python3; then
    record_result "Python3" "SUCCESS" "Python3 instalado"
else
    record_result "Python3" "FAIL" "Python3 não instalado"
fi

if command_exists curl; then
    record_result "cURL" "SUCCESS" "cURL instalado"
else
    record_result "cURL" "FAIL" "cURL não instalado"
fi

# Teste 2: Scripts do projeto
echo -e "${YELLOW}2. TESTANDO SCRIPTS DO PROJETO${NC}"
if [ -f "install_cluster.sh" ]; then
    chmod +x install_cluster.sh
    record_result "install_cluster.sh" "SUCCESS" "Script encontrado e executável"
else
    record_result "install_cluster.sh" "FAIL" "Script não encontrado"
fi

if [ -f "scripts/validation/validate_installation.sh" ]; then
    chmod +x scripts/validation/validate_installation.sh
    record_result "validate_installation.sh" "SUCCESS" "Script de validação encontrado"
else
    record_result "validate_installation.sh" "FAIL" "Script de validação não encontrado"
fi

if [ -f "scripts/utils/check_models.sh" ]; then
    chmod +x scripts/utils/check_models.sh
    record_result "check_models.sh" "SUCCESS" "Script de modelos encontrado"
else
    record_result "check_models.sh" "FAIL" "Script de modelos não encontrado"
fi

# Teste 3: Documentação
echo -e "${YELLOW}3. TESTANDO DOCUMENTAÇÃO${NC}"
docs=(
    "docs/README_PRINCIPAL.md"
    "docs/manuals/INSTALACAO.md"
    "docs/manuals/OLLAMA.md"
    "docs/manuals/OPENWEBUI.md"
    "docs/manuals/BACKUP.md"
    "docs/guides/TROUBLESHOOTING.md"
    "docs/guides/QUICK_START.md"
)

for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        record_result "Documentação $doc" "SUCCESS" "Arquivo encontrado"
    else
        record_result "Documentação $doc" "FAIL" "Arquivo não encontrado"
    fi
done

# Teste 4: Estrutura de diretórios
echo -e "${YELLOW}4. TESTANDO ESTRUTURA DE DIRETÓRIOS${NC}"
dirs=(
    "scripts/installation"
    "scripts/deployment"
    "scripts/development"
    "scripts/maintenance"
    "scripts/backup"
    "scripts/utils"
    "scripts/validation"
    "configs/docker"
    "configs/nginx"
    "configs/tls"
    "examples/basic"
    "examples/advanced"
    "examples/integration"
    "docs/manuals"
    "docs/guides"
)

for dir in "${dirs[@]}"; do
    if [ -d "$dir" ]; then
        record_result "Diretório $dir" "SUCCESS" "Diretório encontrado"
    else
        record_result "Diretório $dir" "FAIL" "Diretório não encontrado"
    fi
done

# Teste 5: Execução de scripts (se dependências instaladas)
if command_exists docker && command_exists python3; then
    echo -e "${YELLOW}5. TESTANDO EXECUÇÃO DE SCRIPTS${NC}"
    
    # Testar script de validação
    if ./scripts/validation/validate_installation.sh > "$TEST_DIR/validation_output.txt" 2>&1; then
        record_result "Execução validate_installation" "SUCCESS" "Script executado com sucesso"
    else
        record_result "Execução validate_installation" "PARTIAL" "Script executado mas com erros (esperado em ambiente limpo)"
    fi
    
    # Testar script de modelos
    if ./scripts/utils/check_models.sh > "$TEST_DIR/models_output.txt" 2>&1; then
        record_result "Execução check_models" "SUCCESS" "Script executado com sucesso"
    else
        record_result "Execução check_models" "PARTIAL" "Script executado mas com erros (esperado sem Ollama)"
    fi
    
    # Verificar se scripts mostram ajuda
    if ./install_cluster.sh --help > "$TEST_DIR/help_output.txt" 2>&1; then
        if grep -q "AJUDA" "$TEST_DIR/help_output.txt"; then
            record_result "Sistema de ajuda" "SUCCESS" "Help funcionando corretamente"
        else
            record_result "Sistema de ajuda" "FAIL" "Help não funcionando"
        fi
    fi
fi

# Teste 6: Exemplos de código
echo -e "${YELLOW}6. TESTANDO EXEMPLOS DE CÓDIGO${NC}"
if [ -f "examples/integration/ollama_integration.py" ]; then
    record_result "Exemplo integração" "SUCCESS" "Exemplo de integração encontrado"
    # Validar sintaxe Python
    if python3 -m py_compile examples/integration/ollama_integration.py; then
        record_result "Sintaxe exemplo integração" "SUCCESS" "Sintaxe Python válida"
    else
        record_result "Sintaxe exemplo integração" "FAIL" "Erro de sintaxe Python"
    fi
fi

if [ -f "examples/basic/basic_usage.py" ]; then
    record_result "Exemplo básico" "SUCCESS" "Exemplo básico encontrado"
    if python3 -m py_compile examples/basic/basic_usage.py; then
        record_result "Sintaxe exemplo básico" "SUCCESS" "Sintaxe Python válida"
    else
        record_result "Sintaxe exemplo básico" "FAIL" "Erro de sintaxe Python"
    fi
fi

# Teste 7: Configurações
echo -e "${YELLOW}7. TESTANDO ARQUIVOS DE CONFIGURAÇÃO${NC}"
configs=(
    "configs/docker/compose-basic.yml"
    "configs/docker/compose-tls.yml"
    "configs/nginx/nginx-tls.conf"
    "configs/tls/issue-certs-robust.sh"
    "configs/tls/issue-certs-simple.sh"
)

for config in "${configs[@]}"; do
    if [ -f "$config" ]; then
        record_result "Configuração $config" "SUCCESS" "Arquivo de configuração encontrado"
    else
        record_result "Configuração $config" "FAIL" "Arquivo de configuração não encontrado"
    fi
done

# Teste 8: Backups
echo -e "${YELLOW}8. TESTANDO SISTEMA DE BACKUP${NC}"
if [ -d "backups/templates" ]; then
    record_result "Templates backup" "SUCCESS" "Templates de backup encontrados"
else
    record_result "Templates backup" "FAIL" "Templates de backup não encontrados"
fi

if [ -f "scripts/backup/"* ]; then
    record_result "Scripts backup" "SUCCESS" "Scripts de backup encontrados"
else
    record_result "Scripts backup" "FAIL" "Scripts de backup não encontrados"
fi

# Resumo final
echo -e "${BLUE}=== RESUMO FINAL DOS TESTES ===${NC}"
echo ""

# Mostrar resultados do log
echo "📊 Resultados detalhados:"
grep "FAIL\|SUCCESS\|PARTIAL" "$LOG_FILE" | tail -20

echo ""
echo -e "${BLUE}📋 ESTATÍSTICAS:${NC}"
total_tests=$(grep -c "SUCCESS\|FAIL\|PARTIAL" "$LOG_FILE")
success_tests=$(grep -c "SUCCESS" "$LOG_FILE")
fail_tests=$(grep -c "FAIL" "$LOG_FILE")
partial_tests=$(grep -c "PARTIAL" "$LOG_FILE")

echo "Total de testes: $total_tests"
echo -e "${GREEN}Sucessos: $success_tests${NC}"
echo -e "${YELLOW}Parciais: $partial_tests${NC}"
echo -e "${RED}Falhas: $fail_tests${NC}"

echo ""
if [ "$OVERALL_SUCCESS" = true ] && [ "$fail_tests" -eq 0 ]; then
    echo -e "${GREEN}🎉 TODOS OS TESTES PASSARAM! O projeto está pronto para uso.${NC}"
    echo ""
    echo -e "${BLUE}🚀 PRÓXIMOS PASSOS:${NC}"
    echo "1. Executar instalação completa: ./install_cluster.sh"
    echo "2. Configurar papel da máquina no menu interativo"
    echo "3. Instalar modelos: ./scripts/utils/check_models.sh"
    echo "4. Validar instalação: ./scripts/validation/validate_installation.sh"
else
    echo -e "${YELLOW}⚠️  ALGUNS TESTES FALHARAM OU ESTÃO PARCIAIS${NC}"
    echo ""
    echo -e "${BLUE}🔧 AÇÕES RECOMENDADAS:${NC}"
    echo "1. Verificar dependências do sistema"
    echo "2. Executar instalação para corrigir issues"
    echo "3. Consultar troubleshooting: docs/guides/TROUBLESHOOTING.md"
    echo "4. Verificar log completo: $LOG_FILE"
fi

echo ""
echo -e "${BLUE}📁 LOG COMPLETO:${NC} $LOG_FILE"
echo -e "${BLUE}📅 DATA DO TESTE:${NC} $(date)"

# Status de saída
if [ "$OVERALL_SUCCESS" = true ] && [ "$fail_tests" -eq 0 ]; then
    exit 0
else
    exit 1
fi
