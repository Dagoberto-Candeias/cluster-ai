#!/bin/bash
# Optimized Auto Worker Discovery Script
# Features: Parallel processing, memory monitoring, error handling

set -euo pipefail

# Configuration
MAX_RETRIES=3
TIMEOUT=30
PARALLEL_JOBS=4
MEMORY_THRESHOLD=80

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Memory monitoring function
check_memory() {
    local mem_usage
    mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ "$mem_usage" -gt "$MEMORY_THRESHOLD" ]; then
        warning "High memory usage: ${mem_usage}%"
        return 1
    fi
    return 0
}

# Optimized kubectl query with retry logic
kubectl_query() {
    local query="$1"
    local attempt=1

    while [ $attempt -le $MAX_RETRIES ]; do
        log "Attempt $attempt/$MAX_RETRIES: $query"

        if timeout "$TIMEOUT" kubectl "$query" 2>/dev/null; then
            return 0
        else
            warning "Query failed, retrying in 2 seconds..."
            sleep 2
            ((attempt++))
        fi
    done

    error "Query failed after $MAX_RETRIES attempts: $query"
    return 1
}

# Parallel worker discovery
discover_workers_parallel() {
    local namespaces=("default" "kube-system" "dask")

    log "🔍 Discovering workers in parallel across namespaces..."

    # Function to check namespace
    check_namespace() {
        local ns="$1"
        if kubectl get namespace "$ns" &>/dev/null; then
            log "Checking namespace: $ns"
            kubectl_query "get pods -n $ns -l app=dask,component=worker -o wide"
        fi
    }

    # Export function for parallel execution
    export -f kubectl_query log warning error check_namespace
    export MAX_RETRIES TIMEOUT PARALLEL_JOBS

    # Run in parallel with background jobs
    for ns in "${namespaces[@]}"; do
        check_namespace "$ns" &
    done
    wait

    success "Parallel worker discovery completed"
}

# Main discovery function
main() {
    log "🚀 Starting optimized worker discovery..."
    log "Descobrindo workers automaticamente..."

    # Check memory before starting
    if ! check_memory; then
        warning "High memory usage detected, but proceeding..."
    fi

    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        error "kubectl not found. Please install kubectl first."
        exit 1
    fi

    # Check cluster connectivity
    if ! kubectl cluster-info &>/dev/null; then
        error "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    # Discover workers
    discover_workers_parallel

    # Additional cluster information
    log "📊 Gathering cluster information..."
    echo ""
    echo "=== CLUSTER SUMMARY ==="
    kubectl_query "get nodes -o wide"
    echo ""
    kubectl_query "get pods --all-namespaces -l app=dask -o wide"

    # Memory check after completion
    if check_memory; then
        success "Memory usage within acceptable limits"
    fi

    success "Worker discovery completed successfully"
}

# Run main function
main "$@"
