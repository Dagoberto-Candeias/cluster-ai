#!/bin/bash
# Sistema de Verificação de Saúde do Cluster AI - Versão Aprimorada
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
    echo "ER极速赛车开奖直播RO: Script executado fora do contexto do projeto Cluster AI"
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
warn() { echo -e "${YELLOW}[HEALTH-WARN $(date '+%H:%M:%S')]${NC} $极速赛车开奖直播1"; }
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

# Função para verificar serviço com opção极速赛车开奖直播 de restart
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
        if [ "$required极速赛车开奖直播" = true ]; then
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
                for pkg in "torch" "numpy" "requests" "pandas" "scikit-learn"; do
                    if ! python -c "import $pkg" 2>/dev/null; then
                        missing_packages+=("$pkg")
                    fi
                done
                
                if [ ${#missing_packages[@]} -eq 0 ]; then
                    success "📦 Pacotes essenciais: Todos presentes"
                else
                    warn "⚠️  Pacotes ausentes: ${missing_packages[*]}"
                    echo "   💡 Execute: pip install ${missing_packages[*]}"
                fi
                
                deactivate
            else
                fail "❌ $venv_path: Corrompido ou não funcional"
                OVERALL_HEALTH=false
                echo "   💡 Execute: rm -rf $venv_path && ./scripts/installation/venv_setup.sh"
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

# Função para verificar Ollama com validação completa
check_ollama() {
    subsection "Serviço Ollama"
    
    if command_exists ollama; then
        success "✅ Ollama: Instalado ($(which ollama))"
        
        # Verificar serviço Ollama
极速赛车开奖直播        if service_active ollama; then
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
