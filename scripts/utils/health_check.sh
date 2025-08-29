#!/bin/bash
# Sistema de Verificação de Saúde do Cluster AI
# Versão: 2.0 - Padronizada e Aprimorada

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
export CLUSTER_AI_LOG_FILE="$LOG_FILE"
OVERALL_HEALTH=true
VENV_PRIORITY=(".venv" "$HOME/venv")  # Prioridade: .venv primeiro, depois $HOME/venv

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
    log "Verificando configuração de GPU..."
    
    # Verificar NVIDIA
    if command_exists nvidia-smi; then
        success "GPU NVIDIA: Detectada"
        nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv
        return 0
    fi
    
    # Verificar AMD
    if command_exists rocminfo || [ -d "/opt/rocm" ]; then
        success "GPU AMD: Detectada"
        if command_exists rocminfo; then
            rocminfo | grep -E "Device Type|Marketing Name" | head -4
        fi
        return 0
    fi
    
    warn "GPU: Não detectada - Modo CPU"
    return 1
}

# Função para verificar PyTorch
check_pytorch() {
    log "Verificando PyTorch..."
    
    if python3 -c "import torch; print(f'PyTorch {torch.__version__}'); print(f'CUDA: {torch.cuda.is_available()}')" 2>/dev/null; then
        success "PyTorch: Funcionando"
        return 0
    else
        fail "PyTorch: Erro na importação"
        OVERALL_HEALTH=false
        return 1
    fi
}

