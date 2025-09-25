#!/bin/bash
# -*- coding: utf-8 -*-
#
# Cluster AI - Security Test Script
# Testador de implementações de segurança do Cluster AI
#
# Projeto: Cluster AI
# Autor: Sistema de consolidação automática
# Data: 2024-12-19
# Versão: 1.0.0
#
# Descrição:
#   Script responsável por testar as implementações de segurança do Cluster AI.
#   Executa uma bateria completa de testes de segurança incluindo permissões,
#   configurações de firewall, autenticação, certificados e vulnerabilidades
#   conhecidas. Gera relatórios detalhados e recomendações.
#
# Uso:
#   ./scripts/security/test_security_improvements.sh [opções]
#
# Dependências:
#   - bash
#   - stat, ls, grep, awk (para verificações)
#   - openssl (para certificados)
#   - nmap (para testes de rede - opcional)
#
# Changelog:
#   v1.0.0 - 2024-12-19: Criação inicial com funcionalidades completas
#
# ============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório base
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
TEST_LOG="$LOG_DIR/security_test.log"

# Configurações
VERBOSE_MODE="false"
GENERATE_REPORT="true"
CRITICAL_ONLY="false"
TIMEOUT_SECONDS="30"

# Arrays para controle
TEST_RESULTS=()
FAILED_TESTS=()
PASSED_TESTS=()
WARNINGS=()

# Funções utilitárias
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar dependências
check_dependencies() {
    log_info "Verificando dependências do testador de segurança..."

    local missing_deps=()
    local required_commands=(
        "stat"
        "grep"
        "awk"
        "openssl"
    )

    local optional_commands=(
        "nmap"
        "curl"
        "wget"
    )

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Dependências obrigatórias faltando: ${missing_deps[*]}"
        return 1
    fi

    for cmd in "${optional_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_warning "Dependência opcional não encontrada: $cmd"
        fi
    done

    log_success "Dependências verificadas"
    return 0
}

# Função para executar teste
run_test() {
    local test_name="$1"
    local test_function="$2"
    local critical="${3:-false}"

    if [ "$CRITICAL_ONLY" = "true" ] && [ "$critical" != "true" ]; then
        return 0
    fi

    log_info "Executando teste: $test_name"

    local start_time=$(date +%s)
    local result="UNKNOWN"
    local output=""

    # Executar teste com timeout
    if output=$(timeout "$TIMEOUT_SECONDS" eval "$test_function" 2>&1); then
        if echo "$output" | grep -q "PASS"; then
            result="PASS"
            PASSED_TESTS+=("$test_name")
        elif echo "$output" | grep -q "FAIL"; then
            result="FAIL"
            FAILED_TESTS+=("$test_name")
        elif echo "$output" | grep -q "WARN"; then
            result="WARN"
            WARNINGS+=("$test_name")
        else
            result="PASS"
            PASSED_TESTS+=("$test_name")
        fi
    else
        result="FAIL"
        FAILED_TESTS+=("$test_name")
        output="Teste falhou ou excedeu timeout de $TIMEOUT_SECONDS segundos"
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    local test_result="$test_name|$result|$duration|$output"
    TEST_RESULTS+=("$test_result")

    case "$result" in
        "PASS")
            log_success "$test_name: PASSADO ($duration s)"
            ;;
        "FAIL")
            log_error "$test_name: FALHADO ($duration s)"
            if [ "$VERBOSE_MODE" = "true" ]; then
                echo "  Detalhes: $output"
            fi
            ;;
        "WARN")
            log_warning "$test_name: AVISO ($duration s)"
            if [ "$VERBOSE_MODE" = "true" ]; then
                echo "  Detalhes: $output"
            fi
            ;;
    esac
}

