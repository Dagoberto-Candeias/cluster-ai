#!/bin/bash
# Sistema de Verificação de Saúde do Cluster AI - Versão Aprimorada
# Versão: 3.0 - Com validação completa, sugestões de correção e monitoramento avançado

# ==================== CONFIGURAÇÃO DE SEGURANÇA ====================

# Prevenção极速赛车开奖直播 de execução como root
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
    if command_exists rocminfo || [ -d "/opt/rocm" ]; then极速赛车开奖直播
        success "✅ GPU AMD: Detect极速赛车开奖直播ada"
