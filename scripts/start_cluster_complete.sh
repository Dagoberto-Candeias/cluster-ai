#!/bin/bash
# -*- coding: utf-8 -*-
#
# Cluster AI - Complete Cluster Start Script
# Inicialização completa e integrada do Cluster AI
#
# Projeto: Cluster AI
# Autor: Sistema de consolidação automática
# Data: 2024-12-19
# Versão: 1.0.0
#
# Descrição:
#   Script responsável por inicializar completamente o sistema Cluster AI,
#   incluindo todos os componentes: Dask, Ollama, OpenWebUI, workers,
#   serviços web e monitoramento. Executa verificações de saúde e
#   configurações automáticas.
#
# Uso:
#   ./scripts/start_cluster_complete.sh [opções]
#
# Dependências:
#   - bash
#   - docker/docker-compose
#   - python3
#   - curl, wget
#   - systemctl (opcional)
#
# Changelog:
#   v1.0.0 - 2024-12-19: Criação inicial com funcionalidades completas
#
# ============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório base
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
COMPONENTS_LOG="$LOG_DIR/cluster_start.log"

# Configurações padrão
DASK_PORT=${DASK_PORT:-8786}
DASHBOARD_PORT=${DASHBOARD_PORT:-8787}
OLLAMA_PORT=${OLLAMA_PORT:-11434}
WEBUI_PORT=${WEBUI_PORT:-3000}
WEB_SERVER_PORT=${WEB_SERVER_PORT:-8080}

# Arrays para controle de serviços
SERVICES_STARTED=()
SERVICES_FAILED=()

# Funções utilitárias
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar dependências
check_dependencies() {
    log_info "Verificando dependências do sistema..."

    local missing_deps=()

    # Verificar comandos essenciais
    local required_commands=(
        "docker"
        "python3"
        "curl"
        "wget"
    )

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Dependências faltando: ${missing_deps[*]}"
        log_info "Instale as dependências necessárias e tente novamente"
        return 1
    fi

    log_success "Todas as dependências verificadas"
    return 0
}

