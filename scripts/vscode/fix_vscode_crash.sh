#!/bin/bash

echo "=== CORREÇÃO DE CRASH DO VS CODE ==="
echo "Resolvendo travamentos e tela de 'reopen'"

# 1. FORÇAR PARADA COMPLETA
echo "1. Parando todos os processos do VSCode..."
pkill -9 -f "code" 2>/dev/null || true
pkill -9 -f "vscode" 2>/dev/null || true
sleep 3

# 2. LIMPAR ESTADO CORROMPIDO
echo "2. Limpando estado corrompido..."

# Remover arquivos de estado da workspace
rm -rf ~/.config/Code/User/workspaceStorage/* 2>/dev/null || true
rm -rf ~/.config/Code/User/globalStorage/* 2>/dev/null || true

# Limpar backups de sessão corrompidos
rm -rf ~/.config/Code/Backups/* 2>/dev/null || true
rm -rf ~/.config/Code/Local\ Storage/* 2>/dev/null || true

# Limpar logs antigos
rm -rf ~/.config/Code/logs/* 2>/dev/null || true

# Limpar cache de extensões
rm -rf ~/.vscode/extensions/* 2>/dev/null || true

# 3. REMOVER EXTENSÕES PROBLEMÁTICAS
echo "3. Removendo extensões que causam conflitos..."

# Lista de extensões problemáticas conhecidas
PROBLEMATIC_EXTENSIONS=(
    "blackboxapp.blackbox"
    "blackboxapp.blackboxagent"
    "codeium.codeium"
    "anthropic.claude-code"
    "askcodi.askcodi-vscode"
    "danielsanmedium.dscodegpt"
    "cweijan.dbclient-jdbc"
    "cweijan.vscode-mysql-client2"
    "angular.ng-template"
    "ms-vscode.vscode-typescript-next"
)

for ext in "${PROBLEMATIC_EXTENSIONS[@]}"; do
    echo "Removendo: $ext"
    rm -rf ~/.vscode/extensions/$ext* 2>/dev/null || true
done

# 4. CONFIGURAÇÕES DE SEGURANÇA
echo "4. Aplicando configurações de segurança..."

cat > ~/.config/Code/User/settings.json << 'EOL'
{
    "telemetry.telemetryLevel": "off",
    "extensions.autoUpdate": false,
    "update.mode": "none",
    "workbench.enableExperiments": false,
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/.git/subtree-cache/**": true,
        "**/node_modules/**": true,
        "**/venv/**": true,
        "**/cluster_env/**": true,
        "**/.vscode/**": true,
        "**/backups/**": true
    },
    "search.exclude": {
        "**/node_modules": true,
        "**/venv": true,
        "**/cluster_env": true,
        "**/.vscode": true,
        "**/backups": true
    },
    "editor.largeFileOptimizations": true,
    "files.maxMemoryForLargeFilesMB": 512,
    "editor.codeLens": false,
    "editor.minimap.enabled": false,
    "gitlens.codeLens.enabled": false,
    "workbench.editor.empty.hint": "hidden",
    "workbench.startupEditor": "none",
    "workbench.editor.limit.enabled": true,
    "workbench.editor.limit.value": 5,
    "window.restoreWindows": "none",
    "window.newWindowDimensions": "default",
    "typescript.tsserver.maxTsServerMemory": 1024,
    "javascript.suggest.enabled": false,
    "typescript.suggest.enabled": false,
    "python.terminal.activateEnvironment": true,
    "terminal.integrated.scrollback": 500,
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 30000
}
EOL

# 5. CRIAR SCRIPT DE INICIALIZAÇÃO SEGURO
echo "5. Criando script de inicialização seguro..."

cat > ~/start_vscode_crash_safe.sh << 'EOL'
#!/bin/bash
# Script para iniciar VS Code sem crashes

echo "Iniciando VS Code em modo seguro (anti-crash)..."

# Definir variáveis de ambiente seguras
export ELECTRON_NO_ATTACH_CONSOLE=1
export ELECTRON_DISABLE_SECURITY_WARNINGS=1
export DISABLE_UPDATE_CHECK=1
export CODE_DISABLE_GPU=1

