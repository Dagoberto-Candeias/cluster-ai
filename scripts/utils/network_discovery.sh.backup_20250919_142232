#!/bin/bash
# =============================================================================
# Network Discovery Script for Cluster AI Workers
# =============================================================================

source "$(dirname "$0")/../lib/common.sh"

# Configuration
DISCOVERY_TIMEOUT=30
DISCOVERY_PORTS="22,8022,2222"  # Common SSH ports
NETWORK_RANGE="192.168.0.0/24,192.168.1.0/24,10.0.0.0/24"  # Common local network ranges

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a tool is available
check_tool() {
    local tool=$1
    if command_exists "$tool"; then
        return 0
    else
        return 1
    fi
}

# Function to resolve hostname to IP
resolve_hostname() {
    local hostname=$1
    local resolved_ip

    # Try to resolve hostname
    resolved_ip=$(getent hosts "$hostname" | awk '{print $1}' | head -1)

    if [ -n "$resolved_ip" ]; then
        echo "$resolved_ip"
        return 0
    else
        # Try nslookup as fallback
        if check_tool nslookup; then
            resolved_ip=$(nslookup "$hostname" 2>/dev/null | grep "Address:" | tail -1 | awk '{print $2}')
            if [ -n "$resolved_ip" ]; then
                echo "$resolved_ip"
                return 0
            fi
        fi
        return 1
    fi
}

# Function to get hostname from IP
get_hostname_from_ip() {
    local ip=$1
    local hostname

    # Try to get hostname from IP
    hostname=$(getent hosts "$ip" | awk '{print $2}' | head -1)

    if [ -n "$hostname" ]; then
        echo "$hostname"
        return 0
    else
        # Try nslookup as fallback
        if check_tool nslookup; then
            hostname=$(nslookup "$ip" 2>/dev/null | grep "name =" | awk '{print $4}' | sed 's/\.$//')
            if [ -n "$hostname" ]; then
                echo "$hostname"
                return 0
            fi
        fi
        return 1
    fi
}

# Function to scan network for SSH services
scan_network_ssh() {
    local network_range=$1
    local discovered_hosts=()

    echo -e "${BLUE}🔍 Scanning network: $network_range${NC}"

    if check_tool nmap; then
        # Use nmap for network scanning
        echo "Using nmap for network discovery..."
        nmap -sn --host-timeout 2s "$network_range" | grep "Nmap scan report" | awk '{print $5}' | while read -r ip; do
            # Check if SSH is running on common ports
            for port in 22 8022 2222; do
                if timeout 3 bash -c "</dev/tcp/$ip/$port" 2>/dev/null; then
                    hostname=$(get_hostname_from_ip "$ip")
                    if [ -n "$hostname" ]; then
                        echo -e "${GREEN}✅ Found SSH service: $hostname ($ip:$port)${NC}"
                        discovered_hosts+=("$hostname:$ip:$port")
                    else
                        echo -e "${YELLOW}⚠️  Found SSH service: $ip:$port (no hostname)${NC}"
                        discovered_hosts+=("unknown-$ip:$ip:$port")
                    fi
                    break
                fi
            done
        done
    elif check_tool arp; then
        # Fallback to ARP table
        echo "Using ARP table for basic discovery..."
        arp -a | grep -v incomplete | while read -r line; do
            ip=$(echo "$line" | awk '{print $2}' | tr -d '()')
            hostname=$(echo "$line" | awk '{print $1}')

            # Check SSH on common ports
            for port in 22 8022 2222; do
                if timeout 3 bash -c "</dev/tcp/$ip/$port" 2>/dev/null; then
                    echo -e "${GREEN}✅ Found SSH service: $hostname ($ip:$port)${NC}"
                    discovered_hosts+=("$hostname:$ip:$port")
                    break
                fi
            done
        done
    else
        echo -e "${RED}❌ Neither nmap nor arp available for network scanning${NC}"
        return 1
    fi

    # Return discovered hosts
    printf '%s\n' "${discovered_hosts[@]}"
}

