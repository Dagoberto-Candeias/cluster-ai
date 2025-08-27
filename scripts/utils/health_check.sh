#!/bin/bash
# Sistema de Verificação de Saúde do Cluster AI

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[HEALTH-CHECK]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[HEALTH-WARN]${NC} $1"
}

error() {
    echo -e "${RED}[HEALTH-ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

fail() {
    echo -e "${RED}❌ $1${NC}"
}

# Configuração
LOG_FILE="/tmp/cluster_ai_health_$(date +%Y%m%d_%H%M%S).log"
OVERALL_HEALTH=true

# Função para verificar comando
check_command() {
    local cmd="$1"
    local description="$2"
    
    if command -v "$cmd" >/dev/null 2>&1; then
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
    
    if systemctl is-active --quiet "$service"; then
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
    if command -v nvidia-smi >/dev/null 2>&1; then
        success "GPU NVIDIA: Detectada"
        nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv
        return 0
    fi
    
    # Verificar AMD
    if command -v rocminfo >/dev/null 2>&1 || [ -d "/opt/rocm" ]; then
        success "GPU AMD: Detectada"
        if command -v rocminfo >/dev/null 2>&1; then
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
    
    if [ -d "$HOME/venv" ]; then
        success "Ambiente virtual: Existe"
        
        # Verificar se pode ser ativado
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

# Função para verificar uso de recursos
check_resources() {
    log "Verificando recursos do sistema..."
    
    # Memória
    local mem_total=$(free -h | awk '/Mem:/ {print $2}')
    local mem_used=$(free -h | awk '/Mem:/ {print $3}')
    local mem_free=$(free -h | awk '/Mem:/ {print $4}')
    
    echo "💾 Memória: Total: $mem_total, Usada: $mem_used, Livre: $mem_free"
    
    # CPU
    local cpu_cores=$(nproc)
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}')
    
    echo "⚡ CPU: Núcleos: $cpu_cores, Carga: $cpu_load"
    
    # Disco
    local disk_usage=$(df -h / | awk 'NR==2 {print $5 " usado (" $3 "/" $2 ")"}')
    echo "💿 Disco: $disk_usage"
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
    
    # Verificar GPU
    echo -e "\n${CYAN}3. VERIFICAÇÃO DE GPU${NC}"
    check_gpu
    
    # Verificar PyTorch
    echo -e "\n${CYAN}4. VERIFICAÇÃO DO PyTorch${NC}"
    check_pytorch
    
    # Verificar ambiente virtual
    echo -e "\n${CYAN}5. VERIFICAÇÃO DO AMBIENTE VIRTUAL${NC}"
    check_venv
    
    # Verificar recursos
    echo -e "\n${CYAN}6. RECURSOS DO SISTEMA${NC}"
    check_resources
    check_temperature
    
    # Verificar diretórios importantes
    echo -e "\n${CYAN}7. ESTRUTURA DE DIRETÓRIOS${NC}"
    check_directory "$HOME/venv" "Diretório do ambiente virtual"
    check_directory "$HOME/cluster_scripts" "Diretório de scripts do cluster"
    check_directory "$HOME/.ollama" "Diretório do Ollama"
    
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
    if ! command -v nvidia-smi >/dev/null 2>&1 && ! [ -d "/opt/rocm" ]; then
        echo "- Instalar drivers GPU para melhor performance"
    fi
    
    if [ ! -d "$HOME/venv" ]; then
        echo "- Configurar ambiente virtual: ./scripts/installation/venv_setup.sh"
    fi
    
    if ! systemctl is-active --quiet docker; then
        echo "- Iniciar serviço Docker: sudo systemctl start docker"
    fi
    
    echo -e "\n${GREEN}🚀 Use './scripts/validation/run_complete_test_modified.sh' para teste completo${NC}"
}

# Executar
main "$@"
