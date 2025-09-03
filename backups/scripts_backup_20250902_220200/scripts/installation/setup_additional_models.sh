
#!/bin/bash
# Script para instalar modelos adicionais no Ollama para o Cluster AI

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

# Lista de modelos a instalar
declare -A MODELS=(
    # Modelos de conversação geral
    ["llama3.2:3b"]="Modelo leve para tarefas gerais"
    ["llama3.1:8b"]="Modelo balanceado para conversação"
    ["mistral:7b"]="Modelo eficiente da Mistral AI"
    ["phi3:3.8b"]="Modelo compacto da Microsoft"

    # Modelos especializados
    ["codellama:7b"]="Especializado em geração de código"
    ["codellama:13b"]="Versão maior para código complexo"
    ["deepseek-coder:6.7b"]="Modelo otimizado para programação"

    # Modelos para tarefas específicas
    ["llava:7b"]="Modelo multimodal (visão + texto)"
    ["nomic-embed-text"]="Modelo para embeddings de texto"
    ["mxbai-embed-large"]="Modelo de embeddings da MixedBread"

    # Modelos em português
    ["portuguese-llm:7b"]="Modelo treinado em português"
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

