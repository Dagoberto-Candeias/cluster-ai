#!/bin/bash
# Sistema de Verificação de Saúde do Cluster AI - Versão Segura
# Versão: 3.0 - Com validação completa, sugestões de correção e monitoramento avançado

# ==================== CONFIGURAÇÃO DE SEGURANÇA ====================

# Prevenção de execução como root
if [ "$EUID" -eq 0 ]; then
    echo "ERRO CRÍTICO: Este script NÃO deve ser executado como root."
    echo "Por favor, execute como um usuário normal com privilégios sudo quando necessário."
    exit 1
fi

# Validação do contexto de execução
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"
if [ ! -f "$PROJECT_ROOT/README.md" ]; then
    echo "ERRO: Script executado fora do contexto do projeto Cluster AI"
    exit 1
fi

# Carregar funções comuns
COMMON_SCRIPT_PATH="$SCRIPT_DIR/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO: Script de funções comuns não encontrado em $COMMON_SCRIPT_PATH"
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# Configurações
LOG_FILE="/tmp/cluster_ai_health_$(date +%Y%m%d_%H%M%S).log"
OVERALL_HEALTH=true
VENV_PRIORITY=(".venv" "$HOME/venv")  # Prioridade: .venv primeiro, depois $HOME/venv

# Funções de log aprimoradas
log() { echo -e "${CYAN}[HEALTH-CHECK $(date '+%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[HEALTH-WARN $(date '+%H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[HEALTH-ERROR $(date '+%H:%M:%S')]${NC} $1"; }
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

# Função para verificar serviço com opção de restart
check_service() {
    local service="$1"
    local description="$2"
    
    if service_active "$service"; then
        success "✅ $description: Ativo"
        return 0
    else
        fail "❌ $description: Inativo"
        echo "   💡 Execute: sudo systemctl start $service"
        OVERALL_HEALTH=false
        return 1
    fi
}

# Função para verificar diretório com permissões
check_directory() {
    local dir="$1"
    local description="$2"
    local required="${3:-false}"
    
    if [ -d "$dir" ]; then
        local perms=$(stat -c "%a %U:%G" "$dir" 2>/dev/null || stat -f "%Sp %u:%g" "$dir")
        success "✅ $description: Existe ($perms)"
        
        # Verificar permissões de escrita
        if [ ! -w "$dir" ]; then
            warn "⚠️  $description: Sem permissão de escrita"
            echo "   💡 Execute: chmod 755 $dir"
        fi
        return 0
    else
        if [ "$required" = true ]; then
            fail "❌ $description: Não existe (OBRIGATÓRIO)"
            OVERALL_HEALTH=false
        else
            warn "⚠️  $description: Não existe"
        fi
        return 1
    fi
}

# Função para verificar arquivo com validação
check_file() {
    local file="$1"
    local description="$2"
    local required="${3:-false}"
    
    if [ -f "$file" ]; then
        local size=$(du -h "$file" 2>/dev/null | cut -f1 || echo "N/A")
        success "✅ $description: Existe ($size)"
        return 0
    else
        if [ "$required" = true ]; then
            fail "❌ $description: Não existe (OBRIGATÓRIO)"
            OVERALL_HEALTH=false
        else
            warn "⚠️  $description: Não existe"
        fi
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
        nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv
        return 0
    fi
    
    # Verificar AMD
    if command_exists rocminfo || [ -d "/opt/rocm" ]; then
        success "✅ GPU AMD: Detectada"
        if command_exists rocminfo; then
            rocminfo | grep -E "Device Type|Marketing Name" | head -4
        fi
        return 0
    fi
    
    warn "⚠️  GPU: Não detectada - Modo CPU"
    return 1
}

# Função para verificar PyTorch
check_pytorch() {
    subsection "Framework PyTorch"
    
    if python3 -c "import torch; print(f'PyTorch {torch.__version__}'); print(f'CUDA: {torch.cuda.is_available()}')" 2>/dev/null; then
        success "✅ PyTorch: Funcionando"
        return 0
    else
        fail "❌ PyTorch: Erro na importação"
        echo "   💡 Execute: pip install torch torchvision torchaudio"
        OVERALL_HEALTH=false
        return 1
    fi
}