# Teste: Permissões de arquivos críticos
test_file_permissions() {
    local critical_files=(
        "manager.sh"
        "scripts/lib/common.sh"
        "scripts/security/test_security_improvements.sh"
    )

    local all_pass=true

    for file in "${critical_files[@]}"; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            local perms
            perms=$(stat -c "%a" "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
            if [ "$perms" = "unknown" ] || [ "$perms" -gt 755 ]; then
                echo "FAIL: Arquivo $file tem permissões inseguras ($perms)"
                all_pass=false
            fi
        else
            echo "WARN: Arquivo crítico $file não encontrado"
        fi
    done

    if [ "$all_pass" = "true" ]; then
        echo "PASS: Todas as permissões de arquivos estão seguras"
    else
        echo "FAIL: Problemas encontrados nas permissões de arquivos"
    fi
}

# Teste: Funções de segurança
test_security_functions() {
    local test_functions=(
        "validate_input"
        "check_user_authorization"
        "confirm_critical_operation"
        "audit_log"
    )

    local available_count=0

    for func in "${test_functions[@]}"; do
        if command -v "$func" >/dev/null 2>&1; then
            ((available_count++))
        fi
    done

    if [ "$available_count" -eq "${#test_functions[@]}" ]; then
        echo "PASS: Todas as funções de segurança estão disponíveis"
    else
        echo "FAIL: $available_count/${#test_functions[@]} funções de segurança disponíveis"
    fi
}

# Teste: Configuração SSH
test_ssh_configuration() {
    local issues=()

    # Verificar se SSH está ativo
    if ! systemctl is-active --quiet sshd 2>/dev/null && ! systemctl is-active --quiet ssh 2>/dev/null; then
        issues+=("Serviço SSH não está ativo")
    fi

    # Verificar chaves SSH
    if [ ! -f "$HOME/.ssh/id_rsa" ] && [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        issues+=("Nenhuma chave SSH encontrada")
    fi

    # Verificar authorized_keys
    if [ -f "$HOME/.ssh/authorized_keys" ]; then
        local key_count=$(wc -l < "$HOME/.ssh/authorized_keys")
        if [ "$key_count" -eq 0 ]; then
            issues+=("Arquivo authorized_keys está vazio")
        fi
    else
        issues+=("Arquivo authorized_keys não encontrado")
    fi

    if [ ${#issues[@]} -eq 0 ]; then
        echo "PASS: Configuração SSH adequada"
    else
        echo "FAIL: Problemas na configuração SSH: ${issues[*]}"
    fi
}

# Teste: Firewall
test_firewall_configuration() {
    local firewall_active=false

    if command -v ufw >/dev/null 2>&1; then
        if ufw status 2>/dev/null | grep -q "Status: active"; then
            firewall_active=true
        fi
    elif command -v firewall-cmd >/dev/null 2>&1; then
        if firewall-cmd --state 2>/dev/null | grep -q "running"; then
            firewall_active=true
        fi
    fi

    if [ "$firewall_active" = "true" ]; then
        echo "PASS: Firewall está ativo"
    else
        echo "FAIL: Nenhum firewall ativo detectado"
    fi
}

# Teste: Certificados SSL/TLS
test_ssl_certificates() {
    local cert_dir="$PROJECT_ROOT/certs"
    local issues=()

    if [ ! -d "$cert_dir" ]; then
        echo "WARN: Diretório de certificados não encontrado"
        return 0
    fi

    for cert_file in "$cert_dir"/*.crt; do
        if [ -f "$cert_file" ]; then
            if ! openssl x509 -in "$cert_file" -noout >/dev/null 2>&1; then
                issues+=("Certificado inválido: $(basename "$cert_file")")
            else
                # Verificar validade
                local expiry=$(openssl x509 -in "$cert_file" -noout -enddate 2>/dev/null | cut -d= -f2)
                if [ -n "$expiry" ]; then
                    local expiry_timestamp=$(date -d "$expiry" +%s 2>/dev/null)
                    local current_timestamp=$(date +%s)
                    local days_left=$(( (expiry_timestamp - current_timestamp) / 86400 ))

                    if [ "$days_left" -lt 0 ]; then
                        issues+=("Certificado expirado: $(basename "$cert_file")")
                    elif [ "$days_left" -lt 30 ]; then
                        issues+=("Certificado expira em $days_left dias: $(basename "$cert_file")")
                    fi
                fi
            fi
        fi
    done

    if [ ${#issues[@]} -eq 0 ]; then
        echo "PASS: Todos os certificados estão válidos"
    else
        echo "FAIL: Problemas com certificados: ${issues[*]}"
    fi
}

# Teste: Segurança de rede
test_network_security() {
    local dangerous_ports=(23 25 110 143 445 139)
    local open_dangerous_ports=()

    for port in "${dangerous_ports[@]}"; do
        if command -v ss >/dev/null 2>&1; then
            if ss -ln 2>/dev/null | grep -q ":$port "; then
                open_dangerous_ports+=("$port")
            fi
        elif command -v netstat >/dev/null 2>&1; then
            if netstat -ln 2>/dev/null | grep -q ":$port "; then
                open_dangerous_ports+=("$port")
            fi
        fi
    done

    if [ ${#open_dangerous_ports[@]} -eq 0 ]; then
        echo "PASS: Nenhuma porta perigosa aberta"
    else
        echo "WARN: Portas potencialmente perigosas abertas: ${open_dangerous_ports[*]}"
    fi
}

# Teste: Permissões de usuário
test_user_permissions() {
    local issues=()

    # Verificar se está executando como root
    if [ "$EUID" -eq 0 ]; then
        issues+=("Executando como root")
    fi

    # Verificar se pode escrever no diretório do projeto
    if ! touch "$PROJECT_ROOT/.test_write" 2>/dev/null; then
        issues+=("Sem permissões de escrita no diretório do projeto")
    else
        rm -f "$PROJECT_ROOT/.test_write"
    fi

    if [ ${#issues[@]} -eq 0 ]; then
        echo "PASS: Permissões de usuário adequadas"
    else
        echo "FAIL: Problemas de permissões: ${issues[*]}"
    fi
}

# Teste: Variáveis de ambiente
test_environment_variables() {
    local required_vars=("PATH" "HOME")
    local missing_vars=()

    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -eq 0 ]; then
        echo "PASS: Todas as variáveis de ambiente críticas estão definidas"
    else
        echo "FAIL: Variáveis de ambiente faltando: ${missing_vars[*]}"
    fi
}

# Teste: Logs de segurança
test_security_logging() {
    local log_files=(
        "$LOG_DIR/security_events.log"
        "$LOG_DIR/auth_manager.log"
        "$LOG_DIR/firewall_manager.log"
    )

    local existing_logs=0

    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            ((existing_logs++))
            # Verificar se o log tem conteúdo recente
            if [ -s "$log_file" ]; then
                local last_modified
                last_modified=$(stat -c %Y "$log_file" 2>/dev/null || echo "0")
                local current_time
                current_time=$(date +%s)
                local age=$((current_time - last_modified))
                if [ "$age" -gt 86400 ]; then  # 24 horas
                    echo "WARN: Log $log_file não foi atualizado recentemente ($age segundos)"
                fi
            else
                echo "WARN: Log $log_file está vazio"
            fi
        fi
    done

    if [ "$existing_logs" -gt 0 ]; then
        echo "PASS: $existing_logs arquivos de log de segurança encontrados"
    else
        echo "WARN: Nenhum arquivo de log de segurança encontrado"
    fi
}

# Teste: Integridade de arquivos críticos
test_file_integrity() {
    local critical_files=(
        "manager.sh"
        "scripts/lib/common.sh"
        "scripts/security/test_security_improvements.sh"
        "README.md"
    )

    local issues=()

    for file in "${critical_files[@]}"; do
        if [ -f "$PROJECT_ROOT/$file" ]; then
            # Verificar se o arquivo não está vazio
            if [ ! -s "$PROJECT_ROOT/$file" ]; then
                issues+=("Arquivo crítico vazio: $file")
            fi

            # Verificar permissões (não deve ser world-writable)
            local perms
            perms=$(stat -c "%a" "$PROJECT_ROOT/$file" 2>/dev/null || echo "unknown")
            if [ "$perms" != "unknown" ] && [ "$perms" -gt 755 ]; then
                issues+=("Permissões inseguras em $file: $perms")
            fi
        else
            issues+=("Arquivo crítico não encontrado: $file")
        fi
    done

    if [ ${#issues[@]} -eq 0 ]; then
        echo "PASS: Integridade de arquivos críticos verificada"
    else
        echo "FAIL: Problemas de integridade: ${issues[*]}"
    fi
}

# Função para gerar relatório
generate_test_report() {
    local report_file="$LOG_DIR/security_test_report_$(date +%Y%m%d_%H%M%S).log"

    cat > "$report_file" << EOF
=== Relatório de Testes de Segurança - Cluster AI ===
Data: $(date -Iseconds)
Total de testes executados: ${#TEST_RESULTS[@]}
Testes aprovados: ${#PASSED_TESTS[@]}
Testes reprovados: ${#FAILED_TESTS[@]}
Avisos: ${#WARNINGS[@]}

1. Testes Executados:
$(printf '  - %s\n' "${TEST_RESULTS[@]}" | sed 's/|/ | /g')

2. Testes Aprovados:
$(printf '  - %s\n' "${PASSED_TESTS[@]}")

3. Testes Reprovados:
$(printf '  - %s\n' "${FAILED_TESTS[@]}")

4. Avisos:
$(printf '  - %s\n' "${WARNINGS[@]}")

5. Configurações de Teste:
  - Modo verboso: $VERBOSE_MODE
  - Apenas testes críticos: $CRITICAL_ONLY
  - Timeout: $TIMEOUT_SECONDS segundos
  - Relatório gerado: $GENERATE_REPORT

6. Recomendações:
$(if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo "  - Corrigir testes reprovados antes de colocar em produção"
    echo "  - Revisar configurações de segurança"
    echo "  - Executar testes regularmente"
else
    echo "  - Manter monitoramento contínuo"
    echo "  - Executar testes regularmente"
    echo "  - Atualizar configurações de segurança"
fi)

=== Fim do Relatório ===
EOF

    log_success "Relatório de testes gerado: $report_file"
    echo "$report_file"
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    # Carregar biblioteca comum
    if [ -f "$PROJECT_ROOT/scripts/lib/common.sh" ]; then
        # shellcheck disable=SC1091
        source "$PROJECT_ROOT/scripts/lib/common.sh"
    else
        log_error "Biblioteca comum não encontrada: $PROJECT_ROOT/scripts/lib/common.sh"
        exit 1
    fi

    # Criar diretório de logs
    mkdir -p "$LOG_DIR"
    touch "$TEST_LOG"

    local action="${1:-run}"

    case "$action" in
        "run")
            check_dependencies || exit 1

            log_info "Iniciando bateria completa de testes de segurança"

            # Executar todos os testes
            run_test "Permissões de Arquivos" "test_file_permissions" "true"
            run_test "Funções de Segurança" "test_security_functions" "true"
            run_test "Configuração SSH" "test_ssh_configuration" "true"
            run_test "Firewall" "test_firewall_configuration" "true"
            run_test "Certificados SSL/TLS" "test_ssl_certificates" "false"
            run_test "Segurança de Rede" "test_network_security" "false"
            run_test "Permissões de Usuário" "test_user_permissions" "true"
            run_test "Variáveis de Ambiente" "test_environment_variables" "false"
            run_test "Logs de Segurança" "test_security_logging" "false"
            run_test "Integridade de Arquivos" "test_file_integrity" "true"

            # Resultado final
            echo
            echo "=== RESULTADO FINAL DOS TESTES ==="
            echo "Total de testes: ${#TEST_RESULTS[@]}"
            echo "✅ Aprovados: ${#PASSED_TESTS[@]}"
            echo "❌ Reprovados: ${#FAILED_TESTS[@]}"
            echo "⚠️  Avisos: ${#WARNINGS[@]}"

            if [ ${#FAILED_TESTS[@]} -eq 0 ]; then
                log_success "Todos os testes críticos foram aprovados!"
            else
                log_error "${#FAILED_TESTS[@]} teste(s) crítico(s) reprovado(s)"
            fi

            # Gerar relatório se solicitado
            if [ "$GENERATE_REPORT" = "true" ]; then
                generate_test_report
            fi
            ;;
        "report")
            generate_test_report
            ;;
        "help"|*)
            echo "Cluster AI - Security Test Script"
            echo ""
            echo "Uso: $0 [ação] [opções]"
            echo ""
            echo "Ações:"
            echo "  run          - Executar bateria completa de testes"
            echo "  report       - Gerar relatório dos últimos testes"
            echo "  help         - Mostra esta mensagem"
            echo ""
            echo "Opções:"
            echo "  --verbose    - Modo verboso"
            echo "  --critical   - Apenas testes críticos"
            echo "  --no-report  - Não gerar relatório"
            echo ""
            echo "Configurações:"
            echo "  - Modo verboso: $VERBOSE_MODE"
            echo "  - Apenas críticos: $CRITICAL_ONLY"
            echo "  - Timeout: $TIMEOUT_SECONDS segundos"
            echo ""
            echo "Exemplos:"
            echo "  $0 run --verbose"
            echo "  $0 run --critical"
            echo "  $0 report"
            ;;
    esac
}

# Processar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE_MODE="true"
            shift
            ;;
        --critical)
            CRITICAL_ONLY="true"
            shift
            ;;
        --no-report)
            GENERATE_REPORT="false"
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Executar função principal
main "$@"
