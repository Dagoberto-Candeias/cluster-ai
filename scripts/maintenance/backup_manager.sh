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
    echo "Uso: $0 [comando] [--encrypt]"
    echo "Gerencia backups completos para o Cluster AI."
    echo ""
    echo "Comandos:"
    echo "  full          - Realiza um backup completo (config, modelos, docker)."
    echo "  config        - Backup apenas das configurações do projeto e do usuário."
    echo "  models        - Backup apenas dos modelos Ollama."
    echo "  docker-data   - Backup dos volumes de dados dos containers Docker."
    echo "  list          - Lista todos os backups existentes."
    echo "  cleanup       - Remove backups mais antigos que $RETENTION_DAYS dias."
    echo "  help          - Mostra esta ajuda."
    echo ""
    echo "Opções:"
    echo "  --encrypt     - Criptografa o arquivo de backup com uma senha."
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

# Verifica se há espaço em disco suficiente para o backup
# Uso: check_disk_space <backup_type> <caminho_volume_docker_opcional>
check_disk_space() {
    local backup_type="$1"
    local docker_volume_path="$2"
    subsection "Verificando espaço em disco"

    local estimated_size_kb=0
    local paths_to_check=()

    # Estimar tamanho dos arquivos do usuário
    if [[ "$backup_type" == "full" || "$backup_type" == "config" ]]; then
        paths_to_check+=("$HOME/.cluster_config" "$HOME/.cluster_optimization" "$HOME/.ssh")
    fi
    if [[ "$backup_type" == "full" || "$backup_type" == "models" ]]; then
        paths_to_check+=("$HOME/.ollama")
    fi

    for path in "${paths_to_check[@]}"; do
        if [ -e "$path" ]; then
            estimated_size_kb=$((estimated_size_kb + $(du -sk "$path" | awk '{print $1}')))
        fi
    done

    # Estimar tamanho do volume Docker (requer sudo)
    if [ -n "$docker_volume_path" ] && [ -d "$docker_volume_path" ]; then
        log "Estimando tamanho do volume Docker (requer sudo)..."
        local docker_size_kb
        docker_size_kb=$(sudo du -sk "$docker_volume_path" | awk '{print $1}')
        estimated_size_kb=$((estimated_size_kb + docker_size_kb))
    fi

    # Adicionar uma margem de segurança (ex: 20%)
    local required_size_kb=$((estimated_size_kb * 120 / 100))
    
    # Verificar espaço disponível no destino do backup
    mkdir -p "$BACKUP_BASE_DIR"
    local available_size_kb
    available_size_kb=$(df -k "$BACKUP_BASE_DIR" | awk 'NR==2 {print $4}')

    log "Tamanho estimado do backup: $(numfmt --to=iec-i --suffix=B --format="%.1f" $estimated_size_kb)K"
    log "Espaço necessário (com margem): $(numfmt --to=iec-i --suffix=B --format="%.1f" $required_size_kb)K"
    log "Espaço disponível em '$BACKUP_BASE_DIR': $(numfmt --to=iec-i --suffix=B --format="%.1f" $available_size_kb)K"

    if [ "$available_size_kb" -lt "$required_size_kb" ]; then
        error "Espaço em disco insuficiente para criar o backup."
        return 1
    fi

    success "Espaço em disco suficiente."
    return 0
}