# Função para verificar se serviços já estão rodando
check_existing_services() {
    log_info "Verificando serviços existentes..."

    local running_services=()

    # Verificar Dask
    if curl -s "http://localhost:$DASHBOARD_PORT" > /dev/null 2>&1; then
        running_services+=("Dask Dashboard")
    fi

    # Verificar Ollama
    if curl -s "http://localhost:$OLLAMA_PORT/api/tags" > /dev/null 2>&1; then
        running_services+=("Ollama API")
    fi

    # Verificar OpenWebUI
    if curl -s "http://localhost:$WEBUI_PORT" > /dev/null 2>&1; then
        running_services+=("OpenWebUI")
    fi

    if [ ${#running_services[@]} -gt 0 ]; then
        log_warning "Serviços já rodando: ${running_services[*]}"
        read -p "Deseja continuar mesmo assim? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Operação cancelada pelo usuário"
            exit 0
        fi
    fi
}

# Função para iniciar Dask
start_dask() {
    log_info "Iniciando Dask..."

    if [ -f "scripts/dask/start_dask_cluster_fixed.py" ]; then
        python3 scripts/dask/start_dask_cluster_fixed.py >> "$COMPONENTS_LOG" 2>&1
        if [ $? -eq 0 ]; then
            SERVICES_STARTED+=("Dask")
            log_success "Dask iniciado"
            return 0
        fi
    fi

    log_error "Falha ao iniciar Dask"
    SERVICES_FAILED+=("Dask")
    return 1
}

# Função para iniciar Ollama
start_ollama() {
    log_info "Iniciando Ollama..."

    if command -v ollama &> /dev/null; then
        # Verificar se já está rodando
        if ! pgrep -f "ollama serve" > /dev/null; then
            nohup ollama serve > "$LOG_DIR/ollama.log" 2>&1 &
            sleep 5

            if curl -s "http://localhost:$OLLAMA_PORT/api/tags" > /dev/null 2>&1; then
                SERVICES_STARTED+=("Ollama")
                log_success "Ollama iniciado"
                return 0
            fi
        else
            SERVICES_STARTED+=("Ollama")
            log_success "Ollama já estava rodando"
            return 0
        fi
    fi

    log_error "Falha ao iniciar Ollama"
    SERVICES_FAILED+=("Ollama")
    return 1
}

# Função para iniciar OpenWebUI
start_openwebui() {
    log_info "Iniciando OpenWebUI..."

    if [ -f "scripts/start_openwebui.sh" ]; then
        bash scripts/start_openwebui.sh >> "$COMPONENTS_LOG" 2>&1
        if [ $? -eq 0 ]; then
            SERVICES_STARTED+=("OpenWebUI")
            log_success "OpenWebUI iniciado"
            return 0
        fi
    fi

    log_error "Falha ao iniciar OpenWebUI"
    SERVICES_FAILED+=("OpenWebUI")
    return 1
}

# Função para iniciar servidor web
start_web_server() {
    log_info "Iniciando servidor web..."

    if [ -f "scripts/web_server.sh" ]; then
        nohup bash scripts/web_server.sh start $WEB_SERVER_PORT > "$LOG_DIR/web_server.log" 2>&1 &
        sleep 3

        if curl -s "http://localhost:$WEB_SERVER_PORT" > /dev/null 2>&1; then
            SERVICES_STARTED+=("Web Server")
            log_success "Servidor web iniciado"
            return 0
        fi
    fi

    log_error "Falha ao iniciar servidor web"
    SERVICES_FAILED+=("Web Server")
    return 1
}

# Função para iniciar workers
start_workers() {
    log_info "Iniciando workers..."

    # Iniciar worker local
    if [ -f "scripts/workers/start_local_worker.sh" ]; then
        bash scripts/workers/start_local_worker.sh >> "$COMPONENTS_LOG" 2>&1 &
        SERVICES_STARTED+=("Local Worker")
        log_success "Worker local iniciado"
    fi

    # Iniciar Android workers se configurados
    if [ -f "scripts/android/setup_android_worker_consolidated.sh" ]; then
        log_info "Verificando workers Android..."
        # Implementar verificação de workers Android
    fi
}

# Função para verificar saúde do sistema
check_system_health() {
    log_info "Verificando saúde do sistema..."

    local health_issues=()

    # Verificar Dask
    if ! curl -s "http://localhost:$DASHBOARD_PORT" > /dev/null 2>&1; then
        health_issues+=("Dask Dashboard não responde")
    fi

    # Verificar Ollama
    if ! curl -s "http://localhost:$OLLAMA_PORT/api/tags" > /dev/null 2>&1; then
        health_issues+=("Ollama API não responde")
    fi

    # Verificar OpenWebUI
    if ! curl -s "http://localhost:$WEBUI_PORT" > /dev/null 2>&1; then
        health_issues+=("OpenWebUI não responde")
    fi

    if [ ${#health_issues[@]} -gt 0 ]; then
        log_warning "Problemas de saúde detectados:"
        printf '%s\n' "${health_issues[@]}" >&2
        return 1
    fi

    log_success "Sistema saudável"
    return 0
}

# Função para mostrar status final
show_final_status() {
    log_info "=== STATUS FINAL DO CLUSTER ==="

    echo "✅ Serviços Iniciados:"
    if [ ${#SERVICES_STARTED[@]} -gt 0 ]; then
        printf '  - %s\n' "${SERVICES_STARTED[@]}"
    else
        echo "  Nenhum"
    fi

    echo "❌ Serviços com Falha:"
    if [ ${#SERVICES_FAILED[@]} -gt 0 ]; then
        printf '  - %s\n' "${SERVICES_FAILED[@]}"
    else
        echo "  Nenhum"
    fi

    echo "🌐 URLs de Acesso:"
    echo "  - Dask Dashboard: http://localhost:$DASHBOARD_PORT"
    echo "  - Ollama API: http://localhost:$OLLAMA_PORT"
    echo "  - OpenWebUI: http://localhost:$WEBUI_PORT"
    echo "  - Web Server: http://localhost:$WEB_SERVER_PORT"

    echo "📝 Logs:"
    echo "  - Principal: $COMPONENTS_LOG"
    echo "  - Dask: $LOG_DIR/dask.log"
    echo "  - Ollama: $LOG_DIR/ollama.log"
    echo "  - Web: $LOG_DIR/web_server.log"
}

# Função para parar todos os serviços
stop_all_services() {
    log_info "Parando todos os serviços..."

    # Parar web server
    if [ -f "scripts/web_server.sh" ]; then
        bash scripts/web_server.sh stop
    fi

    # Parar OpenWebUI
    if [ -f "scripts/stop_openwebui.sh" ]; then
        bash scripts/stop_openwebui.sh
    fi

    # Parar Ollama
    pkill -f "ollama serve" 2>/dev/null || true

    # Parar Dask
    if [ -f "scripts/dask/stop_dask_cluster.sh" ]; then
        bash scripts/dask/stop_dask_cluster.sh
    fi

    log_success "Serviços parados"
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    # Criar diretório de logs
    mkdir -p "$LOG_DIR"
    touch "$COMPONENTS_LOG"

    case "${1:-help}" in
        "start")
            log_info "🚀 Iniciando Cluster AI completo..."

            # Verificações iniciais
            check_dependencies || exit 1
            check_existing_services

            # Iniciar componentes
            start_dask
            start_ollama
            start_openwebui
            start_web_server
            start_workers

            # Verificar saúde
            sleep 5
            check_system_health

            # Status final
            show_final_status
            ;;
        "stop")
            stop_all_services
            ;;
        "restart")
            stop_all_services
            sleep 2
            main "start"
            ;;
        "status")
            check_system_health
            show_final_status
            ;;
        "health")
            check_system_health
            ;;
        "help"|*)
            echo "Cluster AI - Complete Cluster Start Script"
            echo ""
            echo "Uso: $0 [comando]"
            echo ""
            echo "Comandos:"
            echo "  start     - Inicia todos os componentes do cluster"
            echo "  stop      - Para todos os serviços"
            echo "  restart   - Reinicia todos os serviços"
            echo "  status    - Mostra status completo do sistema"
            echo "  health    - Verifica saúde do sistema"
            echo "  help      - Mostra esta mensagem de ajuda"
            echo ""
            echo "Configurações (definir como variáveis de ambiente):"
            echo "  DASK_PORT        - Porta do Dask (padrão: 8786)"
            echo "  DASHBOARD_PORT   - Porta do Dashboard (padrão: 8787)"
            echo "  OLLAMA_PORT      - Porta do Ollama (padrão: 11434)"
            echo "  WEBUI_PORT       - Porta do OpenWebUI (padrão: 3000)"
            echo "  WEB_SERVER_PORT  - Porta do Web Server (padrão: 8080)"
            echo ""
            echo "Exemplo:"
            echo "  $0 start"
            ;;
    esac
}

# Executar função principal
main "$@"
