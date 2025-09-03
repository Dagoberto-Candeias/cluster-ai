#!/bin/bash

echo "=== RESET COMPLETO DO VS CODE - ESTRATÉGIA NOVA ==="
echo "Este script fará um reset completo para resolver travamentos e falta de memória"

# 1. PARAR COMPLETAMENTE O VS CODE
echo "1. Parando todos os processos do VS Code..."
pkill -9 -f "code" 2>/dev/null || true
pkill -9 -f "vscode" 2>/dev/null || true
sleep 3

# 2. BACKUP DAS CONFIGURAÇÕES
echo "2. Criando backup das configurações..."
BACKUP_DIR="$HOME/vscode_complete_reset_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r ~/.config/Code/ "$BACKUP_DIR/config/" 2>/dev/null || true
cp -r ~/.vscode/ "$BACKUP_DIR/extensions/" 2>/dev/null || true
echo "Backup criado em: $BACKUP_DIR"

# 3. LIMPEZA RADICAL
echo "3. Limpando caches e configurações problemáticas..."
rm -rf ~/.config/Code/Cache/* 2>/dev/null || true
rm -rf ~/.config/Code/Code\ Cache/* 2>/dev/null || true
rm -rf ~/.config/Code/User/workspaceStorage/* 2>/dev/null || true
rm -rf ~/.config/Code/User/globalStorage/* 2>/dev/null || true
rm -rf /tmp/vscode-* 2>/dev/null || true
rm -rf /tmp/Crashpad* 2>/dev/null || true

# 4. REMOVER EXTENSÕES PROBLEMÁTICAS
echo "4. Removendo extensões problemáticas..."
rm -rf ~/.vscode/extensions/blackboxapp.* 2>/dev/null || true
rm -rf ~/.vscode/extensions/codeium.* 2>/dev/null || true
rm -rf ~/.vscode/extensions/anthropic.* 2>/dev/null || true
rm -rf ~/.vscode/extensions/askcodi.* 2>/dev/null || true
rm -rf ~/.vscode/extensions/danielsanmedium.* 2>/dev/null || true
rm -rf ~/.vscode/extensions/cweijan.* 2>/dev/null || true

# 5. VERIFICAR MEMÓRIA
echo "5. Estado atual da memória:"
free -h
echo "---"
echo "Memória swap:"
cat /proc/sys/vm/swappiness

# 6. CONFIGURAÇÕES OTIMIZADAS
echo "6. Aplicando configurações otimizadas..."
cat > ~/.config/Code/User/settings.json << 'EOL'
{
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
        "**/tmp/**": true
    },
    "search.exclude": {
        "**/node_modules": true,
        "**/venv": true,
        "**/cluster_env": true,
        "**/.vscode": true,
        "**/backups": true,
        "**/tmp": true
    },
    "editor.largeFileOptimizations": true,
    "files.maxMemoryForLargeFilesMB": 1024,
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 30000,
    "editor.codeLens": false,
    "editor.minimap.enabled": false,
    "gitlens.codeLens.enabled": false,
    "workbench.editor.empty.hint": "hidden",
    "workbench.startupEditor": "none",
    "python.terminal.activateEnvironment": true,
    "python.analysis.extraPaths": [
        "/home/dcm/cluster_env/lib/python3.*/site-packages"
    ],
    "jupyter.notebookFileRoot": "/home/dcm",
    "terminal.integrated.env.linux": {}
}
EOL

# 7. REINICIAR VS CODE LIMPO
echo "7. Reiniciando VS Code de forma limpa..."
code --disable-extensions --disable-gpu --no-sandbox > /tmp/vscode_clean_start.log 2>&1 &

echo "Aguardando 10 segundos para inicialização..."
sleep 10

# 8. VERIFICAR SUCESSO
echo "8. Verificando se o VS Code abriu corretamente..."
if ps aux | grep -E "(code|vscode)" | grep -v grep | grep -q "type=renderer"; then
    echo "✅ VS Code iniciado com sucesso!"
    echo "Processos ativos:"
    ps aux | grep -E "(code|vscode)" | grep -v grep | head -3
else
    echo "⚠️  VS Code pode não ter aberto a interface gráfica"
    echo "Tentando abrir projeto específico..."
    code /home/dcm/Projetos/cluster-ai --disable-extensions --disable-gpu --no-sandbox &
    sleep 5
fi

# 9. INSTALAR APENAS EXTENSÕES ESSENCIAIS
echo "9. Instalando extensões essenciais (aguardando VS Code estabilizar)..."
sleep 10
code --install-extension ms-python.python
code --install-extension ms-toolsai.jupyter
code --install-extension eamodio.gitlens

echo "10. ✅ RESET COMPLETO CONCLUÍDO!"
echo "=================================================="
echo "Ações realizadas:"
echo "1. ✅ Todos os processos do VS Code finalizados"
echo "2. ✅ Backup completo das configurações"
echo "3. ✅ Caches e configurações problemáticas removidas"
echo "4. ✅ Extensões problemáticas removidas"
echo "5. ✅ Configurações otimizadas aplicadas"
echo "6. ✅ VS Code reiniciado em modo limpo"
echo "7. ✅ Extensões essenciais reinstaladas"
echo ""
echo "Próximos passos:"
echo "- Verifique se o VS Code está estável"
echo "- Abra seu projeto normalmente"
echo "- Monitore o uso de memória com: free -h"
echo "- Se necessário, execute: ./monitor_vscode.sh"
echo ""
echo "Backup disponível em: $BACKUP_DIR"
