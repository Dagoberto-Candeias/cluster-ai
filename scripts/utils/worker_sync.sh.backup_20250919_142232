#!/bin/bash
# =============================================================================
# Worker Synchronization Script for Cluster AI
# =============================================================================

source "$(dirname "$0")/../lib/common.sh"

# Configuration
SYNC_LOG="$HOME/.cluster_config/sync.log"
UPDATE_DIR="$HOME/.cluster_config/updates"
WORKERS_CONF="$HOME/.cluster_config/nodes_list.conf"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log sync operations
log_sync() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$SYNC_LOG"
    echo -e "$message"
}

# Function to create update package
create_update_package() {
    local package_name="$1"
    local target_dir="${2:-$UPDATE_DIR}"

    mkdir -p "$target_dir"

    section "📦 Criando pacote de atualização: $package_name"

    local package_file="$target_dir/${package_name}.tar.gz"
    local temp_dir="/tmp/cluster_ai_update_$$"

    mkdir -p "$temp_dir"

    # Copy essential files for update
    cp -r scripts/ "$temp_dir/" 2>/dev/null || true
    cp -r configs/ "$temp_dir/" 2>/dev/null || true
    cp requirements.txt "$temp_dir/" 2>/dev/null || true
    cp manager.sh "$temp_dir/" 2>/dev/null || true

    # Create version info
    echo "Package: $package_name" > "$temp_dir/version.txt"
    echo "Created: $(date)" >> "$temp_dir/version.txt"
    echo "Creator: $(whoami)@$(hostname)" >> "$temp_dir/version.txt"

    # Create the package
    if tar -czf "$package_file" -C "$temp_dir" .; then
        success "Pacote criado: $package_file"
        log_sync "Created update package: $package_file"

        # Clean up
        rm -rf "$temp_dir"

        echo "$package_file"
        return 0
    else
        error "Falha ao criar pacote"
        rm -rf "$temp_dir"
        return 1
    fi
}

# Function to deploy update to worker
deploy_update_to_worker() {
    local worker_hostname="$1"
    local package_file="$2"
    local worker_info

    # Get worker connection info
    worker_info=$(bash "$(dirname "$0")/network_discovery.sh" resolve "$worker_hostname")

    if [ -z "$worker_info" ]; then
        error "Worker '$worker_hostname' não encontrado ou inacessível"
        return 1
    fi

    local hostname ip user port status
    IFS=':' read -r hostname ip user port status <<< "$worker_info"

    section "🚀 Fazendo deploy da atualização para $hostname ($ip)"

    # Test connection
    if ! timeout 10 ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "echo 'Connection OK'" >/dev/null 2>&1; then
        error "Não foi possível conectar ao worker $hostname"
        return 1
    fi

    # Create remote update directory
    ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "mkdir -p ~/.cluster_ai_updates"

    # Copy update package
    if scp -o StrictHostKeyChecking=no -P "$port" "$package_file" "$user@$ip:~/.cluster_ai_updates/"; then
        success "Pacote copiado para $hostname"

        # Execute update on remote worker
        local remote_command="
            cd ~/.cluster_ai_updates &&
            tar -xzf $(basename "$package_file") &&
            if [ -f version.txt ]; then cat version.txt; fi &&
            echo 'Update package extracted successfully'
        "

        if ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "$remote_command"; then
            success "Atualização aplicada com sucesso em $hostname"
            log_sync "Successfully deployed update to $hostname ($ip)"
            return 0
        else
            error "Falha ao aplicar atualização em $hostname"
            return 1
        fi
    else
        error "Falha ao copiar pacote para $hostname"
        return 1
    fi
}

