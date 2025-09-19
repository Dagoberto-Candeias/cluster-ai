#!/bin/bash

echo "=== Correção de Emergência para VSCode Freezing ==="

# Forçar parada completa do VSCode
echo "Forçando parada completa do VSCode..."
pkill -9 -f "code" || true
pkill -9 -f "vscode" || true
pkill -9 -f "electron" || true
sleep 3

# Backup das configurações atuais
echo "Fazendo backup das configurações..."
cp ~/.config/Code/User/settings.json ~/.config/Code/User/settings.json.backup.$(date +%Y%m%d_%H%M%S)

# Limpeza completa do cache
echo "Limpando cache completamente..."
rm -rf ~/.config/Code/Cache/*
rm -rf ~/.config/Code/CachedData/*
rm -rf ~/.config/Code/GPUCache/*
rm -rf ~/.config/Code/Code\ Cache/*
rm -rf ~/.vscode/extensions/*/cache 2>/dev/null || true

# Criar configurações mínimas de emergência
echo "Criando configurações mínimas de emergência..."
cat > ~/.config/Code/User/settings.json << 'EOF'
{
    "workbench.editor.limit.enabled": true,
    "workbench.editor.limit.value": 3,
    "editor.minimap.enabled": false,
    "files.watcherExclude": {
        "**/node_modules/**": true,
        "**/venv/**": true,
        "**/__pycache__/**": true,
        "**/*.pyc": true
    },
    "extensions.ignoreRecommendations": true,
    "workbench.enableExperiments": false,
    "telemetry.telemetryLevel": "off",
    "files.autoSave": "off",
    "terminal.integrated.enablePersistentSessions": false
}
EOF

# Desabilitar todas as extensões de IA
echo "Desabilitando extensões problemáticas..."
code --disable-extension codeium.codeium 2>/dev/null || true
code --disable-extension github.copilot 2>/dev/null || true
code --disable-extension github.copilot-chat 2>/dev/null || true
code --disable-extension sourcegraph.cody-ai 2>/dev/null || true
code --disable-extension google.geminicodeassist 2>/dev/null || true
code --disable-extension blackboxapp.blackboxagent 2>/dev/null || true

echo "Tentando iniciar VSCode com configurações mínimas..."
code --disable-gpu --disable-software-rasterizer --disable-extensions --no-sandbox &
sleep 5

# Verificar se iniciou
if pgrep -f "code" > /dev/null; then
    echo "✅ VSCode iniciado com sucesso!"
    echo "Para restaurar funcionalidades gradualmente:"
    echo "1. Reabilite extensões uma por vez"
    echo "2. Teste a performance após cada reabilitação"
    echo "3. Mantenha no máximo 2 extensões de IA ativas"
else
    echo "❌ VSCode ainda não iniciou. Tentando modo seguro..."
    code --disable-gpu --safe-mode &
    sleep 3
fi

echo "=== Correção de emergência aplicada ==="