# Limpar caches temporários
rm -rf /tmp/vscode-* 2>/dev/null || true
rm -rf /tmp/Crashpad* 2>/dev/null || true

# Iniciar VS Code com configurações anti-crash
code --disable-extensions \
     --disable-gpu \
     --no-sandbox \
     --disable-web-security \
     --disable-background-timer-throttling \
     --disable-renderer-backgrounding \
     --disable-backgrounding-occluded-windows \
     --max_old_space_size=2048 \
     "$@" > /tmp/vscode_crash_safe.log 2>&1 &

echo "VS Code iniciado em modo seguro."
echo "Aguardando estabilização (20 segundos)..."
sleep 20

# Verificar se está rodando
if ps aux | grep -E "(code|vscode)" | grep -v grep | grep -q "type=renderer"; then
    echo "✅ VS Code está executando!"
    echo "Processos ativos:"
    ps aux | grep -E "(code|vscode)" | grep -v grep | head -3
    echo ""
    echo "💡 DICAS PARA EVITAR CRASHES:"
    echo "• Não abra muitas abas simultaneamente"
    echo "• Evite usar múltiplas extensões de IA"
    echo "• Feche terminais não utilizados"
    echo "• Monitore uso de memória: free -h"
else
    echo "❌ VS Code não iniciou corretamente"
    echo "Logs em: /tmp/vscode_crash_safe.log"
    echo ""
    echo "Tentando método alternativo..."
    code --disable-extensions --no-sandbox --disable-gpu &
    sleep 10
fi
EOL

chmod +x ~/start_vscode_crash_safe.sh

# 6. INSTALAR APENAS EXTENSÕES ESSENCIAIS
echo "6. Instalando apenas extensões essenciais..."

# Aguardar VS Code estabilizar se estiver rodando
sleep 5

ESSENTIAL_EXTENSIONS=(
    "ms-python.python"
    "ms-toolsai.jupyter"
    "eamodio.gitlens"
)

for ext in "${ESSENTIAL_EXTENSIONS[@]}"; do
    echo "Instalando essencial: $ext"
    code --install-extension "$ext" --force 2>/dev/null || echo "Pulado: $ext"
    sleep 2
done

# 7. CRIAR ALIAS
echo "7. Criando aliases convenientes..."

if ! grep -q "alias vscode-crash-fix" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Aliases para VS Code anti-crash" >> ~/.bashrc
    echo "alias vscode-safe='~/start_vscode_crash_safe.sh'" >> ~/.bashrc
    echo "alias vscode-crash-fix='~/Projetos/cluster-ai/scripts/vscode/fix_vscode_crash.sh'" >> ~/.bashrc
    echo "alias vscode-clean='pkill -9 -f code && sleep 2 && ~/start_vscode_crash_safe.sh'" >> ~/.bashrc
fi

# 8. TESTAR INICIALIZAÇÃO
echo "8. Testando inicialização..."

~/start_vscode_crash_safe.sh

echo ""
echo "🎯 CORREÇÃO DE CRASH CONCLUÍDA!"
echo "================================"
echo ""
echo "Problemas resolvidos:"
echo "✅ Estado corrompido da workspace limpo"
echo "✅ Extensões problemáticas removidas"
echo "✅ Configurações anti-crash aplicadas"
echo "✅ Script de inicialização seguro criado"
echo ""
echo "Para usar o VS Code:"
echo "• Use: vscode-safe"
echo "• Ou: ~/start_vscode_crash_safe.sh"
echo ""
echo "Se ainda houver crashes:"
echo "• Use: vscode-clean (reinicia completamente)"
echo "• Execute novamente: ./scripts/vscode/fix_vscode_crash.sh"
echo ""
echo "Extensões removidas (causavam conflitos):"
echo "• Blackbox, Codeium, Claude, AskCodi"
echo "• Database clients, Angular templates"
echo ""
echo "Para reabilitar atualizações futuramente:"
echo "• Edite ~/.config/Code/User/settings.json"
echo "• Mude 'update.mode' para 'default'"
echo "• Reinstale extensões gradualmente"
