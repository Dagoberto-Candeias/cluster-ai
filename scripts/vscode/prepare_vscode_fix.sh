#!/bin/bash

echo "=== PREPARAÇÃO PARA CORREÇÃO DO VS CODE ==="
echo "Este script apenas prepara as correções, NÃO inicia o VSCode"

# 1. PARADA FORÇADA COMPLETA
echo "1. Parando todos os processos relacionados..."
pkill -9 -f "code" 2>/dev/null || true
pkill -9 -f "vscode" 2>/dev/null || true
pkill -9 -f "electron" 2>/dev/null || true
sleep 3

# 2. BACKUP DE CONFIGURAÇÕES IMPORTANTES
echo "2. Fazendo backup de configurações importantes..."
BACKUP_DIR="$HOME/.vscode_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup de configurações essenciais
cp -r ~/.config/Code/User/settings.json "$BACKUP_DIR/" 2>/dev/null || true
cp -r ~/.config/Code/User/keybindings.json "$BACKUP_DIR/" 2>/dev/null || true
cp -r ~/.vscode/extensions "$BACKUP_DIR/" 2>/dev/null || true

echo "✅ Backup salvo em: $BACKUP_DIR"

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

echo "✅ Estado corrompido limpo"

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

echo "✅ Configurações básicas recriadas"

# 5. CRIAR SCRIPT DE INICIALIZAÇÃO MANUAL
echo "5. Criando script de inicialização manual..."

cat > ~/start_vscode_manual.sh << 'EOL'
#!/bin/bash
# Script MANUAL para iniciar VS Code - Execute APENAS quando solicitado

echo "=== INICIALIZAÇÃO MANUAL DO VS CODE ==="
echo ""
echo "IMPORTANTE: Este script deve ser executado MANUALMENTE"
echo "NÃO execute automaticamente!"
echo ""

read -p "Você quer continuar com a inicialização? (s/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Inicialização cancelada."
    exit 0
fi

echo "Iniciando VS Code em modo seguro..."

# Variáveis de ambiente seguras
export ELECTRON_NO_ATTACH_CONSOLE=1
export ELECTRON_DISABLE_SECURITY_WARNINGS=1
export DISABLE_UPDATE_CHECK=1
export CODE_DISABLE_GPU=1
export ELECTRON_DISABLE_GPU=1
export LIBGL_ALWAYS_SOFTWARE=1

# Limpeza prévia
rm -rf /tmp/vscode-* 2>/dev/null || true
rm -rf /tmp/Crashpad* 2>/dev/null || true

# Iniciar com configurações mínimas
echo "Tentando inicialização..."
code --disable-extensions \
     --disable-gpu \
     --no-sandbox \
     --disable-web-security \
     --disable-background-timer-throttling \
     --disable-renderer-backgrounding \
     --disable-backgrounding-occluded-windows \
     --max_old_space_size=1024 \
     --user-data-dir=/tmp/vscode_temp \
     "$@" &

echo "VS Code iniciado. Monitore se permanece aberto."
echo "Se fechar, verifique os logs em /tmp/vscode_startup.log"
EOL

chmod +x ~/start_vscode_manual.sh

echo "✅ Script de inicialização manual criado"

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

echo "=== FIM DO DIAGNÓSTICO ==="
EOL

chmod +x ~/diagnose_vscode.sh

echo "✅ Script de diagnóstico criado"

# 7. CRIAR ALIASES PRÁTICOS
echo "7. Criando aliases práticos..."

if ! grep -q "alias vscode-manual" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Aliases para VS Code manual" >> ~/.bashrc
    echo "alias vscode-manual='~/start_vscode_manual.sh'" >> ~/.bashrc
    echo "alias vscode-diag='~/diagnose_vscode.sh'" >> ~/.bashrc
    echo "alias vscode-prepare='~/Projetos/cluster-ai/scripts/vscode/prepare_vscode_fix.sh'" >> ~/.bashrc
fi

echo "✅ Aliases criados"

echo ""
echo "🎯 PREPARAÇÃO CONCLUÍDA!"
echo "========================="
echo ""
echo "✅ Backup salvo em: $BACKUP_DIR"
echo ""
echo "SCRIPTS CRIADOS:"
echo "• ~/start_vscode_manual.sh - Inicialização MANUAL (execute apenas quando solicitado)"
echo "• ~/diagnose_vscode.sh - Diagnóstico completo"
echo ""
echo "ALIASES DISPONÍVEIS:"
echo "• vscode-manual - Inicialização manual do VSCode"
echo "• vscode-diag - Executar diagnóstico"
echo "• vscode-prepare - Preparar correções (este script)"
echo ""
echo "PRÓXIMOS PASSOS:"
echo "1. Execute: source ~/.bashrc (para carregar aliases)"
echo "2. Execute: vscode-diag (para verificar o estado atual)"
echo "3. APENAS SE TUDO ESTIVER OK, execute: vscode-manual"
echo ""
echo "IMPORTANTE:"
echo "• NÃO execute o script de inicialização automaticamente"
echo "• Sempre faça diagnóstico primeiro"
echo "• Monitore se o VSCode permanece aberto após iniciar"
echo "• Se fechar novamente, há um problema mais profundo no sistema"
echo ""
echo "Para restaurar backup se necessário:"
echo "cp -r $BACKUP_DIR/* ~/.config/Code/User/ 2>/dev/null || true"
echo "cp -r $BACKUP_DIR/extensions/* ~/.vscode/ 2>/dev/null || true"
