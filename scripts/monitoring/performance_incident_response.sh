#!/bin/bash
# Sistema de Resposta a Incidentes de Performance
# Detecta degradação, executa recuperação automática e gerencia incidentes

set -euo pipefail

# ==================== CONFIGURAÇÃO ====================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_DIR="${PROJECT_ROOT}/config"
LOGS_DIR="${PROJECT_ROOT}/logs"
ALERTS_DIR="${PROJECT_ROOT}/alerts"
INCIDENTS_DIR="${PROJECT_ROOT}/incidents"

# Arquivos de configuração
INCIDENT_CONFIG="${CONFIG_DIR}/incident_response.conf"
RECOVERY_CONFIG="${CONFIG_DIR}/recovery_actions.conf"

# Arquivos de dados
INCIDENT_LOG="${LOGS_DIR}/incident_response.log"
ACTIVE_INCIDENTS="${INCIDENTS_DIR}/active_incidents.json"
INCIDENT_HISTORY="${INCIDENTS_DIR}/incident_history.log"
RECOVERY_LOG="${LOGS_DIR}/recovery_actions.log"

# Configurações de incidentes
INCIDENT_CHECK_INTERVAL=30  # segundos
RECOVERY_TIMEOUT=300  # 5 minutos
MAX_RECOVERY_ATTEMPTS=3
ESCALATION_TIMEOUT=600  # 10 minutos

# Thresholds de degradação (em % de mudança)
DEGRADATION_CPU_THRESHOLD=50
DEGRADATION_MEMORY_THRESHOLD=40
DEGRADATION_DISK_THRESHOLD=30
DEGRADATION_RESPONSE_TIME_THRESHOLD=100

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# ==================== VARIÁVEIS DE ESTADO ====================

# Estado dos incidentes
declare -A ACTIVE_INCIDENTS_MAP
declare -A INCIDENT_SEVERITY
declare -A INCIDENT_START_TIME
declare -A INCIDENT_RECOVERY_ATTEMPTS

# ==================== FUNÇÕES UTILITÁRIAS ====================

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$INCIDENT_LOG"
}

error() {
    echo -e "${RED}❌ $1${NC}" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$INCIDENT_LOG"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$INCIDENT_LOG"
}

success() {
    echo -e "${GREEN}✅ $1${NC}" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$INCIDENT_LOG"
}

info() {
    echo -e "${CYAN}ℹ️  $1${NC}" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$INCIDENT_LOG"
}

# ==================== FUNÇÕES DE DETECÇÃO DE DEGRADAÇÃO ====================

