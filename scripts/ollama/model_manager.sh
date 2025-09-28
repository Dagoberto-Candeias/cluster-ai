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

# Load common functions (consolidated library)
if [ -f "${PROJECT_ROOT}/scripts/utils/common_functions.sh" ]; then
    # shellcheck source=../utils/common_functions.sh
    source "${PROJECT_ROOT}/scripts/utils/common_functions.sh"
else
    echo "CRITICAL ERROR: Common functions script not found at scripts/utils/common_functions.sh"
    exit 1
fi

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

# Monitor model performance metrics
monitor_performance() {
    local model="$1"
    log_model "INFO" "Monitoring performance for model: $model"

    if ! check_ollama; then
        error "Ollama is not available"
        return 1
    fi

    # Check if model exists
    if ! ollama list | grep -q "^$model"; then
        error "Model $model not found"
        return 1
    fi

    echo -e "${BOLD}${BLUE}PERFORMANCE MONITORING: $model${NC}"
    echo -e "${BLUE}$(printf '%.0s=' {1..50})${NC}"

    # Measure load time
    local start_time end_time load_time
    start_time=$(date +%s.%3N)
    if ollama show "$model" >/dev/null 2>&1; then
        end_time=$(date +%s.%3N)
        load_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "N/A")
        echo -e "${CYAN}Load time:${NC} ${load_time}s"
    else
        echo -e "${RED}Load time:${NC} Failed to load"
        return 1
    fi

    # Get model info
    local model_info
    model_info=$(ollama show "$model" 2>/dev/null)

    # Extract parameters
    local parameters
    parameters=$(echo "$model_info" | grep "parameters:" | sed 's/.*parameters: //' || echo "Unknown")
    echo -e "${CYAN}Parameters:${NC} $parameters"

    # Estimate memory usage (rough calculation)
    local mem_estimate="Unknown"
    case "$parameters" in
        *7b*) mem_estimate="~4-8GB" ;;
        *13b*) mem_estimate="~8-16GB" ;;
        *30b*) mem_estimate="~16-32GB" ;;
        *65b*) mem_estimate="~32-64GB" ;;
        *8b*) mem_estimate="~4-8GB" ;;
        *3b*) mem_estimate="~2-4GB" ;;
    esac
    echo -e "${CYAN}Estimated memory usage:${NC} $mem_estimate"

    # Log performance data
    log_model "INFO" "Performance data for $model - Load time: ${load_time}s, Memory: $mem_estimate"
}

