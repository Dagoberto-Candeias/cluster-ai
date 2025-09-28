#!/bin/bash
# =============================================================================
# Teste Multi-Plataforma - Worker Cluster AI
# =============================================================================
# Script unificado para testar workers em qualquer plataforma
# Funciona em Termux (Android), Debian, Manjaro e outras distros
#
# Autor: Cluster AI Team
# Data: 2025-09-23
# Versão: 1.0.0
# Arquivo: test_worker_multiplatform.sh
# =============================================================================

set -euo pipefail

# --- Importar detector de plataforma ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/detect_platform.sh"

# --- Cores para output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Funções auxiliares ---
log() { echo -e "${BLUE}[TEST]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# Função command_exists (definida localmente)
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- Função para verificar plataforma específica ---
check_platform_specific() {
    local platform
    platform=$(detect_platform)

    log "Verificando plataforma: $(get_platform_info "$platform")"

    case "$platform" in
        "termux")
            check_termux_environment
            ;;
        "debian"|"ubuntu"|"manjaro"|"arch"|"centos"|"linux")
            check_linux_environment
            ;;
        *)
            warn "Plataforma não reconhecida: $platform"
            return 1
            ;;
    esac
}

# --- Verificações específicas do Termux ---
check_termux_environment() {
    log "Verificando ambiente Termux..."

    if [ -d "/data/data/com.termux" ]; then
        success "Ambiente Termux OK"
        return 0
    else
        error "Este script deve ser executado no Termux!"
        return 1
    fi
}

# --- Verificações específicas do Linux ---
check_linux_environment() {
    log "Verificando ambiente Linux..."

    success "Ambiente Linux detectado"
    return 0
}

# --- Verificar dependências ---
check_dependencies() {
    local missing_deps=()
    local platform
    platform=$(detect_platform)

    log "Verificando dependências..."

    # Verificar Python
    if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
        missing_deps+=("python")
    else
        success "Python instalado"
    fi

    # Verificar SSH
    if ! command -v ssh >/dev/null 2>&1; then
        missing_deps+=("openssh")
    else
        success "SSH instalado"
    fi

    # Verificar Git
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    else
        success "Git instalado"
    fi

    # Verificar Dask (opcional)
    if command -v python3 >/dev/null 2>&1; then
        if python3 -c "import dask" 2>/dev/null || python -c "import dask" 2>/dev/null; then
            success "Dask instalado"
        else
            warn "Dask não instalado (opcional)"
        fi
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        warn "Dependências faltando: ${missing_deps[*]}"
        return 1
    fi

    return 0
}

# --- Verificar serviço SSH ---
check_ssh_service() {
    local platform
    platform=$(detect_platform)

    log "Verificando serviço SSH..."

    if is_android "$platform"; then
        # Termux: verificar se SSH está rodando
        if pgrep -f sshd >/dev/null; then
            success "Serviço SSH rodando"
            return 0
        else
            warn "Serviço SSH não está rodando"
            return 1
        fi
    else
        # Linux: verificar serviço SSH
        if command_exists systemctl; then
            if systemctl is-active --quiet ssh; then
                success "Serviço SSH rodando"
                return 0
            else
                warn "Serviço SSH não está rodando"
                return 1
            fi
        elif command_exists service; then
            if service ssh status >/dev/null 2>&1; then
                success "Serviço SSH rodando"
                return 0
            else
                warn "Serviço SSH não está rodando"
                return 1
            fi
        else
            # Verificar processo diretamente
            if pgrep -f sshd >/dev/null; then
                success "Serviço SSH rodando"
                return 0
            else
                warn "Serviço SSH não está rodando"
                return 1
            fi
        fi
    fi
}

# --- Verificar projeto ---
check_project() {
    local project_dir
    project_dir=$(get_platform_config "$(detect_platform)" "project_dir")

    log "Verificando projeto Cluster AI..."

    if [ -d "$project_dir" ]; then
        success "Projeto encontrado"

        # Verificar se é um repositório Git válido
        if [ -d "$project_dir/.git" ]; then
            success "Repositório Git válido"
            return 0
        else
            warn "Diretório existe mas não é um repositório Git"
            return 1
        fi
    else
        error "Projeto não encontrado"
        return 1
    fi
}

# --- Verificar conectividade de rede ---
check_network() {
    log "Verificando conectividade de rede..."

    if ping -c 1 -W 5 8.8.8.8 >/dev/null 2>&1; then
        success "Conectividade com internet OK"
        return 0
    else
        warn "Sem conectividade com internet"
        return 1
    fi
}

# --- Verificar configuração de armazenamento ---
check_storage() {
    local platform
    platform=$(detect_platform)
    local storage_dir
    storage_dir=$(get_platform_config "$platform" "storage_dir")

    log "Verificando configuração de armazenamento..."

    if [ -d "$storage_dir" ]; then
        success "Armazenamento configurado"
        return 0
    else
        if is_android "$platform"; then
            warn "Armazenamento não configurado (execute: termux-setup-storage)"
        else
            warn "Armazenamento não configurado"
            log "Criando diretório de armazenamento..."
            mkdir -p "$storage_dir"
            success "Diretório de armazenamento criado"
        fi
        return 1
    fi
}

