#!/bin/bash
# Script de Verificação Pré-Instalação
# Verifica requisitos do sistema antes da instalação do Cluster AI

# Carregar funções comuns
COMMON_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO: Script de funções comuns não encontrado em $COMMON_SCRIPT_PATH" >&2
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# --- Funções de Verificação ---

# Verifica privilégios sudo
check_sudo_privileges() {
    if sudo -n true 2>/dev/null; then
        success "Privilégios sudo disponíveis"
        return 0
    else
        warn "A senha de sudo pode ser solicitada durante a instalação."
        # Isso não é um erro, apenas um aviso para sessões interativas.
        return 0
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
    local deps=("curl" "git" "python3")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        success "Dependências básicas instaladas"
        return 0
    else
        warn "Dependências básicas faltando: ${missing_deps[*]}"
        return 1
    fi
}

# --- Função Principal ---
main() {
    section "Verificação Pré-Instalação do Cluster AI"
    
    local checks_passed=0
    local checks_total=0
    
    # Executar verificações
    check_sudo_privileges && ((checks_passed++)); ((checks_total++))
    check_disk_space && ((checks_passed++)); ((checks_total++))
    check_memory && ((checks_passed++)); ((checks_total++))
    check_internet_connectivity && ((checks_passed++)); ((checks_total++))
    check_system_repositories && ((checks_passed++)); ((checks_total++))
    check_basic_dependencies && ((checks_passed++)); ((checks_total++))
    
    # Resultado final
    echo ""
    if [ $checks_passed -eq $checks_total ]; then
        success "✅ Todas as verificações passaram! Sistema pronto para instalação."
        return 0
    elif [ $checks_passed -ge $((checks_total * 2 / 3)) ]; then
        warn "⚠️  $checks_passed/$checks_total verificações passaram. Instalação pode prosseguir com limitações."
        return 0
    else
        error "❌ Apenas $checks_passed/$checks_total verificações passaram. Recomenda-se resolver os problemas antes da instalação."
        return 1
    fi
}

# Executar apenas se chamado diretamente
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
