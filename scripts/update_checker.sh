#!/bin/bash
# -*- coding: utf-8 -*-
#
# Cluster AI - Update Checker Script
# Verificador de atualizações do Cluster AI
#
# Projeto: Cluster AI
# Autor: Sistema de consolidação automática
# Data: 2024-12-19
# Versão: 1.0.0
#
# Descrição:
#   Script para verificar e gerenciar atualizações do Cluster AI.
#   Verifica repositório remoto, compara versões, baixa atualizações
#   e aplica patches de forma segura com backup automático.
#
# Uso:
#   ./scripts/update_checker.sh [opções]
#
# Dependências:
#   - bash
#   - git
#   - curl, wget
#   - diff, patch
#
# Changelog:
#   v1.0.0 - 2024-12-19: Criação inicial com funcionalidades completas
#
# ============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório base
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
UPDATE_LOG="$LOG_DIR/update_checker.log"

# Configurações
REMOTE_REPO="https://github.com/Dagoberto-Candeias/cluster-ai.git"
BRANCH="main"
BACKUP_DIR="$PROJECT_ROOT/backups/pre_update_$(date +%Y%m%d_%H%M%S)"
UPDATE_TEMP_DIR="/tmp/cluster_ai_update"

# Arrays para controle
UPDATED_FILES=()
FAILED_UPDATES=()

# Funções utilitárias
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar dependências
check_dependencies() {
    log_info "Verificando dependências de atualização..."

    local missing_deps=()
    local required_commands=(
        "git"
        "curl"
        "wget"
        "diff"
        "patch"
    )

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Dependências faltando: ${missing_deps[*]}"
        log_info "Instale as dependências necessárias e tente novamente"
        return 1
    fi

    log_success "Dependências verificadas"
    return 0
}

# Função para verificar se é um repositório git
check_git_repository() {
    log_info "Verificando repositório git..."

    if [ ! -d ".git" ]; then
        log_error "Diretório não é um repositório git"
        log_info "Execute: git init && git remote add origin $REMOTE_REPO"
        return 1
    fi

    if ! git remote -v | grep -q origin; then
        log_error "Remote origin não configurado"
        log_info "Execute: git remote add origin $REMOTE_REPO"
        return 1
    fi

    log_success "Repositório git válido"
    return 0
}

# Função para buscar atualizações
fetch_updates() {
    log_info "Buscando atualizações do repositório..."

    # Buscar do remote
    if git fetch origin >> "$UPDATE_LOG" 2>&1; then
        log_success "Atualizações buscadas com sucesso"
        return 0
    else
        log_error "Falha ao buscar atualizações"
        return 1
    fi
}

# Função para comparar versões
compare_versions() {
    log_info "Comparando versões..."

    local local_commit=$(git rev-parse HEAD)
    local remote_commit=$(git rev-parse origin/$BRANCH)
    local base_commit=$(git merge-base HEAD origin/$BRANCH)

    log_info "Commit local: $local_commit"
    log_info "Commit remoto: $remote_commit"
    log_info "Commit base: $base_commit"

    if [ "$local_commit" = "$remote_commit" ]; then
        log_success "Sistema já está atualizado"
        return 0
    elif [ "$base_commit" = "$remote_commit" ]; then
        log_warning "Branch local está à frente do remote"
        return 1
    else
        log_info "Atualizações disponíveis"
        return 2
    fi
}

# Função para criar backup
create_backup() {
    log_info "Criando backup antes da atualização..."

    mkdir -p "$BACKUP_DIR"

    # Backup de arquivos importantes
    local important_files=(
        "cluster.conf"
        "config/"
        "models/"
        "data/"
        "logs/"
    )

    for item in "${important_files[@]}"; do
        if [ -e "$item" ]; then
            cp -r "$item" "$BACKUP_DIR/" >> "$UPDATE_LOG" 2>&1
        fi
    done

    # Backup do estado git
    git add . >> "$UPDATE_LOG" 2>&1
    git commit -m "Backup antes da atualização $(date)" >> "$UPDATE_LOG" 2>&1 || true

    log_success "Backup criado: $BACKUP_DIR"
}

# Função para aplicar atualizações
apply_updates() {
    log_info "Aplicando atualizações..."

    # Criar diretório temporário
    mkdir -p "$UPDATE_TEMP_DIR"
    cd "$UPDATE_TEMP_DIR"

    # Clonar repositório temporário
    if git clone -b "$BRANCH" "$REMOTE_REPO" temp_repo >> "$UPDATE_LOG" 2>&1; then
        cd temp_repo

        # Encontrar arquivos modificados
        local changed_files=$(git diff --name-only HEAD..origin/$BRANCH)

        if [ -z "$changed_files" ]; then
            log_info "Nenhum arquivo modificado"
            return 0
        fi

        # Aplicar cada arquivo modificado
        while IFS= read -r file; do
            if [ -f "$file" ]; then
                cp "$file" "$PROJECT_ROOT/$file" >> "$UPDATE_LOG" 2>&1
                UPDATED_FILES+=("$file")
                log_success "Atualizado: $file"
            fi
        done <<< "$changed_files"

        log_success "Atualizações aplicadas"
        return 0
    else
        log_error "Falha ao clonar repositório temporário"
        return 1
    fi
}

