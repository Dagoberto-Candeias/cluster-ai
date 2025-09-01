#!/bin/bash

# Auto Setup Script para Cluster AI
# Configura automaticamente servidor ou worker baseado na detecção

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Função para detectar se é servidor ou worker
detect_node_role() {
    log "🔍 Detectando papel do nó..."

    # Verificar se já existe configuração
    if [ -f "cluster.conf" ]; then
        if grep -q "NODE_ROLE=server" cluster.conf; then
            echo "server"
            return
        elif grep -q "NODE_ROLE=worker" cluster.conf; then
            echo "worker"
            return
        fi
    fi

    # Detectar baseado em recursos do sistema
    CPU_CORES=$(nproc)
    TOTAL_MEM=$(free -g | awk 'NR==2{printf "%.0f", $2}')

    log "Sistema detectado: ${CPU_CORES} cores CPU, ${TOTAL_MEM}GB RAM"

    # Se tem mais de 4 cores e 8GB RAM, assume servidor
    if [ "$CPU_CORES" -gt 4 ] && [ "$TOTAL_MEM" -gt 8 ]; then
        echo "server"
    else
        echo "worker"
    fi
}

# Função para obter IP local
get_local_ip() {
    # Tentar diferentes métodos para obter IP
    LOCAL_IP=$(ip route get 8.8.8.8 | awk 'NR==1 {print $7}')
    if [ -z "$LOCAL_IP" ]; then
        LOCAL_IP=$(hostname -I | awk '{print $1}')
    fi
    echo $LOCAL_IP
}

# Função para descobrir servidor na rede
discover_server() {
    log "🔍 Procurando servidor na rede..."

    LOCAL_IP=$(get_local_ip)
    NETWORK_PREFIX=$(echo $LOCAL_IP | cut -d'.' -f1-3)

    info "IP local: $LOCAL_IP"
    info "Procurando na rede: ${NETWORK_PREFIX}.0/24"

    # Usar nmap para encontrar hosts com porta 8786 (Dask scheduler)
    if command -v nmap &> /dev/null; then
        SERVER_IP=$(nmap -p 8786 --open ${NETWORK_PREFIX}.0/24 -oG - | grep "8786/open" | awk '{print $2}' | head -1)
        if [ ! -z "$SERVER_IP" ]; then
            echo $SERVER_IP
            return
        fi
    fi

    # Fallback: tentar IPs comuns
    for i in {1..254}; do
        IP="${NETWORK_PREFIX}.${i}"
        if [ "$IP" != "$LOCAL_IP" ]; then
            if timeout 2 bash -c "echo >/dev/tcp/$IP/8786" 2>/dev/null; then
                echo $IP
                return
            fi
        fi
    done

    echo ""
}

# Função para configurar servidor
setup_server() {
    log "🚀 Configurando como SERVIDOR..."

    # Criar configuração do cluster
    cat > cluster.conf << EOF
# Configuração do Cluster AI - Servidor
NODE_ROLE=server
NODE_IP=$(get_local_ip)
NODE_HOSTNAME=$(hostname)
CLUSTER_NAME=cluster-ai-main
DASK_SCHEDULER_PORT=8786
DASK_DASHBOARD_PORT=8787
OLLAMA_PORT=11434
OPENWEBUI_PORT=3000
EOF

    log "📝 Configuração criada em cluster.conf"

    # Instalar dependências se necessário
    if [ ! -f "requirements.txt" ]; then
        error "Arquivo requirements.txt não encontrado!"
        exit 1
    fi

    # Verificar se Python virtual env existe
    if [ ! -d "venv" ]; then
        log "🐍 Criando ambiente virtual Python..."
        python3 -m venv venv
    fi

    # Ativar venv e instalar dependências
    source venv/bin/activate
    pip install -r requirements.txt

    # Iniciar serviços do servidor
    log "⚡ Iniciando serviços do servidor..."
    ./manager.sh start

    # Aguardar serviços ficarem prontos
    sleep 5

    # Verificar status
    if ./scripts/utils/health_check.sh; then
        log "✅ Servidor configurado com sucesso!"
        info "🌐 Acesse o dashboard em: http://$(get_local_ip):8787"
        info "🤖 OpenWebUI em: http://$(get_local_ip):3000"
    else
        warn "⚠️ Alguns serviços podem não estar funcionando corretamente"
    fi
}

