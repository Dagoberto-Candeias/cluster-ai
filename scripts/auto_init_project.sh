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

    # Verificar yq (necessário para configuração YAML)
    if command_exists yq; then
        log_success "yq (processador YAML) encontrado"
    else
        log_warning "Comando 'yq' não encontrado. É necessário para gerenciar a configuração."
        read -p "Deseja tentar instalar o 'yq' via snap? (s/N): " choice
        if [[ "$choice" =~ ^[Ss]$ ]]; then
            if command_exists snap; then
                log_info "Instalando yq via snap..."
                sudo snap install yq
                log_success "yq instalado com sucesso!"
            else
                log_error "Comando 'snap' não encontrado. Não foi possível instalar o yq."
                log_info "Por favor, instale o yq manualmente: https://github.com/mikefarah/yq/#install"
                exit 1
            fi
        fi
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

# Verificar se porta está em uso
check_port_usage() {
    local port="$1"
    if lsof -i :$port >/dev/null 2>&1; then
        # Obter informações sobre o processo usando a porta
        local process_info=$(lsof -i :$port | tail -n +2 | head -1)
        echo "$process_info"
        return 0
    else
        return 1
    fi
}

# Resolver conflito de portas
resolve_port_conflict() {
    local port="$1"
    local service_name="$2"

    log_warning "Porta $port já está em uso pelo serviço $service_name"

    # Verificar se é um processo Dask
    if pgrep -f "dask-scheduler" >/dev/null; then
        log_info "Dask scheduler local já está rodando. Parando automaticamente os containers Docker para resolver conflito..."

        # Parar serviços Docker se estiverem rodando
        if command_exists docker; then
            if docker ps --format '{{.Names}}' | grep -qE "(dask-scheduler|dask-worker)"; then
                log_info "Parando containers Docker existentes..."
                if command_exists docker-compose; then
                    docker-compose down
                elif docker compose version >/dev/null 2>&1; then
                    docker compose down
                else
                    # Fallback: parar containers individualmente
                    docker stop $(docker ps -q --filter "name=dask") 2>/dev/null || true
                    docker rm $(docker ps -aq --filter "name=dask") 2>/dev/null || true
                fi
            fi
        fi
        log_success "Serviços Docker parados. Usando scheduler local."
        return 0
    else
        log_warning "Porta $port em uso por outro processo. Procurando alternativa..."
        return 1
    fi
}

# Encontrar porta disponível para Docker
find_available_port() {
    local base_port="$1"
    local max_attempts=10

    for ((i=0; i<max_attempts; i++)); do
        local test_port=$((base_port + i))
        if ! lsof -i :$test_port >/dev/null 2>&1; then
            echo "$test_port"
            return 0
        fi
    done

    log_error "Não foi possível encontrar uma porta disponível após $max_attempts tentativas"
    return 1
}

# Criar configuração Docker alternativa com portas diferentes
create_alternative_docker_config() {
    local scheduler_port="$1"
    local dashboard_port="$2"
    local config_file="docker-compose-alt.yml"

    log_info "Criando configuração Docker alternativa com portas $scheduler_port/$dashboard_port..."

    cat > "$config_file" << EOF
services:
  dask-scheduler:
    image: daskdev/dask:latest
    ports:
      - "${scheduler_port}:8786"
      - "${dashboard_port}:8787"
    command: dask-scheduler
    networks:
      - dask-network

  dask-worker:
    image: daskdev/dask:latest
    depends_on:
      - dask-scheduler
    command: dask-worker dask-scheduler:8786
    deploy:
      replicas: 1
    networks:
      - dask-network

networks:
  dask-network:
    driver: bridge
EOF

    log_success "Configuração alternativa criada: $config_file"
    echo "$config_file"
}

# Limpar configurações Docker alternativas
cleanup_alternative_configs() {
    if [[ -f "docker-compose-alt.yml" ]]; then
        rm -f "docker-compose-alt.yml"
        log_info "Configuração alternativa removida"
    fi
}