# --- Verificar chave SSH ---
check_ssh_key() {
    local ssh_key_path
    ssh_key_path=$(get_platform_config "$(detect_platform)" "ssh_key_path")

    log "Verificando chave SSH..."

    if [ -f "$ssh_key_path" ] && [ -f "$ssh_key_path.pub" ]; then
        success "Chave SSH encontrada"
        return 0
    else
        warn "Chave SSH não encontrada"
        return 1
    fi
}

# --- Teste de conectividade SSH local ---
test_ssh_local() {
    local user
    user=$(whoami)
    local port
    port=$(get_platform_config "$(detect_platform)" "ssh_port")

    log "Testando conectividade SSH local..."

    if timeout 5 ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=no -p "$port" "$user@localhost" "echo 'SSH OK'" 2>/dev/null; then
        success "SSH local funcionando"
        return 0
    else
        warn "SSH local não está respondendo"
        return 1
    fi
}

# --- Verificar configuração Dask ---
check_dask() {
    log "Verificando instalação do Dask..."

    if command -v python3 >/dev/null 2>&1; then
        if python3 -c "import dask; print('Dask version:', dask.__version__)" 2>/dev/null; then
            success "Dask instalado e funcionando"
            return 0
        fi
    elif command -v python >/dev/null 2>&1; then
        if python -c "import dask; print('Dask version:', dask.__version__)" 2>/dev/null; then
            success "Dask instalado e funcionando"
            return 0
        fi
    fi

    warn "Dask não está instalado ou não está funcionando"
    return 1
}

# --- Relatório final ---
generate_report() {
    local platform
    platform=$(detect_platform)

    echo
    echo "=================================================="
    echo "📊 RELATÓRIO DE TESTE - WORKER MULTI-PLATAFORMA"
    echo "=================================================="
    echo
    echo "📱 Informações do Sistema:"
    echo "   Plataforma: $(get_platform_info "$platform")"
    echo "   Usuário: $(whoami)"
    echo "   IP: $(ip route get 1 2>/dev/null | awk '{print $7}' | head -1 || echo 'N/A')"
    echo "   Porta SSH: $(get_platform_config "$platform" "ssh_port")"
    echo "   CPU Cores: $(nproc 2>/dev/null || echo 'N/A')"
    echo "   Memória: $(free -h 2>/dev/null | awk 'NR==2{print $2}' || echo 'N/A')"
    echo
    echo "🔑 Chave SSH (primeiros 50 caracteres):"
    local ssh_key_path
    ssh_key_path=$(get_platform_config "$platform" "ssh_key_path")
    if [ -f "$ssh_key_path.pub" ]; then
        echo "   $(head -c 50 "$ssh_key_path.pub")..."
    else
        echo "   Chave não encontrada"
    fi
    echo
    echo "💡 Recomendações:"
    if is_android "$platform"; then
        echo "• Mantenha bateria acima de 20%"
        echo "• Use Wi-Fi estável"
        echo "• Não feche o Termux em background"
    else
        echo "• Mantenha o sistema ligado"
        echo "• Use rede estável"
        echo "• Configure SSH para iniciar automaticamente"
    fi
    echo "• Para configuração: bash ~/Projetos/cluster-ai/scripts/workers/setup_worker_multiplatform.sh"
    echo
}

# --- Função principal ---
main() {
    local platform
    platform=$(detect_platform)

    echo
    echo "🧪 TESTE MULTI-PLATAFORMA - WORKER CLUSTER AI"
    echo "=================================================="
    echo "Plataforma detectada: $(get_platform_info "$platform")"
    echo

    local all_good=true

    # Executar verificações
    check_platform_specific || all_good=false
    check_dependencies || all_good=false
    check_ssh_service || all_good=false
    check_project || all_good=false
    check_network || all_good=false
    check_storage || all_good=false
    check_ssh_key || all_good=false
    test_ssh_local || all_good=false
    check_dask || all_good=false

    generate_report

    if $all_good; then
        echo
        success "🎉 TODOS OS TESTES PASSARAM!"
        echo "Seu worker $(get_platform_info "$platform") está pronto para uso."
        echo
        echo "Próximos passos:"
        echo "1. Copie a chave SSH mostrada acima"
        echo "2. Configure no servidor principal via ./manager.sh"
        echo "3. Teste a conexão SSH do servidor"
        echo
    else
        echo
        warn "⚠️  Alguns testes falharam."
        echo "Execute novamente a configuração:"
        echo "bash ~/Projetos/cluster-ai/scripts/workers/setup_worker_multiplatform.sh"
        echo
    fi
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
