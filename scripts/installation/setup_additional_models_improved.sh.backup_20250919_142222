#!/bin/bash
# Script melhorado para instalar modelos adicionais no Ollama para o Cluster AI
# Com categorização aprimorada e interface interativa

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/cluster.conf"
LOG_DIR="${PROJECT_ROOT}/logs"
MODEL_LOG="${LOG_DIR}/model_installation_$(date +%Y%m%d_%H%M%S).log"

# Carregar funções comuns
COMMON_SCRIPT_PATH="${PROJECT_ROOT}/scripts/utils/common.sh"
if [ -f "$COMMON_SCRIPT_PATH" ]; then
    source "$COMMON_SCRIPT_PATH"
else
    # Fallback para cores e logs se common.sh não for encontrado
    RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
    error() { echo -e "${RED}[ERROR]${NC} $1"; }
    warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
    log() { echo -e "${GREEN}[INFO]${NC} $1"; }
    success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
    section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
    confirm_operation() {
        read -p "$1 (s/N): " -n 1 -r; echo
        [[ $REPLY =~ ^[Ss]$ ]]
    }
fi

# Carregar configurações
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Configurações
OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"

# Lista de modelos a instalar com categorização aprimorada
declare -A MODELS=(
    # === MODELOS LEVES (1-3GB) ===
    ["llama3.2:1b"]="Modelo ultra-leve para dispositivos móveis e testes"
    ["llama3.2:3b"]="Modelo leve para tarefas gerais e chat"
    ["phi3:3.8b"]="Modelo compacto da Microsoft, ótimo para desenvolvimento"
    ["gemma:2b"]="Modelo leve do Google para tarefas básicas"

    # === MODELOS MÉDIOS (3-7GB) ===
    ["llama3.1:8b"]="Modelo balanceado para conversação avançada"
    ["mistral:7b"]="Modelo eficiente da Mistral AI, ótimo para código"
    ["llama3.2:7b"]="Versão intermediária da Meta, bom equilíbrio"
    ["qwen2:7b"]="Modelo multilíngue da Alibaba"

    # === MODELOS AVANÇADOS (7-15GB) ===
    ["llama3.1:70b"]="Modelo premium da Meta para tarefas complexas"
    ["codellama:13b"]="Especializado em geração e análise de código"
    ["mixtral:8x7b"]="Modelo MoE da Mistral, excelente para código"
    ["qwen2:72b"]="Modelo grande da Alibaba para tarefas avançadas"

    # === MODELOS ESPECIALIZADOS ===
    ["codellama:7b"]="Focado em geração de código Python/JavaScript"
    ["codellama:13b"]="Versão maior para projetos complexos"
    ["deepseek-coder:6.7b"]="Otimizado para desenvolvimento full-stack"
    ["starcoder2:7b"]="Especializado em múltiplas linguagens de programação"

    # === MODELOS MULTIMODAIS ===
    ["llava:7b"]="Processa texto + imagens, ideal para análise visual"
    ["llava:13b"]="Versão maior para análise de imagens complexas"
    ["bakllava:7b"]="Modelo multimodal da Mistral"
    ["moondream:1.8b"]="Modelo leve para análise de imagens"

    # === MODELOS PARA EMBEDDINGS ===
    ["nomic-embed-text"]="Para criação de embeddings de texto"
    ["mxbai-embed-large"]="Embeddings da MixedBread AI"
    ["snowflake-arctic-embed:335m"]="Modelo compacto para embeddings"
    ["text-embedding-3-small"]="Embeddings da OpenAI (compatível)"

    # === MODELOS EM PORTUGUÊS ===
    ["portuguese-llm:7b"]="Modelo treinado especificamente em português"
    ["bertimbau-large"]="Modelo BERT para português brasileiro"
    ["flan-t5-large"]="Modelo multilíngue com suporte ao português"

    # === MODELOS PARA TAREFAS ESPECÍFICAS ===
    ["dolphin-mistral:7b"]="Otimizado para conversação natural"
    ["neural-chat:7b"]="Focado em conversação inteligente"
    ["openchat:7b"]="Modelo de chat aberto e conversacional"
    ["solar:10.7b"]="Modelo avançado da Upstage"
)

