#!/bin/bash
# Script de gerenciamento de backup do Cluster AI

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

fail() {
    echo -e "${RED}❌ $1${NC}"
}

# Configuração
BACKUP_DIR="$HOME/cluster_backups"
DEFAULT_BACKUP_ITEMS=(
    "$HOME/.cluster_role"
    "$HOME/cluster_scripts"
    "$HOME/.ollama"
    "$HOME/.cluster_optimization"
    "$HOME/open-webui"
    "/etc/docker/daemon.json"
    "/etc/systemd/system/ollama.service"
)

# Função para criar diretório de backups
create_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        log "Diretório de backups criado: $BACKUP_DIR"
    fi
}

# Função para verificar itens existentes
get_existing_items() {
    local items=("$@")
    local existing_items=()
    
    for item in "${items[@]}"; do
        if [ -e "$item" ]; then
            existing_items+=("$item")
        fi
    done
    
    echo "${existing_items[@]}"
}

# Backup completo
backup_complete() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/cluster_backup_${timestamp}.tar.gz"
    
    log "Iniciando backup completo..."
    
    # Obter itens existentes
    local existing_items=($(get_existing_items "${DEFAULT_BACKUP_ITEMS[@]}"))
    
    if [ ${#existing_items[@]} -eq 0 ]; then
        error "Nenhum item encontrado para backup."
        return 1
    fi
    
    # Criar backup
    tar -czf "$backup_file" "${existing_items[@]}"
    
    if [ $? -eq 0 ]; then
        success "Backup completo criado com sucesso: $backup_file"
        log "Tamanho do backup: $(du -h "$backup_file" | cut -f1)"
        return 0
    else
        error "Falha ao criar backup."
        return 1
    fi
}

# Backup dos modelos Ollama
backup_ollama_models() {
    if [ ! -d "$HOME/.ollama" ]; then
        error "Diretório .ollama não encontrado."
        return 1
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/ollama_models_${timestamp}.tar.gz"
    
    log "Fazendo backup dos modelos Ollama..."
    
    tar -czf "$backup_file" -C "$HOME" .ollama
    
    if [ $? -eq 0 ]; then
        success "Backup dos modelos Ollama criado com sucesso: $backup_file"
        log "Tamanho do backup: $(du -h "$backup_file" | cut -f1)"
        return 0
    else
        error "Falha ao criar backup dos modelos Ollama."
        return 1
    fi
}

# Backup das configurações
backup_configurations() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/cluster_config_${timestamp}.tar.gz"
    
    log "Fazendo backup das configurações..."
    
    # Itens de configuração para backup
    local config_items=(
        "$HOME/.cluster_role"
        "/etc/docker/daemon.json"
        "/etc/systemd/system/ollama.service"
        "$HOME/cluster_scripts"
    )
    
    local existing_items=($(get_existing_items "${config_items[@]}"))
    
    if [ ${#existing_items[@]} -eq 0 ]; then
        error "Nenhum item de configuração encontrado para backup."
        return 1
    fi
    
    # Criar backup
    tar -czf "$backup_file" "${existing_items[@]}"
    
    if [ $? -eq 0 ]; then
        success "Backup das configurações criado com sucesso: $backup_file"
        log "Tamanho do backup: $(du -h "$backup_file" | cut -f1)"
        return 0
    else
        error "Falha ao criar backup das configurações."
        return 1
    fi
}

# Backup dos dados do OpenWebUI
backup_openwebui_data() {
    if [ ! -d "$HOME/open-webui" ]; then
        error "Diretório open-webui não encontrado."
        return 1
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/openwebui_data_${timestamp}.tar.gz"
    
    log "Fazendo backup dos dados do OpenWebUI..."
    
    tar -czf "$backup_file" -C "$HOME" open-webui
    
    if [ $? -eq 0 ]; then
        success "Backup dos dados do OpenWebUI criado com sucesso: $backup_file"
        log "Tamanho do backup: $(du -h "$backup_file" | cut -f1)"
        return 0
    else
        error "Falha ao criar backup dos dados do OpenWebUI."
        return 1
    fi
}

# Função para restaurar backup
restore_backup() {
    create_backup_dir
    
    # Listar backups disponíveis
    local backup_files=($(ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null))
    
    if [ ${#backup_files[@]} -eq 0 ]; then
        error "Nenhum arquivo de backup encontrado em $BACKUP_DIR"
        return 1
    fi
    
    echo -e "\n${BLUE}=== BACKUPS DISPONÍVEIS ===${NC}"
    local i=1
    for backup_file in "${backup_files[@]}"; do
        echo "$i. $(basename "$backup_file") ($(du -h "$backup_file" | cut -f1))"
        ((i++))
    done
    
    read -p "Selecione o backup para restaurar [1-${#backup_files[@]}]: " backup_choice
    
    if ! [[ "$backup_choice" =~ ^[0-9]+$ ]] || [ "$backup_choice" -lt 1 ] || [ "$backup_choice" -gt ${#backup_files[@]} ]; then
        error "Seleção inválida."
        return 1
    fi
    
    local selected_backup="${backup_files[$((backup_choice-1))]}"
    
    log "Restaurando backup: $selected_backup"
    
    # Extrair backup
    tar -xzf "$selected_backup" -C "$HOME"
    
    if [ $? -eq 0 ]; then
        success "Backup restaurado com sucesso!"
        
        # Verificar se é necessário reiniciar serviços
        if [[ "$selected_backup" == *config* ]] || [[ "$selected_backup" == *complete* ]]; then
            warn "Backup de configuração restaurado. Reinicie os serviços para aplicar as mudanças."
        fi
        
        return 0
    else
        error "Falha ao restaurar backup."
        return 1
    fi
}

# Função para listar backups
list_backups() {
    create_backup_dir
    
    local backup_files=($(ls -1t "$BACKUP_DIR"/*.tar.gz 2>/dev/null))
    
    if [ ${#backup_files[@]} -eq 0 ]; then
        warn "Nenhum arquivo de backup encontrado em $BACKUP_DIR"
        return 1
    fi
    
    echo -e "\n${BLUE}=== BACKUPS DISPONÍVEIS ===${NC}"
    local i=1
    for backup_file in "${backup_files[@]}"; do
        echo "$i. $(basename "$backup_file") ($(du -h "$backup_file" | cut -f1)) - $(date -r "$backup_file" '+%Y-%m-%d %H:%M:%S')"
        ((i++))
    done
    
    return 0
}

# Função para limpar backups antigos
clean_old_backups() {
    local days_to_keep=${1:-30}
    
    create_backup_dir
    
    log "Limpando backups com mais de $days_to_keep dias..."
    
    local deleted_count=0
    local backup_files=($(find "$BACKUP_DIR" -name "*.tar.gz" -mtime "+$days_to_keep"))
    
    for backup_file in "${backup_files[@]}"; do
        rm -f "$backup_file"
        ((deleted_count++))
        log "Removido: $(basename "$backup_file")"
    done
    
    if [ $deleted_count -gt 0 ]; then
        success "$deleted_count backup(s) antigo(s) removido(s)"
    else
        log "Nenhum backup antigo encontrado"
    fi
}

# Mostrar ajuda
show_help() {
    echo -e "${BLUE}=== AJUDA - BACKUP MANAGER ===${NC}"
    echo ""
    echo "Uso: $0 [OPÇÃO]"
    echo ""
    echo "Opções:"
    echo "  --complete       Fazer backup completo"
    echo "  --ollama         Fazer backup dos modelos Ollama"
    echo "  --config         Fazer backup das configurações"
    echo "  --openwebui      Fazer backup dos dados do OpenWebUI"
    echo "  --restore        Restaurar backup"
    echo "  --list           Listar backups disponíveis"
    echo "  --clean [DIAS]   Limpar backups antigos (padrão: 30 dias)"
    echo "  --help           Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 --complete"
    echo "  $0 --restore"
    echo "  $0 --list"
    echo "  $0 --clean 15"
    echo ""
}

# Função principal
main() {
    case "$1" in
        "--complete")
            create_backup_dir
            backup_complete
            ;;
        "--ollama")
            create_backup_dir
            backup_ollama_models
            ;;
        "--config")
            create_backup_dir
            backup_configurations
            ;;
        "--openwebui")
            create_backup_dir
            backup_openwebui_data
            ;;
        "--restore")
            restore_backup
            ;;
        "--list")
            list_backups
            ;;
        "--clean")
            local days=${2:-30}
            clean_old_backups "$days"
            ;;
        "--help"|"")
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
