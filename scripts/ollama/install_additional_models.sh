#!/bin/bash

# Script para instalar modelos adicionais do Ollama
# Organizado por categoria e tamanho

set -e

echo "🤖 INSTALADOR DE MODELOS ADICIONAIS DO OLLAMA"
echo "=============================================="
echo ""

# Verificar se Ollama está instalado
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama não está instalado!"
    echo "Instale primeiro: curl -fsSL https://ollama.com/install.sh | sh"
    exit 1
fi

# Verificar se o serviço está rodando
if ! pgrep -f "ollama serve" > /dev/null && ! systemctl is-active --quiet ollama; then
    echo "⚠️  Ollama não está rodando. Iniciando..."
    ollama serve &
    sleep 3
fi

echo "✅ Ollama está funcionando!"
echo ""

# Função para instalar modelo com verificação
install_model() {
    local model=$1
    local description=$2

    echo "📥 Baixando: $model"
    echo "   $description"

    if ollama list | grep -q "^$model"; then
        echo "   ✅ Já instalado, pulando..."
        return 0
    fi

    if ollama pull "$model"; then
        echo "   ✅ $model instalado com sucesso!"
    else
        echo "   ❌ Falha ao instalar $model"
        return 1
    fi
    echo ""
}

# Função para mostrar progresso
show_progress() {
    local current=$1
    local total=$2
    local model=$3
    echo "[$current/$total] Instalando $model..."
}

# Menu de seleção de categoria
echo "📋 CATEGORIAS DISPONÍVEIS:"
echo "=========================="
echo "1) 🗣️  Modelos de Chat/Conversa (Recomendado)"
echo "2) 💻 Modelos de Programação/Código"
echo "3) 👁️  Modelos Multimodais (Visão)"
echo "4) 🔍 Modelos de Embeddings"
echo "5) ⚡ Modelos Leves (CPU/Raspberry Pi)"
echo "6) 🧠 Modelos Avançados (Grandes)"
echo "7) 🎯 Pacote Completo (Todos os essenciais)"
echo "8) 📊 Ver modelos já instalados"
echo "9) 🔄 Atualizar modelos existentes"
echo "0) ❌ Sair"
echo ""

read -p "Escolha uma categoria (0-9): " choice

