#!/bin/bash
# Setup Firewall para Cluster AI
# Configura regras de firewall para proteger o sistema

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funções auxiliares
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# Detectar sistema de firewall disponível
detect_firewall() {
    if command -v ufw &> /dev/null; then
        echo "ufw"
    elif command -v firewall-cmd &> /dev/null; then
        echo "firewalld"
    elif command -v iptables &> /dev/null; then
        echo "iptables"
    else
        echo "none"
    fi
}

# Verificar status do firewall
check_firewall_status() {
    local firewall_type=$1

    case $firewall_type in
        ufw)
            if sudo ufw status | grep -q "Status: active"; then
                log "UFW está ativo"
                return 0
            else
                log "UFW está inativo"
                return 1
            fi
            ;;
        firewalld)
            if sudo firewall-cmd --state | grep -q "running"; then
                log "Firewalld está ativo"
                return 0
            else
                log "Firewalld está inativo"
                return 1
            fi
            ;;
        iptables)
            log "Usando iptables diretamente"
            return 0
            ;;
        *)
            warn "Nenhum sistema de firewall detectado"
            return 1
            ;;
    esac
}

# Configurar UFW
configure_ufw() {
    log "Configurando UFW..."

    # Habilitar UFW
    sudo ufw --force enable

    # Regras básicas
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    # SSH (essencial)
    sudo ufw allow ssh
    log "SSH permitido na porta 22"

    # HTTP e HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    log "HTTP (80) e HTTPS (443) permitidos"

    # Dask
    sudo ufw allow 8786/tcp  # Dask scheduler
    sudo ufw allow 8787/tcp  # Dask dashboard
    log "Dask scheduler (8786) e dashboard (8787) permitidos"

    # OpenWebUI
    sudo ufw allow 3000/tcp
    log "OpenWebUI (3000) permitido"

    # Ollama
    sudo ufw allow 11434/tcp
    log "Ollama (11434) permitido"

    # Jupyter (se usado)
    sudo ufw allow 8888/tcp
    log "Jupyter (8888) permitido"

    # Aplicar regras
    sudo ufw reload

    success "UFW configurado com sucesso"
}

# Configurar Firewalld
configure_firewalld() {
    log "Configurando Firewalld..."

    # Iniciar firewalld se não estiver ativo
    sudo systemctl start firewalld
    sudo systemctl enable firewalld

    # Remover regras existentes relacionadas
    sudo firewall-cmd --permanent --remove-service=ssh 2>/dev/null || true
    sudo firewall-cmd --permanent --remove-port=80/tcp 2>/dev/null || true
    sudo firewall-cmd --permanent --remove-port=443/tcp 2>/dev/null || true
    sudo firewall-cmd --permanent --remove-port=8786/tcp 2>/dev/null || true
    sudo firewall-cmd --permanent --remove-port=8787/tcp 2>/dev/null || true
    sudo firewall-cmd --permanent --remove-port=3000/tcp 2>/dev/null || true
    sudo firewall-cmd --permanent --remove-port=11434/tcp 2>/dev/null || true
    sudo firewall-cmd --permanent --remove-port=8888/tcp 2>/dev/null || true

    # Adicionar serviços
    sudo firewall-cmd --permanent --add-service=ssh
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --permanent --add-service=https

    # Portas específicas do Cluster AI
    sudo firewall-cmd --permanent --add-port=8786/tcp  # Dask scheduler
    sudo firewall-cmd --permanent --add-port=8787/tcp  # Dask dashboard
    sudo firewall-cmd --permanent --add-port=3000/tcp  # OpenWebUI
    sudo firewall-cmd --permanent --add-port=11434/tcp # Ollama
    sudo firewall-cmd --permanent --add-port=8888/tcp  # Jupyter

    # Aplicar regras
    sudo firewall-cmd --reload

    success "Firewalld configurado com sucesso"
}

