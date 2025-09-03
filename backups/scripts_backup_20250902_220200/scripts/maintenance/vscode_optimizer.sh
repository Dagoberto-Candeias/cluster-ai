#!/bin/bash

# Otimizador de Performance do VSCode
# Previne travamentos e melhora a estabilidade

set -e

# Configurações
VSCODE_CONFIG_DIR="$HOME/.config/Code"
VSCODE_USER_DIR="$HOME/.vscode"
WORKSPACE_FILE="$PWD/cluster-ai.code-workspace"
LOG_FILE="/tmp/vscode_optimizer.log"

# Função de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Verificar se VSCode está rodando
is_vscode_running() {
    pgrep -f "code" >/dev/null 2>&1
}

# Parar VSCode graciosamente
stop_vscode() {
    log "Parando VSCode..."
    if is_vscode_running; then
        pkill -TERM -f "code" 2>/dev/null || true
        sleep 3
        if is_vscode_running; then
            log "Forçando parada do VSCode..."
            pkill -KILL -f "code" 2>/dev/null || true
            sleep 2
        fi
        log "VSCode parado"
    else
        log "VSCode não estava rodando"
    fi
}

# Limpar cache do VSCode
clean_vscode_cache() {
    log "Limpando cache do VSCode..."

    # Cache de extensões
    rm -rf "$VSCODE_CONFIG_DIR/CachedExtensionVSIXs" 2>/dev/null || true
    rm -rf "$VSCODE_CONFIG_DIR/CachedExtensions" 2>/dev/null || true

    # Cache de dados do usuário
    rm -rf "$VSCODE_USER_DIR/cache" 2>/dev/null || true
    rm -rf "$VSCODE_USER_DIR/Cache" 2>/dev/null || true

    # Arquivos temporários
    find "$VSCODE_CONFIG_DIR" -name "*.tmp" -delete 2>/dev/null || true
    find "$VSCODE_USER_DIR" -name "*.tmp" -delete 2>/dev/null || true

    log "Cache limpo"
}

# Otimizar configurações do VSCode
optimize_vscode_settings() {
    log "Otimizando configurações do VSCode..."

    local settings_file="$VSCODE_USER_DIR/settings.json"

    # Criar backup das configurações atuais
    if [ -f "$settings_file" ]; then
        cp "$settings_file" "${settings_file}.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    # Configurações de performance
    cat > "$settings_file" << 'EOF'
{
    // Configurações de Performance
    "workbench.enableExperiments": false,
    "workbench.enablePreviewFeatures": false,
    "workbench.editor.enablePreview": false,
    "workbench.editor.enablePreviewFromQuickOpen": false,
    "workbench.quickOpen.closeOnFocusLost": false,

    // Limitação de recursos
    "files.maxMemoryForLargeFilesMB": 1024,
    "files.exclude": {
        "**/.git": true,
        "**/.svn": true,
        "**/.hg": true,
        "**/CVS": true,
        "**/.DS_Store": true,
        "**/node_modules": true,
        "**/venv": true,
        "**/__pycache__": true,
        "**/*.pyc": true,
        "**/.pytest_cache": true,
        "**/logs": true,
        "**/temp": true,
        "**/test_logs": true
    },

    // Otimizações de editor
    "editor.minimap.enabled": false,
    "editor.renderWhitespace": "boundary",
    "editor.wordWrap": "off",
    "editor.cursorBlinking": "solid",
    "editor.smoothScrolling": true,
    "editor.cursorSmoothCaretAnimation": "off",

    // Otimizações de workspace
    "workbench.editor.limit.enabled": true,
    "workbench.editor.limit.value": 10,
    "workbench.editor.limit.perEditorGroup": true,
    "workbench.tree.renderIndentGuides": "none",
    "workbench.tree.indent": 8,

    // Configurações de pesquisa
    "search.exclude": {
        "**/node_modules": true,
        "**/venv": true,
        "**/__pycache__": true,
        "**/*.pyc": true,
        "**/.pytest_cache": true,
        "**/logs": true,
        "**/temp": true,
        "**/test_logs": true
    },

    // Configurações de terminal
    "terminal.integrated.shell.linux": "/bin/bash",
    "terminal.integrated.shellArgs.linux": ["--login"],
    "terminal.integrated.enablePersistentSessions": false,

    // Configurações de extensões
    "extensions.autoUpdate": false,
    "extensions.autoCheckUpdates": false,

    // Configurações de Git
    "git.autofetch": false,
    "git.enableSmartCommit": true,
    "git.confirmSync": false,

    // Configurações de Python
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": false,
    "python.linting.flake8Enabled": true,
    "python.formatting.provider": "black",
    "python.formatting.blackArgs": ["--line-length", "88"],

    // Configurações de Docker
    "docker.showExplorer": false,
    "docker.containers.groupBy": "None",

    // Configurações de segurança
    "security.workspace.trust.enabled": false,
    "security.workspace.trust.banner": "never",

    // Configurações de telemetria (desabilitar para melhor performance)
    "telemetry.telemetryLevel": "off",
    "workbench.enableTelemetry": false
}
EOF

    log "Configurações otimizadas aplicadas"
}

