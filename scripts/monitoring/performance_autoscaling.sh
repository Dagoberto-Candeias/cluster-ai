#!/bin/bash
# Sistema de Auto-Scaling Baseado em Performance
# Monitora métricas e executa ações de scaling automaticamente

set -euo pipefail

# ==================== CONFIGURAÇÃO ====================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_DIR="${PROJECT_ROOT}/config"
LOGS_DIR="${PROJECT_ROOT}/logs"
METRICS_DIR="${PROJECT_ROOT}/metrics"

# Arquivos de configuração
AUTOSCALING_CONFIG="${CONFIG_DIR}/autoscaling.conf"
PERFORMANCE_THRESHOLDS="${CONFIG_DIR}/performance_thresholds.conf"

# Arquivos de log e estado
AUTOSCALING_LOG="${LOGS_DIR}/autoscaling.log"
SCALING_STATE="${METRICS_DIR}/scaling_state.json"
PERFORMANCE_HISTORY="${METRICS_DIR}/history/performance_history.csv"

# Configurações de auto-scaling
MONITOR_INTERVAL=60  # segundos
EVALUATION_WINDOW=300  # 5 minutos
COOLDOWN_PERIOD=600  # 10 minutos

# Thresholds para scaling (podem ser sobrescritos pelo config)
CPU_SCALE_UP_THRESHOLD=75
CPU_SCALE_DOWN_THRESHOLD=30
MEMORY_SCALE_UP_THRESHOLD=80
MEMORY_SCALE_DOWN_THRESHOLD=40
DISK_SCALE_UP_THRESHOLD=85

# Configurações de scaling
MAX_WORKERS=10
MIN_WORKERS=1
SCALE_UP_FACTOR=1.5
SCALE_DOWN_FACTOR=0.7

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ==================== VARIÁVEIS DE ESTADO ====================

# Estado atual do sistema
CURRENT_WORKERS=1
LAST_SCALE_TIME=0
SCALE_IN_PROGRESS=false

# ==================== FUNÇÕES UTILITÁRIAS ====================

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$AUTOSCALING_LOG"
}

error() {
    echo -e "${RED}❌ $1${NC}" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$AUTOSCALING_LOG"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$AUTOSCALING_LOG"
}

success() {
    echo -e "${GREEN}✅ $1${NC}" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$AUTOSCALING_LOG"
}

info() {
    echo -e "${CYAN}ℹ️  $1${NC}" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$AUTOSCALING_LOG"
}

# ==================== FUNÇÕES DE CONFIGURAÇÃO ====================

# Carregar configurações
load_config() {
    if [ -f "$AUTOSCALING_CONFIG" ]; then
        source "$AUTOSCALING_CONFIG"
        log "Configurações de auto-scaling carregadas de $AUTOSCALING_CONFIG"
    else
        warning "Arquivo de configuração não encontrado: $AUTOSCALING_CONFIG"
        create_default_config
    fi

    if [ -f "$PERFORMANCE_THRESHOLDS" ]; then
        source "$PERFORMANCE_THRESHOLDS"
        log "Thresholds de performance carregados de $PERFORMANCE_THRESHOLDS"
    fi
}

# Criar configuração padrão
create_default_config() {
    log "Criando configuração padrão de auto-scaling..."

    cat > "$AUTOSCALING_CONFIG" << EOF
# Configuração de Auto-Scaling para Cluster AI

# Thresholds para scaling
CPU_SCALE_UP_THRESHOLD=75
CPU_SCALE_DOWN_THRESHOLD=30
MEMORY_SCALE_UP_THRESHOLD=80
MEMORY_SCALE_DOWN_THRESHOLD=40
DISK_SCALE_UP_THRESHOLD=85

# Configurações de workers
MAX_WORKERS=10
MIN_WORKERS=1
SCALE_UP_FACTOR=1.5
SCALE_DOWN_FACTOR=0.7

# Intervalos de monitoramento
MONITOR_INTERVAL=60
EVALUATION_WINDOW=300
COOLDOWN_PERIOD=600

# Configurações específicas do cluster
CLUSTER_TYPE="dask"
SCHEDULER_ADDRESS="tls://192.168.0.2:8786"
WORKER_IMAGE="dask-worker:latest"
EOF

    success "Configuração padrão criada: $AUTOSCALING_CONFIG"
}

