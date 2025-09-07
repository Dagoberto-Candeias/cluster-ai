#!/bin/bash
#
# Script para baixar modelos do Ollama
# Downloads automáticos desabilitados por padrão
# Use --interactive para modo interativo com modelos futuros
# Use --scheduled para downloads agendados (00:00-07:00)
#

set -euo pipefail

# Carregar funções comuns
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# Verificar modo interativo e agendado
INTERACTIVE=false
SCHEDULED=false
if [[ "${1:-}" == "--interactive" ]]; then
    INTERACTIVE=true
elif [[ "${1:-}" == "--scheduled" ]]; then
    SCHEDULED=true
fi

# Verificação de horário: só executa entre 00:00 e 07:00 (apenas no modo agendado)
if $SCHEDULED; then
    CURRENT_HOUR=$(date +%H)
    if [ "$CURRENT_HOUR" -lt 0 ] || [ "$CURRENT_HOUR" -gt 7 ]; then
        log "Fora do horário de execução agendada (00:00-07:00). Horário atual: $(date)"
        exit 0
    fi
fi

# Lista de modelos para download automático (baseado em install_models.sh)
AUTO_MODELS=(
    "phi-2:2.7b"
    "gemma:2b"
    "llama3:8b"
    "mistral:7b"
    "qwen:1.8b"
    "orca-mini:3b"
    "codellama:7b"
    "deepseek-coder:6.7b"
    "starcoder:3b"
    "llama3:70b"
    "mixtral:8x7b"
    "yi:34b"
    "llava:7b"
    "bakllava:7b"
    "qwen:72b"
    "bloom:7b"
    "tinyllama:1.1b"
)

# Lista de modelos para download futuro (opcionais)
FUTURE_MODELS=(
    "llama3.1:8b"
    "llama3.2"
    "phi3"
    "phi4"
    "gemma2:9b"
    "qwen3"
    "deepseek-chat"
    "deepseek-coder-v2:16b"
    "codellama-7b"
    "starcoder2:7b"
    "qwen2.5-coder:1.5b"
    "deepseek-coder"
    "qwen2-vl"
    "minicpm-v"
    "codegemma"
    "nomic-embed-text"
    "text-embedding-3-small"
    "gemma-embed"
    "mistral-embed"
)