# Function to discover workers using mDNS/avahi
discover_mdns_workers() {
    local discovered_hosts=()

    if check_tool avahi-browse; then
        echo -e "${BLUE}🔍 Scanning for mDNS services...${NC}"

        # Look for SSH services via mDNS
        timeout 10 avahi-browse -t -r _ssh._tcp 2>/dev/null | grep "=;" | while read -r line; do
            hostname=$(echo "$line" | awk -F';' '{print $7}')
            ip=$(echo "$line" | awk -F';' '{print $8}')
            port=$(echo "$line" | awk -F';' '{print $9}')

            if [ -n "$hostname" ] && [ -n "$ip" ]; then
                echo -e "${GREEN}✅ Found mDNS SSH service: $hostname ($ip:$port)${NC}"
                discovered_hosts+=("$hostname:$ip:$port")
            fi
        done
    else
        echo -e "${YELLOW}⚠️  avahi-browse not available, skipping mDNS discovery${NC}"
    fi

    # Return discovered hosts
    printf '%s\n' "${discovered_hosts[@]}"
}

# Function to test SSH connection to a host
test_ssh_connection() {
    local host=$1
    local user=${2:-$USER}
    local port=${3:-22}
    local key_file=${4:-}

    echo -e "${BLUE}🔗 Testing SSH connection to $user@$host:$port${NC}"

    local ssh_opts="-o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no"

    if [ -n "$key_file" ] && [ -f "$key_file" ]; then
        ssh_opts="$ssh_opts -i $key_file"
    fi

    if ssh $ssh_opts -p "$port" "$user@$host" "echo 'SSH connection successful'" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ SSH connection successful${NC}"
        return 0
    else
        echo -e "${RED}❌ SSH connection failed${NC}"
        return 1
    fi
}

# Function to add discovered worker to configuration
add_discovered_worker() {
    local hostname=$1
    local ip=$2
    local port=$3
    local user=${4:-$USER}
    local config_file=${5:-$HOME/.cluster_config/nodes_list.conf}

    # Create config directory if it doesn't exist
    mkdir -p "$(dirname "$config_file")"

    # Create config file if it doesn't exist
    if [ ! -f "$config_file" ]; then
        cat > "$config_file" << EOF
# =============================================================================
# Configuração de Workers Remotos para Cluster AI
# Formato: hostname alias IP user port status
# Exemplo: android-worker android 192.168.1.100 u0_a249 8022 active

# Adicione seus workers remotos aqui:
EOF
    fi

    # Generate alias from hostname
    local alias=$(echo "$hostname" | sed 's/[^a-zA-Z0-9]/-/g' | tr '[:upper:]' '[:lower:]')

    # Check if worker already exists
    if grep -q "^$hostname " "$config_file"; then
        echo -e "${YELLOW}⚠️  Worker $hostname already exists in configuration${NC}"
        return 1
    fi

    # Add worker to configuration
    echo "$hostname $alias $ip $user $port inactive" >> "$config_file"
    echo -e "${GREEN}✅ Worker $hostname ($alias) added to configuration${NC}"

    return 0
}

# Main discovery function
discover_workers() {
    local scan_network=${1:-true}
    local use_mdns=${2:-true}
    local all_discovered=()

    echo -e "${BLUE}🚀 Starting worker discovery...${NC}"
    echo

    # Discover via mDNS if enabled
    if [ "$use_mdns" = true ]; then
        echo -e "${BLUE}=== mDNS Discovery ===${NC}"
        mapfile -t mdns_hosts < <(discover_mdns_workers)
        all_discovered+=("${mdns_hosts[@]}")
        echo
    fi

    # Network scan if enabled
    if [ "$scan_network" = true ]; then
        echo -e "${BLUE}=== Network Scan Discovery ===${NC}"

        # Split network ranges and scan each
        IFS=',' read -ra NETWORKS <<< "$NETWORK_RANGE"
        for network in "${NETWORKS[@]}"; do
            mapfile -t network_hosts < <(scan_network_ssh "$network")
            all_discovered+=("${network_hosts[@]}")
        done
        echo
    fi

    # Remove duplicates and display summary
    if [ ${#all_discovered[@]} -gt 0 ]; then
        echo -e "${BLUE}=== Discovery Summary ===${NC}"
        printf '%s\n' "${all_discovered[@]}" | sort | uniq | while IFS=':' read -r hostname ip port; do
            if [ -n "$hostname" ] && [ "$hostname" != "unknown-$ip" ]; then
                echo -e "${GREEN}📱 $hostname ($ip:$port)${NC}"
            fi
        done
        echo

        # Ask user if they want to add discovered workers
        echo -e "${YELLOW}Deseja adicionar algum dos workers descobertos à configuração?${NC}"
        echo -e "${YELLOW}Digite o hostname ou 'todos' para adicionar todos, ou 'nenhum' para pular:${NC}"

        local discovered_list=()
        mapfile -t discovered_list < <(printf '%s\n' "${all_discovered[@]}" | sort | uniq)

        for host_info in "${discovered_list[@]}"; do
            IFS=':' read -r hostname ip port <<< "$host_info"
            if [ -n "$hostname" ] && [ "$hostname" != "unknown-$ip" ]; then
                echo "  - $hostname ($ip:$port)"
            fi
        done

        read -r choice
        case $choice in
            todos|all)
                for host_info in "${discovered_list[@]}"; do
                    IFS=':' read -r hostname ip port <<< "$host_info"
                    if [ -n "$hostname" ] && [ "$hostname" != "unknown-$ip" ]; then
                        add_discovered_worker "$hostname" "$ip" "$port"
                    fi
                done
                ;;
            nenhum|none)
                echo -e "${YELLOW}Nenhum worker adicionado${NC}"
                ;;
            *)
                # Try to find specific hostname
                for host_info in "${discovered_list[@]}"; do
                    IFS=':' read -r hostname ip port <<< "$host_info"
                    if [ "$hostname" = "$choice" ]; then
                        add_discovered_worker "$hostname" "$ip" "$port"
                        break
                    fi
                done
                ;;
        esac
    else
        echo -e "${YELLOW}⚠️  Nenhum worker descoberto na rede${NC}"
    fi
}

