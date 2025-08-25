#!/bin/bash

echo "=== Reinício Limpo do VS Code ==="

# Matar todos os processos do VS Code
echo "Parando todos os processos do VS Code..."
pkill -f "code" || true
pkill -f "vscode" || true
sleep 2

# Verificar se ainda há processos
if ps aux | grep -E "(code|vscode)" | grep -v grep; then
    echo "Forçando parada dos processos remanescentes..."
    pkill -9 -f "code" || true
    pkill -9 -f "vscode" || true
    sleep 1
fi

# Limpar cache temporário
echo "Limpando cache temporário..."
rm -rf /tmp/vscode-* 2>/dev/null || true
rm -rf /tmp/Crashpad* 2>/dev/null || true

# Verificar memória livre
echo "Memória livre antes do reinício:"
free -h

# Reiniciar VS Code de forma limpa
echo "Reiniciando VS Code..."
code --disable-extensions --disable-gpu > /dev/null 2>&1 &

echo "Aguardando inicialização..."
sleep 5

# Verificar se está rodando
if ps aux | grep -E "(code|vscode)" | grep -v grep; then
    echo "✅ VS Code reiniciado com sucesso!"
    echo "Processos ativos:"
    ps aux | grep -E "(code|vscode)" | grep -v grep | head -5
else
    echo "❌ Falha ao reiniciar VS Code"
    exit 1
fi

echo "=== Reinício concluído! ==="
echo "Agora você pode abrir seu projeto normalmente."
