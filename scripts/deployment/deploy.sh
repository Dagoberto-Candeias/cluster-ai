#!/bin/bash
# Script de Deploy para Cluster AI
# Suporte a múltiplos ambientes e estratégias de deploy

set -euo pipefail

# =============================================================================
# CONFIGURAÇÃO
# =============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="${PROJECT_ROOT}/scripts/deployment"
ENVIRONMENT="${1:-development}"
DEPLOY_STRATEGY="${2:-rolling}"

# Performance monitoring configuration
MEMORY_THRESHOLD=85
CPU_THRESHOLD=90
MONITOR_INTERVAL=10
MEMORY_LIMIT_MB=2048  # 2GB memory limit for long-running processes
PERFORMANCE_LOG="${PROJECT_ROOT}/logs/deploy_performance_$(date +%Y%m%d_%H%M%S).log"

# Performance recovery configuration
RECOVERY_ENABLED=true
RECOVERY_COOLDOWN=300  # 5 minutes between recovery attempts
LAST_RECOVERY_TIME=0
MAX_RECOVERY_ATTEMPTS=3
RECOVERY_ATTEMPTS=0

# Caching configuration
RSYNC_CACHE_DIR="${PROJECT_ROOT}/.cache/rsync"
DEPLOY_CACHE_FILE="${RSYNC_CACHE_DIR}/deploy_cache_$(date +%Y%m%d).tar.gz"
CACHE_MAX_AGE=7  # days

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configurações por ambiente
declare -A ENV_CONFIGS=(
    ["development,host"]="localhost"
    ["development,user"]="dev"
    ["development,path"]="/opt/cluster-ai-dev"
    ["staging,host"]="staging.cluster.ai"
    ["staging,user"]="deploy"
    ["staging,path"]="/opt/cluster-ai-staging"
    ["production,host"]="cluster.ai"
    ["production,user"]="deploy"
    ["production,path"]="/opt/cluster-ai"
)

# =============================================================================
# FUNÇÕES UTILITÁRIAS
# =============================================================================

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

# Performance monitoring functions
start_performance_monitoring() {
    local operation="$1"
    echo "Starting performance monitoring for: $operation" >> "$PERFORMANCE_LOG"
    echo "Timestamp: $(date)" >> "$PERFORMANCE_LOG"
    echo "Operation: $operation" >> "$PERFORMANCE_LOG"
    echo "---" >> "$PERFORMANCE_LOG"
}

log_performance_metrics() {
    local timestamp=$(date +%s)
    local mem_usage=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

    echo "$timestamp,$mem_usage,$cpu_usage,$disk_usage" >> "$PERFORMANCE_LOG"
}

check_performance_thresholds() {
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

    if (( $(echo "$mem_usage > $MEMORY_THRESHOLD" | bc -l) )); then
        warning "Memory usage high: ${mem_usage}% (threshold: ${MEMORY_THRESHOLD}%)"
        return 1
    fi

    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
        warning "CPU usage high: ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
        return 1
    fi

    return 0
}

monitor_operation() {
    local operation="$1"
    local pid="$2"

    start_performance_monitoring "$operation"

    # Monitor in background
    (
        while kill -0 "$pid" 2>/dev/null; do
            log_performance_metrics
            sleep "$MONITOR_INTERVAL"
        done
    ) &
    local monitor_pid=$!

    # Enforce memory limit on the monitored process
    (
        while kill -0 "$pid" 2>/dev/null; do
            mem_usage_kb=$(pmap "$pid" 2>/dev/null | tail -n 1 | awk '/[0-9]K/{print $2}' | sed 's/K//')
            mem_usage_mb=$((mem_usage_kb / 1024))
            if [ "$mem_usage_mb" -gt "$MEMORY_LIMIT_MB" ]; then
                warning "Process $pid exceeded memory limit (${mem_usage_mb}MB > ${MEMORY_LIMIT_MB}MB). Killing process."
                kill -9 "$pid"
                break
            fi
            sleep 5
        done
    ) &

    # Wait for operation to complete
    wait "$pid" 2>/dev/null
    local exit_code=$?

    # Stop monitoring
    kill "$monitor_pid" 2>/dev/null || true
    wait "$monitor_pid" 2>/dev/null || true

    # Final metrics
    log_performance_metrics
    echo "Exit code: $exit_code" >> "$PERFORMANCE_LOG"
    echo "---" >> "$PERFORMANCE_LOG"

    return $exit_code
}

