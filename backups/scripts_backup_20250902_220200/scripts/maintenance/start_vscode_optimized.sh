#!/bin/bash

# Script para iniciar VSCode otimizado
# Resolve problemas de travamento e melhora performance

set -e

WORKSPACE_FILE="cluster-ai.code-workspace"
LOG_FILE="/tmp/vscode_start.log"
MAX_RETRIES=3
RETRY_DELAY=2

# Função de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Função para verificar se VSCode está realmente funcionando
is_vscode_responding() {
    local pid
    pid=$(pgrep -f "code" | head -1)

    if [ -n "$pid" ]; then
        # Verificar se o processo está respondendo
        if timeout 3s kill -0 "$pid" 2>/dev/null; then
            # Verificar se há janelas abertas (usando xdotool se disponível)
            if command -v xdotool >/dev/null 2>&1; then
                if xdotool search --class "code" >/dev/null 2>&1; then
                    return 0
                fi
            else
                # Fallback: verificar se o processo existe há pelo menos 5 segundos
                local process_age
                process_age=$(ps -p "$pid" -o etimes= | tr -d ' ')
                if [ "$process_age" -gt 5 ]; then
                    return 0
                fi
            fi
        fi
    fi

    return 1
}

# Função para forçar parada completa do VSCode
force_stop_vscode() {
    log "Forçando parada completa do VSCode..."

    # Tentar parada graciosa primeiro
    pkill -TERM -f "code" 2>/dev/null || true
    sleep 2

    # Forçar parada de todos os processos relacionados
    pkill -KILL -f "code" 2>/dev/null || true
    pkill -KILL -f "Code" 2>/dev/null || true

    # Aguardar limpeza
    sleep 3

    # Verificar se ainda há processos
    if pgrep -f "code" >/dev/null 2>&1; then
        log "⚠️  Ainda há processos VSCode rodando"
        return 1
    else
        log "✅ VSCode parado completamente"
        return 0
    fi
}

# Função para limpar estado corrompido
clean_vscode_state() {
    log "Limpando estado corrompido do VSCode..."

    # Limpar locks e arquivos temporários
    rm -rf "$HOME/.config/Code/locks" 2>/dev/null || true
    rm -rf "$HOME/.vscode/locks" 2>/dev/null || true
    rm -rf "$HOME/.config/Code/Crashpad" 2>/dev/null || true

    # Limpar cache de extensões problemáticas
    rm -rf "$HOME/.vscode/extensions/ms-vscode.vscode-json*" 2>/dev/null || true

    # Limpar arquivos de configuração corrompidos
    if [ -f "$HOME/.config/Code/User/settings.json" ]; then
        if ! jq . "$HOME/.config/Code/User/settings.json" >/dev/null 2>&1; then
            log "Arquivo settings.json corrompido, removendo..."
            rm -f "$HOME/.config/Code/User/settings.json"
        fi
    fi

    log "Estado limpo"
}

log "🚀 Iniciando VSCode otimizado..."

# Verificar se workspace existe
if [ ! -f "$WORKSPACE_FILE" ]; then
    log "📁 Criando workspace otimizado..."
    ./scripts/maintenance/vscode_optimizer.sh workspace
fi

# Limpar estado corrompido antes de iniciar
clean_vscode_state

# Parar qualquer instância existente
if pgrep -f "code" >/dev/null 2>&1; then
    log "🛑 Parando instâncias existentes..."
    force_stop_vscode
fi

# Aplicar otimizações
log "⚙️  Aplicando otimizações..."
./scripts/maintenance/vscode_optimizer.sh settings >/dev/null 2>&1

# Tentar iniciar VSCode com retry
local attempt=1
while [ $attempt -le $MAX_RETRIES ]; do
    log "🔄 Tentativa $attempt de $MAX_RETRIES..."

    # Iniciar VSCode
    if [ -f "$WORKSPACE_FILE" ]; then
        log "📂 Iniciando com workspace otimizado..."
        nohup code "$WORKSPACE_FILE" --disable-gpu --disable-software-rasterizer >/dev/null 2>&1 &
    else
        log "📂 Iniciando no diretório atual..."
        nohup code . --disable-gpu --disable-software-rasterizer >/dev/null 2>&1 &
    fi

    # Aguardar inicialização
    sleep 8

    # Verificar se está respondendo
    if is_vscode_responding; then
        log "✅ VSCode iniciado com sucesso na tentativa $attempt"

        # Aguardar mais um pouco para estabilizar
        sleep 3

        log "💡 Dicas para melhor performance:"
        log "   - Mantenha menos de 15 abas abertas"
        log "   - Feche arquivos não utilizados"
        log "   - Use Ctrl+Shift+P > 'Developer: Reload Window' se travar"
        log "   - Execute './scripts/maintenance/vscode_optimizer.sh full' periodicamente"
        log "   - Use './scripts/maintenance/vscode_performance_monitor.sh monitor &' para monitoramento contínuo"

        exit 0
    else
        log "❌ Tentativa $attempt falhou"

        # Parar processo que pode ter ficado travado
        force_stop_vscode

        if [ $attempt -lt $MAX_RETRIES ]; then
            log "⏳ Aguardando ${RETRY_DELAY}s antes da próxima tentativa..."
            sleep $RETRY_DELAY
        fi
    fi

    attempt=$((attempt + 1))
done

log "❌ Falha ao iniciar VSCode após $MAX_RETRIES tentativas"
log "🔧 Sugestões de solução:"
log "   1. Execute: ./scripts/maintenance/vscode_optimizer.sh full"
log "   2. Reinicie o sistema"
log "   3. Verifique logs em: $LOG_FILE"
log "   4. Execute: code --verbose para diagnóstico"

exit 1
