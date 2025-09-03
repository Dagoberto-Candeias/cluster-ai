#!/bin/bash
# Script para ativar o Cluster AI como servidor completo
# Inicia todos os serviços necessários automaticamente

set -euo pipefail

# =============================================================================
# Cluster AI - Ativação do Servidor
# =============================================================================

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Constantes ---
SERVICES_CONFIG="${PROJECT_ROOT}/configs/services.conf"
LOG_FILE="${PROJECT_ROOT}/logs/server_activation.log"
CONFIG_FILE="${PROJECT_ROOT}/cluster.conf"

# --- Funções ---

# Funções auxiliares
section() {
    echo
    echo "=============================="
    echo " $1"
    echo "=============================="
}

subsection() {
    echo
    echo "---- $1 ----"
}

progress() {
    echo "[...] $1"
}

success() {
    echo "[SUCCESS] $1"
}

error() {
    echo "[ERROR] $1"
}

warn() {
    echo "[WARN] $1"
}

info() {
    echo "[INFO] $1"
}

# Verifica pré-requisitos do sistema
check_prerequisites() {
    section "Verificando Pré-requisitos"

    local missing_deps=()

    # Funções auxiliares
    command_exists() {
        command -v "$1" >/dev/null 2>&1
    }

    # Verificar comandos essenciais
    if ! command_exists docker; then
        missing_deps+=("docker")
    fi

    if ! command_exists python3; then
        missing_deps+=("python3")
    fi

    if ! command_exists curl; then
        missing_deps+=("curl")
    fi

    if ! command_exists nmap; then
        missing_deps+=("nmap")
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        error "Dependências faltando: ${missing_deps[*]}"
        info "Execute: sudo apt install ${missing_deps[*]}"
        return 1
    fi

    success "Pré-requisitos OK"
    return 0
}

# Verifica configuração do cluster
check_configuration() {
    section "Verificando Configuração"

    if [ ! -f "$CONFIG_FILE" ]; then
        error "Arquivo de configuração não encontrado: $CONFIG_FILE"
        info "Execute ./install.sh primeiro"
        return 1
    fi

    # Carregar configuração básica se existir
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE" 2>/dev/null || true
    fi

    success "Configuração carregada"
    return 0
}

# Inicia serviço Docker
start_docker() {
    subsection "Iniciando Docker"

    if ! command_exists docker; then
        warn "Docker não encontrado, pulando..."
        return 0
    fi

    if docker info >/dev/null 2>&1; then
        success "Docker já está ativo"
        return 0
    fi

    progress "Iniciando serviço Docker..."
    if sudo systemctl start docker 2>/dev/null; then
        sleep 2
        if docker info >/dev/null 2>&1; then
            success "Docker iniciado com sucesso"
            return 0
        fi
    fi

    error "Falha ao iniciar Docker"
    return 1
}