# Performance recovery automation functions
trigger_performance_recovery() {
    local issue_type="$1"
    local severity="$2"

    if [ "$RECOVERY_ENABLED" != true ]; then
        log "Performance recovery disabled, skipping recovery for $issue_type"
        return 0
    fi

    # Check cooldown period
    local current_time=$(date +%s)
    local time_since_last_recovery=$((current_time - LAST_RECOVERY_TIME))

    if [ $time_since_last_recovery -lt $RECOVERY_COOLDOWN ]; then
        log "Recovery cooldown active (${time_since_last_recovery}s < ${RECOVERY_COOLDOWN}s), skipping recovery"
        return 0
    fi

    # Check max attempts
    if [ $RECOVERY_ATTEMPTS -ge $MAX_RECOVERY_ATTEMPTS ]; then
        warning "Maximum recovery attempts ($MAX_RECOVERY_ATTEMPTS) reached, manual intervention required"
        return 1
    fi

    log "Triggering performance recovery for: $issue_type (severity: $severity)"
    ((RECOVERY_ATTEMPTS++))
    LAST_RECOVERY_TIME=$current_time

    case "$issue_type" in
        "high_memory")
            recover_high_memory "$severity"
            ;;
        "high_cpu")
            recover_high_cpu "$severity"
            ;;
        "disk_io_high")
            recover_disk_io "$severity"
            ;;
        "network_latency")
            recover_network_latency "$severity"
            ;;
        *)
            warning "Unknown issue type for recovery: $issue_type"
            ;;
    esac
}

recover_high_memory() {
    local severity="$1"
    log "Executing memory recovery (severity: $severity)"

    case "$severity" in
        "critical")
            # Aggressive memory recovery
            log "Critical memory recovery: dropping caches and killing high-memory processes"

            # Drop system caches
            echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

            # Kill processes consuming >500MB (excluding system processes)
            ps aux --no-headers -o pid,rss,cmd | awk '$2 > 524288 {print $1}' | \
                grep -v -E "(systemd|init|bash|sshd)" | head -5 | \
                xargs -r kill -9 2>/dev/null || true

            # Restart memory-intensive services
            systemctl restart ollama 2>/dev/null || true
            systemctl restart docker 2>/dev/null || true
            ;;
        "high")
            # Moderate memory recovery
            log "High memory recovery: dropping caches and optimizing memory"

            # Drop page cache only
            echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || true

            # Clear temporary files
            find /tmp -name "*.tmp" -type f -mtime +1 -delete 2>/dev/null || true
            find /var/tmp -name "*.tmp" -type f -mtime +1 -delete 2>/dev/null || true
            ;;
        "medium")
            # Light memory recovery
            log "Medium memory recovery: basic cache cleanup"

            # Clear apt cache
            apt-get clean >/dev/null 2>&1 || true

            # Clear Python cache
            find . -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
            ;;
    esac

    success "Memory recovery completed"
}

recover_high_cpu() {
    local severity="$1"
    log "Executing CPU recovery (severity: $severity)"

    case "$severity" in
        "critical")
            # Aggressive CPU recovery
            log "Critical CPU recovery: killing high-CPU processes and adjusting priorities"

            # Find and kill processes with CPU >90%
            ps aux --no-headers -o pid,%cpu,cmd | awk '$2 > 90 {print $1}' | \
                grep -v -E "(systemd|init|bash|sshd)" | head -3 | \
                xargs -r kill -9 2>/dev/null || true

            # Renice remaining high-CPU processes
            ps aux --no-headers -o pid,%cpu | awk '$2 > 50 {print $1}' | \
                xargs -r renice 10 2>/dev/null || true
            ;;
        "high")
            # Moderate CPU recovery
            log "High CPU recovery: adjusting process priorities"

            # Renice high-CPU processes
            ps aux --no-headers -o pid,%cpu | awk '$2 > 30 {print $1}' | \
                xargs -r renice 5 2>/dev/null || true

            # Stop non-essential services temporarily
            systemctl stop bluetooth 2>/dev/null || true
            systemctl stop cups 2>/dev/null || true
            ;;
        "medium")
            # Light CPU recovery
            log "Medium CPU recovery: basic process optimization"

            # Adjust I/O priority for background processes
            ionice -c 3 -p $(pgrep -f "rsync\|tar\|gzip") 2>/dev/null || true
            ;;
    esac

    success "CPU recovery completed"
}