# ==================== FUNÇÕES DE MONITORAMENTO ====================

# Coletar métricas atuais
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

    # Número de tarefas ativas (se Dask estiver rodando)
    local active_tasks=0
    if pgrep -f "dask-scheduler\|dask-worker" >/dev/null 2>&1; then
        # Tentar obter métricas do Dask (simplificado)
        active_tasks=$(python3 -c "
import sys
try:
    from dask.distributed import Client
    client = Client('$SCHEDULER_ADDRESS', timeout='2s')
    info = client.scheduler_info()
    tasks = [t for t in info.get('tasks', {}).values() if t.get('state') in ['processing', 'memory']]
    print(len(tasks))
    client.close()
except:
    print('0')
" 2>/dev/null || echo "0")
    fi

    echo "$cpu_usage,$memory_usage,$disk_usage,$load_avg,$active_tasks"
}

# Avaliar necessidade de scaling baseada em histórico
evaluate_scaling_need() {
    local current_metrics="$1"
    IFS=',' read -r cpu_usage memory_usage disk_usage load_avg active_tasks <<< "$current_metrics"

    # Verificar cooldown
    local current_time=$(date +%s)
    if [ $((current_time - LAST_SCALE_TIME)) -lt $COOLDOWN_PERIOD ]; then
        log "Em período de cooldown, pulando avaliação"
        echo "NO_SCALE"
        return
    fi

    # Verificar se já existe scaling em andamento
    if [ "$SCALE_IN_PROGRESS" = true ]; then
        log "Scaling já em andamento, pulando avaliação"
        echo "NO_SCALE"
        return
    fi

    # Avaliar condições de scale up
    local scale_up_reasons=""
    local scale_down_reasons=""

    # CPU alta
    if (( $(echo "$cpu_usage > $CPU_SCALE_UP_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        scale_up_reasons="${scale_up_reasons}CPU:${cpu_usage}%;"
    fi

    # Memória alta
    if (( $(echo "$memory_usage > $MEMORY_SCALE_UP_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        scale_up_reasons="${scale_up_reasons}MEM:${memory_usage}%;"
    fi

    # Disco alto
    if (( $(echo "$disk_usage > $DISK_SCALE_UP_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        scale_up_reasons="${scale_up_reasons}DISK:${disk_usage}%;"
    fi

    # Load average alta
    if (( $(echo "$load_avg > $CURRENT_WORKERS * 1.5" | bc -l 2>/dev/null || echo "0") )); then
        scale_up_reasons="${scale_up_reasons}LOAD:${load_avg};"
    fi

    # Avaliar condições de scale down
    # CPU baixa
    if (( $(echo "$cpu_usage < $CPU_SCALE_DOWN_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        scale_down_reasons="${scale_down_reasons}CPU:${cpu_usage}%;"
    fi

    # Memória baixa
    if (( $(echo "$memory_usage < $MEMORY_SCALE_DOWN_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        scale_down_reasons="${scale_down_reasons}MEM:${memory_usage}%;"
    fi

    # Múltiplas condições de scale up = SCALE_UP
    if [ -n "$scale_up_reasons" ]; then
        echo "SCALE_UP:$scale_up_reasons"
        return
    fi

    # Múltiplas condições de scale down = SCALE_DOWN
    if [ -n "$scale_down_reasons" ]; then
        echo "SCALE_DOWN:$scale_down_reasons"
        return
    fi

    echo "NO_SCALE"
}

# ==================== FUNÇÕES DE SCALING ====================

# Executar scale up
execute_scale_up() {
    local reasons="$1"
    local new_worker_count

    # Calcular novo número de workers
    new_worker_count=$(echo "scale=0; $CURRENT_WORKERS * $SCALE_UP_FACTOR" | bc 2>/dev/null || echo "$CURRENT_WORKERS")
    new_worker_count=$((new_worker_count > MAX_WORKERS ? MAX_WORKERS : new_worker_count))

    if [ "$new_worker_count" -le "$CURRENT_WORKERS" ]; then
        warning "Não é possível aumentar workers (limite atingido: $MAX_WORKERS)"
        return 1
    fi

    info "Executando SCALE UP: $CURRENT_WORKERS -> $new_worker_count workers"
    info "Razões: $reasons"

    SCALE_IN_PROGRESS=true

    # Adicionar workers baseado no tipo de cluster
    case "$CLUSTER_TYPE" in
        dask)
            scale_up_dask_workers "$new_worker_count"
            ;;
        kubernetes)
            scale_up_k8s_workers "$new_worker_count"
            ;;
        docker)
            scale_up_docker_workers "$new_worker_count"
            ;;
        *)
            error "Tipo de cluster não suportado: $CLUSTER_TYPE"
            SCALE_IN_PROGRESS=false
            return 1
            ;;
    esac

    # Atualizar estado
    CURRENT_WORKERS=$new_worker_count
    LAST_SCALE_TIME=$(date +%s)
    SCALE_IN_PROGRESS=false

    success "Scale up concluído: $CURRENT_WORKERS workers ativos"
    return 0
}

# Executar scale down
execute_scale_down() {
    local reasons="$1"
    local new_worker_count

    # Calcular novo número de workers
    new_worker_count=$(echo "scale=0; $CURRENT_WORKERS * $SCALE_DOWN_FACTOR" | bc 2>/dev/null || echo "$CURRENT_WORKERS")
    new_worker_count=$((new_worker_count < MIN_WORKERS ? MIN_WORKERS : new_worker_count))

    if [ "$new_worker_count" -ge "$CURRENT_WORKERS" ]; then
        warning "Não é possível reduzir workers (mínimo atingido: $MIN_WORKERS)"
        return 1
    fi

    info "Executando SCALE DOWN: $CURRENT_WORKERS -> $new_worker_count workers"
    info "Razões: $reasons"

    SCALE_IN_PROGRESS=true

    # Remover workers baseado no tipo de cluster
    case "$CLUSTER_TYPE" in
        dask)
            scale_down_dask_workers "$new_worker_count"
            ;;
        kubernetes)
            scale_down_k8s_workers "$new_worker_count"
            ;;
        docker)
            scale_down_docker_workers "$new_worker_count"
            ;;
        *)
            error "Tipo de cluster não suportado: $CLUSTER_TYPE"
            SCALE_IN_PROGRESS=false
            return 1
            ;;
    esac

    # Atualizar estado
    CURRENT_WORKERS=$new_worker_count
    LAST_SCALE_TIME=$(date +%s)
    SCALE_IN_PROGRESS=false

    success "Scale down concluído: $CURRENT_WORKERS workers ativos"
    return 0
}

# ==================== FUNÇÕES ESPECÍFICAS DO CLUSTER ====================

# Scale up workers Dask
scale_up_dask_workers() {
    local target_count="$1"
    local workers_to_add=$((target_count - CURRENT_WORKERS))

    info "Adicionando $workers_to_add workers Dask..."

    for ((i=1; i<=workers_to_add; i++)); do
        local worker_name="dask-worker-$(date +%s)-$i"

        # Iniciar worker Dask (ajuste conforme sua configuração)
        nohup dask-worker "$SCHEDULER_ADDRESS" \
            --name "$worker_name" \
            --nprocs 1 \
            --nthreads 2 \
            --memory-limit "2GB" \
            >/dev/null 2>&1 &

        log "Worker Dask iniciado: $worker_name"
        sleep 2
    done
}

# Scale down workers Dask
scale_down_dask_workers() {
    local target_count="$1"
    local workers_to_remove=$((CURRENT_WORKERS - target_count))

    info "Removendo $workers_to_remove workers Dask..."

    # Obter lista de workers atuais
    local worker_pids
    worker_pids=$(pgrep -f "dask-worker" | head -n "$workers_to_remove" || true)

    if [ -n "$worker_pids" ]; then
        echo "$worker_pids" | while read -r pid; do
            if [ -n "$pid" ]; then
                kill "$pid" 2>/dev/null || true
                log "Worker Dask removido (PID: $pid)"
            fi
        done
    fi
}

# Scale up workers Kubernetes (placeholder)
scale_up_k8s_workers() {
    local target_count="$1"
    warning "Scale up Kubernetes não implementado ainda"
}

# Scale down workers Kubernetes (placeholder)
scale_down_k8s_workers() {
    local target_count="$1"
    warning "Scale down Kubernetes não implementado ainda"
}

# Scale up workers Docker (placeholder)
scale_up_docker_workers() {
    local target_count="$1"
    warning "Scale up Docker não implementado ainda"
}

# Scale down workers Docker (placeholder)
scale_down_docker_workers() {
    local target_count="$1"
    warning "Scale down Docker não implementado ainda"
}

# ==================== FUNÇÕES DE ESTADO ====================

# Salvar estado atual
save_scaling_state() {
    cat > "$SCALING_STATE" << EOF
{
  "current_workers": $CURRENT_WORKERS,
  "last_scale_time": $LAST_SCALE_TIME,
  "scale_in_progress": $SCALE_IN_PROGRESS,
  "last_update": $(date +%s)
}
EOF
}

# Carregar estado salvo
load_scaling_state() {
    if [ -f "$SCALING_STATE" ]; then
        # Carregar valores do JSON (simplificado)
        CURRENT_WORKERS=$(grep '"current_workers"' "$SCALING_STATE" | cut -d':' -f2 | tr -d ' ,' || echo "1")
        LAST_SCALE_TIME=$(grep '"last_scale_time"' "$SCALING_STATE" | cut -d':' -f2 | tr -d ' ,' || echo "0")
        SCALE_IN_PROGRESS=$(grep '"scale_in_progress"' "$SCALING_STATE" | cut -d':' -f2 | tr -d ' ,' || echo "false")

        log "Estado de scaling carregado: $CURRENT_WORKERS workers"
    else
        log "Nenhum estado salvo encontrado, usando valores padrão"
    fi
}

# ==================== FUNÇÕES DE RELATÓRIOS ====================

# Gerar relatório de auto-scaling
generate_scaling_report() {
    local report_file="${LOGS_DIR}/scaling_report_$(date +%Y%m%d_%H%M%S).txt"

    log "Gerando relatório de auto-scaling..."

    {
        echo "=== RELATÓRIO DE AUTO-SCALING ==="
        echo "Gerado em: $(date)"
        echo ""

        echo "CONFIGURAÇÃO ATUAL:"
        echo "  Workers atuais: $CURRENT_WORKERS"
        echo "  Workers máximo: $MAX_WORKERS"
        echo "  Workers mínimo: $MIN_WORKERS"
        echo "  Tipo de cluster: $CLUSTER_TYPE"
        echo "  Último scaling: $(date -d "@$LAST_SCALE_TIME" 2>/dev/null || echo "Nunca")"
        echo ""

        echo "THRESHOLDS:"
        echo "  CPU Scale Up: ${CPU_SCALE_UP_THRESHOLD}%"
        echo "  CPU Scale Down: ${CPU_SCALE_DOWN_THRESHOLD}%"
        echo "  Memory Scale Up: ${MEMORY_SCALE_UP_THRESHOLD}%"
        echo "  Memory Scale Down: ${MEMORY_SCALE_DOWN_THRESHOLD}%"
        echo "  Disk Scale Up: ${DISK_SCALE_UP_THRESHOLD}%"
        echo ""

        echo "ESTATÍSTICAS RECENTES:"
        if [ -f "$PERFORMANCE_HISTORY" ]; then
            local recent_data
            recent_data=$(tail -n 10 "$PERFORMANCE_HISTORY" 2>/dev/null || echo "")

            if [ -n "$recent_data" ]; then
                echo "Últimas 10 medições de performance:"
                echo "$recent_data" | while read -r line; do
                    echo "  $line"
                done
            fi
        fi
        echo ""

        echo "LOG DE SCALING RECENTE:"
        if [ -f "$AUTOSCALING_LOG" ]; then
            tail -n 20 "$AUTOSCALING_LOG" | while read -r line; do
                echo "  $line"
            done
        fi

    } > "$report_file"

    success "Relatório de auto-scaling gerado: $report_file"
}

# ==================== FUNÇÃO PRINCIPAL ====================

main() {
    case "${1:-monitor}" in
        init)
            load_config
            mkdir -p "$LOGS_DIR" "$METRICS_DIR"
            save_scaling_state
            success "Sistema de auto-scaling inicializado"
            ;;
        monitor)
            load_config
            load_scaling_state

            log "Iniciando monitoramento de auto-scaling..."
            log "Workers atuais: $CURRENT_WORKERS"

            while true; do
                # Coletar métricas
                local metrics
                metrics=$(collect_current_metrics)

                # Avaliar necessidade de scaling
                local scaling_decision
                scaling_decision=$(evaluate_scaling_need "$metrics")

                # Executar scaling se necessário
                case "$scaling_decision" in
                    SCALE_UP:*)
                        local reasons=${scaling_decision#SCALE_UP:}
                        if execute_scale_up "$reasons"; then
                            save_scaling_state
                        fi
                        ;;
                    SCALE_DOWN:*)
                        local reasons=${scaling_decision#SCALE_DOWN:}
                        if execute_scale_down "$reasons"; then
                            save_scaling_state
                        fi
                        ;;
                    NO_SCALE)
                        # Nada a fazer
                        ;;
                esac

                # Aguardar próximo ciclo
                sleep "$MONITOR_INTERVAL"
            done
            ;;
        scale-up)
            load_config
            load_scaling_state
            execute_scale_up "Manual scale up requested"
            save_scaling_state
            ;;
        scale-down)
            load_config
            load_scaling_state
            execute_scale_down "Manual scale down requested"
            save_scaling_state
            ;;
        status)
            load_scaling_state
            echo "=== STATUS DO AUTO-SCALING ==="
            echo "Workers atuais: $CURRENT_WORKERS"
            echo "Último scaling: $(date -d "@$LAST_SCALE_TIME" 2>/dev/null || echo "Nunca")"
            echo "Scaling em andamento: $SCALE_IN_PROGRESS"
            echo "Cooldown até: $(date -d "@$((LAST_SCALE_TIME + COOLDOWN_PERIOD))" 2>/dev/null || echo "N/A")"
            ;;
        report)
            generate_scaling_report
            ;;
        *)
            echo "Uso: $0 [init|monitor|scale-up|scale-down|status|report]"
            echo ""
            echo "Comandos:"
            echo "  init      - Inicializar sistema de auto-scaling"
            echo "  monitor   - Iniciar monitoramento contínuo"
            echo "  scale-up  - Executar scale up manual"
            echo "  scale-down- Executar scale down manual"
            echo "  status    - Mostrar status atual"
            echo "  report    - Gerar relatório de auto-scaling"
            ;;
    esac
}

# Executar função principal
main "$@"
