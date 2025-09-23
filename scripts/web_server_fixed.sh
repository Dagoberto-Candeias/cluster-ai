#!/bin/bash
# =============================================================================
# Servidor Web para Interfaces do Cluster AI (Versão Corrigida)
# =============================================================================
# Servidor web simples para servir as interfaces HTML do sistema
#
# Autor: Cluster AI Team
# Data: 2025-01-20
# Versão: 1.0.0
# Arquivo: web_server_fixed.sh
# =============================================================================

set -euo pipefail

# --- Cores e Estilos ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- Configuração Inicial ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Carregar funções comuns
if [ ! -f "${SCRIPT_DIR}/lib/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${SCRIPT_DIR}/lib/common.sh"

# --- Constantes ---
WEB_DIR="${PROJECT_ROOT}/web"
LOG_DIR="${PROJECT_ROOT}/logs"
WEB_LOG="${LOG_DIR}/web_server.log"
PID_FILE="${PROJECT_ROOT}/.web_server_pid"
DEFAULT_PORT=8080

# Criar diretórios necessários
mkdir -p "$LOG_DIR"
mkdir -p "$WEB_DIR"

# --- Funções ---

# Função para log detalhado
log_web() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" >> "$WEB_LOG"

    case "$level" in
        "INFO")
            info "$message" ;;
        "WARN")
            warn "$message" ;;
        "ERROR")
            error "$message" ;;
    esac
}

# Função para verificar se o servidor já está rodando
check_already_running() {
    if [[ -f "$PID_FILE" ]]; then
        local existing_pid
        existing_pid=$(cat "$PID_FILE")

        if ps -p "$existing_pid" >/dev/null 2>&1; then
            log_web "WARN" "Servidor web já está rodando com PID: $existing_pid"
            return 0
        else
            log_web "INFO" "Removendo PID file obsoleto"
            rm -f "$PID_FILE"
        fi
    fi

    return 1
}

# Função para salvar PID
save_pid() {
    echo $$ > "$PID_FILE"
    log_web "DEBUG" "PID salvo: $$"
}

# Função para remover PID
remove_pid() {
    if [[ -f "$PID_FILE" ]]; then
        rm -f "$PID_FILE"
        log_web "DEBUG" "PID file removido"
    fi
}

# Função para verificar dependências
check_dependencies() {
    local missing_deps=()

    if ! command_exists python3; then
        missing_deps+=("python3")
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Dependências faltando: ${missing_deps[*]}"
        return 1
    fi

    return 0
}

# Função para iniciar servidor web
start_web_server() {
    local port="${1:-$DEFAULT_PORT}"

    log_web "INFO" "Iniciando servidor web na porta $port..."

    # Verificar se já está rodando
    if check_already_running; then
        error "Servidor web já está rodando"
        exit 1
    fi

    # Verificar dependências
    if ! check_dependencies; then
        exit 1
    fi

    # Salvar PID
    save_pid

    # Configurar tratamento de sinais
    trap 'signal_handler INT' INT
    trap 'signal_handler TERM' TERM
    trap 'signal_handler HUP' HUP

    # Iniciar servidor Python simples
    cd "$WEB_DIR"

    # Criar servidor Python simples
    python3 -m http.server "$port" >> "$WEB_LOG" 2>&1 &

    local server_pid=$!

    log_web "INFO" "Servidor web iniciado com PID: $server_pid"
    success "Servidor web iniciado na porta $port"
    echo -e "${CYAN}🌐 Interfaces disponíveis:${NC}"
    echo -e "  ${GREEN}📱 Central de Interfaces${NC}     http://localhost:$port/"
    echo -e "  ${GREEN}🔄 Sistema de Atualizações${NC}  http://localhost:$port/update-interface.html"
    echo -e "  ${GREEN}💾 Gerenciador de Backups${NC}   http://localhost:$port/backup-manager.html"
    echo
    echo -e "${YELLOW}💡 Para parar o servidor: $0 stop${NC}"

    # Aguardar servidor
    wait $server_pid
}

# Função para parar servidor web
stop_web_server() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")

        if ps -p "$pid" >/dev/null 2>&1; then
            log_web "INFO" "Parando servidor web (PID: $pid)..."
            kill "$pid"

            # Aguardar término
            local count=0
            while ps -p "$pid" >/dev/null 2>&1 && [[ $count -lt 10 ]]; do
                sleep 1
                ((count++))
            done

            if ps -p "$pid" >/dev/null 2>&1; then
                log_web "WARN" "Processo não respondeu, forçando término..."
                kill -9 "$pid" 2>/dev/null || true
            fi

            remove_pid
            success "Servidor web parado com sucesso"
        else
            warn "Processo do servidor web não encontrado"
            remove_pid
        fi
    else
        warn "Arquivo PID não encontrado - servidor web pode não estar rodando"
    fi
}

# Função para status do servidor web
status_web_server() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")

        if ps -p "$pid" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} ${BOLD}Servidor web rodando${NC} (PID: $pid)"
            echo -e "${GRAY}Log: $WEB_LOG${NC}"
            echo -e "${GRAY}Diretório web: $WEB_DIR${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠${NC} ${BOLD}Servidor web não está rodando${NC} (PID file obsoleto)"
            remove_pid
            return 1
        fi
    else
        echo -e "${RED}✗${NC} ${BOLD}Servidor web não está rodando${NC}"
        return 1
    fi
}

# Função para verificar arquivos web
check_web_files() {
    local missing_files=()

    local required_files=(
        "index.html"
        "update-interface.html"
        "backup-manager.html"
    )

    for file in "${required_files[@]}"; do
        if [[ ! -f "$WEB_DIR/$file" ]]; then
            missing_files+=("$file")
        fi
    done

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        warn "Arquivos web faltando: ${missing_files[*]}"
        return 1
    fi

    success "Todos os arquivos web estão presentes"
    return 0
}

# Função para tratamento de sinais
signal_handler() {
    local signal="$1"
    log_web "INFO" "Recebido sinal $signal, encerrando servidor web..."
    remove_pid
    exit 0
}

# Função principal
main() {
    # Verificar argumentos
    case "${1:-status}" in
        "start")
            local port="${2:-$DEFAULT_PORT}"
            check_web_files
            start_web_server "$port"
            ;;
        "stop")
            stop_web_server
            ;;
        "restart")
            stop_web_server
            sleep 2
            check_web_files
            start_web_server "$DEFAULT_PORT"
            ;;
        "status")
            status_web_server
            ;;
        "check")
            check_web_files
            ;;
        *)
            echo "Uso: $0 [start [port]|stop|restart|status|check]"
            echo
            echo "Comandos:"
            echo "  start [port] - Iniciar servidor web (padrão: $DEFAULT_PORT)"
            echo "  stop         - Parar servidor web"
            echo "  restart      - Reiniciar servidor web"
            echo "  status       - Verificar status"
            echo "  check        - Verificar arquivos web"
            exit 1
            ;;
    esac
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
