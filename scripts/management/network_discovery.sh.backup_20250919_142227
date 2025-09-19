#!/bin/bash
# Script para descoberta automática de nós na rede
# Melhorado com verificações automáticas e integração com o cluster

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# Funções auxiliares locais (fallback)
if ! command -v info >/dev/null 2>&1; then
    info() {
        echo "[INFO] $1"
    }
fi

if ! command -v warn >/dev/null 2>&1; then
    warn() {
        echo "[WARN] $1"
    }
fi

if ! command -v error >/dev/null 2>&1; then
    error() {
        echo "[ERROR] $1"
    }
fi

if ! command -v success >/dev/null 2>&1; then
    success() {
        echo "[SUCCESS] $1"
    }
fi

if ! command -v file_exists >/dev/null 2>&1; then
    file_exists() {
        [ -f "$1" ]
    }
fi

if ! command -v progress >/dev/null 2>&1; then
    progress() {
        echo "[...] $1"
    }
fi

# --- Constantes ---
NODES_LIST_FILE="$HOME/.cluster_config/nodes_list.conf"
DISCOVERY_LOG="${PROJECT_ROOT}/logs/network_discovery.log"
CLUSTER_PORTS=(22 8786 8787 11434 3000)  # SSH, Dask, Ollama, OpenWebUI

# --- Funções ---

# Detecta automaticamente a faixa de IP da rede local
detect_network_range() {
    local interface
    interface=$(ip route | grep default | awk '{print $5}' | head -1)

    if [ -z "$interface" ]; then
        interface="eth0"
    fi

    local ip_address
    ip_address=$(ip addr show "$interface" | grep "inet " | awk '{print $2}' | cut -d'/' -f1 | head -1)

    if [ -z "$ip_address" ]; then
        error "Não foi possível detectar o endereço IP da interface $interface"
        return 1
    fi

    # Calcular faixa de rede /24
    local network_prefix
    network_prefix=$(echo "$ip_address" | cut -d'.' -f1-3)
    echo "${network_prefix}.0/24"
}

