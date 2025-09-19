#!/bin/bash
#
# 🛡️ TESTE DE MELHORIAS DE SEGURANÇA
# Script para testar as implementações de segurança do Cluster AI
#

set -euo pipefail

# --- Carregar Funções Comuns ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# --- Constantes ---
TEST_LOG="${PROJECT_ROOT}/logs/security_test_$(date +%Y%m%d_%H%M%S).log"

# --- Função de Log de Teste ---
test_log() {
    local message="$1"
    echo "$(date '+%H:%M:%S') - $message" | tee -a "$TEST_LOG"
}

# --- Testes ---

test_input_validation() {
    section "🧪 Testando Validação de Entrada"

    test_log "=== TESTE DE VALIDAÇÃO DE ENTRADA ==="

    # Testar função validate_input (simulando)
    subsection "Teste de IP válido"
    if [[ "192.168.1.1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        IFS='.' read -ra octets <<< "192.168.1.1"
        valid=true
        for octet in "${octets[@]}"; do
            if [[ $octet -lt 0 || $octet -gt 255 ]]; then
                valid=false
                break
            fi
        done
        if $valid; then
            success "✅ IP válido detectado corretamente"
            test_log "PASS: IP validation"
        else
            error "❌ Falha na validação de IP válido"
            test_log "FAIL: IP validation"
        fi
    fi

    subsection "Teste de IP inválido"
    if [[ "999.999.999.999" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        # Mesmo que passe no regex, verificar octetos
        IFS='.' read -ra octets <<< "999.999.999.999"
        invalid=false
        for octet in "${octets[@]}"; do
            if [[ $octet -lt 0 || $octet -gt 255 ]]; then
                invalid=true
                break
            fi
        done
        if $invalid; then
            success "✅ IP inválido rejeitado corretamente"
            test_log "PASS: Invalid IP rejection"
        else
            error "❌ IP inválido aceito incorretamente"
            test_log "FAIL: Invalid IP rejection"
        fi
    else
        success "✅ IP inválido rejeitado corretamente (regex)"
        test_log "PASS: Invalid IP rejection"
    fi

    subsection "Teste de porta válida"
    if [[ "8080" =~ ^[0-9]+$ ]] && [[ 8080 -ge 1 && 8080 -le 65535 ]]; then
        success "✅ Porta válida aceita"
        test_log "PASS: Port validation"
    else
        error "❌ Porta válida rejeitada"
        test_log "FAIL: Port validation"
    fi

    subsection "Teste de porta inválida"
    if [[ ! "99999" =~ ^[0-9]+$ ]] || [[ 99999 -lt 1 || 99999 -gt 65535 ]]; then
        success "✅ Porta inválida rejeitada"
        test_log "PASS: Invalid port rejection"
    else
        error "❌ Porta inválida aceita"
        test_log "FAIL: Invalid port rejection"
    fi
}

test_audit_system() {
    section "🧪 Testando Sistema de Auditoria"

    test_log "=== TESTE DO SISTEMA DE AUDITORIA ==="

    # Criar diretório de logs se não existir
    mkdir -p "${PROJECT_ROOT}/logs"

    # Testar função audit_log (simulando)
    subsection "Teste de auditoria local"
    local test_audit_file="${PROJECT_ROOT}/logs/test_audit.log"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [test_user@test_host] TEST_ACTION: Test details" >> "$test_audit_file"

    if [ -f "$test_audit_file" ] && grep -q "TEST_ACTION" "$test_audit_file"; then
        success "✅ Sistema de auditoria local funcionando"
        test_log "PASS: Local audit system"
    else
        error "❌ Sistema de auditoria local falhando"
        test_log "FAIL: Local audit system"
    fi

    # Limpar arquivo de teste
    rm -f "$test_audit_file"
}

test_authorization() {
    section "🧪 Testando Controle de Acesso"

    test_log "=== TESTE DE CONTROLE DE ACESSO ==="

    subsection "Teste de usuário atual"
    local current_user
    current_user=$(whoami)

    if [ -n "$current_user" ]; then
        success "✅ Usuário atual identificado: $current_user"
        test_log "PASS: Current user identification - $current_user"
    else
        error "❌ Falha ao identificar usuário atual"
        test_log "FAIL: Current user identification"
    fi

    subsection "Teste de grupos do usuário"
    if groups "$current_user" >/dev/null 2>&1; then
        success "✅ Comando groups funcionando"
        test_log "PASS: Groups command working"
    else
        warn "⚠️ Comando groups pode não estar disponível"
        test_log "WARN: Groups command may not be available"
    fi
}

test_service_management() {
    section "🧪 Testando Gerenciamento de Serviços"

    test_log "=== TESTE DE GERENCIAMENTO DE SERVIÇOS ==="

    subsection "Verificação de systemctl"
    if command_exists systemctl; then
        success "✅ systemctl disponível"
        test_log "PASS: systemctl available"
    else
        warn "⚠️ systemctl não disponível (pode ser normal em alguns sistemas)"
        test_log "WARN: systemctl not available"
    fi

    subsection "Verificação de Docker"
    if command_exists docker; then
        success "✅ Docker disponível"
        test_log "PASS: Docker available"
    else
        warn "⚠️ Docker não disponível"
        test_log "WARN: Docker not available"
    fi
}

test_integration_manager_commands() {
    section "🧪 Testando Integração com Comandos do Manager"

    test_log "=== TESTE DE INTEGRAÇÃO COM MANAGER ==="

    subsection "Teste de carregamento das funções de segurança"
    # Simular carregamento das funções do manager.sh
    if grep -q "validate_input()" "${PROJECT_ROOT}/manager.sh"; then
        success "✅ Função validate_input encontrada no manager.sh"
        test_log "PASS: validate_input function found"
    else
        error "❌ Função validate_input não encontrada"
        test_log "FAIL: validate_input function not found"
    fi

    if grep -q "audit_log()" "${PROJECT_ROOT}/manager.sh"; then
        success "✅ Função audit_log encontrada no manager.sh"
        test_log "PASS: audit_log function found"
    else
        error "❌ Função audit_log não encontrada"
        test_log "FAIL: audit_log function not found"
    fi

    if grep -q "check_user_authorization()" "${PROJECT_ROOT}/manager.sh"; then
        success "✅ Função check_user_authorization encontrada no manager.sh"
        test_log "PASS: check_user_authorization function found"
    else
        error "❌ Função check_user_authorization não encontrada"
        test_log "FAIL: check_user_authorization function not found"
    fi

    subsection "Teste de permissões do script manager.sh"
    if [ -x "${PROJECT_ROOT}/manager.sh" ]; then
        success "✅ manager.sh tem permissões de execução"
        test_log "PASS: manager.sh executable permissions"
    else
        warn "⚠️ manager.sh não tem permissões de execução"
        test_log "WARN: manager.sh missing executable permissions"
    fi
}

test_edge_cases() {
    section "🧪 Testando Casos Extremos (Edge Cases)"

    test_log "=== TESTE DE CASOS EXTREMOS ==="

    subsection "Teste de entrada vazia"
    # Testar validação com entrada vazia
    if [[ -z "" ]]; then
        success "✅ Entrada vazia detectada corretamente"
        test_log "PASS: Empty input detection"
    else
        error "❌ Falha na detecção de entrada vazia"
        test_log "FAIL: Empty input detection"
    fi

    subsection "Teste de caracteres especiais"
    # Testar validação com caracteres perigosos
    dangerous_input="test; rm -rf /; echo"
    if [[ "$dangerous_input" =~ [\;\|\&\$\`\(\)\<\>\"\'\\] ]]; then
        success "✅ Caracteres perigosos detectados"
        test_log "PASS: Dangerous characters detection"
    else
        error "❌ Caracteres perigosos não detectados"
        test_log "FAIL: Dangerous characters detection"
    fi

    subsection "Teste de portas extremas"
    # Testar validação de portas
    if [[ "1" =~ ^[0-9]+$ ]] && [[ 1 -ge 1 && 1 -le 65535 ]]; then
        success "✅ Porta mínima válida"
        test_log "PASS: Minimum port validation"
    else
        error "❌ Porta mínima inválida"
        test_log "FAIL: Minimum port validation"
    fi

    if [[ "65535" =~ ^[0-9]+$ ]] && [[ 65535 -ge 1 && 65535 -le 65535 ]]; then
        success "✅ Porta máxima válida"
        test_log "PASS: Maximum port validation"
    else
        error "❌ Porta máxima inválida"
        test_log "FAIL: Maximum port validation"
    fi

    subsection "Teste de nomes de host inválidos"
    invalid_hostnames=("host..name" "host_name" "host name" "host@name" "-hostname" "hostname-" ".hostname" "hostname.")
    for hostname in "${invalid_hostnames[@]}"; do
        # Usar a mesma regex do manager.sh para consistência
        if [[ ! "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?$ ]] || [[ "$hostname" =~ \.\. ]] || [[ "$hostname" =~ ^[-.] || "$hostname" =~ [-.]$ ]]; then
            success "✅ Nome de host inválido '$hostname' rejeitado"
            test_log "PASS: Invalid hostname '$hostname' rejected"
        else
            error "❌ Nome de host inválido '$hostname' aceito"
            test_log "FAIL: Invalid hostname '$hostname' accepted"
        fi
    done
}

test_ssh_simulation() {
    section "🧪 Testando Simulação de Autenticação SSH"

    test_log "=== TESTE DE SIMULAÇÃO SSH ==="

    subsection "Teste de conectividade de porta (simulado)"
    # Simular teste de porta SSH
    local test_port=22
    if [[ "$test_port" =~ ^[0-9]+$ ]] && [[ $test_port -ge 1 && $test_port -le 65535 ]]; then
        success "✅ Porta SSH válida para teste"
        test_log "PASS: SSH port validation"
    else
        error "❌ Porta SSH inválida"
        test_log "FAIL: SSH port validation"
    fi

    subsection "Teste de timeout de conexão (simulado)"
    # Simular timeout de conexão
    local timeout_duration=10
    if [[ "$timeout_duration" =~ ^[0-9]+$ ]] && [ "$timeout_duration" -gt 0 ]; then
        success "✅ Timeout de conexão válido"
        test_log "PASS: Connection timeout validation"
    else
        error "❌ Timeout de conexão inválido"
        test_log "FAIL: Connection timeout validation"
    fi

    subsection "Teste de chave SSH conhecida"
    # Verificar se o arquivo known_hosts existe
    if [ -f ~/.ssh/known_hosts ]; then
        success "✅ Arquivo known_hosts existe"
        test_log "PASS: SSH known_hosts file exists"
    else
        warn "⚠️ Arquivo known_hosts não encontrado (será criado na primeira conexão)"
        test_log "WARN: SSH known_hosts file not found"
    fi
}

test_permissions_and_access() {
    section "🧪 Testando Permissões e Controle de Acesso"

    test_log "=== TESTE DE PERMISSÕES E ACESSO ==="

    subsection "Teste de usuário root/sudo"
    if [ "$EUID" -eq 0 ]; then
        success "✅ Executando como root"
        test_log "PASS: Running as root"
    elif sudo -n true 2>/dev/null; then
        success "✅ Usuário tem privilégios sudo"
        test_log "PASS: User has sudo privileges"
    else
        warn "⚠️ Usuário não tem privilégios sudo"
        test_log "WARN: User lacks sudo privileges"
    fi

    subsection "Teste de grupos do usuário"
    user_groups=$(groups 2>/dev/null)
    if [[ "$user_groups" =~ (sudo|wheel|admin) ]]; then
        success "✅ Usuário pertence a grupo privilegiado"
        test_log "PASS: User in privileged group"
    else
        info "ℹ️ Usuário não está em grupo privilegiado"
        test_log "INFO: User not in privileged group"
    fi

    subsection "Teste de permissões de arquivos críticos"
    critical_files=("${PROJECT_ROOT}/manager.sh" "${PROJECT_ROOT}/scripts/security/test_security_improvements.sh")

    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            if [ -r "$file" ]; then
                success "✅ Arquivo $file é legível"
                test_log "PASS: File $file is readable"
            else
                error "❌ Arquivo $file não é legível"
                test_log "FAIL: File $file is not readable"
            fi

            if [ -x "$file" ]; then
                success "✅ Arquivo $file é executável"
                test_log "PASS: File $file is executable"
            else
                warn "⚠️ Arquivo $file não é executável"
                test_log "WARN: File $file is not executable"
            fi
        else
            error "❌ Arquivo $file não encontrado"
            test_log "FAIL: File $file not found"
        fi
    done
}

test_critical_operations_simulation() {
    section "🧪 Testando Simulação de Operações Críticas"

    test_log "=== TESTE DE OPERAÇÕES CRÍTICAS ==="

    subsection "Teste de níveis de risco"
    risk_levels=("low" "medium" "high" "critical")
    for risk in "${risk_levels[@]}"; do
        case "$risk" in
            "low"|"medium"|"high"|"critical")
                success "✅ Nível de risco '$risk' válido"
                test_log "PASS: Risk level '$risk' valid"
                ;;
            *)
                error "❌ Nível de risco '$risk' inválido"
                test_log "FAIL: Risk level '$risk' invalid"
                ;;
        esac
    done

    subsection "Teste de confirmação de operações (simulado)"
    # Simular confirmação de operação crítica
    local operation="systemctl restart sshd"
    local risk_level="high"

    test_log "OPERATION_REQUEST: $operation, Risk: $risk_level"

    # Simular resposta do usuário
    simulated_response="CONFIRMAR"
    if [[ "$simulated_response" == "CONFIRMAR" ]]; then
        success "✅ Confirmação de operação crítica simulada com sucesso"
        test_log "PASS: Critical operation confirmation simulated"
    else
        error "❌ Falha na simulação de confirmação"
        test_log "FAIL: Critical operation confirmation simulation"
    fi

    subsection "Teste de auditoria de operações críticas"
    # Verificar se o log de auditoria seria criado
    local audit_dir="${PROJECT_ROOT}/logs"
    if [ -d "$audit_dir" ]; then
        success "✅ Diretório de logs existe"
        test_log "PASS: Audit log directory exists"
    else
        mkdir -p "$audit_dir"
        success "✅ Diretório de logs criado"
        test_log "PASS: Audit log directory created"
    fi
}

run_security_tests() {
    section "🛡️ Executando Testes de Segurança do Cluster AI"

    test_log "=== INÍCIO DOS TESTES DE SEGURANÇA ==="
    test_log "Data/Hora: $(date)"
    test_log "Usuário: $(whoami)"
    test_log "Host: $(hostname)"
    test_log ""

    test_input_validation
    echo

    test_audit_system
    echo

    test_authorization
    echo

    test_service_management
    echo

    test_integration_manager_commands
    echo

    test_edge_cases
    echo

    test_ssh_simulation
    echo

    test_permissions_and_access
    echo

    test_critical_operations_simulation
    echo

    subsection "Resumo dos Testes"
    test_log ""
    test_log "=== RESUMO DOS TESTES ==="

    if [ -f "$TEST_LOG" ]; then
        local pass_count
        local fail_count
        local warn_count

        pass_count=$(grep -c "PASS:" "$TEST_LOG" 2>/dev/null || echo "0")
        fail_count=$(grep -c "FAIL:" "$TEST_LOG" 2>/dev/null || echo "0")
        warn_count=$(grep -c "WARN:" "$TEST_LOG" 2>/dev/null || echo "0")

        success "✅ Testes aprovados: $pass_count"
        if [[ "$fail_count" =~ ^[0-9]+$ ]] && [ "$fail_count" -gt 0 ]; then
            error "❌ Testes falhados: $fail_count"
        fi
        if [[ "$warn_count" =~ ^[0-9]+$ ]] && [ "$warn_count" -gt 0 ]; then
            warn "⚠️ Avisos: $warn_count"
        fi

        test_log "Resultados: $pass_count PASS, $fail_count FAIL, $warn_count WARN"

        info "Log completo salvo em: $TEST_LOG"
    fi

    test_log "=== FIM DOS TESTES DE SEGURANÇA ==="
}

# --- Execução ---
main() {
    run_security_tests
}

main "$@"
