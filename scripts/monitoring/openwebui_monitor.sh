#!/bin/bash

# Monitor de Saúde do OpenWebUI com Recuperação Automática
# Previne erros 500 e garante disponibilidade do serviço

set -e

# Configurações
OPENWEBUI_URL="http://localhost:3000"
OLLAMA_URL="http://localhost:11434"
LOG_FILE="/tmp/openwebui_monitor.log"
HEALTH_CHECK_INTERVAL=30
MAX_RETRIES=3
RESTART_DELAY=10

# Função de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Verificar se Docker está rodando
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        log "ERRO: Docker não está rodando"
        return 1
    fi
    return 0
}

# Verificar saúde do OpenWebUI
check_openwebui_health() {
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$OPENWEBUI_URL" 2>/dev/null || echo "000")

    if [ "$response_code" = "200" ]; then
        log "✅ OpenWebUI saudável (HTTP $response_code)"
        return 0
    else
        log "⚠️  OpenWebUI com problema (HTTP $response_code)"
        return 1
    fi
}

# Verificar saúde do Ollama
check_ollama_health() {
    local response_code
    response_code=$(curl -s -o /dev/null -w "%{http_code}" "$OLLAMA_URL/api/tags" 2>/dev/null || echo "000")

    if [ "$response_code" = "200" ]; then
        log "✅ Ollama saudável (HTTP $response_code)"
        return 0
    else
        log "⚠️  Ollama com problema (HTTP $response_code)"
        return 1
    fi
}

# Reiniciar container do OpenWebUI
restart_openwebui() {
    log "🔄 Reiniciando container OpenWebUI..."

    if docker restart open-webui >/dev/null 2>&1; then
        log "✅ Container OpenWebUI reiniciado com sucesso"
        sleep "$RESTART_DELAY"

        # Verificar se reiniciou corretamente
        if check_openwebui_health; then
            log "✅ OpenWebUI recuperado após reinício"
            return 0
        else
            log "❌ OpenWebUI ainda com problemas após reinício"
            return 1
        fi
    else
        log "❌ Falha ao reiniciar container OpenWebUI"
        return 1
    fi
}

# Recriar container do OpenWebUI
recreate_openwebui() {
    log "🔄 Recriando container OpenWebUI..."

    # Parar e remover container existente
    docker stop open-webui >/dev/null 2>&1 || true
    docker rm open-webui >/dev/null 2>&1 || true

    # Iniciar novo container
    if docker run -d \
        --name open-webui \
        -p 3000:8080 \
        -e OLLAMA_API_URL=http://host.docker.internal:11434 \
        --add-host host.docker.internal:host-gateway \
        --restart unless-stopped \
        ghcr.io/open-webui/open-webui:main >/dev/null 2>&1; then

        log "✅ Container OpenWebUI recriado com sucesso"
        sleep "$RESTART_DELAY"

        # Verificar se está funcionando
        if check_openwebui_health; then
            log "✅ OpenWebUI recuperado após recriação"
            return 0
        else
            log "❌ OpenWebUI ainda com problemas após recriação"
            return 1
        fi
    else
        log "❌ Falha ao recriar container OpenWebUI"
        return 1
    fi
}

# Verificar e corrigir problemas
fix_openwebui_issues() {
    local retry_count=0

    while [ $retry_count -lt $MAX_RETRIES ]; do
        log "🔍 Tentativa $((retry_count + 1))/$MAX_RETRIES de correção"

        # Verificar Docker
        if ! check_docker; then
            log "❌ Docker não disponível, pulando correção"
            return 1
        fi

        # Verificar se container existe
        if ! docker ps -a --format 'table {{.Names}}' | grep -q "^open-webui$"; then
            log "📦 Container OpenWebUI não encontrado, criando..."
            if recreate_openwebui; then
                return 0
            fi
        else
            # Container existe, tentar reiniciar
            if restart_openwebui; then
                return 0
            fi
        fi

        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $MAX_RETRIES ]; then
            log "⏳ Aguardando antes da próxima tentativa..."
            sleep "$RESTART_DELAY"
        fi
    done

    log "❌ Todas as tentativas de correção falharam"
    return 1
}

# Verificar uso de recursos
check_resources() {
    # Verificar uso de memória
    local mem_usage
    mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')

    if [ "$mem_usage" -gt 90 ]; then
        log "⚠️  Uso de memória alto: ${mem_usage}%"
        return 1
    fi

    # Verificar uso de CPU
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

    if [ "${cpu_usage%.*}" -gt 90 ]; then
        log "⚠️  Uso de CPU alto: ${cpu_usage}%"
        return 1
    fi

    return 0
}

# Função principal de monitoramento
monitor_openwebui() {
    log "🚀 Iniciando monitoramento do OpenWebUI"

    while true; do
        log "--- Verificação de Saúde ---"

        # Verificar recursos do sistema
        if ! check_resources; then
            log "⚠️  Recursos do sistema sobrecarregados"
        fi

        # Verificar Ollama primeiro (dependência)
        if ! check_ollama_health; then
            log "⚠️  Ollama não está saudável - isso pode afetar o OpenWebUI"
        fi

        # Verificar OpenWebUI
        if ! check_openwebui_health; then
            log "❌ OpenWebUI com problemas - iniciando correção automática"
            if fix_openwebui_issues; then
                log "✅ Problema resolvido automaticamente"
            else
                log "❌ Falha na correção automática - intervenção manual necessária"
            fi
        fi

        log "⏳ Próxima verificação em ${HEALTH_CHECK_INTERVAL}s"
        sleep "$HEALTH_CHECK_INTERVAL"
    done
}

# Função de verificação única
single_check() {
    log "🔍 Verificação única de saúde"

    if check_openwebui_health && check_ollama_health; then
        log "✅ Todos os serviços estão saudáveis"
        return 0
    else
        log "❌ Serviços com problemas detectados"
        return 1
    fi
}

# Processar argumentos da linha de comando
case "${1:-monitor}" in
    "monitor")
        monitor_openwebui
        ;;
    "check")
        single_check
        ;;
    "fix")
        if check_openwebui_health; then
            log "✅ OpenWebUI já está saudável"
        else
            fix_openwebui_issues
        fi
        ;;
    "restart")
        restart_openwebui
        ;;
    "recreate")
        recreate_openwebui
        ;;
    *)
        echo "Uso: $0 [monitor|check|fix|restart|recreate]"
        echo "  monitor  - Monitoramento contínuo (padrão)"
        echo "  check    - Verificação única"
        echo "  fix      - Tentar corrigir problemas automaticamente"
        echo "  restart  - Reiniciar container"
        echo "  recreate - Recriar container"
        exit 1
        ;;
esac