# Verificar e iniciar serviços Docker
check_docker_services() {
    log_info "Verificando serviços Docker..."

    # Verificar se docker-compose.yml existe
    if [[ -f "docker-compose.yml" ]]; then
        log_info "Arquivo docker-compose.yml encontrado"

        # Verificar se há um scheduler Dask local rodando
        local local_scheduler_running=false
        if pgrep -f "dask-scheduler" >/dev/null; then
            local_scheduler_running=true
            log_info "Scheduler Dask local detectado. Priorizando serviços locais."
        fi

        # Verificar se serviços Docker estão rodando
        if docker ps --format '{{.Names}}' | grep -qE "(dask-scheduler|dask-worker)"; then
            log_success "Serviços Docker estão rodando"

            # Se há scheduler local, verificar conflitos
            if [[ "$local_scheduler_running" == "true" ]]; then
                if check_port_usage 8787 >/dev/null; then
                    local port_user=$(check_port_usage 8787 | awk '{print $1}')
                    log_warning "Porta 8787 em uso por processo: $port_user"
                    resolve_port_conflict 8787 "Dask Dashboard"
                fi
            fi
        else
            # Serviços Docker não estão rodando
            if [[ "$local_scheduler_running" == "true" ]]; then
                log_info "Scheduler local ativo. Pulando inicialização Docker para evitar conflitos."
                return 0
            fi

            log_info "Serviços Docker não estão rodando. Tentando iniciar..."

            # Verificar conflitos de portas antes de iniciar
            local can_start_docker=true
            if check_port_usage 8786 >/dev/null || check_port_usage 8787 >/dev/null; then
                log_warning "Portas 8786/8787 em uso. Verificando se é possível resolver..."

                # Tentar resolver conflitos
                if check_port_usage 8786 >/dev/null; then
                    if ! resolve_port_conflict 8786 "Dask Scheduler"; then
                        can_start_docker=false
                    fi
                fi

                if check_port_usage 8787 >/dev/null; then
                    if ! resolve_port_conflict 8787 "Dask Dashboard"; then
                        can_start_docker=false
                    fi
                fi

                # Verificar novamente após resolução
                if [[ "$can_start_docker" == "true" ]]; then
                    if check_port_usage 8786 >/dev/null || check_port_usage 8787 >/dev/null; then
                        log_warning "Conflitos de porta não resolvidos. Pulando inicialização Docker."
                        can_start_docker=false
                    fi
                fi
            fi

            # Tentar iniciar serviços Docker se não há conflitos
            if [[ "$can_start_docker" == "true" ]]; then
                local docker_command=""
                local docker_ps_command=""
                local compose_file="docker-compose.yml"

                # Determinar qual comando Docker usar
                if command_exists docker-compose; then
                    docker_command="docker-compose -f $compose_file up -d"
                    docker_ps_command="docker-compose -f $compose_file ps"
                elif command_exists docker && docker compose version >/dev/null 2>&1; then
                    docker_command="docker compose -f $compose_file up -d"
                    docker_ps_command="docker compose -f $compose_file ps"
                else
                    log_error "docker-compose ou 'docker compose' não encontrado"
                    log_info "Instale docker-compose ou use './manager.sh start' para iniciar os serviços"
                    return 1
                fi

                log_info "Iniciando serviços Docker..."
                if eval "$docker_command"; then
                    log_info "Aguardando inicialização dos containers..."
                    sleep 10  # Aguardar mais tempo para inicialização completa

                    if docker ps --format '{{.Names}}' | grep -qE "(dask-scheduler|dask-worker)"; then
                        log_success "Serviços Docker iniciados com sucesso"

                        # Verificar se os serviços estão realmente acessíveis
                        if curl -s --max-time 10 http://localhost:8787 >/dev/null 2>&1; then
                            log_success "Dashboard Docker acessível em http://localhost:8787"
                        else
                            log_warning "Dashboard Docker pode não estar totalmente pronto"
                        fi
                    else
                        log_warning "Serviços Docker foram iniciados mas containers podem não estar prontos"
                        log_info "Verificando status dos containers..."
                        eval "$docker_ps_command"
                    fi
                else
                    log_error "Falha ao iniciar serviços Docker"
                    log_info "Verificando possíveis causas..."
                    eval "$docker_ps_command"
                    log_info "Use './manager.sh start' para tentar iniciar manualmente"
                fi

                # Limpar configuração alternativa se foi usada
                cleanup_alternative_configs
            else
                # Tentar usar portas alternativas se conflitos não puderam ser resolvidos
                log_warning "Tentando usar portas alternativas para Docker..."

                local alt_scheduler_port=$(find_available_port 8788)
                local alt_dashboard_port=$(find_available_port 8789)

                if [[ -n "$alt_scheduler_port" && -n "$alt_dashboard_port" ]]; then
                    local alt_config=$(create_alternative_docker_config "$alt_scheduler_port" "$alt_dashboard_port")

                    if [[ -n "$alt_config" ]]; then
                        log_info "Tentando iniciar Docker com configuração alternativa..."

                        local docker_command=""
                        local docker_ps_command=""

                        if command_exists docker-compose; then
                            docker_command="docker-compose -f $alt_config up -d"
                            docker_ps_command="docker-compose -f $alt_config ps"
                        elif command_exists docker && docker compose version >/dev/null 2>&1; then
                            docker_command="docker compose -f $alt_config up -d"
                            docker_ps_command="docker compose -f $alt_config ps"
                        fi

                        if [[ -n "$docker_command" ]]; then
                            if eval "$docker_command"; then
                                sleep 10
                                if docker ps --format '{{.Names}}' | grep -qE "(dask-scheduler|dask-worker)"; then
                                    log_success "Serviços Docker iniciados com portas alternativas"
                                    log_info "Scheduler: http://localhost:$alt_scheduler_port"
                                    log_info "Dashboard: http://localhost:$alt_dashboard_port"
                                else
                                    log_warning "Falha ao iniciar com portas alternativas"
                                    eval "$docker_ps_command"
                                fi
                            fi
                        fi

                        # Limpar configuração alternativa
                        cleanup_alternative_configs
                    fi
                else
                    log_error "Não foi possível encontrar portas alternativas disponíveis"
                    log_info "Considere parar o scheduler local ou liberar as portas 8786/8787"
                fi
            fi
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

    # Verificar arquivo de configuração principal (YAML)
    if [[ -f "cluster.yaml" ]]; then
        log_success "Arquivo cluster.yaml encontrado"
    else
        log_warning "Arquivo cluster.yaml não encontrado. Usando configurações padrão."
    fi

    # Verificar arquivo de configuração automática
    if [[ -f "cluster_auto.conf" ]]; then
        log_success "Arquivo cluster_auto.conf encontrado"
    else
        log_warning "Arquivo cluster_auto.conf não encontrado"
    fi
}

