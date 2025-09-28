#!/bin/bash
# =============================================================================
# Script de teste para verificar se o worker Android está funcionando
# =============================================================================
# Script de teste para verificar se o worker Android está funcionando
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: test_android_worker.sh
# =============================================================================

#!/data/data/com.termux/files/usr/bin/bash
# Script de teste para verificar se o worker Android está funcionando

set -euo pipefail

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

# --- Verificações ---
check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        error "Este script deve ser executado no Termux!"
        return 1
    fi
    success "Ambiente Termux OK"
    return 0
}

check_dependencies() {
    local missing_deps=()

    log "Verificando dependências..."

    # Verificar Python
    if ! command -v python >/dev/null 2>&1; then
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

    if [ ${#missing_deps[@]} -gt 0 ]; then
        warn "Dependências faltando: ${missing_deps[*]}"
        return 1
    fi

    return 0
}

check_ssh_service() {
    log "Verificando serviço SSH..."

    if pgrep -f sshd >/dev/null; then
        success "Serviço SSH rodando"
        return 0
    else
        warn "Serviço SSH não está rodando"
        return 1
    fi
}

check_project() {
    log "Verificando projeto Cluster AI..."

    if [ -d "$HOME/Projetos/cluster-ai" ]; then
        success "Projeto encontrado"

        # Verificar se é um repositório Git válido
        if [ -d "$HOME/Projetos/cluster-ai/.git" ]; then
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

check_network() {
    log "Verificando conectividade de rede..."

    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        success "Conectividade com internet OK"
        return 0
    else
        warn "Sem conectividade com internet"
        return 1
    fi
}

check_storage() {
    log "Verificando configuração de armazenamento..."

    if [ -d "$HOME/storage" ]; then
        success "Armazenamento configurado"
        return 0
    else
        warn "Armazenamento não configurado"
        return 1
    fi
}

# --- Relatório final ---
generate_report() {
    echo
    echo "=================================================="
    echo "📊 RELATÓRIO DE TESTE - WORKER ANDROID"
    echo "=================================================="
    echo
    echo "📱 Informações do Sistema:"
    echo "   Usuário: $(whoami)"
    echo "   IP: $(ip route get 1 2>/dev/null | awk '{print $7}' | head -1 || echo 'N/A')"
    echo "   Porta SSH: 8022"
    echo "   Bateria: $(termux-battery-status 2>/dev/null | grep percentage | cut -d: -f2 | tr -d ' ,' || echo 'N/A')"
    echo
    echo "🔑 Chave SSH (se existir):"
    if [ -f "$HOME/.ssh/id_rsa.pub" ]; then
        echo "   $(head -c 50 $HOME/.ssh/id_rsa.pub)..."
    else
        echo "   Chave não encontrada"
    fi
    echo
    echo "💡 Recomendações:"
    echo "• Mantenha bateria acima de 20%"
    echo "• Use Wi-Fi estável"
    echo "• Não feche o Termux em background"
    echo
}

# --- Função principal ---
main() {
    echo
    echo "🧪 TESTE DE INSTALAÇÃO - WORKER ANDROID"
    echo "======================================"
    echo

    local all_good=true

    # Executar verificações
    check_termux || all_good=false
    check_dependencies || all_good=false
    check_ssh_service || all_good=false
    check_project || all_good=false
    check_network || all_good=false
    check_storage || all_good=false

    generate_report

    if $all_good; then
        echo
        success "🎉 TODOS OS TESTES PASSARAM!"
        echo "Seu worker Android está pronto para uso."
        echo
        echo "Próximos passos:"
        echo "1. Copie a chave SSH mostrada acima"
        echo "2. Configure no servidor principal via ./manager.sh"
        echo "3. Teste a conexão SSH"
        echo
    else
        echo
        warn "⚠️  Alguns testes falharam."
        echo "Execute novamente a configuração:"
        echo "bash ~/Projetos/cluster-ai/scripts/android/setup_android_worker_simple.sh"
        echo
    fi
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
