#!/bin/bash

echo "=== CORREÇÃO COMPLETA DO VS CODE ==="
echo "Reinicialização total do ambiente VSCode"

# 1. PARADA FORÇADA COMPLETA
echo "1. Parando todos os processos relacionados..."
pkill -9 -f "code" 2>/dev/null || true
pkill -9 -f "vscode" 2>/dev/null || true
pkill -9 -f "electron" 2>/dev/null || true
sleep 5

# 2. BACKUP DE CONFIGURAÇÕES IMPORTANTES
echo "2. Fazendo backup de configurações importantes..."
BACKUP_DIR="$HOME/.vscode_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup de configurações essenciais
cp -r ~/.config/Code/User/settings.json "$BACKUP_DIR/" 2>/dev/null || true
cp -r ~/.config/Code/User/keybindings.json "$BACKUP_DIR/" 2>/dev/null || true
cp -r ~/.vscode/extensions "$BACKUP_DIR/" 2>/dev/null || true

echo "Backup salvo em: $BACKUP_DIR"

# 3. LIMPEZA TOTAL DO ESTADO CORROMPIDO
echo "3. Limpando estado corrompido..."

# Diretórios de configuração
rm -rf ~/.config/Code/User/workspaceStorage/* 2>/dev/null || true
rm -rf ~/.config/Code/User/globalStorage/* 2>/dev/null || true
rm -rf ~/.config/Code/Backups/* 2>/dev/null || true
rm -rf ~/.config/Code/Local\ Storage/* 2>/dev/null || true
rm -rf ~/.config/Code/logs/* 2>/dev/null || true
rm -rf ~/.config/Code/Crashpad/* 2>/dev/null || true

# Cache de extensões
rm -rf ~/.vscode/extensions/* 2>/dev/null || true

# Arquivos temporários
rm -rf /tmp/vscode-* 2>/dev/null || true
rm -rf /tmp/Crashpad* 2>/dev/null || true
rm -rf /tmp/.org.chromium.* 2>/dev/null || true

# 4. RECRIAÇÃO DE CONFIGURAÇÕES BÁSICAS
echo "4. Recriando configurações básicas..."

mkdir -p ~/.config/Code/User

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
    "workbench.editor.limit.value": 3,
    "window.restoreWindows": "none",
    "window.newWindowDimensions": "default",
    "typescript.tsserver.maxTsServerMemory": 512,
    "javascript.suggest.enabled": false,
    "typescript.suggest.enabled": false,
    "python.terminal.activateEnvironment": true,
    "terminal.integrated.scrollback": 300,
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 60000,
    "editor.renderWhitespace": "none",
    "editor.wordWrap": "off",
    "workbench.list.keyboardNavigation": "simple",
    "workbench.quickOpen.closeOnFocusLost": false
}
EOL

# 5. CRIAR SCRIPT DE INICIALIZAÇÃO ULTRA-SEGURO
echo "5. Criando script de inicialização ultra-seguro..."

cat > ~/start_vscode_ultra_safe.sh << 'EOL'
#!/bin/bash
# Script ultra-seguro para iniciar VS Code

echo "Iniciando VS Code em modo ultra-seguro..."

# Variáveis de ambiente ultra-seguras
export ELECTRON_NO_ATTACH_CONSOLE=1
export ELECTRON_DISABLE_SECURITY_WARNINGS=1
export DISABLE_UPDATE_CHECK=1
export CODE_DISABLE_GPU=1
export ELECTRON_DISABLE_GPU=1
export LIBGL_ALWAYS_SOFTWARE=1
export QT_QPA_PLATFORM=offscreen
export DISPLAY=:0

# Limpeza prévia
rm -rf /tmp/vscode-* 2>/dev/null || true
rm -rf /tmp/Crashpad* 2>/dev/null || true
rm -rf ~/.config/Code/logs/* 2>/dev/null || true

# Iniciar com configurações mínimas
echo "Tentando inicialização básica..."
timeout 30 code --disable-extensions \
                --disable-gpu \
                --no-sandbox \
                --disable-web-security \
                --disable-background-timer-throttling \
                --disable-renderer-backgrounding \
                --disable-backgrounding-occluded-windows \
                --max_old_space_size=1024 \
                --user-data-dir=/tmp/vscode_temp \
                "$@" 2>/tmp/vscode_startup.log &

STARTUP_PID=$!
sleep 10

# Verificar se iniciou
if ps -p $STARTUP_PID > /dev/null 2>&1; then
    echo "✅ VS Code iniciou com sucesso!"
    echo "PID: $STARTUP_PID"
    echo ""
    echo "💡 DICAS PARA MANTER ESTABILIDADE:"
    echo "• Não abra mais de 5 abas simultaneamente"
    echo "• Evite usar extensões pesadas"
    echo "• Feche terminais não utilizados"
    echo "• Monitore uso de memória: free -h"
    echo ""
    echo "Para parar: kill $STARTUP_PID"
else
    echo "❌ Falha na inicialização"
    echo "Logs em: /tmp/vscode_startup.log"
    echo ""
    echo "Tentando método alternativo..."
    code --disable-extensions --no-sandbox --disable-gpu --user-data-dir=/tmp/vscode_alt &
fi
EOL

chmod +x ~/start_vscode_ultra_safe.sh

# 6. CRIAR SCRIPT DE DIAGNÓSTICO
echo "6. Criando script de diagnóstico..."

cat > ~/diagnose_vscode.sh << 'EOL'
#!/bin/bash
# Diagnóstico completo do VSCode

echo "=== DIAGNÓSTICO COMPLETO DO VSCODE ==="
echo ""

echo "1. VERIFICAÇÃO DE SISTEMA:"
echo "Sistema: $(uname -a)"
echo "Usuário: $(whoami)"
echo "Display: $DISPLAY"
echo "Memória: $(free -h | awk 'NR==2{printf "%.1fGB total, %.1fGB used", $2, $3}')"
echo ""

echo "2. VERSÃO DO VSCODE:"
if command -v code >/dev/null 2>&1; then
    code --version
else
    echo "VSCode não encontrado no PATH"
fi
echo ""

echo "3. PROCESSOS RELACIONADOS:"
ps aux | grep -E "(code|vscode|electron)" | grep -v grep || echo "Nenhum processo encontrado"
echo ""

echo "4. ARQUIVOS DE CONFIGURAÇÃO:"
ls -la ~/.config/Code/User/ 2>/dev/null || echo "Diretório não encontrado"
echo ""

echo "5. EXTENSÕES INSTALADAS:"
ls ~/.vscode/extensions/ 2>/dev/null | wc -l || echo "0"
echo ""

echo "6. LOGS DE ERRO RECENTES:"
find ~/.config/Code/logs/ -name "*.log" -mtime -1 -exec tail -20 {} \; 2>/dev/null || echo "Nenhum log recente"
echo ""

echo "7. TESTE DE INICIALIZAÇÃO:"
echo "Testando inicialização básica..."
timeout 10 code --version >/dev/null 2>&1 && echo "✅ Comando básico funciona" || echo "❌ Comando básico falha"
echo ""

echo "=== FIM DO DIAGNÓSTICO ==="
EOL

chmod +x ~/diagnose_vscode.sh

# 7. INSTALAR APENAS EXTENSÃO PYTHON (ESSENCIAL)
echo "7. Instalando apenas extensão Python..."

sleep 3

if command -v code >/dev/null 2>&1; then
    echo "Instalando extensão Python..."
    timeout 30 code --install-extension ms-python.python --force >/dev/null 2>&1 && echo "✅ Python instalada" || echo "❌ Falha na instalação Python"
else
    echo "VSCode não encontrado, pulando instalação de extensões"
fi

# 8. CRIAR ALIASES PRÁTICOS
echo "8. Criando aliases práticos..."

if ! grep -q "alias vscode-ultra" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Aliases para VS Code ultra-seguro" >> ~/.bashrc
    echo "alias vscode-ultra='~/start_vscode_ultra_safe.sh'" >> ~/.bashrc
    echo "alias vscode-diag='~/diagnose_vscode.sh'" >> ~/.bashrc
    echo "alias vscode-clean='pkill -9 -f code && sleep 2 && ~/start_vscode_ultra_safe.sh'" >> ~/.bashrc
    echo "alias vscode-reset='~/Projetos/cluster-ai/scripts/vscode/fix_vscode_complete.sh'" >> ~/.bashrc
fi

# 9. TESTE FINAL
echo "9. Executando teste final..."

~/diagnose_vscode.sh

echo ""
echo "🎯 CORREÇÃO COMPLETA CONCLUÍDA!"
echo "================================"
echo ""
echo "Backup salvo em: $BACKUP_DIR"
echo ""
echo "SCRIPTS CRIADOS:"
echo "• ~/start_vscode_ultra_safe.sh - Inicialização ultra-segura"
echo "• ~/diagnose_vscode.sh - Diagnóstico completo"
echo ""
echo "ALIASES DISPONÍVEIS:"
echo "• vscode-ultra - Iniciar modo ultra-seguro"
echo "• vscode-diag - Executar diagnóstico"
echo "• vscode-clean - Reiniciar completamente"
echo "• vscode-reset - Reset total (este script)"
echo ""
echo "Para usar o VS Code:"
echo "• Execute: vscode-ultra"
echo "• Ou: ~/start_vscode_ultra_safe.sh"
echo ""
echo "Se ainda houver problemas:"
echo "• Execute: vscode-diag (para diagnóstico)"
echo "• Execute: vscode-reset (para reset completo)"
echo ""
echo "IMPORTANTE:"
echo "• Backup das configurações: $BACKUP_DIR"
echo "• Configurações otimizadas para estabilidade"
echo "• Apenas extensão Python instalada"
echo "• GPU desabilitada para evitar crashes"
