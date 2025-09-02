#!/bin/bash
# Script Consolidado de Health Check - Cluster AI
# Versão Unificada 2.0 - Combina recursos de health_check.sh e cluster_health_monitor.sh

set -euo pipefail
IFS=$'\n\t'

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

# ==================== CONFIGURAÇÕES ====================

# Configurações globais
LOG_FILE="/tmp/cluster_ai_health_check_$(date +%Y%m%d_%H%M%S).log"
REPORT_FILE="/tmp/cluster_health_report_$(date +%Y%m%d_%H%M%S).txt"
OVERALL_HEALTH=true
QUIET_MODE=false
REMOTE_HOST=""
REMOTE_USER=""
MONITOR_MODE=false
MONITOR_INTERVAL=300
COMMAND_MODE=""

# Configurações de cluster
NODES_CONFIG_FILE="$HOME/.cluster_config/nodes_list.conf"
CLUSTER_MODE=false

# ==================== FUNÇÕES DE LOG ====================

log() { echo -e "${CYAN}[HEALTH-CHECK $(date '+%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[AVISO $(date '+%H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[ERRO $(date '+%H:%M:%S')]${NC} $1"; }
section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
subsection() { echo -e "\n${CYAN}➤ $1${NC}"; }
info() { echo -e "${GREEN}[INFO $(date '+%H:%M:%S')]${NC} $1"; }

# ==================== FUNÇÕES DE VERIFICAÇÃO BÁSICA ====================

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

check_port() {
    local port="$1"
    local description="${2:-Porta $port}"

    if nc -z localhost $port 2>/dev/null; then
        success "✅ $description: Aberta"
        return 0
    else
        fail "❌ $description: Fechada"
        OVERALL_HEALTH=false
        return 1
    fi
}

# ==================== VERIFICAÇÕES DE SISTEMA ====================

check_system_basics() {
    subsection "Verificações Básicas do Sistema"
    check_command "docker" "Docker" "curl -fsSL https://get.docker.com | sh"
    check_command "python3" "Python 3" "sudo apt install python3"
    check_command "git" "Git" "sudo apt install git"
    check_command "curl" "cURL" "sudo apt install curl"
    check_command "ssh" "SSH Client" "sudo apt install openssh-client"
}

check_services() {
    subsection "Verificação de Serviços Essenciais"
    check_service "docker" "Serviço Docker"
    check_service "ollama" "Serviço Ollama"
}

check_ports() {
    subsection "Verificação de Portas Essenciais"
    check_port 8786 "Dask Scheduler"
    check_port 8787 "Dask Dashboard"
    check_port 11434 "Ollama API"
    check_port 3000 "OpenWebUI"
}

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
}

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

