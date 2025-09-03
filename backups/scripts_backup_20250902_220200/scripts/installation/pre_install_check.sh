#!/bin/bash
# Script de Verificação Pré-Instalação Avançada
# Verifica requisitos do sistema antes da instalação do Cluster AI

set -euo pipefail

# Carregar funções comuns
COMMON_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO: Script de funções comuns não encontrado em $COMMON_SCRIPT_PATH" >&2
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# ==================== CONFIGURAÇÃO ====================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/logs"
LOG_FILE="${LOG_DIR}/pre_install_check_$(date +%Y%m%d_%H%M%S).log"

# Criar diretório de logs se não existir
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

# ==================== VARIÁVEIS DE CONTROLE ====================

CHECKS_PASSED=0
CHECKS_TOTAL=0
CHECKS_WARNING=0
CHECKS_FAILED=0

# ==================== FUNÇÕES DE VALIDAÇÃO AVANÇADA ====================

# Função para executar verificação com controle de status
run_check() {
    local check_name="$1"
    local check_function="$2"
    local is_critical="${3:-true}"

    subsection "Verificando: $check_name"
    ((CHECKS_TOTAL++))

    if $check_function; then
        success "✅ $check_name: OK"
        ((CHECKS_PASSED++))
        return 0
    else
        if [ "$is_critical" = true ]; then
            error "❌ $check_name: FALHA CRÍTICA"
            ((CHECKS_FAILED++))
            return 1
        else
            warn "⚠️  $check_name: AVISO (não crítico)"
            ((CHECKS_WARNING++))
            return 0
        fi
    fi
}

# Verifica privilégios sudo
check_sudo_privileges() {
    if sudo -n true 2>/dev/null; then
        log "Privilégios sudo disponíveis sem senha"
        return 0
    elif sudo -v 2>/dev/null; then
        log "Privilégios sudo disponíveis (senha pode ser solicitada)"
        return 0
    else
        warn "Privilégios sudo não disponíveis ou não configurados"
        return 1
    fi
}

# Verifica espaço em disco
check_disk_space() {
    local required_gb=50
    local available_gb
    
    available_gb=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if [ "$available_gb" -ge "$required_gb" ]; then
        success "Espaço em disco suficiente: ${available_gb}GB disponíveis"
        return 0
    else
        warn "Espaço em disco limitado: ${available_gb}GB disponíveis (mínimo recomendado: ${required_gb}GB)"
        return 1 # É um problema potencial, então falha a verificação.
    fi
}

# Verifica memória RAM
check_memory() {
    local required_mb=8000 # 8GB
    local total_mb

    # Usar LC_ALL=C para garantir um formato de saída padrão e -m para MB.
    total_mb=$(LC_ALL=C free -m | awk '/Mem:/ {print $2}')

    # Verificar se o valor é numérico
    if ! [[ "$total_mb" =~ ^[0-9]+$ ]]; then
        warn "Não foi possível determinar a memória RAM total."
        return 1 # É uma falha se não conseguirmos verificar.
    fi

    if [ "$total_mb" -ge "$required_mb" ]; then
        success "Memória RAM suficiente: $((total_mb / 1024))GB disponíveis"
        return 0
    else
        warn "Memória RAM limitada: $((total_mb / 1024))GB disponíveis (mínimo recomendado: $((required_mb / 1024))GB)"
        return 1
    fi
}

# Verifica conectividade com a internet
check_internet_connectivity() {
    if ping -c 1 -W 2 google.com >/dev/null 2>&1; then
        success "Conectividade com a internet: OK"
        return 0
    elif ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        success "Conectividade com a internet: OK (via IP)"
        return 0
    else
        error "Sem conectividade com a internet"
        return 1
    fi
}

# Verifica repositórios do sistema
check_system_repositories() {
    case $(detect_os) in
        ubuntu|debian)
            if apt-get update >/dev/null 2>&1; then
                success "Repositórios do sistema acessíveis"
                return 0
            else
                warn "Problemas para acessar repositórios do sistema"
                return 1
            fi
            ;;
        manjaro)
            if pacman -Sy --noconfirm >/dev/null 2>&1; then
                success "Repositórios do sistema acessíveis"
                return 0
            else
                warn "Problemas para acessar repositórios do sistema"
                return 1
            fi
            ;;
        centos)
            if command_exists dnf; then
                if dnf check-update >/dev/null 2>&1; then
                    success "Repositórios do sistema acessíveis"
                    return 0
                else
                    warn "Problemas para acessar repositórios do sistema"
                    return 1
                fi
            else
                if yum check-update >/dev/null 2>&1; then
                    success "Repositórios do sistema acessíveis"
                    return 0
                else
                    warn "Problemas para acessar repositórios do sistema"
                    return 1
                fi
            fi
            ;;
        *)
            warn "Sistema operacional não identificado para verificação de repositórios"
            return 0
            ;;
    esac
}

