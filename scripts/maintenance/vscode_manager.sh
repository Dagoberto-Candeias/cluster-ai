#!/bin/bash
# Local: scripts/maintenance/vscode_manager.sh
# Autor: Dagoberto Candeias <betoallnet@gmail.com>

# =============================================================================
# Cluster AI - Gerenciador Unificado do VSCode
# =============================================================================
# Centraliza todas as operações de diagnóstico, reparo e otimização para
# resolver problemas de travamento, lentidão e uso excessivo de recursos.

set -euo pipefail

# Carrega funções comuns
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# =============================================================================
# FUNÇÕES DE OPERAÇÃO
# =============================================================================

show_vscode_status() {
    subsection "🔍 Status do Ambiente VSCode"

    # 1. Verificar processos
    info "Verificando processos do VSCode..."
    if pgrep -af "code" >/dev/null; then
        success "VSCode está em execução."
        echo "Processos encontrados:"
        pgrep -af "code" | awk '{print "  - PID:", $1, "CMD:", $2, $3, $4}' | head -n 5
        echo "  - Total: $(pgrep -af "code" | wc -l) processos."
    else
        warn "VSCode não está em execução."
    fi
    echo

    # 2. Verificar uso de recursos
    info "Uso de memória e CPU (processos 'code'):"
    if pgrep -f "code" >/dev/null; then
        ps -C code -o %cpu,%mem,cmd --sort=-%cpu | head -n 5
    else
        echo "Nenhum processo para analisar."
    fi
    echo

    # 3. Verificar configurações
    info "Verificando arquivos de configuração..."
    local settings_file="$HOME/.config/Code/User/settings.json"
    if file_exists "$settings_file"; then
        success "Arquivo de configurações encontrado: $settings_file"
    else
        warn "Arquivo de configurações não encontrado."
    fi
}

clean_caches() {
    subsection "🧹 Limpeza de Caches e Arquivos Temporários"
    if ! confirm "Isso irá parar o VSCode e limpar todos os caches. Deseja continuar?"; then
        info "Limpeza cancelada."
        return
    fi

    progress "Parando todos os processos do VSCode..."
    pkill -9 -f "code" 2>/dev/null || true
    pkill -9 -f "vscode" 2>/dev/null || true
    sleep 2

    progress "Limpando caches..."
    rm -rf ~/.config/Code/Cache/* 2>/dev/null || true
    rm -rf ~/.config/Code/Code\ Cache/* 2>/dev/null || true
    rm -rf ~/.config/Code/CachedData/* 2>/dev/null || true
    rm -rf ~/.config/Code/User/workspaceStorage/* 2>/dev/null || true
    rm -rf ~/.config/Code/User/globalStorage/* 2>/dev/null || true
    rm -rf ~/.config/Code/logs/* 2>/dev/null || true
    rm -rf /tmp/vscode-* 2>/dev/null || true
    rm -rf /tmp/Crashpad* 2>/dev/null || true

    success "Limpeza de caches concluída."
    info "É recomendado reiniciar o VSCode."
}

reset_settings() {
    subsection "⚙️ Resetar para Configurações Otimizadas"
    local settings_file="$HOME/.config/Code/User/settings.json"

    if ! confirm "Isso irá sobrescrever seu 'settings.json' com uma configuração otimizada para performance. Um backup será criado. Deseja continuar?"; then
        info "Reset de configurações cancelado."
        return
    fi

    if file_exists "$settings_file"; then
        backup_file "$settings_file"
    fi

    progress "Aplicando configurações otimizadas..."
    mkdir -p "$(dirname "$settings_file")"
    cat > "$settings_file" << 'EOL'
{
    "telemetry.telemetryLevel": "off",
    "extensions.autoUpdate": false,
    "update.mode": "none",
    "workbench.startupEditor": "none",
    "editor.minimap.enabled": false,
    "window.restoreWindows": "none",
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/.git/subtree-cache/**": true,
        "**/node_modules/*/**": true,
        "**/venv/**": true,
        "**/dist/**": true,
        "**/build/**": true
    },
    "search.exclude": {
        "**/node_modules": true,
        "**/venv": true,
        "**/dist": true,
        "**/build": true
    },
    "editor.largeFileOptimizations": true,
    "terminal.integrated.scrollback": 1000,
    "python.terminal.activateEnvironment": true,
    "files.autoSave": "afterDelay"
}
EOL
    success "Configurações otimizadas foram aplicadas."
    info "Reinicie o VSCode para que as mudanças tenham efeito."
}

restart_clean() {
    subsection "🔄 Reinicialização Limpa do VSCode"
    if ! confirm "Isso irá forçar a parada de todas as instâncias do VSCode e iniciá-lo em modo limpo (sem extensões). Deseja continuar?"; then
        info "Reinicialização cancelada."
        return
    fi

    progress "Parando todos os processos do VSCode..."
    pkill -9 -f "code" 2>/dev/null || true
    pkill -9 -f "vscode" 2>/dev/null || true
    sleep 2

    progress "Iniciando VSCode em modo limpo..."
    code --disable-extensions --disable-gpu > /tmp/vscode_clean_start.log 2>&1 &

    info "Aguardando 10 segundos para a inicialização..."
    sleep 10

    if pgrep -f "code" >/dev/null; then
        success "VSCode foi reiniciado em modo limpo."
        info "Você pode reativar as extensões uma a uma para identificar a causa do problema."
    else
        error "Falha ao reiniciar o VSCode. Verifique o log em /tmp/vscode_clean_start.log"
    fi
}

# =============================================================================
# MENU E LÓGICA PRINCIPAL
# =============================================================================

show_menu() {
    section "💻 Gerenciador Unificado do VSCode"
    echo "Este utilitário ajuda a resolver problemas de performance e travamentos."
    echo
    echo "1) 🔍 Verificar Status do VSCode"
    echo "2) 🧹 Limpar Caches e Arquivos Temporários"
    echo "3) ⚙️  Resetar para Configurações Otimizadas (cria backup)"
    echo "4) 🔄 Reiniciar o VSCode em Modo Limpo (sem extensões)"
    echo "0) ↩️  Voltar ao Menu Principal"
    echo
}

main() {
    # Se um argumento for passado, executa a ação diretamente
    case "${1:-}" in
        status) show_vscode_status; exit 0 ;;
        clean) clean_caches; exit 0 ;;
        reset) reset_settings; exit 0 ;;
        restart) restart_clean; exit 0 ;;
    esac

    # Menu interativo
    while true; do
        show_menu
        read -p "Digite sua opção: " choice

        case $choice in
            1) show_vscode_status ;;
            2) clean_caches ;;
            3) reset_settings ;;
            4) restart_clean ;;
            0)
                success "Gerenciador VSCode encerrado."
                break
                ;;
            *) error "Opção inválida." ;;
        esac
        echo
        read -p "Pressione Enter para continuar..."
    done
}

main "$@"