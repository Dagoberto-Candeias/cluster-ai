#!/bin/bash
# =============================================================================
# Gerenciador Avançado de Modelos Ollama
# =============================================================================
# Recursos: Cache inteligente, limpeza automática, monitoramento de uso
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: model_manager.sh
# =============================================================================

set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Load common functions
if [ ! -f "${PROJECT_ROOT}/scripts/lib/common.sh" ]; then
    echo "CRITICAL ERROR: Common functions script not found."
    exit 1
fi
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# --- Constants ---
LOG_DIR="${PROJECT_ROOT}/logs"
MODEL_LOG="${LOG_DIR}/model_manager.log"
OLLAMA_MODELS_DIR="${HOME}/.ollama/models"

# Create necessary directories
mkdir -p "$LOG_DIR"

# --- Functions ---

# Enhanced logging function
log_model() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" >> "$MODEL_LOG"

    case "$level" in
        "INFO") info "$message" ;;
        "WARN") warn "$message" ;;
        "ERROR") error "$message" ;;
        "SUCCESS") success "$message" ;;
    esac
}

# Check if Ollama is running
check_ollama() {
    if ! curl -s "http://127.0.0.1:11434/api/tags" >/dev/null 2>&1; then
        log_model "ERROR" "Ollama is not responding on port 11434"
        return 1
    fi
    return 0
}

# Get list of installed models
get_installed_models() {
    ollama list 2>/dev/null | awk 'NR>1 {print $1}' | sort || echo ""
}

# Get model sizes
get_model_sizes() {
    ollama list 2>/dev/null | awk 'NR>1 {print $1, $2}' || echo ""
}

# List all models with details
list_models() {
    log_model "INFO" "Listing all installed models..."

    if ! check_ollama; then
        error "Ollama is not available"
        return 1
    fi

    local models
    models=$(ollama list 2>/dev/null)

    if [[ -z "$models" ]]; then
        warn "No models installed"
        return 1
    fi

    echo -e "${BOLD}${BLUE}INSTALLED OLLAMA MODELS${NC}"
    echo -e "${BLUE}$(printf '%.0s=' {1..50})${NC}"
    echo "$models" | while IFS= read -r line; do
        echo "  $line"
    done

    local count=$(echo "$models" | wc -l)
    log_model "INFO" "Total models: $((count - 1))"
}

# Clean up unused models
cleanup_models() {
    log_model "INFO" "Cleaning up unused models..."

    if ! check_ollama; then
        error "Ollama is not available"
        return 1
    fi

    local installed_models
    installed_models=$(get_installed_models)

    if [[ -z "$installed_models" ]]; then
        warn "No models to clean up"
        return 0
    fi

    local essential_models=(
        "llama3:8b"
        "mistral:7b"
        "gemma:2b"
        "codellama:7b"
    )

    local to_remove=()

    for model in $installed_models; do
        local is_essential=false
        for essential in "${essential_models[@]}"; do
            if [[ "$model" == "$essential" ]]; then
                is_essential=true
                break
            fi
        done

        if [[ "$is_essential" == "false" ]]; then
            to_remove+=("$model")
        fi
    done

    if [[ ${#to_remove[@]} -eq 0 ]]; then
        info "No models to remove"
        return 0
    fi

    echo -e "${BOLD}${YELLOW}MODELS TO REMOVE${NC}"
    for model in "${to_remove[@]}"; do
        echo "  - $model"
    done

    if confirm_operation "Remove these models?"; then
        for model in "${to_remove[@]}"; do
            log_model "INFO" "Removing model: $model"
            if ollama rm "$model" >> "$MODEL_LOG" 2>&1; then
                success "Removed: $model"
            else
                error "Failed to remove: $model"
            fi
        done
    else
        info "Cleanup cancelled"
    fi
}

# Optimize model storage
optimize_storage() {
    log_model "INFO" "Optimizing model storage..."

    if ! check_ollama; then
        error "Ollama is not available"
        return 1
    fi

    # Get disk usage
    local usage
    usage=$(du -sh "$OLLAMA_MODELS_DIR" 2>/dev/null | cut -f1 || echo "Unknown")

    log_model "INFO" "Current model storage usage: $usage"

    # Suggest optimizations
    info "Optimization suggestions:"
    echo "  - Remove unused models with 'cleanup' command"
    echo "  - Use smaller model variants when possible"
    echo "  - Consider model quantization for reduced size"

    # Check for duplicate models
    local models
    models=$(get_installed_models)
    local duplicates=$(echo "$models" | sort | uniq -d)

    if [[ -n "$duplicates" ]]; then
        warn "Duplicate models found:"
        echo "$duplicates" | while read -r dup; do
            echo "  - $dup"
        done
    fi
}

# Show model usage statistics
show_stats() {
    log_model "INFO" "Showing model statistics..."

    if ! check_ollama; then
        error "Ollama is not available"
        return 1
    fi

    local models
    models=$(get_model_sizes)

    if [[ -z "$models" ]]; then
        warn "No models installed"
        return 1
    fi

    echo -e "${BOLD}${BLUE}MODEL STATISTICS${NC}"
    echo -e "${BLUE}$(printf '%.0s=' {1..50})${NC}"

    local total_size=0
    echo "$models" | while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local model size
            model=$(echo "$line" | awk '{print $1}')
            size=$(echo "$line" | awk '{print $2}')

            echo -e "  ${CYAN}$model${NC}: $size"

            # Convert size to bytes for total (simplified)
            case "$size" in
                *GB) total_size=$((total_size + $(echo "$size" | sed 's/GB//') * 1024 * 1024 * 1024)) ;;
                *MB) total_size=$((total_size + $(echo "$size" | sed 's/MB//') * 1024 * 1024)) ;;
                *KB) total_size=$((total_size + $(echo "$size" | sed 's/KB//') * 1024)) ;;
            esac
        fi
    done

    echo
    echo -e "${BOLD}Total models:${NC} $(echo "$models" | wc -l)"
    echo -e "${BOLD}Estimated total size:${NC} $((total_size / 1024 / 1024 / 1024)) GB"
}

# Main function
main() {
    cd "$PROJECT_ROOT"

    # Create log directory
    mkdir -p "$LOG_DIR"
    touch "$MODEL_LOG"

    local action="${1:-help}"

    case "$action" in
        "list")
            list_models ;;
        "cleanup")
            cleanup_models ;;
        "optimize")
            optimize_storage ;;
        "stats")
            show_stats ;;
        "help"|*)
            echo "Cluster AI - Ollama Model Manager"
            echo ""
            echo "Usage: $0 [action]"
            echo ""
            echo "Actions:"
            echo "  list     - List all installed models"
            echo "  cleanup  - Remove unused models"
            echo "  optimize - Optimize storage usage"
            echo "  stats    - Show model statistics"
            echo "  help     - Show this help"
            echo ""
            echo "Examples:"
            echo "  $0 list"
            echo "  $0 cleanup"
            ;;
    esac
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