recover_disk_io() {
    local severity="$1"
    log "Executing disk I/O recovery (severity: $severity)"

    case "$severity" in
        "critical")
            # Aggressive I/O recovery
            log "Critical I/O recovery: stopping I/O intensive processes"

            # Kill processes with high I/O
            iotop -b -n 1 -o | awk 'NR>7 && $10 > 50 {print $1}' | \
                grep -v -E "(systemd|init|bash|sshd)" | head -3 | \
                xargs -r kill -9 2>/dev/null || true

            # Sync filesystem to clear pending writes
            sync
            ;;
        "high")
            # Moderate I/O recovery
            log "High I/O recovery: optimizing I/O operations"

            # Adjust I/O scheduler to deadline
            echo deadline > /sys/block/sda/queue/scheduler 2>/dev/null || true

            # Increase read-ahead
            echo 1024 > /sys/block/sda/queue/read_ahead_kb 2>/dev/null || true

            # Stop non-essential I/O services
            systemctl stop syslog 2>/dev/null || true
            ;;
        "medium")
            # Light I/O recovery
            log "Medium I/O recovery: basic I/O optimization"

            # Clear page cache to reduce I/O pressure
            echo 1 > /proc/sys/vm/drop_caches 2>/dev/null || true

            # Optimize log rotation
            logrotate -f /etc/logrotate.conf >/dev/null 2>&1 || true
            ;;
    esac

    success "Disk I/O recovery completed"
}

recover_network_latency() {
    local severity="$1"
    log "Executing network recovery (severity: $severity)"

    case "$severity" in
        "critical")
            # Aggressive network recovery
            log "Critical network recovery: restarting network services"

            # Restart network manager
            systemctl restart NetworkManager 2>/dev/null || true
            systemctl restart networking 2>/dev/null || true

            # Clear DNS cache
            systemctl restart systemd-resolved 2>/dev/null || true
            ;;
        "high")
            # Moderate network recovery
            log "High network recovery: optimizing network settings"

            # Adjust TCP settings for better performance
            echo 1 > /proc/sys/net/ipv4/tcp_low_latency 2>/dev/null || true
            echo 0 > /proc/sys/net/ipv4/tcp_timestamps 2>/dev/null || true

            # Restart Docker network
            docker network prune -f >/dev/null 2>&1 || true
            ;;
        "medium")
            # Light network recovery
            log "Medium network recovery: basic network optimization"

            # Clear ARP cache
            ip neigh flush all >/dev/null 2>&1 || true

            # Restart SSH service if needed
            systemctl reload ssh >/dev/null 2>&1 || true
            ;;
    esac

    success "Network recovery completed"
}

