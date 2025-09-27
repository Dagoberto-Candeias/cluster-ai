#!/bin/bash
# =============================================================================
# Script para instalar modelos adicionais do Ollama
# =============================================================================
# Organizado por categoria e tamanho
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: install_additional_models.sh
# =============================================================================

set -euo pipefail

# Carregar biblioteca comum
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# Configurações
LOG_FILE="${PROJECT_ROOT}/logs/additional_models.log"
MODELS_DIR="${PROJECT_ROOT}/models"

# Criar diretórios necessários
mkdir -p "$MODELS_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# Função para log detalhado
log_model() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Verificar conectividade com Ollama
check_ollama() {
    if ! curl -s "http://127.0.0.1:11434/api/tags" >/dev/null 2>&1; then
        log_model "Ollama não está respondendo na porta 11434"
        return 1
    fi
    return 0
}

# Obter lista de modelos instalados
get_installed_models() {
    ollama list 2>/dev/null | awk 'NR>1 {print $1}' | sort || echo ""
}

# Verificar se modelo já está instalado
is_model_installed() {
    local model="$1"
    local installed_models="$2"
    echo "$installed_models" | grep -q "^${model}$"
}

# Instalar modelo com progresso
install_model() {
    local model="$1"
    local category="$2"
    local description="$3"

    log_model "📥 [$category] Iniciando download: $model"
    log_model "   Descrição: $description"

    if ollama pull "$model" >> "$LOG_FILE" 2>&1; then
        success "✅ [$category] Modelo $model instalado com sucesso"
        return 0
    else
        error "❌ [$category] Falha ao instalar $model"
        return 1
    fi
}

# Modelos por categoria
get_models_by_category() {
    local category="$1"

    case "$category" in
        "coding")
            cat << 'EOF'
codellama:13b:Modelo avançado para geração de código
deepseek-coder:33b:Modelo especializado em programação
starcoder:15b:Modelo treinado em código de alta qualidade
codeqwen:7b:Modelo de código da Alibaba
EOF
            ;;
        "creative")
            cat << 'EOF'
llama3:70b:Modelo conversacional avançado
mixtral:8x7b:Modelo de mistura de especialistas
nous-hermes2:10.7b:Modelo fino-sintonizado
yarn-mistral:7b:Modelo com memória expandida
EOF
            ;;
        "multilingual")
            cat << 'EOF'
qwen2:72b:Modelo multilíngue avançado
gemma2:27b:Modelo do Google com suporte multilíngue
bloom:7b:Modelo multilíngue da BigScience
m2m100:1.2b:Modelo de tradução da Meta
EOF
            ;;
        "science")
            cat << 'EOF'
galactica:6.7b:Modelo especializado em ciência
meditron:7b:Modelo médico fino-sintonizado
biomistral:7b:Modelo biomédico
chemllm:7b:Modelo de química
EOF
            ;;
        "compact")
            cat << 'EOF'
phi-3:14b:Modelo compacto da Microsoft
gemma:7b:Modelo eficiente do Google
tinyllama:1.1b:Modelo ultracompacto
mobilellm:0.5b:Modelo otimizado para dispositivos móveis
EOF
            ;;
        *)
            error "Categoria desconhecida: $category"
            return 1
            ;;
    esac
}

# Instalar modelos por categoria
install_category() {
    local category="$1"

    log_model "=== INSTALANDO MODELOS: $category ==="

    if ! check_ollama; then
        error "Ollama não está disponível"
        return 1
    fi

    # Obter modelos já instalados
    local installed_models
    installed_models=$(get_installed_models)

    # Contadores
    local total_models=0
    local installed_count=0
    local skipped_count=0
    local failed_count=0

    # Processar modelos da categoria
    while IFS=':' read -r model description; do
        model=$(echo "$model" | xargs)
        description=$(echo "$description" | xargs)

        if [[ -z "$model" || "$model" == "#"* ]]; then
            continue
        fi

        ((total_models++))

        if is_model_installed "$model" "$installed_models"; then
            log_model "⏭️  [$category] Modelo $model já instalado - pulando"
            ((skipped_count++))
        else
            if install_model "$model" "$category" "$description"; then
                ((installed_count++))
            else
                ((failed_count++))
            fi
        fi
    done < <(get_models_by_category "$category")

    # Resumo da categoria
    log_model "=== RESUMO $category ==="
    log_model "Total processados: $total_models"
    log_model "✅ Instalados: $installed_count"
    log_model "⏭️  Já instalados: $skipped_count"
    log_model "❌ Falharam: $failed_count"

    return $failed_count
}

# Instalar todas as categorias
install_all_categories() {
    local categories=("coding" "creative" "multilingual" "science" "compact")
    local total_failed=0

    log_model "🚀 INICIANDO INSTALAÇÃO DE TODAS AS CATEGORIAS"

    for category in "${categories[@]}"; do
        if ! install_category "$category"; then
            ((total_failed++))
        fi
        echo
    done

    if [[ $total_failed -eq 0 ]]; then
        success "🎉 Todas as categorias instaladas com sucesso!"
    else
        warn "⚠️  $total_failed categorias com falhas"
    fi

    return $total_failed
}

# Listar categorias disponíveis
list_categories() {
    echo -e "${BOLD}${BLUE}CATEGORIAS DE MODELOS DISPONÍVEIS${NC}"
    echo -e "${BLUE}=====================================${NC}"
    echo
    echo -e "${CYAN}coding${NC}       - Modelos especializados em programação"
    echo -e "${CYAN}creative${NC}     - Modelos para tarefas criativas e conversação"
    echo -e "${CYAN}multilingual${NC} - Modelos com suporte multilíngue"
    echo -e "${CYAN}science${NC}      - Modelos científicos e especializados"
    echo -e "${CYAN}compact${NC}      - Modelos compactos e eficientes"
    echo
    echo -e "${GRAY}Use: $0 <categoria>${NC}"
}

# Processar argumentos
case "${1:-}" in
    "coding"|"creative"|"multilingual"|"science"|"compact")
        install_category "$1"
        ;;
    "all")
        install_all_categories
        ;;
    "list"|"categories")
        list_categories
        ;;
    "help"|"--help"|"-h"|"")
        cat << 'EOF'
📖 Instalador de Modelos Adicionais do Ollama

USO:
    ./install_additional_models.sh [CATEGORIA|COMANDO]

CATEGORIAS:
    coding       - Modelos para programação e desenvolvimento
    creative     - Modelos para tarefas criativas
    multilingual - Modelos multilíngues
    science      - Modelos científicos especializados
    compact      - Modelos compactos e eficientes

COMANDOS:
    all          - Instalar todas as categorias
    list         - Listar categorias disponíveis
    help         - Mostrar esta ajuda

EXEMPLOS:
    # Instalar modelos de programação
    ./install_additional_models.sh coding

    # Instalar todos os modelos adicionais
    ./install_additional_models.sh all

    # Listar categorias
    ./install_additional_models.sh list

LOG:
    Todos os logs são salvos em: logs/additional_models.log

NOTA:
    Este script instala modelos adicionais além dos essenciais.
    Use auto_download_models.sh para os modelos básicos.
EOF
        ;;
    *)
        error "Categoria ou comando inválido: $1"
        echo "Use '$0 help' para ver as opções disponíveis"
        exit 1
        ;;
esac
