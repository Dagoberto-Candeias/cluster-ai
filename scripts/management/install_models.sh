#!/bin/bash
#
# 🧠 Script Interativo para Instalar Modelos do Ollama - Cluster AI
# Instala uma lista pré-definida de modelos, focando nos menores e mais eficientes.
#

set -euo pipefail

# --- Carregar Funções Comuns ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# --- Variáveis de Cor Adicionais ---
GRAY='\033[0;37m'

# --- Lista de Modelos Disponíveis para Instalação ---
# Modelos organizados por categoria com descrições detalhadas
# Formato: "nome:tamanho" # (tamanho) Descrição detalhada + casos de uso

# 🗣️ MODELOS DE CONVERSAÇÃO (Foco em diálogo natural)
CONVERSATION_MODELS=(
    "phi-2:2.7b"        # (1.7 GB) Modelo compacto da Microsoft, ideal para desenvolvimento rápido e testes de conceito
    "gemma:2b"          # (1.7 GB) Modelo do Google, excelente para diálogo natural e compreensão contextual
    "llama3:8b"         # (4.7 GB) Meta Llama 3, versátil para conversação, análise e tarefas gerais
    "mistral:7b"        # (4.1 GB) Modelo francês eficiente, ótimo para conversação multilíngue
    "qwen:1.8b"         # (1.1 GB) Modelo bilíngue chinês/inglês, competente para diálogo intercultural
    "orca-mini:3b"      # (1.9 GB) Modelo otimizado para conversação, rápido e eficiente
)

# 💻 MODELOS DE PROGRAMAÇÃO (Foco em código e desenvolvimento)
CODING_MODELS=(
    "codellama:7b"      # (3.8 GB) Especialista em programação, geração e análise de código
    "deepseek-coder:6.7b" # (4.0 GB) Modelo otimizado para desenvolvimento de software
    "starcoder:3b"      # (1.8 GB) Modelo focado em geração de código, bom para prototipagem
)

# 📊 MODELOS DE ANÁLISE (Foco em raciocínio e análise)
ANALYSIS_MODELS=(
    "llama3:70b"        # (40 GB) Versão grande do Llama 3, excelente para análise complexa
    "mixtral:8x7b"      # (26 GB) Modelo de mistura de especialistas, ótimo para tarefas analíticas
    "yi:34b"           # (20 GB) Modelo chinês avançado, forte em matemática e análise
)

# 🎨 MODELOS CRIATIVOS (Foco em geração de conteúdo)
CREATIVE_MODELS=(
    "llava:7b"          # (4.5 GB) Modelo multimodal, combina visão e texto para criatividade
    "bakllava:7b"       # (4.5 GB) Versão otimizada do LLaVA para tarefas criativas
)

# 🌍 MODELOS MULTILÍNGUES (Foco em múltiplos idiomas)
MULTILINGUAL_MODELS=(
    "qwen:72b"          # (42 GB) Modelo massivo multilíngue, suporta 20+ idiomas
    "bloom:7b"          # (4.0 GB) Modelo multilíngue da BigScience, forte em idiomas diversos
)

# 🧪 MODELOS LEVES (Foco em testes e prototipagem)
LIGHT_MODELS=(
    "tinyllama:1.1b"    # (637 MB) Extremamente leve, ideal para testes e dispositivos limitados
    "phi-2:2.7b"        # (1.7 GB) Modelo compacto da Microsoft, bom para desenvolvimento rápido
)

# Combinar todas as categorias em uma lista única
AVAILABLE_MODELS=(
    # Conversação
    "${CONVERSATION_MODELS[@]}"
    # Programação
    "${CODING_MODELS[@]}"
    # Análise
    "${ANALYSIS_MODELS[@]}"
    # Criativos
    "${CREATIVE_MODELS[@]}"
    # Multilíngues
    "${MULTILINGUAL_MODELS[@]}"
    # Leves
    "${LIGHT_MODELS[@]}"
)

# Mapeamento de categorias para facilitar navegação
declare -A MODEL_CATEGORIES
MODEL_CATEGORIES=(
    ["phi-3:3.8b"]="🗣️ Conversação"
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
    ["phi-2:2.7b"]="🧪 Leve"
)

