#!/bin/bash
# Biblioteca de funções comuns para os scripts do Cluster AI

# --- Configuração de Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Funções de Log ---
log() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

fail() {
    echo -e "${RED}❌ $1${NC}"
}

# --- Funções de Verificação ---

# Verifica se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verifica se um serviço systemd está ativo
service_active() {
    systemctl is-active --quiet "$1"
}

# Verifica se um processo está rodando (usando pgrep)
process_running() {
    pgrep -f "$1" >/dev/null
}

# --- Funções de Segurança ---

# Validação de segurança para caminhos de arquivos/diretórios
safe_path_check() {
    local path="$1"
    local operation="$2"
    
    # Verificar se o caminho está vazio
    if [ -z "$path" ]; then
        error "ERRO CRÍTICO: Caminho vazio para operação: $operation"
        return 1
    fi
    
    # Verificar se é o diretório raiz
    if [ "$path" = "/" ]; then
        error "ERRO CRÍTICO: Tentativa de operação no diretório raiz: $operation"
        return 1
    fi
    
    # Lista de diretórios críticos do sistema
    local critical_dirs=("/usr" "/bin" "/sbin" "/etc" "/var" "/lib" "/boot" "/root")
    for dir in "${critical_dirs[@]}"; do
        if [[ "$path" == "$dir"* ]]; then
            error "ERRO CRÍTICO: Tentativa de operação em diretório crítico: $dir"
            return 1
        fi
    done
    
    # Verificar se o caminho está dentro do projeto ou home do usuário
    local project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    if [[ "$path" != "$HOME"* ]] && [[ "$path" != "$project_root"* ]] && [[ "$path" != "/tmp"* ]]; then
        warn "AVISO: Operação fora do diretório do projeto, home ou tmp: $path"
        # Não é erro crítico, apenas warning
    fi
    
    return 0
}

# Confirmação explícita do usuário para operações perigosas
confirm_operation() {
    local message="$1"
    local default="${2:-n}"
    
    echo -e "${YELLOW}⚠️  $message${NC}"
    read -p "Deseja continuar? (s/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Função segura para remoção de arquivos/diretórios
safe_remove() {
    local target="$1"
    local description="$2"
    
    if ! safe_path_check "$target" "remoção de $description"; then
        return 1
    fi
    
    if [ -e "$target" ]; then
        if confirm_operation "Esta operação irá remover: $target"; then
            rm -rf "$target"
            log "$description removido com segurança: $target"
            return 0
        else
            warn "Operação de remoção cancelada pelo usuário"
            return 1
        fi
    else
        warn "$description não existe: $target"
        return 1
    fi
}
