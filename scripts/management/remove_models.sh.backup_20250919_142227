#!/bin/bash
#
# 🧠 Script Interativo para Remover Modelos do Ollama - Cluster AI
# Permite ao usuário selecionar e remover modelos Ollama instalados.
#

set -euo pipefail

# --- Carregar Funções Comuns ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# --- Funções do Menu Interativo ---

# Array para armazenar os índices dos modelos selecionados
declare -a selected_indices
# Array para armazenar os modelos disponíveis para remoção
declare -a installed_models_list

# Verifica se um índice está no array de selecionados
is_selected() {
    local index="$1"
    for i in "${selected_indices[@]}"; do
        if [[ "$i" == "$index" ]]; then
            return 0 # true
        fi
    done
    return 1 # false
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

# Exibe o menu de seleção de remoção
show_removal_menu() {
    clear
    section "🗑️ Seleção de Modelos para Remover"
    
    for i in "${!installed_models_list[@]}"; do
        local model_info="${installed_models_list[$i]}"
        local model_name
        model_name=$(echo "$model_info" | awk '{print $1}')
        local model_size
        model_size=$(echo "$model_info" | awk '{print $3, $4}')

        local checkbox="[ ]"

        if is_selected "$i"; then
            checkbox="[${GREEN}x${NC}]"
        fi

        printf "  %s %2d) %-25s (%s)\n" "$checkbox" "$((i+1))" "$model_name" "$model_size"
    done

    echo
    info "Digite o número para selecionar/desmarcar um modelo."
    info "Pressione 'a' para selecionar/desmarcar TODOS."
    info "Pressione 'r' para REMOVER os selecionados ou 'q' para sair."
}

# Loop principal para a seleção interativa
run_interactive_removal() {
    while true; do
        show_removal_menu
        read -p "Sua escolha: " choice

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#installed_models_list[@]} ]; then
            toggle_selection "$((choice-1))"
        elif [[ "$choice" == "a" || "$choice" == "A" ]]; then
            if [ ${#selected_indices[@]} -eq ${#installed_models_list[@]} ]; then
                selected_indices=() # Desmarcar todos
            else
                selected_indices=($(seq 0 $((${#installed_models_list[@]} - 1)))) # Selecionar todos
            fi
        elif [[ "$choice" == "r" || "$choice" == "R" ]]; then
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
    section "🗑️ Removedor de Modelos Ollama"

    if ! command_exists ollama; then
        error "Ollama não está instalado ou não está no PATH."
        exit 1
    fi

    # Obter lista de modelos instalados
    mapfile -t installed_models_list < <(ollama list | tail -n +2)

    if [ ${#installed_models_list[@]} -eq 0 ]; then
        success "Nenhum modelo Ollama instalado para remover."
        exit 0
    fi

    run_interactive_removal

    if [ ${#selected_indices[@]} -eq 0 ]; then
        info "Nenhum modelo selecionado. Operação cancelada."
        exit 0
    fi

    local models_to_remove=()
    for index in "${selected_indices[@]}"; do
        models_to_remove+=("$(echo "${installed_models_list[$index]}" | awk '{print $1}')")
    done

    subsection "Modelos a serem removidos:"
    for model in "${models_to_remove[@]}"; do
        echo "  - $model"
    done
    echo

    if ! confirm_operation "Tem certeza que deseja remover permanentemente estes modelos?"; then
        info "Remoção cancelada."
        exit 0
    fi

    section "🔥 Removendo Modelos"
    for model in "${models_to_remove[@]}"; do
        subsection "Removendo: $model"
        if ollama rm "$model"; then
            success "Modelo $model removido com sucesso!"
        else
            error "Falha ao remover o modelo $model."
        fi
    done

    section "✅ Remoção Concluída"
    info "Lista de modelos restantes:"
    ollama list
}

main "$@"