# Configurar iptables (fallback)
configure_iptables() {
    log "Configurando iptables..."

    # Políticas padrão
    sudo iptables -P INPUT DROP
    sudo iptables -P FORWARD DROP
    sudo iptables -P OUTPUT ACCEPT

    # Permitir loopback
    sudo iptables -A INPUT -i lo -j ACCEPT
    sudo iptables -A OUTPUT -o lo -j ACCEPT

    # Permitir conexões estabelecidas
    sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

    # SSH
    sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

    # HTTP/HTTPS
    sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

    # Dask
    sudo iptables -A INPUT -p tcp --dport 8786 -j ACCEPT
    sudo iptables -A INPUT -p tcp --dport 8787 -j ACCEPT

    # OpenWebUI
    sudo iptables -A INPUT -p tcp --dport 3000 -j ACCEPT

    # Ollama
    sudo iptables -A INPUT -p tcp --dport 11434 -j ACCEPT

    # Jupyter
    sudo iptables -A INPUT -p tcp --dport 8888 -j ACCEPT

    # Salvar regras (tentar diferentes métodos)
    if command -v netfilter-persistent &> /dev/null; then
        sudo netfilter-persistent save
    elif command -v iptables-save &> /dev/null; then
        sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
    fi

    success "Iptables configurado com sucesso"
}

# Mostrar status do firewall
show_status() {
    local firewall_type=$1

    echo
    echo "📊 STATUS DO FIREWALL:"
    echo "======================"

    case $firewall_type in
        ufw)
            echo "🔥 UFW Status:"
            sudo ufw status verbose
            ;;
        firewalld)
            echo "🔥 Firewalld Status:"
            sudo firewall-cmd --list-all
            ;;
        iptables)
            echo "🔥 Iptables Rules:"
            sudo iptables -L -n
            ;;
        *)
            echo "❌ Nenhum firewall configurado"
            ;;
    esac
}

# Verificar portas abertas
verify_ports() {
    log "Verificando portas abertas..."

    local ports=(22 80 443 8786 8787 3000 11434 8888)
    local failed=0

    for port in "${ports[@]}"; do
        if sudo ss -tln | grep -q ":$port "; then
            success "Porta $port está aberta"
        else
            warn "Porta $port pode não estar aberta"
            ((failed++))
        fi
    done

    if [ $failed -gt 0 ]; then
        warn "$failed portas podem precisar de configuração adicional nos serviços"
    fi
}

# Função principal
main() {
    echo
    echo "🔥 CONFIGURAÇÃO FIREWALL - CLUSTER AI"
    echo "====================================="
    echo

    # Detectar firewall disponível
    FIREWALL_TYPE=$(detect_firewall)

    case $FIREWALL_TYPE in
        ufw)
            log "Firewall detectado: UFW (Ubuntu/Debian)"
            ;;
        firewalld)
            log "Firewall detectado: Firewalld (Fedora/RHEL)"
            ;;
        iptables)
            log "Firewall detectado: iptables (genérico)"
            ;;
        none)
            error "Nenhum sistema de firewall detectado"
            error "Instale ufw, firewalld ou iptables primeiro"
            exit 1
            ;;
    esac

    # Verificar status atual
    if check_firewall_status "$FIREWALL_TYPE"; then
        read -p "Firewall já está ativo. Deseja reconfigurar? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Configuração cancelada pelo usuário"
            show_status "$FIREWALL_TYPE"
            exit 0
        fi
    fi

    # Configurar firewall
    case $FIREWALL_TYPE in
        ufw)
            configure_ufw
            ;;
        firewalld)
            configure_firewalld
            ;;
        iptables)
            configure_iptables
            ;;
    esac

    # Verificar portas
    verify_ports

    # Mostrar status final
    show_status "$FIREWALL_TYPE"

    echo
    success "Configuração do firewall concluída!"
    echo
    echo "🔒 PORTAS CONFIGURADAS:"
    echo "• SSH: 22"
    echo "• HTTP: 80"
    echo "• HTTPS: 443"
    echo "• Dask Scheduler: 8786"
    echo "• Dask Dashboard: 8787"
    echo "• OpenWebUI: 3000"
    echo "• Ollama: 11434"
    echo "• Jupyter: 8888"
    echo
    echo "⚠️  IMPORTANTE:"
    echo "• Certifique-se de que os serviços estão configurados para essas portas"
    echo "• Monitore os logs: journalctl -f -u [serviço]"
    echo "• Teste as conexões remotas após configurar"
    echo
}

# Executar
main "$@"