# Função para verificar ambiente virtual
check_venv() {
    subsection "Ambiente Virtual Python"
    
    local venv_found=false
    local venv_path=""
    
    # Procurar ambiente virtual seguindo a prioridade
    for venv_dir in "${VENV_PRIORITY[@]}"; do
        if [ -d "$venv_dir" ] && [ -f "$venv_dir/bin/activate" ]; then
            venv_found=true
            venv_path="$venv_dir"
            break
        fi
    done
    
    if [ "$venv_found" = true ]; then
        success "✅ Ambiente Virtual: Encontrado ($venv_path)"
        
        # Verificar se o ambiente está ativo
        if [ -n "$VIRTUAL_ENV" ]; then
            success "✅ Ambiente Ativo: $VIRTUAL_ENV"
        else
            warn "⚠️  Ambiente não ativado"
            echo "   💡 Execute: source $venv_path/bin/activate"
        fi
        
        return 0
    else
        fail "❌ Ambiente Virtual: Não encontrado"
        echo "   💡 Para criar um ambiente seguro:"
        echo "      python3 -m venv .venv"
        echo "      source .venv/bin/activate"
        echo "      pip install -r requirements.txt"
        OVERALL_HEALTH=false
        return 1
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
                
                # Listar e validar modelos
                local models=$(timeout 10 ollama list 2>/dev/null || echo "timeout")
                if [ "$models" != "timeout" ]; then
                    local models_count=$(echo "$models" | wc -l)
                    if [ $models_count -gt 1 ]; then
                        success "📦 Modelos Ollama: $((models_count-1)) instalado(s)"
                        echo "   Modelos: $(echo "$models" | grep -v "NAME" | awk '{print $1}' | tr '\n' ' ')"
                    else
                        warn "⚠️  Modelos Ollama: Nenhum modelo instalado"
                        echo "   💡 Execute: ollama pull llama2"
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
        
        # Verificar diretório de modelos
        check_directory "$HOME/.ollama" "Diretório de modelos Ollama" false
        
    else
        warn "⚠️  Ollama: Não instalado"
        echo "   💡 Execute: curl -fsSL https://ollama.ai/install.sh | sh"
    fi
}

# Função para verificar Dask com monitoramento
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
        # Mostrar informações dos workers
        pgrep -f "dask-worker" | xargs ps -o pid,pcpu,pmem,cmd -p 2>/dev/null | head -$((workers_count+1))
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

# Função para verificar containers Docker com health check
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
                
                # Verificar health status se disponível
                local health=$(docker inspect --format='{{.State.Health.Status}}' "$name" 2>/dev/null || echo "N/A")
                if [ "$health" != "N/A" ]; then
                    echo "   Saúde: $health"
                fi
            else
                warn "⚠️  Container $name: $status"
                echo "   💡 Execute: docker start $name"
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

# Função para verificar uso de recursos com alertas e sugestões
check_resources() {
    subsection "Monitoramento de Recursos"
    
    # Memória RAM
    local mem_info=$(free -b 2>/dev/null || vm_stat 2>/dev/null)
    local mem_total_kb=$(echo "$mem_info" | awk '/Mem:/ {print $2/1024}')
    local mem_used_kb=$(echo "$mem_info" | awk '/Mem:/ {print $3/1024}')
    local mem_used_percent=$((mem_used_kb * 100 / mem_total_kb))
    local mem_total=$(free -h | awk '/Mem:/ {print $2}' || echo "N/A")
    local mem_used=$(free -h | awk '/Mem:/ {print $3}' || echo "N/A")
    local mem_free=$(free -h | awk '/Mem:/ {print $4}' || echo "N/A")
    
    echo "💾 Memória RAM: Total: $mem_total, Usada: $mem_used, Livre: $mem_free"
    
    # Alertas de memória
    if [ $mem_used_percent -gt 90 ]; then
        error "🚨 ALERTA CRÍTICO: Uso de memória: ${mem_used_percent}%"
        echo "   💡 Execute: ./scripts/utils/memory_manager_secure.sh start"
        OVERALL_HEALTH=false
    elif [ $mem_used_percent -gt 80 ]; then
        warn "⚠️  AVISO: Uso de memória alto: ${mem_used_percent}%"
        echo "   💡 Monitor: ./scripts/utils/memory_manager_secure.sh status"
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
}

# Função principal de verificação de saúde
main_health_check() {
    section "VERIFICAÇÃO DE SAÚDE DO CLUSTER AI"
    echo "Iniciando verificação completa do sistema..."
    echo "Log detalhado: $LOG_FILE"
    echo ""
    
    # Verificações de segurança e sistema
    check_network
    check_gpu
    check_pytorch
    check_venv
    
    # Verificações de serviços
    check_ollama
    check_dask
    check_docker_containers
    
    # Verificações de recursos
    check_resources
    
    # Resultado final
    section "RESULTADO DA VERIFICAÇÃO"
    if [ "$OVERALL_HEALTH" = true ]; then
        success "✅ SISTEMA SAUDÁVEL: Todas as verificações passaram"
        echo "O cluster AI está funcionando corretamente."
    else
        error "❌ SISTEMA COM PROBLEMAS: Algumas verificações falharam"
        echo "Verifique as mensagens acima e execute as sugestões de correção."
        exit 1
    fi
}

# Executar verificação principal
main_health_check
