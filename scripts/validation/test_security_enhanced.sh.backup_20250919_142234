#!/bin/bash
# Script de Teste Avançado para Validação de Segurança

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
COMMON_SCRIPT="${PROJECT_ROOT}/scripts/lib/common.sh"

if [ ! -f "$COMMON_SCRIPT" ]; then
    echo "ERRO: Script de funções comuns não encontrado: $COMMON_SCRIPT"
    exit 1
fi

source "$COMMON_SCRIPT"

# Configurações de teste
TEST_LOG_FILE="${LOG_DIR}/security_test_$(date +%Y%m%d_%H%M%S).log"
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Função para executar teste de segurança
run_security_test() {
    local test_name="$1"
    local path_to_test="$2"
    local expected_result="$3"  # 0 = permitido, 1 = bloqueado
    local operation="${4:-teste}"
    
    ((TEST_COUNT++))
    echo -n "  [TEST $TEST_COUNT] $test_name... "
    
    # Executar safe_path_check
    if safe_path_check "$path_to_test" "$operation"; then
        local actual_result=0
    else
        local actual_result=1
    fi
    
    # Verificar resultado
    if [ "$actual_result" -eq "$expected_result" ]; then
        echo -e "${GREEN}PASSOU${NC}"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}FALHOU${NC}"
        echo "    Esperado: $expected_result, Obtido: $actual_result"
        ((FAIL_COUNT++))
        return 1
    fi
}

# Função principal de teste
main() {
    section "TESTE AVANÇADO DE SEGURANÇA - safe_path_check"
    echo "Arquivo de log: $TEST_LOG_FILE"
    echo ""
    
    # Testes que devem PASSAR (caminhos seguros)
    subsection "Testes de Caminhos Seguros (deve permitir)"
    run_security_test "Diretório do projeto" "$PROJECT_ROOT" 0
    run_security_test "Subdiretório do projeto" "$PROJECT_ROOT/logs" 0
    run_security_test "Home do usuário" "/home/$USER" 0
    run_security_test "Subdiretório home" "/home/$USER/teste" 0
    run_security_test "Diretório temporário" "/tmp/teste_seguro" 0
    run_security_test "Var tmp" "/var/tmp/teste" 0
    run_security_test "Logs do sistema" "/var/log/syslog" 0
    
    # Testes que devem FALHAR (caminhos perigosos)
    subsection "Testes de Caminhos Perigosos (deve bloquear)"
    run_security_test "Diretório raiz" "/" 1
    run_security_test "Binários do sistema" "/bin/bash" 1
    run_security_test "SBIN do sistema" "/sbin/init" 1
    run_security_test "Configurações do sistema" "/etc/passwd" 1
    run_security_test "Lib do sistema" "/lib/libc.so.6" 1
    run_security_test "Boot do sistema" "/boot/vmlinuz" 1
    run_security_test "Root do sistema" "/root" 1
    run_security_test "Proc do sistema" "/proc/1" 1
    run_security_test "Sys do sistema" "/sys/kernel" 1
    run_security_test "Dev do sistema" "/dev/sda" 1
    run_security_test "Outro usuário" "/home/outrousuario" 1
    run_security_test "Caminho relativo perigoso" "../../etc/passwd" 1
    run_security_test "Caminho vazio" "" 1
    
    # Testes de diretórios críticos específicos
    subsection "Testes de Diretórios Críticos Específicos"
    run_security_test "USR bin" "/usr/bin/ls" 1
    run_security_test "USR sbin" "/usr/sbin/sshd" 1
    run_security_test "USR local bin" "/usr/local/bin" 1
    run_security_test "ETC network" "/etc/network/interfaces" 1
    run_security_test "ETC systemd" "/etc/systemd/system" 1
    run_security_test "Lib64" "/lib64/ld-linux-x86-64.so.2" 1
    run_security_test "Var lib" "/var/lib/dpkg" 1
    run_security_test "Var cache" "/var/cache/apt" 1
    run_security_test "Media" "/media" 1
    run_security_test "Mnt" "/mnt" 1
    run_security_test "Opt" "/opt" 1
    run_security_test "Srv" "/srv" 1
    run_security_test "Run" "/run" 1
    
    # Resumo
    section "RESULTADO DO TESTE DE SEGURANÇA"
    echo "Total de testes: $TEST_COUNT"
    echo -e "${GREEN}Testes passados: $PASS_COUNT${NC}"
    if [ $FAIL_COUNT -gt 0 ]; then
        echo -e "${RED}Testes falhados: $FAIL_COUNT${NC}"
    else
        echo -e "${GREEN}Testes falhados: $FAIL_COUNT${NC}"
    fi
    
    # Taxa de sucesso
    local success_rate=$((PASS_COUNT * 100 / TEST_COUNT))
    echo "Taxa de sucesso: $success_rate%"
    
    if [ $FAIL_COUNT -eq 0 ]; then
        success "✅ Todos os testes de segurança passaram!"
        return 0
    else
        error "❌ $FAIL_COUNT testes de segurança falharam!"
        return 1
    fi
}

# Executar teste principal
main "$@" | tee "$TEST_LOG_FILE"

# Retornar status baseado no resultado do teste
if [ $FAIL_COUNT -eq 0 ]; then
    exit 0
else
    exit 1
fi