# Categorias para melhor organização
declare -A CATEGORIES=(
    ["LEVE"]="Modelos leves ideais para dispositivos móveis e testes iniciais"
    ["MEDIO"]="Modelos balanceados para uso geral e desenvolvimento"
    ["AVANCADO"]="Modelos premium para tarefas complexas e produção"
    ["CODIGO"]="Especializados em geração e análise de código"
    ["MULTIMODAL"]="Processam texto e imagens simultaneamente"
    ["EMBEDDINGS"]="Criados especificamente para gerar embeddings"
    ["PORTUGUES"]="Modelos treinados ou otimizados para português"
    ["CONVERSACAO"]="Otimizados para conversação natural e chat"
)

# Função para verificar se Ollama está rodando
check_ollama() {
    section "Verificando Ollama"

    if ! pgrep -f "ollama" >/dev/null; then
        log "Ollama não está rodando. Iniciando..."
        if command -v ollama >/dev/null 2>&1; then
            nohup ollama serve > /dev/null 2>&1 &
            sleep 5
            success "Ollama iniciado"
        else
            error "Ollama não está instalado"
            exit 1
        fi
    else
        log "Ollama já está rodando"
    fi

    # Testar conectividade
    if curl -s "http://${OLLAMA_HOST}/api/tags" >/dev/null 2>&1; then
        success "Conectividade com Ollama OK"
    else
        error "Não foi possível conectar ao Ollama"
        exit 1
    fi
}

# Função para verificar se modelo já existe
model_exists() {
    local model_name="$1"
    curl -s "http://${OLLAMA_HOST}/api/tags" | grep -q "\"name\":\"${model_name}\"" 2>/dev/null
}

# Função para instalar modelo
install_model() {
    local model_name="$1"
    local description="$2"

    log "Instalando: $model_name"
    log "Descrição: $description"

    if model_exists "$model_name"; then
        warn "Modelo $model_name já existe, pulando..."
        return 0
    fi

    # Instalar modelo
    if ollama pull "$model_name" >> "$MODEL_LOG" 2>&1; then
        success "✅ Modelo $model_name instalado com sucesso"
        return 0
    else
        error "❌ Falha ao instalar modelo $model_name"
        return 1
    fi
}

# Função para mostrar menu de categorias
show_category_menu() {
    section "📂 CATEGORIAS DE MODELOS DISPONÍVEIS"

    local i=1
    for category in "${!CATEGORIES[@]}"; do
        echo "$i) $category - ${CATEGORIES[$category]}"
        ((i++))
    done

    echo "0) Todas as categorias"
    echo "q) Sair"

    echo
    read -p "Escolha uma categoria (0-$((${#CATEGORIES[@]}-1)) ou 'q'): " choice

    case $choice in
        0) echo "ALL" ;;
        q|Q) echo "QUIT" ;;
        [1-9]|[1-9][0-9])
            if [ "$choice" -le "${#CATEGORIES[@]}" ]; then
                local category_index=0
                for category in "${!CATEGORIES[@]}"; do
                    ((category_index++))
                    if [ "$category_index" -eq "$choice" ]; then
                        echo "$category"
                        return
                    fi
                done
            else
                echo "INVALID"
            fi
            ;;
        *) echo "INVALID" ;;
    esac
}

