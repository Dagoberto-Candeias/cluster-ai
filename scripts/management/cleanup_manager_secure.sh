#!/bin/bash
# =============================================================================
# Cluster AI - Secure Cleanup Manager
# =============================================================================
# Gerencia limpeza de arquivos antigos e backups com confirmações de segurança
#
# Autor: Cluster AI Team
# Data: 2025-01-27
# Version: 2.0.0
# =============================================================================

set -euo pipefail

# Carregar biblioteca comum (consolidada)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=../utils/common_functions.sh
source "${PROJECT_ROOT}/scripts/utils/common_functions.sh"

# Configurações padrão
KEEP_BACKUPS_DAYS=${KEEP_BACKUPS_DAYS:-30}
KEEP_LOGS_DAYS=${KEEP_LOGS_DAYS:-30}
KEEP_TEMP_FILES_HOURS=${KEEP_TEMP_FILES_HOURS:-24}

# Função para limpar backups antigos com confirmação
cleanup_backups() {
    log "Analisando backups antigos (> $KEEP_BACKUPS_DAYS dias)..."

    local backup_files
    backup_files=$(find "$PROJECT_ROOT" -name "*.backup_*" -type f -mtime +$KEEP_BACKUPS_DAYS 2>/dev/null)

    if [[ -z "$backup_files" ]]; then
        info "Nenhum backup antigo encontrado"
        return 0
    fi

    local count
    count=$(echo "$backup_files" | wc -l)

    warn "Encontrados $count backups antigos para remoção:"
    echo "$backup_files" | while read -r file; do
        echo "  - $file"
    done

    if confirm_critical_operation "Remover $count backups antigos?" "medium"; then
        echo "$backup_files" | while read -r file; do
            if [[ -f "$file" ]]; then
                audit_log 'BACKUP_CLEANUP' "Removendo backup antigo: $file"
                rm "$file"
                success "Removido: $file"
            fi
        done
        success "Limpeza de backups concluída"
    else
        info "Operação de limpeza de backups cancelada"
    fi
}

# Função para limpar logs antigos com confirmação
cleanup_logs() {
    log "Analisando logs antigos (> $KEEP_LOGS_DAYS dias)..."

    local log_files
    log_files=$(find "$PROJECT_ROOT/logs" -name "*.log" -type f -mtime +$KEEP_LOGS_DAYS 2>/dev/null)

    if [[ -z "$log_files" ]]; then
        info "Nenhum log antigo encontrado"
        return 0
    fi

    local count
    count=$(echo "$log_files" | wc -l)

    warn "Encontrados $count logs antigos para remoção:"
    echo "$log_files" | while read -r file; do
        echo "  - $file"
    done

    if confirm_critical_operation "Remover $count logs antigos?" "low"; then
        echo "$log_files" | while read -r file; do
            if [[ -f "$file" ]]; then
                audit_log 'LOG_CLEANUP' "Removendo log antigo: $file"
                rm "$file"
                success "Removido: $file"
            fi
        done
        success "Limpeza de logs concluída"
    else
        info "Operação de limpeza de logs cancelada"
    fi
}

# Função para limpar arquivos temporários
cleanup_temp_files() {
    log "Analisando arquivos temporários (> $KEEP_TEMP_FILES_HOURS horas)..."

    local temp_files
    temp_files=$(find "$PROJECT_ROOT" \( -name "*.tmp" -o -name "*.temp" -o -name ".DS_Store" -o -name "Thumbs.db" \) -type f -mmin +$((KEEP_TEMP_FILES_HOURS * 60)) 2>/dev/null)

    if [[ -z "$temp_files" ]]; then
        info "Nenhum arquivo temporário antigo encontrado"
        return 0
    fi

    local count
    count=$(echo "$temp_files" | wc -l)

    warn "Encontrados $count arquivos temporários para remoção:"
    echo "$temp_files" | while read -r file; do
        echo "  - $file"
    done

    if confirm_critical_operation "Remover $count arquivos temporários?" "low"; then
        echo "$temp_files" | while read -r file; do
            if [[ -f "$file" ]]; then
                audit_log 'TEMP_CLEANUP' "Removendo arquivo temporário: $file"
                rm "$file"
                success "Removido: $file"
            fi
        done
        success "Limpeza de arquivos temporários concluída"
    else
        info "Operação de limpeza de arquivos temporários cancelada"
    fi
}