# Enhanced performance monitoring with recovery
enhanced_performance_monitor() {
    local operation="$1"
    local pid="$2"
    local recovery_enabled="${3:-true}"

    start_performance_monitoring "$operation"

    # Monitor in background with recovery
    (
        local consecutive_high_memory=0
        local consecutive_high_cpu=0
        local consecutive_high_disk=0

        while kill -0 "$pid" 2>/dev/null; do
            log_performance_metrics

            if [ "$recovery_enabled" = true ]; then
                # Check for performance issues and trigger recovery
                local mem_usage cpu_usage disk_usage
                mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
                cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
                disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

                # Memory monitoring with recovery
                if (( $(echo "$mem_usage > 90" | bc -l) )); then
                    ((consecutive_high_memory++))
                    if [ $consecutive_high_memory -ge 3 ]; then
                        trigger_performance_recovery "high_memory" "critical"
                        consecutive_high_memory=0
                    fi
                elif (( $(echo "$mem_usage > 80" | bc -l) )); then
                    ((consecutive_high_memory++))
                    if [ $consecutive_high_memory -ge 5 ]; then
                        trigger_performance_recovery "high_memory" "high"
                        consecutive_high_memory=0
                    fi
                else
                    consecutive_high_memory=0
                fi

                # CPU monitoring with recovery
                if (( $(echo "$cpu_usage > 95" | bc -l) )); then
                    ((consecutive_high_cpu++))
                    if [ $consecutive_high_cpu -ge 3 ]; then
                        trigger_performance_recovery "high_cpu" "critical"
                        consecutive_high_cpu=0
                    fi
                elif (( $(echo "$cpu_usage > 85" | bc -l) )); then
                    ((consecutive_high_cpu++))
                    if [ $consecutive_high_cpu -ge 5 ]; then
                        trigger_performance_recovery "high_cpu" "high"
                        consecutive_high_cpu=0
                    fi
                else
                    consecutive_high_cpu=0
                fi

                # Disk I/O monitoring with recovery (simplified)
                if [ "$disk_usage" -gt 95 ]; then
                    ((consecutive_high_disk++))
                    if [ $consecutive_high_disk -ge 3 ]; then
                        trigger_performance_recovery "disk_io_high" "critical"
                        consecutive_high_disk=0
                    fi
                elif [ "$disk_usage" -gt 85 ]; then
                    ((consecutive_high_disk++))
                    if [ $consecutive_high_disk -ge 5 ]; then
                        trigger_performance_recovery "disk_io_high" "high"
                        consecutive_high_disk=0
                    fi
                else
                    consecutive_high_disk=0
                fi
            fi

            sleep "$MONITOR_INTERVAL"
        done
    ) &
    local monitor_pid=$!

    # Enforce memory limit on the monitored process
    (
        while kill -0 "$pid" 2>/dev/null; do
            mem_usage_kb=$(pmap "$pid" 2>/dev/null | tail -n 1 | awk '/[0-9]K/{print $2}' | sed 's/K//')
            mem_usage_mb=$((mem_usage_kb / 1024))
            if [ "$mem_usage_mb" -gt "$MEMORY_LIMIT_MB" ]; then
                warning "Process $pid exceeded memory limit (${mem_usage_mb}MB > ${MEMORY_LIMIT_MB}MB). Killing process."
                kill -9 "$pid"
                break
            fi
            sleep 5
        done
    ) &

    # Wait for operation to complete
    wait "$pid" 2>/dev/null
    local exit_code=$?

    # Stop monitoring
    kill "$monitor_pid" 2>/dev/null || true
    wait "$monitor_pid" 2>/dev/null || true

    # Final metrics
    log_performance_metrics
    echo "Exit code: $exit_code" >> "$PERFORMANCE_LOG"
    echo "---" >> "$PERFORMANCE_LOG"

    return $exit_code
}

# Intelligent caching functions
setup_rsync_cache() {
    mkdir -p "$RSYNC_CACHE_DIR"

    # Clean old cache files
    find "$RSYNC_CACHE_DIR" -name "deploy_cache_*.tar.gz" -mtime +$CACHE_MAX_AGE -delete 2>/dev/null || true

    # Check if today's cache exists
    if [ -f "$DEPLOY_CACHE_FILE" ]; then
        echo "✅ Cache de deploy encontrado para hoje"
        return 0
    else
        echo "📦 Criando novo cache de deploy..."
        return 1
    fi
}

# Docker layer caching functions
setup_docker_cache() {
    local docker_cache_dir="$HOME/.cache/docker"
    mkdir -p "$docker_cache_dir"

    # Configure Docker daemon for better caching
    local daemon_config="/etc/docker/daemon.json"
    if [ ! -f "$daemon_config" ] || ! grep -q "storage-driver" "$daemon_config"; then
        log "Configurando Docker para melhor cache..."
        sudo tee "$daemon_config" > /dev/null << EOF
{
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "registry-mirrors": ["https://registry-1.docker.io"],
    "experimental": true,
    "features": {
        "buildkit": true
    },
    "builder": {
        "gc": {
            "enabled": true,
            "defaultKeepStorage": "20GB",
            "policy": [
                {"keepStorage": "10GB", "filter": ["unused-for=2200h"]},
                {"keepStorage": "25GB", "filter": ["unused-for=3300h"]},
                {"keepStorage": "50GB", "all": true}
            ]
        }
    }
}
EOF
        sudo systemctl restart docker 2>/dev/null || true
        log "✅ Docker configurado com cache otimizado"
    fi
}

build_with_cache() {
    local dockerfile_path="$1"
    local image_tag="$2"
    local context_dir="$3"

    # Enable BuildKit for better caching
    export DOCKER_BUILDKIT=1

    # Use build cache mounts for common operations
    log "Construindo imagem Docker com cache otimizado..."

    docker build \
        --tag "$image_tag" \
        --cache-from "$image_tag:latest" \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        --progress=plain \
        "$context_dir" \
        -f "$dockerfile_path"

    if [ $? -eq 0 ]; then
        log "✅ Imagem construída com sucesso usando cache"
        return 0
    else
        log "❌ Falha na construção da imagem"
        return 1
    fi
}

