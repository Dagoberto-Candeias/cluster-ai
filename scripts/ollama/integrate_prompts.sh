#!/bin/bash

# Script para integrar prompts do Cluster-AI com modelos Ollama
# Cria system prompts compatíveis com Ollama, IDEs e OpenWebUI

set -e

echo "🤖 INTEGRAÇÃO DE PROMPTS COM OLLAMA"
echo "===================================="

# Diretório dos prompts
PROMPTS_DIR="docs/guides"
OLLAMA_PROMPTS_DIR="$HOME/.ollama/prompts"
IDE_PROMPTS_DIR="$HOME/.config/cluster-ai/prompts"

# Criar diretórios
mkdir -p "$OLLAMA_PROMPTS_DIR"
mkdir -p "$IDE_PROMPTS_DIR"

echo "📁 Criando diretórios de integração..."
echo "   Ollama: $OLLAMA_PROMPTS_DIR"
echo "   IDEs: $IDE_PROMPTS_DIR"
echo ""

# Função para extrair prompts de um arquivo markdown
extract_prompts() {
    local file="$1"
    local category="$2"

    echo "📄 Processando: $file"

    # Extrair seções de prompts usando awk
    awk '
    BEGIN { in_prompt = 0; in_code = 0; prompt_content = ""; prompt_title = "" }

    # Detectar título da seção
    /^### [0-9]+\./ {
        if (in_prompt && prompt_title != "" && prompt_content != "") {
            print prompt_title "|||" prompt_content
        }
        prompt_title = substr($0, index($0, ". ") + 2)
        in_prompt = 0
        in_code = 0
        prompt_content = ""
    }

    # Detectar início de seção de prompt
    /^\*\*Modelo\*\*:/ {
        in_prompt = 1
    }

    # Detectar abertura de bloco de código
    in_prompt && /^```/ && !in_code {
        in_code = 1
        next
    }

    # Detectar fechamento de bloco de código
    in_prompt && /^```/ && in_code {
        in_code = 0
        if (prompt_title != "" && prompt_content != "") {
            print prompt_title "|||" prompt_content
        }
        prompt_content = ""
        next
    }

    # Coletar conteúdo do prompt
    in_code {
        if ($0 !~ /^```/) {
            prompt_content = prompt_content $0 "\n"
        }
    }

    END {
        if (prompt_title != "" && prompt_content != "") {
            print prompt_title "|||" prompt_content
        }
    }
    ' "$file"
}

# Função para criar arquivo de system prompt para Ollama
create_ollama_prompt() {
    local title="$1"
    local content="$2"
    local category="$3"
    local filename=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_\|_$//g')

    # Criar arquivo de system prompt
    cat > "$OLLAMA_PROMPTS_DIR/${category}_${filename}.txt" << EOF
# System Prompt: $title
# Category: $category
# Generated for Cluster-AI
# Usage: ollama run <model> --system "$(cat $OLLAMA_PROMPTS_DIR/${category}_${filename}.txt)"

$content
EOF

    echo "   ✅ Criado: ${category}_${filename}.txt"
}

# Função para criar arquivo para IDEs
create_ide_prompt() {
    local title="$1"
    local content="$2"
    local category="$3"
    local filename=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g' | sed 's/__*/_/g' | sed 's/^_\|_$//g')

    # Criar arquivo JSON para IDEs
    cat > "$IDE_PROMPTS_DIR/${category}_${filename}.json" << EOF
{
  "name": "$title",
  "description": "Prompt especializado para $category - Cluster-AI",
  "category": "$category",
  "content": $(jq -Rs . <<< "$content"),
  "model_recommendations": {
    "chat": ["llama3.1:8b", "mistral:latest"],
    "coding": ["codellama:latest", "deepseek-coder-v2:16b"],
    "analysis": ["mixtral:latest", "llama3:70b"]
  },
  "temperature_suggestions": {
    "code_generation": 0.2,
    "analysis": 0.4,
    "creative": 0.7
  }
}
EOF

    echo "   ✅ Criado: ${category}_${filename}.json"
}

# Processar arquivos de prompts
echo "🔄 Extraindo prompts dos arquivos..."

# Lista de arquivos de prompts a processar
PROMPT_FILES=(
    "prompts_desenvolvedores_cluster_ai.md:desenvolvedores"
    "prompts_administradores_cluster_ai.md:administradores"
    "prompts_monitoramento_cluster_ai.md:monitoramento"
    "prompts_seguranca_cluster_ai.md:seguranca"
    "prompts_devops_cluster_ai.md:devops"
    "prompts_multimodais_rag_cluster_ai.md:multimodal"
    "prompts_estudantes_cluster_ai.md:estudantes"
    "prompts_professores_universitarios_cluster_ai.md:professores"
    "prompts_pesquisadores_cluster_ai.md:pesquisadores"
    "prompts_negocios_cluster_ai.md:negocios"
    "prompts_financeiro_cluster_ai.md:financeiro"
    "prompts_auditoria_cluster_ai.md:auditoria"
)

total_processed=0

for file_info in "${PROMPT_FILES[@]}"; do
    IFS=':' read -r filename category <<< "$file_info"
    filepath="$PROMPTS_DIR/$filename"

    if [ -f "$filepath" ]; then
        echo ""
        echo "📂 Processando categoria: $category"

        # Extrair prompts e processar
        while IFS='|||' read -r title content; do
            if [ -n "$title" ] && [ -n "$content" ]; then
                create_ollama_prompt "$title" "$content" "$category"
                create_ide_prompt "$title" "$content" "$category"
                ((total_processed++))
            fi
        done < <(extract_prompts "$filepath" "$category")
    else
        echo "   ⚠️  Arquivo não encontrado: $filepath"
    fi
done

echo ""
echo "🎉 INTEGRAÇÃO CONCLUÍDA!"
echo "========================"
echo ""
echo "📊 Estatísticas:"
echo "   • Prompts processados: $total_processed"
echo "   • Arquivos Ollama criados: $total_processed"
echo "   • Arquivos IDE criados: $total_processed"
echo ""
echo "📁 Localizações:"
echo "   • Ollama: $OLLAMA_PROMPTS_DIR"
echo "   • IDEs: $IDE_PROMPTS_DIR"
echo ""
echo "💡 Como usar:"
echo ""
echo "🔧 Com Ollama:"
echo "   ollama run llama3.1:8b --system \"\$(cat $OLLAMA_PROMPTS_DIR/desenvolvedores_diagnostico_de_problemas_de_instalacao.txt)\""
echo ""
echo "💻 Com IDEs:"
echo "   Os arquivos JSON podem ser importados em VSCode, PyCharm, etc."
echo ""
echo "🌐 Com OpenWebUI:"
echo "   1. Acesse: http://localhost:3000"
echo "   2. Vá em Settings > Personas"
echo "   3. Importe os arquivos JSON como personas"
echo ""
echo "📋 Lista de categorias disponíveis:"
for file_info in "${PROMPT_FILES[@]}"; do
    IFS=':' read -r filename category <<< "$file_info"
    echo "   • $category"
done