case $choice in
    1)
        echo ""
        echo "🗣️  INSTALANDO MODELOS DE CHAT/CONVERSA"
        echo "======================================"

        models=(
            "llama3.1:8b|Modelo LLaMA 3.1 otimizado para conversas"
            "llama3.2|Versão mais avançada do LLaMA 3"
            "phi3|Modelo Microsoft com excelente raciocínio"
            "phi4|Versão avançada do Phi com melhor inferência"
            "gemma2:9b|Modelo Google para conversas multi-turno"
            "qwen3|Modelo Alibaba com alta performance"
            "deepseek-chat|Modelo técnico especializado da DeepSeek"
        )

        total=${#models[@]}
        current=1

        for model_info in "${models[@]}"; do
            IFS='|' read -r model desc <<< "$model_info"
            show_progress $current $total "$model"
            install_model "$model" "$desc"
            ((current++))
        done
        ;;

    2)
        echo ""
        echo "💻 INSTALANDO MODELOS DE PROGRAMAÇÃO"
        echo "==================================="

        models=(
            "deepseek-coder-v2:16b|Melhor para desenvolvimento (128K contexto)"
            "codellama-7b|Versão leve do CodeLlama"
            "starcoder2:7b|Excelente para autocomplete em IDEs"
            "qwen2.5-coder:1.5b|Modelo leve otimizado para CPU"
            "deepseek-coder|Versão compacta e rápida"
        )

        total=${#models[@]}
        current=1

        for model_info in "${models[@]}"; do
            IFS='|' read -r model desc <<< "$model_info"
            show_progress $current $total "$model"
            install_model "$model" "$desc"
            ((current++))
        done
        ;;

    3)
        echo ""
        echo "👁️  INSTALANDO MODELOS MULTIMODAIS"
        echo "=================================="

        models=(
            "llava|Análise de imagens + conversação"
            "qwen2-vl|Multimodal avançado da Alibaba"
            "minicpm-v|Modelo compacto para visão"
            "codegemma|Código + análise visual"
        )

        total=${#models[@]}
        current=1

        for model_info in "${models[@]}"; do
            IFS='|' read -r model desc <<< "$model_info"
            show_progress $current $total "$model"
            install_model "$model" "$desc"
            ((current++))
        done
        ;;

    4)
        echo ""
        echo "🔍 INSTALANDO MODELOS DE EMBEDDINGS"
        echo "==================================="

        models=(
            "nomic-embed-text|Busca semântica otimizada"
            "text-embedding-3-small|Embeddings leves da OpenAI"
            "gemma-embed|Embeddings do Google"
            "mistral-embed|Embeddings do Mistral"
        )

        total=${#models[@]}
        current=1

        for model_info in "${models[@]}"; do
            IFS='|' read -r model desc <<< "$model_info"
            show_progress $current $total "$model"
            install_model "$model" "$desc"
            ((current++))
        done
        ;;

    5)
        echo ""
        echo "⚡ INSTALANDO MODELOS LEVES"
        echo "==========================="

        models=(
            "tinyllama:1b|Perfeito para Raspberry Pi"
            "phi3|Otimizado para laptops/CPU"
            "qwen2.5-coder:1.5b|Leve e eficiente"
        )

        total=${#models[@]}
        current=1

        for model_info in "${models[@]}"; do
            IFS='|' read -r model desc <<< "$model_info"
            show_progress $current $total "$model"
            install_model "$model" "$desc"
            ((current++))
        done
        ;;

    6)
        echo ""
        echo "🧠 INSTALANDO MODELOS AVANÇADOS"
        echo "==============================="

        echo "⚠️  ATENÇÃO: Estes modelos são muito grandes!"
        echo "   Certifique-se de ter espaço em disco suficiente."
        read -p "Continuar? (s/N): " confirm

        if [[ $confirm =~ ^[Ss]$ ]]; then
            models=(
                "llama3:70b|Modelo LLaMA 3 grande (70B parâmetros)"
                "codellama-34b|CodeLlama de alta precisão"
                "qwen2.5-coder:32b|Modelo de código muito grande"
                "gemma2:27b|Gemma multimodal grande"
            )

            total=${#models[@]}
            current=1

            for model_info in "${models[@]}"; do
                IFS='|' read -r model desc <<< "$model_info"
                show_progress $current $total "$model"
                install_model "$model" "$desc"
                ((current++))
            done
        else
            echo "Instalação cancelada."
        fi
        ;;

    7)
        echo ""
        echo "🎯 INSTALANDO PACOTE COMPLETO"
        echo "============================="

        echo "📦 Este pacote inclui os melhores modelos de cada categoria:"
        echo "   • 1 Chat: llama3.1:8b"
        echo "   • 1 Código: deepseek-coder-v2:16b"
        echo "   • 1 Visão: llava"
        echo "   • 1 Embedding: nomic-embed-text"
        echo ""

        read -p "Instalar pacote completo? (s/N): " confirm

        if [[ $confirm =~ ^[Ss]$ ]]; then
            models=(
                "llama3.1:8b|Melhor equilíbrio geral para conversas"
                "deepseek-coder-v2:16b|Melhor para desenvolvimento"
                "llava|Análise de imagens + chat"
                "nomic-embed-text|Busca semântica eficiente"
            )

            total=${#models[@]}
            current=1

            for model_info in "${models[@]}"; do
                IFS='|' read -r model desc <<< "$model_info"
                show_progress $current $total "$model"
                install_model "$model" "$desc"
                ((current++))
            done
        else
            echo "Instalação cancelada."
        fi
        ;;

    8)
        echo ""
        echo "📊 MODELOS JÁ INSTALADOS"
        echo "========================"
        ollama list
        echo ""
        echo "💾 Espaço usado: $(du -sh ~/.ollama 2>/dev/null || echo 'N/A')"
        ;;

    9)
        echo ""
        echo "🔄 ATUALIZANDO MODELOS EXISTENTES"
        echo "================================="

        echo "Atualizando todos os modelos instalados..."
        ollama pull --all
        echo "✅ Todos os modelos foram atualizados!"
        ;;

    0)
        echo "❌ Saindo..."
        exit 0
        ;;

    *)
        echo "❌ Opção inválida!"
        exit 1
        ;;
esac

echo ""
echo "🎉 INSTALAÇÃO CONCLUÍDA!"
echo "========================"
echo ""
echo "📊 Resumo dos modelos instalados:"
ollama list
echo ""
echo "💡 DICAS DE USO:"
echo "================"
echo "• Execute: ollama run <nome-do-modelo>"
echo "• Liste modelos: ollama list"
echo "• Remova modelo: ollama rm <nome-do-modelo>"
echo "• Veja info: ollama show <nome-do-modelo>"
echo ""
echo "🔧 Para usar no Cluster AI:"
echo "• Os modelos ficam disponíveis automaticamente"
echo "• Acesse via OpenWebUI ou API do Ollama"
echo "• Porta padrão: 11434"