# Função para configurar worker
setup_worker() {
    log "🔧 Configurando como WORKER..."

    # Descobrir servidor
    SERVER_IP=$(discover_server)

    if [ -z "$SERVER_IP" ]; then
        error "❌ Nenhum servidor encontrado na rede!"
        info "Certifique-se de que o servidor está rodando e na mesma rede"
        info "Você pode especificar o IP do servidor manualmente:"
        echo "  ./auto_setup.sh --server-ip IP_DO_SERVIDOR"
        exit 1
    fi

    log "🎯 Servidor encontrado: $SERVER_IP"

    # Criar configuração do worker
    cat > cluster.conf << EOF
# Configuração do Cluster AI - Worker
NODE_ROLE=worker
NODE_IP=$(get_local_ip)
NODE_HOSTNAME=$(hostname)
SERVER_IP=$SERVER_IP
DASK_SCHEDULER_PORT=8786
DASK_DASHBOARD_PORT=8787
EOF

    log "📝 Configuração criada em cluster.conf"

    # Instalar dependências se necessário
    if [ ! -f "requirements.txt" ]; then
        error "Arquivo requirements.txt não encontrado!"
        exit 1
    fi

    # Verificar se Python virtual env existe
    if [ ! -d "venv" ]; then
        log "🐍 Criando ambiente virtual Python..."
        python3 -m venv venv
    fi

    # Ativar venv e instalar dependências
    source venv/bin/activate
    pip install -r requirements.txt

    # Configurar SSH key se não existir
    if [ ! -f "~/.ssh/id_rsa" ]; then
        log "🔑 Gerando chave SSH..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    fi

    # Tentar conectar ao servidor
    log "🔗 Conectando ao servidor..."
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 $SERVER_IP "echo 'Conexão SSH estabelecida'" 2>/dev/null; then
        log "✅ Conexão SSH estabelecida com o servidor"

        # Copiar chave SSH para o servidor
        ssh-copy-id -o StrictHostKeyChecking=no $SERVER_IP

        # Registrar worker no servidor
        log "📝 Registrando worker no servidor..."
        ssh $SERVER_IP "cd ~/cluster-ai && ./scripts/deployment/register_worker_node.sh $(get_local_ip)"

    else
        warn "⚠️ Não foi possível estabelecer conexão SSH automática"
        info "Você precisará configurar o SSH manualmente:"
        info "1. Copie sua chave SSH: ssh-copy-id usuario@$SERVER_IP"
        info "2. Execute no servidor: ./scripts/deployment/register_worker_node.sh $(get_local_ip)"
    fi

    # Iniciar worker local
    log "⚡ Iniciando worker local..."
    ./scripts/runtime/start_worker.sh

    log "✅ Worker configurado com sucesso!"
    info "🔗 Conectado ao servidor: $SERVER_IP"
}

# Função principal
main() {
    log "🚀 Iniciando Auto Setup do Cluster AI"

    # Verificar se estamos no diretório correto
    if [ ! -f "manager.sh" ]; then
        error "❌ Arquivo manager.sh não encontrado!"
        error "Execute este script dentro do diretório cluster-ai"
        exit 1
    fi

    # Verificar argumentos
    if [ "$1" = "--server-ip" ] && [ ! -z "$2" ]; then
        SERVER_IP="$2"
        log "🎯 IP do servidor especificado: $SERVER_IP"
        setup_worker
        exit 0
    fi

    # Detectar papel do nó
    NODE_ROLE=$(detect_node_role)

    case $NODE_ROLE in
        "server")
            setup_server
            ;;
        "worker")
            setup_worker
            ;;
        *)
            error "❌ Não foi possível determinar o papel do nó"
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"
