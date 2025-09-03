#!/bin/bash

# Monitor de Performance do VSCode
# Detecta problemas de performance e aplica correções automaticamente

set -e

# Configurações
LOG_FILE="/tmp/vscode_performance_monitor.log"
VSCODE_PROCESS_NAME="code"
MONITOR_INTERVAL=60
MAX_MEMORY_USAGE=80
MAX_CPU_USAGE=70
MAX_OPEN_FILES=50
RESTART_THRESHOLD=3

# Contadores de problemas
memory_warnings=0
cpu_warnings=0
file_warnings=0
restart_count=0

# Função de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Verificar se VSCode está rodando
is_vscode_running() {
    pgrep -f "$VSCODE_PROCESS_NAME" >/dev/null 2>&1
}

# Obter PID do VSCode
get_vscode_pid() {
    pgrep -f "$VSCODE_PROCESS_NAME" | head -1
}

# Verificar uso de memória do VSCode
check_vscode_memory() {
    local pid
    pid=$(get_vscode_pid)

    if [ -n "$pid" ]; then
        local mem_usage
        mem_usage=$(ps -p "$pid" -o pmem= | tr -d ' ')

        # Converter para número inteiro
        local mem_int
        mem_int=$(echo "$mem_usage" | awk '{printf "%.0f", $1}')

        echo "$mem_int"
        return 0
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
        cpu_usage=$(ps -p "$pid" -o pcpu= | tr -d ' ')

        # Converter para número inteiro
        local cpu_int
        cpu_int=$(echo "$cpu_usage" | awk '{printf "%.0f", $1}')

        echo "$cpu_int"
        return 0
    fi

    echo "0"
    return 1
}

# Contar arquivos abertos no VSCode
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

# Verificar tempo de resposta da interface
check_ui_responsiveness() {
    # Verificar se há processos VSCode "congelados"
    local pid
    pid=$(get_vscode_pid)

    if [ -n "$pid" ]; then
        # Verificar se o processo está respondendo
        if timeout 5s kill -0 "$pid" 2>/dev/null; then
            return 0  # Respondendo
        else
            return 1  # Não respondendo
        fi
    fi

    return 1  # Não está rodando
}

# Aplicar correções de performance
apply_performance_fixes() {
    log "Aplicando correções de performance..."

    # Liberar memória do sistema
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

    # Otimizar swappiness
    echo 10 > /proc/sys/vm/swappiness 2>/dev/null || true

    # Limpar cache do VSCode
    local vscode_cache_dir="$HOME/.vscode"
    if [ -d "$vscode_cache_dir" ]; then
        find "$vscode_cache_dir" -name "*.tmp" -delete 2>/dev/null || true
        find "$vscode_cache_dir" -name "Cache" -type d -exec rm -rf {} + 2>/dev/null || true
    fi

    log "Correções aplicadas"
}

# Reiniciar VSCode se necessário
restart_vscode_if_needed() {
    local should_restart=false

    # Verificar condições para reinício
    if [ $memory_warnings -ge $RESTART_THRESHOLD ] || \
       [ $cpu_warnings -ge $RESTART_THRESHOLD ] || \
       [ $file_warnings -ge $RESTART_THRESHOLD ]; then
        should_restart=true
    fi

    # Verificar se a interface não está respondendo
    if ! check_ui_responsiveness; then
        should_restart=true
        log "Interface do VSCode não está respondendo"
    fi

    if [ "$should_restart" = true ]; then
        log "Reiniciando VSCode devido a problemas de performance..."

        # Parar VSCode
        pkill -TERM -f "$VSCODE_PROCESS_NAME" 2>/dev/null || true
        sleep 3

        # Forçar parada se necessário
        if is_vscode_running; then
            pkill -KILL -f "$VSCODE_PROCESS_NAME" 2>/dev/null || true
            sleep 2
        fi

        # Aplicar correções antes de reiniciar
        apply_performance_fixes

        # Reiniciar VSCode
        if [ -f "cluster-ai.code-workspace" ]; then
            nohup code cluster-ai.code-workspace >/dev/null 2>&1 &
        else
            nohup code . >/dev/null 2>&1 &
        fi

        # Resetar contadores
        memory_warnings=0
        cpu_warnings=0
        file_warnings=0
        restart_count=$((restart_count + 1))

        log "VSCode reiniciado (total de reinícios: $restart_count)"

        # Aguardar inicialização
        sleep 10
    fi
}

