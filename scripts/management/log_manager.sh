#!/bin/bash
# -*- coding: utf-8 -*-
#
# Cluster AI - Log Management Script
# Organiza e gerencia logs do sistema de forma inteligente
#
# Projeto: Cluster AI
# Autor: Sistema de consolidação automática
# Data: 2024-12-19
# Versão: 1.0.0
#
# Descrição:
#   Script responsável por organizar, limpar, comprimir e gerenciar logs
#   do sistema Cluster AI. Categoriza logs automaticamente, remove arquivos
#   antigos e comprime logs para otimizar espaço em disco.
#
# Uso:
#   ./scripts/management/log_manager.sh [comando] [argumentos]
#
# Dependências:
#   - bash
#   - find, ls, tail, du, wc, gzip
#   - mkdir, mv, rm
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
LOG_DIR="$PROJECT_ROOT/logs"

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

# Função para organizar logs automaticamente
organize_logs() {
    log_info "Organizando logs automaticamente..."

    # Criar estrutura de diretórios se não existir
    mkdir -p "$LOG_DIR"/{system,security,tests,applications,dask,monitoring,backups}

    # Mover logs para categorias apropriadas
    local moved_count=0

    # Logs de segurança
    for file in "$LOG_DIR"/*security*; do
        if [ -f "$file" ]; then
            mv "$file" "$LOG_DIR/security/" 2>/dev/null && ((moved_count++))
        fi
    done

    # Logs do Dask
    for file in "$LOG_DIR"/*dask*; do
        if [ -f "$file" ]; then
            mv "$file" "$LOG_DIR/dask/" 2>/dev/null && ((moved_count++))
        fi
    done

    # Logs de monitoramento
    for file in "$LOG_DIR"/*health* "$LOG_DIR"/*monitor*; do
        if [ -f "$file" ]; then
            mv "$file" "$LOG_DIR/monitoring/" 2>/dev/null && ((moved_count++))
        fi
    done

    # Logs de backup
    for file in "$LOG_DIR"/*backup*; do
        if [ -f "$file" ]; then
            mv "$file" "$LOG_DIR/backups/" 2>/dev/null && ((moved_count++))
        fi
    done

    # Logs de aplicações
    for file in "$LOG_DIR"/cluster* "$LOG_DIR"/web_server* "$LOG_DIR"/auto_init* "$LOG_DIR"/audit*; do
        if [ -f "$file" ]; then
            mv "$file" "$LOG_DIR/applications/" 2>/dev/null && ((moved_count++))
        fi
    done

    # Logs de sistema
    for file in "$LOG_DIR"/script* "$LOG_DIR"/validation* "$LOG_DIR"/integration* "$LOG_DIR"/comprehensive* "$LOG_DIR"/advanced_tools* "$LOG_DIR"/pre_install* "$LOG_DIR"/model_download* "$LOG_DIR"/ollama* "$LOG_DIR"/update*; do
        if [ -f "$file" ]; then
            mv "$file" "$LOG_DIR/system/" 2>/dev/null && ((moved_count++))
        fi
    done

    log_success "Organização concluída! $moved_count arquivos movidos."
}

# Função para limpar logs antigos
cleanup_old_logs() {
    local days=${1:-30}
    log_info "Limpando logs com mais de $days dias..."

    local deleted_count=0

    find "$LOG_DIR" -name "*.log" -type f -mtime +$days -delete 2>/dev/null && deleted_count=$?

    if [ $deleted_count -gt 0 ]; then
        log_success "Limpeza concluída! $deleted_count arquivos removidos."
    else
        log_info "Nenhum arquivo antigo encontrado para remoção."
    fi
}

# Função para comprimir logs antigos
compress_old_logs() {
    local days=${1:-7}
    log_info "Comprimindo logs com mais de $days dias..."

    local compressed_count=0

    find "$LOG_DIR" -name "*.log" -type f -mtime +$days -exec gzip {} \; 2>/dev/null && compressed_count=$?

    if [ $compressed_count -gt 0 ]; then
        log_success "Compressão concluída! $compressed_count arquivos comprimidos."
    else
        log_info "Nenhum arquivo encontrado para compressão."
    fi
}

# Função para mostrar estatísticas dos logs
show_log_stats() {
    log_info "Estatísticas dos logs:"

    echo "Diretório: $LOG_DIR"
    echo "Tamanho total: $(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)"

    echo -e "\nPor categoria:"
    for dir in "$LOG_DIR"/*/; do
        if [ -d "$dir" ]; then
            local dir_name=$(basename "$dir")
            local count=$(find "$dir" -name "*.log" -o -name "*.log.gz" | wc -l)
            local size=$(du -sh "$dir" 2>/dev/null | cut -f1)
            echo "  $dir_name: $count arquivos ($size)"
        fi
    done

    local total_files=$(find "$LOG_DIR" -name "*.log" -o -name "*.log.gz" | wc -l)
    echo -e "\nTotal de arquivos de log: $total_files"
}

# Função para mostrar logs recentes
show_recent_logs() {
    local lines=${1:-20}
    log_info "Mostrando $lines linhas dos logs mais recentes:"

    find "$LOG_DIR" -name "*.log" -type f -exec ls -t {} \; | head -5 | while read file; do
        echo -e "\n=== $(basename "$file") ==="
        tail -n $lines "$file" 2>/dev/null || echo "Erro ao ler $file"
    done
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    case "${1:-help}" in
        "organize")
            organize_logs
            ;;
        "cleanup")
            cleanup_old_logs "${2:-30}"
            ;;
        "compress")
            compress_old_logs "${2:-7}"
            ;;
        "stats")
            show_log_stats
            ;;
        "recent")
            show_recent_logs "${2:-20}"
            ;;
        "all")
            organize_logs
            compress_old_logs
            show_log_stats
            ;;
        "help"|*)
            echo "Cluster AI - Log Management Script"
            echo ""
            echo "Uso: $0 [comando] [argumentos]"
            echo ""
            echo "Comandos:"
            echo "  organize    - Organiza logs em categorias"
            echo "  cleanup     - Remove logs antigos (padrão: 30 dias)"
            echo "  compress    - Comprime logs antigos (padrão: 7 dias)"
            echo "  stats       - Mostra estatísticas dos logs"
            echo "  recent      - Mostra logs recentes (padrão: 20 linhas)"
            echo "  all         - Executa organização, compressão e estatísticas"
            echo "  help        - Mostra esta mensagem de ajuda"
            echo ""
            echo "Exemplos:"
            echo "  $0 organize"
            echo "  $0 cleanup 60"
            echo "  $0 compress 14"
            echo "  $0 stats"
            echo "  $0 recent 50"
            ;;
    esac
}

# Executar função principal
main "$@"
