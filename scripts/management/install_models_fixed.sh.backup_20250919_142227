#!/bin/bash
#
# 🧠 Script Interativo para Instalar Modelos do Ollama - Cluster AI
# Instala uma lista pré-definida de modelos, focando nos menores e mais eficientes.
#

set -euo pipefail

# --- Carregar Funções Comuns ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# --- Variáveis de Cor ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# --- Lista de Modelos Disponíveis para Instalação ---
# Modelos organizados por categoria com descrições detalhadas
# Formato: "nome:tamanho" # (tamanho) Descrição detalhada + casos de uso

# 🗣️ MODELOS DE CONVERSAÇÃO (Foco em diálogo natural)
CONVERSATION_MODELS=(
    "phi-3:3.8b"        # (2.3 GB) Modelo compacto da Microsoft, ótimo para conversação geral e tarefas leves
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

# CATEGORIAS DISPONÍVEIS
CATEGORIAS_DISPONIVEIS=(
    "🗣️ Conversação"
    "💻 Programação"
    "📊 Análise"
    "🎨 Criativo"
    "🌍 Multilíngue"
    "🧪 Leve"
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
