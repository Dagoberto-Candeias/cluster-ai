#!/bin/bash

echo "=== Corrigindo VSCode Freezing ==="

# Parar processos do VSCode
echo "Parando processos do VSCode..."
pkill -f "code" || true
pkill -f "vscode" || true
sleep 2

# Limpar cache do VSCode
echo "Limpando cache do VSCode..."
rm -rf ~/.config/Code/Cache/*
rm -rf ~/.config/Code/CachedData/*
rm -rf ~/.config/Code/GPUCache/*
rm -rf ~/.vscode/extensions/*/cache 2>/dev/null || true

# Limpar configurações problemáticas do workspace
echo "Otimizando configurações do workspace..."
if [ -f "cluster-ai.code-workspace" ]; then
    sed -i 's/"workbench.editor.limit.value": 15/"workbench.editor.limit.value": 3/g' cluster-ai.code-workspace
fi

# Criar arquivo de configurações de performance
echo "Criando configurações de performance..."
mkdir -p ~/.config/Code/User

# Configurações já foram aplicadas via edit_file

echo "Reiniciando VSCode..."
code --disable-gpu --disable-software-rasterizer --disable-extensions &
sleep 3

echo "=== VSCode otimizado! ==="
echo "Se ainda houver problemas, execute:"
echo "code --disable-gpu --no-sandbox"
