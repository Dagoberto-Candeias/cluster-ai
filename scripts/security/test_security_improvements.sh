#!/bin/bash
# =============================================================================
# Script para testar as implementações de segurança do Cluster AI
# =============================================================================
# Script para testar as implementações de segurança do Cluster AI
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: test_security_improvements.sh
# =============================================================================

set -uo pipefail

# =============================================================================
# CONFIGURAÇÃO
# =============================================================================
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# =============================================================================
# CORES E ESTILOS
# =============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# =============================================================================
# VARIÁVEIS GLOBAIS
# =============================================================================
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# =============================================================================
# FUNÇÕES DE LOG
# =============================================================================
log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
}

log_test() {
    local result="$1"
    local message="$2"
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}[PASS]${NC} $message"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}[FAIL]${NC} $message"
        ((TESTS_FAILED++))
    fi
    ((TOTAL_TESTS++))
}

# =============================================================================
# FUNÇÕES DE TESTE
# =============================================================================

test_file_permissions() {
    log_info "Testando permissões de arquivos..."

    # Testar se arquivos críticos têm permissões adequadas
    local critical_files=(
        "manager.sh"
        "scripts/lib/common.sh"
        "scripts/security/test_security_improvements.sh"
    )

    for file in "${critical_files[@]}"; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            local perms
            perms=$(stat -c "%a" "$PROJECT_ROOT/$file" 2>/dev/null)
            if [ $? -eq 0 ] && [ "$perms" -le 755 ]; then
                log_test "PASS" "Arquivo $file tem permissões seguras ($perms)"
            else
                log_test "FAIL" "Arquivo $file tem permissões inseguras ($perms)"
            fi
        else
            log_test "FAIL" "Arquivo crítico $file não encontrado"
        fi
    done
}

test_security_functions() {
    log_info "Testando funções de segurança..."

    # Testar se as funções de segurança estão disponíveis
    local test_functions=(
        "validate_input"
        "check_user_authorization"
        "confirm_critical_operation"
        "audit_log"
    )

    for func in "${test_functions[@]}"; do
        if command -v "$func" >/dev/null 2>&1; then
            log_test "PASS" "Função de segurança $func disponível"
        else
            log_test "FAIL" "Função de segurança $func não encontrada"
        fi
    done
}

test_directory_permissions() {
    log_info "Testando permissões de diretórios..."

    # Testar se diretórios têm permissões adequadas
    local critical_dirs=(
        "scripts"
        "logs"
        "config"
    )

    for dir in "${critical_dirs[@]}"; do
        if [ -d "$PROJECT_ROOT/$dir" ]; then
            local perms
            perms=$(stat -c "%a" "$PROJECT_ROOT/$dir" 2>/dev/null)
            if [ $? -eq 0 ] && [ "$perms" -le 755 ]; then
                log_test "PASS" "Diretório $dir tem permissões seguras ($perms)"
            else
                log_test "FAIL" "Diretório $dir tem permissões inseguras ($perms)"
            fi
        else
            log_test "INFO" "Diretório $dir não existe (será criado quando necessário)"
        fi
    done
}

test_ssh_configuration() {
    log_info "Testando configuração SSH..."

    # Verificar se SSH está configurado adequadamente
    if command -v sshd >/dev/null 2>&1; then
        if systemctl is-active --quiet sshd 2>/dev/null || systemctl is-active --quiet ssh 2>/dev/null; then
            log_test "PASS" "Serviço SSH está ativo"
        else
            log_test "INFO" "Serviço SSH não está ativo (pode ser intencional)"
        fi
    else
        log_test "INFO" "SSHD não está instalado"
    fi

    # Verificar se há chaves SSH
    if [ -f "$HOME/.ssh/id_rsa" ] || [ -f "$HOME/.ssh/id_ed25519" ]; then
        log_test "PASS" "Chaves SSH encontradas"
    else
        log_test "INFO" "Nenhuma chave SSH encontrada"
    fi
}

