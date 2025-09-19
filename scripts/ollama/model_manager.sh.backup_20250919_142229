#!/bin/bash
#
# Gerenciador Avançado de Modelos Ollama
# Recursos: Cache inteligente, limpeza automática, monitoramento de uso
#

set -euo pipefail

# Carregar funções comuns
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# Configurações
CACHE_DIR="${PROJECT_ROOT}/cache/models"
METRICS_DIR="${PROJECT_ROOT}/metrics/models"
LOG_FILE="${PROJECT_ROOT}/logs/model_manager.log"

# Criar diretórios necessários
mkdir -p "$CACHE_DIR" "$METRICS_DIR"

# Função de logging específica para o gerenciador
log_model() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
    echo -e "${BLUE}[MODEL_MANAGER]${NC} $message"
}

# Função para obter métricas de uso de modelos
get_model_metrics() {
    local model="$1"
    local metrics_file="$METRICS_DIR/${model//\//_}.json"

    if [[ -f "$metrics_file" ]]; then
        cat "$metrics_file"
    else
        echo "{}"
    fi
}

# Função para atualizar métricas de uso
update_model_metrics() {
    local model="$1"
    local action="$2"
    local metrics_file="$METRICS_DIR/${model//\//_}.json"

    # Obter métricas atuais
    local current_metrics
    current_metrics=$(get_model_metrics "$model")

    # Atualizar contadores
    local usage_count=1
    local last_used
    last_used=$(date +%s)

    if [[ -f "$metrics_file" ]]; then
        usage_count=$(( $(jq -r '.usage_count // 0' <<< "$current_metrics") + 1 ))
    fi

    # Criar/atualizar arquivo de métricas
    jq -n \
        --arg model "$model" \
        --arg action "$action" \
        --argjson usage_count "$usage_count" \
        --argjson last_used "$last_used" \
        '{
            model: $model,
            usage_count: $usage_count,
            last_used: $last_used,
            last_action: $action,
            first_seen: (.first_seen // now),
            size_mb: (.size_mb // 0)
        }' > "$metrics_file"

    log_model "INFO" "Métricas atualizadas para $model (uso: $usage_count)"
}

# Função para listar modelos com métricas
list_models_with_metrics() {
    section "📊 Modelos Instalados com Métricas"

    if ! command_exists ollama; then
        error "Ollama não está instalado."
        return 1
    fi

    local installed_models
    installed_models=$(ollama list | awk 'NR>1 {print $1}')

    if [[ -z "$installed_models" ]]; then
        info "Nenhum modelo instalado."
        return 0
    fi

    printf "%-25s %-10s %-15s %-20s\n" "MODELO" "USO" "ÚLTIMO USO" "TAMANHO"
    echo "────────────────────────────────────────────────────────────────"

    for model in $installed_models; do
        local metrics_file="$METRICS_DIR/${model//\//_}.json"

        if [[ -f "$metrics_file" ]]; then
            local usage_count
            usage_count=$(jq -r '.usage_count // 0' "$metrics_file")

            local last_used
            last_used=$(jq -r '.last_used // 0' "$metrics_file")
            if [[ "$last_used" != "0" ]]; then
                last_used=$(date -d "@$last_used" '+%Y-%m-%d %H:%M')
            else
                last_used="Nunca"
            fi

            local size_mb
            size_mb=$(jq -r '.size_mb // "N/A"' "$metrics_file")
            if [[ "$size_mb" == "N/A" || "$size_mb" == "0" ]]; then
                size_mb="N/A"
            else
                size_mb="${size_mb}MB"
            fi
        else
            usage_count="0"
            last_used="Nunca"
            size_mb="N/A"
        fi

        printf "%-25s %-10s %-15s %-20s\n" "$model" "$usage_count" "$last_used" "$size_mb"
    done
}

# Função para limpeza inteligente de modelos não utilizados
cleanup_unused_models() {
    local days_threshold="${1:-30}"
    section "🧹 Limpeza Inteligente de Modelos"

    warn "Esta operação irá remover modelos não utilizados há mais de ${days_threshold} dias."
    read -p "Continuar? (s/N): " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        info "Operação cancelada."
        return 0
    fi

    local current_time
    current_time=$(date +%s)
    local threshold_seconds=$(( days_threshold * 24 * 60 * 60 ))

    local models_to_remove=()

    for metrics_file in "$METRICS_DIR"/*.json; do
        if [[ -f "$metrics_file" ]]; then
            local model_name
            model_name=$(basename "$metrics_file" .json)
            model_name=${model_name//_/\//}

            local last_used
            last_used=$(jq -r '.last_used // 0' "$metrics_file")

            if [[ "$last_used" != "0" ]]; then
                local days_unused=$(( (current_time - last_used) / (24 * 60 * 60) ))

                if [[ $days_unused -gt $days_threshold ]]; then
                    models_to_remove+=("$model_name")
                    log_model "INFO" "Modelo $model_name não usado há $days_unused dias - marcado para remoção"
                fi
            fi
        fi
    done

    if [[ ${#models_to_remove[@]} -eq 0 ]]; then
        info "Nenhum modelo encontrado para limpeza."
        return 0
    fi

    subsection "Modelos a serem removidos:"
    for model in "${models_to_remove[@]}"; do
        echo "  ❌ $model"
    done

    echo
    read -p "Confirmar remoção de ${#models_to_remove[@]} modelos? (s/N): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Ss]$ ]]; then
        for model in "${models_to_remove[@]}"; do
            subsection "Removendo: $model"
            if ollama rm "$model"; then
                success "Modelo $model removido com sucesso!"
                rm -f "$METRICS_DIR/${model//\//_}.json"
                log_model "INFO" "Modelo $model removido e métricas limpas"
            else
                error "Falha ao remover $model"
            fi
        done
    else
        info "Remoção cancelada."
    fi
}

# Função para cache inteligente de modelos
cache_model() {
    local model="$1"
    local cache_file="$CACHE_DIR/${model//\//_}.cache"

    subsection "Criando cache para: $model"

    # Verificar se modelo existe
    if ! ollama list | grep -q "^$model"; then
        error "Modelo $model não está instalado."
        return 1
    fi

    # Criar cache do modelo (simulação - em implementação real, isso copiaria arquivos)
    echo "Modelo: $model" > "$cache_file"
    echo "Criado em: $(date)" >> "$cache_file"
    echo "Tamanho aproximado: $(du -sh "$HOME/.ollama/models" | cut -f1)" >> "$cache_file"

    success "Cache criado para $model"
    log_model "INFO" "Cache criado para modelo $model"
}

# Função para otimizar uso de disco
optimize_disk_usage() {
    section "💾 Otimização de Uso de Disco"

    # Verificar espaço em disco
    local disk_usage
    disk_usage=$(df -h "$HOME" | awk 'NR==2 {print $5}')

    info "Uso atual de disco: $disk_usage"

    # Verificar tamanho dos modelos
    if [[ -d "$HOME/.ollama/models" ]]; then
        local models_size
        models_size=$(du -sh "$HOME/.ollama/models" | cut -f1)
        info "Espaço usado pelos modelos: $models_size"
    fi

    # Sugerir otimizações
    subsection "💡 Sugestões de Otimização:"
    echo "  1. Execute limpeza de modelos não utilizados: ./model_manager.sh cleanup"
    echo "  2. Use cache para modelos frequentemente utilizados"
    echo "  3. Considere mover modelos grandes para armazenamento externo"
    echo "  4. Configure limpeza automática mensal"

    log_model "INFO" "Otimizações de disco analisadas"
}

# Função principal
main() {
    local command="${1:-help}"

    case "$command" in
        "list")
            list_models_with_metrics
            ;;
        "cleanup")
            local days="${2:-30}"
            cleanup_unused_models "$days"
            ;;
        "cache")
            if [[ -z "${2:-}" ]]; then
                error "Uso: $0 cache <modelo>"
                exit 1
            fi
            cache_model "$2"
            ;;
        "optimize")
            optimize_disk_usage
            ;;
        "metrics")
            if [[ -z "${2:-}" ]]; then
                list_models_with_metrics
            else
                get_model_metrics "$2"
            fi
            ;;
        "help"|*)
            section "🤖 Gerenciador Avançado de Modelos Ollama"
            echo
            echo "Uso: $0 <comando> [opções]"
            echo
            echo "Comandos disponíveis:"
            echo "  list                    - Lista modelos com métricas de uso"
            echo "  cleanup [dias]         - Remove modelos não utilizados (padrão: 30 dias)"
            echo "  cache <modelo>         - Cria cache para modelo específico"
            echo "  optimize               - Analisa e sugere otimizações de disco"
            echo "  metrics [modelo]       - Mostra métricas de uso (todos ou específico)"
            echo "  help                   - Mostra esta ajuda"
            echo
            echo "Exemplos:"
            echo "  $0 list"
            echo "  $0 cleanup 60"
            echo "  $0 cache llama3:8b"
            echo "  $0 optimize"
            ;;
    esac
}

# Interceptar chamadas do Ollama para métricas
if [[ "${1:-}" == "ollama" ]]; then
    shift
    local model="$1"
    local action="run"

    # Executar comando original
    if ollama "$@"; then
        update_model_metrics "$model" "$action"
    fi
else
    main "$@"
fi
