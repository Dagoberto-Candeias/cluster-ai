#!/bin/bash
# Script para limpar backups antigos do Cluster AI

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuração
BACKUP_DIR="$HOME/cluster_backups"
DEFAULT_DAYS_TO_KEEP=30

# Função para limpar backups antigos
clean_old_backups() {
    local days_to_keep=${1:-$DEFAULT_DAYS_TO_KEEP}
    
    if [ ! -d "$BACKUP_DIR" ]; then
        warn "Diretório de backups não encontrado: $BACKUP_DIR"
        return 0
    fi
    
    log "Limpando backups com mais de $days_to_keep dias em $BACKUP_DIR..."
    
    local deleted_count=0
    local total_size=0
    local backup_files=($(find "$BACKUP_DIR" -name "*.tar.gz" -mtime "+$days_to_keep"))
    
    if [ ${#backup_files[@]} -eq 0 ]; then
        log "Nenhum backup antigo encontrado"
        return 0
    fi
    
    echo -e "${YELLOW}Backups a serem removidos:${NC}"
    for backup_file in "${backup_files[@]}"; do
        local file_size=$(du -h "$backup_file" | cut -f1)
        echo "  - $(basename "$backup_file") ($file_size) - $(date -r "$backup_file" '+%Y-%m-%d %H:%M:%S')"
        total_size=$((total_size + $(du -k "$backup_file" | cut -f1)))
    done
    
    echo ""
    read -p "Confirmar remoção de ${#backup_files[@]} backup(s)? (s/N): " confirm
    
    if [[ "$confirm" =~ ^[Ss]$ ]]; then
        for backup_file in "${backup_files[@]}"; do
            if rm -f "$backup_file"; then
                ((deleted_count++))
                log "Removido: $(basename "$backup_file")"
            else
                error "Falha ao remover: $(basename "$backup_file")"
            fi
        done
        
        local total_size_mb=$(echo "scale=2; $total_size / 1024" | bc)
        success "$deleted_count backup(s) removido(s), liberando ${total_size_mb}MB"
        return 0
    else
        warn "Operação cancelada pelo usuário"
        return 0
    fi
}

# Função para mostrar estatísticas
show_stats() {
    if [ ! -d "$BACKUP_DIR" ]; then
        warn "Diretório de backups não encontrado"
        return 1
    fi
    
    local total_files=$(find "$BACKUP_DIR" -name "*.tar.gz" | wc -l)
    local total_size=$(du -sh "$BACKUP_DIR" | cut -f1)
    local oldest_file=$(find "$BACKUP_DIR" -name "*.tar.gz" -printf '%T@ %p\n' | sort -n | head -1 | cut -d' ' -f2-)
    local newest_file=$(find "$BACKUP_DIR" -name "*.tar.gz" -printf '%T@ %p\n' | sort -nr | head -1 | cut -d' ' -f2-)
    
    echo -e "${BLUE}=== ESTATÍSTICAS DE BACKUP ===${NC}"
    echo "Diretório: $BACKUP_DIR"
    echo "Total de backups: $total_files"
    echo "Espaço utilizado: $total_size"
    
    if [ -n "$oldest_file" ]; then
        echo "Backup mais antigo: $(basename "$oldest_file") ($(date -r "$oldest_file" '+%Y-%m-%d %H:%M:%S'))"
    fi
    
    if [ -n "$newest_file" ]; then
        echo "Backup mais recente: $(basename "$newest_file") ($(date -r "$newest_file" '+%Y-%m-%d %H:%M:%S'))"
    fi
    
    # Mostrar backups por idade
    echo ""
    echo -e "${YELLOW}Distribuição por idade:${NC}"
    echo "  - Menos de 7 dias: $(find "$BACKUP_DIR" -name "*.tar.gz" -mtime -7 | wc -l)"
    echo "  - 7-30 dias: $(find "$BACKUP_DIR" -name "*.tar.gz" -mtime +6 -mtime -30 | wc -l)"
    echo "  - Mais de 30 dias: $(find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 | wc -l)"
}

# Mostrar ajuda
show_help() {
    echo -e "${BLUE}=== AJUDA - CLEANUP BACKUPS ===${NC}"
    echo ""
    echo "Uso: $0 [OPÇÃO] [DIAS]"
    echo ""
    echo "Opções:"
    echo "  clean [DIAS]    Limpar backups com mais de DIAS (padrão: 30)"
    echo "  stats           Mostrar estatísticas dos backups"
    echo "  help            Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 clean        # Limpar backups com mais de 30 dias"
    echo "  $0 clean 15     # Limpar backups com mais de 15 dias"
    echo "  $0 stats        # Mostrar estatísticas"
    echo ""
    exit 0
}

# Função principal
main() {
    case "$1" in
        "clean")
            local days=${2:-$DEFAULT_DAYS_TO_KEEP}
            clean_old_backups "$days"
            ;;
        "stats")
            show_stats
            ;;
        "help"|"")
            show_help
            ;;
        *)
            error "Opção inválida: $1"
            show_help
            return 1
            ;;
    esac
}

# Executar função principal
main "$@"

# Salvar resultado
exit $?