# Descrições detalhadas dos modelos
declare -A MODEL_DESCRIPTIONS
MODEL_DESCRIPTIONS=(
    ["phi-3:3.8b"]="Modelo compacto da Microsoft com ótimo desempenho para conversação geral, tarefas leves e prototipagem rápida"
    ["gemma:2b"]="Modelo do Google otimizado para diálogo natural, compreensão contextual e tarefas conversacionais do dia a dia"
    ["llama3:8b"]="Meta Llama 3 versátil - excelente para conversação, análise de texto e tarefas gerais de processamento de linguagem"
    ["mistral:7b"]="Modelo francês eficiente, ideal para conversação multilíngue e tarefas que exigem compreensão cultural"
    ["qwen:1.8b"]="Modelo bilíngue chinês/inglês, perfeito para comunicação intercultural e tarefas que envolvem ambos os idiomas"
    ["orca-mini:3b"]="Modelo otimizado para conversação natural, rápido e eficiente para chatbots e assistentes virtuais"
    ["codellama:7b"]="Especialista em programação - gera, analisa e depura código em múltiplas linguagens de programação"
    ["deepseek-coder:6.7b"]="Modelo otimizado para desenvolvimento de software, com foco em geração e compreensão de código"
    ["starcoder:3b"]="Modelo focado em geração de código, ideal para prototipagem rápida e desenvolvimento ágil"
    ["llama3:70b"]="Versão avançada do Llama 3, excelente para análise complexa, pesquisa e tarefas que exigem raciocínio profundo"
    ["mixtral:8x7b"]="Modelo de mistura de especialistas, ótimo para tarefas analíticas complexas e processamento de dados"
    ["yi:34b"]="Modelo chinês avançado, forte em matemática, análise lógica e resolução de problemas complexos"
    ["llava:7b"]="Modelo multimodal que combina visão e texto, perfeito para tarefas criativas que envolvem imagens"
    ["bakllava:7b"]="Versão otimizada do LLaVA, especializada em tarefas criativas e geração de conteúdo visual"
    ["qwen:72b"]="Modelo massivo multilíngue que suporta mais de 20 idiomas, ideal para aplicações globais"
    ["bloom:7b"]="Modelo multilíngue da BigScience, forte em processamento de idiomas diversos e tradução"
    ["tinyllama:1.1b"]="Modelo extremamente leve, perfeito para testes, prototipagem e dispositivos com recursos limitados"
    ["phi-2:2.7b"]="Modelo compacto da Microsoft, ideal para desenvolvimento rápido e testes de conceito"
)

# --- Funções do Menu Interativo ---

# Array para armazenar os índices dos modelos selecionados
declare -a selected_indices

# Verifica se um índice está no array de selecionados
is_selected() {
    local index="$1"
    for i in "${selected_indices[@]}"; do
        if [[ "$i" == "$index" ]]; then
            return 0 # 0 significa sucesso (true em bash)
        fi
    done
    return 1 # 1 significa falha (false)
}

# Alterna a seleção de um índice
toggle_selection() {
    local index="$1"
    local new_selection=()
    local found=false
    for i in "${selected_indices[@]}"; do
        if [[ "$i" == "$index" ]]; then
            found=true
        else
            new_selection+=("$i")
        fi
    done

    if ! $found; then
        new_selection+=("$index")
    fi
    selected_indices=("${new_selection[@]}")
}

# Exibe o menu de seleção
show_selection_menu() {
    clear
    section "🧠 Seleção de Modelos para Instalar"

    # Obter lista de modelos já instalados
    local installed_models
    installed_models=$(ollama list | awk 'NR>1 {print $1}')

    # Mostrar categorias disponíveis
    echo -e "\n${BLUE}📂 CATEGORIAS DISPONÍVEIS:${NC}"
    echo "🗣️  Conversação  💻 Programação  📊 Análise  🎨 Criativo  🌍 Multilíngue  🧪 Leve"
    echo

    local current_category=""
    for i in "${!AVAILABLE_MODELS[@]}"; do
        local model_name="${AVAILABLE_MODELS[$i]}"
        local category="${MODEL_CATEGORIES[$model_name]}"
        local description="${MODEL_DESCRIPTIONS[$model_name]}"
        local checkbox="[ ]"
        local status=""

        # Mostrar cabeçalho da categoria quando muda
        if [[ "$category" != "$current_category" ]]; then
            echo -e "\n${YELLOW}$category${NC}"
            echo "────────────────────────────────────────"
            current_category="$category"
        fi

        if is_selected "$i"; then
            checkbox="[${GREEN}x${NC}]"
        fi

        if echo "$installed_models" | grep -q "^${model_name}"; then
            status="(${YELLOW}Já instalado${NC})"
        fi

        # Extrair tamanho do modelo do nome
        local size_info=""
        if [[ "$model_name" == *":"* ]]; then
            size_info="($(echo $model_name | cut -d':' -f2))"
        fi

        printf "  %s %2d) %-20s %-8s %s\n" "$checkbox" "$((i+1))" "$model_name" "$size_info" "$status"
        # Mostrar descrição se disponível
        if [[ -n "$description" ]]; then
            echo -e "      ${GRAY}└─ $description${NC}"
        fi
    done

    echo
    info "Digite o número para selecionar/desmarcar um modelo."
    info "Pressione 'c' para ver apenas uma categoria específica."
    info "Pressione 'a' para selecionar/desmarcar TODOS."
    info "Pressione 'i' para instalar os selecionados ou 'q' para sair."
}

