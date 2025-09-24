#!/bin/bash
# -*- coding: utf-8 -*-
#
# Cluster AI - Security Logger Script
# Logger de segurança do Cluster AI
#
# Projeto: Cluster AI
# Autor: Sistema de consolidação automática
# Data: 2024-12-19
# Versão: 1.0.0
#
# Descrição:
#   Script responsável pelo logging de eventos de segurança do Cluster AI.
#   Coleta logs de autenticação, tentativas de acesso, mudanças de sistema
#   e eventos de segurança. Suporta rotação de logs, compressão e
#   análise de padrões de segurança.
#
# Uso:
#   ./scripts/security/security_logger.sh [opções]
#
# Dependências:
#   - bash
#   - journalctl (para logs do systemd)
#   - logrotate (para rotação de logs)
#   - grep, awk, sed (para processamento)
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
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
SECURITY_LOG="$LOG_DIR/security_events.log"
ARCHIVE_DIR="$LOG_DIR/archive"

# Configurações
LOG_RETENTION_DAYS="90"
MAX_LOG_SIZE="100M"
COMPRESSION_ENABLED="true"
REAL_TIME_MONITORING="false"
ALERT_ON_SUSPICIOUS="true"

# Arrays para controle
SECURITY_EVENTS=()
SUSPICIOUS_PATTERNS=(
    "Failed password"
    "Invalid user"
    "Connection closed by"
    "POSSIBLE BREAK-IN ATTEMPT"
    "sudo.*COMMAND"
    "su.*failed"
)

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
    log_info "Verificando dependências do logger de segurança..."

    local missing_deps=()
    local required_commands=(
        "journalctl"
        "logrotate"
        "grep"
        "awk"
        "sed"
        "gzip"
    )

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Dependências faltando: ${missing_deps[*]}"
        log_info "Instale as dependências necessárias e tente novamente"
        return 1
    fi

    log_success "Dependências verificadas"
    return 0
}

# Função para coletar logs de autenticação
collect_auth_logs() {
    local since="${1:-1 hour ago}"
    local auth_logs=""

    log_info "Coletando logs de autenticação desde $since..."

    # SSH logs
    if command -v journalctl &> /dev/null; then
        auth_logs+=$(sudo journalctl -u ssh --since "$since" --no-pager 2>/dev/null || echo "")
        auth_logs+=$'\n'
    fi

    # System auth logs
    if [ -f "/var/log/auth.log" ]; then
        auth_logs+=$(sudo tail -n 1000 /var/log/auth.log | grep -E "$(date -d "$since" +%b' '%e)" 2>/dev/null || echo "")
        auth_logs+=$'\n'
    fi

    # Secure logs
    if [ -f "/var/log/secure" ]; then
        auth_logs+=$(sudo tail -n 1000 /var/log/secure | grep -E "$(date -d "$since" +%b' '%e)" 2>/dev/null || echo "")
    fi

    echo "$auth_logs"
}

# Função para detectar eventos suspeitos
detect_suspicious_events() {
    local logs="$1"
    local suspicious_found=()

    for pattern in "${SUSPICIOUS_PATTERNS[@]}"; do
        local matches=$(echo "$logs" | grep -i "$pattern" | wc -l)
        if [ "$matches" -gt 0 ]; then
            suspicious_found+=("$pattern: $matches ocorrências")
        fi
    done

    if [ ${#suspicious_found[@]} -gt 0 ]; then
        log_warning "Eventos suspeitos detectados:"
        printf '  - %s\n' "${suspicious_found[@]}"
        SECURITY_EVENTS+=("${suspicious_found[@]}")
    fi
}

# Função para registrar evento de segurança
log_security_event() {
    local event_type="$1"
    local description="$2"
    local severity="${3:-INFO}"
    local timestamp=$(date -Iseconds)

    local log_entry="$timestamp [$severity] $event_type: $description"

    echo "$log_entry" >> "$SECURITY_LOG"
    SECURITY_EVENTS+=("$log_entry")

    case "$severity" in
        "CRITICAL"|"ERROR")
            log_error "$event_type: $description"
            ;;
        "WARNING")
            log_warning "$event_type: $description"
            ;;
        *)
            log_info "$event_type: $description"
            ;;
    esac
}