# Função para filtrar modelos por categoria
get_models_by_category() {
    local category="$1"
    local filtered_models=()

    case $category in
        "LEVE")
            for model in "${!MODELS[@]}"; do
                if [[ "$model" =~ (1b|2b|3b|3\.8b) ]] && [[ ! "$model" =~ (13b|70b|72b|8x7b) ]]; then
                    filtered_models+=("$model")
                fi
            done
            ;;
        "MEDIO")
            for model in "${!MODELS[@]}"; do
                if [[ "$model" =~ (7b|8b) ]] && [[ ! "$model" =~ (13b|70b|72b|8x7b) ]]; then
                    filtered_models+=("$model")
                fi
            done
            ;;
        "AVANCADO")
            for model in "${!MODELS[@]}"; do
                if [[ "$model" =~ (70b|72b|8x7b|13b) ]]; then
                    filtered_models+=("$model")
                fi
            done
            ;;
        "CODIGO")
            for model in "${!MODELS[@]}"; do
                if [[ "$model" =~ (codellama|deepseek-coder|starcoder) ]]; then
                    filtered_models+=("$model")
                fi
            done
            ;;
        "MULTIMODAL")
            for model in "${!MODELS[@]}"; do
                if [[ "$model" =~ (llava|bakllava|moondream) ]]; then
                    filtered_models+=("$model")
                fi
            done
            ;;
        "EMBEDDINGS")
            for model in "${!MODELS[@]}"; do
                if [[ "$model" =~ (embed) ]]; then
                    filtered_models+=("$model")
                fi
            done
            ;;
        "PORTUGUES")
            for model in "${!MODELS[@]}"; do
                if [[ "$model" =~ (portuguese|bertimbau|t5) ]]; then
                    filtered_models+=("$model")
                fi
            done
            ;;
        "CONVERSACAO")
            for model in "${!MODELS[@]}"; do
                if [[ "$model" =~ (dolphin|neural-chat|openchat|solar) ]]; then
                    filtered_models+=("$model")
                fi
            done
            ;;
        "ALL")
            for model in "${!MODELS[@]}"; do
                filtered_models+=("$model")
            done
            ;;
    esac

    echo "${filtered_models[@]}"
}

