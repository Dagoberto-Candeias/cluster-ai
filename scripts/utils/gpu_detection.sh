#!/bin/bash
# Script de detecção e configuração de GPU para Cluster AI

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[GPU-DETECT]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[GPU-WARN]${NC} $1"
}

error() {
    echo -e "${RED}[GPU-ERROR]${NC} $1"
}

# Configuração
GPU_INFO_FILE="/tmp/cluster_ai_gpu_info.log"
GPU_CONFIG_FILE="$HOME/.cluster_gpu_config"

# Função para detectar GPUs
detect_gpus() {
    echo "=== DETECÇÃO DE GPUs ===" > "$GPU_INFO_FILE"
    echo "Data/Hora: $(date '+%Y-%m-%d %H:%M:%S')" >> "$GPU_INFO_FILE"
    echo "Sistema: $(uname -a)" >> "$GPU_INFO_FILE"
    echo "" >> "$GPU_INFO_FILE"
    
    # Detectar GPUs NVIDIA
    log "Detectando GPUs NVIDIA..."
    NVIDIA_GPUS=$(lspci -nn | grep -i "nvidia" | wc -l)
    if [ "$NVIDIA_GPUS" -gt 0 ]; then
        echo "=== GPUs NVIDIA DETECTADAS ===" >> "$GPU_INFO_FILE"
        lspci -nn | grep -i "nvidia" >> "$GPU_INFO_FILE"
        echo "Total: $NVIDIA_GPUS GPU(s) NVIDIA" >> "$GPU_INFO_FILE"
        log "Encontradas $NVIDIA_GPUS GPU(s) NVIDIA"
    fi
    
    # Detectar GPUs AMD
    log "Detectando GPUs AMD..."
    AMD_GPUS=$(lspci -nn | grep -i "amd" | grep -i "vga\|display" | wc -l)
    if [ "$AMD_GPUS" -gt 0 ]; then
        echo "" >> "$GPU_INFO_FILE"
        echo "=== GPUs AMD DETECTADAS ===" >> "$GPU_INFO_FILE"
        lspci -nn | grep -i "amd" | grep -i "vga\|display" >> "$GPU_INFO_FILE"
        echo "Total: $AMD_GPUS GPU(s) AMD" >> "$GPU_INFO_FILE"
        log "Encontradas $AMD_GPUS GPU(s) AMD"
    fi
    
    # Detectar GPUs Intel
    log "Detectando GPUs Intel..."
    INTEL_GPUS=$(lspci -nn | grep -i "intel" | grep -i "vga\|display" | wc -l)
    if [ "$INTEL_GPUS" -gt 0 ]; then
        echo "" >> "$GPU_INFO_FILE"
        echo "=== GPUs Intel DETECTADAS ===" >> "$GPU_INFO_FILE"
        lspci -nn | grep -i "intel" | grep -i "vga\|display" >> "$GPU_INFO_FILE"
        echo "Total: $INTEL_GPUS GPU(s) Intel" >> "$GPU_INFO_FILE"
        log "Encontradas $INTEL_GPUS GPU(s) Intel"
    fi
    
    # Verificar drivers carregados
    echo "" >> "$GPU_INFO_FILE"
    echo "=== DRIVERS CARREGADOS ===" >> "$GPU_INFO_FILE"
    lsmod | grep -E "nvidia|amdgpu|radeon|nouveau|i915" >> "$GPU_INFO_FILE" || echo "Nenhum driver de GPU carregado" >> "$GPU_INFO_FILE"
    
    # Verificar CUDA
    if command -v nvcc >/dev/null 2>&1; then
        echo "" >> "$GPU_INFO_FILE"
        echo "=== CUDA DETECTADO ===" >> "$GPU_INFO_FILE"
        nvcc --version >> "$GPU_INFO_FILE"
    fi
    
    # Verificar ROCm
    if [ -f "/opt/rocm/bin/rocminfo" ]; then
        echo "" >> "$GPU_INFO_FILE"
        echo "=== ROCm DETECTADO ===" >> "$GPU_INFO_FILE"
        /opt/rocm/bin/rocminfo --version 2>/dev/null >> "$GPU_INFO_FILE" || echo "ROCm presente mas rocminfo falhou" >> "$GPU_INFO_FILE"
    fi
    
    # Verificar nvidia-smi
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "" >> "$GPU_INFO_FILE"
        echo "=== NVIDIA-SMI ===" >> "$GPU_INFO_FILE"
        nvidia-smi >> "$GPU_INFO_FILE" 2>/dev/null || echo "nvidia-smi falhou" >> "$GPU_INFO_FILE"
    fi
    
    log "Informações de GPU salvas em: $GPU_INFO_FILE"
}

