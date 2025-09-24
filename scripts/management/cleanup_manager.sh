#!/bin/bash
# -*- coding: utf-8 -*-
#
# Cluster AI - Cleanup Manager
# Gerencia limpeza de arquivos antigos e backups
#
# Projeto: Cluster AI
# Autor: Sistema de consolidação automática
# Data: 2024-12-19
# Versão: 1.0.0
#
# Descrição:
#   Script responsável por gerenciar a limpeza de arquivos antigos, backups,
#   logs e cache do projeto Cluster AI. Mantém o projeto organizado e
#   otimizado removendo arquivos desnecessários de forma segura.
#
# Uso:
#   ./scripts/management/cleanup_manager.sh [comando]
#
# Dependências:
#   - bash
#   - find, du, wc, rm
#   - log_manager.sh (opcional)
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
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Configurações padrão
KEEP_BACKUPS_DAYS=${KEEP_BACKUPS_DAYS:-30}
KEEP_LOGS_DAYS=${KEEP_LOGS_DAYS:-30}
KEEP_TEMP_FILES_HOURS=${KEEP_TEMP_FILES_HOURS:-24}

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

# Função para limpar backups antigos
cleanup_backups() {
    log_info "Limpando backups antigos (manter últimos $KEEP_BACKUPS_DAYS dias)..."

    local backup_count=0
    local removed_count=0

    # Encontrar todos os arquivos de backup
    find "$PROJECT_ROOT" -name "*.backup_*" -type f -mtime +$KEEP_BACKUPS_DAYS 2>/dev/null | while read -r backup_file; do
        if [ -f "$backup_file" ]; then
            log_info "Removendo backup antigo: $backup_file"
            rm "$backup_file"
            ((removed_count++))
        fi
    done

    log_success "Limpeza de backups concluída! $removed_count backups removidos."
}

# Função para limpar logs antigos
cleanup_logs() {
    log_info "Limpando logs antigos (manter últimos $KEEP_LOGS_DAYS dias)..."

    local removed_count=0

    # Usar o log_manager.sh se disponível
    if [ -f "$PROJECT_ROOT/scripts/management/log_manager.sh" ]; then
        log_info "Usando log_manager.sh para limpeza de logs..."
        "$PROJECT_ROOT/scripts/management/log_manager.sh" cleanup $KEEP_LOGS_DAYS
    else
        # Limpeza manual
        find "$PROJECT_ROOT/logs" -name "*.log" -type f -mtime +$KEEP_LOGS_DAYS 2>/dev/null | while read -r log_file; do
            if [ -f "$log_file" ]; then
                log_info "Removendo log antigo: $log_file"
                rm "$log_file"
                ((removed_count++))
            fi
        done
        log_success "Limpeza manual de logs concluída! $removed_count logs removidos."
    fi
}

# Função para limpar arquivos temporários
cleanup_temp_files() {
    log_info "Limpando arquivos temporários (manter últimas $KEEP_TEMP_FILES_HOURS horas)..."

    local removed_count=0

    # Encontrar arquivos temporários comuns
    find "$PROJECT_ROOT" -name "*.tmp" -o -name "*.temp" -o -name ".DS_Store" -o -name "Thumbs.db" | while read -r temp_file; do
        if [ -f "$temp_file" ]; then
            # Verificar se é realmente antigo
            if [ $(find "$temp_file" -mmin +$((KEEP_TEMP_FILES_HOURS * 60)) 2>/dev/null | wc -l) -gt 0 ]; then
                log_info "Removendo arquivo temporário: $temp_file"
                rm "$temp_file"
                ((removed_count++))
            fi
        fi
    done

    log_success "Limpeza de arquivos temporários concluída! $removed_count arquivos removidos."
}