pull_with_cache() {
    local image="$1"
    local max_retries=3
    local attempt=1

    while [ $attempt -le $max_retries ]; do
        log "🐳 Tentativa $attempt/$max_retries: Baixando imagem $image com cache..."

        # Check if image exists locally first
        if docker image inspect "$image" >/dev/null 2>&1; then
            log "✅ Imagem $image já existe localmente"
            return 0
        fi

        if docker pull "$image"; then
            log "✅ Imagem $image baixada com sucesso"
            return 0
        fi

        sleep 2
        ((attempt++))
    done

    log "❌ Falha ao baixar imagem $image após $max_retries tentativas"
    return 1
}

create_deploy_cache() {
    local source_dir="$1"

    log "Criando cache de deploy..."
    cd "$source_dir" || return 1

    # Create compressed cache of deploy files
    tar -czf "$DEPLOY_CACHE_FILE" \
        --exclude='.git' \
        --exclude='__pycache__' \
        --exclude='*.pyc' \
        --exclude='.pytest_cache' \
        --exclude='logs' \
        --exclude='.cache' \
        .

    if [ $? -eq 0 ]; then
        success "Cache de deploy criado: $DEPLOY_CACHE_FILE"
        return 0
    else
        error "Falha ao criar cache de deploy"
        return 1
    fi
}