main() {
    section "🤖 Download Automático de Modelos Ollama"

    if ! command_exists ollama; then
        error "Ollama não está instalado."
        exit 1
    fi

    log "Verificando serviço Ollama..."
    if ! pgrep -f "ollama serve" > /dev/null && ! sudo systemctl is-active --quiet ollama 2>/dev/null; then
        warn "Ollama não está ativo. Iniciando..."
        bash "${PROJECT_ROOT}/manager.sh" start
        sleep 5
    fi

    # Obter lista de modelos instalados
    installed_models=$(ollama list | awk 'NR>1 {print $1}')

    section "📋 Verificando Modelos Faltantes"

    models_to_download=()
    for model in "${AUTO_MODELS[@]}"; do
        if ! echo "$installed_models" | grep -q "^${model}"; then
            models_to_download+=("$model")
        fi
    done

    if [ ${#models_to_download[@]} -eq 0 ]; then
        info "Todos os modelos da lista automática já estão instalados."
    else
        info "Modelos a serem baixados: ${models_to_download[*]}"
    fi

    # Verificar se deve baixar automaticamente
    if ! $INTERACTIVE && ! $SCHEDULED; then
        if [ ${#models_to_download[@]} -gt 0 ]; then
            info "Downloads automáticos desabilitados. Use --interactive para modo interativo ou --scheduled para agendamento."
        fi
        # Ainda salva a lista de modelos futuros
        future_list_file="${PROJECT_ROOT}/scripts/ollama/future_models.txt"
        echo "# Lista de modelos para download futuro (opcionais)" > "$future_list_file"
        echo "# Execute manualmente: ollama pull <modelo>" >> "$future_list_file"
        echo "" >> "$future_list_file"
        for model in "${FUTURE_MODELS[@]}"; do
            echo "$model" >> "$future_list_file"
        done
        info "Lista de modelos futuros salva em: $future_list_file"
        exit 0
    fi

    if [ ${#models_to_download[@]} -eq 0 ]; then
        info "Todos os modelos da lista automática já estão instalados."
        exit 0
    fi

    section "🚀 Iniciando Downloads"

    for model in "${models_to_download[@]}"; do
        subsection "Baixando: $model"
        if ollama pull "$model"; then
            success "Modelo $model baixado com sucesso!"
        else
            error "Falha ao baixar $model"
        fi
    done

    section "✅ Downloads Automáticos Concluídos"

    # Função para categorizar modelos instalados
    categorize_installed_models() {
        local installed_models="$1"

        # Mapeamento de categorias
        declare -A model_categories=(
            ["phi-2:2.7b"]="🗣️ Conversação"
            ["gemma:2b"]="🗣️ Conversação"
            ["llama3:8b"]="🗣️ Conversação"
            ["mistral:7b"]="🗣️ Conversação"
            ["qwen:1.8b"]="🗣️ Conversação"
            ["orca-mini:3b"]="🗣️ Conversação"
            ["codellama:7b"]="💻 Programação"
            ["deepseek-coder:6.7b"]="💻 Programação"
            ["starcoder:3b"]="💻 Programação"
            ["llama3:70b"]="📊 Análise"
            ["mixtral:8x7b"]="📊 Análise"
            ["yi:34b"]="📊 Análise"
            ["llava:7b"]="🎨 Criativo"
            ["bakllava:7b"]="🎨 Criativo"
            ["qwen:72b"]="🌍 Multilíngue"
            ["bloom:7b"]="🌍 Multilíngue"
            ["tinyllama:1.1b"]="🧪 Leve"
        )

        echo "📋 Modelos Instalados (Categorizados):"
        echo "====================================="

        local current_category=""
        local has_models=false

        for model in $installed_models; do
            local category="${model_categories[$model]:-Outros}"
            if [[ "$category" != "$current_category" ]]; then
                if [[ -n "$current_category" ]]; then
                    echo ""
                fi
                echo -e "\n${YELLOW}$category${NC}"
                echo "─────────────────────────────"
                current_category="$category"
                has_models=true
            fi
            echo "  ✅ $model"
        done

        if ! $has_models; then
            echo "  Nenhum modelo categorizado encontrado."
        fi
        echo ""
    }

    # Obter lista atualizada de modelos instalados
    updated_installed_models=$(ollama list | awk 'NR>1 {print $1}')

    # Categorizar e mostrar modelos instalados
    categorize_installed_models "$updated_installed_models"

    # Modo interativo para modelos futuros
    if $INTERACTIVE; then
        section "🔮 Modelos Futuros (Opcionais)"

        # Salvar lista de modelos futuros em um arquivo
        future_list_file="${PROJECT_ROOT}/scripts/ollama/future_models.txt"
        echo "# Lista de modelos para download futuro (opcionais)" > "$future_list_file"
        echo "# Execute manualmente: ollama pull <modelo>" >> "$future_list_file"
        echo "" >> "$future_list_file"
        for model in "${FUTURE_MODELS[@]}"; do
            echo "$model" >> "$future_list_file"
        done

        info "Lista de modelos futuros salva em: $future_list_file"
        echo ""
        info "Modelos disponíveis para download futuro:"
        for i in "${!FUTURE_MODELS[@]}"; do
            model="${FUTURE_MODELS[$i]}"
            if echo "$installed_models" | grep -q "^${model}"; then
                echo "  [$((i+1))] $model (já instalado)"
            else
                echo "  [$((i+1))] $model"
            fi
        done

        echo ""
        read -p "Deseja baixar algum modelo futuro agora? Digite o número ou 'n' para não: " choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#FUTURE_MODELS[@]} ]; then
            selected_model="${FUTURE_MODELS[$((choice-1))]}"
            if echo "$installed_models" | grep -q "^${selected_model}"; then
                info "Modelo $selected_model já está instalado."
            else
                subsection "Baixando modelo futuro: $selected_model"
                if ollama pull "$selected_model"; then
                    success "Modelo $selected_model baixado com sucesso!"
                else
                    error "Falha ao baixar $selected_model"
                fi
            fi
        elif [[ "$choice" == "n" || "$choice" == "N" ]]; then
            info "Nenhum modelo futuro selecionado."
        else
            warn "Opção inválida."
        fi
    else
        # Salvar lista de modelos futuros em um arquivo (modo automático)
        future_list_file="${PROJECT_ROOT}/scripts/ollama/future_models.txt"
        echo "# Lista de modelos para download futuro (opcionais)" > "$future_list_file"
        echo "# Execute manualmente: ollama pull <modelo>" >> "$future_list_file"
        echo "" >> "$future_list_file"
        for model in "${FUTURE_MODELS[@]}"; do
            echo "$model" >> "$future_list_file"
        done

        info "Lista de modelos futuros salva em: $future_list_file"
    fi
}

main "$@"
