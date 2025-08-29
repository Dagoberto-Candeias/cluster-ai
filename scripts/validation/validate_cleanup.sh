#!/bin/bash

# 🧪 Script de Validação de Limpeza - Cluster AI
# Descrição: Verifica se o script de desinstalação removeu todos os artefatos do projeto.

# --- Carregar Funções Comuns ---
COMMON_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO: Script de funções comuns não encontrado em $COMMON_SCRIPT_PATH"
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# --- Definição de Caminhos ---
PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
CONFIG_FILE="$PROJECT_ROOT/.cluster_config"
VENV_DIR="$PROJECT_ROOT/.venv"
RUNTIME_SCRIPTS_DIR="$PROJECT_ROOT/scripts/runtime"
LOG_DIR="$PROJECT_ROOT/logs"

# Caminhos no diretório HOME do usuário
HOME_CLUSTER_ROLE="$HOME/.cluster_role"
HOME_CLUSTER_SCRIPTS="$HOME/cluster_scripts"
HOME_CLUSTER_ENV="$HOME/cluster_env"
HOME_OLLAMA_DIR="$HOME/.ollama"
HOME_CLUSTER_BACKUPS="$HOME/cluster_backups"


FAIL_COUNT=0

# --- Funções de Verificação ---

check_files_and_dirs() {
    info "Verificando arquivos e diretórios do projeto"
    
    if [ ! -d "$VENV_DIR" ]; then
        success "Diretório do ambiente virtual (.venv) foi removido."
    else
        fail "Diretório do ambiente virtual (.venv) ainda existe."
    fi

    if [ ! -d "$RUNTIME_SCRIPTS_DIR" ]; then
        success "Diretório de scripts de runtime foi removido."
    else
        fail "Diretório de scripts de runtime ainda existe."
    fi

    if [ ! -d "$LOG_DIR" ]; then
        success "Diretório de logs foi removido."
    else
        fail "Diretório de logs ainda existe."
    fi

    if [ ! -f "$CONFIG_FILE" ]; then
        success "Arquivo de configuração (.cluster_config) foi removido."
    else
        fail "Arquivo de configuração (.cluster_config) ainda existe."
    fi

    info "Verificando artefatos no diretório HOME"

    local home_artifacts=("$HOME_CLUSTER_ROLE" "$HOME_CLUSTER_SCRIPTS" "$HOME_CLUSTER_ENV" "$HOME_OLLAMA_DIR" "$HOME_CLUSTER_BACKUPS")
    for item in "${home_artifacts[@]}"; do
        if [ ! -e "$item" ]; then
            success "Artefato do HOME ('$(basename "$item")') foi removido."
        else
            fail "Artefato do HOME ('$(basename "$item")') ainda existe em $item."
        fi
    done
}

check_processes() {
    info "Verificando processos em execução"

    if ! process_running "dask-scheduler"; then
        success "Processo Dask Scheduler não está em execução."
    else
        fail "Processo Dask Scheduler ainda está em execução."
    fi

    if ! process_running "dask-worker"; then
        success "Processo Dask Worker não está em execução."
    else
        fail "Processo Dask Worker ainda está em execução."
    fi

    # Ollama pode rodar como um serviço de sistema ou um processo manual
    if command_exists systemctl && service_active "ollama"; then
        fail "Serviço 'ollama.service' ainda está ativo."
    elif process_running "ollama serve"; then
        fail "Processo 'ollama serve' ainda está em execução."
    else
        success "Processo/serviço Ollama não está em execução."
    fi
}

check_services() {
    info "Verificando serviços do sistema (systemd)"
    if ! command_exists systemctl; then
        warn "Comando 'systemctl' não encontrado. Pulando verificação de serviços."
        return
    fi

    # Adicione aqui nomes de serviços que o cluster possa criar, ex: dask-scheduler.service
    # Exemplo:
    # if ! service_active "dask-scheduler.service"; then success "Serviço dask-scheduler não está ativo."; else fail "Serviço dask-scheduler ainda está ativo."; fi
}

check_docker_containers() {
    info "Verificando containers Docker"

    if ! command -v docker >/dev/null 2>&1; then
        info "Docker não está instalado. Pulando verificação de container."
        return
    fi

    # Verifica se o usuário pode rodar docker sem sudo
    if ! docker ps >/dev/null 2>&1; then
        warn "Docker não está acessível para o usuário atual. Tentando com sudo."
        DOCKER_CMD="sudo docker"
    else
        DOCKER_CMD="docker"
    fi

    if ! $DOCKER_CMD ps -a --format '{{.Names}}' | grep -q 'open-webui'; then
        success "Container Docker 'open-webui' foi removido."
    else
        fail "Container Docker 'open-webui' ainda existe."
    fi
}

# --- Script Principal ---
main() {
    echo "Iniciando validação da limpeza do ambiente Cluster AI..."
    echo ""

    check_files_and_dirs
    echo ""
    check_processes
    echo ""
    check_services
    echo ""
    check_docker_containers
    echo ""

    info "Resultado Final da Validação"
    if [ "$FAIL_COUNT" -eq 0 ]; then
        echo -e "${GREEN}✅ Validação concluída com sucesso! O ambiente foi limpo corretamente.${NC}"
    else
        echo -e "${RED}❌ Validação falhou. Foram encontrados $FAIL_COUNT problemas.${NC}"
        echo -e "${YELLOW}Artefatos do projeto ainda existem. Execute ./uninstall.sh novamente ou remova-os manualmente.${NC}"
        exit 1
    fi
}

main
