#!/bin/bash

# Script para mostrar progresso dos downloads do Ollama

echo "📊 PROGRESSO DOS DOWNLOADS DO OLLAMA"
echo "===================================="

# Verifica se há processos de download ativos
download_pids=$(pgrep -f "ollama pull" || echo "")

if [ -n "$download_pids" ]; then
    echo "🔄 Downloads ativos:"
    for pid in $download_pids; do
        model=$(ps -p $pid -o cmd= | grep -o "ollama pull .*" | cut -d' ' -f3)
        echo "   • $model (PID: $pid)"
    done
    echo ""
else
    echo "✅ Nenhum download ativo no momento."
    echo ""
fi

# Mostra modelos já instalados
echo "📦 Modelos instalados:"
if command -v ollama &> /dev/null; then
    ollama list 2>/dev/null || echo "   Nenhum modelo encontrado ou Ollama não está rodando."
else
    echo "   Ollama não encontrado."
fi

echo ""
echo "💾 Espaço em disco:"
df -h ~ | tail -n 1 | awk '{print "   Home: " $4 " disponível de " $2}'

echo ""
echo "🔍 Verificar progresso em tempo real:"
echo "   watch -n 5 './scripts/ollama/show_progress.sh'"
