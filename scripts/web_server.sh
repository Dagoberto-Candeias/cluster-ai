#!/bin/bash
# -*- coding: utf-8 -*-
#
# Cluster AI - Web Server Script
# Servidor web para interfaces do Cluster AI
#
# Projeto: Cluster AI
# Autor: Sistema de consolidação automática
# Data: 2024-12-19
# Versão: 1.0.0
#
# Descrição:
#   Script responsável por iniciar e gerenciar o servidor web para as
#   interfaces do Cluster AI. Serve páginas HTML, gerencia configurações
#   e fornece endpoints para integração com o sistema.
#
# Uso:
#   ./scripts/web_server.sh [comando] [porta]
#
# Dependências:
#   - bash
#   - python3 (para servidor HTTP)
#   - netstat, lsof (para verificação de porta)
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
WEB_DIR="$PROJECT_ROOT/web"
LOG_DIR="$PROJECT_ROOT/logs"
DEFAULT_PORT=8080

# Configurações
SERVER_PID_FILE="/tmp/cluster_ai_web_server.pid"
LOG_FILE="$LOG_DIR/web_server.log"

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

# Função para verificar se a porta está em uso
check_port() {
    local port=${1:-$DEFAULT_PORT}

    if command -v netstat &> /dev/null; then
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            return 0  # Porta em uso
        fi
    elif command -v lsof &> /dev/null; then
        if lsof -i :$port &> /dev/null; then
            return 0  # Porta em uso
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln 2>/dev/null | grep -q ":$port "; then
            return 0  # Porta em uso
        fi
    fi

    return 1  # Porta livre
}

# Função para iniciar servidor web
start_web_server() {
    local port=${1:-$DEFAULT_PORT}

    log_info "Iniciando servidor web na porta $port..."

    # Verificar se a porta está em uso
    if check_port $port; then
        log_error "Porta $port já está em uso"
        log_info "Tente uma porta diferente ou pare o serviço existente"
        return 1
    fi

    # Criar diretório web se não existir
    mkdir -p "$WEB_DIR"

    # Criar arquivo de log se não existir
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"

    # Iniciar servidor Python HTTP simples
    cd "$WEB_DIR"
    nohup python3 -m http.server $port > "$LOG_FILE" 2>&1 &
    local server_pid=$!

    # Salvar PID
    echo $server_pid > "$SERVER_PID_FILE"

    # Aguardar um pouco para verificar se iniciou
    sleep 2

    if ps -p $server_pid > /dev/null; then
        log_success "Servidor web iniciado com PID $server_pid"
        log_success "Acesse: http://localhost:$port"
        log_info "Logs: $LOG_FILE"
        return 0
    else
        log_error "Falha ao iniciar servidor web"
        rm -f "$SERVER_PID_FILE"
        return 1
    fi
}

# Função para parar servidor web
stop_web_server() {
    log_info "Parando servidor web..."

    if [ -f "$SERVER_PID_FILE" ]; then
        local server_pid=$(cat "$SERVER_PID_FILE")

        if ps -p $server_pid > /dev/null; then
            kill $server_pid
            sleep 2

            if ps -p $server_pid > /dev/null; then
                log_warning "Servidor não parou normalmente, forçando..."
                kill -9 $server_pid
            fi

            log_success "Servidor web parado"
        else
            log_warning "Servidor não estava rodando (PID $server_pid)"
        fi

        rm -f "$SERVER_PID_FILE"
    else
        log_info "Arquivo PID não encontrado, servidor pode não estar rodando"
    fi
}

# Função para verificar status do servidor
check_web_server_status() {
    log_info "Verificando status do servidor web..."

    if [ -f "$SERVER_PID_FILE" ]; then
        local server_pid=$(cat "$SERVER_PID_FILE")

        if ps -p $server_pid > /dev/null; then
            log_success "Servidor web está rodando (PID: $server_pid)"
            return 0
        else
            log_warning "Servidor web não está rodando (PID: $server_pid - processo morto)"
            rm -f "$SERVER_PID_FILE"
            return 1
        fi
    else
        log_info "Servidor web não está rodando"
        return 1
    fi
}