# Detectar degradação de performance
detect_performance_degradation() {
    local current_metrics="$1"
    local baseline_metrics="$2"

    IFS=',' read -r curr_cpu curr_mem curr_disk curr_load curr_tasks <<< "$current_metrics"
    IFS=',' read -r base_cpu base_mem base_disk base_load base_tasks <<< "$baseline_metrics"

    local degradation_detected=false
    local degradation_details=""

    # Verificar degradação de CPU
    if [ -n "$base_cpu" ] && (( $(echo "$base_cpu > 0" | bc -l 2>/dev/null || echo "0") )); then
        local cpu_change
        cpu_change=$(echo "scale=2; (($curr_cpu - $base_cpu) / $base_cpu) * 100" | bc 2>/dev/null || echo "0")

        if (( $(echo "$cpu_change > $DEGRADATION_CPU_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
            degradation_detected=true
            degradation_details="${degradation_details}CPU:+${cpu_change}%;"
        fi
    fi

    # Verificar degradação de memória
    if [ -n "$base_mem" ] && (( $(echo "$base_mem > 0" | bc -l 2>/dev/null || echo "0") )); then
        local mem_change
        mem_change=$(echo "scale=2; (($curr_mem - $base_mem) / $base_mem) * 100" | bc 2>/dev/null || echo "0")

        if (( $(echo "$mem_change > $DEGRADATION_MEMORY_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
            degradation_detected=true
            degradation_details="${degradation_details}MEM:+${mem_change}%;"
        fi
    fi

    # Verificar degradação de disco
    if [ -n "$base_disk" ] && (( $(echo "$base_disk > 0" | bc -l 2>/dev/null || echo "0") )); then
        local disk_change
        disk_change=$(echo "scale=2; (($curr_disk - $base_disk) / $base_disk) * 100" | bc 2>/dev/null || echo "0")

        if (( $(echo "$disk_change > $DEGRADATION_DISK_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
            degradation_detected=true
            degradation_details="${degradation_details}DISK:+${disk_change}%;"
        fi
    fi

    if [ "$degradation_detected" = true ]; then
        echo "DEGRADATION_DETECTED:$degradation_details"
    else
        echo "NORMAL"
    fi
}

# Calcular baseline de performance
calculate_performance_baseline() {
    local history_file="${PROJECT_ROOT}/metrics/history/performance_history.csv"

    if [ ! -f "$history_file" ]; then
        echo "0,0,0,0,0"
        return
    fi

    # Calcular média das últimas 24 horas (assumindo coleta a cada 5 minutos = 288 entradas)
    local recent_data
    recent_data=$(tail -n 288 "$history_file" 2>/dev/null | head -n -1 || tail -n 50 "$history_file" 2>/dev/null | head -n -1 || echo "")

    if [ -z "$recent_data" ]; then
        echo "0,0,0,0,0"
        return
    fi

    # Calcular médias
    local cpu_sum=0 mem_sum=0 disk_sum=0 load_sum=0 tasks_sum=0 count=0

    while IFS=',' read -r timestamp cpu mem disk network_rx network_tx load temp; do
        if [ "$timestamp" != "timestamp" ] && [ -n "$cpu" ]; then
            cpu_sum=$(echo "$cpu_sum + $cpu" | bc 2>/dev/null || echo "$cpu_sum")
            mem_sum=$(echo "$mem_sum + $mem" | bc 2>/dev/null || echo "$mem_sum")
            disk_sum=$(echo "$disk_sum + $disk" | bc 2>/dev/null || echo "$disk_sum")
            load_sum=$(echo "$load_sum + $load" | bc 2>/dev/null || echo "$load_sum")
            tasks_sum=$(echo "$tasks_sum + $network_rx" | bc 2>/dev/null || echo "$tasks_sum")  # Usando network_rx como proxy para tasks
            ((count++))
        fi
    done <<< "$recent_data"

    if [ $count -gt 0 ]; then
        local avg_cpu avg_mem avg_disk avg_load avg_tasks
        avg_cpu=$(echo "scale=2; $cpu_sum / $count" | bc 2>/dev/null || echo "0")
        avg_mem=$(echo "scale=2; $mem_sum / $count" | bc 2>/dev/null || echo "0")
        avg_disk=$(echo "scale=2; $disk_sum / $count" | bc 2>/dev/null || echo "0")
        avg_load=$(echo "scale=2; $load_sum / $count" | bc 2>/dev/null || echo "0")
        avg_tasks=$(echo "scale=2; $tasks_sum / $count" | bc 2>/dev/null || echo "0")

        echo "$avg_cpu,$avg_mem,$avg_disk,$avg_load,$avg_tasks"
    else
        echo "0,0,0,0,0"
    fi
}

# ==================== FUNÇÕES DE GERENCIAMENTO DE INCIDENTES ====================

# Criar novo incidente
create_incident() {
    local incident_type="$1"
    local severity="$2"
    local description="$3"
    local details="$4"

    local incident_id="INC-$(date +%s)-$RANDOM"
    local current_time=$(date +%s)

    # Registrar incidente
    ACTIVE_INCIDENTS_MAP["$incident_id"]=1
    INCIDENT_SEVERITY["$incident_id"]="$severity"
    INCIDENT_START_TIME["$incident_id"]=$current_time
    INCIDENT_RECOVERY_ATTEMPTS["$incident_id"]=0

    # Log do incidente
    log "INCIDENTE CRIADO: $incident_id"
    log "Tipo: $incident_type"
    log "Severidade: $severity"
    log "Descrição: $description"
    log "Detalhes: $details"

    # Salvar em arquivo de incidentes ativos
    save_active_incidents

    # Criar arquivo detalhado do incidente
    local incident_file="${INCIDENTS_DIR}/incident_${incident_id}.json"
    cat > "$incident_file" << EOF
{
  "id": "$incident_id",
  "type": "$incident_type",
  "severity": "$severity",
  "description": "$description",
  "details": "$details",
  "created_at": $current_time,
  "status": "ACTIVE",
  "recovery_attempts": 0,
  "escalation_time": $((current_time + ESCALATION_TIMEOUT)),
  "timeline": [
    {
      "timestamp": $current_time,
      "event": "Incident created",
      "details": "$description"
    }
  ]
}
EOF

    # Alertar sobre incidente crítico
    if [ "$severity" = "CRITICAL" ]; then
        send_critical_alert "$incident_id" "$description" "$details"
    fi

    echo "$incident_id"
}

# Atualizar incidente
update_incident() {
    local incident_id="$1"
    local event="$2"
    local details="$3"

    if [ -z "${ACTIVE_INCIDENTS_MAP[$incident_id]}" ]; then
        warning "Incidente não encontrado: $incident_id"
        return
    fi

    local current_time=$(date +%s)
    local incident_file="${INCIDENTS_DIR}/incident_${incident_id}.json"

    # Adicionar evento à timeline
    if [ -f "$incident_file" ]; then
        # Adicionar à timeline (simplificado - em produção usaria jq)
        sed -i "s/\"timeline\": \[/\"timeline\": [\n    {\n      \"timestamp\": $current_time,\n      \"event\": \"$event\",\n      \"details\": \"$details\"\n    },/" "$incident_file"
    fi

    log "INCIDENTE ATUALIZADO: $incident_id - $event"
}

# Resolver incidente
resolve_incident() {
    local incident_id="$1"
    local resolution="$2"

    if [ -z "${ACTIVE_INCIDENTS_MAP[$incident_id]}" ]; then
        warning "Incidente não encontrado: $incident_id"
        return
    fi

    local current_time=$(date +%s)
    local duration=$((current_time - INCIDENT_START_TIME[$incident_id]))

    # Atualizar status
    update_incident "$incident_id" "RESOLVED" "$resolution"

    # Mover para histórico
    echo "[$current_time] RESOLVED: $incident_id - Duration: ${duration}s - Resolution: $resolution" >> "$INCIDENT_HISTORY"

    # Remover dos incidentes ativos
    unset ACTIVE_INCIDENTS_MAP["$incident_id"]
    unset INCIDENT_SEVERITY["$incident_id"]
    unset INCIDENT_START_TIME["$incident_id"]
    unset INCIDENT_RECOVERY_ATTEMPTS["$incident_id"]

    save_active_incidents

    success "Incidente resolvido: $incident_id ($resolution)"
}

# Escalar incidente
escalate_incident() {
    local incident_id="$1"
    local reason="$2"

    update_incident "$incident_id" "ESCALATED" "$reason"

    # Enviar alerta de escalação
    send_escalation_alert "$incident_id" "$reason"

    log "INCIDENTE ESCALADO: $incident_id - $reason"
}

# Salvar incidentes ativos
save_active_incidents() {
    local json_content="{"

    for incident_id in "${!ACTIVE_INCIDENTS_MAP[@]}"; do
        if [ -n "$json_content" ] && [ "$json_content" != "{" ]; then
            json_content="${json_content},"
        fi
        json_content="${json_content}\"${incident_id}\":{\"severity\":\"${INCIDENT_SEVERITY[$incident_id]}\",\"start_time\":${INCIDENT_START_TIME[$incident_id]},\"recovery_attempts\":${INCIDENT_RECOVERY_ATTEMPTS[$incident_id]}}"
    done

    json_content="${json_content}}"

    echo "$json_content" > "$ACTIVE_INCIDENTS"
}

# Carregar incidentes ativos
load_active_incidents() {
    if [ ! -f "$ACTIVE_INCIDENTS" ]; then
        return
    fi

    # Carregar incidentes do JSON (simplificado)
    while IFS=':' read -r incident_id data; do
        incident_id=$(echo "$incident_id" | tr -d '"{')
        if [ -n "$incident_id" ] && [ "$incident_id" != "}" ]; then
            ACTIVE_INCIDENTS_MAP["$incident_id"]=1

            # Extrair dados (simplificado)
            severity=$(echo "$data" | grep -o '"severity":"[^"]*"' | cut -d'"' -f4 || echo "WARNING")
            start_time=$(echo "$data" | grep -o '"start_time":[0-9]*' | cut -d':' -f2 || echo "0")
            recovery_attempts=$(echo "$data" | grep -o '"recovery_attempts":[0-9]*' | cut -d':' -f2 || echo "0")

            INCIDENT_SEVERITY["$incident_id"]="$severity"
            INCIDENT_START_TIME["$incident_id"]=$start_time
            INCIDENT_RECOVERY_ATTEMPTS["$incident_id"]=$recovery_attempts
        fi
    done < <(grep -v '^}$' "$ACTIVE_INCIDENTS" | tr -d ' ' | tr '}' '\n')
}

# ==================== FUNÇÕES DE RECUPERAÇÃO AUTOMÁTICA ====================

# Executar ações de recuperação
execute_recovery_actions() {
    local incident_id="$1"
    local incident_type="$2"
    local severity="$3"

    local attempt=$((INCIDENT_RECOVERY_ATTEMPTS[$incident_id] + 1))
    INCIDENT_RECOVERY_ATTEMPTS[$incident_id]=$attempt

    update_incident "$incident_id" "RECOVERY_ATTEMPT" "Attempt $attempt"

    log "EXECUTANDO RECUPERAÇÃO: $incident_id (Tentativa $attempt)"

    case "$incident_type" in
        "PERFORMANCE_DEGRADATION")
            recover_performance_degradation "$incident_id" "$severity" "$attempt"
            ;;
        "MEMORY_LEAK")
            recover_memory_leak "$incident_id" "$severity" "$attempt"
            ;;
        "HIGH_CPU")
            recover_high_cpu "$incident_id" "$severity" "$attempt"
            ;;
        "DISK_IO_HIGH")
            recover_disk_io_high "$incident_id" "$severity" "$attempt"
            ;;
        *)
            warning "Tipo de incidente não suportado para recuperação automática: $incident_type"
            ;;
    esac

    save_active_incidents
}

# Recuperação de degradação de performance
recover_performance_degradation() {
    local incident_id="$1"
    local severity="$2"
    local attempt="$3"

    log "Recuperação de degradação de performance (Tentativa $attempt)"

    case "$attempt" in
        1)
            # Tentativa 1: Reiniciar serviços não críticos
            log "Tentativa 1: Reiniciando serviços não críticos"
            restart_non_critical_services
            ;;
        2)
            # Tentativa 2: Limpar cache e reiniciar
            log "Tentativa 2: Limpando cache e reiniciando serviços"
            clear_system_cache
            restart_services
            ;;
        3)
            # Tentativa 3: Scale up e reinício completo
            log "Tentativa 3: Scale up e reinício completo do sistema"
            trigger_emergency_scale_up
            full_system_restart
            ;;
    esac
}

# Recuperação de vazamento de memória
recover_memory_leak() {
    local incident_id="$1"
    local severity="$2"
    local attempt="$3"

    log "Recuperação de vazamento de memória (Tentativa $attempt)"

    case "$attempt" in
        1)
            # Liberar memória cache
            log "Liberando memória cache do sistema"
            echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
            ;;
        2)
            # Reiniciar processos com alto consumo
            log "Reiniciando processos com alto consumo de memória"
            restart_high_memory_processes
            ;;
        3)
            # Reinício completo do sistema
            log "Reinício completo do sistema devido a vazamento de memória"
            full_system_restart
            ;;
    esac
}