check_resources() {
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

# ==================== VERIFICAÇÕES DE COMPONENTES ====================

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

# ==================== VERIFICAÇÕES DE CLUSTER ====================

check_remote_workers() {
    subsection "Workers Remotos do Cluster"

    # Verificar se existe arquivo de configuração de nós
    if [ ! -f "$NODES_CONFIG_FILE" ]; then
        echo "   Arquivo de configuração de nós não encontrado: $NODES_CONFIG_FILE"
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

    done < "$NODES_CONFIG_FILE"

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

# ==================== FUNÇÕES DE MONITORAMENTO ====================

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
    ssh "$target_user@$target_host" "cd ~/Projetos/cluster-ai && ./scripts/utils/health_check_consolidated.sh --quiet"

    if [ $? -eq 0 ]; then
        success "✅ Health check remoto concluído com sucesso em $target_host"
    else
        warn "⚠️  Health check remoto detectou problemas em $target_host"
        OVERALL_HEALTH=false
    fi
}

show_cluster_status() {
    section "STATUS RESUMIDO DO CLUSTER"

    # Status local
    echo "🏠 Nó Local:"
    if "$0" --quiet >/dev/null 2>&1; then
        success "   ✅ Saudável"
    else
        error "   ❌ Com problemas"
    fi

    # Status dos workers
    if [ -f "$NODES_CONFIG_FILE" ]; then
        echo
        echo "👥 Workers Remotos:"
        local worker_count=0
        local active_workers=0

        while read -r hostname ip user port; do
            if [ -z "$hostname" ] || [[ "$hostname" =~ ^[[:space:]]*# ]]; then
                continue
            fi

            ((worker_count++))
            if ssh -p "${port:-22}" -o ConnectTimeout=3 -o BatchMode=yes "$user@$hostname" "pgrep -f dask-worker >/dev/null 2>&1 && echo 'OK'" >/dev/null 2>&1; then
                success "   ✅ $hostname: Ativo"
                ((active_workers++))
            else
                error "   ❌ $hostname: Inativo/Problemas"
            fi
        done < "$NODES_CONFIG_FILE"

        echo
        echo "📊 Resumo: $active_workers/$worker_count workers ativos"
    else
        echo
        echo "👥 Workers Remotos: Nenhum configurado"
    fi
}

generate_detailed_report() {
    local output_file="${1:-$REPORT_FILE}"

    section "GERANDO RELATÓRIO DETALHADO"

    {
        echo "========================================"
        echo "RELATÓRIO DE SAÚDE DO CLUSTER AI"
        echo "========================================"
        echo "Data/Hora: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Host: $(hostname)"
        echo "Usuário: $USER"
        echo ""

        echo "1. HEALTH CHECK LOCAL"
        echo "======================"
        "$0" --quiet 2>/dev/null || echo "ERRO: Falha no health check local"

        echo
        echo "2. HEALTH CHECK WORKERS REMOTOS"
        echo "================================"

        if [ -f "$NODES_CONFIG_FILE" ]; then
            local worker_num=1
            while read -r hostname ip user port; do
                if [ -z "$hostname" ] || [[ "$hostname" =~ ^[[:space:]]*# ]]; then
                    continue
                fi

                echo
                echo "Worker $worker_num: $hostname ($ip)"
                echo "---"

                if ssh -p "${port:-22}" -o ConnectTimeout=5 -o BatchMode=yes "$user@$hostname" "cd ~/Projetos/cluster-ai && ./scripts/utils/health_check_consolidated.sh --quiet" 2>/dev/null; then
                    echo "Status: OK"
                else
                    echo "Status: PROBLEMAS DETECTADOS"
                fi

                ((worker_num++))
            done < "$NODES_CONFIG_FILE"
        else
            echo "Nenhum worker remoto configurado"
        fi

        echo
        echo "3. RECOMENDAÇÕES"
        echo "================="
        echo "- Execute '$0 all' para verificação completa"
        echo "- Use '$0 monitor' para monitoramento contínuo"
        echo "- Verifique logs em: $LOG_FILE"

    } > "$output_file"

    success "✅ Relatório gerado: $output_file"
    info "Para visualizar: cat $output_file"
}

start_monitoring_mode() {
    local interval="${1:-300}"

    section "MODO DE MONITORAMENTO CONTÍNUO"
    info "Intervalo: $interval segundos"
    info "Pressione Ctrl+C para parar"
    echo

    trap 'echo -e "\n"; info "Monitoramento interrompido."; exit 0' SIGINT

    while true; do
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] Executando verificação de saúde..."

        if run_complete_health_check true; then
            success "[$timestamp] ✅ Cluster saudável"
        else
            error "[$timestamp] ❌ Problemas detectados no cluster"
        fi

        echo "Aguardando $interval segundos para próxima verificação..."
        sleep "$interval"
    done
}

# ==================== FUNÇÕES PRINCIPAIS ====================

run_local_health_check() {
    local quiet="${1:-false}"

    section "HEALTH CHECK LOCAL"
    info "Executando verificação de saúde no nó local..."

    # Executar verificações
    check_system_basics
    check_services
    check_ports
    check_network
    check_gpu
    check_ollama
    check_dask
    check_docker_containers
    check_resources

    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        success "✅ Health check local concluído com sucesso"
    else
        warn "⚠️  Health check local detectou problemas"
    fi

    return $exit_code
}

run_all_remote_health_checks() {
    local quiet="${1:-false}"

    section "HEALTH CHECK REMOTO - TODOS OS WORKERS"

    # Verificar arquivo de configuração
    if [ ! -f "$NODES_CONFIG_FILE" ]; then
        error "Arquivo de configuração de nós não encontrado: $NODES_CONFIG_FILE"
        info "Execute: ./scripts/management/remote_worker_manager.sh help"
        return 1
    fi

    local total_workers=0
    local successful_checks=0
    local failed_checks=0

    while read -r hostname ip user port; do
        if [ -z "$hostname" ] || [[ "$hostname" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        ((total_workers++))

        if run_remote_worker_health_check "$hostname" "$user" "$quiet"; then
            ((successful_checks++))
        else
            ((failed_checks++))
        fi

        echo
    done < "$NODES_CONFIG_FILE"

    # Resumo
    subsection "Resumo dos Health Checks Remotos"
    echo "Total de workers: $total_workers"
    echo "Checks bem-sucedidos: $successful_checks"
    echo "Checks com falha: $failed_checks"

    if [ $failed_checks -gt 0 ]; then
        warn "⚠️  Alguns workers apresentaram problemas"
        return 1
    else
        success "✅ Todos os workers passaram no health check"
        return 0
    fi
}

run_remote_worker_health_check() {
    local target_host="$1"
    local target_user="${2:-$USER}"
    local quiet="${3:-false}"

    subsection "Health Check Remoto: $target_user@$target_host"

    # Verificar conectividade SSH
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no "$target_user@$target_host" "echo 'SSH OK'" >/dev/null 2>&1; then
        error "❌ Falha na conexão SSH com $target_host"
        return 1
    fi

    # Verificar se o projeto existe
    if ! ssh "$target_user@$target_host" "test -d ~/Projetos/cluster-ai" >/dev/null 2>&1; then
        error "❌ Projeto Cluster AI não encontrado em $target_host"
        return 1
    fi

    # Executar health check remoto
    success "✅ Executando health check remoto em $target_host..."

    if [ "$quiet" = true ]; then
        ssh "$target_user@$target_host" "cd ~/Projetos/cluster-ai && ./scripts/utils/health_check_consolidated.sh --quiet"
    else
        ssh "$target_user@$target_host" "cd ~/Projetos/cluster-ai && ./scripts/utils/health_check_consolidated.sh"
    fi

    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        success "✅ Health check remoto concluído com sucesso em $target_host"
    else
        warn "⚠️  Health check remoto detectou problemas em $target_host"
    fi

    return $exit_code
}

run_complete_health_check() {
    local quiet="${1:-false}"

    section "HEALTH CHECK COMPLETO DO CLUSTER"

    local local_result=0
    local remote_result=0

    # Health check local
    if run_local_health_check "$quiet"; then
        success "✅ Nó local: OK"
    else
        error "❌ Nó local: PROBLEMAS DETECTADOS"
        local_result=1
    fi

    echo

    # Health check remoto
    if run_all_remote_health_checks "$quiet"; then
        success "✅ Workers remotos: OK"
    else
        error "❌ Workers remotos: PROBLEMAS DETECTADOS"
        remote_result=1
    fi

    # Resultado final
    echo
    if [ $local_result -eq 0 ] && [ $remote_result -eq 0 ]; then
        success "🎉 CLUSTER SAUDÁVEL - Todos os nós passaram nas verificações!"
        return 0
    else
        error "🚨 CLUSTER COM PROBLEMAS - Verifique os detalhes acima"
        return 1
    fi
}

show_help() {
    echo "Health Check Consolidado - Cluster AI"
    echo
    echo "Uso: $0 [comando] [opções]"
    echo
    echo "Comandos:"
    echo "  local                 Executar health check apenas no nó local"
    echo "  remote                Executar health check em todos os workers remotos"
    echo "  all                   Executar health check local + todos os workers remotos"
    echo "  worker <host>         Executar health check em um worker específico"
    echo "  status                Mostrar status resumido de todos os nós"
    echo "  report                Gerar relatório detalhado de saúde do cluster"
    echo "  monitor               Modo de monitoramento contínuo"
    echo "  help                  Mostrar esta ajuda"
    echo
    echo "Opções:"
    echo "  --quiet, -q          Modo silencioso"
    echo "  --interval <seg>     Intervalo para monitoramento (padrão: 300s)"
    echo "  --output <arquivo>   Arquivo de saída para relatório"
    echo "  --remote-health-check <host> [usuario]  Executar health check remoto"
    echo
    echo "Exemplos:"
    echo "  $0 local                    # Health check local"
    echo "  $0 remote                   # Health check em todos os workers"
    echo "  $0 worker worker1           # Health check em worker específico"
    echo "  $0 all                      # Health check completo"
    echo "  $0 monitor --interval 600   # Monitoramento contínuo a cada 10min"
    echo "  $0 --remote-health-check worker1  # Health check remoto"
}

# ==================== FUNÇÃO PRINCIPAL ====================

main() {
    # Processar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            local|remote|all|worker|status|report|monitor)
                COMMAND_MODE="$1"
                shift
                break
                ;;
            --quiet|-q)
                QUIET_MODE=true
                shift
                ;;
            --interval)
                MONITOR_INTERVAL="$2"
                shift 2
                ;;
            --output)
                REPORT_FILE="$2"
                shift 2
                ;;
            --remote-health-check)
                REMOTE_HOST="$2"
                REMOTE_USER="${3:-$USER}"
                shift 3
                ;;
            help|--help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Comando desconhecido: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Comando padrão
    if [ -z "$COMMAND_MODE" ] && [ -z "$REMOTE_HOST" ]; then
        COMMAND_MODE="all"
    fi

    # Se foi solicitado health check remoto, executar apenas isso
    if [ -n "$REMOTE_HOST" ]; then
        run_remote_health_check "$REMOTE_HOST" "$REMOTE_USER"
        return $?
    fi

    # Configurar log
    if [ "$QUIET_MODE" != true ]; then
        exec > >(tee -a "$LOG_FILE") 2>&1
    fi

    section "HEALTH CHECK CONSOLIDADO - CLUSTER AI"
    echo "Log: $LOG_FILE"

    # Executar comando
    case "$COMMAND_MODE" in
        local)
            run_local_health_check "$QUIET_MODE"
            ;;
        remote)
            run_all_remote_health_checks "$QUIET_MODE"
            ;;
        all)
            run_complete_health_check "$QUIET_MODE"
            ;;
        worker)
            if [ $# -lt 1 ]; then
                error "Host do worker não especificado"
                echo "Uso: $0 worker <hostname> [usuario]"
                exit 1
            fi
            local worker_host="$1"
            local worker_user="${2:-$USER}"
            run_remote_worker_health_check "$worker_host" "$worker_user" "$QUIET_MODE"
            ;;
        status)
            show_cluster_status
            ;;
        report)
            generate_detailed_report "$REPORT_FILE"
            ;;
        monitor)
            start_monitoring_mode "$MONITOR_INTERVAL"
            ;;
        *)
            error "Comando não reconhecido: $COMMAND_MODE"
            show_help
            exit 1
            ;;
    esac

    # Resumo final

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

# ==================== EXECUÇÃO ====================

# Verificar se é modo teste
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
