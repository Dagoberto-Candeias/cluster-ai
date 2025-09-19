#!/bin/bash
# Sistema de Logging de Segurança Aprimorado para Cluster AI

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/cluster.conf"
LOG_DIR="${PROJECT_ROOT}/logs/security"
LOG_FILE="${LOG_DIR}/security.log"
AUDIT_LOG="${LOG_DIR}/audit.log"

# Carregar funções comuns
COMMON_SCRIPT_PATH="${PROJECT_ROOT}/scripts/utils/common.sh"
if [ -f "$COMMON_SCRIPT_PATH" ]; then
    source "$COMMON_SCRIPT_PATH"
else
    # Fallback para cores e logs se common.sh não for encontrado
    RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
    error() { echo -e "${RED}[ERROR]${NC} $1"; }
    warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
    log() { echo -e "${GREEN}[INFO]${NC} $1"; }
    success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
    section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
    confirm_operation() {
        read -p "$1 (s/N): " -n 1 -r; echo
        [[ $REPLY =~ ^[Ss]$ ]]
    }
fi

# Carregar configurações
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Configurações padrão
NODE_IP="${NODE_IP:-192.168.0.2}"
DASK_SCHEDULER_PORT="${DASK_SCHEDULER_PORT:-8786}"
WORKER_MANJARO_IP="${WORKER_MANJARO_IP:-192.168.0.4}"
SECONDARY_IP="${NODE_IP_SECONDARY:-192.168.0.3}"

# Função para inicializar logs de segurança
init_security_logs() {
    section "Inicializando Sistema de Logs de Segurança"

    # Criar diretório de logs se não existir
    mkdir -p "$LOG_DIR"

    # Configurar permissões seguras
    chmod 750 "$LOG_DIR"
    touch "$LOG_FILE" "$AUDIT_LOG"
    chmod 640 "$LOG_FILE" "$AUDIT_LOG"

    log "Diretório de logs criado: $LOG_DIR"
    log "Arquivo de segurança: $LOG_FILE"
    log "Arquivo de auditoria: $AUDIT_LOG"

    success "Sistema de logs inicializado!"
}

# Função para registrar eventos de segurança
log_security_event() {
    local event_type="$1"
    local severity="$2"
    local message="$3"
    local source_ip="${4:-unknown}"
    local user="${5:-system}"

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local hostname=$(hostname)

    # Formatar entrada de log
    local log_entry="$timestamp|$hostname|$event_type|$severity|$source_ip|$user|$message"

    # Escrever no arquivo de log
    echo "$log_entry" >> "$LOG_FILE"

    # Para eventos críticos, também escrever no audit log
    if [[ "$severity" == "CRITICAL" || "$severity" == "HIGH" ]]; then
        echo "$log_entry" >> "$AUDIT_LOG"
    fi

    # Exibir no console se for evento importante
    case "$severity" in
        "CRITICAL")
            error "[$event_type] $message (IP: $source_ip)"
            ;;
        "HIGH")
            warn "[$event_type] $message (IP: $source_ip)"
            ;;
        "MEDIUM")
            log "[$event_type] $message (IP: $source_ip)"
            ;;
    esac
}

# Função para monitorar conexões de rede
monitor_network_connections() {
    section "Monitorando Conexões de Rede"

    log "Verificando conexões ativas nas portas do cluster..."

    # Verificar conexões no scheduler primário
    local scheduler_connections=$(netstat -tlnp 2>/dev/null | grep ":$DASK_SCHEDULER_PORT" | wc -l)
    if [ "$scheduler_connections" -gt 0 ]; then
        log_security_event "NETWORK" "INFO" "Scheduler primário ativo com $scheduler_connections conexões" "$NODE_IP" "system"
    fi

    # Verificar conexões de workers conhecidos
    local worker_connections=$(netstat -tlnp 2>/dev/null | grep -E "($WORKER_MANJARO_IP|$SECONDARY_IP)" | wc -l)
    if [ "$worker_connections" -gt 0 ]; then
        log_security_event "NETWORK" "INFO" "Conexões ativas de workers conhecidos: $worker_connections" "cluster" "system"
    fi

    # Verificar por conexões suspeitas
    local suspicious_connections=$(netstat -tlnp 2>/dev/null | grep -v -E "($NODE_IP|$WORKER_MANJARO_IP|$SECONDARY_IP|127\.0\.0\.1|0\.0\.0\.0)" | wc -l)
    if [ "$suspicious_connections" -gt 0 ]; then
        log_security_event "NETWORK" "HIGH" "Detectadas $suspicious_connections conexões de IPs não autorizados" "unknown" "system"
    fi
}

# Função para monitorar tentativas de acesso
monitor_access_attempts() {
    section "Monitorando Tentativas de Acesso"

    # Verificar logs do sistema para tentativas de acesso negado
    if command -v journalctl >/dev/null 2>&1; then
        local failed_attempts=$(journalctl -u dask-scheduler --since "1 hour ago" 2>/dev/null | grep -i "failed\|denied\|unauthorized" | wc -l)
        if [ "$failed_attempts" -gt 0 ]; then
            log_security_event "ACCESS" "HIGH" "$failed_attempts tentativas de acesso negadas detectadas" "unknown" "system"
        fi
    fi

    # Verificar logs do firewall
    if command -v ufw >/dev/null 2>&1; then
        local blocked_packets=$(ufw status verbose 2>/dev/null | grep -i "blocked" | wc -l)
        if [ "$blocked_packets" -gt 0 ]; then
            log_security_event "FIREWALL" "MEDIUM" "$blocked_packets pacotes bloqueados pelo firewall" "unknown" "system"
        fi
    fi
}