# Inicia Dask
start_dask() {
    subsection "Iniciando Dask"

    local scheduler_port="${DASK_SCHEDULER_PORT:-8786}"
    local dashboard_port="${DASK_DASHBOARD_PORT:-8787}"

    # Função auxiliar para verificar porta
    is_port_open() {
        timeout 2 bash -c "echo >/dev/tcp/localhost/$1" 2>/dev/null
    }

    if is_port_open "$scheduler_port"; then
        success "Dask Scheduler já está ativo (porta $scheduler_port)"
        return 0
    fi

    progress "Iniciando Dask Scheduler..."

    # Criar script temporário para iniciar Dask
    cat > /tmp/start_dask.sh << 'EOF'
#!/bin/bash
source .venv/bin/activate 2>/dev/null || true
cd /home/dcm/Projetos/cluster-ai
python -c "
import dask
from dask.distributed import Client, LocalCluster
import time
import os

print('Iniciando cluster Dask com segurança...')

# Configurações de segurança
cert_file = 'certs/dask_cert.pem'
key_file = 'certs/dask_key.pem'
auth_token = 'secure_token_12345'

security = {
    'tls': {
        'cert': cert_file,
        'key': key_file
    },
    'require_encryption': True,
    'auth': auth_token
}

cluster = LocalCluster(
    n_workers=2,
    threads_per_worker=2,
    dashboard_address=':8787',
    processes=False,
    security=security
)
client = Client(cluster)
print(f'Dask Dashboard: https://localhost:8787/status')
print(f'Dask Scheduler: {cluster.scheduler_address}')
print('Dask iniciado com TLS e autenticação. Pressione Ctrl+C para parar.')

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print('Encerrando Dask...')
    client.close()
    cluster.close()
"
EOF

    chmod +x /tmp/start_dask.sh

    # Iniciar Dask em background
    nohup /tmp/start_dask.sh > /tmp/dask.log 2>&1 &
    echo $! > /tmp/dask.pid

    # Aguardar inicialização
    local retries=10
    while [ $retries -gt 0 ]; do
        if is_port_open "$scheduler_port" && is_port_open "$dashboard_port"; then
            success "Dask iniciado com sucesso"
            success "  📊 Scheduler: http://localhost:$scheduler_port"
            success "  📈 Dashboard: http://localhost:$dashboard_port"
            return 0
        fi
        sleep 2
        retries=$((retries - 1))
    done

    error "Falha ao iniciar Dask"
    return 1
}

# Inicia Ollama
start_ollama() {
    subsection "Iniciando Ollama"

    local port="${OLLAMA_PORT:-11434}"

    if is_port_open "$port"; then
        success "Ollama já está ativo (porta $port)"
        return 0
    fi

    progress "Iniciando serviço Ollama..."

    # Tentar iniciar via systemd primeiro
    if sudo systemctl start ollama 2>/dev/null; then
        sleep 3
        if is_port_open "$port"; then
            success "Ollama iniciado via systemd"
            return 0
        fi
    fi

    # Se não conseguiu via systemd, tentar iniciar manualmente
    if command_exists ollama; then
        nohup ollama serve > /tmp/ollama.log 2>&1 &
        echo $! > /tmp/ollama.pid

        local retries=10
        while [ $retries -gt 0 ]; do
            if is_port_open "$port"; then
                success "Ollama iniciado manualmente"
                return 0
            fi
            sleep 2
            retries=$((retries - 1))
        done
    fi

    error "Falha ao iniciar Ollama"
    return 1
}

# Inicia OpenWebUI
start_openwebui() {
    subsection "Iniciando OpenWebUI"

    local port="${OPENWEBUI_PORT:-3000}"

    if is_port_open "$port"; then
        success "OpenWebUI já está ativo (porta $port)"
        return 0
    fi

    progress "Iniciando OpenWebUI..."

    # Verificar se há container Docker do OpenWebUI
    if command_exists docker && docker ps | grep -q openwebui; then
        success "OpenWebUI já está rodando em container Docker"
        return 0
    fi

    # Tentar iniciar via Docker Compose
    if file_exists "configs/docker/compose.yml" || file_exists "docker-compose.yml"; then
        progress "Iniciando via Docker Compose..."
        if docker-compose up -d openwebui 2>/dev/null || docker compose up -d openwebui 2>/dev/null; then
            sleep 5
            if is_port_open "$port"; then
                success "OpenWebUI iniciado via Docker Compose"
                success "  🌐 WebUI: http://localhost:$port"
                return 0
            fi
        fi
    fi

    # Se não conseguiu via Docker, verificar se há instalação local
    if command_exists open-webui; then
        nohup open-webui --host 0.0.0.0 --port "$port" > /tmp/openwebui.log 2>&1 &
        echo $! > /tmp/openwebui.pid

        local retries=15
        while [ $retries -gt 0 ]; do
            if is_port_open "$port"; then
                success "OpenWebUI iniciado localmente"
                success "  🌐 WebUI: http://localhost:$port"
                return 0
            fi
            sleep 2
            retries=$((retries - 1))
        done
    fi

    error "Falha ao iniciar OpenWebUI"
    return 1
}