# Recuperação de CPU alta
recover_high_cpu() {
    local incident_id="$1"
    local severity="$2"
    local attempt="$3"

    log "Recuperação de CPU alta (Tentativa $attempt)"

    case "$attempt" in
        1)
            # Ajustar prioridade de processos
            log "Ajustando prioridade de processos CPU-intensive"
            renice_high_cpu_processes
            ;;
        2)
            # Scale up workers
            log "Executando scale up de workers"
            trigger_scale_up
            ;;
        3)
            # Reinício de serviços problemáticos
            log "Reiniciando serviços com alto consumo de CPU"
            restart_high_cpu_services
            ;;
    esac
}

# Recuperação de I/O de disco alta
recover_disk_io_high() {
    local incident_id="$1"
    local severity="$2"
    local attempt="$3"

    log "Recuperação de I/O de disco alta (Tentativa $attempt)"

    case "$attempt" in
        1)
            # Otimizar I/O
            log "Otimizando configurações de I/O"
            optimize_io_settings
            ;;
        2)
            # Mover dados para memória/disco mais rápido
            log "Movendo dados para armazenamento mais rápido"
            move_data_to_faster_storage
            ;;
        3)
            # Scale out para distribuir carga
            log "Distribuindo carga entre múltiplos nós"
            trigger_scale_out
            ;;
    esac
}

