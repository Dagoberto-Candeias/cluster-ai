#!/bin/bash
# Script de instalação automática de drivers GPU para Cluster AI

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[GPU-SETUP]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[GPU-WARN]${NC} $1"
}

error() {
    echo -e "${RED}[GPU-ERROR]${NC} $1"
}

# Configuração
LOG_FILE="/tmp/gpu_setup_$(date +%Y%m%d_%H%M%S).log"
GPU_CONFIG="$HOME/.cluster_gpu_config"

# Função para verificar sudo
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        error "Este script requer privilégios sudo"
        exit 1
    fi
}

# Função para detectar tipo de GPU
detect_gpu_type() {
    if [ -f "$GPU_CONFIG" ]; then
        source "$GPU_CONFIG"
        echo "$GPU_TYPE"
    else
        # Detecção básica se o arquivo de configuração não existir
        if lspci -nn | grep -i "nvidia" >/dev/null 2>&1; then
            echo "nvidia"
        elif lspci -nn | grep -i "amd" | grep -i "vga\|display" >/dev/null 2>&1; then
            echo "amd"
        else
            echo "none"
        fi
    fi
}

# Função para instalar NVIDIA CUDA
install_nvidia() {
    log "Instalando NVIDIA CUDA..."
    
    # Atualizar sistema
    apt update && apt upgrade -y
    
    # Instalar dependências
    apt install -y wget curl gnupg software-properties-common \
                  build-essential dkms linux-headers-$(uname -r)
    
    # Adicionar repositório NVIDIA
    wget https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb
    dpkg -i cuda-keyring_1.1-1_all.deb
    apt update
    
    # Instalar CUDA Toolkit
    apt install -y cuda
    
    # Configurar variáveis de ambiente
    echo 'export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}' >> /etc/profile.d/cuda.sh
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> /etc/profile.d/cuda.sh
    chmod +x /etc/profile.d/cuda.sh
    
    # Blacklist nouveau se necessário
    if lsmod | grep -q "nouveau"; then
        warn "Nouveau detectado - aplicando blacklist..."
        echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nouveau.conf
        echo "options nouveau modeset=0" >> /etc/modprobe.d/blacklist-nouveau.conf
        update-initramfs -u
    fi
    
    log "Instalação NVIDIA CUDA concluída"
}

# Função para instalar AMD ROCm
install_amd() {
    log "Instalando AMD ROCm..."
    
    # Definir versões (ajustar conforme necessário)
    local ROCM_VER="6.1.1"
    local APT_CODENAME="jammy"  # Ubuntu jammy para Debian 13
    
    # Atualizar sistema
    apt update && apt upgrade -y
    
    # Instalar dependências
    apt install -y wget ca-certificates gnupg lsb-release curl \
                  build-essential dkms linux-headers-$(uname -r) \
                  python3-setuptools python3-wheel initramfs-tools
    
    # Adicionar chave GPG
    mkdir -p /etc/apt/keyrings
    wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | gpg --dearmor | tee /etc/apt/keyrings/rocm.gpg > /dev/null
    
    # Adicionar repositório
    tee /etc/apt/sources.list.d/rocm.list > /dev/null <<EOF
deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/${ROCM_VER} ${APT_CODENAME} main
EOF
    
    # Instalar ROCm
    apt install -y rocm-dev rocm-hip-runtime rocm-hip-libraries
    
    # Verificar Secure Boot
    if command -v mokutil >/dev/null 2>&1; then
        if mokutil --sb-state 2>/dev/null | grep -q "enabled"; then
            warn "Secure Boot ativado - pode requerer enrolamento MOK manual"
        fi
    fi
    
    log "Instalação AMD ROCm concluída"
}

# Função para configurar PyTorch com suporte GPU
setup_pytorch_gpu() {
    local gpu_type=$1
    
    log "Configurando PyTorch com suporte para $gpu_type..."
    
    # Ativar ambiente virtual se existir
    if [ -f "/home/dcm/Projetos/cluster-ai/.venv/bin/activate" ]; then
        source "/home/dcm/Projetos/cluster-ai/.venv/bin/activate"
    fi
    
    # Instalar PyTorch com suporte apropriado
    if [ "$gpu_type" = "nvidia" ]; then
        pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
    elif [ "$gpu_type" = "amd" ]; then
        pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.0
    else
        pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
    fi
    
    log "PyTorch configurado para $gpu_type"
}

# Função para validar instalação
validate_installation() {
    local gpu_type=$1
    
    log "Validando instalação..."
    
    if [ "$gpu_type" = "nvidia" ]; then
        if command -v nvidia-smi >/dev/null 2>&1; then
            nvidia-smi
            log "✅ NVIDIA drivers validados"
        else
            error "❌ NVIDIA drivers não funcionando"
            return 1
        fi
        
        if command -v nvcc >/dev/null 2>&1; then
            nvcc --version
            log "✅ CUDA Toolkit validado"
        else
            error "❌ CUDA Toolkit não instalado"
            return 1
        fi
        
    elif [ "$gpu_type" = "amd" ]; then
        if [ -f "/opt/rocm/bin/rocminfo" ]; then
            /opt/rocm/bin/rocminfo --version
            log "✅ ROCm validado"
        else
            error "❌ ROCm não instalado"
            return 1
        fi
    fi
    
    return 0
}

# Função principal
main() {
    check_sudo
    
    log "Iniciando configuração de GPU..."
    echo "Log detalhado: $LOG_FILE"
    exec > >(tee -a "$LOG_FILE") 2>&1
    
    local gpu_type=$(detect_gpu_type)
    
    if [ "$gpu_type" = "none" ]; then
        warn "Nenhuma GPU dedicada detectada - configurando para CPU apenas"
        setup_pytorch_gpu "cpu"
        exit 0
    fi
    
    log "GPU detectada: $gpu_type"
    
    # Instalar drivers
    if [ "$gpu_type" = "nvidia" ]; then
        install_nvidia
    elif [ "$gpu_type" = "amd" ]; then
        install_amd
    fi
    
    # Configurar PyTorch
    setup_pytorch_gpu "$gpu_type"
    
    # Validar
    if validate_installation "$gpu_type"; then
        log "✅ Configuração de GPU concluída com sucesso!"
        echo ""
        echo -e "${GREEN}=== PRÓXIMOS PASSOS ===${NC}"
        echo "1. Reinicie o sistema: sudo reboot"
        echo "2. Execute novamente a validação: ./scripts/validation/validate_installation.sh"
        echo "3. Teste com: python scripts/utils/test_gpu.py"
    else
        error "❌ Falha na configuração de GPU"
        echo -e "${RED}Consulte o log: $LOG_FILE${NC}"
        exit 1
    fi
}

# Executar
main "$@"
