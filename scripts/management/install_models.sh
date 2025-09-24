#!/bin/bash
# =============================================================================
# Instala uma lista pré-definida de modelos, focando nos menores e mais eficientes.
# =============================================================================
# Instala uma lista pré-definida de modelos, focando nos menores e mais eficientes.
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: install_models.sh
# =============================================================================

set -euo pipefail

# Carregar biblioteca comum
source "$(dirname "$0")/../lib/common.sh"

# --- Cores e Estilos (fallback caso common.sh não esteja disponível) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/config/cluster.conf"
LOG_DIR="${PROJECT_ROOT}/logs"

# Criar arquivo temporário para log
MODEL_LOG=$(mktemp)

# Carregar configurações
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Configurações do Ollama
OLLAMA_HOST="${OLLAMA_HOST:-127.0.0.1:11434}"

# --- Categorias de Modelos ---
declare -A CATEGORIAS_DISPONIVEIS=(
    ["1"]="Conversação"
    ["2"]="Programação"
    ["3"]="Análise"
    ["4"]="Criativo"
    ["5"]="Multilíngue"
    ["6"]="Leve"
    ["7"]="Instalar Todos"
    ["q"]="Sair"
)

# --- Arrays de Modelos por Categoria ---
declare -A MODELOS_CONVERSACAO=(
    ["phi-3:3.8b"]="Modelo compacto da Microsoft para conversação geral"
    ["gemma:2b"]="Modelo leve do Google para conversação"
    ["llama3:8b"]="Modelo balanceado da Meta para conversação"
    ["mistral:7b"]="Modelo eficiente da Mistral AI"
    ["qwen2:7b"]="Modelo versátil da Alibaba"
)

declare -A MODELOS_PROGRAMACAO=(
    ["codellama:7b"]="Especializado em geração de código"
    ["deepseek-coder:6.7b"]="Modelo otimizado para programação"
    ["starcoder:3b"]="Modelo compacto para código"
    ["codegemma:2b"]="Modelo do Google para programação"
    ["qwen2.5-coder:7b"]="Modelo da Alibaba para desenvolvimento"
)

declare -A MODELOS_ANALISE=(
    ["llama3.1:8b"]="Modelo para análise de dados e texto"
    ["qwen2:7b"]="Modelo para tarefas analíticas"
    ["gemma:7b"]="Modelo do Google para análise"
)

declare -A MODELOS_CRIATIVO=(
    ["llama3:8b"]="Modelo criativo da Meta"
    ["phi-3:3.8b"]="Modelo criativo compacto"
    ["gemma:7b"]="Modelo criativo do Google"
)

declare -A MODELOS_MULTILINGUE=(
    ["llama3:8b"]="Suporte multilíngue da Meta"
    ["qwen2:7b"]="Modelo multilíngue da Alibaba"
    ["gemma:7b"]="Suporte global do Google"
)

declare -A MODELOS_LEVE=(
    ["phi-3:3.8b"]="Modelo compacto da Microsoft"
    ["gemma:2b"]="Modelo leve do Google"
    ["tinyllama:1.1b"]="Modelo ultracompacto"
    ["qwen2:1.5b"]="Modelo leve da Alibaba"
    ["smollm:1.7b"]="Modelo muito compacto"
)

# Array principal com todos os modelos (sem duplicatas para reduzir contagem)
declare -A MODELS=(
    ["phi-3:3.8b"]="Modelo compacto da Microsoft para conversação geral"
    ["gemma:2b"]="Modelo leve do Google para conversação"
    ["llama3:8b"]="Modelo balanceado da Meta para conversação"
    ["mistral:7b"]="Modelo eficiente da Mistral AI"
    ["qwen2:7b"]="Modelo versátil da Alibaba"
    ["codellama:7b"]="Especializado em geração de código"
    ["deepseek-coder:6.7b"]="Modelo otimizado para programação"
    ["starcoder:3b"]="Modelo compacto para código"
    ["codegemma:2b"]="Modelo do Google para programação"
    ["qwen2.5-coder:7b"]="Modelo da Alibaba para desenvolvimento"
    ["llama3.1:8b"]="Modelo para análise de dados e texto"
    ["gemma:7b"]="Modelo do Google para análise"
    ["tinyllama:1.1b"]="Modelo ultracompacto"
    ["qwen2:1.5b"]="Modelo leve da Alibaba"
    ["smollm:1.7b"]="Modelo muito compacto"
)

# --- Funções ---

