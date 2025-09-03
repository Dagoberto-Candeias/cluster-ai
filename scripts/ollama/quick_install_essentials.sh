#!/bin/bash

# Instalação rápida dos modelos essenciais do Ollama
# Modelos mais importantes para começar

set -e

echo "🚀 INSTALAÇÃO RÁPIDA - MODELOS ESSENCIAIS"
echo "========================================="
echo ""

# Verificar Ollama
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama não encontrado. Instale primeiro:"
    echo "curl -fsSL https://ollama.com/install.sh | sh"
    exit 1
fi

# Modelos essenciais (ordenados por prioridade)
ESSENTIAL_MODELS=(
    "llama3.1:8b"      # Melhor para conversas gerais
    "deepseek-coder-v2:16b"  # Melhor para desenvolvimento
    "llava"            # Visão computacional
    "nomic-embed-text" # Embeddings para busca
    "phi3"             # Modelo leve e rápido
)

echo "📦 Modelos que serão instalados:"
echo "================================="
for i in "${!ESSENTIAL_MODELS[@]}"; do
    model="${ESSENTIAL_MODELS[$i]}"
    case $model in
        "llama3.1:8b") desc="Chat geral - Melhor equilíbrio" ;;
        "deepseek-coder-v2:16b") desc="Programação - Melhor para devs" ;;
        "llava") desc="Visão - Análise de imagens" ;;
        "nomic-embed-text") desc="Embeddings - Busca semântica" ;;
        "phi3") desc="Leve - Raciocínio lógico" ;;
        *) desc="Modelo adicional" ;;
    esac
    echo "$((i+1)). $model - $desc"
done
echo ""

read -p "Continuar com a instalação? (s/N): " confirm
if [[ ! $confirm =~ ^[SsYy]$ ]]; then
    echo "❌ Instalação cancelada."
    exit 0
fi

echo ""
echo "📥 Iniciando downloads..."
echo "========================"

total=${#ESSENTIAL_MODELS[@]}
current=1

for model in "${ESSENTIAL_MODELS[@]}"; do
    echo ""
    echo "[$current/$total] Instalando: $model"

    if ollama list | grep -q "^$model"; then
        echo "   ✅ Já instalado, pulando..."
    else
        echo "   ⏳ Baixando $model... (pode demorar alguns minutos)"
        echo "   📊 Progresso: Iniciando download..."

        # Executa o pull em background para capturar saída
        ollama pull "$model" > /tmp/ollama_progress.log 2>&1 &
        pull_pid=$!

        # Monitora o progresso
        while kill -0 $pull_pid 2>/dev/null; do
            if [ -f /tmp/ollama_progress.log ]; then
                # Mostra as últimas linhas do log para progresso
                tail -n 3 /tmp/ollama_progress.log | grep -E "(pulling|verifying|writing|done)" | tail -n 1
            fi
            sleep 2
        done

        # Verifica se foi bem-sucedido
        wait $pull_pid
        if [ $? -eq 0 ]; then
            echo "   ✅ $model instalado com sucesso!"
        else
            echo "   ❌ Falha ao instalar $model"
            cat /tmp/ollama_progress.log
        fi

        # Limpa arquivo temporário
        rm -f /tmp/ollama_progress.log
    fi

    ((current++))
done

echo ""
echo "🎉 INSTALAÇÃO CONCLUÍDA!"
echo "========================"
echo ""
echo "📊 Modelos instalados:"
ollama list
echo ""
echo "💡 PRÓXIMOS PASSOS:"
echo "==================="
echo "1. Teste os modelos:"
echo "   ollama run llama3.1:8b"
echo ""
echo "2. Acesse via OpenWebUI:"
echo "   http://localhost:3000"
echo ""
echo "3. Use a API:"
echo "   curl http://localhost:11434/api/generate -d '{\"model\":\"llama3.1:8b\",\"prompt\":\"Olá!\"}'"
echo ""
echo "4. Para mais modelos, execute:"
echo "   ./scripts/ollama/install_additional_models.sh"