use_deploy_cache() {
    local target_dir="$1"

    if [ -f "$DEPLOY_CACHE_FILE" ]; then
        log "Usando cache de deploy..."
        mkdir -p "$target_dir"
        cd "$target_dir" || return 1

        # Extract from cache
        tar -xzf "$DEPLOY_CACHE_FILE"

        if [ $? -eq 0 ]; then
            success "Cache de deploy extraído com sucesso"
            return 0
        else
            error "Falha ao extrair cache de deploy"
            return 1
        fi
    fi

    return 1
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

section() {
    echo
    echo -e "${PURPLE}================================================================================${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}================================================================================${NC}"
    echo
}

# =============================================================================
# VALIDAÇÃO
# =============================================================================

validate_environment() {
    section "VALIDAÇÃO DO AMBIENTE"

    # Verificar se o ambiente é suportado
    if [[ ! "${ENV_CONFIGS[${ENVIRONMENT},host]+_}" ]]; then
        error "Ambiente '${ENVIRONMENT}' não é suportado. Ambientes disponíveis: development, staging, production"
    fi

    # Verificar dependências
    local deps=("rsync" "ssh" "git")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "Dependência '$dep' não encontrada. Instale-a antes de continuar."
        fi
    done

    # Verificar se estamos em um repositório git limpo
    if [[ -n $(git status --porcelain) ]]; then
        warning "Repositório git não está limpo. Mudanças não commitadas serão ignoradas."
        read -p "Continuar mesmo assim? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    success "Validação do ambiente concluída"
}

# =============================================================================
# PREPARAÇÃO DO DEPLOY
# =============================================================================

prepare_deploy() {
    section "PREPARAÇÃO DO DEPLOY"

    # Try to use cache first
    setup_rsync_cache
    if use_deploy_cache "$DEPLOY_TMP_DIR"; then
        log "Usando cache de deploy existente"
    else
        # Criar diretório temporário para o deploy
        DEPLOY_TMP_DIR=$(mktemp -d)
        log "Diretório temporário criado: $DEPLOY_TMP_DIR"

        # Fazer checkout limpo do código
        log "Preparando código para deploy..."
        git archive --format=tar --output="${DEPLOY_TMP_DIR}/cluster-ai.tar" HEAD
        cd "$DEPLOY_TMP_DIR"
        tar -xf cluster-ai.tar
        rm cluster-ai.tar

        # Instalar dependências Python
        if [ -f "requirements.txt" ]; then
            log "Instalando dependências Python..."
            python3 -m venv venv
            source venv/bin/activate
            pip install --upgrade pip
            pip install -r requirements.txt
            deactivate
        fi

        # Configurar permissões
        find . -name "*.sh" -exec chmod +x {} \;

        # Create cache for future use
        create_deploy_cache "$DEPLOY_TMP_DIR"
    fi

    success "Preparação do deploy concluída"
}

# =============================================================================
# ESTRATÉGIAS DE DEPLOY
# =============================================================================

deploy_rolling() {
    section "DEPLOY ROLLING UPDATE"

    local host="${ENV_CONFIGS[${ENVIRONMENT},host]}"
    local user="${ENV_CONFIGS[${ENVIRONMENT},user]}"
    local path="${ENV_CONFIGS[${ENVIRONMENT},path]}"

    log "Iniciando deploy rolling para ${ENVIRONMENT}..."

    # Check performance before starting
    if ! check_performance_thresholds; then
        warning "System resources are high, but proceeding with deploy..."
    fi

    # Criar backup with enhanced monitoring and recovery
    log "Criando backup da versão atual..."
    ssh "${user}@${host}" "cd '${path}' && tar -czf backup_$(date +%Y%m%d_%H%M%S).tar.gz ." &
    local backup_pid=$!
    enhanced_performance_monitor "backup_creation" "$backup_pid" true

    # Sincronizar arquivos with parallel optimization and monitoring
    log "Sincronizando arquivos com paralelização otimizada..."

    # Enhanced parallel rsync function with I/O optimization
    parallel_rsync_deploy() {
        local source_dir="$1"
        local dest="$2"
        local max_parallel=4

        # Check available memory and adjust parallelism
        local mem_usage
        mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
        if [ "$mem_usage" -gt 80 ]; then
            max_parallel=2
            log "Memory high (${mem_usage}%), reducing parallel rsync to $max_parallel"
        elif [ "$mem_usage" -gt 60 ]; then
            max_parallel=3
            log "Memory moderate (${mem_usage}%), setting parallel rsync to $max_parallel"
        fi

        # Create file list for parallel sync with size-based sorting
        local file_list
        file_list=$(mktemp)

        # Generate file list with sizes (excluding large directories)
        find "$source_dir" -type f \
            -not -path '*/.git/*' \
            -not -path '*/__pycache__/*' \
            -not -name '*.pyc' \
            -not -path '*/.pytest_cache/*' \
            -not -name '*.log' \
            -exec stat -f "%z %N" {} \; 2>/dev/null | sort -nr > "$file_list"

        local total_files
        total_files=$(wc -l < "$file_list")

        if [ "$total_files" -lt 10 ]; then
            # For few files, use normal rsync with optimized flags
            rsync -avz --delete --exclude='.git' --exclude='__pycache__' \
                --exclude='*.pyc' --exclude='.pytest_cache' \
                --bwlimit=0 --compress-level=6 \
                "$source_dir/" "$dest/"
        else
            # For many files, use enhanced parallelization
            log "Sincronizando $total_files arquivos em paralelo (max $max_parallel jobs)..."

            # Split files into chunks (larger files first for better I/O)
            local chunk_size=$(( (total_files + max_parallel - 1) / max_parallel ))
            local temp_dir
            temp_dir=$(mktemp -d)

            # Create sync scripts for each chunk with I/O optimization
            for ((i=0; i<max_parallel; i++)); do
                local start=$((i * chunk_size + 1))
                local end=$((start + chunk_size - 1))

                if [ $start -le $total_files ]; then
                    sed -n "${start},${end}p" "$file_list" | awk '{print $2}' > "${temp_dir}/files_${i}.txt"

                    cat > "${temp_dir}/sync_${i}.sh" << EOF
#!/bin/bash
# Set I/O priority for background sync
ionice -c 3 -p \$\$

while IFS= read -r file; do
    # Calculate relative path
    relative_path=\${file#$source_dir/}
    dest_dir=\$(dirname "$dest/\$relative_path")

    # Create directory if it doesn't exist
    ssh "${user}@${host}" "mkdir -p '\$dest_dir'" 2>/dev/null || true

    # Sync individual file with optimized flags
    rsync -az --bwlimit=0 --compress-level=6 "\$file" "${user}@${host}:$dest/\$relative_path" 2>/dev/null || true
done < "${temp_dir}/files_${i}.txt"
EOF
                    chmod +x "${temp_dir}/sync_${i}.sh"
                fi
            done

            # Execute syncs in parallel with monitoring
            local pids=()
            local start_time=$(date +%s)
            for script in "${temp_dir}"/sync_*.sh; do
                if [ -f "$script" ]; then
                    "$script" &
                    pids+=($!)
                fi
            done

            # Monitor progress and wait for completion
            local completed=0
            local total_pids=${#pids[@]}
            while [ $completed -lt $total_pids ]; do
                completed=0
                for pid in "${pids[@]}"; do
                    if ! kill -0 "$pid" 2>/dev/null; then
                        ((completed++))
                    fi
                done
                sleep 2
            done

            # Wait for all processes to finish
            for pid in "${pids[@]}"; do
                wait "$pid"
            done

            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            log "Parallel sync completed in ${duration}s"

            # Cleanup
            rm -rf "$temp_dir"
        fi

        # Clean temp file
        rm -f "$file_list"

        # Final sync for directory structure, permissions, and any missed files
        rsync -avz --delete --exclude='.git' --exclude='__pycache__' \
            --exclude='*.pyc' --exclude='.pytest_cache' \
            --exclude='*.log' --bwlimit=0 --compress-level=6 \
            "$source_dir/" "$dest/"
    }

    # Execute parallel rsync with enhanced monitoring and recovery
    parallel_rsync_deploy "${DEPLOY_TMP_DIR}" "${user}@${host}:${path}" &
    local rsync_pid=$!
    enhanced_performance_monitor "parallel_file_sync" "$rsync_pid" true

    # Executar migrações se necessário with enhanced monitoring and recovery
    if ssh "${user}@${host}" "[ -f '${path}/scripts/migration.sh' ]"; then
        log "Executando migrações..."
        ssh "${user}@${host}" "cd '${path}' && bash scripts/migration.sh" &
        local migration_pid=$!
        enhanced_performance_monitor "migration" "$migration_pid" true
    fi

    # Reiniciar serviços with enhanced monitoring and recovery
    log "Reiniciando serviços..."
    ssh "${user}@${host}" "cd '${path}' && bash scripts/restart_services.sh" &
    local restart_pid=$!
    enhanced_performance_monitor "service_restart" "$restart_pid" true

    success "Deploy rolling concluído"
    info "Performance log saved to: $PERFORMANCE_LOG"
}

deploy_blue_green() {
    section "DEPLOY BLUE-GREEN"

    local host="${ENV_CONFIGS[${ENVIRONMENT},host]}"
    local user="${ENV_CONFIGS[${ENVIRONMENT},user]}"
    local path="${ENV_CONFIGS[${ENVIRONMENT},path]}"

    log "Iniciando deploy blue-green para ${ENVIRONMENT}..."

    # Determinar qual versão está ativa
    local active_version
    active_version=$(ssh "${user}@${host}" "readlink '${path}/current'" | xargs basename)

    local new_version="blue"
    if [ "$active_version" = "blue" ]; then
        new_version="green"
    fi

    local new_path="${path}/${new_version}"

    # Deploy para nova versão
    log "Deploying para versão ${new_version}..."
    ssh "${user}@${host}" "mkdir -p '${new_path}'"
    rsync -avz --delete --exclude='.git' --exclude='__pycache__' \
        --exclude='*.pyc' --exclude='.pytest_cache' \
        "${DEPLOY_TMP_DIR}/" "${user}@${host}:${new_path}/"

    # Executar testes na nova versão
    log "Executando testes na nova versão..."
    ssh "${user}@${host}" "cd '${new_path}' && bash scripts/run_tests.sh"

    # Executar migrações se necessário
    if ssh "${user}@${host}" "[ -f '${new_path}/scripts/migration.sh' ]"; then
        log "Executando migrações..."
        ssh "${user}@${host}" "cd '${new_path}' && bash scripts/migration.sh"
    fi

    # Testar nova versão
    log "Testando nova versão..."
    if ssh "${user}@${host}" "cd '${new_path}' && bash scripts/health_check.sh"; then
        # Switch para nova versão
        log "Alternando para nova versão..."
        ssh "${user}@${host}" "cd '${path}' && ln -sfn '${new_version}' current"

        # Reiniciar serviços
        ssh "${user}@${host}" "cd '${path}/current' && bash scripts/restart_services.sh"

        success "Deploy blue-green concluído - versão ${new_version} ativada"
    else
        error "Testes falharam na nova versão. Deploy abortado."
    fi
}

deploy_canary() {
    section "DEPLOY CANARY"

    local host="${ENV_CONFIGS[${ENVIRONMENT},host]}"
    local user="${ENV_CONFIGS[${ENVIRONMENT},user]}"
    local path="${ENV_CONFIGS[${ENVIRONMENT},path]}"

    log "Iniciando deploy canary para ${ENVIRONMENT}..."

    # Deploy para subconjunto de servidores
    local canary_servers=("server1" "server2")  # Configurar conforme necessário

    for server in "${canary_servers[@]}"; do
        log "Deploying para servidor canary: ${server}..."

        # Sincronizar para servidor canary
        rsync -avz --delete --exclude='.git' --exclude='__pycache__' \
            --exclude='*.pyc' --exclude='.pytest_cache' \
            "${DEPLOY_TMP_DIR}/" "${user}@${server}:${path}/"

        # Executar testes no servidor canary
        if ssh "${user}@${server}" "cd '${path}' && bash scripts/health_check.sh"; then
            success "Servidor canary ${server} aprovado"
        else
            error "Servidor canary ${server} falhou nos testes"
        fi
    done

    # Se todos os servidores canary passarem, continuar com deploy completo
    log "Todos os servidores canary aprovados. Continuando com deploy completo..."
    deploy_rolling

    success "Deploy canary concluído"
}

# =============================================================================
# PÓS-DEPLOY
# =============================================================================

post_deploy() {
    section "PÓS-DEPLOY"

    local host="${ENV_CONFIGS[${ENVIRONMENT},host]}"
    local user="${ENV_CONFIGS[${ENVIRONMENT},user]}"
    local path="${ENV_CONFIGS[${ENVIRONMENT},path]}"

    # Executar verificações finais
    log "Executando verificações finais..."
    if ssh "${user}@${host}" "cd '${path}' && bash scripts/health_check.sh"; then
        success "Verificações de saúde passaram"
    else
        warning "Algumas verificações de saúde falharam"
    fi

    # Limpar backups antigos (manter apenas os últimos 5)
    log "Limpando backups antigos..."
    ssh "${user}@${host}" "cd '${path}' && ls -t backup_*.tar.gz | tail -n +6 | xargs -r rm"

    # Enviar notificações
    log "Enviando notificações..."
    # Adicionar lógica de notificação aqui

    success "Pós-deploy concluído"
}

# =============================================================================
# ROLLBACK
# =============================================================================

rollback() {
    section "ROLLBACK"

    local host="${ENV_CONFIGS[${ENVIRONMENT},host]}"
    local user="${ENV_CONFIGS[${ENVIRONMENT},user]}"
    local path="${ENV_CONFIGS[${ENVIRONMENT},path]}"

    log "Iniciando rollback para ${ENVIRONMENT}..."

    # Encontrar último backup
    local latest_backup
    latest_backup=$(ssh "${user}@${host}" "cd '${path}' && ls -t backup_*.tar.gz | head -1")

    if [ -z "$latest_backup" ]; then
        error "Nenhum backup encontrado para rollback"
    fi

    log "Restaurando backup: ${latest_backup}"

    # Restaurar backup
    ssh "${user}@${host}" "cd '${path}' && tar -xzf '${latest_backup}'"

    # Reiniciar serviços
    ssh "${user}@${host}" "cd '${path}' && bash scripts/restart_services.sh"

    success "Rollback concluído"
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    log "Iniciando deploy para ambiente: ${ENVIRONMENT}"
    log "Estratégia: ${DEPLOY_STRATEGY}"

    # Validar entrada
    if [ $# -lt 1 ] || [ $# -gt 2 ]; then
        echo "Uso: $0 <environment> [strategy]"
        echo ""
        echo "Ambientes: development, staging, production"
        echo "Estratégias: rolling (padrão), blue-green, canary"
        echo ""
        echo "Exemplos:"
        echo "  $0 development"
        echo "  $0 staging blue-green"
        echo "  $0 production canary"
        exit 1
    fi

    # Executar validações
    validate_environment

    # Preparar deploy
    prepare_deploy

    # Executar deploy baseado na estratégia
    case "$DEPLOY_STRATEGY" in
        "rolling")
            deploy_rolling
            ;;
        "blue-green")
            deploy_blue_green
            ;;
        "canary")
            deploy_canary
            ;;
        *)
            error "Estratégia '${DEPLOY_STRATEGY}' não suportada"
            ;;
    esac

    # Pós-deploy
    post_deploy

    # Limpeza
    log "Limpando arquivos temporários..."
    rm -rf "$DEPLOY_TMP_DIR"

    success "Deploy concluído com sucesso!"
    info "Ambiente: ${ENVIRONMENT}"
    info "Estratégia: ${DEPLOY_STRATEGY}"
    info "Data/Hora: $(date)"
}

# Executar
main "$@"