# Function to resolve worker connection (hostname -> IP)
resolve_worker_connection() {
    local worker_spec=$1  # Can be hostname, alias, or IP
    local config_file=${2:-$HOME/.cluster_config/nodes_list.conf}

    # First, try to find in configuration by hostname or alias
    if [ -f "$config_file" ]; then
        while IFS= read -r line; do
            if [[ $line =~ ^# ]] || [ -z "$line" ]; then
                continue
            fi

            local hostname alias ip user port status
            read -r hostname alias ip user port status <<< "$line"

            if [ "$worker_spec" = "$hostname" ] || [ "$worker_spec" = "$alias" ]; then
                echo "$hostname:$ip:$user:$port:$status"
                return 0
            fi
        done < "$config_file"
    fi

    # If not found in config, try to resolve as hostname
    local resolved_ip=$(resolve_hostname "$worker_spec")
    if [ -n "$resolved_ip" ]; then
        echo "$worker_spec:$resolved_ip:$USER:22:unknown"
        return 0
    fi

    # If it's already an IP, return as-is
    if [[ $worker_spec =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "unknown:$worker_spec:$USER:22:unknown"
        return 0
    fi

    return 1
}

# Help function
show_help() {
    echo "Network Discovery Script for Cluster AI Workers"
    echo
    echo "Usage: $0 [command] [options]"
    echo
    echo "Commands:"
    echo "  discover          Discover workers on the network"
    echo "  resolve <host>    Resolve hostname/alias to connection info"
    echo "  test <host>       Test SSH connection to a host"
    echo "  help              Show this help"
    echo
    echo "Options:"
    echo "  --no-network      Skip network scanning"
    echo "  --no-mdns         Skip mDNS discovery"
    echo "  --user <user>     SSH username (default: current user)"
    echo "  --port <port>     SSH port (default: 22)"
    echo "  --key <file>      SSH key file"
    echo
    echo "Examples:"
    echo "  $0 discover"
    echo "  $0 resolve my-android-device"
    echo "  $0 test 192.168.1.100 --user pi --port 22"
}

# Main script logic
case "${1:-discover}" in
    discover)
        shift
        scan_network=true
        use_mdns=true

        while [[ $# -gt 0 ]]; do
            case $1 in
                --no-network) scan_network=false ;;
                --no-mdns) use_mdns=false ;;
                *) echo "Unknown option: $1"; exit 1 ;;
            esac
            shift
        done

        discover_workers "$scan_network" "$use_mdns"
        ;;
    resolve)
        if [ -z "$2" ]; then
            echo "Error: Please specify a hostname, alias, or IP to resolve"
            exit 1
        fi
        resolve_worker_connection "$2"
        ;;
    test)
        if [ -z "$2" ]; then
            echo "Error: Please specify a host to test"
            exit 1
        fi

        shift
        user=$USER
        port=22
        key_file=""

        while [[ $# -gt 0 ]]; do
            case $1 in
                --user) user="$2"; shift ;;
                --port) port="$2"; shift ;;
                --key) key_file="$2"; shift ;;
                *) echo "Unknown option: $1"; exit 1 ;;
            esac
            shift
        done

        test_ssh_connection "$2" "$user" "$port" "$key_file"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
