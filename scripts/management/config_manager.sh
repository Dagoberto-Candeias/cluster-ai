#!/bin/bash
# Gerenciador de Configurações de Otimização - Cluster AI
# Faz backup e restaura as configurações geradas pelo resource_optimizer.sh

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"
BACKUP_DIR="${PROJECT_ROOT}/backups/config_backups"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado em ${UTILS_DIR}/common.sh"
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Arquivos de Configuração ---
DASK_CONFIG_PATH="$HOME/.cluster_config/dask.conf"
OLLAMA_CONFIG_PATH="/etc/systemd/system/ollama.service.d/override.conf"

# --- Funções ---

show_help() {
    echo "Uso: $0 [comando]"
    echo "Gerencia backups e restaurações das configurações de otimização."
    echo ""
    echo "Comandos:"
    echo "  backup    - Cria um novo backup das configurações atuais."
    echo "  restore   - Restaura configurações a partir de um backup."
    echo "  list      - Lista os backups disponíveis."
    echo "  help      - Mostra esta ajuda."
}

list_backups() {
    section "Backups de Configuração Disponíveis"
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR"/*.tar.gz 2>/dev/null)" ]; then
        warn "Nenhum backup de configuração encontrado em $BACKUP_DIR"
        return 1
    fi
    
    # Usar um loop para listar os arquivos com números
    local i=1
    mapfile -t backups < <(ls -1t "$BACKUP_DIR"/*.tar.gz)
    for backup in "${backups[@]}"; do
        echo "  $i) $(basename "$backup")"
        ((i++))
    done
    return 0
}

do_backup() {
    section "Criando Backup das Configurações de Otimização"
    
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/config_backup_${timestamp}.tar.gz"
    local staging_dir
    staging_dir=$(mktemp -d)

    # Função para limpar o diretório temporário na saída
    trap 'rm -rf "$staging_dir"' EXIT

    local backup_created=false

    # Copiar configuração do Dask
    if [ -f "$DASK_CONFIG_PATH" ]; then
        log "Fazendo backup de: $DASK_CONFIG_PATH"
        cp "$DASK_CONFIG_PATH" "$staging_dir/dask.conf"
        backup_created=true
    else
        warn "Arquivo de configuração do Dask não encontrado. Pulando."
    fi

    # Copiar configuração do Ollama com sudo
    if [ -f "$OLLAMA_CONFIG_PATH" ]; then
        log "Fazendo backup de: $OLLAMA_CONFIG_PATH"
        sudo cp "$OLLAMA_CONFIG_PATH" "$staging_dir/override.conf"
        backup_created=true
    else
        warn "Arquivo de configuração do Ollama não encontrado. Pulando."
    fi

    if [ "$backup_created" = false ]; then
        error "Nenhum arquivo de configuração encontrado para fazer backup."
        return 1
    fi

    # Criar o arquivo de backup
    mkdir -p "$BACKUP_DIR"
    tar -czf "$backup_file" -C "$staging_dir" .
    
    success "Backup criado com sucesso em: $backup_file"
    log "Tamanho: $(du -h "$backup_file" | cut -f1)"
}

do_restore() {
    section "Restaurando Configurações de Otimização"
    
    if ! list_backups; then
        return 1
    fi
    
    echo ""
    read -p "Digite o número do backup que deseja restaurar (ou 'q' para cancelar): " choice

    if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        log "Restauração cancelada."
        return 0
    fi

    mapfile -t backups < <(ls -1t "$BACKUP_DIR"/*.tar.gz)
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#backups[@]} ]; then
        error "Seleção inválida."
        return 1
    fi

    local backup_to_restore="${backups[$((choice-1))]}"
    log "Restaurando a partir de: $(basename "$backup_to_restore")"

    if ! confirm_operation "Esta ação irá sobrescrever as configurações atuais."; then
        log "Restauração cancelada."
        return 0
    fi

    local staging_dir; staging_dir=$(mktemp -d); trap 'rm -rf "$staging_dir"' EXIT
    tar -xzf "$backup_to_restore" -C "$staging_dir"

    [ -f "$staging_dir/dask.conf" ] && { log "Restaurando Dask..."; mkdir -p "$(dirname "$DASK_CONFIG_PATH")"; cp "$staging_dir/dask.conf" "$DASK_CONFIG_PATH"; success "Dask restaurado."; }
    [ -f "$staging_dir/override.conf" ] && { log "Restaurando Ollama (requer sudo)..."; sudo mkdir -p "$(dirname "$OLLAMA_CONFIG_PATH")"; sudo cp "$staging_dir/override.conf" "$OLLAMA_CONFIG_PATH"; success "Ollama restaurado."; sudo systemctl daemon-reload && sudo systemctl restart ollama && success "Serviço Ollama reiniciado."; }

    echo ""; success "Restauração concluída."; info "Reinicie os Dask workers para aplicar as mudanças."
}

# --- Menu Principal ---
main() {
    case "${1:-help}" in
        backup) do_backup ;;
        restore) do_restore ;;
        list) list_backups ;;
        *) show_help ;;
    esac
}

main "$@"