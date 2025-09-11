#!/bin/bash
echo "✅ Verificando saúde do Cluster-AI..."

# Verificar Dask Scheduler
if ss -tlnp | grep -q ':8786'; then
    echo "✅ Dask Scheduler (porta 8786) - ATIVO"
else
    echo "❌ Dask Scheduler (porta 8786) - INATIVO"
fi

# Verificar Dask Dashboard
if curl -s --max-time 5 http://localhost:8787/status > /dev/null 2>&1; then
    echo "✅ Dask Dashboard (porta 8787) - ATIVO"
else
    echo "❌ Dask Dashboard (porta 8787) - INATIVO"
fi

# Verificar Ollama API
if curl -s --max-time 5 http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Ollama API (porta 11434) - ATIVO"
else
    echo "❌ Ollama API (porta 11434) - INATIVO"
fi

# Verificar OpenWebUI
if curl -s --max-time 5 http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ OpenWebUI (porta 3000) - ATIVO"
else
    echo "❌ OpenWebUI (porta 3000) - INATIVO"
fi

echo ""
echo "Para iniciar serviços inativos:"
echo "- Dask: ./start_cluster.sh"
echo "- Ollama: ollama serve"
echo "- OpenWebUI: docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main"