# Menu de seleção de categoria
show_category_menu() {
    clear
    section "📂 Seleção de Categoria"

    echo "Escolha uma categoria para filtrar os modelos:"
    echo
    echo "1. 🗣️  Conversação     - Modelos para diálogo natural"
    echo "2. 💻 Programação      - Modelos especializados em código"
    echo "3. 📊 Análise          - Modelos para raciocínio e análise"
    echo "4. 🎨 Criativo         - Modelos para geração de conteúdo"
    echo "5. 🌍 Multilíngue      - Modelos para múltiplos idiomas"
    echo "6. 🧪 Leve             - Modelos leves para testes"
    echo "7. 🔄 Mostrar Todos    - Ver todas as categorias"
    echo
    echo "8. ↩️  Voltar ao menu principal"
}

# Filtrar modelos por categoria
filter_models_by_category() {
    local category_choice="$1"
    local filtered_models=()

    case $category_choice in
        1) local category_filter="🗣️ Conversação" ;;
        2) local category_filter="💻 Programação" ;;
        3) local category_filter="📊 Análise" ;;
        4) local category_filter="🎨 Criativo" ;;
        5) local category_filter="🌍 Multilíngue" ;;
        6) local category_filter="🧪 Leve" ;;
        7) return 0 ;; # Mostrar todos
        *) return 1 ;; # Inválido
    esac

    # Filtrar modelos pela categoria
    for i in "${!AVAILABLE_MODELS[@]}"; do
        local model_name="${AVAILABLE_MODELS[$i]}"
        local model_category="${MODEL_CATEGORIES[$model_name]}"

        if [[ "$model_category" == "$category_filter" ]]; then
            filtered_models+=("$i")
        fi
    done

    echo "${filtered_models[@]}"
}

# Exibe o menu de seleção filtrado por categoria
show_filtered_selection_menu() {
    local category_filter="$1"
    clear
    section "🧠 Seleção de Modelos - $category_filter"

    # Obter lista de modelos já instalados
    local installed_models
    installed_models=$(ollama list | awk 'NR>1 {print $1}')

    echo -e "\n${BLUE}📂 Categoria: $category_filter${NC}"
    echo "────────────────────────────────────────"

    local item_number=1
    for i in "${!AVAILABLE_MODELS[@]}"; do
        local model_name="${AVAILABLE_MODELS[$i]}"
        local model_category="${MODEL_CATEGORIES[$model_name]}"
        local description="${MODEL_DESCRIPTIONS[$model_name]}"

        # Mostrar apenas modelos da categoria filtrada
        if [[ "$model_category" == "$category_filter" ]]; then
            local checkbox="[ ]"
            local status=""

            if is_selected "$i"; then
                checkbox="[${GREEN}x${NC}]"
            fi

            if echo "$installed_models" | grep -q "^${model_name}"; then
                status="(${YELLOW}Já instalado${NC})"
            fi

            # Extrair tamanho do modelo do nome
            local size_info=""
            if [[ "$model_name" == *":"* ]]; then
                size_info="($(echo $model_name | cut -d':' -f2))"
            fi

            printf "  %s %2d) %-20s %-8s %s\n" "$checkbox" "$item_number" "$model_name" "$size_info" "$status"
            # Mostrar descrição se disponível
            if [[ -n "$description" ]]; then
                echo -e "      ${GRAY}└─ $description${NC}"
            fi

            # Adicionar à lista de índices filtrados para mapeamento
            filtered_indices[$((item_number-1))]="$i"
            ((item_number++))
        fi
    done

    echo
    info "Digite o número para selecionar/desmarcar um modelo desta categoria."
    info "Pressione 'a' para selecionar/desmarcar TODOS desta categoria."
    info "Pressione 'c' para escolher outra categoria."
    info "Pressione 'i' para instalar os selecionados ou 'q' para sair."
}

