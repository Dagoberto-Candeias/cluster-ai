#!/bin/bash
# Gerenciador de Backup Completo para o Cluster AI
# Descrição: Faz backup de configurações, modelos Ollama e dados de containers Docker.

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Configurações de Backup ---
BACKUP_BASE_DIR="${PROJECT_ROOT}/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7 # Manter backups por 7 dias

# --- Funções ---

show_help() {
    echo "Uso: $0 [comando]"
    echo "Gerencia backups completos para o Cluster AI."
    echo ""
    echo "Comandos:"
    echo "  full         - Realiza um backup completo (config, modelos, docker)."
    echo "  config       - Backup apenas das configurações do projeto e do usuário."
    echo "  models       - Backup apenas dos modelos Ollama."
    echo "  docker-data  - Backup dos volumes de dados dos containers Docker."
    echo "  list         - Lista todos os backups existentes."
    echo "  cleanup      - Remove backups mais antigos que $RETENTION_DAYS dias."
    echo "  help         - Mostra esta ajuda."
}

# Função para obter o caminho de um volume Docker
get_docker_volume_path() {
    local volume_name="$1"
    if ! command_exists docker; then return 1; fi
    # Usa `jq` se disponível para parsear JSON de forma segura, senão usa grep/awk
    if command_exists jq; then
        sudo docker volume inspect "$volume_name" | jq -r '.[0].Mountpoint' 2>/dev/null
    else
        sudo docker volume inspect "$volume_name" | grep "Mountpoint" | awk -F'"' '{print $4}' 2>/dev/null
    fi
}

# Função principal de backup
do_backup() {
    local backup_type="$1"
    section "Iniciando Backup: $backup_type"

    local backup_file="$BACKUP_BASE_DIR/backup_${backup_type}_${TIMESTAMP}.tar.gz"
    local staging_dir; staging_dir=$(mktemp -d)
    trap 'rm -rf "$staging_dir"' EXIT # Garante limpeza do diretório temporário

    local files_to_backup=()

    # Adicionar componentes com base no tipo de backup
    if [[ "$backup_type" == "full" || "$backup_type" == "config" ]]; then
        files_to_backup+=("$HOME/.cluster_config" "$HOME/.cluster_optimization" "$HOME/.ssh")
    fi
    if [[ "$backup_type" == "full" || "$backup_type" == "models" ]]; then
        files_to_backup+=("$HOME/.ollama")
    fi

    # Copiar arquivos do usuário para o staging
    for path in "${files_to_backup[@]}"; do
        if [ -e "$path" ]; then
            # Preserva a estrutura de diretórios relativa ao HOME para facilitar a restauração
            local dest_path="$staging_dir/user_home/$(realpath --relative-to="$HOME" "$path")"
            mkdir -p "$(dirname "$dest_path")"
            cp -a "$path" "$dest_path"
        else
            warn "Caminho não encontrado, pulando: $path"
        fi
    done

    # Lidar com dados do Docker, que exigem sudo
    if [[ "$backup_type" == "full" || "$backup_type" == "docker-data" ]]; then
        local webui_volume_path; webui_volume_path=$(get_docker_volume_path "open-webui")
        if [ -n "$webui_volume_path" ] && [ -d "$webui_volume_path" ]; then
            log "Copiando dados do volume 'open-webui' para a área de preparação..."
            sudo cp -a "$webui_volume_path" "$staging_dir/docker_volumes_data"
        else
            warn "Volume Docker 'open-webui' não encontrado ou caminho inválido. Pulando."
        fi
    fi

    # Verificar se há algo para fazer backup
    if [ -z "$(ls -A "$staging_dir")" ]; then
        error "Nenhum arquivo encontrado para o backup do tipo '$backup_type'. Operação abortada."
        return 1
    fi

    # Criar o arquivo de backup
    log "Criando arquivo de backup compactado..."
    mkdir -p "$BACKUP_BASE_DIR"
    if tar -czf "$backup_file" -C "$staging_dir" .; then
        success "Backup '$backup_type' concluído com sucesso!"
        log "Arquivo salvo em: $backup_file"
        log "Tamanho: $(du -h "$backup_file" | cut -f1)"
    else
        error "Falha ao criar o arquivo de backup. Verifique as permissões e o espaço em disco."
        rm -f "$backup_file" # Remove arquivo parcial
        return 1
    fi
}

# Função para listar backups
list_backups() {
    section "Backups Existentes em $BACKUP_BASE_DIR"
    if [ ! -d "$BACKUP_BASE_DIR" ] || [ -z "$(ls -A "$BACKUP_BASE_DIR"/*.tar.gz 2>/dev/null)" ]; then
        warn "Nenhum backup encontrado."
        return 1
    fi
    ls -lh "$BACKUP_BASE_DIR" | grep ".tar.gz" | awk '{print "  - " $9 " (" $5 ") - " $6 " " $7 " " $8}'
}

# Função para limpar backups antigos
cleanup_backups() {
    section "Limpando Backups Antigos (mais de $RETENTION_DAYS dias)"
    if [ ! -d "$BACKUP_BASE_DIR" ]; then
        warn "Diretório de backup não existe. Nada a fazer."
        return
    fi

    log "Procurando por backups com mais de $RETENTION_DAYS dias..."
    local old_backups; mapfile -t old_backups < <(find "$BACKUP_BASE_DIR" -name "*.tar.gz" -mtime +"$RETENTION_DAYS")

    if [ ${#old_backups[@]} -eq 0 ]; then
        log "Nenhum backup antigo para remover."
        return
    fi

    echo "Os seguintes arquivos serão removidos:"; printf "  - %s\n" "${old_backups[@]}"
    if confirm_operation "Deseja continuar com a remoção?"; then
        find "$BACKUP_BASE_DIR" -name "*.tar.gz" -mtime +"$RETENTION_DAYS" -print0 | xargs -0 -r rm -f
        success "Backups antigos removidos."
    else
        warn "Limpeza cancelada."
    fi
}

# --- Execução ---
main() {
    local command="${1:-help}"
    if [[ "$command" == "docker-data" || "$command" == "full" ]]; then
        if ! sudo -n true 2>/dev/null; then
            error "Este comando requer privilégios de sudo para acessar os volumes do Docker."; return 1
        fi
    fi
    case "$command" in
        full|config|models|docker-data) do_backup "$command" ;;
        list) list_backups ;;
        cleanup) cleanup_backups ;;
        *) show_help ;;
    esac
}

main "$@"