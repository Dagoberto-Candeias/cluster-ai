#!/bin/bash
# Monitor Worker Updates Script
# Monitora continuamente mudanças no projeto e atualiza workers automaticamente

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Verificar se estamos no diretório correto
if [[ ! -f "manager.sh" ]] || [[ ! -f "requirements.txt" ]]; then
    log_error "Este script deve ser executado no diretório raiz do projeto Cluster AI"
    exit 1
fi

# Arquivo de controle do monitor
MONITOR_PID_FILE="/tmp/cluster_worker_monitor.pid"
MONITOR_LOG_FILE="logs/worker_monitor.log"

# Verificar se já existe um monitor rodando
if [[ -f "$MONITOR_PID_FILE" ]]; then
    existing_pid=$(cat "$MONITOR_PID_FILE")
    if kill -0 "$existing_pid" 2>/dev/null; then
        log_warning "Monitor já está rodando (PID: $existing_pid)"
        log_info "Para parar o monitor: kill $existing_pid"
        exit 1
    else
        log_info "Removendo PID file antigo..."
        rm -f "$MONITOR_PID_FILE"
    fi
fi

# Salvar PID do monitor
echo $$ > "$MONITOR_PID_FILE"

# Criar diretório de logs se não existir
mkdir -p logs

log_info "🚀 Iniciando monitor de atualizações de workers..."
log_info "PID do monitor: $$"
log_info "Logs: $MONITOR_LOG_FILE"

# Função de limpeza ao sair
cleanup() {
    log_info "🛑 Parando monitor de workers..."
    rm -f "$MONITOR_PID_FILE"
    exit 0
}

# Capturar sinais de interrupção
trap cleanup SIGINT SIGTERM

# Ativar ambiente virtual
if [[ -d "venv" ]]; then
    source venv/bin/activate
    log_success "Ambiente virtual ativado"
else
    log_error "Ambiente virtual não encontrado"
    exit 1
fi

# Intervalo de verificação (em segundos) - padrão 5 minutos
CHECK_INTERVAL=${CHECK_INTERVAL:-300}

log_info "Intervalo de verificação: ${CHECK_INTERVAL} segundos"

# Loop principal de monitoramento
while true; do
    log_info "🔍 Verificando atualizações no projeto..."

    # Verificar se há mudanças no projeto
    if python3 scripts/utils/auto_worker_updates.py check >> "$MONITOR_LOG_FILE" 2>&1; then
        log_info "📋 Mudanças detectadas! Iniciando atualização dos workers..."

        # Aplicar atualizações
        if python3 scripts/utils/auto_worker_updates.py update >> "$MONITOR_LOG_FILE" 2>&1; then
            log_success "✅ Workers atualizados com sucesso!"
        else
            log_error "❌ Falha ao atualizar workers"
        fi
    else
        log_info "✅ Projeto inalterado - nenhum worker precisa de atualização"
    fi

    # Aguardar próximo ciclo
    log_info "⏰ Aguardando ${CHECK_INTERVAL} segundos até próxima verificação..."
    sleep "$CHECK_INTERVAL"
done
