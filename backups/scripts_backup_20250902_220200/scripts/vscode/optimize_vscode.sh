#!/bin/bash

echo "=== Otimização do VS Code para Cluster AI ==="
echo "Desativando extensões problemáticas e otimizando configurações..."

# Criar backup das configurações atuais
BACKUP_DIR="$HOME/vscode_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r ~/.config/Code/User/ "$BACKUP_DIR/"
echo "Backup criado em: $BACKUP_DIR"

# Lista de extensões essenciais para manter
ESSENTIAL_EXTENSIONS=(
    "ms-python.python"
    "ms-toolsai.jupyter"
    "eamodio.gitlens"
    "github.copilot"
    "ms-azuretools.vscode-docker"
    "redhat.vscode-yaml"
    "esbenp.prettier-vscode"
    "dbaeumer.vscode-eslint"
)

# Lista de extensões para desativar/remover
PROBLEMATIC_EXTENSIONS=(
    "codeium.codeium"
    "anthropic.claude-code"
    "askcodi.askcodi-vscode"
    "blackboxapp.blackbox"
    "blackboxapp.blackboxagent"
    "danielsanmedium.dscodegpt"
    "continue.continue"
    "cweijan.dbclient-jdbc"
    "cweijan.vscode-mysql-client2"
    "angular.ng-template"
    "adpyke.codesnap"
    "alefragnani.bookmarks"
    "atomiks.moonlight"
    "batisteo.vscode-django"
    "bierner.markdown-preview-github-styles"
    "bradlc.vscode-tailwindcss"
    "christian-kohler.npm-intellisense"
    "christian-kohler.path-intellisense"
)

echo "Desativando extensões problemáticas..."
for ext in "${PROBLEMATIC_EXTENSIONS[@]}"; do
    echo "Desativando: $ext"
    code --disable-extension "$ext" 2>/dev/null || true
done

echo "Atualizando configurações do VS Code..."
cat > ~/.config/Code/User/settings.json << 'EOL'
{
    "python.terminal.activateEnvironment": true,
    "python.analysis.extraPaths": [
        "/home/dcm/cluster_env/lib/python3.*/site-packages"
    ],
    "jupyter.notebookFileRoot": "/home/dcm",
    "python.formatting.autopep8Path": "/home/dcm/cluster_env/bin/autopep8",
    "python.linting.flake8Path": "/home/dcm/cluster_env/bin/flake8",
    "python.linting.pylintPath": "/home/dcm/cluster_env/bin/pylint",
    "workbench.editor.empty.hint": "hidden",
    "database-client.autoSync": false,
    "makefile.configureOnOpen": false,
    "terminal.integrated.env.linux": {},
    "telemetry.telemetryLevel": "off",
    "extensions.autoUpdate": false,
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
    "files.maxMemoryForLargeFilesMB": 2048,
    "workbench.secondarySideBar.defaultVisibility": "hidden",
    "redhat.telemetry.enabled": false,
    "editor.fontSize": 14,
    "editor.wordWrap": "on",
    "editor.minimap.enabled": false,
    "workbench.startupEditor": "none",
    "explorer.confirmDelete": false,
    "explorer.confirmDragAndDrop": false
}
EOL

echo "Otimizando configurações do sistema..."
# Reduzir swappiness para melhor performance
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Limpar cache do sistema
sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches

echo "Criando script de monitoramento..."
cat > ~/monitor_vscode.sh << 'EOL'
#!/bin/bash
echo "=== Monitor de Performance do VS Code ==="
echo "Processos VS Code ativos:"
ps aux | grep -E "(code|vscode)" | grep -v grep | awk '{print $4 "% MEM - " $11}' | sort -nr
echo ""
echo "Uso de memória:"
free -h
echo ""
echo "Extensões instaladas:"
code --list-extensions | wc -l
EOL

chmod +x ~/monitor_vscode.sh

echo "=== Otimização concluída! ==="
echo "Extensões mantidas (essenciais):"
printf '%s\n' "${ESSENTIAL_EXTENSIONS[@]}"
echo ""
echo "Próximos passos:"
echo "1. Reinicie completamente o VS Code"
echo "2. Execute: ~/monitor_vscode.sh para verificar performance"
echo "3. Verifique se o congelamento parou"
echo "4. Se necessário, reinstale apenas extensões essenciais manualmente"

# Verificar extensões atuais
echo ""
echo "Extensões atualmente instaladas:"
code --list-extensions | wc -l