# Função para limpar cache com confirmação
cleanup_cache() {
    log "Analisando diretórios de cache..."

    local cache_dirs=(
        "$PROJECT_ROOT/.pytest_cache"
        "$PROJECT_ROOT/__pycache__"
        "$PROJECT_ROOT/*/__pycache__"
        "$PROJECT_ROOT/.mypy_cache"
        "$PROJECT_ROOT/.tox"
        "$PROJECT_ROOT/htmlcov"
        "$PROJECT_ROOT/.coverage"
    )

    local found_caches=()
    for cache_dir in "${cache_dirs[@]}"; do
        if [[ -d "$cache_dir" ]]; then
            found_caches+=("$cache_dir")
        fi
    done

    if [[ ${#found_caches[@]} -eq 0 ]]; then
        info "Nenhum diretório de cache encontrado"
        return 0
    fi

    warn "Encontrados ${#found_caches[@]} diretórios de cache para remoção:"
    for cache_dir in "${found_caches[@]}"; do
        echo "  - $cache_dir"
    done

    if confirm_critical_operation "Remover ${#found_caches[@]} diretórios de cache?" "medium"; then
        for cache_dir in "${found_caches[@]}"; do
            if [[ -d "$cache_dir" ]]; then
                audit_log 'CACHE_CLEANUP' "Removendo cache: $cache_dir"
                rm -rf "$cache_dir"
                success "Removido: $cache_dir"
            fi
        done
        success "Limpeza de cache concluída"
    else
        info "Operação de limpeza de cache cancelada"
    fi
}

# Função para mostrar estatísticas
show_stats() {
    section "ESTATÍSTICAS DE LIMPEZA"

    echo "Backups antigos (> $KEEP_BACKUPS_DAYS dias): $(find "$PROJECT_ROOT" -name "*.backup_*" -type f -mtime +$KEEP_BACKUPS_DAYS 2>/dev/null | wc -l)"
    echo "Logs antigos (> $KEEP_LOGS_DAYS dias): $(find "$PROJECT_ROOT/logs" -name "*.log" -type f -mtime +$KEEP_LOGS_DAYS 2>/dev/null | wc -l)"
    echo "Arquivos temporários (> $KEEP_TEMP_FILES_HOURS horas): $(find "$PROJECT_ROOT" \( -name "*.tmp" -o -name "*.temp" \) -type f -mmin +$((KEEP_TEMP_FILES_HOURS * 60)) 2>/dev/null | wc -l)"
    echo "Diretórios de cache: $(find "$PROJECT_ROOT" -type d \( -name "__pycache__" -o -name ".pytest_cache" -o -name ".mypy_cache" \) 2>/dev/null | wc -l)"
    echo
    echo "Espaço total do projeto: $(du -sh "$PROJECT_ROOT" 2>/dev/null | cut -f1)"
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    local action="${1:-help}"

    case "$action" in
        "backups")
            cleanup_backups ;;
        "logs")
            cleanup_logs ;;
        "temp")
            cleanup_temp_files ;;
        "cache")
            cleanup_cache ;;
        "all")
            cleanup_backups
            cleanup_logs
            cleanup_temp_files
            cleanup_cache ;;
        "stats")
            show_stats ;;
        "help"|*)
            echo "Cluster AI - Secure Cleanup Manager"
            echo ""
            echo "Uso: $0 [ação]"
            echo ""
            echo "Ações:"
            echo "  backups  - Limpa backups antigos (com confirmação)"
            echo "  logs     - Limpa logs antigos (com confirmação)"
            echo "  temp     - Limpa arquivos temporários (com confirmação)"
            echo "  cache    - Limpa cache (com confirmação)"
            echo "  all      - Executa limpeza completa (com confirmações)"
            echo "  stats    - Mostra estatísticas"
            echo "  help     - Mostra esta ajuda"
            echo ""
            echo "Configurações (variáveis de ambiente):"
            echo "  KEEP_BACKUPS_DAYS     - Dias para manter backups (padrão: 30)"
            echo "  KEEP_LOGS_DAYS        - Dias para manter logs (padrão: 30)"
            echo "  KEEP_TEMP_FILES_HOURS - Horas para manter temporários (padrão: 24)"
            ;;
    esac
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
