#!/bin/bash

# Sistema de Auto-Recuperação do VSCode
# Monitora e recupera automaticamente problemas de performance

set -e

LOG_FILE="/tmp/vscode_auto_recovery.log"
PID_FILE="/tmp/vscode_auto_recovery.pid"
MONITOR_INTERVAL=30
MAX_MEMORY_USAGE=85
MAX_CPU_USAGE=75
MAX_OPEN_FILES=100
RESTART_THRESHOLD=2

# Contadores de problemas
memory_warnings=0
cpu_warnings=0
file_warnings=0
restart_count=0
last_restart_time=0

# Função de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Verificar se já está rodando
is_already_running() {
    if [ -f "$PID_FILE" ]; then
        local existing_pid
        existing_pid=$(cat "$PID_FILE")

        if ps -p "$existing_pid" >/dev/null 2>&1; then
            return 0  # Já está rodando
        else
            # PID file existe mas processo não está rodando
            rm -f "$PID_FILE"
        fi
    fi

    return 1  # Não está rodando
}

# Salvar PID
save_pid() {
    echo $$ > "$PID_FILE"
}

# Limpar PID
cleanup_pid() {
    rm -f "$PID_FILE"
}

# Verificar se VSCode está rodando
is_vscode_running() {
    pgrep -f "code" >/dev/null 2>&1
}

# Obter PID do VSCode
get_vscode_pid() {
    pgrep -f "code" | head -1
}

# Verificar uso de memória do VSCode
check_vscode_memory() {
    local pid
    pid=$(get_vscode_pid)

    if [ -n "$pid" ]; then
        local mem_usage
        mem_usage=$(ps -p "$pid" -o pmem= | tr -d ' ' | head -1)

        if [ -n "$mem_usage" ]; then
            # Converter para número inteiro usando awk
            local mem_int
            mem_int=$(echo "$mem_usage" | awk '{printf "%.0f", $1}')
            echo "$mem_int"
            return 0
        fi
    fi

    echo "0"
    return 1
}

# Verificar uso de CPU do VSCode
check_vscode_cpu() {
    local pid
    pid=$(get_vscode_pid)

    if [ -n "$pid" ]; then
        local cpu_usage
        cpu_usage=$(ps -p "$pid" -o pcpu= | tr -d ' ' | head -1)

        if [ -n "$cpu_usage" ]; then
            # Converter para número inteiro usando awk
            local cpu_int
            cpu_int=$(echo "$cpu_usage" | awk '{printf "%.0f", $1}')
            echo "$cpu_int"
            return 0
        fi
    fi

    echo "0"
    return 1
}

# Contar arquivos abertos
count_open_files() {
    local pid
    pid=$(get_vscode_pid)

    if [ -n "$pid" ]; then
        local open_files
        open_files=$(lsof -p "$pid" 2>/dev/null | wc -l)
        echo "$open_files"
        return 0
    fi

    echo "0"
    return 1
}

# Verificar se VSCode está respondendo
is_vscode_responding() {
    local pid
    pid=$(get_vscode_pid)

    if [ -n "$pid" ]; then
        # Verificar se o processo está respondendo
        if timeout 5s kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi

    return 1
}

# Aplicar correções de performance
apply_performance_fixes() {
    log "Aplicando correções de performance..."

    # Liberar memória cache do sistema (se possível)
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

    # Otimizar swappiness (se possível)
    echo 10 > /proc/sys/vm/swappiness 2>/dev/null || true

    # Limpar cache temporário do VSCode
    local vscode_cache_dir="$HOME/.vscode"
    if [ -d "$vscode_cache_dir" ]; then
        find "$vscode_cache_dir" -name "*.tmp" -delete 2>/dev/null || true
        find "$vscode_cache_dir" -name "Cache" -type d -exec rm -rf {} + 2>/dev/null || true
    fi

    log "Correções aplicadas"
}

# Reiniciar VSCode se necessário
restart_vscode_if_needed() {
    local current_time
    current_time=$(date +%s)

    # Evitar reinícios muito frequentes (mínimo 5 minutos entre reinícios)
    if [ $((current_time - last_restart_time)) -lt 300 ]; then
        log "Reinício muito recente, aguardando..."
        return
    fi

    local should_restart=false
    local reason=""

    # Verificar condições para reinício
    if [ $memory_warnings -ge $RESTART_THRESHOLD ]; then
        should_restart=true
        reason="uso excessivo de memória"
    elif [ $cpu_warnings -ge $RESTART_THRESHOLD ]; then
        should_restart=true
        reason="uso excessivo de CPU"
    elif [ $file_warnings -ge $RESTART_THRESHOLD ]; then
        should_restart=true
        reason="muitos arquivos abertos"
    elif ! is_vscode_responding; then
        should_restart=true
        reason="interface não responsiva"
    fi

    if [ "$should_restart" = true ]; then
        log "🔄 Reiniciando VSCode devido a: $reason"

        # Parar VSCode
        pkill -TERM -f "code" 2>/dev/null || true
        sleep 3

        # Forçar parada se necessário
        if is_vscode_running; then
            pkill -KILL -f "code" 2>/dev/null || true
            sleep 2
        fi

        # Aplicar correções antes de reiniciar
        apply_performance_fixes

        # Reiniciar VSCode
        if [ -f "cluster-ai.code-workspace" ]; then
            nohup code "cluster-ai.code-workspace" --disable-gpu >/dev/null 2>&1 &
        else
            nohup code . --disable-gpu >/dev/null 2>&1 &
        fi

        # Resetar contadores
        memory_warnings=0
        cpu_warnings=0
        file_warnings=0
        last_restart_time=$current_time
        restart_count=$((restart_count + 1))

        log "✅ VSCode reiniciado (total: $restart_count reinícios)"

        # Aguardar inicialização
        sleep 10

    fi
}