# Auto cleanup based on usage thresholds
auto_cleanup() {
    local max_models="${1:-10}"
    local max_disk_percent="${2:-80}"
    log_model "INFO" "Running auto cleanup - Max models: $max_models, Max disk: ${max_disk_percent}%"

    if ! check_ollama; then
        error "Ollama is not available"
        return 1
    fi

    local installed_models
    installed_models=$(get_installed_models)
    local model_count=$(echo "$installed_models" | wc -l)

    # Check model count
    if [ "$model_count" -gt "$max_models" ]; then
        warn "Too many models installed ($model_count > $max_models)"
        log_model "WARN" "Auto cleanup triggered: too many models ($model_count > $max_models)"

        # Remove oldest models (simplified - remove non-essential models)
        local essential_models=(
            "llama3:8b"
            "mistral:7b"
            "gemma:2b"
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

        # Remove excess models
        local excess=$((model_count - max_models))
        if [ "${#to_remove[@]}" -gt "$excess" ]; then
            for ((i=0; i<excess; i++)); do
                local model="${to_remove[$i]}"
                log_model "INFO" "Auto removing model: $model"
                if ollama rm "$model" >> "$MODEL_LOG" 2>&1; then
                    success "Auto removed: $model"
                else
                    error "Failed to auto remove: $model"
                fi
            done
        fi
    fi

    # Check disk usage
    local disk_usage
    disk_usage=$(df "$OLLAMA_MODELS_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')

    if [ "$disk_usage" -gt "$max_disk_percent" ]; then
        warn "Disk usage too high (${disk_usage}% > ${max_disk_percent}%)"
        log_model "WARN" "Auto cleanup triggered: high disk usage (${disk_usage}%)"

        # Force cleanup of largest models
        local large_models
        large_models=$(get_model_sizes | sort -k2 -hr | head -3 | awk '{print $1}')

        for model in $large_models; do
            local is_essential=false
            for essential in "${essential_models[@]}"; do
                if [[ "$model" == "$essential" ]]; then
                    is_essential=true
                    break
                fi
            done

            if [[ "$is_essential" == "false" ]]; then
                log_model "INFO" "Auto removing large model: $model"
                if ollama rm "$model" >> "$MODEL_LOG" 2>&1; then
                    success "Auto removed large model: $model"
                fi
                break  # Remove only one large model
            fi
        done
    fi
}

# Verify model integrity
verify_integrity() {
    local model="$1"
    log_model "INFO" "Verifying integrity of model: $model"

    if ! check_ollama; then
        error "Ollama is not available"
        return 1
    fi

    # Check if model exists
    if ! ollama list | grep -q "^$model"; then
        error "Model $model not found"
        return 1
    fi

    # Try to load model
    if timeout 30 ollama show "$model" >/dev/null 2>&1; then
        success "Model $model integrity OK"
        log_model "INFO" "Model integrity verified: $model"
        return 0
    else
        error "Model $model integrity check failed"
        log_model "ERROR" "Model integrity check failed: $model"
        return 1
    fi
}

# Batch verify all models
verify_all_models() {
    log_model "INFO" "Verifying integrity of all models"

    if ! check_ollama; then
        error "Ollama is not available"
        return 1
    fi

    local models
    models=$(get_installed_models)

    if [[ -z "$models" ]]; then
        warn "No models to verify"
        return 0
    fi

    local failed_models=()

    echo -e "${BOLD}${BLUE}VERIFYING MODEL INTEGRITY${NC}"
    echo -e "${BLUE}$(printf '%.0s=' {1..50})${NC}"

    for model in $models; do
        echo -n "Checking $model... "
        if verify_integrity "$model" >/dev/null 2>&1; then
            echo -e "${GREEN}OK${NC}"
        else
            echo -e "${RED}FAILED${NC}"
            failed_models+=("$model")
        fi
    done

    if [ ${#failed_models[@]} -gt 0 ]; then
        warn "Failed models: ${failed_models[*]}"
        log_model "WARN" "Integrity check failed for models: ${failed_models[*]}"
        return 1
    else
        success "All models verified successfully"
        log_model "INFO" "All models integrity verified"
        return 0
    fi
}

# Benchmark model performance
benchmark_model() {
    local model="$1"
    local prompt="${2:-"Explain quantum computing in simple terms"}"
    log_model "INFO" "Benchmarking model: $model"

    if ! check_ollama; then
        error "Ollama is not available"
        return 1
    fi

    # Check if model exists
    if ! ollama list | grep -q "^$model"; then
        error "Model $model not found"
        return 1
    fi

    echo -e "${BOLD}${BLUE}BENCHMARKING: $model${NC}"
    echo -e "${BLUE}$(printf '%.0s=' {1..50})${NC}"

    # Measure inference time
    local start_time end_time inference_time tokens_per_sec
    start_time=$(date +%s.%3N)

    local response
    response=$(echo "{\"model\": \"$model\", \"prompt\": \"$prompt\", \"stream\": false}" | \
               curl -s -X POST "http://127.0.0.1:11434/api/generate" \
                    -H "Content-Type: application/json" \
                    -d @-)

    end_time=$(date +%s.%3N)
    inference_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "0")

    if [[ -z "$response" ]]; then
        error "Failed to get response from model"
        return 1
    fi

    # Extract response text and token count
    local response_text token_count
    response_text=$(echo "$response" | jq -r '.response // empty' 2>/dev/null || echo "$response")
    token_count=$(echo "$response_text" | wc -w)

    if [[ "$inference_time" != "0" && "$token_count" -gt 0 ]]; then
        tokens_per_sec=$(echo "scale=2; $token_count / $inference_time" | bc 2>/dev/null || echo "N/A")
    else
        tokens_per_sec="N/A"
    fi

    echo -e "${CYAN}Prompt:${NC} $prompt"
    echo -e "${CYAN}Inference time:${NC} ${inference_time}s"
    echo -e "${CYAN}Tokens generated:${NC} $token_count"
    echo -e "${CYAN}Tokens/second:${NC} $tokens_per_sec"

    # Quality assessment (basic)
    local quality_score="N/A"
    if [[ ${#response_text} -gt 50 ]]; then
        quality_score="Good"
    elif [[ ${#response_text} -gt 20 ]]; then
        quality_score="Fair"
    else
        quality_score="Poor"
    fi
    echo -e "${CYAN}Quality assessment:${NC} $quality_score"

    # Log benchmark data
    log_model "INFO" "Benchmark $model - Time: ${inference_time}s, Tokens: $token_count, Speed: $tokens_per_sec tok/s"

    # Return benchmark data as JSON for scripting
    echo "{\"model\":\"$model\",\"time\":$inference_time,\"tokens\":$token_count,\"speed\":\"$tokens_per_sec\",\"quality\":\"$quality_score\"}"
}

# Auto-select best model for task
auto_select_model() {
    local task_type="$1"
    log_model "INFO" "Auto-selecting model for task: $task_type"

    if ! check_ollama; then
        error "Ollama is not available"
        return 1
    fi

    local installed_models
    installed_models=$(get_installed_models)

    if [[ -z "$installed_models" ]]; then
        error "No models installed"
        return 1
    fi

    # Define model preferences by task type
    local preferred_models=()
    case "$task_type" in
        "coding"|"programming")
            preferred_models=("codellama:7b" "deepseek-coder:6.7b" "llama3:8b" "starcoder:7b")
            ;;
        "creative"|"writing")
            preferred_models=("llama3:8b" "mistral:7b" "nous-hermes:13b")
            ;;
        "analysis"|"research")
            preferred_models=("nous-hermes:13b" "llama3:8b" "mixtral:8x7b" "mistral:7b")
            ;;
        "chat"|"general")
            preferred_models=("llama3:8b" "mistral:7b" "gemma:7b")
            ;;
        "compact"|"fast")
            preferred_models=("phi3:3.8b" "gemma:2b" "llama3:1b")
            ;;
        "vision"|"multimodal")
            preferred_models=("llava:7b" "bakllava:7b" "moondream:1.8b")
            ;;
        *)
            error "Unknown task type: $task_type"
            echo "Available task types: coding, creative, analysis, chat, compact, vision"
            return 1
            ;;
    esac

    # Find best available model
    local selected_model=""
    for preferred in "${preferred_models[@]}"; do
        if echo "$installed_models" | grep -q "^$preferred$"; then
            selected_model="$preferred"
            break
        fi
    done

    if [[ -z "$selected_model" ]]; then
        # Fallback to first available model
        selected_model=$(echo "$installed_models" | head -1)
        warn "No preferred model found for $task_type, using: $selected_model"
    fi

    success "Selected model for $task_type: $selected_model"
    log_model "INFO" "Auto-selected model: $selected_model for task: $task_type"

    echo "$selected_model"
}

# Compare models performance
compare_models() {
    local models_list="$1"
    local prompt="${2:-"Hello, how are you?"}"
    log_model "INFO" "Comparing models: $models_list"

    if ! check_ollama; then
        error "Ollama is not available"
        return 1
    fi

    echo -e "${BOLD}${BLUE}MODEL COMPARISON${NC}"
    echo -e "${BLUE}$(printf '%.0s=' {1..60})${NC}"
    echo -e "${BOLD}Prompt:${NC} $prompt"
    echo ""

    local results=()
    local best_model=""
    local best_speed="0"

    # Benchmark each model
    for model in $models_list; do
        if ollama list | grep -q "^$model"; then
            echo -e "${CYAN}Testing $model...${NC}"

            local benchmark_data
            benchmark_data=$(benchmark_model "$model" "$prompt")

            if [[ $? -eq 0 ]]; then
                local time speed quality
                time=$(echo "$benchmark_data" | jq -r '.time // 0' 2>/dev/null || echo "0")
                speed=$(echo "$benchmark_data" | jq -r '.speed // "0"' 2>/dev/null || echo "0")
                quality=$(echo "$benchmark_data" | jq -r '.quality // "Unknown"' 2>/dev/null || echo "Unknown")

                # Convert speed to number for comparison
                local speed_num
                speed_num=$(echo "$speed" | sed 's/[^0-9.]//g' | head -1)

                if [[ $(echo "$speed_num > $best_speed" | bc 2>/dev/null) -eq 1 ]]; then
                    best_speed="$speed_num"
                    best_model="$model"
                fi

                results+=("$model|$time|$speed|$quality")
                echo ""
            else
                error "Failed to benchmark $model"
            fi
        else
            warn "Model $model not installed"
        fi
    done

    # Display comparison table
    echo -e "${BOLD}COMPARISON RESULTS${NC}"
    echo -e "${YELLOW}$(printf '%.0s-' {1..60})${NC}"
    printf "${BOLD}%-20s %-10s %-12s %-10s${NC}\n" "Model" "Time(s)" "Speed(tok/s)" "Quality"
    echo -e "${YELLOW}$(printf '%.0s-' {1..60})${NC}"

    for result in "${results[@]}"; do
        IFS='|' read -r model time speed quality <<< "$result"
        printf "%-20s %-10s %-12s %-10s\n" "$model" "$time" "$speed" "$quality"
    done

    echo ""
    if [[ -n "$best_model" ]]; then
        success "Fastest model: $best_model (${best_speed} tok/s)"
        log_model "INFO" "Comparison completed - Best model: $best_model"
    fi
}

# Health check for models
health_check() {
    log_model "INFO" "Running model health check"

    if ! check_ollama; then
        error "Ollama is not available"
        return 1
    fi

    local models
    models=$(get_installed_models)

    if [[ -z "$models" ]]; then
        warn "No models installed"
        return 0
    fi

    echo -e "${BOLD}${BLUE}MODEL HEALTH CHECK${NC}"
    echo -e "${BLUE}$(printf '%.0s=' {1..50})${NC}"

    local healthy=0
    local unhealthy=0

    for model in $models; do
        echo -n "Checking $model... "

        # Quick health check - try to get model info
        if timeout 10 ollama show "$model" >/dev/null 2>&1; then
            echo -e "${GREEN}HEALTHY${NC}"
            ((healthy++))
        else
            echo -e "${RED}UNHEALTHY${NC}"
            ((unhealthy++))
            log_model "WARN" "Unhealthy model detected: $model"
        fi
    done

    echo ""
    echo -e "${BOLD}Summary:${NC}"
    echo -e "  Healthy models: $healthy"
    echo -e "  Unhealthy models: $unhealthy"

    if [[ $unhealthy -gt 0 ]]; then
        warn "$unhealthy unhealthy model(s) found"
        log_model "WARN" "Health check found $unhealthy unhealthy models"
        return 1
    else
        success "All models are healthy"
        log_model "INFO" "Health check passed - all models healthy"
        return 0
    fi
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
        "monitor")
            if [ -n "${2:-}" ]; then
                monitor_performance "$2"
            else
                error "Usage: $0 monitor <model_name>"
                exit 1
            fi ;;
        "benchmark")
            if [ -n "${2:-}" ]; then
                benchmark_model "$2" "${3:-}"
            else
                error "Usage: $0 benchmark <model_name> [prompt]"
                exit 1
            fi ;;
        "auto-select")
            if [ -n "${2:-}" ]; then
                auto_select_model "$2"
            else
                error "Usage: $0 auto-select <task_type>"
                echo "Task types: coding, creative, analysis, chat, compact, vision"
                exit 1
            fi ;;
        "compare")
            if [ -n "${2:-}" ]; then
                compare_models "$2" "${3:-}"
            else
                error "Usage: $0 compare \"model1 model2 model3\" [prompt]"
                exit 1
            fi ;;
        "health")
            health_check ;;
        "auto-cleanup")
            auto_cleanup "${2:-10}" "${3:-80}" ;;
        "verify")
            if [ -n "${2:-}" ]; then
                verify_integrity "$2"
            else
                verify_all_models
            fi ;;
        "help"|*)
            echo "Cluster AI - Ollama Model Manager"
            echo ""
            echo "Usage: $0 [action] [options]"
            echo ""
            echo "Actions:"
            echo "  list         - List all installed models"
            echo "  cleanup      - Remove unused models"
            echo "  optimize     - Optimize storage usage"
            echo "  stats        - Show model statistics"
            echo "  monitor <model> - Monitor performance of specific model"
            echo "  benchmark <model> [prompt] - Benchmark model performance"
            echo "  auto-select <task> - Auto-select best model for task"
            echo "  compare \"models\" [prompt] - Compare multiple models"
            echo "  health       - Run health check on all models"
            echo "  auto-cleanup [max_models] [max_disk%] - Auto cleanup based on thresholds"
            echo "  verify [model] - Verify model integrity (all models if no model specified)"
            echo "  help         - Show this help"
            echo ""
            echo "Task Types for auto-select:"
            echo "  coding, creative, analysis, chat, compact, vision"
            echo ""
            echo "Examples:"
            echo "  $0 list"
            echo "  $0 benchmark llama3:8b"
            echo "  $0 auto-select coding"
            echo "  $0 compare \"llama3:8b mistral:7b\""
            echo "  $0 health"
            echo "  $0 auto-cleanup 5 70"
            echo "  $0 verify llama3:8b"
            ;;
    esac
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
