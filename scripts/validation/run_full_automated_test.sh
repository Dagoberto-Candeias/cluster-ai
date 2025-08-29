#!/bin/bash
# Script de teste automatizado completo do Cluster AI
# Executa todos os testes e instalações automaticamente sem interação humana
# Com tratamento robusto de erros e retry automático

# Cores para output
COMMON_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO: Script de funções comuns não encontrado em $COMMON_SCRIPT_PATH"
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# Configuração
TEST_DIR="/tmp/cluster_ai_full_test"
LOG_FILE="$TEST_DIR/full_test_results_$(date +%Y%m%d_%H%M%S).log"
MAX_RETRIES=3
RETRY_DELAY=5
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

# Função para verificar se timeout está disponível
check_timeout() {
    if command_exists timeout; then
        return 0
    else
        warn "Comando 'timeout' não disponível. Instalando..."
        if run_with_sudo_if_needed "apt-get install -y timeout" "Instalar timeout"; then
            log "Timeout instalado com sucesso"
            return 0
        else
            error "Falha ao instalar timeout"
            return 1
        fi
    fi
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

# Função para executar comando com retry automático
run_with_retry() {
    local cmd="$1"
    local description="$2"
    local max_retries=${3:-$MAX_RETRIES}
    local retry_delay=${4:-$RETRY_DELAY}
    local retry_count=0
    
    while [ $retry_count -lt $max_retries ]; do
        log "Tentativa $((retry_count + 1))/$max_retries: $description"
        
        if eval "$cmd"; then
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            warn "Falha na tentativa $retry_count. Tentando novamente em $retry_delay segundos..."
            sleep $retry_delay
        fi
    done
    
    error "Falha após $max_retries tentativas: $description"
    return 1
}

# Função para limpar ambiente completamente
clean_environment_completely() {
    log "Limpando ambiente completamente..."
    
    # Remover todos os arquivos e diretórios do cluster
    local files_to_remove=(
        "$HOME/.cluster_role"
        "$HOME/cluster_scripts"
        "$HOME/.ollama"
        "$HOME/.cluster_optimization"
        "$HOME/cluster_swap"
    )
    
    for item in "${files_to_remove[@]}"; do
        if [ -e "$item" ]; then
            if [ -d "$item" ] && [ "$item" = "$HOME/cluster_swap" ]; then
                # Desativar swap se estiver ativo
                if grep -q "$HOME/cluster_swap/swapfile" /proc/swaps; then
                    run_with_sudo_if_needed "swapoff $HOME/cluster_swap/swapfile" "Desativar swapfile"
                fi
            fi
            run_with_sudo_if_needed "rm -rf $item" "Remover $item"
        fi
    done
    
    # Parar e remover containers Docker
    if command_exists docker; then
        log "Limpando containers Docker..."
        run_with_retry "docker ps -aq | xargs -r docker stop" "Parar containers"
        run_with_retry "docker ps -aq | xargs -r docker rm" "Remover containers"
        run_with_retry "docker network prune -f" "Limpar redes"
        run_with_retry "docker volume prune -f" "Limpar volumes"
    fi
    
    log "Ambiente limpo completamente."
}

# Função para instalar dependências automaticamente
install_dependencies() {
    log "Instalando dependências automaticamente..."
    
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
        log "Instalando dependências faltantes: ${missing_deps[*]}"
        
        # Atualizar repositórios
        run_with_retry "apt-get update -y" "Atualizar repositórios"
        
        # Instalar dependências
        for dep in "${missing_deps[@]}"; do
            case $dep in
                "docker")
                    run_with_retry "apt-get install -y docker.io docker-compose" "Instalar Docker"
                    ;;
                "python3")
                    run_with_retry "apt-get install -y python3 python3-pip" "Instalar Python3"
                    ;;
                "curl")
                    run_with_retry "apt-get install -y curl" "Instalar cURL"
                    ;;
            esac
        done
        
        log "Instalação de dependências concluída"
    else
        log "Todas as dependências já estão instaladas"
    fi
}

# Função para executar teste completo com timeout
run_complete_test() {
    log "Executando teste completo do cluster..."
    
    # Verificar se timeout está disponível
    if ! check_timeout; then
        error "O comando 'timeout' não está disponível. Abortando teste."
        return 1
    fi
    
    # Executar com timeout para evitar travamentos
    if timeout 300s ./scripts/validation/run_complete_test_modified.sh; then
        record_result "Teste Completo" "SUCCESS" "Teste executado com sucesso"
        return 0
    else
        local exit_code=$?
        if [ $exit_code -eq 124 ]; then
            record_result "Teste Completo" "FAIL" "Teste timeout (5 minutos excedidos)"
        else
            record_result "Teste Completo" "FAIL" "Falha no teste completo (código: $exit_code)"
        fi
        return 1
    fi
}

# Função principal de execução
main() {
    echo -e "${BLUE}=== INICIANDO TESTE AUTOMATIZADO COMPLETO CLUSTER AI ===${NC}"
    echo "Log detalhado: $LOG_FILE"
    echo ""
    
    # Registrar informações do usuário
    log_user_info
    
    # Limpar ambiente completamente antes de começar
    clean_environment_completely
    
    # Instalar dependências se necessário
    install_dependencies
    
    # Executar teste completo
    if run_complete_test; then
        success "✅ TESTE COMPLETO CONCLUÍDO COM SUCESSO!"
        echo ""
        echo -e "${GREEN}🎉 Todos os testes passaram! O ambiente está pronto para uso.${NC}"
        echo ""
        echo -e "${BLUE}📁 Log completo:${NC} $LOG_FILE"
        echo -e "${BLUE}📁 Informações do usuário:${NC} /tmp/cluster_ai_user_info.log"
        exit 0
    else
        error "❌ TESTE FALHOU!"
        echo ""
        echo -e "${RED}Alguns testes falharam. Verifique o log para detalhes.${NC}"
        echo -e "${BLUE}📁 Log completo:${NC} $LOG_FILE"
        echo -e "${YELLOW}🔧 Tentando correção automática...${NC}"
        
        # Tentar correção automática
        clean_environment_completely
        install_dependencies
        
        # Tentar executar novamente
        if run_complete_test; then
            success "✅ CORREÇÃO AUTOMÁTICA BEM-SUCEDIDA!"
            exit 0
        else
            fail "❌ CORREÇÃO AUTOMÁTICA FALHOU!"
            exit 1
        fi
    fi
}

# Tratamento de erros global
set -eE
trap 'error "Erro fatal na linha $LINENO. Executando limpeza..."; clean_environment_completely; exit 1' ERR

# Executar função principal
main
