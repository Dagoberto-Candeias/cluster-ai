#!/bin/bash
# Gerenciador de Firewall para Cluster AI

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/cluster.conf"

# Carregar funções comuns
COMMON_SCRIPT_PATH="${PROJECT_ROOT}/scripts/utils/common.sh"
if [ -f "$COMMON_SCRIPT_PATH" ]; then
    source "$COMMON_SCRIPT_PATH"
else
    # Fallback para cores e logs se common.sh não for encontrado
    RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
    error() { echo -e "${RED}[ERROR]${NC} $1"; }
    warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
    log() { echo -e "${GREEN}[INFO]${NC} $1"; }
    success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
    section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
    confirm_operation() {
        read -p "$1 (s/N): " -n 1 -r; echo
        [[ $REPLY =~ ^[Ss]$ ]]
    }
fi

# Carregar configurações
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Configurações padrão
NODE_IP="${NODE_IP:-192.168.0.2}"
DASK_SCHEDULER_PORT="${DASK_SCHEDULER_PORT:-8786}"
DASK_DASHBOARD_PORT="${DASK_DASHBOARD_PORT:-8787}"
OLLAMA_PORT="${OLLAMA_PORT:-11434}"
OPENWEBUI_PORT="${OPENWEBUI_PORT:-3000}"
WORKER_MANJARO_IP="${WORKER_MANJARO_IP:-192.168.0.4}"
SECONDARY_IP="${NODE_IP_SECONDARY:-192.168.0.3}"
SECONDARY_PORT="${DASK_SCHEDULER_SECONDARY_PORT:-8788}"

LOG_FILE="${PROJECT_ROOT}/logs/firewall.log"

# Função para detectar gerenciador de firewall
detect_firewall_manager() {
    if command -v ufw >/dev/null 2>&1; then
        echo "ufw"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        echo "firewalld"
    elif command -v iptables >/dev/null 2>&1; then
        echo "iptables"
    else
        echo "none"
    fi
}

# Função para configurar UFW
configure_ufw() {
    section "Configurando UFW Firewall"

    log "Habilitando UFW..."
    sudo ufw --force enable

    log "Configurando regras básicas..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    log "Permitindo portas do Cluster AI..."

    # Portas do scheduler primário
    sudo ufw allow from "${WORKER_MANJARO_IP}" to any port "${DASK_SCHEDULER_PORT}" proto tcp
    sudo ufw allow from "${SECONDARY_IP}" to any port "${DASK_SCHEDULER_PORT}" proto tcp

    # Porta do dashboard
    sudo ufw allow from "${WORKER_MANJARO_IP}" to any port "${DASK_DASHBOARD_PORT}" proto tcp
    sudo ufw allow from "${SECONDARY_IP}" to any port "${DASK_DASHBOARD_PORT}" proto tcp

    # Porta do scheduler secundário
    sudo ufw allow from "${WORKER_MANJARO_IP}" to "${SECONDARY_IP}" port "${SECONDARY_PORT}" proto tcp
    sudo ufw allow from "${NODE_IP}" to "${SECONDARY_IP}" port "${SECONDARY_PORT}" proto tcp

    # Porta do Ollama (apenas local)
    sudo ufw allow from 127.0.0.1 to any port "${OLLAMA_PORT}" proto tcp

    # Porta do OpenWebUI
    sudo ufw allow from "${WORKER_MANJARO_IP}" to any port "${OPENWEBUI_PORT}" proto tcp

    # SSH (essencial para administração)
    sudo ufw allow ssh

    log "Recarregando UFW..."
    sudo ufw reload

    success "UFW configurado com sucesso!"
}

# Função para configurar Firewalld
configure_firewalld() {
    section "Configurando Firewalld"

    log "Configurando zona padrão..."
    sudo firewall-cmd --set-default-zone=drop

    log "Adicionando regras do Cluster AI..."

    # Portas do scheduler primário
    sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='${WORKER_MANJARO_IP}' port port='${DASK_SCHEDULER_PORT}' protocol='tcp' accept"
    sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='${SECONDARY_IP}' port port='${DASK_SCHEDULER_PORT}' protocol='tcp' accept"

    # Porta do dashboard
    sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='${WORKER_MANJARO_IP}' port port='${DASK_DASHBOARD_PORT}' protocol='tcp' accept"
    sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='${SECONDARY_IP}' port port='${DASK_DASHBOARD_PORT}' protocol='tcp' accept"

    # Porta do scheduler secundário
    sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='${WORKER_MANJARO_IP}' destination address='${SECONDARY_IP}' port port='${SECONDARY_PORT}' protocol='tcp' accept"
    sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='${NODE_IP}' destination address='${SECONDARY_IP}' port port='${SECONDARY_PORT}' protocol='tcp' accept"

    # Porta do Ollama (apenas local)
    sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='127.0.0.1' port port='${OLLAMA_PORT}' protocol='tcp' accept"

    # Porta do OpenWebUI
    sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='${WORKER_MANJARO_IP}' port port='${OPENWEBUI_PORT}' protocol='tcp' accept"

    # SSH
    sudo firewall-cmd --permanent --add-service=ssh

    log "Recarregando firewalld..."
    sudo firewall-cmd --reload

    success "Firewalld configurado com sucesso!"
}

