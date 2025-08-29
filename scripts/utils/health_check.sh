#!/bin/bash
# Sistema de Verificação de Saúde do Cluster AI

# Security check to prevent running as root
if [ "$EUID" -eq 0 ]; then
    echo "ERRO: Este script não deve ser executado como root. Por favor, execute como um usuário normal."
    exit 1
fi

# Cores para output
COMMON_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/." && pwd)/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO: Script de funções comuns não encontrado em $COMMON_SCRIPT_PATH"
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# Sobrescrever log para adicionar prefixo
log() { echo -e "${CYAN}[HEALTH-CHECK]${NC} $1"; }
warn() { echo -e "${YELLOW}[HEALTH-WARN]${NC} $1"; }
error() { echo -e "${RED}[HEALTH-ERROR]${NC} $1"; }

# Configuração
LOG_FILE="/tmp/cluster_ai_health_$(date +%Y%m%d_%H%M%S).log"
OVERALL_HEALTH=true

# Função para verificar comando
check_command() {
    local cmd="$1"
    local description="$2"
    
    if command_exists "$cmd"; then
        success "$description: Disponível"
        return 0
    else
        fail "$description: Não encontrado"
        OVERALL_HEALTH=false
        return 1
    fi
}

# Função para verificar serviço
check_service() {
    local service="$1"
    local description="$2"
    
    if service_active "$service"; then
        success "$description: Ativo"
        return 0
    else
        fail "$description: Inativo"
        OVERALL_HEALTH=false
        return 1
    fi
}

# Função para verificar diretório
check_directory() {
    local dir="$1"
    local description="$2"
    
    if [ -d "$dir" ]; then
        success "$description: Existe"
        return 0
    else
        fail "$description: Não existe"
        OVERALL_HEALTH=false
        return 1
    fi
}

# Função para verificar arquivo
check_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        success "$description: Existe"
        return 0
    else
        fail "$description: Não existe"
        OVERALL_HEALTH=false
        return 1
    fi
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

# Função para verificar ambiente virtual
check_venv() {
    log "Verificando ambiente virtual..."
    
    # Check for .venv in the project root
    if [ -d ".venv" ]; then
        success "Ambiente virtual: .venv Existe"
        
        # Verify if it can be activated
        if source ".venv/bin/activate" 2>/dev/null && python -c "import sys; print(f'Python: {sys.version}')"; then
            success "Ambiente virtual: Funcional"
            deactivate
        else
            fail "Ambiente virtual: Não funcional"
            OVERALL_HEALTH=false
        fi
        return 0
    fi

    # Check for $HOME/venv
    if [ -d "$HOME/venv" ]; then
        success "Ambiente virtual: $HOME/venv Existe"
        
        # Verify if it can be activated
        if source "$HOME/venv/bin/activate" 2>/dev/null && python -c "import sys; print(f'Python: {sys.version}')"; then
            success "Ambiente virtual: Funcional"
            deactivate
        else
            fail "Ambiente virtual: Não funcional"
            OVERALL_HEALTH=false
        fi
        return 0
    else
        fail "Ambiente virtual: Não existe"
        OVERALL_HEALTH=false
        return 1
    fi
}


# Função para verificar Ollama
check_ollama() {
    log "Verificando Ollama..."
    
    if command_exists ollama; then
        success "Ollama: Instalado"
        
        # Check if Ollama service is running
        if service_active ollama; then
            success "Ollama Service: Ativo"
            
            # Check if Ollama API is responding
            if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
                success "Ollama API: Respondendo"
                
                # List installed models
                local models_count=$(ollama list 2>/dev/null | wc -l)
                if [ $models_count -gt 1 ]; then
                    success "Modelos Ollama: $((models_count-1)) instalado(s)"
                else
                    warn "Modelos Ollama: Nenhum modelo instalado"
                fi
            else
                fail "Ollama API: Não responde"
                OVERALL_HEALTH=false
            fi
        else
            fail "Ollama Service: Inativo"
            OVERALL_HEALTH=false
        fi
    else
        warn "Ollama: Não instalado"
    fi
}

# Função para verificar Dask
check_dask() {
    log "Verificando Dask..."
    
    # Check Dask scheduler
    if process_running "dask-scheduler"; then
        success "Dask Scheduler: Executando"
    else
        warn "Dask Scheduler: Não está executando"
    fi
    
    # Check Dask workers
    local workers_count=$(pgrep -f "dask-worker" | wc -l)
    if [ $workers_count -gt 0 ]; then
        success "Dask Workers: $workers_count executando"
    else
        warn "Dask Workers: Nenhum worker executando"
    fi
}

# Função para verificar containers Docker do projeto
check_docker_containers() {
    log "Verificando containers Docker do projeto..."
    
    # Check for OpenWebUI container
    if docker ps --format '{{.Names}}' | grep -q "open-webui"; then
        success "Container OpenWebUI: Executando"
    else
        warn "Container OpenWebUI: Não está executando"
    fi
    
    # Check for OpenWebUI Nginx container
    if docker ps --format '{{.Names}}' | grep -q "openwebui-nginx"; then
        success "Container OpenWebUI Nginx: Executando"
    else
        warn "Container OpenWebUI Nginx: Não está executando"
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
    echo -e "${BLUE}=== VERIFICAÇÃO DE SAÚDE - CLUSTER AI ===${NC}"
    echo "Log: $LOG_FILE"
    exec > >(tee -a "$LOG_FILE") 2>&1
    
    # Verificações básicas do sistema
    echo -e "\n${CYAN}1. VERIFICAÇÕES DO SISTEMA${NC}"
    check_command "docker" "Docker"
    check_command "python3" "Python 3"
    check_command "pip" "PIP"
    check_command "git" "Git"
    check_command "curl" "cURL"
    
    # Verificar serviços
    echo -e "\n${CYAN}2. VERIFICAÇÃO DE SERVIÇOS${NC}"
    check_service "docker" "Serviço Docker"
    
    # Verificar Ollama
    echo -e "\n${BLUE}3. VERIFICAÇÃO DO OLLAMA${NC}"
    check_ollama
    
    # Verificar Dask
    echo -e "\n${CYAN}4. VERIFICAÇÃO DO DASK${NC}"
    check_dask
    
    # Verificar containers Docker
    echo -e "\n${BLUE}5. VERIFICAÇÃO DE CONTAINERS DOCKER${NC}"
    check_docker_containers
    
    # Verificar GPU
    echo -e "\n${CYAN}6. VERIFICAÇÃO DE GPU${NC}"
    check_gpu
    
    # Verificar PyTorch
    echo -e "\n${BLUE}7. VERIFICAÇÃO DO PyTorch${NC}"
    check_pytorch
    
    # Verificar ambiente virtual
    echo -e "\n${CYAN}8. VERIFICAÇÃO DO AMBIENTE VIRTUAL${NC}"
    check_venv
    
    # Verificar recursos
    echo -e "\n${CYAN}9. RECURSOS DO SISTEMA${NC}"
    check_resources
    check_temperature
    
    # Verificar diretórios importantes
    echo -e "\n${BLUE}10. ESTRUTURA DE DIRETÓRIOS${NC}"
    check_directory "$HOME/venv" "Diretório do ambiente virtual"
    check_directory "$HOME/cluster_scripts" "Diretório de scripts do cluster"
    check_directory "$HOME/.ollama" "Diretório do Ollama"
    check_directory ".venv" "Diretório .venv do projeto"
    
    # Resumo final
    echo -e "\n${BLUE}=== RESUMO DA SAÚDE DO SISTEMA ===${NC}"
    
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
