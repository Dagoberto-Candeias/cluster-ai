#!/bin/bash

# Script de Inicialização Automática do Projeto Cluster AI
# Garante que todos os serviços sejam inicializados corretamente

set -e  # Para no primeiro erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções de logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar se estamos no diretório correto
check_project_directory() {
    if [[ ! -f "manager.sh" ]] || [[ ! -f "requirements.txt" ]]; then
        log_error "Este script deve ser executado no diretório raiz do projeto Cluster AI"
        exit 1
    fi
    log_success "Diretório do projeto verificado"
}

# Ativar ambiente virtual
activate_venv() {
    if [[ -d "venv" ]]; then
        log_info "Ativando ambiente virtual..."
        source venv/bin/activate
        log_success "Ambiente virtual ativado"
    else
        log_warning "Ambiente virtual não encontrado. Criando..."
        python3 -m venv venv
        source venv/bin/activate
        log_info "Instalando dependências..."
        pip install -r requirements.txt
        log_success "Ambiente virtual criado e dependências instaladas"
    fi
}

# Verificar e instalar dependências do sistema
check_system_dependencies() {
    log_info "Verificando dependências do sistema..."

    # Verificar Docker
    if command_exists docker; then
        log_success "Docker encontrado"
    else
        log_warning "Docker não encontrado. Alguns recursos podem não funcionar."
    fi

    # Verificar Python
    if command_exists python3; then
        log_success "Python3 encontrado"
    else
        log_error "Python3 não encontrado. Instalação necessária."
        exit 1
    fi

    # Verificar pip
    if command_exists pip; then
        log_success "Pip encontrado"
    else
        log_error "Pip não encontrado. Instalação necessária."
        exit 1
    fi
}

# Verificar e instalar dependências Python
check_python_dependencies() {
    log_info "Verificando dependências Python..."

    # Lista de pacotes essenciais
    essential_packages=("dask" "distributed" "paramiko" "pytest")

    for package in "${essential_packages[@]}"; do
        if python -c "import $package" 2>/dev/null; then
            log_success "Pacote $package encontrado"
        else
            log_warning "Pacote $package não encontrado. Instalando..."
            pip install $package
            log_success "Pacote $package instalado"
        fi
    done
}

# Inicializar cluster Dask
start_dask_cluster() {
    log_info "Verificando cluster Dask..."

    # Verificar se scheduler já está rodando
    if pgrep -f "dask-scheduler" > /dev/null; then
        log_success "Dask scheduler já está rodando"
        return 0
    fi

    log_info "Iniciando Dask scheduler..."

    # Encontrar uma porta disponível automaticamente
    local port=8786
    local max_attempts=10

    for ((i=0; i<max_attempts; i++)); do
        if ! lsof -i :$port > /dev/null 2>&1; then
            log_info "Tentando iniciar Dask scheduler na porta $port..."
            nohup dask-scheduler --port $port > logs/dask_scheduler.log 2>&1 &
            sleep 3

            if pgrep -f "dask-scheduler" > /dev/null; then
                log_success "Dask scheduler iniciado na porta $port"
                # Verificar se dashboard está acessível
                local dashboard_port=$((port + 1))
                if curl -s http://localhost:$dashboard_port > /dev/null 2>&1; then
                    log_success "Dask dashboard acessível em http://localhost:$dashboard_port"
                else
                    log_warning "Dask dashboard não está acessível na porta $dashboard_port"
                fi
                return 0
            else
                log_warning "Falha ao iniciar Dask scheduler na porta $port"
            fi
        fi
        port=$((port + 1))
    done

    log_error "Não foi possível encontrar uma porta disponível para o Dask scheduler após $max_attempts tentativas"
    return 1
}

# Inicializar workers Dask
start_dask_workers() {
    log_info "Verificando workers Dask..."

    # Contar workers ativos
    worker_count=$(pgrep -f "dask-worker" | wc -l)

    if [[ $worker_count -gt 0 ]]; then
        log_success "$worker_count worker(s) Dask já ativo(s)"
    else
        log_info "Iniciando workers Dask..."

        # Determinar porta do scheduler
        local scheduler_port=8786
        if pgrep -f "dask-scheduler" > /dev/null; then
            # Tentar encontrar a porta do scheduler ativo
            scheduler_port=$(ps aux | grep dask-scheduler | grep -oP "port \K\d+" | head -1 || echo "8786")
        fi

        # Iniciar worker básico
        log_info "Iniciando worker básico na porta $scheduler_port..."
        nohup dask-worker localhost:$scheduler_port --nthreads 2 --memory-limit 4GB > logs/dask_worker.log 2>&1 &
        sleep 2

        if pgrep -f "dask-worker" > /dev/null; then
            log_success "Worker Dask iniciado"
        else
            log_error "Falha ao iniciar worker Dask"
            return 1
        fi
    fi
}

# Verificar serviços Docker
check_docker_services() {
    log_info "Verificando serviços Docker..."

    # Verificar se docker-compose.yml existe
    if [[ -f "docker-compose.yml" ]]; then
        log_info "Arquivo docker-compose.yml encontrado"

        # Verificar se serviços estão rodando
        if docker ps | grep -q "cluster-ai"; then
            log_success "Serviços Docker estão rodando"
        else
            log_info "Serviços Docker não estão rodando. Use './manager.sh' para iniciá-los."
        fi
    else
        log_info "Arquivo docker-compose.yml não encontrado"
    fi
}

# Criar diretórios necessários
create_directories() {
    log_info "Criando diretórios necessários..."

    directories=("logs" "data" "models" "backups" "test_logs")

    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            log_success "Diretório $dir criado"
        else
            log_info "Diretório $dir já existe"
        fi
    done
}

# Verificar configuração
check_configuration() {
    log_info "Verificando configuração..."

    # Verificar arquivo de configuração principal
    if [[ -f "cluster.conf" ]]; then
        log_success "Arquivo cluster.conf encontrado"
    else
        log_warning "Arquivo cluster.conf não encontrado. Usando configurações padrão."
    fi

    # Verificar arquivo de configuração automática
    if [[ -f "cluster_auto.conf" ]]; then
        log_success "Arquivo cluster_auto.conf encontrado"
    else
        log_warning "Arquivo cluster_auto.conf não encontrado"
    fi
}

# Função principal
main() {
    echo
    echo "========================================"
    echo "🚀 INICIALIZAÇÃO AUTOMÁTICA - CLUSTER AI"
    echo "========================================"
    echo

    # Executar verificações e inicializações
    check_project_directory
    create_directories
    check_system_dependencies
    activate_venv
    check_python_dependencies
    check_configuration
    start_dask_cluster
    start_dask_workers
    check_docker_services

    echo
    echo "========================================"
    log_success "INICIALIZAÇÃO CONCLUÍDA!"
    echo "========================================"
    echo
    log_info "Serviços ativos:"
    echo "  • Dask Scheduler: http://localhost:8786"
    echo "  • Dask Dashboard: http://localhost:8787"
    echo "  • Manager: ./manager.sh"
    echo
    log_info "Para usar o cluster:"
    echo "  source venv/bin/activate"
    echo "  python demo_cluster.py"
    echo
}

# Executar função principal
main "$@"
