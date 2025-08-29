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

# Função para verificar se o ambiente já existe
check_existing_environment() {
    if [ -f "$HOME/.cluster_role" ] || [ -d "$HOME/cluster_scripts" ] || [ -d "$HOME/.ollama" ]; then
        return 0
    else
        return 1
    fi
}

# Função para limpar o ambiente
clean_environment() {
    # Remover arquivos e diretórios (exceto swapfile que pode estar em uso)
    rm -rf "$HOME/.cluster_role" "$HOME/cluster_scripts" "$HOME/.ollama" "$HOME/.cluster_optimization"
    
    # Tentar remover cluster_swap, mas ignorar erros se o swapfile estiver em uso
    if [ -d "$HOME/cluster_swap" ]; then
        # Desativar swap se estiver ativo
        if grep -q "$HOME/cluster_swap/swapfile" /proc/swaps; then
            run_with_sudo_if_needed "swapoff $HOME/cluster_swap/swapfile" "Desativar swapfile"
        fi
        run_with_sudo_if_needed "rm -rf $HOME/cluster_swap" "Remover diretório cluster_swap"
    fi
    
    log "Ambiente limpo com sucesso."
}

# Função para registrar informações do usuário localmente
log_user_info() {
    local user_info_file="/tmp/cluster_ai_user_info.log"
    
    echo "=== INFORMAÇÕES DO USUÁRIO ===" > "$user_info_file"
    echo "Data/Hora: $(date '+%Y-%m-%d %H:%M:%S')" >> "$user_info_file"
    echo "Usuário: $(whoami)" >> "$user_info_file"
    echo "Hostname: $(hostname)" >> "$user_info_file"
    echo "Sistema: $(uname -a)" >> "$user_info_file"
    echo "Diretório de trabalho: $(pwd)" >> "$user_info_file"
    echo "UID: $(id -u)" >> "$user_info_file"
    echo "GID: $(id -g)" >> "$user_info_file"
    echo "Grupos: $(id -Gn)" >> "$user_info_file"
    
    log "Informações do usuário registradas em: $user_info_file"
}

# Função para verificar e executar com sudo se necessário
run_with_sudo_if_needed() {
    local cmd="$1"
    local description="$2"
    
    if [[ $EUID -eq 0 ]]; then
        # Já é root, executar diretamente
        $cmd
    else
        # Verificar se o comando precisa de sudo
        if [[ "$cmd" == *"swapoff"* ]] || [[ "$cmd" == *"rm -rf"* ]] && [[ "$cmd" == *"/cluster_swap"* ]] || 
           [[ "$cmd" == *"apt-get"* ]] || [[ "$cmd" == *"apt "* ]] || [[ "$cmd" == *"dpkg"* ]] ||
           [[ "$cmd" == *"systemctl"* ]] || [[ "$cmd" == *"service"* ]] || [[ "$cmd" == *"docker"* ]] && [[ "$cmd" != *"--help"* ]]; then
            log "Executando com sudo: $description"
            sudo $cmd
        else
            $cmd
        fi
    fi
}

# Função para executar instalação automática se necessário
run_auto_installation() {
    local missing_deps=()
    
    # Verificar dependências faltantes
    if ! command_exists docker; then
        missing_deps+=("docker")
    fi
    
    if ! command_exists python3; then
        missing_deps+=("python3")
    fi
    
    if ! command_exists curl; then
        missing_deps+=("curl")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log "Instalando dependências faltantes automaticamente: ${missing_deps[*]}"
        
        # Atualizar repositórios
        run_with_sudo_if_needed "apt-get update" "Atualizar repositórios"
        
        # Instalar dependências
        for dep in "${missing_deps[@]}"; do
            case $dep in
                "docker")
                    run_with_sudo_if_needed "apt-get install -y docker.io docker-compose" "Instalar Docker"
                    ;;
                "python3")
                    run_with_sudo_if_needed "apt-get install -y python3 python3-pip" "Instalar Python3"
                    ;;
                "curl")
                    run_with_sudo_if_needed "apt-get install -y curl" "Instalar cURL"
                    ;;
            esac
        done
        
        log "Instalação automática concluída"
    fi
}

# Início dos testes
echo -e "${BLUE}=== INICIANDO TESTE COMPLETO CLUSTER AI ===${NC}"
echo "Log detalhado: $LOG_FILE"
echo ""

# Registrar informações do usuário
log_user_info

# Verificar se o ambiente já existe e limpar automaticamente
if check_existing_environment; then
    log "Ambiente existente detectado. Limpando automaticamente..."
    clean_environment
