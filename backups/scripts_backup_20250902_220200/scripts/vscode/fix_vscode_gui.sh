#!/bin/bash

echo "=== Corrigindo Problema de Interface do VS Code ==="

# Parar todos os processos do VS Code
echo "Parando VS Code..."
pkill -f "code" 2>/dev/null || true
pkill -f "vscode" 2>/dev/null || true
sleep 3

# Forçar parada se necessário
if ps aux | grep -E "(code|vscode)" | grep -v grep; then
    echo "Forçando parada de processos remanescentes..."
    pkill -9 -f "code" 2>/dev/null || true
    pkill -9 -f "vscode" 2>/dev/null || true
    sleep 2
fi

# Limpar caches problemáticos
echo "Limpando caches..."
rm -rf /tmp/vscode-* 2>/dev/null || true
rm -rf /tmp/Crashpad* 2>/dev/null || true
rm -rf ~/.config/Code/Cache/* 2>/dev/null || true
rm -rf ~/.config/Code/Code\ Cache/* 2>/dev/null || true

# Verificar e configurar display
echo "Configurando display..."
export DISPLAY=:0
xhost +local: > /dev/null 2>&1 || echo "Display configurado"

# Verificar memória
echo "Estado da memória:"
free -h

# Reiniciar VS Code com configurações específicas para interface
echo "Reiniciando VS Code com configurações de interface..."
code --disable-extensions --disable-gpu --no-sandbox > /tmp/vscode_start.log 2>&1 &

echo "Aguardando inicialização (15 segundos)..."
sleep 15

# Verificar se abriu corretamente
if ps aux | grep -E "(code|vscode)" | grep -v grep | grep -q "type=renderer"; then
    echo "✅ VS Code iniciado com interface gráfica!"
    echo "Processos de renderização ativos:"
    ps aux | grep -E "(code|vscode)" | grep -v grep | grep "type=renderer"
else
    echo "❌ Problema persistente com interface gráfica"
    echo "Logs de inicialização:"
    cat /tmp/vscode_start.log 2>/dev/null || echo "Nenhum log disponível"
    echo "Tentando método alternativo..."
    
    # Método alternativo: abrir diretamente o arquivo
    code /home/dcm/Projetos/cluster-ai --disable-extensions --disable-gpu --no-sandbox &
    sleep 10
fi

echo "=== Correção concluída! ==="
echo "Se ainda não abrir, verifique:"
echo "1. Permissões do X11: xhost +local:"
echo "2. Configuração do display: echo \$DISPLAY"
echo "3. Logs em: /tmp/vscode_start.log"