# Função para mostrar logs do servidor
show_web_server_logs() {
    local lines=${1:-20}

    if [ -f "$LOG_FILE" ]; then
        log_info "Mostrando últimas $lines linhas do log:"
        tail -n $lines "$LOG_FILE"
    else
        log_warning "Arquivo de log não encontrado: $LOG_FILE"
    fi
}

# Função para criar página HTML básica
create_basic_html() {
    log_info "Criando página HTML básica..."

    mkdir -p "$WEB_DIR"

    cat > "$WEB_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Cluster AI - Interface Web</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .status {
            padding: 15px;
            border-radius: 5px;
            margin: 10px 0;
        }
        .success { background-color: #d4edda; color: #155724; }
        .info { background-color: #d1ecf1; color: #0c5460; }
        .warning { background-color: #fff3cd; color: #856404; }
        .error { background-color: #f8d7da; color: #721c24; }
        .card {
            background: #f8f9fa;
            padding: 20px;
            margin: 20px 0;
            border-radius: 5px;
            border-left: 4px solid #007bff;
        }
        .btn {
            background: #007bff;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
        }
        .btn:hover { background: #0056b3; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🤖 Cluster AI - Interface Web</h1>

        <div class="status success">
            <h3>✅ Sistema Online</h3>
            <p>Servidor web do Cluster AI está funcionando corretamente.</p>
        </div>

        <div class="card">
            <h3>🚀 Acesso às Interfaces</h3>
            <p><a href="/update-interface.html" class="btn">Interface de Atualizações</a></p>
            <p><a href="/backup-manager.html" class="btn">Gerenciador de Backups</a></p>
            <p><a href="/dashboard.html" class="btn">Dashboard Principal</a></p>
        </div>

        <div class="card">
            <h3>📊 Status do Sistema</h3>
            <div class="status info">
                <p>🌐 Servidor Web: Porta 8080</p>
                <p>📁 Diretório Web: /web</p>
                <p>📝 Logs: /logs/web_server.log</p>
            </div>
        </div>

        <div class="card">
            <h3>🔧 Comandos Disponíveis</h3>
            <ul>
                <li><code>./scripts/web_server.sh start</code> - Iniciar servidor</li>
                <li><code>./scripts/web_server.sh stop</code> - Parar servidor</li>
                <li><code>./scripts/web_server.sh status</code> - Verificar status</li>
                <li><code>./scripts/web_server.sh logs</code> - Ver logs</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF

    log_success "Página HTML básica criada em $WEB_DIR/index.html"
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    case "${1:-help}" in
        "start")
            start_web_server "${2:-$DEFAULT_PORT}"
            ;;
        "stop")
            stop_web_server
            ;;
        "restart")
            stop_web_server
            sleep 1
            start_web_server "${2:-$DEFAULT_PORT}"
            ;;
        "status")
            check_web_server_status
            ;;
        "logs")
            show_web_server_logs "${2:-20}"
            ;;
        "create-html")
            create_basic_html
            ;;
        "help"|*)
            echo "Cluster AI - Web Server Script"
            echo ""
            echo "Uso: $0 [comando] [porta]"
            echo ""
            echo "Comandos:"
            echo "  start [porta]    - Inicia servidor web (padrão: 8080)"
            echo "  stop             - Para servidor web"
            echo "  restart [porta]  - Reinicia servidor web"
            echo "  status           - Verifica status do servidor"
            echo "  logs [linhas]    - Mostra logs do servidor (padrão: 20 linhas)"
            echo "  create-html      - Cria página HTML básica"
            echo "  help             - Mostra esta mensagem de ajuda"
            echo ""
            echo "Exemplos:"
            echo "  $0 start 8080"
            echo "  $0 stop"
            echo "  $0 status"
            echo "  $0 logs 50"
            ;;
    esac
}

# Executar função principal
main "$@"
