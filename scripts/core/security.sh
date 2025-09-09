#!/bin/bash
# =============================================================================
# Cluster AI - Módulo de Segurança
# =============================================================================
# Este arquivo contém todas as funções relacionadas à segurança, validação
# de entrada e sistema de auditoria do Cluster AI.

set -euo pipefail

# Carregar funções comuns se não estiver carregado
if [[ -z "${PROJECT_ROOT:-}" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
fi

# =============================================================================
# CONFIGURAÇÃO DE SEGURANÇA
# =============================================================================

# Arquivos de auditoria
readonly AUDIT_LOG_FILE="/var/log/cluster_ai_audit.log"
readonly LOCAL_AUDIT_FILE="${LOGS_DIR}/security_audit.log"

# Níveis de risco
readonly RISK_LOW="low"
readonly RISK_MEDIUM="medium"
readonly RISK_HIGH="high"
readonly RISK_CRITICAL="critical"

# =============================================================================
# FUNÇÕES DE AUDITORIA
# =============================================================================

# Registrar evento de auditoria
audit_log() {
    local action="$1"
    local status="${2:-SUCCESS}"
    local details="${3:-}"
    local user="${USER:-unknown}"
    local hostname="${HOSTNAME:-unknown}"
    local timestamp=$(current_timestamp)

    # Formatar entrada de log
    local log_entry="$timestamp [$user@$hostname] [$action] [$status] $details"

    # Tentar escrever no log do sistema
    if sudo touch "$AUDIT_LOG_FILE" 2>/dev/null; then
        echo "$log_entry" | sudo tee -a "$AUDIT_LOG_FILE" >/dev/null
    fi

    # Sempre escrever no log local
    ensure_file "$LOCAL_AUDIT_FILE"
    echo "$log_entry" >> "$LOCAL_AUDIT_FILE"

    debug "Audit log: $action - $status"
}

# Registrar evento de segurança
security_log() {
    local event="$1"
    local severity="${2:-INFO}"
    local details="${3:-}"

    audit_log "SECURITY_$event" "$severity" "$details"
}

# =============================================================================
# VALIDAÇÃO DE ENTRADA
# =============================================================================

# Validar entrada genérica
validate_input() {
    local input="$1"
    local type="$2"
    local max_length="${3:-255}"

    # Verificar tamanho
    if (( ${#input} > max_length )); then
        error "Entrada muito longa (máx: $max_length caracteres)"
        return 1
    fi

    # Verificar caracteres perigosos
    if [[ "$input" =~ [\;\|\&\$\`\(\)\<\>\"\'\\] ]]; then
        security_log "INVALID_INPUT" "HIGH" "Caracteres perigosos detectados: $input"
        error "Caracteres não permitidos na entrada"
        return 1
    fi

    # Validação específica por tipo
    case "$type" in
        "ip")
            validate_ip "$input" || return 1
            ;;
        "port")
            validate_port "$input" || return 1
            ;;
        "hostname")
            validate_hostname "$input" || return 1
            ;;
        "filepath")
            validate_filepath "$input" || return 1
            ;;
        "service_name")
            validate_service_name "$input" || return 1
            ;;
        "user")
            validate_username "$input" || return 1
            ;;
        *)
            warn "Tipo de validação desconhecido: $type"
            ;;
    esac

    return 0
}

# Validar endereço IP
validate_ip() {
    local ip="$1"

    if ! is_valid_ip "$ip"; then
        error "Formato de IP inválido: $ip"
        return 1
    fi

    # Verificar octetos válidos
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ -z "$octet" ]] || (( octet < 0 || octet > 255 )); then
            error "Octeto inválido no IP: $octet"
            return 1
        fi
    done

    # Verificar octetos consecutivos vazios
    if [[ "$ip" =~ \.\. ]]; then
        error "IP contém octetos vazios consecutivos: $ip"
        return 1
    fi

    return 0
}

# Validar porta
validate_port() {
    local port="$1"

    if ! is_number "$port"; then
        error "Porta deve ser um número: $port"
        return 1
    fi

    if (( port < 1 || port > 65535 )); then
        error "Porta deve estar entre 1-65535: $port"
        return 1
    fi

    return 0
}

# Validar hostname
validate_hostname() {
    local hostname="$1"

    if ! is_valid_hostname "$hostname"; then
        error "Nome de host inválido: $hostname"
        return 1
    fi

    # Verificar comprimento
    if (( ${#hostname} > 253 )); then
        error "Nome de host muito longo (máx: 253 caracteres): $hostname"
        return 1
    fi

    return 0
}

# Validar caminho de arquivo
validate_filepath() {
    local path="$1"

    # Verificar caracteres perigosos
    if [[ "$path" =~ [\;\|\&\$\`\(\)\<\>\"\'\\] ]]; then
        error "Caminho contém caracteres não permitidos: $path"
        return 1
    fi

    # Verificar tentativas de path traversal
    if [[ "$path" =~ \.\. ]]; then
        security_log "PATH_TRAVERSAL_ATTEMPT" "HIGH" "Tentativa de path traversal: $path"
        error "Caminho não permitido (path traversal)"
        return 1
    fi

    return 0
}

# Validar nome de serviço
validate_service_name() {
    local service="$1"

    if [[ ! "$service" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "Nome de serviço inválido (apenas letras, números, hífen, underscore): $service"
        return 1
    fi

    if (( ${#service} > 50 )); then
        error "Nome de serviço muito longo (máx: 50 caracteres): $service"
        return 1
    fi

    return 0
}

# Validar nome de usuário
validate_username() {
    local user="$1"

    if [[ ! "$user" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "Nome de usuário inválido: $user"
        return 1
    fi

    if (( ${#user} > 32 )); then
        error "Nome de usuário muito longo (máx: 32 caracteres): $user"
        return 1
    fi

    return 0
}

# =============================================================================
# AUTORIZAÇÃO E AUTENTICAÇÃO
# =============================================================================

# Verificar autorização do usuário
check_user_authorization() {
    local current_user="${USER:-$(whoami)}"
    local sudo_user="${SUDO_USER:-}"

    # Lista de usuários autorizados
    local authorized_users=("root" "dcm" "dagoberto" "admin")
    local privileged_groups=("sudo" "wheel" "admin")

    # Verificar usuário atual
    for user in "${authorized_users[@]}"; do
        if [[ "$current_user" == "$user" ]] || [[ "$sudo_user" == "$user" ]]; then
            audit_log "USER_AUTHORIZED" "SUCCESS" "User: $current_user, SUDO_USER: $sudo_user"
            return 0
        fi
    done

    # Verificar grupos privilegiados
    if groups "$current_user" 2>/dev/null | grep -qE "\b($(IFS=\|; echo "${privileged_groups[*]}"))\b"; then
        audit_log "USER_AUTHORIZED_GROUP" "SUCCESS" "User: $current_user is in privileged group"
        return 0
    fi

    # Usuário não autorizado
    security_log "UNAUTHORIZED_ACCESS" "CRITICAL" "User: $current_user, SUDO_USER: $sudo_user"
    error "Usuário não autorizado para executar operações administrativas"
    info "Para executar este script, você precisa ser um usuário autorizado ou estar no grupo sudo/wheel"
    return 1
}

# Verificar se usuário é root (com aviso)
check_root_user() {
    if [[ "$EUID" -eq 0 ]]; then
        warn "ERRO DE SEGURANÇA: Este script não deve ser executado como root (sudo)."
        warn "Use um usuário normal com privilégios sudo quando necessário."
        audit_log "ROOT_EXECUTION_WARNING" "WARNING" "Script executado como root"
        return 1
    fi
    return 0
}

# =============================================================================
# CONFIRMAÇÃO DE OPERAÇÕES CRÍTICAS
# =============================================================================

# Solicitar confirmação do usuário
confirm_operation() {
    local message="$1"
    local default="${2:-n}"  # y ou n

    echo -e -n "${YELLOW}AVISO:${NC} $message "
    if [[ "$default" == "y" ]]; then
        echo -n "(Y/n) "
    else
        echo -n "(y/N) "
    fi

    read -n 1 -r
    echo

    if [[ "$default" == "y" ]]; then
        [[ ! $REPLY =~ ^[Nn]$ ]]
    else
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# Confirmar operação crítica
confirm_critical_operation() {
    local operation="$1"
    local risk_level="$2"
    local details="${3:-}"

    audit_log "CRITICAL_OPERATION_REQUEST" "INFO" "Operation: $operation, Risk: $risk_level"

    # Mensagem baseada no nível de risco
    case "$risk_level" in
        "$RISK_CRITICAL")
            echo -e "${RED}🚨 OPERAÇÃO CRÍTICA DETECTADA${NC}"
            echo -e "${RED}Esta operação pode comprometer a segurança do sistema${NC}"
            ;;
        "$RISK_HIGH")
            echo -e "${RED}⚠️  OPERAÇÃO DE ALTO RISCO${NC}"
            ;;
        "$RISK_MEDIUM")
            echo -e "${YELLOW}⚡ OPERAÇÃO DE RISCO MÉDIO${NC}"
            ;;
        "$RISK_LOW")
            echo -e "${GREEN}ℹ️  OPERAÇÃO DE BAIXO RISCO${NC}"
            ;;
    esac

    echo
    echo "Operação: $operation"
    [[ -n "$details" ]] && echo "Detalhes: $details"
    echo

    # Múltiplas tentativas para operações críticas
    local max_attempts=3
    local attempt=0

    while (( attempt < max_attempts )); do
        if [[ "$risk_level" == "$RISK_CRITICAL" ]]; then
            read -p "Digite 'CONFIRMAR' para prosseguir (ou 'cancelar' para abortar): " response
            if [[ "$response" == "CONFIRMAR" ]]; then
                audit_log "CRITICAL_OPERATION_CONFIRMED" "SUCCESS" "Operation: $operation"
                return 0
            elif [[ "$response" == "cancelar" ]]; then
                audit_log "CRITICAL_OPERATION_CANCELLED" "INFO" "Operation: $operation"
                return 1
            fi
        else
            if confirm_operation "Confirmar execução desta operação?"; then
                audit_log "OPERATION_CONFIRMED" "SUCCESS" "Operation: $operation, Risk: $risk_level"
                return 0
            else
                audit_log "OPERATION_CANCELLED" "INFO" "Operation: $operation, Risk: $risk_level"
                return 1
            fi
        fi

        ((attempt++))
        if (( attempt < max_attempts )); then
            warn "Tentativa $attempt de $max_attempts. Tente novamente."
        fi
    done

    error "Número máximo de tentativas excedido. Operação cancelada."
    audit_log "OPERATION_CANCELLED_MAX_ATTEMPTS" "WARNING" "Operation: $operation"
    return 1
}

# =============================================================================
# RATE LIMITING
# =============================================================================

# Arquivo para controlar rate limiting
readonly RATE_LIMIT_FILE="${RUN_DIR}/rate_limit.cache"

# Verificar rate limiting
check_rate_limit() {
    local operation="$1"
    local max_per_hour="${2:-10}"
    local current_time=$(date +%s)
    local hour_ago=$((current_time - 3600))

    ensure_file "$RATE_LIMIT_FILE"

    # Contar operações na última hora
    local count=$(grep "^$operation:" "$RATE_LIMIT_FILE" | \
                  awk -F: -v hour_ago="$hour_ago" '$2 > hour_ago {count++} END {print count+0}')

    if (( count >= max_per_hour )); then
        security_log "RATE_LIMIT_EXCEEDED" "WARNING" "Operation: $operation, Count: $count"
        error "Limite de operações excedido para: $operation"
        return 1
    fi

    # Registrar operação
    echo "$operation:$current_time" >> "$RATE_LIMIT_FILE"

    # Limpar entradas antigas
    sed -i "/^$operation:/d" "$RATE_LIMIT_FILE" 2>/dev/null || true
    grep "^$operation:" "$RATE_LIMIT_FILE" | \
    awk -F: -v hour_ago="$hour_ago" '$2 > hour_ago {print}' >> "$RATE_LIMIT_FILE"

    return 0
}

# =============================================================================
# VALIDAÇÃO DE CONFIGURAÇÃO
# =============================================================================

# Validar arquivo de configuração
validate_config_file() {
    local config_file="$1"

    if ! file_exists "$config_file"; then
        error "Arquivo de configuração não encontrado: $config_file"
        return 1
    fi

    # Verificar permissões (não deve ser world-writable)
    if [[ -w "$config_file" && $(stat -c %a "$config_file" 2>/dev/null | cut -c3) == "2" ]] 2>/dev/null; then
        security_log "INSECURE_CONFIG_PERMISSIONS" "HIGH" "Config file world-writable: $config_file"
        warn "Arquivo de configuração tem permissões inseguras"
    fi

    # Verificar sintaxe básica (se for YAML)
    if [[ "$config_file" == *.yaml || "$config_file" == *.yml ]]; then
        if command_exists python3; then
            if ! python3 -c "import yaml; yaml.safe_load(open('$config_file'))" 2>/dev/null; then
                error "Arquivo de configuração YAML inválido: $config_file"
                return 1
            fi
        fi
    fi

    return 0
}

# =============================================================================
# HARDENING DO SISTEMA
# =============================================================================

# Verificar configurações de segurança básicas
check_security_hardening() {
    local issues=()

    # Verificar se SSH root login está desabilitado
    if file_exists "/etc/ssh/sshd_config"; then
        if grep -q "^PermitRootLogin yes" "/etc/ssh/sshd_config"; then
            issues+=("SSH root login habilitado")
        fi
    fi

    # Verificar firewall
    if ! command_exists ufw && ! command_exists firewall-cmd; then
        issues+=("Nenhum firewall detectado")
    fi

    # Verificar SELinux/AppArmor
    if command_exists getenforce; then
        if [[ "$(getenforce 2>/dev/null)" == "Disabled" ]]; then
            issues+=("SELinux desabilitado")
        fi
    fi

    if (( ${#issues[@]} > 0 )); then
        warn "Problemas de segurança detectados:"
        for issue in "${issues[@]}"; do
            echo "  - $issue"
        done
        security_log "SECURITY_ISSUES_DETECTED" "WARNING" "Issues: ${issues[*]}"
    fi
}

# =============================================================================
# LIMPEZA DE SEGURANÇA
# =============================================================================

# Limpar dados sensíveis dos logs
sanitize_logs() {
    local log_file="$1"

    if file_exists "$log_file"; then
        # Remover senhas e tokens dos logs
        sed -i 's/password=[^ ]*/password=***/gi' "$log_file" 2>/dev/null || true
        sed -i 's/token=[^ ]*/token=***/gi' "$log_file" 2>/dev/null || true
        sed -i 's/key=[^ ]*/key=***/gi' "$log_file" 2>/dev/null || true
    fi
}

# Limpar cache de rate limiting antigo
cleanup_rate_limit_cache() {
    if file_exists "$RATE_LIMIT_FILE"; then
        local week_ago=$(date -d '1 week ago' +%s 2>/dev/null || echo "0")
        sed -i "/:[0-9]\{10\}$/d" "$RATE_LIMIT_FILE" 2>/dev/null || true
        awk -F: -v cutoff="$week_ago" '$2 > cutoff {print}' "$RATE_LIMIT_FILE" > "${RATE_LIMIT_FILE}.tmp" 2>/dev/null && \
        mv "${RATE_LIMIT_FILE}.tmp" "$RATE_LIMIT_FILE" 2>/dev/null || true
    fi
}

# =============================================================================
# INICIALIZAÇÃO DO MÓDULO
# =============================================================================

# Inicializar módulo de segurança
init_security_module() {
    # Criar diretórios necessários
    ensure_dir "$(dirname "$AUDIT_LOG_FILE")"
    ensure_dir "$(dirname "$LOCAL_AUDIT_FILE")"

    # Verificar hardening básico
    check_security_hardening

    # Limpar cache antigo
    cleanup_rate_limit_cache

    audit_log "SECURITY_MODULE_INITIALIZED" "SUCCESS" "Security module loaded"
}

# Verificar se módulo foi carregado corretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_environment
    init_security_module
    info "Módulo security.sh carregado com sucesso"
fi