# Função principal
main() {
    section "🚀 INSTALADOR DE MODELOS ADICIONAIS - CLUSTER AI"

    # Verificar Ollama
    check_ollama

    # Criar diretório de logs
    mkdir -p "$LOG_DIR"

    # Menu principal
    while true; do
        section "📋 MENU DE INSTALAÇÃO DE MODELOS"

        echo "Total de modelos disponíveis: ${#MODELS[@]}"
        echo
        echo "Opções:"
        echo "1) 📂 Instalar por categoria"
        echo "2) 🔍 Buscar modelo específico"
        echo "3) 📊 Mostrar todos os modelos"
        echo "4) ⚡ Instalação rápida (recomendados)"
        echo "0) ❌ Sair"
        echo

        read -p "Escolha uma opção: " choice

        case $choice in
            1)
                # Instalar por categoria
                category=$(show_category_menu)

                case $category in
                    "QUIT") continue ;;
                    "INVALID")
                        warn "Opção inválida"
                        continue
                        ;;
                    *)
                        section "📦 MODELOS DA CATEGORIA: $category"

                        # Obter modelos da categoria
                        read -ra models_array <<< "$(get_models_by_category "$category")"

                        if [ ${#models_array[@]} -eq 0 ]; then
                            warn "Nenhum modelo encontrado nesta categoria"
                            continue
                        fi

                        echo "Modelos encontrados: ${#models_array[@]}"
                        echo

                        # Mostrar modelos disponíveis
                        local i=1
                        for model in "${models_array[@]}"; do
                            echo "$i) $model - ${MODELS[$model]}"
                            ((i++))
                        done

                        echo
                        read -p "Digite os números dos modelos (ex: 1,3,5) ou 'todos': " selection

                        if [ "$selection" = "todos" ]; then
                            selected_models=("${models_array[@]}")
                        else
                            selected_models=()
                            IFS=',' read -ra selections <<< "$selection"
                            for sel in "${selections[@]}"; do
                                if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le ${#models_array[@]} ]; then
                                    selected_models+=("${models_array[$((sel-1))]}")
                                fi
                            done
                        fi

                        if [ ${#selected_models[@]} -eq 0 ]; then
                            warn "Nenhum modelo válido selecionado"
                            continue
                        fi

                        # Instalar modelos selecionados
                        section "⬇️ INSTALANDO MODELOS SELECIONADOS"
                        local installed=0
                        local failed=0

                        for model in "${selected_models[@]}"; do
                            if install_model "$model" "${MODELS[$model]}"; then
                                ((installed++))
                            else
                                ((failed++))
                            fi
                        done

                        section "📊 RESULTADO DA INSTALAÇÃO"
                        success "✅ Instalados: $installed"
                        if [ $failed -gt 0 ]; then
                            warn "❌ Falharam: $failed"
                        fi
                        ;;
                esac
                ;;

            2)
                # Buscar modelo específico
                read -p "Digite o nome do modelo para buscar: " search_term

                section "🔍 RESULTADOS DA BUSCA: '$search_term'"

                local found_models=()
                for model in "${!MODELS[@]}"; do
                    if [[ "$model" =~ $search_term ]] || [[ "${MODELS[$model]}" =~ $search_term ]]; then
                        found_models+=("$model")
                    fi
                done

                if [ ${#found_models[@]} -eq 0 ]; then
                    warn "Nenhum modelo encontrado"
                    continue
                fi

                local i=1
                for model in "${found_models[@]}"; do
                    echo "$i) $model - ${MODELS[$model]}"
                    ((i++))
                done

                echo
                read -p "Digite o número do modelo para instalar (0 para cancelar): " model_choice

                if [[ "$model_choice" =~ ^[0-9]+$ ]] && [ "$model_choice" -ge 1 ] && [ "$model_choice" -le ${#found_models[@]} ]; then
                    selected_model="${found_models[$((model_choice-1))]}"
                    section "⬇️ INSTALANDO MODELO: $selected_model"
                    install_model "$selected_model" "${MODELS[$selected_model]}"
                fi
                ;;

            3)
                # Mostrar todos os modelos
                section "📚 TODOS OS MODELOS DISPONÍVEIS"

                for category in "${!CATEGORIES[@]}"; do
                    echo
                    echo "=== $category ==="
                    echo "${CATEGORIES[$category]}"
                    echo

                    local category_models=()
                    read -ra category_models <<< "$(get_models_by_category "$category")"

                    for model in "${category_models[@]}"; do
                        echo "  • $model - ${MODELS[$model]}"
                    done
                done

                echo
                read -p "Pressione Enter para continuar..."
                ;;

            4)
                # Instalação rápida
                section "⚡ INSTALAÇÃO RÁPIDA - MODELOS RECOMENDADOS"

                local recommended_models=(
                    "llama3.2:3b"
                    "mistral:7b"
                    "codellama:7b"
                    "llava:7b"
                    "nomic-embed-text"
                )

                echo "Modelos recomendados para começar:"
                local i=1
                for model in "${recommended_models[@]}"; do
                    echo "$i) $model - ${MODELS[$model]}"
                    ((i++))
                done

                echo
                if confirm_operation "Deseja instalar todos os modelos recomendados?"; then
                    section "⬇️ INSTALANDO MODELOS RECOMENDADOS"
                    local installed=0
                    local failed=0

                    for model in "${recommended_models[@]}"; do
                        if install_model "$model" "${MODELS[$model]}"; then
                            ((installed++))
                        else
                            ((failed++))
                        fi
                    done

                    section "📊 RESULTADO DA INSTALAÇÃO RÁPIDA"
                    success "✅ Instalados: $installed"
                    if [ $failed -gt 0 ]; then
                        warn "❌ Falharam: $failed"
                    fi
                fi
                ;;

            0)
                section "👋 ATÉ LOGO!"
                success "Instalação de modelos concluída"
                exit 0
                ;;

            *)
                warn "Opção inválida"
                ;;
        esac
    done
}

# Executar função principal
main "$@"