# Função para verificar se Ollama está rodando
check_ollama() {
    section "Verificando Ollama"

    if ! pgrep -f "ollama" >/dev/null; then
        log "Ollama não está rodando. Iniciando..."
        if command_exists ollama; then
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

# Função para instalar um modelo
install_model() {
    local model_name="$1"
    local model_description="$2"

    if model_exists "$model_name"; then
        warn "Modelo $model_name já está instalado"
        return 0
    fi

    log "Instalando $model_name..."
    progress "Download em andamento: $model_name"

    if ollama pull "$model_name" >> "$MODEL_LOG" 2>&1; then
        success "Modelo $model_name instalado com sucesso"
        return 0
    else
        error "Falha ao instalar $model_name"
        return 1
    fi
}

# Função para exibir modelos de uma categoria
display_models() {
    local category_name="$1"
    local -n models_ref="$2"

    section "Modelos - $category_name"
    echo -e "${CYAN}Selecione os modelos que deseja instalar:${NC}"
    echo

    local index=1
    for model in "${!models_ref[@]}"; do
        local description="${models_ref[$model]}"
        echo -e "${YELLOW}$index)${NC} $model"
        echo -e "    ${GRAY}$description${NC}"
        ((index++))
    done

    echo
    echo -e "${YELLOW}*)${NC} Selecionar todos"
    echo -e "${YELLOW}0)${NC} Voltar"
    echo
    echo -e "${GRAY}Digite o número da opção ou pressione Enter para continuar:${NC}"
}

# Função para selecionar categoria
select_category() {
    section "Instalador de Modelos Ollama - Cluster AI"
    echo -e "${CYAN}Selecione uma categoria de modelos:${NC}"
    echo

    for key in "${!CATEGORIAS_DISPONIVEIS[@]}"; do
        local category="${CATEGORIAS_DISPONIVEIS[$key]}"
        echo -e "${YELLOW}$key)${NC} $category"
    done

    echo
    echo -e "${GRAY}Digite o número da categoria ou pressione 'q' para sair:${NC}"
}

# Função para instalar modelos selecionados
install_selected_models() {
    local -n models_to_install="$1"
    local category_name="$2"

    local selected_models=()
    local select_all=false

    while true; do
        display_models "$category_name" models_to_install

        read -p "Digite sua escolha: " choice
        echo

        case $choice in
            0)
                return 1
                ;;
            "*")
                select_all=true
                break
                ;;
            [1-9]|[1-9][0-9])
                local index=$choice
                local count=1
                for model in "${!models_to_install[@]}"; do
                    if [ $count -eq $index ]; then
                        selected_models+=("$model")
                        break
                    fi
                    ((count++))
                done
                ;;
            *)
                warn "Opção inválida: $choice"
                continue
                ;;
        esac

        if [ ${#selected_models[@]} -gt 0 ] || [ "$select_all" = true ]; then
            break
        fi
    done

    # Confirmar instalação
    if [ "$select_all" = true ]; then
        echo -e "${CYAN}Você selecionou todos os modelos da categoria $category_name${NC}"
        selected_models=("${!models_to_install[@]}")
    else
        echo -e "${CYAN}Você selecionou:${NC}"
        for model in "${selected_models[@]}"; do
            echo -e "  - $model"
        done
    fi

    echo
    if ! confirm_operation "Deseja instalar os modelos selecionados?"; then
        warn "Instalação cancelada pelo usuário"
        return 1
    fi

    # Instalar modelos
    local success_count=0
    local total_count=${#selected_models[@]}

    section "Instalando Modelos"
    for model in "${selected_models[@]}"; do
        local description="${models_to_install[$model]}"
        if install_model "$model" "$description"; then
            ((success_count++))
        fi
    done

    # Resultado final
    echo
    if [ $success_count -eq $total_count ]; then
        success "Todos os $total_count modelos foram instalados com sucesso!"
    else
        warn "$success_count de $total_count modelos instalados com sucesso"
    fi

    return 0
}

# Função para instalar todos os modelos
install_all_models() {
    section "Instalando Todos os Modelos"

    echo -e "${CYAN}Esta operação instalará todos os modelos disponíveis.${NC}"
    echo -e "${YELLOW}Atenção: Esta operação pode demorar muito tempo e consumir muito espaço em disco.${NC}"
    echo

    if ! confirm_operation "Tem certeza que deseja instalar TODOS os modelos?"; then
        warn "Instalação de todos os modelos cancelada"
        return 1
    fi

    local success_count=0
    local total_count=${#MODELS[@]}

    for model in "${!MODELS[@]}"; do
        local description="${MODELS[$model]}"
        if install_model "$model" "$description"; then
            ((success_count++))
        fi
    done

    echo
    if [ $success_count -eq $total_count ]; then
        success "Todos os $total_count modelos foram instalados com sucesso!"
    else
        warn "$success_count de $total_count modelos instalados com sucesso"
    fi
}

# Função principal
main() {
    # Verificar se foi chamado com argumentos
    if [ $# -gt 0 ]; then
        case "$1" in
            --help|-h)
                echo "Uso: $0 [opções]"
                echo
                echo "Opções:"
                echo "  --help, -h    Mostra esta ajuda"
                echo "  --all         Instala todos os modelos sem interação"
                echo "  --category N  Instala modelos de uma categoria específica"
                echo
                echo "Se executado sem argumentos, inicia o modo interativo."
                echo "Pressione 'q' a qualquer momento para sair."
                exit 0
                ;;
            --all)
                check_ollama
                install_all_models
                exit 0
                ;;
            --category)
                if [ $# -lt 2 ]; then
                    error "Categoria não especificada. Use --category <número>"
                    exit 1
                fi
                # Implementar lógica para categoria específica se necessário
                warn "Funcionalidade --category ainda não implementada"
                exit 1
                ;;
            *)
                error "Opção inválida: $1"
                echo "Use --help para ver as opções disponíveis"
                exit 1
                ;;
        esac
    fi

    # Modo interativo
    check_ollama

    while true; do
        select_category

        read -p "Digite sua escolha: " choice
        echo

        case $choice in
            q|Q)
                success "Saindo do instalador..."
                exit 0
                ;;
            1)
                install_selected_models MODELOS_CONVERSACAO "Conversação"
                ;;
            2)
                install_selected_models MODELOS_PROGRAMACAO "Programação"
                ;;
            3)
                install_selected_models MODELOS_ANALISE "Análise"
                ;;
            4)
                install_selected_models MODELOS_CRIATIVO "Criativo"
                ;;
            5)
                install_selected_models MODELOS_MULTILINGUE "Multilíngue"
                ;;
            6)
                install_selected_models MODELOS_LEVE "Leve"
                ;;
            7)
                install_all_models
                ;;
            *)
                warn "Opção inválida: $choice"
                continue
                ;;
        esac

        echo
        if ! confirm_operation "Deseja instalar modelos de outra categoria?"; then
            success "Instalação concluída!"
            break
        fi
    done
}

# Executar função principal
main "$@"
