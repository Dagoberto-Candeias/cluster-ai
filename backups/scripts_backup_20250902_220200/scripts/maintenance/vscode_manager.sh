#!/bin/bash

# Gerenciador Completo de Performance do VSCode
# Interface unificada para todos os recursos de otimização

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função de logging colorido
log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Verificar dependências
check_dependencies() {
    local missing_deps=()

    if ! command -v code >/dev/null 2>&1; then
        missing_deps+=("VSCode (code)")
    fi

    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        error "Dependências faltando: ${missing_deps[*]}"
        return 1
    fi

    return 0
}

# Mostrar status do sistema
show_status() {
    log "=== Status do Sistema VSCode ==="

    # Verificar se VSCode está rodando
    if pgrep -f "code" >/dev/null 2>&1; then
        info "VSCode: Rodando"

        # Obter informações de performance
        local pid mem_usage cpu_usage open_files
        pid=$(pgrep -f "code" | head -1)
        mem_usage=$(ps -p "$pid" -o pmem= 2>/dev/null | tr -d ' ' | head -1)
        cpu_usage=$(ps -p "$pid" -o pcpu= 2>/dev/null | tr -d ' ' | head -1)
        open_files=$(lsof -p "$pid" 2>/dev/null | wc -l)

        info "PID: $pid"
        info "Memória: ${mem_usage}%"
        info "CPU: ${cpu_usage}%"
        info "Arquivos abertos: $open_files"
    else
        warn "VSCode: Parado"
    fi

    # Verificar auto-recuperação
    if [ -f "/tmp/vscode_auto_recovery.pid" ]; then
        local recovery_pid
        recovery_pid=$(cat "/tmp/vscode_auto_recovery.pid")
        if ps -p "$recovery_pid" >/dev/null 2>&1; then
            info "Auto-recuperação: Ativa (PID: $recovery_pid)"
        else
            warn "Auto-recuperação: PID file existe mas processo parado"
        fi
    else
        warn "Auto-recuperação: Inativa"
    fi

    # Verificar workspace
    if [ -f "cluster-ai.code-workspace" ]; then
        info "Workspace: Configurado (cluster-ai.code-workspace)"
    else
        warn "Workspace: Não encontrado"
    fi

    echo
}

# Otimização completa
optimize_full() {
    log "=== Otimização Completa do VSCode ==="

    # Parar auto-recuperação temporariamente
    if [ -f "/tmp/vscode_auto_recovery.pid" ]; then
        info "Parando auto-recuperação temporariamente..."
        "$SCRIPT_DIR/vscode_auto_recovery.sh" stop
    fi

    # Executar otimizador completo
    info "Executando otimizador completo..."
    "$SCRIPT_DIR/vscode_optimizer.sh" full

    # Reiniciar auto-recuperação
    info "Reiniciando auto-recuperação..."
    "$SCRIPT_DIR/vscode_auto_recovery.sh" start

    log "✅ Otimização completa finalizada!"
}

# Iniciar VSCode otimizado
start_optimized() {
    log "=== Iniciando VSCode Otimizado ==="

    # Parar auto-recuperação temporariamente
    if [ -f "/tmp/vscode_auto_recovery.pid" ]; then
        "$SCRIPT_DIR/vscode_auto_recovery.sh" stop
    fi

    # Iniciar VSCode otimizado
    "$SCRIPT_DIR/start_vscode_optimized.sh"

    # Aguardar estabilização
    sleep 5

    # Reiniciar auto-recuperação
    "$SCRIPT_DIR/vscode_auto_recovery.sh" start
}

# Gerenciar auto-recuperação
manage_recovery() {
    case "${2:-status}" in
        "start")
            log "Iniciando auto-recuperação..."
            "$SCRIPT_DIR/vscode_auto_recovery.sh" start
            ;;
        "stop")
            log "Parando auto-recuperação..."
            "$SCRIPT_DIR/vscode_auto_recovery.sh" stop
            ;;
        "status")
            "$SCRIPT_DIR/vscode_auto_recovery.sh" status
            ;;
        "check")
            "$SCRIPT_DIR/vscode_auto_recovery.sh" check
            ;;
        *)
            error "Comando inválido. Use: start, stop, status, check"
            return 1
            ;;
    esac
}

