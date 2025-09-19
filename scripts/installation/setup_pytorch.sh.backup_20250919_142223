#!/bin/bash
# Script para instalação do PyTorch com suporte a GPU/CPU
# Otimizado para desenvolvimento de IA no Cluster AI

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

# Função para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detectar GPU
detect_gpu() {
    log "Detectando hardware GPU..."

    if command_exists nvidia-smi; then
        GPU_TYPE="cuda"
        CUDA_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -1)
        log "GPU NVIDIA detectada - CUDA disponível"
    elif command_exists rocm-smi; then
        GPU_TYPE="rocm"
        log "GPU AMD detectada - ROCm disponível"
    else
        GPU_TYPE="cpu"
        warn "Nenhuma GPU detectada - usando versão CPU"
    fi
}

# Instalar PyTorch
install_pytorch() {
    log "Instalando PyTorch..."

    # Verificar se já está instalado
    if python3 -c "import torch; print('PyTorch já instalado:', torch.__version__)" 2>/dev/null; then
        success "PyTorch já está instalado"
        return 0
    fi

    # Instalar via pip no ambiente virtual
    case $GPU_TYPE in
        cuda)
            log "Instalando PyTorch com suporte CUDA..."
            pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
            ;;
        rocm)
            log "Instalando PyTorch com suporte ROCm..."
            pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.0
            ;;
        cpu)
            log "Instalando PyTorch CPU-only..."
            pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
            ;;
    esac

    # Verificar instalação
    if python3 -c "import torch; print('PyTorch instalado:', torch.__version__)" 2>/dev/null; then
        success "PyTorch instalado com sucesso"
    else
        error "Falha na instalação do PyTorch"
        return 1
    fi
}

# Instalar bibliotecas complementares
install_complementary_libs() {
    log "Instalando bibliotecas complementares para PyTorch..."

    pip install \
        numpy \
        pandas \
        matplotlib \
        scikit-learn \
        jupyter \
        ipykernel \
        tensorboard \
        tqdm \
        pillow \
        opencv-python \
        transformers \
        accelerate \
        datasets \
        evaluate

    success "Bibliotecas complementares instaladas"
}

# Configurar Jupyter kernel
setup_jupyter_kernel() {
    log "Configurando kernel Jupyter para o ambiente..."

    # Instalar kernel Python
    python3 -m ipykernel install --user --name cluster-ai --display-name "Python (Cluster AI)"

    success "Kernel Jupyter configurado"
}

# Testar instalação
test_installation() {
    log "Testando instalação do PyTorch..."

    python3 -c "
import torch
import torchvision
import numpy as np

print('PyTorch version:', torch.__version__)
print('Torchvision version:', torchvision.__version__)
print('CUDA disponível:', torch.cuda.is_available())
if torch.cuda.is_available():
    print('GPU:', torch.cuda.get_device_name(0))
    print('CUDA version:', torch.version.cuda)

# Teste básico
x = torch.rand(5, 3)
print('Tensor shape:', x.shape)
print('Teste básico: OK')
"

    success "Teste do PyTorch concluído com sucesso"
}

# Função principal
main() {
    echo -e "${BLUE}=== INSTALAÇÃO PYTORCH - CLUSTER AI ===${NC}"

    # Detectar GPU
    detect_gpu

    # Instalar PyTorch
    if ! install_pytorch; then
        error "Falha na instalação do PyTorch"
        exit 1
    fi

    # Instalar bibliotecas complementares
    install_complementary_libs

    # Configurar Jupyter
    setup_jupyter_kernel

    # Testar instalação
    test_installation

    echo -e "\n${GREEN}✅ PYTORCH INSTALADO COM SUCESSO!${NC}"
    echo -e "${CYAN}Resumo:${NC}"
    echo "- PyTorch: $(python3 -c "import torch; print(torch.__version__)" 2>/dev/null)"
    echo "- GPU Support: $GPU_TYPE"
    echo "- Bibliotecas complementares instaladas"
    echo "- Kernel Jupyter configurado"
    echo ""
    echo -e "${YELLOW}Para usar:${NC}"
    echo "  python3 -c \"import torch; print('PyTorch OK')\""
    echo "  jupyter notebook  # Para usar Jupyter"
    echo "  tensorboard --logdir ./logs  # Para TensorBoard"
}

# Executar instalação
main