# Função para analisar padrões de acesso
analyze_access_patterns() {
    local logs="$1"

    log_info "Analisando padrões de acesso..."

    # IPs com mais tentativas falhidas
    local failed_ips=$(echo "$logs" | grep "Failed password" | grep -oE "from [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort | uniq -c | sort -nr | head -10)

    if [ -n "$failed_ips" ]; then
        log_security_event "ACCESS_PATTERN" "IPs com tentativas falhidas:" "WARNING"
        echo "$failed_ips" | while read -r line; do
            log_security_event "FAILED_ATTEMPTS" "$line" "WARNING"
        done
    fi

    # Usuários com tentativas falhidas
    local failed_users=$(echo "$logs" | grep "Failed password" | grep -oE "for [^ ]+" | sort | uniq -c | sort -nr | head -5)

    if [ -n "$failed_users" ]; then
        log_security_event "USER_PATTERN" "Usuários com tentativas falhidas:" "WARNING"
        echo "$failed_users" | while read -r line; do
            log_security_event "FAILED_USER" "$line" "WARNING"
        done
    fi
}

# Função para monitorar mudanças no sistema
monitor_system_changes() {
    log_info "Monitorando mudanças no sistema..."

    # Verificar pacotes instalados recentemente
    if command -v rpm &> /dev/null; then
        local recent_packages=$(rpm -qa --last | head -10)
        if [ -n "$recent_packages" ]; then
            log_security_event "PACKAGE_CHANGE" "Pacotes instalados recentemente" "INFO"
        fi
    elif command -v dpkg &> /dev/null; then
        local recent_packages=$(grep "install" /var/log/dpkg.log | tail -10)
        if [ -n "$recent_packages" ]; then
            log_security_event "PACKAGE_CHANGE" "Pacotes instalados recentemente" "INFO"
        fi
    fi

    # Verificar usuários criados recentemente
    local recent_users=$(cut -d: -f1 /etc/passwd | xargs -I {} sh -c 'echo "{}:$(chage -l {} | grep "Last password change" | cut -d: -f2)"' | grep -v "never" | sort -k2 -t: | tail -5)
    if [ -n "$recent_users" ]; then
        log_security_event "USER_CHANGE" "Usuários criados/modificados recentemente" "INFO"
    fi
}

# Função para rotacionar logs
rotate_logs() {
    log_info "Rotacionando logs de segurança..."

    local current_size=$(stat -f%z "$SECURITY_LOG" 2>/dev/null || stat -c%s "$SECURITY_LOG" 2>/dev/null || echo "0")

    # Verificar tamanho do log
    if [ "$current_size" -gt "$MAX_LOG_SIZE" ]; then
        local archive_file="$ARCHIVE_DIR/security_events_$(date +%Y%m%d_%H%M%S).log"

        mkdir -p "$ARCHIVE_DIR"
        cp "$SECURITY_LOG" "$archive_file"

        if [ "$COMPRESSION_ENABLED" = "true" ]; then
            gzip "$archive_file"
            archive_file+=".gz"
        fi

        # Limpar log atual
        echo "# Log rotated on $(date -Iseconds)" > "$SECURITY_LOG"

        log_success "Log rotacionado: $archive_file"
    fi

    # Limpar logs antigos
    find "$ARCHIVE_DIR" -name "security_events_*.log*" -mtime +"$LOG_RETENTION_DAYS" -delete 2>/dev/null || true
}

# Função para gerar relatório de segurança
generate_security_report() {
    local report_file="$LOG_DIR/security_report_$(date +%Y%m%d_%H%M%S).log"

    cat > "$report_file" << EOF
=== Relatório de Segurança - Cluster AI ===
Data: $(date -Iseconds)

1. Eventos de Segurança Recentes:
$(tail -20 "$SECURITY_LOG" 2>/dev/null || echo "Nenhum evento registrado")

2. Eventos Suspeitos:
$(printf '  - %s\n' "${SECURITY_EVENTS[@]: -10}")

3. Estatísticas:
  - Total de eventos: $(wc -l < "$SECURITY_LOG" 2>/dev/null || echo "0")
  - Eventos suspeitos hoje: $(grep "$(date +%Y-%m-%d)" "$SECURITY_LOG" | wc -l 2>/dev/null || echo "0")
  - Logs arquivados: $(find "$ARCHIVE_DIR" -name "*.log*" | wc -l 2>/dev/null || echo "0")

4. Configurações:
  - Retenção de logs: $LOG_RETENTION_DAYS dias
  - Tamanho máximo do log: $MAX_LOG_SIZE
  - Compressão: $COMPRESSION_ENABLED
  - Monitoramento em tempo real: $REAL_TIME_MONITORING
  - Alertas para suspeitas: $ALERT_ON_SUSPICIOUS

5. Recomendações:
  - Revisar eventos suspeitos regularmente
  - Configurar alertas para tentativas falhidas
  - Manter logs arquivados por período adequado
  - Implementar monitoramento contínuo

=== Fim do Relatório ===
EOF

    log_success "Relatório de segurança gerado: $report_file"
    echo "$report_file"
}

# Função para monitoramento em tempo real
start_real_time_monitoring() {
    log_info "Iniciando monitoramento em tempo real (Ctrl+C para parar)..."

    local last_check=$(date +%s)

    while true; do
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_check))

        if [ $time_diff -ge 60 ]; then  # Verificar a cada minuto
            local logs=$(collect_auth_logs "1 minute ago")
            detect_suspicious_events "$logs"
            analyze_access_patterns "$logs"
            monitor_system_changes
            rotate_logs

            last_check=$current_time
        fi

        sleep 10
    done
}