# Monitorar performance
monitor_performance() {
    case "${2:-check}" in
        "check")
            "$SCRIPT_DIR/vscode_performance_monitor.sh" check
            ;;
        "fix")
            "$SCRIPT_DIR/vscode_performance_monitor.sh" fix
            ;;
        "monitor")
            warn "Iniciando monitoramento contínuo (pressione Ctrl+C para parar)..."
            "$SCRIPT_DIR/vscode_performance_monitor.sh" monitor
            ;;
        *)
            error "Comando inválido. Use: check, fix, monitor"
            return 1
            ;;
    esac
}

# Limpar sistema
clean_system() {
    log "=== Limpando Sistema ==="

    # Parar serviços
    if [ -f "/tmp/vscode_auto_recovery.pid" ]; then
        "$SCRIPT_DIR/vscode_auto_recovery.sh" stop
    fi

    # Parar VSCode
    if pgrep -f "code" >/dev/null 2>&1; then
        info "Parando VSCode..."
        pkill -TERM -f "code" 2>/dev/null || true
        sleep 3
        pkill -KILL -f "code" 2>/dev/null || true
    fi

    # Limpar arquivos temporários
    info "Limpando arquivos temporários..."
    rm -f /tmp/vscode_*.log
    rm -f /tmp/vscode_*.pid

    # Limpar cache do VSCode
    "$SCRIPT_DIR/vscode_optimizer.sh" clean

    log "✅ Sistema limpo!"
}

# Mostrar ajuda
show_help() {
    cat << 'EOF'
Gerenciador de Performance do VSCode - Cluster AI

COMANDOS DISPONÍVEIS:

  status              - Mostra status completo do sistema
  optimize           - Executa otimização completa
  start              - Inicia VSCode otimizado
  recovery <cmd>     - Gerencia auto-recuperação
    start            - Inicia auto-recuperação
    stop             - Para auto-recuperação
    status           - Mostra status da auto-recuperação
    check            - Verificação manual
  monitor <cmd>      - Monitora performance
    check            - Verificação única
    fix              - Aplica correções
    monitor          - Monitoramento contínuo
  clean              - Limpa sistema completamente
  help               - Mostra esta ajuda

EXEMPLOS DE USO:

  # Verificar status
  ./vscode_manager.sh status

  # Otimização completa
  ./vscode_manager.sh optimize

  # Iniciar VSCode otimizado
  ./vscode_manager.sh start

  # Iniciar auto-recuperação
  ./vscode_manager.sh recovery start

  # Verificar performance
  ./vscode_manager.sh monitor check

  # Limpar tudo
  ./vscode_manager.sh clean

DICAS DE PERFORMANCE:

  - Mantenha menos de 15 abas abertas
  - Feche arquivos não utilizados
  - Use Ctrl+Shift+P > 'Developer: Reload Window' se travar
  - Execute otimização semanalmente
  - Mantenha auto-recuperação ativa

LOGS:
  - /tmp/vscode_manager.log
  - /tmp/vscode_optimizer.log
  - /tmp/vscode_performance_monitor.log
  - /tmp/vscode_auto_recovery.log
EOF
}

# Função principal
main() {
    # Verificar dependências
    if ! check_dependencies; then
        exit 1
    fi

    # Processar argumentos
    case "${1:-help}" in
        "status")
            show_status
            ;;
        "optimize")
            optimize_full
            ;;
        "start")
            start_optimized
            ;;
        "recovery")
            manage_recovery "$@"
            ;;
        "monitor")
            monitor_performance "$@"
            ;;
        "clean")
            clean_system
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            error "Comando inválido: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"
