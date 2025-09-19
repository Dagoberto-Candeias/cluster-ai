#!/bin/bash

# Configuração do VSCode para usar SSD Externo como Memória Auxiliar
# Autor: Sistema Cluster AI
# Descrição: Configura VSCode para usar SSD externo para cache e dados

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configurações
SSD_PATH="/mnt/external_ssd"
VSCODE_SSD_PATH="$SSD_PATH/vscode"
VSCODE_CONFIG_DIR="$HOME/.config/Code"
VSCODE_USER_DIR="$HOME/.vscode"
LOG_FILE="/tmp/vscode_ssd_setup.log"

# Função de logging
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

# Função de sucesso
success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

# Função de warning
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

# Verificar se SSD externo está montado
check_ssd_mounted() {
    log "Verificando se SSD externo está montado..."

    if [ ! -d "$SSD_PATH" ]; then
        echo -e "${RED}❌ SSD externo não encontrado em $SSD_PATH${NC}"
        echo "Certifique-se de que o SSD externo está montado corretamente."
        exit 1
    fi

    if ! mountpoint -q "$SSD_PATH"; then
        echo -e "${RED}❌ $SSD_PATH não é um ponto de montagem${NC}"
        echo "Verifique se o SSD externo está montado."
        exit 1
    fi

    success "SSD externo verificado: $SSD_PATH"
}

# Criar estrutura de diretórios no SSD
create_ssd_directories() {
    log "Criando estrutura de diretórios no SSD..."

    sudo mkdir -p "$VSCODE_SSD_PATH"/{cache,user-data,extensions,workspace-storage,logs}

    # Ajustar permissões
    sudo chown -R $USER:$USER "$VSCODE_SSD_PATH"

    # Verificar espaço disponível
    local available_space
    available_space=$(df "$SSD_PATH" | tail -1 | awk '{print $4}')
    local available_gb=$((available_space / 1024 / 1024))

    if [ $available_gb -lt 10 ]; then
        warning "Espaço disponível no SSD: ${available_gb}GB (recomendado: 20GB+)"
    else
        success "Espaço disponível no SSD: ${available_gb}GB"
    fi

    success "Estrutura de diretórios criada"
}

# Backup das configurações atuais
backup_current_config() {
    log "Fazendo backup das configurações atuais..."

    local backup_dir="$HOME/.vscode_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    # Backup de configurações
    if [ -d "$VSCODE_CONFIG_DIR" ]; then
        cp -r "$VSCODE_CONFIG_DIR" "$backup_dir/"
        success "Backup de configurações: $backup_dir/config"
    fi

    if [ -d "$VSCODE_USER_DIR" ]; then
        cp -r "$VSCODE_USER_DIR" "$backup_dir/"
        success "Backup de dados do usuário: $backup_dir/user"
    fi

    echo "$backup_dir" > /tmp/vscode_ssd_backup_path
}

# Configurar VSCode para usar SSD
configure_vscode_ssd() {
    log "Configurando VSCode para usar SSD..."

    # Criar script de inicialização personalizado
    cat > "$HOME/.vscode_ssd_launcher" << EOF
#!/bin/bash
# VSCode Launcher com SSD Externo
# Configurado automaticamente pelo Cluster AI

export VSCODE_EXTENSIONS="$VSCODE_SSD_PATH/extensions"
export VSCODE_LOGS="$VSCODE_SSD_PATH/logs"

# Iniciar VSCode com configurações do SSD
code --extensions-dir "$VSCODE_SSD_PATH/extensions" \\
     --user-data-dir "$VSCODE_SSD_PATH/user-data" \\
     --logs-path "$VSCODE_SSD_PATH/logs" \\
     "\$@"
EOF

    chmod +x "$HOME/.vscode_ssd_launcher"

    # Criar alias para facilitar uso
    if ! grep -q "vscode_ssd" "$HOME/.bashrc"; then
        echo "# VSCode com SSD Externo - Cluster AI" >> "$HOME/.bashrc"
        echo "alias code-ssd='$HOME/.vscode_ssd_launcher'" >> "$HOME/.bashrc"
        echo "alias vscode-ssd='$HOME/.vscode_ssd_launcher'" >> "$HOME/.bashrc"
    fi

    success "VSCode configurado para usar SSD"
}

# Migrar dados existentes para SSD
migrate_data_to_ssd() {
    log "Migrando dados existentes para SSD..."

    # Migrar extensões
    if [ -d "$VSCODE_CONFIG_DIR/extensions" ]; then
        log "Migrando extensões..."
        rsync -av "$VSCODE_CONFIG_DIR/extensions/" "$VSCODE_SSD_PATH/extensions/" || true
    fi

    # Migrar dados do usuário
    if [ -d "$VSCODE_USER_DIR" ]; then
        log "Migrando dados do usuário..."
        rsync -av "$VSCODE_USER_DIR/" "$VSCODE_SSD_PATH/user-data/" || true
    fi

    success "Migração de dados concluída"
}