# Função para verificar integridade de arquivos críticos
check_file_integrity() {
    section "Verificando Integridade de Arquivos"

    local critical_files=(
        "$PROJECT_ROOT/cluster.conf"
        "$PROJECT_ROOT/certs/dask_cert.pem"
        "$PROJECT_ROOT/certs/dask_key.pem"
        "$PROJECT_ROOT/scripts/management/failover_scheduler.sh"
        "$PROJECT_ROOT/scripts/security/auth_manager.sh"
    )

    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            local file_perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%A" "$file" 2>/dev/null)
            if [ "$file_perms" != "600" ] && [ "$file_perms" != "640" ]; then
                log_security_event "FILE" "HIGH" "Permissões inseguras no arquivo crítico: $file ($file_perms)" "localhost" "system"
            fi
        else
            log_security_event "FILE" "MEDIUM" "Arquivo crítico não encontrado: $file" "localhost" "system"
        fi
    done
}

# Função para gerar relatório de segurança
generate_security_report() {
    section "Gerando Relatório de Segurança"

    local report_file="${LOG_DIR}/security_report_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "=== RELATÓRIO DE SEGURANÇA - CLUSTER AI ==="
        echo "Data/Hora: $(date)"
        echo "Host: $(hostname)"
        echo ""

        echo "=== ESTATÍSTICAS DE LOGS ==="
        echo "Total de eventos de segurança: $(wc -l < "$LOG_FILE")"
        echo "Eventos de auditoria: $(wc -l < "$AUDIT_LOG")"
        echo ""

        echo "=== ÚLTIMOS EVENTOS CRÍTICOS ==="
        tail -10 "$AUDIT_LOG" 2>/dev/null || echo "Nenhum evento crítico encontrado"
        echo ""

        echo "=== STATUS DO SISTEMA ==="
        echo "Scheduler primário: $(pgrep -f "dask-scheduler" >/dev/null && echo "ATIVO" || echo "INATIVO")"
        echo "Firewall: $(command -v ufw >/dev/null && ufw status | grep -q "active" && echo "ATIVO" || echo "INATIVO")"
        echo "TLS/SSL: $([ -f "$PROJECT_ROOT/certs/dask_cert.pem" ] && echo "CONFIGURADO" || echo "NÃO CONFIGURADO")"
        echo ""

        echo "=== RECOMENDAÇÕES ==="
        if ! pgrep -f "dask-scheduler" >/dev/null; then
            echo "- Scheduler não está rodando - verificar status do serviço"
        fi
        if ! command -v ufw >/dev/null || ! ufw status | grep -q "active"; then
            echo "- Firewall não está ativo - considerar ativação para segurança"
        fi
        if [ ! -f "$PROJECT_ROOT/certs/dask_cert.pem" ]; then
            echo "- Certificados TLS não encontrados - configurar criptografia"
        fi

    } > "$report_file"

    log_security_event "REPORT" "INFO" "Relatório de segurança gerado: $report_file" "localhost" "system"
    success "Relatório salvo em: $report_file"
}

# Função para configurar monitoramento contínuo
setup_continuous_monitoring() {
    section "Configurando Monitoramento Contínuo"

    local cron_job="@hourly $0 monitor"
    local cron_file="/tmp/cluster_security_monitor"

    # Verificar se já existe job no crontab
    if ! crontab -l 2>/dev/null | grep -q "security_logger.sh monitor"; then
        # Adicionar ao crontab
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        log_security_event "CONFIG" "INFO" "Monitoramento contínuo configurado no crontab" "localhost" "system"
        success "Monitoramento contínuo configurado!"
    else
        log "Monitoramento contínuo já está configurado"
    fi
}

# Função principal
main() {
    case "${1:-help}" in
        init)
            init_security_logs
            ;;
        monitor)
            monitor_network_connections
            monitor_access_attempts
            check_file_integrity
            ;;
        report)
            generate_security_report
            ;;
        continuous)
            setup_continuous_monitoring
            ;;
        status)
            section "Status do Sistema de Segurança"
            echo "Diretório de logs: $LOG_DIR"
            echo "Arquivo de segurança: $([ -f "$LOG_FILE" ] && echo "EXISTE ($(wc -l < "$LOG_FILE") linhas)" || echo "NÃO EXISTE")"
            echo "Arquivo de auditoria: $([ -f "$AUDIT_LOG" ] && echo "EXISTE ($(wc -l < "$AUDIT_LOG") linhas)" || echo "NÃO EXISTE")"
            echo ""
            echo "Monitoramento contínuo: $(crontab -l 2>/dev/null | grep -q "security_logger.sh" && echo "ATIVO" || echo "INATIVO")"
            ;;
        *)
            echo "Uso: $0 [init|monitor|report|continuous|status]"
            echo ""
            echo "Comandos:"
            echo "  init       - Inicializar sistema de logs de segurança"
            echo "  monitor    - Executar monitoramento de segurança"
            echo "  report     - Gerar relatório de segurança"
            echo "  continuous - Configurar monitoramento contínuo (crontab)"
            echo "  status     - Mostrar status do sistema de segurança"
            ;;
    esac
}

main "$@"