# Testar conectividade de um worker
test_worker_connectivity() {
    local hostname="$1"
    local ip="$2"
    local user="$3"
    local port="$4"

    # Primeiro tentar ping
    if ping -c 1 -W 2 "$ip" >/dev/null 2>&1; then
        # Se ping funciona, testar SSH
        if timeout 5 ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "echo 'test'" >/dev/null 2>&1; then
            echo "online"
        else
            # SSH falhou, mas ping funcionou - worker está acessível mas SSH não configurado
            echo "pingable (SSH não configurado)"
        fi
    else
        echo "offline"
    fi
}

# Listar workers configurados com status de conectividade
list_workers() {
    local config_file="$HOME/.cluster_config/nodes_list.conf"

    if [[ ! -f "$config_file" ]]; then
        log_warning "Arquivo de configuração dos workers não encontrado: $config_file"
        return 1
    fi

    log_info "Verificando lista de workers configurados..."

    local active_workers=()
    local inactive_workers=()

    while IFS= read -r line; do
        if [[ $line =~ ^# ]] || [[ -z "$line" ]]; then
            continue
        fi

        local hostname alias ip user port status
        read -r hostname alias ip user port status <<< "$line"

        # Testar conectividade se IP estiver definido
        local connectivity_status=""
        if [[ -n "$ip" && "$ip" != " " ]]; then
            local connectivity_result
            connectivity_result=$(test_worker_connectivity "$hostname" "$ip" "${user:-$USER}" "${port:-22}")
            case "$connectivity_result" in
                "online")
                    connectivity_status="${GREEN}ONLINE${NC}"
                    ;;
                "pingable (SSH não configurado)")
                    connectivity_status="${YELLOW}PING OK (SSH requer config)${NC}"
                    ;;
                *)
                    connectivity_status="${RED}OFFLINE${NC}"
                    ;;
            esac
        fi

        # Formatar display com status de conectividade
        local worker_display="$hostname ($ip) - Status: $connectivity_status"

        if [[ "$status" == "active" ]]; then
            active_workers+=("$worker_display")
        else
            inactive_workers+=("$worker_display")
        fi
    done < "$config_file"

    echo
    log_info "Workers Ativos:"
    if [[ ${#active_workers[@]} -gt 0 ]]; then
        for worker in "${active_workers[@]}"; do
            echo -e "  • $worker"
        done
    else
        echo "  • Nenhum worker ativo"
    fi

    echo
    log_info "Workers Inativos:"
    if [[ ${#inactive_workers[@]} -gt 0 ]]; then
        for worker in "${inactive_workers[@]}"; do
            echo -e "  • $worker"
        done
    else
        echo "  • Nenhum worker inativo"
    fi
    echo
}

# Atualizar lista de workers via descoberta de rede
refresh_worker_list() {
    log_info "Atualizando lista de workers via descoberta de rede..."

    if [[ -f "scripts/utils/network_discovery.sh" ]]; then
        # Executar descoberta de rede em background para não bloquear
        bash scripts/utils/network_discovery.sh discover --no-mdns > /dev/null 2>&1 &
        local pid=$!

        # Aguardar um pouco para a descoberta
        sleep 5

        # Verificar se o processo ainda está rodando
        if kill -0 $pid 2>/dev/null; then
            log_info "Descoberta de rede em andamento... (PID: $pid)"
        else
            log_success "Descoberta de rede concluída"
        fi
    else
        log_warning "Script de descoberta de rede não encontrado"
    fi
}

# Sincronizar configuração de workers para o formato JSON
sync_worker_config() {
    if [ -f "scripts/utils/sync_config.sh" ] && command_exists yq; then
        log_info "Sincronizando configuração de workers para YAML..."
        bash scripts/utils/sync_config.sh
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
    sync_worker_config # Adicionado aqui para garantir a sincronização
    refresh_worker_list
    start_dask_cluster
    start_dask_workers
    list_workers
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