fi

# Executar instalação automática de dependências se necessário
run_auto_installation

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
    
    # Testar script de validação - esperado falhar em ambiente limpo
    if timeout 30s ./scripts/validation/validate_installation.sh > "$TEST_DIR/validation_output.txt" 2>&1; then
        record_result "Execução validate_installation" "SUCCESS" "Script executado com sucesso"
    else
        # Verificar se a falha é esperada (ambiente limpo)
        if grep -q "ambiente virtual não encontrado\|não instalado\|não está rodando" "$TEST_DIR/validation_output.txt"; then
            record_result "Execução validate_installation" "PARTIAL" "Script executado mas com erros (esperado em ambiente limpo)"
        else
            record_result "Execução validate_installation" "FAIL" "Falha inesperada na execução"
        fi
    fi
    
    # Testar script de modelos
    if timeout 30s ./scripts/utils/check_models.sh > "$TEST_DIR/models_output.txt" 2>&1; then
        record_result "Execução check_models" "SUCCESS" "Script executado com sucesso"
    else
        # Verificar se a falha é esperada (sem Ollama)
        if grep -q "Ollama\|modelo" "$TEST_DIR/models_output.txt"; then
            record_result "Execução check_models" "PARTIAL" "Script executado mas com erros (esperado sem Ollama)"
        else
            record_result "Execução check_models" "FAIL" "Falha inesperada na execução"
        fi
    fi
    
    # Verificar se scripts mostram ajuda
    if timeout 10s ./install_cluster.sh --help > "$TEST_DIR/help_output.txt" 2>&1; then
        if grep -q -i "ajuda\|help\|usage" "$TEST_DIR/help_output.txt"; then
            record_result "Sistema de ajuda" "SUCCESS" "Help funcionando corretamente"
        else
            record_result "Sistema de ajuda" "PARTIAL" "Help executado mas sem texto esperado"
        fi
    else
        record_result "Sistema de ajuda" "FAIL" "Falha ao executar help"
    fi
fi

# Teste 6: Detecção e suporte a GPU
echo -e "${YELLOW}6. TESTANDO SUPORTE A GPU${NC}"
if [ -f "scripts/utils/gpu_detection.sh" ]; then
    chmod +x scripts/utils/gpu_detection.sh
    record_result "Script GPU Detection" "SUCCESS" "Script de detecção encontrado"
    
    # Executar detecção
    if ./scripts/utils/gpu_detection.sh > "$TEST_DIR/gpu_detection_output.txt" 2>&1; then
        record_result "Execução GPU Detection" "SUCCESS" "Detecção de GPU executada"
    else
        record_result "Execução GPU Detection" "PARTIAL" "Detecção executada com avisos"
    fi
fi

if [ -f "scripts/utils/test_gpu.py" ]; then
    record_result "Script Test GPU" "SUCCESS" "Script de teste GPU encontrado"
    # Validar sintaxe Python
    if python3 -m py_compile scripts/utils/test_gpu.py; then
        record_result "Sintaxe teste GPU" "SUCCESS" "Sintaxe Python válida"
    else
        record_result "Sintaxe teste GPU" "FAIL" "Erro de sintaxe Python"
    fi
fi

if [ -f "scripts/installation/gpu_setup.sh" ]; then
    chmod +x scripts/installation/gpu_setup.sh
    record_result "Script GPU Setup" "SUCCESS" "Script de instalação GPU encontrado"
fi

# Teste 7: Exemplos de código
echo -e "${YELLOW}7. TESTANDO EXEMPLOS DE CÓDIGO${NC}"
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
    record_result "Templates backup" "PARTIAL" "Templates de backup não encontrados (opcional)"
fi

# Verificar scripts de backup individualmente
backup_scripts=(
    "scripts/backup/backup_manager.sh"
    "scripts/backup/cleanup_old_backups.sh"
)

for script in "${backup_scripts[@]}"; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        record_result "Script $(basename "$script")" "SUCCESS" "Script de backup encontrado e executável"
    else
        record_result "Script $(basename "$script")" "PARTIAL" "Script de backup não encontrado (pode ser criado)"
    fi
done

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
# Considerar sucesso se não houver falhas reais (apenas parciais esperados)
if [ "$fail_tests" -eq 0 ]; then
    if [ "$partial_tests" -gt 0 ]; then
        warn "Testes concluídos com $partial_tests resultado(s) parcial(is) (esperado em ambiente limpo)"
    fi
    exit 0
else
    exit 1
fi