# Função principal de backup
do_backup() {
    local backup_type="$1"
    local encrypt_backup=false
    if [[ "$2" == "--encrypt" ]]; then
        encrypt_backup=true
    fi

    section "Iniciando Backup: $backup_type (Criptografado: $encrypt_backup)"
    audit_log "BACKUP_START" "Type: $backup_type, Encrypted: $encrypt_backup"

    local hostname; hostname=$(hostname -s)
    local backup_file_base="$BACKUP_BASE_DIR/backup_${backup_type}_${hostname}_${TIMESTAMP}"
    local backup_file="${backup_file_base}.tar.gz"
    if [ "$encrypt_backup" = true ]; then
        backup_file="${backup_file}.enc"
    fi

    local staging_dir; staging_dir=$(mktemp -d)
    trap 'rm -rf "$staging_dir"' EXIT # Garante limpeza do diretório temporário

    # Verificar espaço em disco antes de prosseguir
    local docker_volume_path_check=""
    if [[ "$backup_type" == "full" || "$backup_type" == "docker-data" ]]; then
        docker_volume_path_check=$(get_docker_volume_path "open-webui")
    fi
    if ! check_disk_space "$backup_type" "$docker_volume_path_check"; then return 1; fi

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
            local dest_parent_dir="$staging_dir/user_home"
            mkdir -p "$dest_parent_dir"
            log "Copiando $(basename "$path")..."
            rsync -a --info=progress2 --relative "$path" "$dest_parent_dir"
        else
            warn "Caminho não encontrado, pulando: $path"
        fi
    done

    # Lidar com dados do Docker, que exigem sudo
    if [[ "$backup_type" == "full" || "$backup_type" == "docker-data" ]]; then
        local webui_volume_path; webui_volume_path=$(get_docker_volume_path "open-webui")
        if [ -n "$webui_volume_path" ] && [ -d "$webui_volume_path" ]; then
            log "Copiando dados do volume 'open-webui' para a área de preparação..."
            sudo rsync -a --info=progress2 "$webui_volume_path/" "$staging_dir/docker_volumes_data/"
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

    # Comandos para o pipeline de backup
    local tar_command="tar -c -C \"$staging_dir\" ."
    local compressor="gzip"
    local pv_command=""
    local encrypt_command=""
    local final_command=""

    if [ "$encrypt_backup" = true ]; then
        if ! command_exists openssl; then
            error "Comando 'openssl' não encontrado. A criptografia não é possível."
            info "Instale com: sudo apt install openssl (ou equivalente)"
            return 1
        fi
        local password
        read -s -p "Digite a senha para criptografar o backup: " password
        echo
        read -s -p "Confirme a senha: " password_confirm
        echo
        if [ -z "$password" ] || [ "$password" != "$password_confirm" ]; then
            error "Senhas não conferem ou estão em branco. Operação abortada."
            return 1
        fi
        # Usa PBKDF2 para derivação de chave mais segura
        encrypt_command="openssl enc -aes-256-cbc -pbkdf2 -pass pass:'$password'"
    fi

    # Melhoria: Usar zstd se disponível, pois é mais rápido e eficiente
    if command_exists zstd; then
        log "Usando 'zstd' para compressão (mais eficiente)."
        compressor="zstd"
        backup_file="${backup_file_base}.tar.zst" # Altera a extensão do arquivo
    fi

    local success_flag=false
    if command_exists pv; then
        log "Usando 'pv' para exibir barra de progresso..."
        # Estima o tamanho total para o pv
        local total_size; total_size=$(du -sb "$staging_dir" | awk '{print $1}')
        pv_command="pv -s \"$total_size\""
    else
        warn "Comando 'pv' não encontrado. A barra de progresso não será exibida."
        info "Para instalar: sudo apt install pv (ou equivalente)"
    fi

    # Constrói o pipeline de comandos
    final_command="$tar_command"
    [ -n "$pv_command" ] && final_command+=" | $pv_command"
    final_command+=" | $compressor"
    [ -n "$encrypt_command" ] && final_command+=" | $encrypt_command"

    if eval "$final_command" > "$backup_file"; then
        success "Backup '$backup_type' concluído com sucesso!"
        log "Arquivo salvo em: $backup_file"
        log "Tamanho: $(du -h "$backup_file" | cut -f1)"

        # Melhoria: Gerar checksum para verificação de integridade
        log "Gerando checksum SHA256 para verificação de integridade..."
        if sha256sum "$backup_file" > "${backup_file}.sha256"; then
            success "Checksum salvo em: ${backup_file}.sha256"
        else
            warn "Não foi possível gerar o checksum para o backup."
        fi

        audit_log "BACKUP_SUCCESS" "File: $(basename "$backup_file")"
    else
        error "Falha ao criar o arquivo de backup. Verifique as permissões e o espaço em disco."
        rm -f "$backup_file" # Remove arquivo parcial
        audit_log "BACKUP_FAIL" "Type: $backup_type"
        return 1
    fi
}

# Função para listar backups
list_backups() {
    section "Backups Existentes em $BACKUP_BASE_DIR"
    if [ ! -d "$BACKUP_BASE_DIR" ] || [ -z "$(ls -A "$BACKUP_BASE_DIR"/*.tar.* 2>/dev/null)" ]; then
        warn "Nenhum backup encontrado."
        return 1
    fi
    ls -lh "$BACKUP_BASE_DIR" | grep ".tar." | awk '{print "  - " $9 " (" $5 ") - " $6 " " $7 " " $8}'
}

# Função para limpar backups antigos
cleanup_backups() {
    section "Limpando Backups Antigos (mais de $RETENTION_DAYS dias)"
    audit_log "CLEANUP_START" "Retention: $RETENTION_DAYS days"
    if [ ! -d "$BACKUP_BASE_DIR" ]; then
        warn "Diretório de backup não existe. Nada a fazer."
        return
    fi

    log "Procurando por backups com mais de $RETENTION_DAYS dias..."
    local old_backups; mapfile -t old_backups < <(find "$BACKUP_BASE_DIR" -name "*.tar.*" -mtime +"$RETENTION_DAYS")

    if [ ${#old_backups[@]} -eq 0 ]; then
        log "Nenhum backup antigo para remover."
        return
    fi

    echo "Os seguintes arquivos (e seus checksums) serão removidos:"; printf "  - %s\n" "${old_backups[@]}"
    if confirm_operation "Deseja continuar com a remoção?"; then
        find "$BACKUP_BASE_DIR" -name "*.tar.*" -mtime +"$RETENTION_DAYS" -print0 | xargs -0 -r rm -f
        audit_log "CLEANUP_SUCCESS" "Removed ${#old_backups[@]} files"
        success "Backups antigos removidos."
    else
        audit_log "CLEANUP_CANCEL" "User cancelled operation"
        warn "Limpeza cancelada."
    fi
}

# --- Execução ---
main() {
    local command="${1:-help}"
    local encrypt_flag="${2:-}"

    if [[ "$command" == "docker-data" || "$command" == "full" ]]; then
        if ! sudo -n true 2>/dev/null; then
            error "Este comando requer privilégios de sudo para acessar os volumes do Docker."; return 1
        fi
    fi
    case "$command" in
        full|config|models|docker-data) do_backup "$command" "$encrypt_flag" ;;
        list) list_backups ;;
        cleanup) cleanup_backups ;;
        *) show_help ;;
    esac
}

main "$@"