# Otimizar configurações para SSD
optimize_ssd_settings() {
    log "Otimizando configurações para SSD..."

    # Criar configurações otimizadas
    mkdir -p "$VSCODE_SSD_PATH/user-data/User"

    cat > "$VSCODE_SSD_PATH/user-data/User/settings.json" << 'EOF'
{
    // Configurações otimizadas para SSD Externo - Cluster AI
    "workbench.enableExperiments": false,
    "workbench.enablePreviewFeatures": false,
    "workbench.editor.enablePreview": false,
    "workbench.editor.limit.enabled": true,
    "workbench.editor.limit.value": 20,

    // Otimizações de performance para SSD
    "files.maxMemoryForLargeFilesMB": 2048,
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/.git/subtree-cache/**": true,
        "**/node_modules/**": true,
        "**/venv/**": true,
        "**/__pycache__/**": true,
        "**/.pytest_cache/**": true
    },

    // Cache otimizado
    "search.exclude": {
        "**/node_modules": true,
        "**/venv": true,
        "**/__pycache__": true,
        "**/*.pyc": true,
        "**/.pytest_cache": true,
        "**/logs": true,
        "**/temp": true
    },

    // Configurações de terminal
    "terminal.integrated.shell.linux": "/bin/bash",
    "terminal.integrated.enablePersistentSessions": false,

    // Extensões essenciais
    "extensions.autoUpdate": false,
    "extensions.autoCheckUpdates": false,

    // Telemetria desabilitada para melhor performance
    "telemetry.telemetryLevel": "off",
    "workbench.enableTelemetry": false,

    // Configurações específicas do Cluster AI
    "python.linting.enabled": true,
    "python.linting.flake8Enabled": true,
    "python.formatting.provider": "black",
    "python.formatting.blackArgs": ["--line-length", "88"],
    "docker.showExplorer": false,
    "git.autofetch": false
}
EOF

    success "Configurações otimizadas aplicadas"
}

# Criar script de monitoramento
create_monitoring_script() {
    log "Criando script de monitoramento..."

    cat > "$VSCODE_SSD_PATH/monitor_ssd.sh" << EOF
#!/bin/bash
# Monitoramento de Performance do VSCode com SSD
# Cluster AI

echo "=== Monitoramento VSCode + SSD ==="
echo "Data: \$(date)"
echo ""

# Verificar uso do SSD
echo "📊 Uso do SSD:"
df -h $SSD_PATH
echo ""

# Verificar processos do VSCode
echo "🔍 Processos VSCode:"
ps aux | grep -i code | grep -v grep || echo "Nenhum processo encontrado"
echo ""

# Verificar uso de memória
echo "🧠 Uso de memória:"
free -h
echo ""

# Verificar espaço nos diretórios do VSCode
echo "💾 Espaço usado pelo VSCode no SSD:"
du -sh $VSCODE_SSD_PATH/* 2>/dev/null || echo "Diretórios vazios"
echo ""

echo "✅ Monitoramento concluído"
EOF

    chmod +x "$VSCODE_SSD_PATH/monitor_ssd.sh"

    success "Script de monitoramento criado"
}

# Criar documentação
create_documentation() {
    log "Criando documentação..."

    cat > "$VSCODE_SSD_PATH/README.md" << EOF
# VSCode com SSD Externo - Cluster AI

## 📋 Visão Geral
Este setup configura o VSCode para usar SSD externo como memória auxiliar, melhorando significativamente a performance e estabilidade.

## 🚀 Como Usar

### Iniciar VSCode com SSD
\`\`\`bash
# Usar alias configurado
code-ssd

# Ou diretamente
$VSCODE_SSD_PATH/../.vscode_ssd_launcher
\`\`\`

### Monitorar Performance
\`\`\`bash
# Executar monitoramento
$VSCODE_SSD_PATH/monitor_ssd.sh
\`\`\`

## 📁 Estrutura de Diretórios
- \`cache/\` - Cache temporário
- \`user-data/\` - Configurações e dados do usuário
- \`extensions/\` - Extensões instaladas
- \`workspace-storage/\` - Dados de workspace
- \`logs/\` - Logs do VSCode

## ⚙️ Configurações Aplicadas
- Cache movido para SSD
- Extensões no SSD
- Dados do usuário no SSD
- Configurações otimizadas para performance
- Limites de memória aumentados

## 🔧 Manutenção

### Limpar Cache
\`\`\`bash
rm -rf $VSCODE_SSD_PATH/cache/*
\`\`\`

### Backup de Configurações
\`\`\`bash
cp -r $VSCODE_SSD_PATH/user-data $HOME/vscode_ssd_backup_\$(date +%Y%m%d)
\`\`\`

### Verificar Integridade
\`\`\`bash
$VSCODE_SSD_PATH/monitor_ssd.sh
\`\`\`

## 📞 Suporte
- Consulte: \`docs/guides/VSCODE_OPTIMIZATION.md\`
- Backup disponível em: \`/tmp/vscode_ssd_backup_path\`

---
*Configurado automaticamente pelo Cluster AI*
EOF

    success "Documentação criada"
}

# Função principal
main() {
    log "=== Configuração VSCode + SSD Externo ==="
    log "Cluster AI - Otimização de Performance"

    check_ssd_mounted
    create_ssd_directories
    backup_current_config
    configure_vscode_ssd
    migrate_data_to_ssd
    optimize_ssd_settings
    create_monitoring_script
    create_documentation

    log ""
    success "🎉 CONFIGURAÇÃO CONCLUÍDA COM SUCESSO!"
    log ""
    log "📍 SSD configurado em: $VSCODE_SSD_PATH"
    log "🚀 Para usar: code-ssd"
    log "📊 Monitorar: $VSCODE_SSD_PATH/monitor_ssd.sh"
    log "📚 Documentação: $VSCODE_SSD_PATH/README.md"
    log "🔄 Backup: $(cat /tmp/vscode_ssd_backup_path 2>/dev/null || echo 'N/A')"

    echo ""
    echo -e "${GREEN}💡 PRÓXIMOS PASSOS:${NC}"
    echo "1. Reinicie o terminal para carregar aliases"
    echo "2. Use 'code-ssd' para iniciar VSCode com SSD"
    echo "3. Execute monitoramento: $VSCODE_SSD_PATH/monitor_ssd.sh"
    echo "4. Consulte documentação no SSD para detalhes"

    # Recarregar bashrc
    source "$HOME/.bashrc" 2>/dev/null || true
}

# Executar
main "$@"