# Escaneia portas específicas nos hosts descobertos
scan_cluster_ports() {
    local ip="$1"
    local hostname="${2:-$ip}"

    log "Verificando portas do cluster em $hostname ($ip)..."

    local cluster_services=()

    for port in "${CLUSTER_PORTS[@]}"; do
        if timeout 3 bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null; then
            case $port in
                22) cluster_services+=("SSH") ;;
                8786) cluster_services+=("Dask-Scheduler") ;;
                8787) cluster_services+=("Dask-Dashboard") ;;
                11434) cluster_services+=("Ollama") ;;
                3000) cluster_services+=("OpenWebUI") ;;
            esac
        fi
    done

    if [ ${#cluster_services[@]} -gt 0 ]; then
        success "  ✅ Serviços encontrados: ${cluster_services[*]}"
        return 0
    else
        info "  ⚪ Nenhum serviço do cluster encontrado"
        return 1
    fi
}

# Verifica conectividade SSH
check_ssh_connectivity() {
    local ip="$1"
    local user="${2:-$USER}"

    log "Testando conectividade SSH: $user@$ip"

    # Tentar conexão SSH sem senha (chave SSH)
    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$user@$ip" "echo 'SSH OK'" 2>/dev/null; then
        success "  ✅ SSH acessível com chave"
        return 0
    fi

    # Se falhou, informar sobre configuração necessária
    warn "  ⚠️  SSH requer configuração (chave SSH ou senha)"
    return 1
}

# Adiciona nó à lista de configuração
add_node_to_config() {
    local hostname="$1"
    local ip="$2"
    local ssh_user="$3"
    local services="$4"

    # Verificar se já existe
    if grep -q -E "($hostname|$ip)" "$NODES_LIST_FILE" 2>/dev/null; then
        info "  📝 Nó já existe na configuração"
        return 0
    fi

    # Adicionar à configuração
    mkdir -p "$(dirname "$NODES_LIST_FILE")"
    echo "# Adicionado automaticamente em $(date)" >> "$NODES_LIST_FILE"
    echo "$hostname $ip $ssh_user # Serviços: $services" >> "$NODES_LIST_FILE"

    success "  ➕ Nó adicionado: $hostname ($ip)"
    log "Nó registrado com serviços: $services"
}

# Registrar worker automaticamente se for um worker do cluster
register_worker_automatically() {
    local hostname="$1"
    local ip="$2"
    local ssh_user="${3:-$USER}"

    # Verificar se é um worker do cluster tentando registro automático
    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$ssh_user@$ip" "
        test -f ~/Projetos/cluster-ai/scripts/management/worker_registration.sh ||
        test -f /opt/cluster-ai/scripts/management/worker_registration.sh
    " 2>/dev/null; then

        info "  🔄 Worker do cluster detectado, tentando registro automático..."

        # Tentar executar registro automático no worker
        if ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$ssh_user@$ip" "
            if [ -f ~/Projetos/cluster-ai/scripts/installation/setup_generic_worker.sh ]; then
                bash ~/Projetos/cluster-ai/scripts/installation/setup_generic_worker.sh --register-only
            elif [ -f /opt/cluster-ai/scripts/installation/setup_generic_worker.sh ]; then
                bash /opt/cluster-ai/scripts/installation/setup_generic_worker.sh --register-only
            fi
        " 2>/dev/null; then
            success "  ✅ Worker registrado automaticamente"
            return 0
        else
            warn "  ⚠️  Falha no registro automático do worker"
            return 1
        fi
    fi

    return 1
}

# Descoberta automática de nós
auto_discover_nodes() {
    section "🔍 Descoberta Automática de Nós"

    if ! command_exists nmap; then
        error "nmap não encontrado. Instale com: sudo apt install nmap"
        return 1
    fi

    # Detectar faixa de rede automaticamente
    local network_range
    if ! network_range=$(detect_network_range); then
        error "Não foi possível detectar a faixa de rede"
        return 1
    fi

    info "Faixa de rede detectada: $network_range"

    # Escanear hosts ativos
    progress "Escaneando rede em busca de hosts ativos..."
    local discovered_hosts
    discovered_hosts=$(sudo nmap -sn "$network_range" 2>/dev/null | awk '/Up$/{print $2}' | grep -v "$network_range")

    if [ -z "$discovered_hosts" ]; then
        warn "Nenhum host ativo encontrado na rede"
        return 0
    fi

    info "Hosts ativos encontrados: $(echo "$discovered_hosts" | wc -l)"

    local nodes_added=0
    local nodes_with_services=0

    for ip in $discovered_hosts; do
        # Resolver hostname
        local hostname
        hostname=$(nslookup "$ip" 2>/dev/null | awk -F'=' '/name =/{print $2}' | sed 's/\.$//; s/ //g' || echo "$ip")

        subsection "Analisando: $hostname ($ip)"

        # Verificar portas do cluster
        local services_found=""
        if scan_cluster_ports "$ip" "$hostname"; then
            services_found="Cluster-Services"
            nodes_with_services=$((nodes_with_services + 1))
        fi

        # Verificar SSH
        local ssh_accessible=false
        if check_ssh_connectivity "$ip"; then
            ssh_accessible=true
        fi

        # Decidir se adiciona o nó
        if [ -n "$services_found" ] || $ssh_accessible; then
            local ssh_user
            if $ssh_accessible; then
                ssh_user="$USER"
            else
                ssh_user="configurar-ssh"
            fi

            # Tentar registro automático se for um worker do cluster
            if $ssh_accessible && register_worker_automatically "$hostname" "$ip" "$ssh_user"; then
                info "  📝 Worker registrado automaticamente na configuração de workers"
            fi

            add_node_to_config "$hostname" "$ip" "$ssh_user" "$services_found"
            nodes_added=$((nodes_added + 1))
        else
            info "  ⏭️  Pulando nó (sem serviços relevantes)"
        fi

        echo
    done

    # Resumo
    section "📊 Resumo da Descoberta"
    success "Hosts ativos encontrados: $(echo "$discovered_hosts" | wc -l)"
    success "Nós com serviços do cluster: $nodes_with_services"
    success "Nós adicionados à configuração: $nodes_added"

    if [ -f "$NODES_LIST_FILE" ]; then
        echo
        info "Lista atual de nós:"
        cat "$NODES_LIST_FILE" | grep -v '^#' | grep -v '^$'
    fi
}

# Monitoramento contínuo de nós
monitor_nodes() {
    section "📡 Monitoramento Contínuo de Nós"

    if ! file_exists "$NODES_LIST_FILE"; then
        warn "Nenhum nó configurado para monitoramento"
        return 0
    fi

    info "Monitorando nós configurados..."

    while IFS= read -r line; do
        # Pular comentários e linhas vazias
        [[ $line =~ ^# ]] && continue
        [[ -z $line ]] && continue

        local hostname ip ssh_user
        hostname=$(echo "$line" | awk '{print $1}')
        ip=$(echo "$line" | awk '{print $2}')
        ssh_user=$(echo "$line" | awk '{print $3}')

        subsection "Verificando: $hostname ($ip)"

        # Verificar se host está online
        if ping -c 1 -W 2 "$ip" >/dev/null 2>&1; then
            success "  🟢 Online"

            # Verificar serviços
            if scan_cluster_ports "$ip" "$hostname" >/dev/null; then
                success "  ✅ Serviços ativos"
            else
                warn "  ⚠️  Serviços inativos"
            fi
        else
            error "  🔴 Offline"
        fi

    done < "$NODES_LIST_FILE"

    echo
    info "Monitoramento concluído em $(date)"
}

# Menu principal
show_menu() {
    subsection "Menu de Descoberta de Rede"

    echo "Escolha uma operação:"
    echo
    echo "🔍 DESCOBERTA:"
    echo "1) 🔍 Descoberta automática de nós"
    echo "2) 📡 Monitorar nós existentes"
    echo "3) 📋 Listar nós configurados"
    echo
    echo "⚙️  CONFIGURAÇÃO:"
    echo "4) ➕ Adicionar nó manualmente"
    echo "5) 🗑️  Remover nó"
    echo "6) 🔧 Configurar SSH para nós"
    echo
    echo "0) ❌ Voltar"
    echo
}

# Lista nós configurados
list_nodes() {
    section "📋 Nós Configurados"

    if ! file_exists "$NODES_LIST_FILE"; then
        warn "Nenhum nó configurado"
        return 0
    fi

    echo "Nós registrados no cluster:"
    echo

    local count=0
    while IFS= read -r line; do
        [[ $line =~ ^# ]] && continue
        [[ -z $line ]] && continue

        count=$((count + 1))
        local hostname ip ssh_user comment
        hostname=$(echo "$line" | awk '{print $1}')
        ip=$(echo "$line" | awk '{print $2}')
        ssh_user=$(echo "$line" | awk '{print $3}')
        comment=$(echo "$line" | cut -d'#' -f2- | sed 's/^ *//')

        echo "$count) $hostname ($ip) - SSH: $ssh_user"
        if [ -n "$comment" ]; then
            echo "   📝 $comment"
        fi
        echo
    done < "$NODES_LIST_FILE"

    if [ $count -eq 0 ]; then
        warn "Nenhum nó ativo encontrado na configuração"
    fi
}

# Adiciona nó manualmente
add_node_manually() {
    section "➕ Adicionar Nó Manualmente"

    read -p "Digite o hostname ou IP: " node_address
    if [ -z "$node_address" ]; then
        error "Endereço não pode ser vazio"
        return 1
    fi

    read -p "Digite o usuário SSH (padrão: $USER): " ssh_user
    ssh_user=${ssh_user:-$USER}

    # Verificar conectividade
    if ! ping -c 1 -W 2 "$node_address" >/dev/null 2>&1; then
        error "Host $node_address não está acessível"
        return 1
    fi

    # Verificar portas
    local services=""
    if scan_cluster_ports "$node_address" "$node_address"; then
        services="Cluster-Services"
    fi

    add_node_to_config "$node_address" "$node_address" "$ssh_user" "$services"
    success "Nó adicionado com sucesso"
}

# Função principal
main() {
    # Criar diretório de logs
    mkdir -p "${PROJECT_ROOT}/logs"

    # Processar argumentos da linha de comando
    case "${1:-}" in
        auto)
            auto_discover_nodes
            exit 0
            ;;
        monitor)
            monitor_nodes
            exit 0
            ;;
        list)
            list_nodes
            exit 0
            ;;
    esac

    # Menu interativo
    while true; do
        section "🌐 Gerenciamento de Rede - Cluster AI"
        show_menu

        local choice
        read -p "Digite sua opção (0-6): " choice

        case $choice in
            1) auto_discover_nodes ;;
            2) monitor_nodes ;;
            3) list_nodes ;;
            4) add_node_manually ;;
            5) warn "Remover nó - Em desenvolvimento" ;;
            6) warn "Configurar SSH - Em desenvolvimento" ;;
            0)
                info "Voltando ao menu principal"
                exit 0
                ;;
            *)
                error "Opção inválida. Tente novamente."
                sleep 2
                ;;
        esac

        echo
        read -p "Pressione Enter para continuar..."
        clear
    done
}

# Executar função principal
main "$@"