# Loop principal para a seleção interativa
run_interactive_selection() {
    selected_indices=()  # Initialize the array
    local category_filter=""
    local filtered_indices=()

    while true; do
        if [[ -n "$category_filter" ]]; then
            # Mostrar apenas modelos filtrados
            show_filtered_selection_menu "$category_filter"
        else
            # Mostrar todos os modelos
            show_selection_menu
        fi

        read -p "Sua escolha: " choice

        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            if [[ -n "$category_filter" && ${#filtered_indices[@]} -gt 0 ]]; then
                # Modo filtrado - mapear para índice real
                local filtered_index="$((choice-1))"
                if [ "$filtered_index" -lt "${#filtered_indices[@]}" ]; then
                    local real_index="${filtered_indices[$filtered_index]}"
                    toggle_selection "$real_index"
                else
                    warn "Número inválido para categoria filtrada."
                    sleep 1
                fi
            elif [ "$choice" -ge 1 ] && [ "$choice" -le ${#AVAILABLE_MODELS[@]} ]; then
                # Modo normal
                toggle_selection "$((choice-1))"
            else
                warn "Número inválido."
                sleep 1
            fi
        elif [[ "$choice" == "a" || "$choice" == "A" ]]; then
            if [[ -n "$category_filter" ]]; then
                # Selecionar/desmarcar apenas da categoria filtrada
                local all_selected=true
                for idx in "${filtered_indices[@]}"; do
                    if ! is_selected "$idx"; then
                        all_selected=false
                        break
                    fi
                done

                if $all_selected; then
                    # Desmarcar todos da categoria
                    for idx in "${filtered_indices[@]}"; do
                        # Remover da seleção se estiver selecionado
                        local new_selection=()
                        for sel_idx in "${selected_indices[@]}"; do
                            if [[ "$sel_idx" != "$idx" ]]; then
                                new_selection+=("$sel_idx")
                            fi
                        done
                        selected_indices=("${new_selection[@]}")
                    done
                else
                    # Selecionar todos da categoria
                    for idx in "${filtered_indices[@]}"; do
                        if ! is_selected "$idx"; then
                            selected_indices+=("$idx")
                        fi
                    done
                fi
            else
                # Modo normal - todos os modelos
                if [ ${#selected_indices[@]} -eq ${#AVAILABLE_MODELS[@]} ]; then
                    selected_indices=() # Desmarcar todos
                else
                    selected_indices=($(seq 0 $((${#AVAILABLE_MODELS[@]} - 1)))) # Selecionar todos
                fi
            fi
        elif [[ "$choice" == "c" || "$choice" == "C" ]]; then
            # Menu de categorias
            while true; do
                show_category_menu
                read -p "Escolha uma categoria [1-8]: " cat_choice

                case $cat_choice in
                    1|2|3|4|5|6)
                        filtered_indices=($(filter_models_by_category "$cat_choice"))
                        case $cat_choice in
                            1) category_filter="🗣️ Conversação" ;;
                            2) category_filter="💻 Programação" ;;
                            3) category_filter="📊 Análise" ;;
                            4) category_filter="🎨 Criativo" ;;
                            5) category_filter="🌍 Multilíngue" ;;
                            6) category_filter="🧪 Leve" ;;
                        esac
                        break
                        ;;
                    7)
                        category_filter=""
                        filtered_indices=()
                        break
                        ;;
                    8)
                        break
                        ;;
                    *)
                        warn "Opção inválida."
                        sleep 1
                        ;;
                esac
            done
        elif [[ "$choice" == "i" || "$choice" == "I" ]]; then
            break
        elif [[ "$choice" == "q" || "$choice" == "Q" ]]; then
            selected_indices=() # Limpa a seleção antes de sair
            break
        else
            warn "Opção inválida."
            sleep 1
        fi
    done
}

# --- Função Principal ---
main() {
    section "🧠 Instalador de Modelos Ollama"

    if ! command_exists ollama; then
        error "Ollama não está instalado ou não está no PATH."
        info "Por favor, execute o instalador principal primeiro: ./install_unified.sh"
        exit 1
    fi

    log "Verificando o serviço Ollama..."
    if ! pgrep -f "ollama serve" > /dev/null && ! sudo systemctl is-active --quiet ollama; then
        warn "O serviço Ollama não está ativo. Tentando iniciar..."
        # Tenta iniciar via manager.sh para manter a consistência
        bash "${PROJECT_ROOT}/manager.sh" start
        sleep 5 # Aguarda o serviço iniciar
    fi

    run_interactive_selection

    if [ ${#selected_indices[@]} -eq 0 ]; then
        info "Nenhum modelo selecionado. Operação cancelada."
        exit 0
    fi

    local models_to_install=()
    for index in "${selected_indices[@]}"; do
        models_to_install+=("${AVAILABLE_MODELS[$index]}")
    done

    section "🚀 Iniciando Instalação"
    info "Modelos a serem instalados: ${models_to_install[*]}"
    
    for model in "${models_to_install[@]}"; do
        # Verifica novamente se o modelo já está instalado antes de puxar
        if ollama list | awk 'NR>1 {print $1}' | grep -q "^${model}"; then
            subsection "Verificando atualizações para: $model"
            info "Modelo já está instalado. O Ollama irá baixar apenas as camadas novas, se houver."
        else
            subsection "Baixando novo modelo: $model"
        fi
        
        # O ollama pull é idempotente, só baixa o que for novo.
        ollama pull "$model" || error "Falha ao baixar o modelo '$model'. Verifique a conexão com a internet ou o nome do modelo."
    done

    section "✅ Instalação Concluída"
    info "Lista de modelos atualmente instalados:"
    ollama list
}

main "$@"