#!/bin/bash
# Script para verificar e instalar modelos Ollama automaticamente

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Verificar se Ollama está instalado
check_ollama_installed() {
    if command -v ollama >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Listar modelos instalados
list_installed_models() {
    if check_ollama_installed; then
        echo -e "${BLUE}=== MODELOS INSTALADOS ===${NC}"
        ollama list
        return 0
    else
        error "Ollama não está instalado."
        return 1
    fi
}

# Verificar se modelo específico está instalado
check_model_installed() {
    local model="$1"
    if check_ollama_installed; then
        if ollama list | grep -q "$model"; then
            return 0
        else
            return 1
        fi
    else
        return 2
    fi
}

# Instalar modelo específico
install_model() {
    local model="$1"
    if check_ollama_installed; then
        log "Instalando modelo: $model"
        ollama pull "$model"
        if [ $? -eq 0 ]; then
            log "Modelo $model instalado com sucesso!"
            return 0
        else
            error "Falha ao instalar modelo $model"
            return 1
        fi
    else
        error "Ollama não está instalado. Instale o Ollama primeiro."
        return 2
    fi
}

# Lista de modelos recomendados (atualizada com mixtral)
RECOMMENDED_MODELS=(
    "llama3.1:8b"
    "llama3:8b" 
    "mixtral:8x7b"       # Novo modelo solicitado
    "deepseek-coder"
    "mistral"
    "llava"
    "phi3"
    "gemma2:9b"
    "codellama"
)

# Menu interativo aprimorado para seleção múltipla de modelos
model_selection_menu() {
    while true; do
        echo -e "${BLUE}=== SELEÇÃO DE MODELOS OLLAMA ===${NC}"
        echo "Selecione os modelos que deseja instalar (múltipla escolha):"
        echo "Use números separados por vírgula ou 'all' para todos"
        echo ""
        
        # Array para armazenar seleção
        local selected_models=()
        local i=1
        
        # Mostrar modelos com status
        for model in "${RECOMMENDED_MODELS[@]}"; do
            if check_model_installed "$model"; then
                echo -e "${GREEN}[$i] $model ✓ (INSTALADO)${NC}"
            else
                echo -e "${YELLOW}[$i] $model ✗ (NÃO INSTALADO)${NC}"
            fi
            ((i++))
        done
        
        echo -e "${CYAN}[a] Instalar TODOS os modelos${NC}"
        echo -e "${CYAN}[c] Modelo personalizado${NC}"
        echo -e "${CYAN}[v] Ver modelos instalados${NC}"
        echo -e "${CYAN}[s] Instalar selecionados${NC}"
        echo -e "${CYAN}[q] Voltar${NC}"
        
        read -p "Selecione as opções (ex: 1,3,5 ou 'all'): " choices
        
        case $choices in
            a|A|all|ALL)
                log "Instalando TODOS os modelos recomendados..."
                for model in "${RECOMMENDED_MODELS[@]}"; do
                    if ! check_model_installed "$model"; then
                        install_model "$model"
                    else
                        log "Modelo $model já está instalado."
                    fi
                done
                ;;
            c|C)
                read -p "Digite o nome do modelo personalizado: " custom_model
                if [ -n "$custom_model" ]; then
                    install_model "$custom_model"
                fi
                ;;
            v|V)
                list_installed_models
                ;;
            s|S)
                if [ ${#selected_models[@]} -eq 0 ]; then
                    warn "Nenhum modelo selecionado. Use números para selecionar."
                else
                    log "Instalando modelos selecionados..."
                    for model in "${selected_models[@]}"; do
                        if ! check_model_installed "$model"; then
                            install_model "$model"
                        else
                            log "Modelo $model já está instalado."
                        fi
                    done
                fi
                ;;
            q|Q)
                return
                ;;
            *)
                # Processar seleção múltipla por números
                selected_models=()
                IFS=',' read -ra choices_array <<< "$choices"
                for choice in "${choices_array[@]}"; do
                    choice=$(echo "$choice" | tr -d '[:space:]')
                    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#RECOMMENDED_MODELS[@]} ]; then
                        local model_index=$((choice-1))
                        selected_models+=("${RECOMMENDED_MODELS[$model_index]}")
                    else
                        warn "Opção inválida: $choice"
                    fi
                done
                
                if [ ${#selected_models[@]} -gt 0 ]; then
                    log "Preparando para instalar ${#selected_models[@]} modelos..."
                    read -p "Confirmar instalação? (s/n): " confirm
                    if [ "$confirm" = "s" ] || [ "$confirm" = "S" ]; then
                        for model in "${selected_models[@]}"; do
                            if ! check_model_installed "$model"; then
                                install_model "$model"
                            else
                                log "Modelo $model já está instalado."
                            fi
                        done
                    fi
                else
                    warn "Nenhuma seleção válida."
                fi
                ;;
        esac
        
        echo ""
        read -p "Pressione Enter para continuar ou 'q' para sair: " continue
        if [ "$continue" = "q" ] || [ "$continue" = "Q" ]; then
            break
        fi
    done
}

# Função principal
main() {
    echo -e "${BLUE}=== VERIFICAÇÃO DE MODELOS OLLAMA ===${NC}"
    
    if ! check_ollama_installed; then
        error "Ollama não está instalado neste sistema."
        echo "Para instalar o Ollama, execute primeiro:"
        echo "curl --connect-timeout 30 --max-time 120 --connect-timeout 30 --max-time 120 -fsSL https://ollama.com/install.sh | sh"
        echo "Ou execute o script principal de instalação do Cluster AI:"
        echo "./install_cluster.sh"
        return 1
    fi
    
    # Mostrar modelos instalados
    list_installed_models
    
    # Verificar se há modelos instalados
    local installed_count=$(ollama list | wc -l)
    if [ "$installed_count" -eq 0 ]; then
        warn "Nenhum modelo Ollama encontrado."
        read -p "Deseja instalar modelos agora? (s/n): " install_choice
        if [ "$install_choice" = "s" ] || [ "$install_choice" = "S" ]; then
            model_selection_menu
        fi
    else
        read -p "Deseja instalar modelos adicionais? (s/n): " additional_choice
        if [ "$additional_choice" = "s" ] || [ "$additional_choice" = "S" ]; then
            model_selection_menu
        fi
    fi
    
    echo -e "${GREEN}Verificação de modelos concluída!${NC}"
}

# Executar função principal
main "$@"