# Inicia Nginx
start_nginx() {
    subsection "Iniciando Nginx"

    if command_exists nginx && pgrep nginx >/dev/null; then
        success "Nginx já está ativo"
        return 0
    fi

    if ! command_exists nginx; then
        warn "Nginx não instalado, pulando..."
        return 0
    fi

    progress "Iniciando serviço Nginx..."
    if sudo systemctl start nginx 2>/dev/null; then
        sleep 2
        if pgrep nginx >/dev/null; then
            success "Nginx iniciado com sucesso"
            return 0
        fi
    fi

    error "Falha ao iniciar Nginx"
    return 1
}

# Verifica status de todos os serviços
verify_services() {
    section "Verificando Status dos Serviços"

    local all_good=true

    # Docker
    if command_exists docker && docker info >/dev/null 2>&1; then
        success "🐳 Docker: Ativo"
    else
        error "🐳 Docker: Inativo"
        all_good=false
    fi

    # Dask
    if is_port_open "${DASK_SCHEDULER_PORT:-8786}"; then
        success "📊 Dask Scheduler: Ativo (porta ${DASK_SCHEDULER_PORT:-8786})"
    else
        error "📊 Dask Scheduler: Inativo"
        all_good=false
    fi

    if is_port_open "${DASK_DASHBOARD_PORT:-8787}"; then
        success "📈 Dask Dashboard: Ativo (porta ${DASK_DASHBOARD_PORT:-8787})"
    else
        error "📈 Dask Dashboard: Inativo"
        all_good=false
    fi

    # Ollama
    if is_port_open "${OLLAMA_PORT:-11434}"; then
        success "🧠 Ollama: Ativo (porta ${OLLAMA_PORT:-11434})"
    else
        error "🧠 Ollama: Inativo"
        all_good=false
    fi

    # OpenWebUI
    if is_port_open "${OPENWEBUI_PORT:-3000}"; then
        success "🌐 OpenWebUI: Ativo (porta ${OPENWEBUI_PORT:-3000})"
    else
        error "🌐 OpenWebUI: Inativo"
        all_good=false
    fi

    # Nginx
    if command_exists nginx && pgrep nginx >/dev/null; then
        success "🌐 Nginx: Ativo"
    else
        warn "🌐 Nginx: Inativo"
    fi

    echo

    if $all_good; then
        success "🎉 Todos os serviços principais estão ativos!"
        return 0
    else
        warn "⚠️  Alguns serviços não puderam ser iniciados"
        return 1
    fi
}

# Função principal
main() {
    section "🚀 Ativando Cluster AI como Servidor"

    # Criar diretório de logs
    mkdir -p "${PROJECT_ROOT}/logs"

    # Verificar pré-requisitos
    if ! check_prerequisites; then
        exit 1
    fi

    # Verificar configuração
    if ! check_configuration; then
        exit 1
    fi

    # Iniciar serviços na ordem correta
    start_docker
    start_dask
    start_ollama
    start_openwebui
    start_nginx

    # Verificar status final
    echo
    verify_services

    # Salvar informações de processos
    echo
    subsection "Informações dos Processos"
    if [ -f /tmp/dask.pid ]; then
        info "Dask PID: $(cat /tmp/dask.pid)"
    fi
    if [ -f /tmp/ollama.pid ]; then
        info "Ollama PID: $(cat /tmp/ollama.pid)"
    fi
    if [ -f /tmp/openwebui.pid ]; then
        info "OpenWebUI PID: $(cat /tmp/openwebui.pid)"
    fi

    echo
    success "🎯 Ativação do servidor concluída!"
    echo
    info "Serviços disponíveis:"
    info "  📊 Dask Dashboard: http://localhost:${DASK_DASHBOARD_PORT:-8787}"
    info "  🌐 OpenWebUI: http://localhost:${OPENWEBUI_PORT:-3000}"
    info "  🧠 Ollama API: http://localhost:${OLLAMA_PORT:-11434}"
    echo
    info "Para parar todos os serviços: ./manager.sh stop"
    info "Para verificar status: ./manager.sh status"
}

# Executar função principal
main "$@"
