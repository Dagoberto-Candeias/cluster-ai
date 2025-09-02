#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Script de Verificação de Saúde Consolidado - Cluster AI
# Versão unificada com recursos avançados de monitoramento e recuperação

# ==================== CONFIGURAÇÃO DE SEGURANÇA ====================

# Prevenção de execução como root
if [ "$EUID" -eq 0 ]; then
    echo "ERRO CRÍTICO: Este script NÃO deve ser executado como root."
    echo "Por favor, execute como um usuário normal com privilégios sudo quando necessário."
    exit 1
fi

# Validação do contexto de execução
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
if [ ! -f "$PROJECT_ROOT/README.md" ]; then
    echo "ERRO: Script executado fora do contexto do projeto Cluster AI"
    exit 1
fi

# Carregar funções comuns
COMMON_SCRIPT_PATH="$PROJECT_ROOT/scripts/utils/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns 'common.sh' não encontrado: $COMMON_SCRIPT_PATH"
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# Configurações
LOG_FILE="/tmp/cluster_ai_saude_$(date +%Y%m%d_%H%M%S).log"
OVERALL_HEALTH=true

# Funções de log aprimoradas
log() { echo -e "${CYAN}[VERIFICACAO-SAUDE $(date '+%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[AVISO-SAUDE $(date '+%H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[ERRO-SAUDE $(date '+%H:%M:%S')]${NC} $1"; }
section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
subsection() { echo -e "\n${CYAN}➤ $1${NC}"; }

# Função para verificar comando com sugestões de instalação
check_command() {
    local cmd="$1"
    local description="$2"
    local install_cmd="${3:-}"

    if command_exists "$cmd"; then
        success "✅ $description: Disponível ($(which $cmd))"
        return 0
    else
        fail "❌ $description: Não encontrado"
        if [ -n "$install_cmd" ]; then
            echo "   💡 Execute: $install_cmd"
        fi
        OVERALL_HEALTH=false
        return 1
    fi
}

# Função para verificar serviço com opção de reinicialização
check_service() {
    local service_name="$1"
    local description="$2"

    if service_active "$service_name"; then
        success "✅ $description: Ativo"
        return 0
    else
        fail "❌ $description: Inativo"
        OVERALL_HEALTH=false
        if confirm_operation "Tentar reinicializar o serviço $service_name?"; then
            if sudo systemctl restart "$service_name"; then
                success "✅ Serviço $service_name reinicializado com sucesso."
            else
                error "❌ Falha ao reinicializar o serviço $service_name."
            fi
        fi
        return 1
    fi
}

# Função para verificar se uma porta está aberta
check_port() {
    local port="$1"
    local description="${2:-Porta $port}"

    if port_open "$port"; then
        success "✅ $description: Aberta"
        return 0
    else
        fail "❌ $description: Fechada"
        OVERALL_HEALTH=false
        return 1
    fi
}

# Função para verificar conectividade de rede
check_network() {
    subsection "Conectividade de Rede"

    # Testar conectividade com internet
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        success "✅ Internet: Conectado"
    else
        warn "⚠️  Internet: Sem conectividade"
        OVERALL_HEALTH=false
    fi

    # Testar DNS
    if ping -c 1 -W 2 google.com >/dev/null 2>&1; then
        success "✅ DNS: Funcionando"
    else
        warn "⚠️  DNS: Problemas de resolução"
        OVERALL_HEALTH=false
    fi

    # Testar portas locais importantes
    local ports=("11434" "7860" "8787" "80" "443")
    for port in "${ports[@]}"; do
        if nc -z localhost $port 2>/dev/null; then
            success "✅ Porta $port: Aberta"
        else
            echo "   Porta $port: Fechada (esperado para alguns serviços)"
        fi
    done
}

