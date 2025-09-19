#!/bin/bash

# Script de Descoberta Automática de Workers para Cluster AI - Versão Corrigida
# Suporte para IPs dinâmicos através de múltiplas estratégias

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
CONFIG_DIR="$HOME/.cluster_config"
WORKERS_FILE="$CONFIG_DIR/discovered_workers.json"
NODES_FILE="$CONFIG_DIR/nodes_list.conf"
DISCOVERY_LOG="$CONFIG_DIR/discovery.log"

# Funções de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2 | tee -a "$DISCOVERY_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2 | tee -a "$DISCOVERY_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2 | tee -a "$DISCOVERY_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2 | tee -a "$DISCOVERY_LOG"
}

# Criar diretório de configuração
setup_config_dir() {
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
        log_info "Diretório de configuração criado: $CONFIG_DIR"
    fi

    if [[ ! -f "$DISCOVERY_LOG" ]]; then
        touch "$DISCOVERY_LOG"
    fi
}

# Escaneamento ARP - Versão corrigida
discover_by_arp() {
    local network="${1:-192.168.0.0/24}"

    local devices=()

    # Usar arp-scan para descoberta ARP
    log_info "Usando arp-scan para descoberta ARP"
    # Executar arp-scan e capturar apenas a saída padrão, ignorando logs
    local arp_output
    arp_output=$(arp-scan --localnet --quiet 2>/dev/null | grep -E "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" 2>/dev/null)

    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            ip=$(echo "$line" | awk '{print $1}')
            mac=$(echo "$line" | awk '{print $2}')
            hostname=$(echo "$line" | awk '{print $3}')

            if [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                # Resolver hostname se não estiver disponível
                if [[ -z "$hostname" || "$hostname" == "?" ]]; then
                    hostname=$(getent hosts "$ip" | awk '{print $2}' || echo "")
                fi
                devices+=("$ip|$mac|$hostname|arp_scan")
            fi
        fi
    done <<< "$arp_output"

    # Fallback: usar ping e arp
    if [[ ${#devices[@]} -eq 0 ]]; then
        log_info "Usando método alternativo (ping + arp)"
        local network_prefix="192.168.0"
        for i in {1..254}; do
            local ip="$network_prefix.$i"
            if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
                # Verificar se está na tabela ARP
                if command -v arp >/dev/null 2>&1; then
                    if arp_output=$(arp -n "$ip" 2>/dev/null); then
                        if [[ $arp_output != *"no entry"* && $arp_output != *"incomplete"* ]]; then
                            mac=$(echo "$arp_output" | awk '{print $3}')
                            hostname=$(getent hosts "$ip" | awk '{print $2}' || echo "")
                            if [[ -n "$mac" && "$mac" != *"incomplete"* ]]; then
                                devices+=("$ip|$mac|$hostname|ping_arp")
                            fi
                        fi
                    fi
                fi
            fi
        done
    fi

    printf '%s\n' "${devices[@]}"
}

# Descoberta por mDNS/Bonjour
discover_by_mdns() {
    log_info "Procurando dispositivos com mDNS/Bonjour"

    local devices=()

    if command -v avahi-browse >/dev/null 2>&1; then
        log_info "Usando avahi-browse para descoberta mDNS"
        while IFS= read -r line; do
            if [[ $line == *";IPv4;"* ]]; then
                hostname=$(echo "$line" | cut -d';' -f7)
                ip=$(echo "$line" | cut -d';' -f8)

                if [[ -n "$hostname" && -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    devices+=("$ip||$hostname|mdns")
                fi
            fi
        done < <(avahi-browse -a -t 2>/dev/null | grep "IPv4")
    else
        log_warning "avahi-browse não encontrado. Instale com: sudo apt install avahi-utils"
    fi

    printf '%s\n' "${devices[@]}"
}

# Escaneamento de portas SSH
discover_ssh_hosts() {
    local port="${1:-22}"
    log_info "Escaneando portas SSH (porta $port)"

    local devices=()

    if command -v nmap >/dev/null 2>&1; then
        log_info "Usando nmap para descoberta SSH"
        while IFS= read -r line; do
            if [[ $line == *"Nmap scan report for"* ]]; then
                ip=$(echo "$line" | sed 's/.*for //' | tr -d '()')
                if [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                devices+=("$ip|||ssh_scan")
                fi
            fi
        done < <(nmap -p "$port" --open 192.168.0.0/24 2>/dev/null | grep "Nmap scan report")
    else
        log_warning "nmap não encontrado. Instale com: sudo apt install nmap"
    fi

    printf '%s\n' "${devices[@]}"
}

# Registrar worker - Versão corrigida
register_worker() {
    local ip="$1"
    local mac="$2"
    local hostname="$3"
    local discovery_method="$4"

    # Validar dados de entrada
    if [[ -z "$ip" || "$ip" =~ ^\[.*\]\[INFO\] || "$ip" =~ ^\[.*\]\[WARNING\] ]]; then
        log_warning "IP inválido ou contém dados de log: $ip"
        return 1
    fi

    # Validar formato de IP
    if ! [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_warning "Formato de IP inválido: $ip"
        return 1
    fi

    # Carregar workers existentes
    local workers="{}"
    if [[ -f "$WORKERS_FILE" ]]; then
        workers=$(cat "$WORKERS_FILE")
    fi

    # Gerar ID único
    local worker_id
    if [[ -n "$hostname" && "$hostname" != "?" && "$hostname" != " " ]]; then
        worker_id="$hostname"
    elif [[ -n "$mac" && "$mac" != "incomplete" ]]; then
        worker_id="worker_${mac//:/}"
    else
        worker_id="worker_$(date +%s)"
    fi

    # Verificar se já existe
    if echo "$workers" | jq -e ".\"$worker_id\"" >/dev/null 2>&1; then
        log_info "Worker $worker_id já registrado, atualizando..."
    else
        log_success "Novo worker descoberto: $worker_id ($ip)"
    fi

    # Limpar hostname se for inválido
    if [[ -z "$hostname" || "$hostname" == "?" || "$hostname" == " " ]]; then
        hostname=""
    fi

    # Limpar MAC se for inválido
    if [[ -z "$mac" || "$mac" == "incomplete" ]]; then
        mac=""
    fi

    # Atualizar informações do worker
    local worker_info
    worker_info=$(jq -n \
        --arg ip "$ip" \
        --arg mac "$mac" \
        --arg hostname "$hostname" \
        --arg method "$discovery_method" \
        --arg timestamp "$(date +%s)" \
        '{
            name: $hostname,
            ip: $ip,
            mac: $mac,
            hostname: $hostname,
            discovery_method: $method,
            last_seen: $timestamp,
            status: "active"
        }')

    # Atualizar JSON
    workers=$(echo "$workers" | jq ".\"$worker_id\" = $worker_info")

    echo "$workers" > "$WORKERS_FILE"
}

# Atualizar configuração
update_configuration() {
    log_info "Atualizando arquivo de configuração dos workers"

    if [[ ! -f "$WORKERS_FILE" ]]; then
        log_warning "Arquivo de workers não encontrado"
        return 1
    fi

    local config_lines=()
    config_lines+=("# =================================================================================")
    config_lines+=("# Configuração de Workers - Gerado Automaticamente")
    config_lines+=("# Atualizado em: $(date)")
    config_lines+=("# =================================================================================")
    config_lines+=("")

    # Ler workers do JSON
    local workers
    workers=$(cat "$WORKERS_FILE")

    local count=0
    for worker_id in $(echo "$workers" | jq -r 'keys[]'); do
        local worker_info
        worker_info=$(echo "$workers" | jq ".\"$worker_id\"")

        local hostname ip user port status
        hostname=$(echo "$worker_info" | jq -r '.hostname // .name // "'$worker_id'"')
        ip=$(echo "$worker_info" | jq -r '.ip // ""')
        user=$(echo "$worker_info" | jq -r '.user // "user"')
        port=$(echo "$worker_info" | jq -r '.port // 22')
        status=$(echo "$worker_info" | jq -r '.status // "active"')

        if [[ "$status" == "active" && -n "$ip" ]]; then
            config_lines+=("$hostname $worker_id $ip $user $port $status")
            ((count++))
        fi
    done

    printf '%s\n' "${config_lines[@]}" > "$NODES_FILE"
    log_success "Configuração atualizada com $count workers"
}

# Descoberta completa
discover_all() {
    log_info "🔍 Iniciando descoberta automática de workers..."

    # Descoberta ARP
    log_info "📡 Executando descoberta ARP..."
    while IFS='|' read -r ip mac hostname method; do
        if [[ -n "$ip" ]]; then
            register_worker "$ip" "$mac" "$hostname" "$method"
        fi
    done < <(discover_by_arp)

    # Descoberta mDNS
    log_info "🌐 Executando descoberta mDNS..."
    while IFS='|' read -r ip mac hostname method; do
        if [[ -n "$ip" ]]; then
            register_worker "$ip" "$mac" "$hostname" "$method"
        fi
    done < <(discover_by_mdns)

    # Descoberta SSH
    log_info "🔐 Executando descoberta SSH..."
    while IFS='|' read -r ip mac hostname method; do
        if [[ -n "$ip" ]]; then
            register_worker "$ip" "$mac" "$hostname" "$method"
        fi
    done < <(discover_ssh_hosts)

    # Atualizar configuração
    update_configuration
}

# Listar workers descobertos
list_workers() {
    if [[ ! -f "$WORKERS_FILE" ]]; then
        log_warning "Nenhum worker descoberto ainda"
        return
    fi

    echo
    echo "🤖 WORKERS DESCOBERTOS:"
    echo "=" * 50

    local workers
    workers=$(cat "$WORKERS_FILE")

    local count=0
    for worker_id in $(echo "$workers" | jq -r 'keys[]'); do
        local worker_info
        worker_info=$(echo "$workers" | jq ".\"$worker_id\"")

        local name ip method last_seen
        name=$(echo "$worker_info" | jq -r '.name // .hostname // "'$worker_id'"')
        ip=$(echo "$worker_info" | jq -r '.ip // "N/A"')
        method=$(echo "$worker_info" | jq -r '.discovery_method // "unknown"')
        last_seen=$(echo "$worker_info" | jq -r '.last_seen // 0')
        last_seen_formatted=$(date -d "@$last_seen" 2>/dev/null || echo "N/A")

        echo "  • $name ($ip)"
        echo "    Método: $method | Última vez visto: $last_seen_formatted"
        echo
        ((count++))
    done

    echo "Total: $count workers descobertos"
}

# Função principal
main() {
    echo
    echo "🔍 CLUSTER AI - Sistema de Descoberta Automática (Corrigido)"
    echo "=" * 60
    echo

    setup_config_dir

    case "${1:-help}" in
        "discover")
            discover_all
            ;;
        "list")
            list_workers
            ;;
        "help"|*)
            echo "Uso: $0 <comando>"
            echo
            echo "Comandos disponíveis:"
            echo "  discover          - Executar descoberta completa"
            echo "  list              - Listar workers descobertos"
            echo "  help              - Mostrar esta ajuda"
            echo
            echo "Exemplos:"
            echo "  $0 discover"
            echo "  $0 list"
            ;;
    esac
}

# Executar função principal
main "$@"
