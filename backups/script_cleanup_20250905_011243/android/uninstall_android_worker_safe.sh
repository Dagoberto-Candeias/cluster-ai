#!/bin/bash
# =============================================================================
# Script de desinstalação SEGURO do Worker Android para Cluster AI
# =============================================================================
# Execute este script no Termux para remover apenas os arquivos do projeto
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: uninstall_android_worker_safe.sh
# =============================================================================

#!/data/data/com.termux/files/usr/bin/bash
# Script de desinstalação SEGURO do Worker Android para Cluster AI
# Execute este script no Termux para remover apenas os arquivos do projeto
# PRESERVA configurações do sistema e outros arquivos do usuário

set -euo pipefail

RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
BLUE='\\033[0;34m'
NC='\\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        error "Este script deve ser executado no Termux!"
        exit 1
    fi
    success "Termux detectado"
}

remove_project() {
    local project_dir="$HOME/Projetos/cluster-ai"

    if [ -d "$project_dir" ]; then
        warn "Removendo diretório do projeto Cluster AI..."
        echo "Diretório: $project_dir"

        # Listar conteúdo antes de remover
        echo "Conteúdo a ser removido:"
        ls -la "$project_dir" | head -10

        # Confirmar remoção
        read -p "Confirmar remoção do diretório do projeto? (s/N): " confirm
        if [[ $confirm =~ ^[Ss]$ ]]; then
            rm -rf "$project_dir"
            success "Diretório do projeto removido."
        else
            warn "Remoção do projeto cancelada."
        fi
    else
        warn "Diretório do projeto não encontrado, nada a remover."
    fi
}

stop_ssh() {
    log "Verificando serviço SSH..."

    # Verificar se há processos SSH relacionados ao projeto
    if pgrep -f "sshd" >/dev/null; then
        warn "Serviço SSH está em execução."

        # Não parar SSH automaticamente para não interferir com outras conexões
        warn "ATENÇÃO: O serviço SSH foi preservado para não interromper outras conexões."
        warn "Se desejar parar o SSH manualmente, execute: pkill -f sshd"
    else
        log "Nenhum processo SSH em execução."
    fi
}

remove_project_ssh_keys() {
    # Remover apenas chaves específicas do projeto, NÃO o diretório .ssh inteiro
    local ssh_dir="$HOME/.ssh"
    local project_keys=(
        "$ssh_dir/id_rsa_cluster_ai"
        "$ssh_dir/id_rsa_cluster_ai.pub"
        "$ssh_dir/known_hosts_cluster_ai"
    )

    local removed=0
    for key in "${project_keys[@]}"; do
        if [ -f "$key" ]; then
            warn "Removendo chave específica do projeto: $(basename "$key")"
            rm -f "$key"
            ((removed++))
        fi
    done

    if [ $removed -gt 0 ]; then
        success "$removed chaves específicas do projeto removidas."
    else
        warn "Nenhuma chave específica do projeto encontrada."
    fi

    # IMPORTANTE: Não remover todo o diretório .ssh
    warn "✅ PRESERVADO: Diretório ~/.ssh mantido intacto para não corromper outras configurações SSH."
}

clean_temp_files() {
    log "Limpando arquivos temporários do projeto..."

    # Remover arquivos temporários relacionados ao projeto
    local temp_patterns=(
        "/tmp/cluster-ai-*"
        "$HOME/.cache/cluster-ai"
        "$HOME/.local/share/cluster-ai"
    )

    local cleaned=0
    for pattern in "${temp_patterns[@]}"; do
        if [ -e "$pattern" ]; then
            rm -rf "$pattern" 2>/dev/null && ((cleaned++))
        fi
    done

    if [ $cleaned -gt 0 ]; then
        success "$cleaned arquivos temporários removidos."
    else
        log "Nenhum arquivo temporário encontrado."
    fi
}

show_preservation_notice() {
    echo
    echo "🛡️  ARQUIVOS PRESERVADOS (por segurança do sistema):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ ~/.ssh/                    - Chaves SSH pessoais do usuário"
    echo "✅ ~/.bashrc                  - Configurações do shell"
    echo "✅ ~/.profile                 - Perfil do usuário"
    echo "✅ /data/data/com.termux/*    - Arquivos do sistema Termux"
    echo "✅ Pacotes instalados         - Dependências do sistema"
    echo
    echo "💡 Para remover completamente:"
    echo "   • Chaves SSH: rm -f ~/.ssh/id_rsa* (com cuidado!)"
    echo "   • Termux: Desinstalar o app normalmente"
    echo
}

main() {
    echo
    echo "🗑️  DESINSTALAÇÃO SEGURA - Worker Android Cluster AI"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    warn "Este script remove APENAS arquivos do projeto."
    warn "Configurações do sistema e arquivos pessoais são PRESERVADOS."
    echo

    check_termux
    remove_project
    stop_ssh
    remove_project_ssh_keys
    clean_temp_files

    echo
    success "✅ Desinstalação segura concluída!"
    echo
    show_preservation_notice
}

main