# Função para verificar ambiente virtual (padronizada)
check_venv() {
    subsection "Ambiente Virtual Python"
    log "Verificando ambientes virtuais (prioridade: .venv > \$HOME/venv)..."
    
    local venv_found=false
    local active_venv=""
    
    # Verificar ambientes na ordem de prioridade
    for venv_path in "${VENV_PRIORITY[@]}"; do
        if [ -d "$venv_path" ]; then
            venv_found=true
            active_venv="$venv_path"
            
            # Verificar se pode ser ativado
            if source "$venv_path/bin/activate" 2>/dev/null && python -c "import sys; print(f'Python: {sys.version}')" 2>/dev/null; then
                success "✅ $venv_path: Funcional ($(python --version 2>&1))"
                # Verificar pacotes essenciais
                local missing_packages=()
                for pkg in "torch" "numpy" "requests"; do
                    if ! python -c "import $pkg" 2>/dev/null; then
                        missing_packages+=("$pkg")
                    fi
                done
                
                if [ ${#missing_packages[@]} -eq 0 ]; then
                    success "📦 Pacotes essenciais: Todos presentes"
                else
                    warn "⚠️  Pacotes ausentes: ${missing_packages[*]}"
                    echo "   Execute: ./scripts/installation/venv_setup.sh para instalar"
                fi
                
                deactivate
            else
                fail "❌ $venv_path: Corrompido ou não funcional"
                OVERALL_HEALTH=false
                echo "   Execute: rm -rf $venv_path && ./scripts/installation/venv_setup.sh"
            fi
            break
        fi
    done
    
    if [ "$venv_found" = false ]; then
        fail "❌ Nenhum ambiente virtual encontrado"
        OVERALL_HEALTH=false
        echo "💡 RECOMENDAÇÃO:"
        echo "   Execute: ./scripts/installation/venv_setup.sh para criar ambiente virtual"
        echo "   OU: python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt"
    fi
    
    # Documentar padrão recomendado
    if [ "$venv_found" = true ]; then
        echo "📋 Padrão recomendado: .venv no diretório do projeto (${VENV_PRIORITY[0]})"
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

# Função para verificar uso de recursos com alertas
check_resources() {
    log "Verificando recursos do sistema..."
    
    # Memória
    local mem_total_kb=$(free | awk '/Mem:/ {print $2}')
    local mem_used_kb=$(free | awk '/Mem:/ {print $3}')
    local mem_used_percent=$((mem_used_kb * 100 / mem_total_kb))
    local mem_total=$(free -h | awk '/Mem:/ {print $2}')
    local mem_used=$(free -h | awk '/Mem:/ {print $3}')
    local mem_free=$(free -h | awk '/Mem:/ {print $4}')
    
    echo "💾 Memória: Total: $mem_total, Usada: $mem_used, Livre: $mem_free"
    
    # Memory alert
    if [ $mem_used_percent -gt 90 ]; then
        error "ALERTA: Uso de memória crítico: ${mem_used_percent}%"
        OVERALL_HEALTH=false
    elif [ $mem_used_percent -gt 80 ]; then
        warn "Aviso: Uso de memória alto: ${mem_used_percent}%"
    fi
    
    # CPU
    local cpu_cores=$(nproc)
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')
    local cpu_load_per_core=$(echo "scale=2; $cpu_load / $cpu_cores" | bc)
    
    echo "⚡ CPU: Núcleos: $cpu_cores, Carga: $cpu_load (${cpu_load_per_core} por núcleo)"
    
    # CPU alert
    if (( $(echo "$cpu_load_per_core > 2.0" | bc -l) )); then
        error "ALERTA: Carga de CPU muito alta: ${cpu_load_per_core} por núcleo"
        OVERALL_HEALTH=false
    elif (( $(echo "$cpu_load_per_core > 1.5" | bc -l) )); then
        warn "Aviso: Carga de CPU alta: ${cpu_load_per_core} por núcleo"
    fi
    
    # Disco
    local disk_usage_percent=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    local disk_usage=$(df -h / | awk 'NR==2 {print $5 " usado (" $3 "/" $2 ")"}')
    
    echo "💿 Disco: $disk_usage"
    
    # Disk alert
    if [ $disk_usage_percent -gt 90 ]; then
        error "ALERTA: Uso de disco crítico: ${disk_usage_percent}%"
        OVERALL_HEALTH=false
    elif [ $disk_usage_percent -gt 80 ]; then
        warn "Aviso: Uso de disco alto: ${disk_usage_percent}%"
    fi
}

# Função para verificar temperatura (se disponível)
check_temperature() {
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        local temp_c=$((temp/1000))
        echo "🌡️  Temperatura CPU: ${temp_c}°C"
        
        if [ $temp_c -gt 80 ]; then
            warn "Temperatura alta: ${temp_c}°C"
        fi
    fi
}

# Função principal
main() {
    section "VERIFICAÇÃO DE SAÚDE - CLUSTER AI"
    echo "Log: $LOG_FILE"
    
    # Verificações básicas do sistema
    section "1. VERIFICAÇÕES DO SISTEMA"
    check_command "docker" "Docker"
    check_command "python3" "Python 3"
    check_command "pip" "PIP"
    check_command "git" "Git"
    check_command "curl" "cURL"
    
    # Verificar serviços
    section "2. VERIFICAÇÃO DE SERVIÇOS"
    check_service "docker" "Serviço Docker"
    
    # Verificar Ollama
    section "3. VERIFICAÇÃO DO OLLAMA"
    local check_script="$PROJECT_ROOT/scripts/diagnostics/check_ollama.sh"
    if [ -f "$check_script" ]; then
        bash "$check_script" || OVERALL_HEALTH=false
    else
        warn "Script de verificação do Ollama não encontrado em $check_script"
    fi
    
    # Verificar Dask
    section "4. VERIFICAÇÃO DO DASK"
    check_dask
    
    # Verificar containers Docker
    section "5. VERIFICAÇÃO DE CONTAINERS DOCKER"
    check_docker_containers
    
    # Verificar GPU
    section "6. VERIFICAÇÃO DE GPU"
    check_gpu
    
    # Verificar PyTorch
    section "7. VERIFICAÇÃO DO PyTorch"
    check_pytorch
    
    # Verificar ambiente virtual
    section "8. VERIFICAÇÃO DO AMBIENTE VIRTUAL"
    check_venv
    
    # Verificar recursos
    section "9. RECURSOS DO SISTEMA"
    check_resources
    check_temperature
    
    # Verificar diretórios importantes
    section "10. ESTRUTURA DE DIRETÓRIOS"
    check_directory "$HOME/venv" "Diretório do ambiente virtual"
    check_directory "$HOME/cluster_scripts" "Diretório de scripts do cluster"
    check_directory "$HOME/.ollama" "Diretório do Ollama"
    check_directory ".venv" "Diretório .venv do projeto"
    
    # Resumo final
    section "RESUMO DA SAÚDE DO SISTEMA"
    
    if [ "$OVERALL_HEALTH" = true ]; then
        echo -e "${GREEN}🎉 SISTEMA SAUDÁVEL!${NC}"
        echo "Todos os componentes essenciais estão funcionando corretamente."
    else
        echo -e "${YELLOW}⚠️  SISTEMA COM PROBLEMAS${NC}"
        echo "Alguns componentes necessitam de atenção."
        echo "Consulte o log completo: $LOG_FILE"
    fi
    
    echo -e "\n${BLUE}📋 RECOMENDAÇÕES:${NC}"
    if ! command_exists nvidia-smi && ! [ -d "/opt/rocm" ]; then
        echo "- Instalar drivers GPU para melhor performance"
    fi
    
    if [ ! -d "$HOME/venv" ]; then
        echo "- Configurar ambiente virtual: ./scripts/installation/venv_setup.sh"
    fi
    
    if ! service_active docker; then
        echo "- Iniciar serviço Docker: sudo systemctl start docker"
    fi
    
    echo -e "\n${GREEN}🚀 Use './scripts/validation/run_complete_test_modified.sh' para teste completo${NC}"
}

# Executar
main "$@"
