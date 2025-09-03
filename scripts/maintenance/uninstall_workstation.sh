#!/bin/bash

# 🗑️ Script de Desinstalação para Estações de Trabalho - Cluster AI
# Descrição: Remove a instalação do Cluster AI de estações de trabalho Linux/Windows/macOS

set -e

# --- Carregar Funções Comuns ---
PROJECT_ROOT=$(pwd)
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Definição de Caminhos ---
PROJECT_ROOT=$(pwd)
CONFIG_FILE="$PROJECT_ROOT/.cluster_config"
VENV_DIR="$PROJECT_ROOT/.venv"
LOG_DIR="$PROJECT_ROOT/logs"
BACKUP_DIR="$PROJECT_ROOT/backups"

# --- Função para Parar Serviços ---
stop_services() {
    log "Parando todos os serviços relacionados ao Cluster AI..."

    # Parar Dask Scheduler e Worker
    pkill -f "dask-scheduler" 2>/dev/null || log "Dask Scheduler não estava em execução."
    pkill -f "dask-worker" 2>/dev/null || log "Dask Worker não estava em execução."

    # Parar Ollama (se iniciado pelo script)
    if command_exists ollama && service_active ollama; then
        log "Parando serviço Ollama do sistema..."
        sudo systemctl stop ollama 2>/dev/null || true
    else
        pkill -f "ollama serve" 2>/dev/null || log "Processo 'ollama serve' não estava em execução."
    fi

    # Parar e remover containers Docker relacionados
    if command_exists docker; then
        if docker ps -a --format '{{.Names}}' | grep -q '^open-webui$'; then
            log "Parando e removendo container Docker 'open-webui'..."
            docker stop open-webui >/dev/null 2>&1
            docker rm open-webui >/dev/null 2>&1
            log "Container 'open-webui' removido."
        fi

        if docker ps -a --format '{{.Names}}' | grep -q '^cluster-ai'; then
            log "Parando e removendo containers relacionados ao cluster-ai..."
            docker stop $(docker ps -a --filter name=cluster-ai --format '{{.Names}}') >/dev/null 2>&1
            docker rm $(docker ps -a --filter name=cluster-ai --format '{{.Names}}') >/dev/null 2>&1
            log "Containers cluster-ai removidos."
        fi
    fi

    # Parar processos Python relacionados
    pkill -f "cluster_ai" 2>/dev/null || log "Processos cluster_ai não estavam em execução."
}

# --- Função para Remover Artefatos ---
remove_artifacts() {
    subsection "Removendo artefatos do projeto"

    local paths_to_remove=(
        "$VENV_DIR"
        "$LOG_DIR"
        "$BACKUP_DIR"
        "$PROJECT_ROOT/.pytest_cache"
        "$PROJECT_ROOT/__pycache__"
        "$PROJECT_ROOT/*.pyc"
        "$PROJECT_ROOT/.coverage"
        "$PROJECT_ROOT/coverage.xml"
        "$PROJECT_ROOT/.vscode/settings.json"
        "$PROJECT_ROOT/.vscode/launch.json"
    )

    for path in "${paths_to_remove[@]}"; do
        if [ -e "$path" ]; then
            if confirm_operation "Remover '$path'?"; then
                if safe_path_check "$path" "remoção"; then
                    rm -rf "$path" && success "Removido: $path"
                else
                    error "Remoção de '$path' abortada por segurança."
                fi
            else
                warn "Remoção de '$path' pulada."
            fi
        fi
    done

    # Remover arquivos de configuração específicos
    local config_files=(
        "$CONFIG_FILE"
        "$PROJECT_ROOT/cluster.conf"
        "$PROJECT_ROOT/config/cluster.conf"
        "$PROJECT_ROOT/.env"
        "$PROJECT_ROOT/.env.local"
    )

    for config in "${config_files[@]}"; do
        if [ -f "$config" ]; then
            if confirm_operation "Remover arquivo de configuração '$config'?"; then
                rm -f "$config" && success "Arquivo de configuração removido: $config"
            else
                warn "Remoção de '$config' pulada."
            fi
        fi
    done
}