# Criar arquivo de workspace otimizado
create_optimized_workspace() {
    log "Criando workspace otimizado..."

    cat > "$WORKSPACE_FILE" << 'EOF'
{
    "folders": [
        {
            "name": "Cluster AI",
            "path": "."
        }
    ],
    "settings": {
        // Configurações específicas do workspace
        "files.exclude": {
            "**/.git": true,
            "**/node_modules": true,
            "**/venv": true,
            "**/__pycache__": true,
            "**/*.pyc": true,
            "**/.pytest_cache": true,
            "**/logs": true,
            "**/temp": true,
            "**/test_logs": true,
            "**/backups": true,
            "**/reports": true,
            "**/metrics": true,
            "**/models": true
        },
        "search.exclude": {
            "**/node_modules": true,
            "**/venv": true,
            "**/__pycache__": true,
            "**/*.pyc": true,
            "**/.pytest_cache": true,
            "**/logs": true,
            "**/temp": true,
            "**/test_logs": true,
            "**/backups": true
        },
        // Limitar abas abertas
        "workbench.editor.limit.enabled": true,
        "workbench.editor.limit.value": 15,
        "workbench.editor.limit.perEditorGroup": true
    },
    "extensions": {
        "recommendations": [
            "ms-python.python",
            "ms-python.black-formatter",
            "ms-python.flake8",
            "ms-vscode.vscode-json",
            "redhat.vscode-yaml",
            "ms-vscode-remote.remote-ssh",
            "ms-vscode.vscode-docker",
            "ms-vscode.vscode-git-graph",
            "gruntfuggly.todo-tree",
            "christian-kohler.path-intellisense"
        ]
    },
    "launch": {
        "version": "0.2.0",
        "configurations": [
            {
                "name": "Python: Demo Cluster",
                "type": "python",
                "request": "launch",
                "program": "${workspaceFolder}/demo_cluster.py",
                "console": "integratedTerminal",
                "justMyCode": true
            },
            {
                "name": "Python: Test Installation",
                "type": "python",
                "request": "launch",
                "program": "${workspaceFolder}/test_installation.py",
                "console": "integratedTerminal",
                "justMyCode": true
            }
        ]
    }
}
EOF

    log "Workspace otimizado criado"
}

# Otimizar uso de memória
optimize_memory_usage() {
    log "Otimizando uso de memória..."

    # Limpar cache do sistema
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

    # Otimizar swappiness
    echo 10 > /proc/sys/vm/swappiness 2>/dev/null || true

    log "Memória otimizada"
}

# Monitorar recursos do sistema
monitor_system_resources() {
    log "Monitorando recursos do sistema..."

    # Verificar uso de memória
    local mem_usage
    mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')

    if [ "$mem_usage" -gt 85 ]; then
        log "⚠️  Uso de memória alto: ${mem_usage}%"
        optimize_memory_usage
    fi

    # Verificar uso de CPU
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

    if [ "${cpu_usage%.*}" -gt 80 ]; then
        log "⚠️  Uso de CPU alto: ${cpu_usage}%"
    fi

    # Verificar espaço em disco
    local disk_usage
    disk_usage=$(df "$PWD" | tail -1 | awk '{print $5}' | sed 's/%//')

    if [ "$disk_usage" -gt 90 ]; then
        log "⚠️  Espaço em disco baixo: ${disk_usage}%"
    fi
}

# Reiniciar VSCode com configurações otimizadas
restart_vscode_optimized() {
    log "Reiniciando VSCode com configurações otimizadas..."

    stop_vscode
    sleep 2

    # Iniciar VSCode com workspace otimizado
    if [ -f "$WORKSPACE_FILE" ]; then
        nohup code "$WORKSPACE_FILE" >/dev/null 2>&1 &
        log "VSCode iniciado com workspace otimizado"
    else
        nohup code . >/dev/null 2>&1 &
        log "VSCode iniciado no diretório atual"
    fi

    sleep 5

    if is_vscode_running; then
        log "✅ VSCode reiniciado com sucesso"
    else
        log "❌ Falha ao reiniciar VSCode"
    fi
}

# Função principal
main() {
    log "=== Otimizador de Performance do VSCode ==="

    case "${1:-full}" in
        "clean")
            clean_vscode_cache
            ;;
        "settings")
            optimize_vscode_settings
            ;;
        "workspace")
            create_optimized_workspace
            ;;
        "memory")
            optimize_memory_usage
            ;;
        "monitor")
            monitor_system_resources
            ;;
        "restart")
            restart_vscode_optimized
            ;;
        "full")
            log "Executando otimização completa..."
            monitor_system_resources
            clean_vscode_cache
            optimize_vscode_settings
            create_optimized_workspace
            optimize_memory_usage
            restart_vscode_optimized
            log "✅ Otimização completa finalizada"
            ;;
        *)
            echo "Uso: $0 [clean|settings|workspace|memory|monitor|restart|full]"
            echo "  clean     - Limpar cache"
            echo "  settings  - Otimizar configurações"
            echo "  workspace - Criar workspace otimizado"
            echo "  memory    - Otimizar uso de memória"
            echo "  monitor   - Monitorar recursos"
            echo "  restart   - Reiniciar VSCode otimizado"
            echo "  full      - Otimização completa (padrão)"
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"
