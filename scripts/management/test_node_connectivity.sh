#!/bin/bash
# Script para testar conectividade com nó específico

set -euo pipefail

# --- Configuração ---
TARGET_IP="${1:-192.168.0.18}"
TARGET_HOSTNAME="${2:-pc-dago}"
TIMEOUT=30

# --- Funções ---
section() {
    echo
    echo "=============================="
    echo " $1"
    echo "=============================="
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

test_ping() {
    local ip="$1"
    info "Testando ping para $ip..."
    if ping -c 3 -W 2 "$ip" >/dev/null 2>&1; then
        success "Host $ip está respondendo ao ping"
        return 0
    else
        warn "Host $ip não está respondendo ao ping"
        return 1
    fi
}

test_ssh() {
    local ip="$1"
    local hostname="$2"
    info "Testando conexão SSH para $hostname ($ip)..."
    if timeout 5 ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "$hostname" "echo 'SSH OK'" 2>/dev/null; then
        success "SSH funcionando para $hostname"
        return 0
    else
        warn "SSH não está acessível para $hostname"
        return 1
    fi
}

test_cluster_ports() {
    local ip="$1"
    local ports=(22 8786 8787 11434 3000)
    local port_names=("SSH" "Dask Scheduler" "Dask Dashboard" "Ollama" "OpenWebUI")

    info "Testando portas do cluster em $ip..."

    for i in "${!ports[@]}"; do
        local port="${ports[$i]}"
        local name="${port_names[$i]}"

        if timeout 3 bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null; then
            success "Porta $port ($name) está aberta"
        else
            warn "Porta $port ($name) está fechada"
        fi
    done
}

check_services() {
    local hostname="$1"
    info "Verificando serviços no nó $hostname..."

    # Testar se o nó tem o projeto Cluster AI
    if ssh -o ConnectTimeout=3 "$hostname" "test -d ~/Projetos/cluster-ai" 2>/dev/null; then
        success "Projeto Cluster AI encontrado no nó"
    else
        warn "Projeto Cluster AI não encontrado no nó"
        info "Execute no nó Manjaro:"
        info "  git clone <repo> ~/Projetos/cluster-ai"
        info "  cd ~/Projetos/cluster-ai && ./install.sh"
    fi
}

generate_setup_instructions() {
    local ip="$1"
    local hostname="$2"

    section "📋 Instruções para Configurar Nó Worker"

    echo "Execute estes comandos no computador Manjaro ($hostname - $ip):"
    echo
    echo "1️⃣  Instalar dependências:"
    echo "   sudo pacman -Syu"
    echo "   sudo pacman -S docker python python-pip git nmap curl"
    echo
    echo "2️⃣  Clonar projeto:"
    echo "   git clone <URL_DO_REPO> ~/Projetos/cluster-ai"
    echo "   cd ~/Projetos/cluster-ai"
    echo
    echo "3️⃣  Instalar Cluster AI:"
    echo "   ./install.sh"
    echo
    echo "4️⃣  Configurar SSH (se necessário):"
    echo "   ssh-keygen -t rsa -b 4096"
    echo "   ssh-copy-id $hostname"
    echo
    echo "5️⃣  Iniciar como worker:"
    echo "   ./start_cluster.sh --worker --scheduler-ip $(hostname -I | awk '{print $1}')"
    echo
    echo "6️⃣  Verificar status:"
    echo "   ./manager.sh status"
}

main() {
    section "🔍 Teste de Conectividade do Nó"

    info "Testando conectividade com: $TARGET_HOSTNAME ($TARGET_IP)"
    echo

    # Teste básico de conectividade
    if ! test_ping "$TARGET_IP"; then
        error "Nó não está acessível na rede"
        echo
        generate_setup_instructions "$TARGET_IP" "$TARGET_HOSTNAME"
        exit 1
    fi

    # Testar SSH
    test_ssh "$TARGET_IP" "$TARGET_HOSTNAME"

    # Testar portas do cluster
    test_cluster_ports "$TARGET_IP"

    # Verificar serviços
    check_services "$TARGET_HOSTNAME"

    section "📊 Resultado do Teste"

    if test_ping "$TARGET_IP" && test_ssh "$TARGET_IP" "$TARGET_HOSTNAME"; then
        success "Nó $TARGET_HOSTNAME está pronto para ser configurado como worker!"
        echo
        info "Para configurar como worker, execute no nó Manjaro:"
        info "  cd ~/Projetos/cluster-ai"
        info "  ./start_cluster.sh --worker --scheduler-ip $(hostname -I | awk '{print $1}')"
    else
        warn "Nó precisa de configuração adicional"
        echo
        generate_setup_instructions "$TARGET_IP" "$TARGET_HOSTNAME"
    fi
}

# Verificar argumentos
if [ $# -eq 0 ]; then
    info "Uso: $0 [IP] [HOSTNAME]"
    info "Exemplo: $0 192.168.0.18 pc-dago"
    echo
fi

main "$@"
