#!/bin/bash

# 🗑️ Script de Desinstalação Segura - Cluster AI
# Descrição: Remove os artefatos gerados pelo projeto, como ambiente virtual,
#            scripts de runtime, logs e arquivos de configuração.

set -e

# --- Configuração de Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# --- Funções de Log ---
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# --- Definição de Caminhos ---
# O script deve estar na raiz do projeto para funcionar corretamente.
PROJECT_ROOT=$(pwd)
CONFIG_FILE="$PROJECT_ROOT/.cluster_config"
VENV_DIR="$PROJECT_ROOT/.venv"
RUNTIME_SCRIPTS_DIR="$PROJECT_ROOT/scripts/runtime"
LOG_DIR="$PROJECT_ROOT/logs"

# --- Função para Parar Serviços ---
stop_services() {
    log "Parando todos os serviços relacionados ao Cluster AI..."

    # Parar Dask Scheduler e Worker
    pkill -f "dask-scheduler" 2>/dev/null || log "Dask Scheduler não estava em execução."
    pkill -f "dask-worker" 2>/dev/null || log "Dask Worker não estava em execução."

    # Parar Ollama (se iniciado pelo script)
    if command_exists ollama && service_active ollama; then
        log "Parando serviço Ollama do sistema..."
        sudo systemctl stop ollama
    else
        pkill -f "ollama serve" 2>/dev/null || log "Processo 'ollama serve' não estava em execução."
    fi

    # Parar e remover containers Docker relacionados
    if sudo docker ps -a --format '{{.Names}}' | grep -q '^open-webui$'; then
        log "Parando e removendo container Docker 'open-webui'..."
        sudo docker stop open-webui >/dev/null 2>&1
        sudo docker rm open-webui >/dev/null 2>&1
        log "Container 'open-webui' removido."
    else
        log "Container Docker 'open-webui' não encontrado."
    fi
}

# --- Função para Remover Artefatos ---
remove_artifacts() {
    subsection "Removendo artefatos do projeto"

    local paths_to_remove=(
        "$VENV_DIR"
        "$RUNTIME_SCRIPTS_DIR"
        "$LOG_DIR"
        "$BACKUP_DIR"
    )

    for path in "${paths_to_remove[@]}"; do
        if [ -e "$path" ]; then
            if confirm_operation "Remover o diretório '$path'?"; then
                if safe_path_check "$path" "remoção"; then
                    rm -rf "$path" && success "Diretório '$path' removido."
                else
                    error "Remoção de '$path' abortada por segurança."
                fi
            else
                warn "Remoção de '$path' pulada."
            fi
        fi
    done

    subsection "Removendo artefatos no diretório HOME"
    warn "As operações a seguir afetam arquivos fora do diretório do projeto."

    if [ -d "$HOME_VENV_DIR" ]; then
        if confirm_operation "Remover ambiente virtual em '$HOME_VENV_DIR'?"; then
            if safe_path_check "$HOME_VENV_DIR" "remoção"; then
                rm -rf "$HOME_VENV_DIR" && success "Diretório '$HOME_VENV_DIR' removido."
            else
                error "Remoção de '$HOME_VENV_DIR' abortada por segurança."
            fi
        else
            warn "Remoção de '$HOME_VENV_DIR' pulada."
        fi
    fi

    if [ -f "$GPU_CONFIG_FILE" ]; then
        if confirm_operation "Remover arquivo de configuração de GPU em '$GPU_CONFIG_FILE'?"; then
            rm -f "$GPU_CONFIG_FILE" && success "Arquivo '$GPU_CONFIG_FILE' removido."
        else
            warn "Remoção de '$GPU_CONFIG_FILE' pulada."
        fi
    fi

    subsection "Ações Manuais Recomendadas"
    warn "As seguintes ações não são automáticas para evitar perda de dados:"
    echo "  - Modelos Ollama: Os modelos de IA estão em '$OLLAMA_DATA_DIR'."
    echo "    Para removê-los, execute: 'rm -rf $OLLAMA_DATA_DIR'"
    echo "  - Dependências de Sistema: Pacotes como 'docker', 'python3', 'nvidia-drivers' não são removidos."
    echo "    Use o gerenciador de pacotes do seu sistema (apt, pacman, dnf) para removê-los se desejar."
}

# --- Script Principal ---
main() {
    section "Desinstalador do Cluster AI"
    warn "Este script removerá os artefatos gerados pelo projeto e parará os serviços."
    warn "Ele NÃO removerá dependências de sistema (como Docker) ou modelos de IA baixados."
    echo ""

    if [ ! -d "$VENV_DIR" ] && [ ! -d "$LOG_DIR" ] && [ ! -d "$HOME_VENV_DIR" ]; then
        warn "Nenhum artefato de instalação comum encontrado. O projeto parece já estar limpo."
        exit 0
    fi

    if confirm_operation "Você tem certeza que deseja iniciar o processo de desinstalação?"; then
        stop_services
        echo ""
        remove_artifacts

        echo ""
        success "✅ Processo de desinstalação concluído!"
    else
        error "Desinstalação cancelada pelo usuário."
        exit 1
    fi
}

# Executa o script principal
main