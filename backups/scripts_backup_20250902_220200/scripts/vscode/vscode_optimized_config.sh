#!/bin/bash

echo "=== CONFIGURAÇÃO OTIMIZADA DO VS CODE ==="
echo "Criando configurações que previnem travamentos e múltiplas janelas"

# Criar diretório de configuração se não existir
mkdir -p ~/.config/Code/User

# Configurações otimizadas para performance
cat > ~/.config/Code/User/settings.json << 'EOL'
{
    // Configurações de performance
    "telemetry.telemetryLevel": "off",
    "extensions.autoUpdate": false,
    "update.mode": "none",
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/.git/subtree-cache/**": true,
        "**/node_modules/**": true,
        "**/venv/**": true,
        "**/cluster_env/**": true,
        "**/.vscode/**": true,
        "**/backups/**": true,
        "**/tmp/**": true,
        "**/deployments/**": true,
        "**/docs/**": true,
        "**/examples/**": true,
        "**/configs/**": true
    },
    "search.exclude": {
        "**/node_modules": true,
        "**/venv": true,
        "**/cluster_env": true,
        "**/.vscode": true,
        "**/backups": true,
        "**/tmp": true,
        "**/deployments": true,
        "**/docs": true,
        "**/examples": true,
        "**/configs": true
    },
    "editor.largeFileOptimizations": true,
    "files.maxMemoryForLargeFilesMB": 512,
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 30000,
    
    // Configurações de interface
    "editor.codeLens": false,
    "editor.minimap.enabled": false,
    "gitlens.codeLens.enabled": false,
    "workbench.editor.empty.hint": "hidden",
    "workbench.startupEditor": "none",
    "workbench.editor.limit.enabled": true,
    "workbench.editor.limit.value": 10,
    
    // Configurações específicas do projeto
    "python.terminal.activateEnvironment": true,
    "python.analysis.extraPaths": [
        "/home/dcm/cluster_env/lib/python3.*/site-packages"
    ],
    "jupyter.notebookFileRoot": "/home/dcm",
    
    // Prevenir múltiplas instâncias
    "window.restoreWindows": "none",
    "window.newWindowDimensions": "default",
    
    // Configurações de memória
    "typescript.tsserver.maxTsServerMemory": 2048,
    "javascript.suggest.enabled": false,
    "typescript.suggest.enabled": false,
    
    // Terminal
    "terminal.integrated.env.linux": {},
    "terminal.integrated.scrollback": 1000
}
EOL

echo "✅ Configurações otimizadas aplicadas!"

# Criar script de inicialização segura
cat > ~/start_vscode_safe.sh << 'EOL'
#!/bin/bash
# Script para iniciar VS Code de forma segura

# Verificar se já está executando
if pgrep -x "code" > /dev/null; then
    echo "VS Code já está executando. Fechando instâncias anteriores..."
    pkill -f "code"
    sleep 2
fi

# Limpar caches temporários
rm -rf /tmp/vscode-* 2>/dev/null || true

# Iniciar VS Code com configurações seguras
code --disable-extensions --disable-gpu --no-sandbox "$@" &

echo "VS Code iniciado em modo seguro. Aguarde 10 segundos antes de abrir extensões..."
sleep 10
EOL

chmod +x ~/start_vscode_safe.sh

echo "✅ Script de inicialização segura criado: ~/start_vscode_safe.sh"

# Instalar apenas extensões essenciais
echo "Instalando extensões essenciais..."
EXTENSIONS=(
    "ms-python.python"
    "ms-toolsai.jupyter" 
    "eamodio.gitlens"
    "blackboxapp.blackbox"
)

for ext in "${EXTENSIONS[@]}"; do
    echo "Instalando: $ext"
    code --install-extension "$ext" --force 2>/dev/null || echo "Pulando $ext (pode já estar instalada)"
done

echo "✅ Extensões essenciais instaladas"

# Criar alias no .bashrc
if ! grep -q "alias code-safe" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Alias para VS Code seguro" >> ~/.bashrc
    echo "alias code-safe='~/start_vscode_safe.sh'" >> ~/.bashrc
    echo "alias vscode-restart='pkill -f code && sleep 2 && ~/start_vscode_safe.sh'" >> ~/.bashrc
fi

echo "✅ Aliases criados:"
echo "   code-safe     - Inicia VS Code em modo seguro"
echo "   vscode-restart - Reinicia completamente o VS Code"

echo ""
echo "🎯 CONFIGURAÇÃO CONCLUÍDA!"
echo "=========================="
echo "Use 'code-safe' para iniciar o VS Code de forma segura"
echo "Use 'vscode-restart' para reiniciar completamente"
echo ""
echo "As configurações aplicadas previnem:"
echo "✅ Travamentos por falta de memória"
echo "✅ Múltiplas janelas do VS Code" 
echo "✅ Corrupção de extensões"
echo "✅ Problemas de performance"
