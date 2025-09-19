#!/bin/bash

echo "🚀 Demonstração Completa do Sistema Cluster AI"
echo "=============================================="

# Ativar ambiente virtual
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    echo "✅ Ambiente virtual ativado"
elif [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
    echo "✅ Ambiente virtual ativado"
else
    echo "⚠️ Ambiente virtual não encontrado"
fi

echo ""

# Verificar saúde do sistema
echo "📊 Verificando saúde do sistema..."
bash scripts/health_check.sh

echo ""

# Testar Dask
echo "🔢 Testando computação distribuída com Dask..."
python3 -c "
from dask.distributed import Client
import dask.array as da
import time

print('Conectando ao cluster Dask...')
try:
    client = Client('tcp://localhost:8786', timeout=10)
    print('✅ Conectado ao scheduler Dask')

    print('Executando computação distribuída...')
    x = da.random.random((1000, 1000), chunks=(500, 500))
    y = (x + x.T).sum()
    result = y.compute()
    print(f'✅ Resultado da computação: {result:.2f}')

    client.close()
    print('✅ Teste Dask concluído com sucesso')
except Exception as e:
    print(f'❌ Erro no teste Dask: {e}')
"

echo ""

# Testar Ollama
echo "🧠 Testando modelos IA com Ollama..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "Modelos disponíveis:"
    curl -s http://localhost:11434/api/tags | python3 -c "
import sys, json
data = json.load(sys.stdin)
if 'models' in data:
    for model in data['models']:
        print(f'  - {model[\"name\"]} ({model[\"size\"]} bytes)')
else:
    print('  Nenhum modelo encontrado')
"

    # Testar um modelo simples se disponível
    if curl -s http://localhost:11434/api/tags | grep -q 'llama'; then
        echo "Testando geração de texto..."
        curl -s -X POST http://localhost:11434/api/generate \
             -H 'Content-Type: application/json' \
             -d '{"model": "llama3:8b", "prompt": "Olá! Você é uma IA útil.", "stream": false}' | \
             python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    response = data.get('response', '')[:100]
    print(f'Resposta: {response}...')
    print('✅ Teste Ollama concluído')
except:
    print('❌ Erro ao testar Ollama')
"
    fi
else
    echo "❌ Ollama não está respondendo"
fi

echo ""

# Informações dos serviços
echo "🌐 Serviços disponíveis:"
echo "  - Dask Dashboard: http://localhost:8787"
echo "  - OpenWebUI: http://localhost:3000"
echo "  - Ollama API: http://localhost:11434"

echo ""

echo "🎉 Demonstração concluída!"
echo "Para usar o sistema:"
echo "1. Acesse o OpenWebUI para interagir com IA"
echo "2. Use o Dask Dashboard para monitorar computações"
echo "3. Conecte suas aplicações aos endpoints da API"