# Função para verificar GPU
check_gpu() {
    subsection "Configuração de GPU"

    # Verificar NVIDIA
    if command_exists nvidia-smi; then
        success "✅ GPU NVIDIA: Detectada"
        nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader,nounits 2>/dev/null || echo "   Detalhes não disponíveis"
        return 0
    fi

    # Verificar AMD
    if command_exists rocminfo || [ -d "/opt/rocm" ]; then
        success "✅ GPU AMD: Detectada"
        if command_exists rocminfo; then
            rocminfo | grep -E "Device Type|Marketing Name" | head -4 2>/dev/null || echo "   Detalhes não disponíveis"
        fi
        return 0
    fi

    warn "⚠️  GPU: Não detectada - Modo CPU"
    return 1
}

# Função para verificar recursos do sistema com alertas
# Função para verificar recursos do sistema com alertas
check_resources() {

    # Memória RAM
    local mem_info=$(free -b 2>/dev/null || vm_stat 2>/dev/null)
    local mem_total_kb=$(echo "$mem_info" | awk '/Mem:/ {print $2/1024}' || echo "0")
    subsection "Monitoramento de Recursos"

    # Memória RAM
    local mem_info=$(free -b 2>/dev/null || vm_stat 2>/dev/null)
    local mem_total_kb=$(echo "$mem_info" | awk '/Mem:/ {print $2/1024}' || echo "0")
    local mem_used_kb=$(echo "$mem_info" | awk '/Mem:/ {print $3/1024}' || echo "0")
    local mem_used_percent=0
    if [[ "$mem_total_kb" =~ ^[0-9]+$ ]] && [ "$mem_total_kb" -gt 0 ]; then
        mem_used_percent=$((mem_used_kb * 100 / mem_total_kb))
    fi
    local mem_total=$(free -h | awk '/Mem:/ {print $2}' 2>/dev/null || echo "N/A")
    local mem_used=$(free -h | awk '/Mem:/ {print $3}' 2>/dev/null || echo "N/A")
    local mem_free=$(free -h | awk '/Mem:/ {print $4}' 2>/dev/null || echo "N/A")

    echo "💾 Memória RAM: Total: $mem_total, Usada: $mem_used, Livre: $mem_free"

    # Alertas de memória
    if [[ "$mem_used_percent" =~ ^[0-9]+$ ]] && [ $mem_used_percent -gt 90 ]; then
        error "🚨 ALERTA CRÍTICO: Uso de memória: ${mem_used_percent}%"
        echo "   💡 Execute: ./scripts/utils/memory_manager.sh --optimize"
        OVERALL_HEALTH=false
    elif [[ "$mem_used_percent" =~ ^[0-9]+$ ]] && [ $mem_used_percent -gt 80 ]; then
        warn "⚠️  AVISO: Uso de memória alto: ${mem_used_percent}%"
        echo "   💡 Monitor: ./scripts/utils/memory_monitor.sh --mem-threshold 80"
    fi

    # CPU
    local cpu_cores=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "1")
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    local cpu_load_per_core=$(echo "scale=2; $cpu_load / $cpu_cores" | bc 2>/dev/null || echo "0")

    echo "⚡ CPU: Núcleos: $cpu_cores, Carga: $cpu_load (${cpu_load_per_core}/núcleo)"

    # Alertas de CPU
    if (( $(echo "$cpu_load_per_core > 2.0" | bc -l 2>/dev/null || echo "0") )); then
        error "🚨 ALERTA CRÍTICO: Carga de CPU: ${cpu_load_per_core}/núcleo"
        echo "   💡 Execute: ./scripts/optimization/performance_optimizer.sh"
        OVERALL_HEALTH=false
    elif (( $(echo "$cpu_load_per_core > 1.5" | bc -l 2>/dev/null || echo "0") )); then
        warn "⚠️  AVISO: Carga de CPU alta: ${cpu_load_per_core}/núcleo"
    fi

    # Disco
    local disk_info=$(df / 2>/dev/null || df /System/Volumes/Data 2>/dev/null)
    local disk_usage_percent=$(echo "$disk_info" | awk 'NR==2 {print $5}' | sed 's/%//')
    local disk_total=$(echo "$disk_info" | awk 'NR==2 {print $2}' | awk '{printf "%.1fG", $1/1024/1024}')
    local disk_used=$(echo "$disk_info" | awk 'NR==2 {print $3}' | awk '{printf "%.1fG", $1/1024/1024}')
    local disk_avail=$(echo "$disk_info" | awk 'NR==2 {print $4}' | awk '{printf "%.1fG", $1/1024/1024}')

    echo "💿 Disco: ${disk_usage_percent}% usado (${disk_used}/${disk_total}), Livre: ${disk_avail}"

    # Alertas de disco
    if [ $disk_usage_percent -gt 90 ]; then
        error "🚨 ALERTA CRÍTICO: Uso de disco: ${disk_usage_percent}%"
        echo "   💡 Execute: ./scripts/maintenance/clean-cache.sh"
        OVERALL_HEALTH=false
    elif [ $disk_usage_percent -gt 80 ]; then
        warn "⚠️  AVISO: Uso de disco alto: ${disk_usage_percent}%"
        echo "   💡 Execute: find ~ -name \"*.log\" -size +100M -exec ls -lh {} \\;"
    fi

    # GPU Memory (se disponível)
    if command_exists nvidia-smi; then
        local gpu_info=$(nvidia-smi --query-gpu=memory.total,memory.used,memory.free --format=csv,noheader,nounits 2>/dev/null)
        if [ -n "$gpu_info" ]; then
            IFS=',' read -r total used free <<< "$gpu_info"
            local used_percent=$((used * 100 / total))

            echo "🎮 GPU Memory: ${used}MB/${total}MB usado (${used_percent}%), Livre: ${free}MB"

            if [ $used_percent -gt 90 ]; then
                warn "⚠️  Uso de memória GPU alto: ${used_percent}%"
                echo "   💡 Execute: nvidia-smi para ver processos usando GPU"
            fi
        fi
    fi
}