# ==================== FUNÇÕES DE SERVIÇOS ====================

# Reiniciar serviços não críticos
restart_non_critical_services() {
    log "Reiniciando serviços não críticos..."

    # Lista de serviços não críticos (ajuste conforme necessário)
    local non_critical_services=("apache2" "nginx" "mysql" "postgresql")

    for service in "${non_critical_services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log "Reiniciando serviço: $service"
            systemctl restart "$service" 2>/dev/null || true
        fi
    done
}

# Limpar cache do sistema
clear_system_cache() {
    log "Limpando cache do sistema..."

    # Limpar cache de pacotes
    if command -v apt-get >/dev/null 2>&1; then
        apt-get clean >/dev/null 2>&1 || true
    fi

    # Limpar cache do Python
    find /tmp -name "*.pyc" -delete 2>/dev/null || true
    find /tmp -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

    # Limpar cache de aplicações
    rm -rf /tmp/* 2>/dev/null || true
}

# Reiniciar serviços
restart_services() {
    log "Reiniciando serviços principais..."

    # Reiniciar serviços do cluster
    if pgrep -f "dask-scheduler" >/dev/null 2>&1; then
        log "Reiniciando Dask scheduler"
        pkill -f "dask-scheduler" 2>/dev/null || true
        sleep 2
        # Reiniciar scheduler (ajuste o comando conforme sua configuração)
        # dask-scheduler --host 0.0.0.0 --port 8786 &
    fi

    if pgrep -f "ollama" >/dev/null 2>&1; then
        log "Reiniciando Ollama"
        pkill -f "ollama" 2>/dev/null || true
        sleep 2
        # Reiniciar Ollama (ajuste conforme necessário)
        # ollama serve &
    fi
}

# Reinício completo do sistema
full_system_restart() {
    log "Executando reinício completo do sistema..."

    # Criar snapshot antes do reinício (se disponível)
    create_system_snapshot

    # Aguardar um pouco antes do reinício
    warning "Reinício completo do sistema em 30 segundos..."
    sleep 30

    # Reiniciar sistema
    if command -v systemctl >/dev/null 2>&1; then
        systemctl reboot
    else
        reboot
    fi
}

# ==================== FUNÇÕES DE ALERTAS ====================

# Enviar alerta crítico
send_critical_alert() {
    local incident_id="$1"
    local description="$2"
    local details="$3"

    log "ENVIANDO ALERTA CRÍTICO: $incident_id"

    # Aqui você pode integrar com sistemas de alerta externos
    # Exemplo: Slack, email, PagerDuty, etc.

    # Por enquanto, apenas log detalhado
    {
        echo "🚨 ALERTA CRÍTICO DE PERFORMANCE 🚨"
        echo "ID do Incidente: $incident_id"
        echo "Descrição: $description"
        echo "Detalhes: $details"
        echo "Timestamp: $(date)"
        echo ""
        echo "Ação necessária: Verificar sistema imediatamente"
    } >> "${ALERTS_DIR}/critical_alerts.log"
}

# Enviar alerta de escalação
send_escalation_alert() {
    local incident_id="$1"
    local reason="$2"

    log "ENVIANDO ALERTA DE ESCALAÇÃO: $incident_id"

    # Alerta de escalação para equipe de resposta
    {
        echo "⚠️ ESCALAÇÃO DE INCIDENTE ⚠️"
        echo "ID do Incidente: $incident_id"
        echo "Motivo da Escalação: $reason"
        echo "Timestamp: $(date)"
        echo ""
        echo "Ação: Equipe de resposta deve intervir imediatamente"
    } >> "${ALERTS_DIR}/escalation_alerts.log"
}

# ==================== FUNÇÕES PLACEHOLDER ====================

# Placeholders para funções específicas (implementar conforme necessário)
renice_high_cpu_processes() { log "Função renice_high_cpu_processes não implementada"; }
restart_high_memory_processes() { log "Função restart_high_memory_processes não implementada"; }
trigger_emergency_scale_up() { log "Função trigger_emergency_scale_up não implementada"; }
create_system_snapshot() { log "Função create_system_snapshot não implementada"; }
restart_high_cpu_services() { log "Função restart_high_cpu_services não implementada"; }
optimize_io_settings() { log "Função optimize_io_settings não implementada"; }
move_data_to_faster_storage() { log "Função move_data_to_faster_storage não implementada"; }
trigger_scale_out() { log "Função trigger_scale_out não implementada"; }
trigger_scale_up() { log "Função trigger_scale_up não implementada"; }

# ==================== FUNÇÃO PRINCIPAL ====================

main() {
    case "${1:-monitor}" in
        init)
            # Criar diretórios necessários
            mkdir -p "$INCIDENTS_DIR" "$ALERTS_DIR"

            # Inicializar arquivos
            touch "$INCIDENT_LOG" "$RECOVERY_LOG" "$INCIDENT_HISTORY"

            success "Sistema de resposta a incidentes inicializado"
            ;;
        monitor)
            log "Iniciando monitoramento de incidentes..."

            # Carregar incidentes ativos
            load_active_incidents

            # Calcular baseline inicial
            local baseline_metrics
            baseline_metrics=$(calculate_performance_baseline)
            log "Baseline calculado: $baseline_metrics"

            while true; do
                # Coletar métricas atuais
                local current_metrics
                current_metrics=$(collect_current_metrics)

                # Detectar degradação
                local degradation_result
                degradation_result=$(detect_performance_degradation "$current_metrics" "$baseline_metrics")

                if [[ $degradation_result == DEGRADATION_DETECTED:* ]]; then
                    local details=${degradation_result#DEGRADATION_DETECTED:}

                    # Criar incidente
                    local incident_id
                    incident_id=$(create_incident "PERFORMANCE_DEGRADATION" "WARNING" "Performance degradation detected" "$details")

                    # Executar recuperação automática
                    execute_recovery_actions "$incident_id" "PERFORMANCE_DEGRADATION" "WARNING"
                fi

                # Verificar escalação de incidentes ativos
                check_incident_escalation

                # Aguardar próximo ciclo
                sleep "$INCIDENT_CHECK_INTERVAL"
            done
            ;;
        list)
            echo "=== INCIDENTES ATIVOS ==="
            for incident_id in "${!ACTIVE_INCIDENTS_MAP[@]}"; do
                echo "ID: $incident_id"
                echo "  Severidade: ${INCIDENT_SEVERITY[$incident_id]}"
                echo "  Início: $(date -d "@${INCIDENT_START_TIME[$incident_id]}" 2>/dev/null || echo "Unknown")"
                echo "  Tentativas de Recuperação: ${INCIDENT_RECOVERY_ATTEMPTS[$incident_id]}"
                echo ""
            done
            ;;
        resolve)
            if [ -z "${2:-}" ]; then
                error "ID do incidente necessário"
                exit 1
            fi
            resolve_incident "$2" "Resolvido manualmente"
            ;;
        report)
            generate_incident_report
            ;;
        *)
            echo "Uso: $0 [init|monitor|list|resolve <id>|report]"
            echo ""
            echo "Comandos:"
            echo "  init     - Inicializar sistema"
            echo "  monitor  - Iniciar monitoramento"
            echo "  list     - Listar incidentes ativos"
            echo "  resolve  - Resolver incidente manualmente"
            echo "  report   - Gerar relatório de incidentes"
            ;;
    esac
}

# Função auxiliar para coletar métricas (igual ao auto-scaling)
collect_current_metrics() {
    # CPU
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' | xargs printf "%.2f")

    # Memória
    local memory_usage
    memory_usage=$(free | awk 'NR==2{printf "%.2f", $3*100/$2}')

    # Disco
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//' | xargs printf "%.2f")

    # Load Average
    local load_avg
    load_avg=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)

    # Tarefas ativas (simplificado)
    local active_tasks=0
    if pgrep -f "dask-scheduler\|dask-worker" >/dev/null 2>&1; then
        active_tasks=$(pgrep -f "dask-worker" | wc -l)
    fi

    echo "$cpu_usage,$memory_usage,$disk_usage,$load_avg,$active_tasks"
}

# Verificar escalação de incidentes
check_incident_escalation() {
    local current_time=$(date +%s)

    for incident_id in "${!ACTIVE_INCIDENTS_MAP[@]}"; do
        local start_time=${INCIDENT_START_TIME[$incident_id]}
        local time_elapsed=$((current_time - start_time))

        # Escalar se passou do tempo limite
        if [ $time_elapsed -gt $ESCALATION_TIMEOUT ]; then
            escalate_incident "$incident_id" "Timeout de resolução excedido (${time_elapsed}s > ${ESCALATION_TIMEOUT}s)"
        fi

        # Escalar se muitas tentativas de recuperação falharam
        if [ ${INCIDENT_RECOVERY_ATTEMPTS[$incident_id]} -ge $MAX_RECOVERY_ATTEMPTS ]; then
            escalate_incident "$incident_id" "Máximo de tentativas de recuperação atingido (${INCIDENT_RECOVERY_ATTEMPTS[$incident_id]})"
        fi
    done
}

# Gerar relatório de incidentes
generate_incident_report() {
    local report_file="${LOGS_DIR}/incident_report_$(date +%Y%m%d_%H%M%S).txt"

    log "Gerando relatório de incidentes..."

    {
        echo "=== RELATÓRIO DE INCIDENTES ==="
        echo "Gerado em: $(date)"
        echo ""

        echo "INCIDENTES ATIVOS:"
        echo "-------------------"
        local active_count=0
        for incident_id in "${!ACTIVE_INCIDENTS_MAP[@]}"; do
            echo "ID: $incident_id"
            echo "  Severidade: ${INCIDENT_SEVERITY[$incident_id]}"
            echo "  Duração: $(( $(date +%s) - INCIDENT_START_TIME[$incident_id] ))s"
            echo "  Tentativas de Recuperação: ${INCIDENT_RECOVERY_ATTEMPTS[$incident_id]}"
            echo ""
            ((active_count++))
        done

        if [ $active_count -eq 0 ]; then
            echo "Nenhum incidente ativo"
            echo ""
        fi

        echo "HISTÓRICO RECENTE:"
        echo "------------------"
        if [ -f "$INCIDENT_HISTORY" ]; then
            tail -n 10 "$INCIDENT_HISTORY" | while read -r line; do
                echo "  $line"
            done
        else
            echo "Nenhum histórico disponível"
        fi

        echo ""
        echo "ESTATÍSTICAS:"
        echo "-------------"
        echo "Incidentes ativos: $active_count"
        echo "Total no histórico: $(wc -l < "$INCIDENT_HISTORY" 2>/dev/null || echo "0")"

    } > "$report_file"

    success "Relatório gerado: $report_file"
}

# Executar função principal
main "$@"