# Função para validar atualizações
validate_updates() {
    log_info "Validando atualizações..."

    local validation_issues=()

    # Verificar se scripts ainda são executáveis
    for file in "${UPDATED_FILES[@]}"; do
        if [[ "$file" == *.sh ]] && [ -f "$PROJECT_ROOT/$file" ]; then
            if [ ! -x "$PROJECT_ROOT/$file" ]; then
                chmod +x "$PROJECT_ROOT/$file"
            fi
        fi
    done

    # Verificar sintaxe de scripts Python
    for file in "${UPDATED_FILES[@]}"; do
        if [[ "$file" == *.py ]] && [ -f "$PROJECT_ROOT/$file" ]; then
            if ! python3 -m py_compile "$PROJECT_ROOT/$file" >> "$UPDATE_LOG" 2>&1; then
                validation_issues+=("Erro de sintaxe em $file")
            fi
        fi
    done

    if [ ${#validation_issues[@]} -gt 0 ]; then
        log_warning "Problemas de validação detectados:"
        printf '  - %s\n' "${validation_issues[@]}"
        return 1
    fi

    log_success "Atualizações validadas"
    return 0
}

# Função para mostrar status final
show_final_status() {
    log_info "=== STATUS FINAL DAS ATUALIZAÇÕES ==="

    echo "✅ Arquivos Atualizados:"
    if [ ${#UPDATED_FILES[@]} -gt 0 ]; then
        printf '  - %s\n' "${UPDATED_FILES[@]}"
    else
        echo "  Nenhum"
    fi

    echo "❌ Atualizações com Falha:"
    if [ ${#FAILED_UPDATES[@]} -gt 0 ]; then
        printf '  - %s\n' "${FAILED_UPDATES[@]}"
    else
        echo "  Nenhum"
    fi

    echo "📁 Diretórios:"
    echo "  - Backup: $BACKUP_DIR"
    echo "  - Logs: $UPDATE_LOG"

    echo "🚀 Próximos Passos:"
    echo "  1. Verifique os arquivos atualizados"
    echo "  2. Execute: ./scripts/start_cluster_complete.sh restart"
    echo "  3. Teste as funcionalidades atualizadas"
    echo "  4. Em caso de problemas, restaure: $BACKUP_DIR"
}

# Função para reverter atualizações
revert_updates() {
    log_info "Revertendo atualizações..."

    if [ -d "$BACKUP_DIR" ]; then
        cp -r "$BACKUP_DIR/"* "$PROJECT_ROOT/" >> "$UPDATE_LOG" 2>&1
        log_success "Atualizações revertidas"
    else
        log_error "Backup não encontrado para reverter"
        return 1
    fi
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    # Criar diretório de logs
    mkdir -p "$LOG_DIR"
    touch "$UPDATE_LOG"

    local action="${1:-check}"

    case "$action" in
        "check")
            log_info "🔍 Verificando atualizações disponíveis..."

            check_dependencies || exit 1
            check_git_repository || exit 1
            fetch_updates || exit 1

            local status
            status=$(compare_versions)

            case $status in
                0)
                    log_success "Sistema já está atualizado"
                    ;;
                1)
                    log_warning "Branch local está à frente - considere fazer push"
                    ;;
                2)
                    log_info "Atualizações disponíveis"
                    log_info "Execute: ./scripts/update_checker.sh update"
                    ;;
            esac
            ;;
        "update")
            log_info "🚀 Aplicando atualizações..."

            check_dependencies || exit 1
            check_git_repository || exit 1
            create_backup
            apply_updates || exit 1
            validate_updates || log_warning "Problemas de validação detectados"

            show_final_status
            ;;
        "revert")
            log_info "🔄 Revertendo atualizações..."
            revert_updates
            ;;
        "force-update")
            log_info "⚠️  Forçando atualização (sem backup)..."
            check_dependencies || exit 1
            check_git_repository || exit 1
            apply_updates || exit 1
            validate_updates || exit 1
            show_final_status
            ;;
        "help"|*)
            echo "Cluster AI - Update Checker Script"
            echo ""
            echo "Uso: $0 [ação]"
            echo ""
            echo "Ações:"
            echo "  check         - Verifica atualizações disponíveis (padrão)"
            echo "  update        - Aplica atualizações com backup"
            echo "  force-update  - Aplica atualizações sem backup"
            echo "  revert        - Reverte para backup anterior"
            echo "  help          - Mostra esta mensagem"
            echo ""
            echo "Pré-requisitos:"
            echo "  - Repositório git inicializado"
            echo "  - Remote origin configurado"
            echo "  - Conectividade com o repositório remoto"
            echo ""
            echo "Exemplos:"
            echo "  $0 check"
            echo "  $0 update"
            echo "  $0 revert"
            ;;
    esac
}

# Executar função principal
main "$@"