# Função para verificar integridade dos logs
verify_log_integrity() {
    log_info "Verificando integridade dos logs..."

    # Verificar se o arquivo de log existe
    if [ ! -f "$SECURITY_LOG" ]; then
        log_warning "Arquivo de log não encontrado, criando novo..."
        touch "$SECURITY_LOG"
        return 0
    fi

    # Verificar permissões
    local permissions=$(stat -c %a "$SECURITY_LOG" 2>/dev/null || stat -f %A "$SECURITY_LOG" 2>/dev/null)
    if [ "$permissions" != "644" ] && [ "$permissions" != "-rw-r--r--" ]; then
        log_warning "Permissões incorretas no arquivo de log: $permissions"
        chmod 644 "$SECURITY_LOG"
    fi

    # Verificar tamanho
    local size=$(stat -f%z "$SECURITY_LOG" 2>/dev/null || stat -c%s "$SECURITY_LOG" 2>/dev/null)
    if [ "$size" -gt "$MAX_LOG_SIZE" ]; then
        log_warning "Arquivo de log muito grande, rotacionando..."
        rotate_logs
    fi

    log_success "Integridade dos logs verificada"
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    # Criar diretórios
    mkdir -p "$LOG_DIR"
    mkdir -p "$ARCHIVE_DIR"
    touch "$SECURITY_LOG"

    local action="${1:-help}"

    case "$action" in
        "collect")
            check_dependencies || exit 1
            local logs=$(collect_auth_logs "${2:-1 hour ago}")
            detect_suspicious_events "$logs"
            analyze_access_patterns "$logs"
            ;;
        "monitor")
            check_dependencies || exit 1
            monitor_system_changes
            ;;
        "rotate")
            rotate_logs
            ;;
        "report")
            check_dependencies || exit 1
            generate_security_report
            ;;
        "verify")
            verify_log_integrity
            ;;
        "realtime")
            check_dependencies || exit 1
            start_real_time_monitoring
            ;;
        "help"|*)
            echo "Cluster AI - Security Logger Script"
            echo ""
            echo "Uso: $0 <ação> [parâmetros]"
            echo ""
            echo "Ações:"
            echo "  collect [time]          - Coletar logs de autenticação"
            echo "  monitor                 - Monitorar mudanças no sistema"
            echo "  rotate                  - Rotacionar logs"
            echo "  report                  - Gerar relatório de segurança"
            echo "  verify                  - Verificar integridade dos logs"
            echo "  realtime                - Monitoramento em tempo real"
            echo "  help                    - Mostra esta mensagem"
            echo ""
            echo "Configurações:"
            echo "  - Retenção de logs: $LOG_RETENTION_DAYS dias"
            echo "  - Tamanho máximo: $MAX_LOG_SIZE"
            echo "  - Compressão: $COMPRESSION_ENABLED"
            echo "  - Monitoramento RT: $REAL_TIME_MONITORING"
            echo "  - Alertas suspeitas: $ALERT_ON_SUSPICIOUS"
            echo ""
            echo "Exemplos:"
            echo "  $0 collect '2 hours ago'"
            echo "  $0 monitor"
            echo "  $0 report"
            echo "  $0 realtime"
            ;;
    esac
}

# Executar função principal
main "$@"