# Monitor principal
monitor_vscode_performance() {
    log "Iniciando monitoramento de performance do VSCode..."

    while true; do
        if is_vscode_running; then
            log "--- Verificação de Performance ---"

            # Verificar uso de memória
            local mem_usage
            mem_usage=$(check_vscode_memory)

            if [ "$mem_usage" -gt $MAX_MEMORY_USAGE ]; then
                memory_warnings=$((memory_warnings + 1))
                log "⚠️  Uso de memória alto: ${mem_usage}% (aviso $memory_warnings/$RESTART_THRESHOLD)"
            else
                # Resetar contador se estiver OK
                if [ $memory_warnings -gt 0 ]; then
                    memory_warnings=0
                fi
            fi

            # Verificar uso de CPU
            local cpu_usage
            cpu_usage=$(check_vscode_cpu)

            if [ "$cpu_usage" -gt $MAX_CPU_USAGE ]; then
                cpu_warnings=$((cpu_warnings + 1))
                log "⚠️  Uso de CPU alto: ${cpu_usage}% (aviso $cpu_warnings/$RESTART_THRESHOLD)"
            else
                # Resetar contador se estiver OK
                if [ $cpu_warnings -gt 0 ]; then
                    cpu_warnings=0
                fi
            fi

            # Verificar arquivos abertos
            local open_files
            open_files=$(count_open_files)

            if [ "$open_files" -gt $MAX_OPEN_FILES ]; then
                file_warnings=$((file_warnings + 1))
                log "⚠️  Muitos arquivos abertos: $open_files (aviso $file_warnings/$RESTART_THRESHOLD)"
            else
                # Resetar contador se estiver OK
                if [ $file_warnings -gt 0 ]; then
                    file_warnings=0
                fi
            fi

            # Verificar se precisa reiniciar
            restart_vscode_if_needed

        else
            log "VSCode não está rodando - pulando verificação"
        fi

        log "Próxima verificação em ${MONITOR_INTERVAL}s"
        sleep "$MONITOR_INTERVAL"
    done
}

# Verificação única
single_check() {
    log "Verificação única de performance"

    if is_vscode_running; then
        local mem_usage cpu_usage open_files

        mem_usage=$(check_vscode_memory)
        cpu_usage=$(check_vscode_cpu)
        open_files=$(count_open_files)

        log "Status do VSCode:"
        log "  - Memória: ${mem_usage}%"
        log "  - CPU: ${cpu_usage}%"
        log "  - Arquivos abertos: $open_files"
        log "  - Interface responsiva: $(check_ui_responsiveness && echo 'Sim' || echo 'Não')"

        # Verificar se há problemas
        local has_issues=false

        if [ "$mem_usage" -gt $MAX_MEMORY_USAGE ]; then
            log "❌ Problema: Uso de memória alto"
            has_issues=true
        fi

        if [ "$cpu_usage" -gt $MAX_CPU_USAGE ]; then
            log "❌ Problema: Uso de CPU alto"
            has_issues=true
        fi

        if [ "$open_files" -gt $MAX_OPEN_FILES ]; then
            log "❌ Problema: Muitos arquivos abertos"
            has_issues=true
        fi

        if ! check_ui_responsiveness; then
            log "❌ Problema: Interface não responsiva"
            has_issues=true
        fi

        if [ "$has_issues" = false ]; then
            log "✅ VSCode funcionando normalmente"
            return 0
        else
            log "❌ Problemas de performance detectados"
            return 1
        fi
    else
        log "VSCode não está rodando"
        return 1
    fi
}

# Processar argumentos
case "${1:-monitor}" in
    "monitor")
        monitor_vscode_performance
        ;;
    "check")
        single_check
        ;;
    "fix")
        apply_performance_fixes
        ;;
    "restart")
        restart_vscode_if_needed
        ;;
    *)
        echo "Uso: $0 [monitor|check|fix|restart]"
        echo "  monitor - Monitoramento contínuo (padrão)"
        echo "  check   - Verificação única"
        echo "  fix     - Aplicar correções de performance"
        echo "  restart - Reiniciar VSCode se necessário"
        exit 1
        ;;
esac