# Função para configurar iptables
configure_iptables() {
    section "Configurando iptables"

    log "Criando regras do Cluster AI..."

    # Limpar regras existentes
    sudo iptables -F
    sudo iptables -X

    # Políticas padrão
    sudo iptables -P INPUT DROP
    sudo iptables -P FORWARD DROP
    sudo iptables -P OUTPUT ACCEPT

    # Permitir loopback
    sudo iptables -A INPUT -i lo -j ACCEPT

    # Permitir conexões estabelecidas
    sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # SSH
    sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

    # Portas do scheduler primário
    sudo iptables -A INPUT -p tcp -s "${WORKER_MANJARO_IP}" --dport "${DASK_SCHEDULER_PORT}" -j ACCEPT
    sudo iptables -A INPUT -p tcp -s "${SECONDARY_IP}" --dport "${DASK_SCHEDULER_PORT}" -j ACCEPT

    # Porta do dashboard
    sudo iptables -A INPUT -p tcp -s "${WORKER_MANJARO_IP}" --dport "${DASK_DASHBOARD_PORT}" -j ACCEPT
    sudo iptables -A INPUT -p tcp -s "${SECONDARY_IP}" --dport "${DASK_DASHBOARD_PORT}" -j ACCEPT

    # Porta do scheduler secundário
    sudo iptables -A INPUT -p tcp -s "${WORKER_MANJARO_IP}" -d "${SECONDARY_IP}" --dport "${SECONDARY_PORT}" -j ACCEPT
    sudo iptables -A INPUT -p tcp -s "${NODE_IP}" -d "${SECONDARY_IP}" --dport "${SECONDARY_PORT}" -j ACCEPT

    # Porta do Ollama (apenas local)
    sudo iptables -A INPUT -p tcp -s 127.0.0.1 --dport "${OLLAMA_PORT}" -j ACCEPT

    # Porta do OpenWebUI
    sudo iptables -A INPUT -p tcp -s "${WORKER_MANJARO_IP}" --dport "${OPENWEBUI_PORT}" -j ACCEPT

    # Salvar regras
    if command -v netfilter-persistent >/dev/null 2>&1; then
        sudo netfilter-persistent save
    elif [ -f /etc/init.d/iptables ]; then
        sudo service iptables save
    fi

    success "iptables configurado com sucesso!"
}

# Função para mostrar status do firewall
show_firewall_status() {
    section "Status do Firewall"

    FIREWALL_TYPE=$(detect_firewall_manager)

    case "$FIREWALL_TYPE" in
        ufw)
            echo "Gerenciador: UFW"
            sudo ufw status verbose
            ;;
        firewalld)
            echo "Gerenciador: Firewalld"
            sudo firewall-cmd --list-all
            ;;
        iptables)
            echo "Gerenciador: iptables"
            sudo iptables -L -n -v
            ;;
        none)
            warn "Nenhum gerenciador de firewall detectado!"
            echo "Recomenda-se instalar ufw ou firewalld para melhor segurança."
            ;;
    esac
}

# Função para testar conectividade
test_connectivity() {
    section "Testando Conectividade do Firewall"

    log "Testando conexão com scheduler primário..."
    if timeout 5 bash -c "echo >/dev/tcp/${NODE_IP}/${DASK_SCHEDULER_PORT}" 2>/dev/null; then
        success "✅ Scheduler primário acessível"
    else
        warn "❌ Scheduler primário não acessível"
    fi

    log "Testando conexão com dashboard..."
    if timeout 5 bash -c "echo >/dev/tcp/${NODE_IP}/${DASK_DASHBOARD_PORT}" 2>/dev/null; then
        success "✅ Dashboard acessível"
    else
        warn "❌ Dashboard não acessível"
    fi

    log "Testando conexão com Ollama (local)..."
    if timeout 5 bash -c "echo >/dev/tcp/127.0.0.1/${OLLAMA_PORT}" 2>/dev/null; then
        success "✅ Ollama acessível localmente"
    else
        warn "❌ Ollama não acessível localmente"
    fi
}

# Função principal
main() {
    mkdir -p "${PROJECT_ROOT}/logs"

    case "${1:-status}" in
        configure|setup)
            FIREWALL_TYPE=$(detect_firewall_manager)

            case "$FIREWALL_TYPE" in
                ufw)
                    configure_ufw
                    ;;
                firewalld)
                    configure_firewalld
                    ;;
                iptables)
                    configure_iptables
                    ;;
                none)
                    error "Nenhum gerenciador de firewall encontrado!"
                    echo "Instale ufw (Ubuntu/Debian) ou firewalld (CentOS/RHEL) primeiro."
                    exit 1
                    ;;
            esac

            test_connectivity
            ;;
        status)
            show_firewall_status
            ;;
        test)
            test_connectivity
            ;;
        reset)
            section "Resetando Firewall"

            FIREWALL_TYPE=$(detect_firewall_manager)

            case "$FIREWALL_TYPE" in
                ufw)
                    sudo ufw --force reset
                    sudo ufw --force enable
                    ;;
                firewalld)
                    sudo firewall-cmd --complete-reload
                    ;;
                iptables)
                    sudo iptables -F
                    sudo iptables -X
                    sudo iptables -P INPUT ACCEPT
                    sudo iptables -P FORWARD ACCEPT
                    sudo iptables -P OUTPUT ACCEPT
                    ;;
            esac

            success "Firewall resetado!"
            ;;
        *)
            echo "Uso: $0 [configure|status|test|reset]"
            echo ""
            echo "Comandos:"
            echo "  configure - Configura regras do firewall para o Cluster AI"
            echo "  status    - Mostra status atual do firewall"
            echo "  test      - Testa conectividade das portas"
            echo "  reset     - Reseta firewall para configurações padrão"
            ;;
    esac
}

main "$@"