test_firewall_configuration() {
    log_info "Testando configuração de firewall..."

    # Verificar se firewall está ativo
    if command -v ufw >/dev/null 2>&1; then
        if ufw status 2>/dev/null | grep -q "Status: active" 2>/dev/null; then
            log_test "PASS" "UFW está ativo"
        else
            log_test "INFO" "UFW não está ativo"
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if firewall-cmd --state 2>/dev/null | grep -q "running" 2>/dev/null; then
            log_test "PASS" "Firewalld está ativo"
        else
            log_test "INFO" "Firewalld não está ativo"
        fi
    else
        log_test "INFO" "Nenhum firewall detectado"
    fi
}

test_user_permissions() {
    log_info "Testando permissões de usuário..."

    # Verificar se usuário atual tem privilégios necessários
    if [ "$EUID" -eq 0 ]; then
        log_test "INFO" "Executando como root (aceitável para instalação)"
    else
        log_test "PASS" "Executando como usuário não-root"
    fi

    # Verificar se usuário pode criar arquivos
    if touch "$PROJECT_ROOT/test_write_permission" 2>/dev/null; then
        rm -f "$PROJECT_ROOT/test_write_permission" 2>/dev/null
        log_test "PASS" "Permissões de escrita OK"
    else
        log_test "FAIL" "Sem permissões de escrita no diretório"
    fi
}

test_environment_variables() {
    log_info "Testando variáveis de ambiente..."

    # Verificar se variáveis críticas estão definidas
    if [ -n "${PATH:-}" ]; then
        log_test "PASS" "Variável PATH definida"
    else
        log_test "FAIL" "Variável PATH não definida"
    fi

    if [ -n "${HOME:-}" ]; then
        log_test "PASS" "Variável HOME definida"
    else
        log_test "FAIL" "Variável HOME não definida"
    fi
}

test_network_security() {
    log_info "Testando segurança de rede..."

    # Verificar se portas desnecessárias estão fechadas
    local dangerous_ports=(23 25 110 143)
    local open_ports=0

    # Check if ss or netstat is available
    if command -v ss >/dev/null 2>&1; then
        for port in "${dangerous_ports[@]}"; do
            if ss -ln 2>/dev/null | grep -q ":$port "; then
                log_test "INFO" "Porta $port está aberta (verificar se é necessário)"
                ((open_ports++))
            fi
        done
    elif command -v netstat >/dev/null 2>&1; then
        for port in "${dangerous_ports[@]}"; do
            if netstat -ln 2>/dev/null | grep -q ":$port "; then
                log_test "INFO" "Porta $port está aberta (verificar se é necessário)"
                ((open_ports++))
            fi
        done
    else
        log_test "INFO" "Nenhuma ferramenta de monitoramento de rede disponível"
    fi

    if [ $open_ports -eq 0 ]; then
        log_test "PASS" "Nenhuma porta perigosa desnecessária aberta"
    fi
}

test_software_updates() {
    log_info "Testando atualizações de software..."

    # Verificar se sistema está atualizado (simplificado)
    if command -v apt-get >/dev/null 2>&1; then
        if apt-get check >/dev/null 2>&1; then
            log_test "PASS" "Sistema apt está consistente"
        else
            log_test "INFO" "Sistema apt pode precisar de reparos"
        fi
    elif command -v yum >/dev/null 2>&1; then
        log_test "PASS" "Sistema yum detectado"
    else
        log_test "INFO" "Gerenciador de pacotes não detectado"
    fi
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================
main() {
    log_info "Iniciando testes de segurança do Cluster AI"
    echo "=================================================="
    echo "         Testes de Segurança - Cluster AI        "
    echo "=================================================="

    # Executar todos os testes
    test_file_permissions
    test_directory_permissions
    test_security_functions
    test_ssh_configuration
    test_firewall_configuration
    test_user_permissions
    test_environment_variables
    test_network_security
    test_software_updates

    # Resultado final
    echo
    echo "=================================================="
    echo "                 RESULTADO FINAL                  "
    echo "=================================================="
    echo "Total de testes: $TOTAL_TESTS"
    echo -e "✅ Testes aprovados: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "❌ Testes reprovados: ${RED}$TESTS_FAILED${NC}"

    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "Todos os testes de segurança foram aprovados!"
        echo "🎉 Sistema considerado SEGURO"
        return 0
    else
        log_error "$TESTS_FAILED teste(s) de segurança falharam"
        echo "⚠️  Sistema precisa de atenção"
        return 1
    fi
}

# =============================================================================
# EXECUÇÃO
# =============================================================================
main "$@"
