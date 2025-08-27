#!/bin/bash
# Configuração do Ambiente Virtual Otimizado para Cluster AI

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[VENV-SETUP]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[VENV-WARN]${NC} $1"
}

error() {
    echo -e "${RED}[VENV-ERROR]${NC} $1"
    exit 1
}

# Configuração
VENV_DIR="$HOME/venv"
REQUIREMENTS_FILE="requirements.txt"
LOG_DIR="/tmp/venv_setup_logs"
mkdir -p "$LOG_DIR"

# Função para detectar GPU e configurar PyTorch apropriadamente
detect_gpu_and_configure() {
    log "Detectando configuração de GPU..."
    
    local pytorch_extra=""
    local torchvision_extra=""
    local torchaudio_extra=""
    
    # Verificar NVIDIA CUDA
    if command -v nvcc >/dev/null 2>&1 || command -v nvidia-smi >/dev/null 2>&1; then
        log "GPU NVIDIA detectada - Configurando para CUDA"
        pytorch_extra="torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118"
        return 0
    fi
    
    # Verificar AMD ROCm
    if [ -d "/opt/rocm" ] || command -v rocminfo >/dev/null 2>&1; then
        log "GPU AMD detectada - Configurando para ROCm"
        pytorch_extra="torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm5.6"
        return 0
    fi
    
    # Fallback para CPU
    warn "Nenhuma GPU detectada - Usando versão CPU"
    pytorch_extra="torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu"
    return 1
}

# Função para criar ambiente virtual
create_venv() {
    log "Criando ambiente virtual em: $VENV_DIR"
    
    if [ -d "$VENV_DIR" ]; then
        warn "Ambiente virtual já existe. Recriando..."
        rm -rf "$VENV_DIR"
    fi
    
    python3 -m venv "$VENV_DIR"
    
    if [ $? -eq 0 ]; then
        log "Ambiente virtual criado com sucesso"
        return 0
    else
        error "Falha ao criar ambiente virtual"
        return 1
    fi
}

# Função para instalar dependências básicas
install_basic_deps() {
    log "Instalando dependências básicas..."
    
    # Ativar ambiente virtual
    source "$VENV_DIR/bin/activate"
    
    # Atualizar pip
    pip install --upgrade pip
    
    # Instalar dependências básicas
    local basic_deps=(
        "numpy"
        "pandas"
        "scipy"
        "matplotlib"
        "seaborn"
        "scikit-learn"
        "jupyterlab"
        "notebook"
        "ipykernel"
        "requests"
        "beautifulsoup4"
        "lxml"
        "fastapi"
        "uvicorn"
        "pytest"
        "httpx"
    )
    
    for dep in "${basic_deps[@]}"; do
        pip install "$dep"
    done
    
    log "Dependências básicas instaladas"
}

# Função para instalar PyTorch com suporte apropriado
install_pytorch() {
    log "Instalando PyTorch com suporte otimizado..."
    
    source "$VENV_DIR/bin/activate"
    
    # Detectar GPU e obter comando de instalação
    detect_gpu_and_configure
    local pytorch_cmd=$pytorch_extra
    
    if [ -n "$pytorch_cmd" ]; then
        pip install $pytorch_cmd
    else
        pip install torch torchvision torchaudio
    fi
    
    # Verificar instalação do PyTorch
    python3 -c "import torch; print(f'PyTorch {torch.__version__}'); print(f'CUDA disponível: {torch.cuda.is_available()}'); print(f'Dispositivo: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"CPU\"}')"
    
    log "PyTorch instalado com sucesso"
}

# Função para instalar dependências do projeto
install_project_deps() {
    log "Instalando dependências do projeto..."
    
    source "$VENV_DIR/bin/activate"
    
    if [ -f "$REQUIREMENTS_FILE" ]; then
        pip install -r "$REQUIREMENTS_FILE"
        log "Dependências do projeto instaladas"
    else
        warn "Arquivo requirements.txt não encontrado"
    fi
}

# Função para configurar variáveis de ambiente
setup_environment() {
    log "Configurando variáveis de ambiente..."
    
    local env_file="$HOME/.cluster_ai_env"
    
    cat > "$env_file" << 'EOF'
# Cluster AI Environment Variables
export VENV_PATH="$HOME/venv"
export PYTHONPATH="$PYTHONPATH:$HOME/cluster_scripts"

# Ativar ambiente virtual
alias venv-activate="source \$VENV_PATH/bin/activate"

# Comandos úteis
alias cluster-status="python3 -c \"import torch; print('PyTorch:', torch.__version__); print('CUDA:', torch.cuda.is_available())\""
alias gpu-info="python3 scripts/utils/test_gpu.py"

# Adicionar binários do ambiente ao PATH
export PATH="\$VENV_PATH/bin:\$PATH"
EOF
    
    # Adicionar ao .bashrc se não existir
    if ! grep -q "cluster_ai_env" "$HOME/.bashrc"; then
        echo -e "\n# Cluster AI Environment\nsource \$HOME/.cluster_ai_env" >> "$HOME/.bashrc"
    fi
    
    log "Variáveis de ambiente configuradas"
}

# Função para criar script de ativação
create_activation_script() {
    log "Criando script de ativação..."
    
    local activate_script="$HOME/venv/activate_cluster.sh"
    
    cat > "$activate_script" << 'EOF'
#!/bin/bash
# Script de ativação do Cluster AI

echo "=== CLUSTER AI ENVIRONMENT ==="
echo "Ativando ambiente virtual..."

source ~/venv/bin/activate

echo "✅ Ambiente virtual ativado"
echo "📦 Python: $(python --version)"
echo "🐍 PIP: $(pip --version)"

# Verificar PyTorch
python -c "
import torch
print(f'🔥 PyTorch: {torch.__version__}')
if torch.cuda.is_available():
    print(f'🎮 CUDA: Disponível')
    print(f'💾 GPU: {torch.cuda.get_device_name(0)}')
else:
    print('⚡ CUDA: Não disponível - Modo CPU')
"

echo ""
echo "🚀 Use 'cluster-status' para verificar o status"
echo "💡 Use 'gpu-info' para informações da GPU"
EOF
    
    chmod +x "$activate_script"
    log "Script de ativação criado: $activate_script"
}

# Função principal
main() {
    echo -e "${BLUE}=== CONFIGURAÇÃO DO AMBIENTE VIRTUAL CLUSTER AI ===${NC}"
    
    # Criar ambiente virtual
    create_venv
    
    # Instalar dependências
    install_basic_deps
    install_pytorch
    install_project_deps
    
    # Configurar ambiente
    setup_environment
    create_activation_script
    
    # Mensagem final
    echo -e "${GREEN}🎉 Ambiente virtual configurado com sucesso!${NC}"
    echo ""
    echo -e "${BLUE}📋 PRÓXIMOS PASSOS:${NC}"
    echo "1. Ativar ambiente: source ~/venv/bin/activate"
    echo "2. Ou usar: ~/venv/activate_cluster.sh"
    echo "3. Verificar instalação: cluster-status"
    echo "4. Testar GPU: gpu-info"
    echo ""
    echo -e "${YELLOW}💡 DICA:${NC} O ambiente já inclui PyTorch com suporte otimizado para sua GPU!"
}

# Executar
main "$@"
