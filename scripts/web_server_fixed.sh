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
# shellcheck disable=SC2034  # Algumas cores podem não ser usadas diretamente neste script
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
# shellcheck disable=SC2034  # Pode não ser usada diretamente
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- Configuração Inicial ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Carregar funções comuns
# shellcheck source=lib/common.sh
# shellcheck disable=SC1091  # O ShellCheck não segue includes sem -x
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
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

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

# Função para verificar se a porta está em uso
is_port_in_use() {
    local port="$1"
    lsof -i :"$port" >/dev/null 2>&1
}

# Função para liberar porta se em uso
free_port() {
    local port="$1"
    if is_port_in_use "$port"; then
        log_web "WARN" "Porta $port em uso. Liberando processos com fuser..."
        # Usar fuser para matar processos na porta TCP
        fuser -k "$port"/tcp 2>/dev/null || true
        sleep 2
        # Verificar novamente e forçar se necessário
        if is_port_in_use "$port"; then
            fuser -k -9 "$port"/tcp 2>/dev/null || true
            sleep 2
        fi
        # Verificação final
        if is_port_in_use "$port"; then
            log_web "ERROR" "Não foi possível liberar a porta $port mesmo após tentativas"
        else
            log_web "INFO" "Porta $port liberada com sucesso"
        fi
    fi
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

# Função para encontrar uma porta livre
find_free_port() {
    local preferred_port="$1"
    local test_port="$preferred_port"
    local max_tries=10
    local try=0

    while [[ $try -lt $max_tries ]]; do
        if ! is_port_in_use "$test_port"; then
            echo "$test_port"
            return 0
        fi
        ((try++))
        ((test_port++))
    done

    log_web "ERROR" "Não foi possível encontrar uma porta livre após $max_tries tentativas a partir de $preferred_port"
    return 1
}

# Função para iniciar servidor web
start_web_server() {
    local preferred_port="${1:-$DEFAULT_PORT}"
    local port

    log_web "INFO" "Tentando iniciar servidor web na porta preferida $preferred_port..."

    # Verificar se já está rodando
    if check_already_running; then
        error "Servidor web já está rodando"
        exit 1
    fi

    # Verificar dependências
    if ! check_dependencies; then
        exit 1
    fi

    # Encontrar porta livre
    if ! port=$(find_free_port "$preferred_port"); then
        error "Não foi possível encontrar uma porta livre"
        exit 1
    fi

    if [[ $port -ne $preferred_port ]]; then
        log_web "WARN" "Porta $preferred_port em uso. Usando porta $port em vez disso."
        warn "Usando porta $port em vez de $preferred_port"
    fi

    # Liberar a porta selecionada se necessário (deve estar livre, mas por segurança)
    free_port "$port"

    # Salvar PID
    save_pid

    # Configurar tratamento de sinais
    trap 'signal_handler INT' INT
    trap 'signal_handler TERM' TERM
    trap 'signal_handler HUP' HUP

    # Iniciar servidor Python simples
    log_web "DEBUG" "Mudando para diretório web: $WEB_DIR"
    if [[ ! -d "$WEB_DIR" ]]; then
        log_web "ERROR" "Diretório web não encontrado: $WEB_DIR"
        error "Diretório web não encontrado: $WEB_DIR"
        remove_pid
        exit 1
    fi
    cd "$WEB_DIR" || {
        log_web "ERROR" "Falha ao mudar para $WEB_DIR"
        error "Falha ao mudar para $WEB_DIR"
        remove_pid
        exit 1
    }
    log_web "DEBUG" "Diretório atual: $(pwd)"

    # Verificar se python3 está disponível no PATH
    if ! command -v python3 >/dev/null 2>&1; then
        log_web "ERROR" "python3 não encontrado no PATH"
        error "python3 não encontrado no PATH"
        remove_pid
        exit 1
    fi

    # Criar servidor Python simples com melhor captura de erro
    log_web "INFO" "Executando: python3 -m http.server $port"
    python3 -m http.server "$port" >> "$WEB_LOG" 2>&1 &
    local server_pid=$!

    log_web "DEBUG" "PID do servidor capturado: $server_pid"

    # Aguardar um pouco e verificar se o processo ainda roda
    sleep 2
    if ! ps -p "$server_pid" >/dev/null 2>&1; then
        log_web "ERROR" "Servidor parou imediatamente após início (PID $server_pid). Verifique $WEB_LOG para erros."
        # Tentar capturar último erro do log
        local last_error
        last_error=$(tail -5 "$WEB_LOG" 2>/dev/null | grep -i error || echo "Nenhum erro recente encontrado")
        log_web "ERROR" "Último erro no log: $last_error"
        error "Falha ao iniciar servidor web. Verifique logs em $WEB_LOG"
        remove_pid
        exit 1
    fi

    # Verificar se a porta está escutando
    if ! lsof -i :"$port" >/dev/null 2>&1; then
        log_web "ERROR" "Porta $port não está escutando após início"
        error "Porta $port não está escutando. Verifique logs."
        remove_pid
        exit 1
    fi

    log_web "INFO" "Servidor web iniciado com PID: $server_pid na porta $port"
    success "Servidor web iniciado na porta $port"
    echo -e "${CYAN}🌐 Interfaces disponíveis:${NC}"
    echo -e "  ${GREEN}📱 Central de Interfaces${NC}     http://localhost:$port/"
    echo -e "  ${GREEN}🔄 Sistema de Atualizações${NC}  http://localhost:$port/update-interface.html"
    echo -e "  ${GREEN}💾 Gerenciador de Backups${NC}   http://localhost:$port/backup-manager.html"
    echo
    echo -e "${YELLOW}💡 Para parar o servidor: $0 stop${NC}"

    # Salvar PID do servidor (não do script)
    echo $server_pid > "$PID_FILE"

    # Não aguardar - deixar rodar em background
    return 0
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