# Função para limpar cache
cleanup_cache() {
    log_info "Limpando diretórios de cache..."

    local removed_count=0

    # Diretórios de cache comuns
    local cache_dirs=(
        "$PROJECT_ROOT/.pytest_cache"
        "$PROJECT_ROOT/__pycache__"
        "$PROJECT_ROOT/*/__pycache__"
        "$PROJECT_ROOT/.mypy_cache"
        "$PROJECT_ROOT/.tox"
        "$PROJECT_ROOT/htmlcov"
        "$PROJECT_ROOT/.coverage"
    )

    for cache_dir in "${cache_dirs[@]}"; do
        if [ -d "$cache_dir" ]; then
            log_info "Removendo cache: $cache_dir"
            rm -rf "$cache_dir"
            ((removed_count++))
        fi
    done

    log_success "Limpeza de cache concluída! $removed_count diretórios removidos."
}

# Função para mostrar estatísticas antes da limpeza
show_cleanup_stats() {
    log_info "Estatísticas antes da limpeza:"

    echo "Backups antigos (> $KEEP_BACKUPS_DAYS dias): $(find "$PROJECT_ROOT" -name "*.backup_*" -type f -mtime +$KEEP_BACKUPS_DAYS 2>/dev/null | wc -l)"
    echo "Logs antigos (> $KEEP_LOGS_DAYS dias): $(find "$PROJECT_ROOT/logs" -name "*.log" -type f -mtime +$KEEP_LOGS_DAYS 2>/dev/null | wc -l)"
    echo "Arquivos temporários (> $KEEP_TEMP_FILES_HOURS horas): $(find "$PROJECT_ROOT" -name "*.tmp" -o -name "*.temp" | wc -l)"
    echo "Diretórios de cache: $(find "$PROJECT_ROOT" -type d \( -name "__pycache__" -o -name ".pytest_cache" -o -name ".mypy_cache" \) | wc -l)"
}

# Função para mostrar estatísticas após a limpeza
show_final_stats() {
    log_info "Estatísticas após a limpeza:"

    local total_size_before=$(du -sb "$PROJECT_ROOT" 2>/dev/null | cut -f1)
    echo "Tamanho total do projeto: $(du -sh "$PROJECT_ROOT" 2>/dev/null | cut -f1)"
    echo "Arquivos de backup restantes: $(find "$PROJECT_ROOT" -name "*.backup_*" -type f | wc -l)"
    echo "Logs restantes: $(find "$PROJECT_ROOT/logs" -name "*.log" -type f 2>/dev/null | wc -l)"
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    case "${1:-help}" in
        "backups")
            show_cleanup_stats
            cleanup_backups
            ;;
        "logs")
            cleanup_logs
            ;;
        "temp")
            cleanup_temp_files
            ;;
        "cache")
            cleanup_cache
            ;;
        "all")
            show_cleanup_stats
            cleanup_backups
            cleanup_logs
            cleanup_temp_files
            cleanup_cache
            show_final_stats
            ;;
        "stats")
            show_cleanup_stats
            ;;
        "help"|*)
            echo "Cluster AI - Cleanup Manager"
            echo ""
            echo "Uso: $0 [comando]"
            echo ""
            echo "Comandos:"
            echo "  backups     - Limpa backups antigos"
            echo "  logs        - Limpa logs antigos"
            echo "  temp        - Limpa arquivos temporários"
            echo "  cache       - Limpa diretórios de cache"
            echo "  all         - Executa limpeza completa"
            echo "  stats       - Mostra estatísticas de limpeza"
            echo "  help        - Mostra esta mensagem de ajuda"
            echo ""
            echo "Configurações (definir como variáveis de ambiente):"
            echo "  KEEP_BACKUPS_DAYS       - Dias para manter backups (padrão: 30)"
            echo "  KEEP_LOGS_DAYS          - Dias para manter logs (padrão: 30)"
            echo "  KEEP_TEMP_FILES_HOURS   - Horas para manter arquivos temporários (padrão: 24)"
            echo ""
            echo "Exemplo:"
            echo "  $0 all"
            ;;
    esac
}

# Executar função principal
main "$@"
