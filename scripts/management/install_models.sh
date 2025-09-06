#!/bin/bash
#
# 🧠 Script Interativo para Instalar Modelos do Ollama - Cluster AI
# Instala uma lista pré-definida de modelos, focando nos menores e mais eficientes.
#

set -euo pipefail

# --- Carregar Funções Comuns ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# --- Lista de Modelos Disponíveis para Instalação ---
# Adicione ou remova modelos conforme sua necessidade.
# Estes são modelos pequenos e eficientes, ótimos para começar.
AVAILABLE_MODELS=(
    "phi-3"          # (2.3 GB) Ótimo desempenho em um pacote pequeno.
    "gemma:2b"       # (1.7 GB) Modelo de 2 bilhões de parâmetros do Google.
    "tinyllama"      # (637 MB) Extremamente leve, ideal para testes rápidos.
    "qwen:1.8b"      # (1.1 GB) Modelo bilíngue (chinês/inglês) muito competente.
    "orca-mini"      # (1.9 GB) Um modelo pequeno e rápido, bom para conversação.
    "llama3:8b"      # (4.7 GB) Modelo popular e versátil de 8 bilhões de parâmetros.
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

    for i in "${!AVAILABLE_MODELS[@]}"; do
        local model_name="${AVAILABLE_MODELS[$i]}"
        local checkbox="[ ]"
        local status=""

        if is_selected "$i"; then
            checkbox="[${GREEN}x${NC}]"
        fi

        if echo "$installed_models" | grep -q "^${model_name}"; then
            status="(${YELLOW}Já instalado${NC})"
        fi

        printf "  %s %2d) %-15s %s\n" "$checkbox" "$((i+1))" "$model_name" "$status"
    done

    echo
    info "Digite o número para selecionar/desmarcar um modelo."
    info "Pressione 'a' para selecionar/desmarcar TODOS."
    info "Pressione 'i' para instalar os selecionados ou 'q' para sair."
}

# Loop principal para a seleção interativa
run_interactive_selection() {
    while true; do
        show_selection_menu
        read -p "Sua escolha: " choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#AVAILABLE_MODELS[@]} ]; then
            toggle_selection "$((choice-1))"
        elif [[ "$choice" == "a" || "$choice" == "A" ]]; then
            if [ ${#selected_indices[@]} -eq ${#AVAILABLE_MODELS[@]} ]; then
                selected_indices=() # Desmarcar todos
            else
                selected_indices=($(seq 0 $((${#AVAILABLE_MODELS[@]} - 1)))) # Selecionar todos
            fi
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