# --- Função para Limpar Cache e Dados Temporários ---
clean_cache() {
    subsection "Limpando cache e dados temporários"

    # Limpar cache Python
    if command_exists python3; then
        log "Limpando cache Python..."
        find "$PROJECT_ROOT" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
        find "$PROJECT_ROOT" -name "*.pyc" -delete 2>/dev/null || true
        find "$PROJECT_ROOT" -name "*.pyo" -delete 2>/dev/null || true
        success "Cache Python limpo."
    fi

    # Limpar cache npm/node se existir
    if [ -d "$PROJECT_ROOT/node_modules" ]; then
        if confirm_operation "Remover diretório node_modules?"; then
            rm -rf "$PROJECT_ROOT/node_modules" && success "node_modules removido."
        fi
    fi

    # Limpar logs antigos
    if [ -d "$LOG_DIR" ]; then
        log "Removendo logs antigos..."
        find "$LOG_DIR" -name "*.log" -mtime +30 -delete 2>/dev/null || true
        success "Logs antigos removidos."
    fi
}

# --- Função para Remover Integrações ---
remove_integrations() {
    subsection "Removendo integrações"

    # Remover atalhos de desktop
    local desktop_files=(
        "$HOME/.local/share/applications/cluster-ai.desktop"
        "$HOME/Desktop/cluster-ai.desktop"
        "/usr/share/applications/cluster-ai.desktop"
    )

    for desktop_file in "${desktop_files[@]}"; do
        if [ -f "$desktop_file" ]; then
            if confirm_operation "Remover atalho '$desktop_file'?"; then
                sudo rm -f "$desktop_file" 2>/dev/null || rm -f "$desktop_file"
                success "Atalho removido: $desktop_file"
            fi
        fi
    done

    # Remover integrações VSCode/PyCharm
    local ide_settings=(
        "$HOME/.vscode/extensions/cluster-ai"
        "$HOME/.config/JetBrains/PyCharm*/options/cluster_ai.xml"
    )

    for setting in "${ide_settings[@]}"; do
        if [ -e "$setting" ]; then
            if confirm_operation "Remover integração IDE '$setting'?"; then
                rm -rf "$setting" && success "Integração IDE removida: $setting"
            fi
        fi
    done

    # Remover configurações do Ollama
    if [ -d "$HOME/.ollama/prompts" ]; then
        if confirm_operation "Remover prompts do Ollama?"; then
            rm -rf "$HOME/.ollama/prompts" && success "Prompts do Ollama removidos."
        fi
    fi
}

# --- Script Principal ---
main() {
    section "Desinstalador para Estações de Trabalho - Cluster AI"
    warn "Este script removerá a instalação do Cluster AI da estação de trabalho."
    warn "Ele NÃO removerá dependências de sistema ou modelos de IA baixados."
    echo ""

    # Verificar se estamos no diretório correto
    if [ ! -f "manager.sh" ] || [ ! -d "scripts" ]; then
        error "Este script deve ser executado na raiz do projeto Cluster AI."
        exit 1
    fi

    if confirm_operation "Você tem certeza que deseja desinstalar o Cluster AI desta estação de trabalho?"; then
        stop_services
        echo ""
        remove_artifacts
        echo ""
        clean_cache
        echo ""
        remove_integrations

        echo ""
        success "✅ Desinstalação da estação de trabalho concluída!"
        echo ""
        info "Para remover completamente:"
        echo "  - Modelos Ollama: rm -rf ~/.ollama"
        echo "  - Dependências Python: pip uninstall -r requirements.txt"
        echo "  - Docker images: docker system prune -a"
    else
        error "Desinstalação cancelada pelo usuário."
        exit 1
    fi
}

# Executa o script principal
main