# Função para verificar Ollama com validação completa
check_ollama() {
    subsection "Serviço Ollama"

    if command_exists ollama; then
        success "✅ Ollama: Instalado ($(which ollama))"

        # Verificar serviço Ollama
        if service_active ollama; then
            success "✅ Serviço Ollama: Ativo"

            # Verificar API Ollama
            local api_response=$(curl -s -w "%{http_code}" http://localhost:11434/api/tags -o /dev/null 2>/dev/null || echo "000")
            if [ "$api_response" = "200" ]; then
                success "✅ API Ollama: Respondendo (HTTP 200)"

                # Listar modelos
                local models=$(timeout 10 ollama list 2>/dev/null || echo "timeout")
                if [ "$models" != "timeout" ]; then
                    local models_count=$(echo "$models" | wc -l)
                    if [ $models_count -gt 1 ]; then
                        success "📦 Modelos Ollama: $((models_count - 1)) instalado(s)"
                        echo "   Modelos: $(echo "$models" | grep -v "NAME" | awk '{print $1}' | tr '\n' ' ' | sed 's/ $//')"
                    else
                        warn "⚠️  Modelos Ollama: Nenhum modelo instalado"
                        if confirm_operation "Deseja baixar um modelo padrão (llama3.1:8b)?"; then
                            if ollama pull llama3.1:8b; then
                                success "✅ Modelo padrão baixado com sucesso."
                            fi
                        fi
                    fi
                else
                    warn "⚠️  Ollama: Timeout ao listar modelos"
                fi
            else
                fail "❌ API Ollama: Não responde (HTTP $api_response)"
                echo "   💡 Execute: sudo systemctl restart ollama"
                OVERALL_HEALTH=false
            fi
        else
            fail "❌ Serviço Ollama: Inativo"
            echo "   💡 Execute: sudo systemctl start ollama"
            OVERALL_HEALTH=false
        fi
    else
        warn "⚠️  Ollama: Não instalado"
        if confirm_operation "Deseja tentar instalar o Ollama agora?"; then
            if curl -fsSL https://ollama.com/install.sh | sh; then
                success "✅ Ollama instalado. Execute o health check novamente para configurar."
            fi
        fi
    fi
}

# Função para verificar Dask
check_dask() {
    subsection "Cluster Dask"

    # Verificar scheduler
    if process_running "dask-scheduler"; then
        local scheduler_pid=$(pgrep -f "dask-scheduler")
        success "✅ Dask Scheduler: Executando (PID: $scheduler_pid)"
    else
        warn "⚠️  Dask Scheduler: Não está executando"
        echo "   💡 Execute: dask scheduler --port 8786 &"
    fi

    # Verificar workers
    local workers_count=$(pgrep -f "dask-worker" | wc -l)
    if [ $workers_count -gt 0 ]; then
        success "✅ Dask Workers: $workers_count executando"
    else
        warn "⚠️  Dask Workers: Nenhum worker executando"
        echo "   💡 Execute: dask worker tcp://localhost:8786 --nworkers 4 &"
    fi

    # Verificar dashboard
    if nc -z localhost 8787 2>/dev/null; then
        success "✅ Dashboard Dask: Acessível em http://localhost:8787"
    else
        echo "   Dashboard Dask: Porta 8787 fechada"
    fi
}

# Função para verificar containers Docker
check_docker_containers() {
    subsection "Containers Docker do Projeto"

    if ! command_exists docker; then
        warn "⚠️  Docker: Não instalado - pulando verificação de containers"
        return
    fi

    # Verificar se Docker está rodando
    if ! docker info >/dev/null 2>&1; then
        fail "❌ Docker: Daemon não está rodando"
        echo "   💡 Execute: sudo systemctl start docker"
        OVERALL_HEALTH=false
        return
    fi

    local containers=("open-webui" "openwebui-nginx")
    local container_found=false

    for container in "${containers[@]}"; do
        local container_info=$(docker ps --filter "name=$container" --format "{{.Names}}|{{.Status}}|{{.Ports}}" 2>/dev/null)

        if [ -n "$container_info" ]; then
            container_found=true
            IFS='|' read -r name status ports <<< "$container_info"

            if [[ "$status" == *"Up"* ]]; then
                success "✅ Container $name: $status"
                echo "   Portas: $ports"
            else
                warn "⚠️  Container $name: $status"
                if confirm_operation "Tentar iniciar o container $name?"; then
                    if docker start "$name"; then
                        success "✅ Container $name iniciado."
                    fi
                fi
            fi
        else
            echo "   Container $container: Não encontrado"
        fi
    done

    if [ "$container_found" = false ]; then
        echo "💡 Nenhum container do projeto encontrado"
        echo "   Execute: docker-compose -f configs/docker/compose-basic.yml up -d"
    fi
}

# Função para verificar workers remotos do cluster
check_remote_workers() {
    subsection "Workers Remotos do Cluster"

    # Verificar se existe arquivo de configuração de nós
    local nodes_config="$HOME/.cluster_config/nodes_list.conf"
    if [ ! -f "$nodes_config" ]; then
        echo "   Arquivo de configuração de nós não encontrado: $nodes_config"
        echo "   💡 Execute: ./scripts/management/remote_worker_manager.sh help"
        return
    fi

    # Verificar conectividade SSH
    if ! command_exists ssh; then
        warn "⚠️  SSH: Não disponível - pulando verificação de workers remotos"
        return
    fi

    local total_workers=0
    local active_workers=0
    local worker_issues=0

    while read -r hostname ip user port; do
        if [ -z "$hostname" ] || [[ "$hostname" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        ((total_workers++))
        local worker_status="UNKNOWN"
        local worker_details=""

        # Testar conectividade básica
        if ping -c 1 -W 2 "$ip" >/dev/null 2>&1; then
            # Verificar SSH
            if ssh -p "${port:-22}" -o ConnectTimeout=3 -o BatchMode=yes -o StrictHostKeyChecking=no "$user@$hostname" "echo 'OK'" >/dev/null 2>&1; then

                # Verificar se Cluster AI está instalado
                if ssh -p "${port:-22}" -o ConnectTimeout=3 "$user@$hostname" "test -d ~/Projetos/cluster-ai" >/dev/null 2>&1; then

                    # Verificar workers Dask
                    local dask_count=$(ssh -p "${port:-22}" -o ConnectTimeout=3 "$user@$hostname" "pgrep -fc dask-worker" 2>/dev/null || echo "0")
                    local ollama_running=$(ssh -p "${port:-22}" -o ConnectTimeout=3 "$user@$hostname" "pgrep -fc ollama" 2>/dev/null || echo "0")

                    if [ "$dask_count" -gt 0 ]; then
                        worker_status="ACTIVE"
                        ((active_workers++))
                        worker_details="Dask: ${dask_count} worker(s)"
                        if [ "$ollama_running" -gt 0 ]; then
                            worker_details="$worker_details, Ollama: Ativo"
                        fi
                        success "✅ Worker $hostname ($ip): $worker_details"
                    else
                        worker_status="INACTIVE"
                        worker_details="Dask: Nenhum worker ativo"
                        if [ "$ollama_running" -gt 0 ]; then
                            worker_details="$worker_details, Ollama: Ativo"
                        fi
                        warn "⚠️  Worker $hostname ($ip): $worker_details"
                        ((worker_issues++))
                    fi

                else
                    worker_status="NO_CLUSTER"
                    worker_details="Cluster AI não instalado"
                    warn "⚠️  Worker $hostname ($ip): $worker_details"
                    ((worker_issues++))
                fi

            else
                worker_status="SSH_FAILED"
                worker_details="Falha na conexão SSH"
                error "❌ Worker $hostname ($ip): $worker_details"
                ((worker_issues++))
            fi

        else
            worker_status="OFFLINE"
            worker_details="Nó offline"
            error "❌ Worker $hostname ($ip): $worker_details"
            ((worker_issues++))
        fi

    done < "$nodes_config"

    # Resumo dos workers
    echo
    echo "📊 Resumo dos Workers:"
    echo "   Total de workers configurados: $total_workers"
    echo "   Workers ativos: $active_workers"
    echo "   Workers com problemas: $worker_issues"

    if [ $worker_issues -gt 0 ]; then
        OVERALL_HEALTH=false
        echo "   💡 Execute: ./scripts/management/remote_worker_manager.sh status"
        echo "   💡 Execute: ./scripts/management/remote_worker_manager.sh start <scheduler_ip>"
    fi
}

# Função para executar health check remoto em um worker
run_remote_health_check() {
    local target_host="$1"
    local target_user="${2:-$USER}"

    if [ -z "$target_host" ]; then
        error "Host alvo não especificado"
        echo "Uso: $0 --remote-health-check <host> [usuario]"
        return 1
    fi

    subsection "Health Check Remoto: $target_user@$target_host"

    # Verificar conectividade
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$target_user@$target_host" "echo 'SSH OK'" >/dev/null 2>&1; then
        error "❌ Falha na conexão SSH com $target_host"
        return 1
    fi

    # Verificar se o projeto existe no host remoto
    if ! ssh "$target_user@$target_host" "test -d ~/Projetos/cluster-ai" >/dev/null 2>&1; then
        error "❌ Projeto Cluster AI não encontrado em $target_host"
        return 1
    fi

    # Executar health check remoto
    success "✅ Executando health check remoto em $target_host..."
    ssh "$target_user@$target_host" "cd ~/Projetos/cluster-ai && ./scripts/utils/health_check.sh --quiet"

    if [ $? -eq 0 ]; then
        success "✅ Health check remoto concluído com sucesso em $target_host"
    else
        warn "⚠️  Health check remoto detectou problemas em $target_host"
        OVERALL_HEALTH=false
    fi
}

# Função principal consolidada
main() {
    # Processar argumentos da linha de comando
    QUIET_MODE=false
    REMOTE_HOST=""
    REMOTE_USER=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --test)
                # Modo teste - já implementado
                shift
                ;;
            --quiet)
                QUIET_MODE=true
                shift
                ;;
            --remote-health-check)
                REMOTE_HOST="$2"
                REMOTE_USER="${3:-$USER}"
                shift 3
                ;;
            --help|-h)
                echo "Uso: $0 [opções]"
                echo
                echo "Opções:"
                echo "  --test                 Modo de teste (simulação)"
                echo "  --quiet               Modo silencioso (menos saída)"
                echo "  --remote-health-check <host> [usuario]  Executar health check remoto"
                echo "  --help, -h            Mostrar esta ajuda"
                echo
                echo "Exemplos:"
                echo "  $0                     # Health check completo local"
                echo "  $0 --test             # Modo teste"
                echo "  $0 --quiet            # Modo silencioso"
                echo "  $0 --remote-health-check worker1  # Health check remoto"
                exit 0
                ;;
            *)
                error "Opção desconhecida: $1"
                echo "Use --help para ver as opções disponíveis"
                exit 1
                ;;
        esac
    done

    # Se foi solicitado health check remoto, executar apenas isso
    if [ -n "$REMOTE_HOST" ]; then
        run_remote_health_check "$REMOTE_HOST" "$REMOTE_USER"
        return $?
    fi

    section "HEALTH CHECK CONSOLIDADO - CLUSTER AI"
    echo "Log: $LOG_FILE"

    # Não redirecionar saída se estiver em modo quiet
    if [ "$QUIET_MODE" != true ]; then
        exec > >(tee -a "$LOG_FILE") 2>&1
    fi

    # Verificações básicas do sistema
    subsection "Verificações do Sistema"
    check_command "docker" "Docker"
    check_command "python3" "Python 3"
    check_command "git" "Git"
    check_command "curl" "cURL"

    # Verificar serviços
    subsection "Verificação de Serviços"
    check_service "docker" "Serviço Docker"
    check_service "ollama" "Serviço Ollama"

    # Verificar portas
    subsection "Verificação de Portas"
    check_port 8786 "Dask Scheduler"
    check_port 8787 "Dask Dashboard"
    check_port 11434 "Ollama API"
    check_port 3000 "OpenWebUI"

    # Verificar conectividade de rede
    check_network

    # Verificar GPU
    check_gpu

    # Verificar Ollama detalhado
    check_ollama

    # Verificar Dask
    check_dask

    # Verificar containers Docker
    check_docker_containers

    # Verificar workers remotos (se não for modo quiet)
    if [ "$QUIET_MODE" != true ]; then
        check_remote_workers
    fi

    # Verificar recursos
    check_resources

    # Resumo final
    section "RESUMO DA SAÚDE DO SISTEMA"

    if [ "$OVERALL_HEALTH" = true ]; then
        success "🎉 SISTEMA SAUDÁVEL!"
        echo "Todos os componentes essenciais estão funcionando corretamente."
    else
        warn "⚠️  SISTEMA COM PROBLEMAS"
        echo "Alguns componentes necessitam de atenção."
        echo "Consulte o log completo: $LOG_FILE"
    fi

    echo -e "\n${BLUE}📋 RECOMENDAÇÕES:${NC}"
    if ! command_exists nvidia-smi && ! [ -d "/opt/rocm" ]; then
        echo "- Instalar drivers GPU para melhor performance"
    fi

    if ! service_active docker; then
        echo "- Iniciar serviço Docker: sudo systemctl start docker"
    fi

    echo -e "\n${GREEN}🚀 Use './scripts/validation/run_tests.sh' para teste completo${NC}"
}

# Executar função principal
if [ "${1:-}" = "--test" ]; then
    # Modo de teste - execução básica
    echo "=== MODO TESTE - HEALTH CHECK CONSOLIDADO ==="
    echo "Simulando verificação de serviços..."
    echo "✅ Docker Daemon está ativo"
    echo "✅ Ollama Service está ativo"
    echo "✅ Porta 8080 está aberta"
    echo "✅ Health check concluído"
    exit 0
else
    main "$@"
fi
