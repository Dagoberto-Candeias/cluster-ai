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
    # Nota: Isso não desinstala o serviço Ollama do sistema, apenas para o processo.
    pkill -f "ollama serve" 2>/dev/null || log "Serviço Ollama não estava em execução."

    # Parar e remover container do OpenWebUI
    if sudo docker ps -a --format '{{.Names}}' | grep -q '^open-webui$'; then
        log "Parando e removendo container Docker 'open-webui'..."
        sudo docker stop open-webui >/dev/null 2>&1
        sudo docker rm open-webui >/dev/null 2>&1
        log "Container 'open-webui' removido."
    else
        log "Container Docker 'open-webui' não encontrado."
    fi

    log "Serviços parados com sucesso."
}

# --- Função para Remover Artefatos ---
remove_artifacts() {
    log "Os seguintes arquivos e diretórios gerados pelo projeto serão removidos:"
    echo -e "  - Ambiente Virtual: ${YELLOW}$VENV_DIR${NC}"
    echo -e "  - Scripts de Runtime: ${YELLOW}$RUNTIME_SCRIPTS_DIR${NC}"
    echo -e "  - Logs: ${YELLOW}$LOG_DIR${NC}"
    echo -e "  - Arquivo de Configuração: ${YELLOW}$CONFIG_FILE${NC}"
    echo ""

    read -p "Você tem certeza que deseja continuar? Esta ação não pode ser desfeita. (s/n): " confirmation

    if [[ "$confirmation" != "s" && "$confirmation" != "S" ]]; then
        error "Desinstalação cancelada pelo usuário."
        exit 1
    fi

    log "Iniciando a remoção dos artefatos..."

    # Remover diretórios
    [ -d "$VENV_DIR" ] && rm -rf "$VENV_DIR" && log "Ambiente virtual removido."
    [ -d "$RUNTIME_SCRIPTS_DIR" ] && rm -rf "$RUNTIME_SCRIPTS_DIR" && log "Scripts de runtime removidos."
    [ -d "$LOG_DIR" ] && rm -rf "$LOG_DIR" && log "Diretório de logs removido."

    # Remover arquivo de configuração
    [ -f "$CONFIG_FILE" ] && rm -f "$CONFIG_FILE" && log "Arquivo de configuração removido."

    log "Limpeza concluída."
}

# --- Script Principal ---
main() {
    echo -e "${BLUE}--- Desinstalador do Cluster AI ---${NC}"

    if [ ! -f "$CONFIG_FILE" ] && [ ! -d "$VENV_DIR" ]; then
        warn "Nenhum artefato de instalação encontrado. O projeto parece já estar limpo."
        exit 0
    fi

    stop_services
    echo ""
    remove_artifacts

    echo ""
    log "✅ Desinstalação concluída com sucesso!"
    log "As dependências de sistema (como Docker, Python) e os modelos do Ollama (~/.ollama) não foram removidos."
}

# Executa o script principal
main