# Função para gerar configuração de GPU
generate_gpu_config() {
    local has_nvidia=$(lspci -nn | grep -i "nvidia" | wc -l)
    local has_amd=$(lspci -nn | grep -i "amd" | grep -i "vga\|display" | wc -l)
    local has_cuda=$(command -v nvcc >/dev/null 2>&1 && echo "true" || echo "false")
    local gpu_vram_mb=0
    local has_rocm=$([ -f "/opt/rocm/bin/rocminfo" ] && echo "true" || echo "false")

    # Inicializar arquivo de configuração
    echo "DETECTION_DATE=$(date '+%Y-%m-%d %H:%M:%S')" > "$GPU_CONFIG_FILE"

    if [ "$has_nvidia" -gt 0 ]; then
        if command -v nvidia-smi >/dev/null 2>&1; then
            # Get VRAM in MiB from the first GPU
            gpu_vram_mb=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -n 1 || echo "0")
        fi
        echo "GPU_TYPE=nvidia" >> "$GPU_CONFIG_FILE"
        echo "GPU_COUNT=$has_nvidia" >> "$GPU_CONFIG_FILE"
        echo "CUDA_AVAILABLE=$has_cuda" >> "$GPU_CONFIG_FILE"
        echo "ROCm_AVAILABLE=false" >> "$GPU_CONFIG_FILE"
        log "Configuração NVIDIA gerada: $has_nvidia GPU(s), CUDA: $has_cuda, VRAM: ${gpu_vram_mb}MB"
    elif [ "$has_amd" -gt 0 ]; then
        # Tentar detectar VRAM para AMD usando múltiplos métodos
        if command -v glxinfo >/dev/null 2>&1; then
            gpu_vram_mb=$(glxinfo | grep -i "video memory" | head -n 1 | awk '{print $3}' | sed 's/[^0-9]*//g')
        fi

        if [ -z "$gpu_vram_mb" ] || [ "$gpu_vram_mb" = "0" ]; then
            # Tentar ler diretamente dos arquivos do sistema
            for card in /sys/class/drm/card*; do
                if [ -f "$card/device/mem_info_vram_total" ]; then
                    vram_bytes=$(cat "$card/device/mem_info_vram_total" 2>/dev/null)
                    if [ ! -z "$vram_bytes" ]; then
                        gpu_vram_mb=$((vram_bytes / 1024 / 1024))
                        break
                    fi
                fi
            done
        fi

        if [ -z "$gpu_vram_mb" ] || [ "$gpu_vram_mb" = "0" ]; then
            # Método alternativo com lshw
            if command -v lshw >/dev/null 2>&1; then
                gpu_vram_mb=$(lshw -C display | grep -i 'size' | head -n 1 | awk '{print $2}' | sed 's/[^0-9]*//g')
            fi
        fi

        if [ -z "$gpu_vram_mb" ]; then
            gpu_vram_mb=0
        fi

        echo "GPU_TYPE=amd" >> "$GPU_CONFIG_FILE"
        echo "GPU_COUNT=$has_amd" >> "$GPU_CONFIG_FILE"
        echo "CUDA_AVAILABLE=false" >> "$GPU_CONFIG_FILE"
        echo "ROCm_AVAILABLE=$has_rocm" >> "$GPU_CONFIG_FILE"
        log "Configuração AMD gerada: $has_amd GPU(s), ROCm: $has_rocm, VRAM detectada: ${gpu_vram_mb}MB"
    else
        echo "GPU_TYPE=none" >> "$GPU_CONFIG_FILE"
        echo "GPU_COUNT=0" >> "$GPU_CONFIG_FILE"
        echo "CUDA_AVAILABLE=false" >> "$GPU_CONFIG_FILE"
        echo "ROCm_AVAILABLE=false" >> "$GPU_CONFIG_FILE"
        warn "Nenhuma GPU dedicada detectada - usando CPU apenas"
    fi

    echo "GPU_VRAM_MB=${gpu_vram_mb:-0}" >> "$GPU_CONFIG_FILE"
}

# Função para verificar compatibilidade
check_compatibility() {
    local kernel_version=$(uname -r)
    local os_info=$(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')
    
    echo "" >> "$GPU_INFO_FILE"
    echo "=== COMPATIBILIDADE ===" >> "$GPU_INFO_FILE"
    echo "Kernel: $kernel_version" >> "$GPU_INFO_FILE"
    echo "Sistema: $os_info" >> "$GPU_INFO_FILE"
    
    # Verificar Secure Boot
    if command -v mokutil >/dev/null 2>&1; then
        local secure_boot=$(sudo mokutil --sb-state 2>/dev/null | grep -i "enabled" && echo "true" || echo "false")
        echo "Secure Boot: $secure_boot" >> "$GPU_INFO_FILE"
        if [ "$secure_boot" = "true" ]; then
            warn "Secure Boot ativado - pode requerer configuração adicional"
        fi
    fi
}

# Função principal
main() {
    log "Iniciando detecção de GPU..."
    detect_gpus
    check_compatibility
    generate_gpu_config
    log "Detecção concluída. Configuração salva em: $GPU_CONFIG_FILE"
    
    # Mostrar resumo
    echo ""
    echo -e "${BLUE}=== RESUMO DA DETECÇÃO DE GPU ===${NC}"
    if [ -f "$GPU_CONFIG_FILE" ]; then
        cat "$GPU_CONFIG_FILE"
    fi
    echo ""
    echo -e "${CYAN}Log completo:${NC} $GPU_INFO_FILE"
}

# Executar
main "$@"