# Verificar se VSCode deve estar rodando
should_vscode_be_running() {
    # Verificar se há arquivos abertos recentemente no projeto
    local recent_files
    recent_files=$(find . -name "*.py" -o -name "*.sh" -o -name "*.md" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" | head -5)

    if [ -n "$recent_files" ]; then
        # Verificar se há atividade recente (últimos 30 minutos)
        local recent_activity
        recent_activity=$(find . -name "*.py" -o -name "*.sh" -o -name "*.md" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" -newermt "30 minutes ago" 2>/dev/null | wc -l)

        if [ "$recent_activity" -gt 0 ]; then
            return 0  # Deve estar rodando
        fi
    fi

    return 1  # Não precisa estar rodando
}

# Iniciar VSCode se necessário
start_vscode_if_needed() {
    if ! is_vscode_running && should_vscode_be_running; then
        log "Iniciando VSCode automaticamente..."

        if [ -f "cluster-ai.code-workspace" ]; then
            nohup code "cluster-ai.code-workspace" --disable-gpu >/dev/null 2>&1 &
        else
            nohup code . --disable-gpu >/dev/null 2>&1 &
        fi

        sleep 5
        log "VSCode iniciado automaticamente"
    fi
}

# Monitor principal
monitor_loop() {
    log "=== Iniciando Auto-Recuperação do VSCode ==="
    log "Intervalo de monitoramento: ${MONITOR_INTERVAL}s"
    log "Limites: Memória ${MAX_MEMORY_USAGE}%, CPU ${MAX_CPU_USAGE}%, Arquivos ${MAX_OPEN_FILES}"

    while true; do
        if is_vscode_running; then
            # Verificar uso de memória
            local mem_usage
            mem_usage=$(check_vscode_memory)

            if [ "$mem_usage" -gt $MAX_MEMORY_USAGE ]; then
                memory_warnings=$((memory_warnings + 1))
                log "⚠️  Memória alta: ${mem_usage}% (aviso $memory_warnings/$RESTART_THRESHOLD)"
            else
                if [ $memory_warnings -gt 0 ]; then
                    memory_warnings=0
                fi
            fi

            # Verificar uso de CPU
            local cpu_usage
            cpu_usage=$(check_vscode_cpu)

            if [ "$cpu_usage" -gt $MAX_CPU_USAGE ]; then
                cpu_warnings=$((cpu_warnings + 1))
                log "⚠️  CPU alta: ${cpu_usage}% (aviso $cpu_warnings/$RESTART_THRESHOLD)"
            else
                if [ $cpu_warnings -gt 0 ]; then
                    cpu_warnings=0
                fi
            fi

            # Verificar arquivos abertos
            local open_files
            open_files=$(count_open_files)

            if [ "$open_files" -gt $MAX_OPEN_FILES ]; then
                file_warnings=$((file_warnings + 1))
                log "⚠️  Muitos arquivos: $open_files (aviso $file_warnings/$RESTART_THRESHOLD)"
            else
                if [ $file_warnings -gt 0 ]; then
                    file_warnings=0
                fi
            fi

            # Verificar se está respondendo
            if ! is_vscode_responding; then
                log "⚠️  VSCode não está respondendo"
                restart_vscode_if_needed
            fi

            # Aplicar correções se necessário
            restart_vscode_if_needed

        else
            # Verificar se deve iniciar
            start_vscode_if_needed
        fi

        # Aguardar próximo ciclo
        sleep "$MONITOR_INTERVAL"
    done
}

# Processar argumentos
case "${1:-start}" in
    "start")
        if is_already_running; then
            log "Auto-recuperação já está rodando"
            exit 1
        fi

        save_pid
        trap cleanup_pid EXIT

        log "Iniciando auto-recuperação em background..."
        monitor_loop
        ;;
    "stop")
        if [ -f "$PID_FILE" ]; then
            local pid
            pid=$(cat "$PID_FILE")
            kill "$pid" 2>/dev/null || true
            cleanup_pid
            log "Auto-recuperação parada"
        else
            log "Auto-recuperação não está rodando"
        fi
        ;;
    "status")
        if is_already_running; then
            local pid
            pid=$(cat "$PID_FILE")
            log "Auto-recuperação rodando (PID: $pid)"
            log "Reinícios automáticos: $restart_count"
            log "Último reinício: $(date -d "@$last_restart_time" 2>/dev/null || echo 'Nunca')"
        else
            log "Auto-recuperação não está rodando"
        fi
        ;;
    "check")
        log "Verificação manual:"
        if is_vscode_running; then
            local mem_usage cpu_usage open_files
            mem_usage=$(check_vscode_memory)
            cpu_usage=$(check_vscode_cpu)
            open_files=$(count_open_files)

            log "  Status: Rodando"
            log "  Memória: ${mem_usage}%"
            log "  CPU: ${cpu_usage}%"
            log "  Arquivos abertos: $open_files"
            log "  Responsivo: $(is_vscode_responding && echo 'Sim' || echo 'Não')"
        else
            log "  Status: Parado"
        fi
        ;;
    *)
        echo "Uso: $0 [start|stop|status|check]"
        echo "  start  - Iniciar auto-recuperação em background"
        echo "  stop   - Parar auto-recuperação"
        echo "  status - Verificar status"
        echo "  check  - Verificação manual"
        exit 1
        ;;
esac