# Verifica dependências básicas
check_basic_dependencies() {
    local deps=("curl" "git" "python3" "wget" "tar" "gzip")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -eq 0 ]; then
        log "Todas as dependências básicas estão instaladas"
        return 0
    else
        warn "Dependências básicas faltando: ${missing_deps[*]}"
        return 1
    fi
}

# Verifica versão do Python
check_python_version() {
    if ! command_exists python3; then
        warn "Python3 não encontrado"
        return 1
    fi

    local python_version
    python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')

    if [[ "$(printf '%s\n' "$python_version" "3.8" | sort -V | head -n1)" = "3.8" ]]; then
        log "Versão do Python adequada: $python_version"
        return 0
    else
        warn "Versão do Python baixa: $python_version (recomendado: 3.8+)"
        return 1
    fi
}

# Verifica conectividade com repositórios específicos
check_repository_connectivity() {
    local repos=("pypi.org" "github.com" "registry-1.docker.io")
    local failed_repos=()

    for repo in "${repos[@]}"; do
        if ! ping -c 1 -W 3 "$repo" >/dev/null 2>&1; then
            failed_repos+=("$repo")
        fi
    done

    if [ ${#failed_repos[@]} -eq 0 ]; then
        log "Conectividade com todos os repositórios principais OK"
        return 0
    else
        warn "Problemas de conectividade com: ${failed_repos[*]}"
        return 1
    fi
}

# Verifica permissões de escrita em diretórios importantes
check_write_permissions() {
    local dirs=("$HOME" "$HOME/.local" "/tmp" "$PROJECT_ROOT")
    local failed_dirs=()

    for dir in "${dirs[@]}"; do
        if [ ! -w "$dir" ]; then
            failed_dirs+=("$dir")
        fi
    done

    if [ ${#failed_dirs[@]} -eq 0 ]; then
        log "Permissões de escrita adequadas em todos os diretórios"
        return 0
    else
        warn "Sem permissões de escrita em: ${failed_dirs[*]}"
        return 1
    fi
}

# Verifica se há processos conflitantes
check_conflicting_processes() {
    local conflicting_procs=("ollama" "dask-scheduler" "dask-worker")
    local running_procs=()

    for proc in "${conflicting_procs[@]}"; do
        if pgrep -f "$proc" >/dev/null 2>&1; then
            running_procs+=("$proc")
        fi
    done

    if [ ${#running_procs[@]} -eq 0 ]; then
        log "Nenhum processo conflitante detectado"
        return 0
    else
        warn "Processos conflitantes em execução: ${running_procs[*]}"
        info "Considere parar estes processos antes da instalação"
        return 0  # Não é crítico, apenas um aviso
    fi
}

# Verifica configuração de locale
check_locale_settings() {
    if locale -a 2>/dev/null | grep -q "C.UTF-8\|en_US.UTF-8"; then
        log "Configuração de locale adequada"
        return 0
    else
        warn "Configuração de locale pode causar problemas"
        info "Recomenda-se instalar locales adequados"
        return 0  # Não é crítico
    fi
}

 # --- Função Principal ---
 main() {
     section "Verificação Pré-Instalação do Cluster AI"

     run_check "Privilégios sudo" check_sudo_privileges false
     run_check "Espaço em disco disponível" check_disk_space true
     run_check "Memória RAM disponível" check_memory true
     run_check "Versão do Python" check_python_version true
     run_check "Conectividade com repositórios" check_repository_connectivity true
     run_check "Dependências básicas" check_basic_dependencies true
     run_check "Permissões de escrita" check_write_permissions true
     run_check "Processos conflitantes" check_conflicting_processes false
     run_check "Configuração de locale" check_locale_settings false

     echo ""
     log "Resumo das verificações:"
     log "  - Total de verificações: $CHECKS_TOTAL"
     log "  - Verificações aprovadas: $CHECKS_PASSED"
     log "  - Verificações com aviso: $CHECKS_WARNING"
     log "  - Verificações falhadas: $CHECKS_FAILED"
     echo ""

     if [ $CHECKS_FAILED -gt 0 ]; then
         error "❌ Algumas verificações críticas falharam. Recomenda-se corrigir antes da instalação."
         return 1
     elif [ $CHECKS_WARNING -gt 0 ]; then
         warn "⚠️ Algumas verificações apresentaram avisos. A instalação pode prosseguir com limitações."
         return 0
     else
         success "✅ Todas as verificações passaram! Sistema pronto para instalação."
         return 0
     fi
}

# Executar apenas se chamado diretamente
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