# Function to sync all workers
sync_all_workers() {
    local package_name="${1:-update-$(date +%Y%m%d_%H%M%S)}"

    section "🔄 Sincronizando todos os workers"

    # Create update package
    local package_file
    package_file=$(create_update_package "$package_name")

    if [ -z "$package_file" ]; then
        error "Falha ao criar pacote de atualização"
        return 1
    fi

    # Get list of active workers
    if [ ! -f "$WORKERS_CONF" ]; then
        error "Arquivo de configuração dos workers não encontrado: $WORKERS_CONF"
        return 1
    fi

    local success_count=0
    local total_count=0

    while IFS= read -r line; do
        if [[ $line =~ ^# ]] || [ -z "$line" ]; then
            continue
        fi

        local hostname alias ip user port status
        read -r hostname alias ip user port status <<< "$line"

        if [ "$status" = "active" ] && [ "$hostname" != "$(hostname)" ]; then
            ((total_count++))
            subsection "Atualizando worker: $hostname ($ip)"

            if deploy_update_to_worker "$hostname" "$package_file"; then
                ((success_count++))
            fi
        fi
    done < "$WORKERS_CONF"

    # Clean up local package
    rm -f "$package_file"

    section "📊 Resultado da Sincronização"
    echo -e "${GREEN}Workers atualizados com sucesso: $success_count/${total_count}${NC}"

    if [ $success_count -eq $total_count ]; then
        success "Todos os workers foram sincronizados!"
        log_sync "All workers synchronized successfully ($success_count/$total_count)"
    else
        warn "Alguns workers não puderam ser atualizados ($success_count/$total_count)"
        log_sync "Partial synchronization completed ($success_count/$total_count)"
    fi
}

# Function to check for updates on worker
check_worker_updates() {
    local worker_hostname="$1"

    section "🔍 Verificando atualizações no worker: $worker_hostname"

    local worker_info
    worker_info=$(bash "$(dirname "$0")/network_discovery.sh" resolve "$worker_hostname")

    if [ -z "$worker_info" ]; then
        error "Worker '$worker_hostname' não encontrado"
        return 1
    fi

    local hostname ip user port status
    IFS=':' read -r hostname ip user port status <<< "$worker_info"

    # Check for update directory on worker
    local remote_command="
        if [ -d ~/.cluster_ai_updates ]; then
            echo 'Update directory exists'
            ls -la ~/.cluster_ai_updates/ | grep -v '^total' | wc -l
        else
            echo 'No update directory'
        fi
    "

    local result
    result=$(ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "$remote_command" 2>/dev/null)

    if [[ $result == *"Update directory exists"* ]]; then
        local update_count
        update_count=$(echo "$result" | grep -o '[0-9]\+')
        echo -e "${GREEN}✅ Worker $hostname tem $update_count pacote(s) de atualização${NC}"
    else
        echo -e "${YELLOW}⚠️  Worker $hostname não tem pacotes de atualização${NC}"
    fi
}

# Function to clean old updates
clean_old_updates() {
    local days_old="${1:-30}"

    section "🧹 Limpando atualizações antigas (+$days_old dias)"

    # Clean local updates
    if [ -d "$UPDATE_DIR" ]; then
        local old_files
        old_files=$(find "$UPDATE_DIR" -name "*.tar.gz" -mtime +"$days_old" | wc -l)

        if [ "$old_files" -gt 0 ]; then
            find "$UPDATE_DIR" -name "*.tar.gz" -mtime +"$days_old" -delete
            success "Removidos $old_files pacotes antigos localmente"
        fi
    fi

    # Clean remote updates on all workers
    if [ -f "$WORKERS_CONF" ]; then
        while IFS= read -r line; do
            if [[ $line =~ ^# ]] || [ -z "$line" ]; then
                continue
            fi

            local hostname alias ip user port status
            read -r hostname alias ip user port status <<< "$line"

            if [ "$status" = "active" ]; then
                subsection "Limpando worker: $hostname"

                local remote_command="
                    if [ -d ~/.cluster_ai_updates ]; then
                        find ~/.cluster_ai_updates -name '*.tar.gz' -mtime +$days_old -delete 2>/dev/null || true
                        echo 'Cleanup completed on $hostname'
                    fi
                "

                ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "$remote_command" 2>/dev/null || true
            fi
        done < "$WORKERS_CONF"
    fi

    success "Limpeza de atualizações antigas concluída"
}

# Function to show sync status
show_sync_status() {
    section "📊 Status da Sincronização"

    echo -e "${BLUE}=== Arquivos de Atualização Local ===${NC}"
    if [ -d "$UPDATE_DIR" ]; then
        ls -la "$UPDATE_DIR"/*.tar.gz 2>/dev/null || echo "Nenhum pacote de atualização local"
    else
        echo "Diretório de atualizações não existe"
    fi

    echo
    echo -e "${BLUE}=== Status dos Workers ===${NC}"

    if [ -f "$WORKERS_CONF" ]; then
        while IFS= read -r line; do
            if [[ $line =~ ^# ]] || [ -z "$line" ]; then
                continue
            fi

            local hostname alias ip user port status
            read -r hostname alias ip user port status <<< "$line"

            echo -n "$hostname ($ip): "
            check_worker_updates "$hostname" | tail -1
        done < "$WORKERS_CONF"
    else
        echo "Arquivo de configuração dos workers não encontrado"
    fi

    echo
    echo -e "${BLUE}=== Log de Sincronização ===${NC}"
    if [ -f "$SYNC_LOG" ]; then
        tail -10 "$SYNC_LOG" 2>/dev/null || echo "Log vazio"
    else
        echo "Arquivo de log não encontrado"
    fi
}

# Help function
show_help() {
    echo "Worker Synchronization Script for Cluster AI"
    echo
    echo "Usage: $0 [command] [options]"
    echo
    echo "Commands:"
    echo "  sync [package_name]    Sync all active workers with latest updates"
    echo "  deploy <worker> <package>  Deploy specific update to specific worker"
    echo "  check <worker>         Check for updates on specific worker"
    echo "  create <package_name>  Create update package"
    echo "  clean [days]           Clean old updates (default: 30 days)"
    echo "  status                 Show synchronization status"
    echo "  help                   Show this help"
    echo
    echo "Examples:"
    echo "  $0 sync"
    echo "  $0 deploy celdago update-20241201.tar.gz"
    echo "  $0 check android-worker"
    echo "  $0 create emergency-fix"
    echo "  $0 clean 7"
    echo "  $0 status"
}

# Main script logic
case "${1:-help}" in
    sync)
        shift
        sync_all_workers "$@"
        ;;
    deploy)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Error: Please specify worker hostname and package file"
            exit 1
        fi
        deploy_update_to_worker "$2" "$3"
        ;;
    check)
        if [ -z "$2" ]; then
            echo "Error: Please specify worker hostname"
            exit 1
        fi
        check_worker_updates "$2"
        ;;
    create)
        if [ -z "$2" ]; then
            echo "Error: Please specify package name"
            exit 1
        fi
        create_update_package "$2"
        ;;
    clean)
        shift
        clean_old_updates "$@"
        ;;
    status)
        show_sync_status
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
