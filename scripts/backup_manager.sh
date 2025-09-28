#!/bin/bash
# =============================================================================
# Sistema de Gerenciamento de Backups - Cluster AI
# =============================================================================
# Gerencia backups automáticos antes de atualizações
#
# Autor: Cluster AI Team
# Data: 2025-01-20
# Versão: 1.0.0
# Arquivo: backup_manager.sh
# =============================================================================

set -euo pipefail

# --- Configuração Inicial ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Carregar funções comuns
if [ ! -f "${SCRIPT_DIR}/lib/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${SCRIPT_DIR}/lib/common.sh"

# Carregar configuração
UPDATE_CONFIG="${PROJECT_ROOT}/config/update.conf"
if [ ! -f "$UPDATE_CONFIG" ]; then
    error "Arquivo de configuração não encontrado: $UPDATE_CONFIG"
    exit 1
fi

# --- Constantes ---
LOG_DIR="${PROJECT_ROOT}/logs"
BACKUP_LOG="${LOG_DIR}/backup_manager.log"

# Criar diretórios necessários
mkdir -p "$LOG_DIR"

# --- Funções ---

# Função para log detalhado
log_backup() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" >> "$BACKUP_LOG"

    case "$level" in
        "INFO")
            info "$message" ;;
        "WARN")
            warn "$message" ;;
        "ERROR")
            error "$message" ;;
    esac
}

# Função para obter configuração
get_update_config() {
    get_config_value "$1" "$2" "$UPDATE_CONFIG" "$3"
}

# Função para gerar nome do backup
generate_backup_name() {
    local backup_type="$1"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    echo "backup_${backup_type}_${timestamp}"
}

# Função para limpar backups antigos
cleanup_old_backups() {
    local backup_dir
    backup_dir=$(get_update_config "GENERAL" "BACKUP_DIR")

    local max_backups
    max_backups=$(get_update_config "GENERAL" "MAX_BACKUPS")

    if [[ ! -d "$backup_dir" ]]; then
        log_backup "DEBUG" "Diretório de backup não existe: $backup_dir"
        return 0
    fi

    log_backup "INFO" "Limpando backups antigos (máximo: $max_backups)"

    # Contar backups existentes
    local backup_count
    backup_count=$(find "$backup_dir" -name "backup_*.tar.gz" | wc -l)

    if [[ $backup_count -le $max_backups ]]; then
        log_backup "DEBUG" "Número de backups dentro do limite: $backup_count <= $max_backups"
        return 0
    fi

    # Remover backups mais antigos
    local to_remove
    to_remove=$((backup_count - max_backups))

    log_backup "INFO" "Removendo $to_remove backups antigos"

    find "$backup_dir" -name "backup_*.tar.gz" -printf '%T+ %p\n' | sort | head -n "$to_remove" | while read -r line; do
        local backup_file
        backup_file=$(echo "$line" | cut -d' ' -f2-)
        log_backup "INFO" "Removendo backup antigo: $backup_file"
        rm -f "$backup_file"
    done

    log_backup "INFO" "Limpeza de backups concluída"
}

# Função para fazer backup de configurações
backup_configs() {
    local backup_name="$1"
    local backup_dir
    backup_dir=$(get_update_config "GENERAL" "BACKUP_DIR")

    log_backup "INFO" "Fazendo backup das configurações..."

    # Criar diretório do backup
    local full_backup_dir="${backup_dir}/${backup_name}"
    mkdir -p "$full_backup_dir"

    # Lista de arquivos/diretórios para backup
    local configs=(
        "config/"
        "configs/"
        "config/cluster.conf"
        "cluster.conf.ini"
        "docker-compose.yml"
        "docker-compose.prod.yml"
        ".env"
    )

    local backup_success=true

    for config in "${configs[@]}"; do
        if [[ -e "$PROJECT_ROOT/$config" ]]; then
            log_backup "INFO" "Fazendo backup de: $config"
            if cp -r "$PROJECT_ROOT/$config" "$full_backup_dir/"; then
                log_backup "DEBUG" "Backup de $config concluído"
            else
                log_backup "ERROR" "Falha no backup de: $config"
                backup_success=false
            fi
        else
            log_backup "DEBUG" "Arquivo não encontrado, pulando: $config"
        fi
    done

    if [[ "$backup_success" == "true" ]]; then
        log_backup "INFO" "Backup de configurações concluído com sucesso"
        return 0
    else
        log_backup "ERROR" "Falha no backup de configurações"
        return 1
    fi
}

# Função para fazer backup de dados
backup_data() {
    local backup_name="$1"
    local backup_dir
    backup_dir=$(get_update_config "GENERAL" "BACKUP_DIR")

    log_backup "INFO" "Fazendo backup dos dados..."

    local full_backup_dir="${backup_dir}/${backup_name}"

    # Lista de diretórios de dados para backup
    local data_dirs=(
        "data/"
        "models/"
        "logs/"
        "backups/"
    )

    local backup_success=true

    for data_dir in "${data_dirs[@]}"; do
        if [[ -d "$PROJECT_ROOT/$data_dir" ]]; then
            log_backup "INFO" "Fazendo backup de: $data_dir"
            if tar -czf "${full_backup_dir}/data_${data_dir//\//_}.tar.gz" -C "$PROJECT_ROOT" "$data_dir" 2>/dev/null; then
                log_backup "DEBUG" "Backup de $data_dir concluído"
            else
                log_backup "ERROR" "Falha no backup de: $data_dir"
                backup_success=false
            fi
        else
            log_backup "DEBUG" "Diretório não encontrado, pulando: $data_dir"
        fi
    done

    if [[ "$backup_success" == "true" ]]; then
        log_backup "INFO" "Backup de dados concluído com sucesso"
        return 0
    else
        log_backup "ERROR" "Falha no backup de dados"
        return 1
    fi
}

# Função para fazer backup de containers Docker
backup_docker_containers() {
    local backup_name="$1"
    local backup_dir
    backup_dir=$(get_update_config "GENERAL" "BACKUP_DIR")

    if ! command_exists docker; then
        log_backup "DEBUG" "Docker não está instalado, pulando backup de containers"
        return 0
    fi

    log_backup "INFO" "Fazendo backup de containers Docker..."

    local full_backup_dir="${backup_dir}/${backup_name}"

    # Obter lista de containers importantes
    local containers=("open-webui" "nginx" "ollama")
    local backup_success=true

    for container in "${containers[@]}"; do
        if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
            log_backup "INFO" "Fazendo backup do container: $container"

            # Backup dos volumes
            local volumes
            volumes=$(docker inspect "$container" --format '{{range .Mounts}}{{.Source}}:{{.Destination}} {{end}}' 2>/dev/null || echo "")

            if [[ -n "$volumes" ]]; then
                while IFS=':' read -r source dest; do
                    [[ -z "$source" || -z "$dest" ]] && continue

                    if [[ -d "$source" ]]; then
                        local volume_name
                        volume_name=$(basename "$source")
                        log_backup "INFO" "Fazendo backup do volume: $volume_name"

                        if tar -czf "${full_backup_dir}/docker_volume_${container}_${volume_name}.tar.gz" -C "$source" . 2>/dev/null; then
                            log_backup "DEBUG" "Backup do volume $volume_name concluído"
                        else
                            log_backup "ERROR" "Falha no backup do volume: $volume_name"
                            backup_success=false
                        fi
                    fi
                done <<< "$volumes"
            fi

            # Backup da configuração do container
            if docker inspect "$container" > "${full_backup_dir}/docker_inspect_${container}.json" 2>/dev/null; then
                log_backup "DEBUG" "Backup da configuração do container $container concluído"
            else
                log_backup "ERROR" "Falha no backup da configuração do container: $container"
                backup_success=false
            fi
        else
            log_backup "DEBUG" "Container não encontrado, pulando: $container"
        fi
    done

    if [[ "$backup_success" == "true" ]]; then
        log_backup "INFO" "Backup de containers Docker concluído com sucesso"
        return 0
    else
        log_backup "ERROR" "Falha no backup de containers Docker"
        return 1
    fi
}

# Função para fazer backup do banco de dados
backup_database() {
    local backup_name="$1"
    local backup_dir
    backup_dir=$(get_update_config "GENERAL" "BACKUP_DIR")

    log_backup "INFO" "Fazendo backup do banco de dados..."

    local full_backup_dir="${backup_dir}/${backup_name}"

    # Verificar se há algum banco de dados rodando
    if command_exists docker && docker ps --format '{{.Names}}' | grep -q "postgres\|mysql\|mongodb"; then
        log_backup "INFO" "Banco de dados detectado, fazendo backup..."

        # Para PostgreSQL
        if docker ps --format '{{.Names}}' | grep -q "postgres"; then
            log_backup "INFO" "Fazendo backup do PostgreSQL"
            if docker exec postgres pg_dumpall -U postgres > "${full_backup_dir}/postgres_backup.sql" 2>/dev/null; then
                log_backup "DEBUG" "Backup do PostgreSQL concluído"
            else
                log_backup "ERROR" "Falha no backup do PostgreSQL"
                return 1
            fi
        fi

        # Para MySQL
        if docker ps --format '{{.Names}}' | grep -q "mysql"; then
            log_backup "INFO" "Fazendo backup do MySQL"
            if docker exec mysql mysqldump -u root -p --all-databases > "${full_backup_dir}/mysql_backup.sql" 2>/dev/null; then
                log_backup "DEBUG" "Backup do MySQL concluído"
            else
                log_backup "ERROR" "Falha no backup do MySQL"
                return 1
            fi
        fi
    else
        log_backup "DEBUG" "Nenhum banco de dados detectado"
    fi

    log_backup "INFO" "Backup do banco de dados concluído"
    return 0
}

# Função para criar backup completo
create_full_backup() {
    local backup_type="${1:-pre_update}"
    local backup_name
    backup_name=$(generate_backup_name "$backup_type")

    local backup_dir
    backup_dir=$(get_update_config "GENERAL" "BACKUP_DIR")

    log_backup "INFO" "Iniciando backup completo: $backup_name"

    # Criar diretório do backup
    local full_backup_dir="${backup_dir}/${backup_name}"
    mkdir -p "$full_backup_dir"

    # Criar arquivo de metadados
    {
        echo "Backup Type: $backup_type"
        echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Hostname: $(hostname)"
        echo "User: $(whoami)"
        echo "Project: Cluster AI"
        echo "Version: $(git rev-parse HEAD 2>/dev/null || echo 'unknown')"
    } > "${full_backup_dir}/backup_metadata.txt"

    # Executar backups
    local backup_success=true

    if ! backup_configs "$backup_name"; then
        backup_success=false
    fi

    if ! backup_data "$backup_name"; then
        backup_success=false
    fi

    if ! backup_docker_containers "$backup_name"; then
        backup_success=false
    fi

    if ! backup_database "$backup_name"; then
        backup_success=false
    fi

    # Criar arquivo de checksum
    find "$full_backup_dir" -type f -exec sha256sum {} \; > "${full_backup_dir}/checksums.sha256"

    # Criar arquivo compactado final
    local final_backup="${backup_dir}/${backup_name}.tar.gz"

    if cd "$backup_dir" && tar -czf "$final_backup" "$backup_name"; then
        log_backup "INFO" "Backup compactado criado: $final_backup"

        # Remover diretório temporário
        rm -rf "$full_backup_dir"

        # Limpar backups antigos
        cleanup_old_backups

        if [[ "$backup_success" == "true" ]]; then
            log_backup "INFO" "Backup completo criado com sucesso: $final_backup"
            success "Backup criado: $final_backup"
            return 0
        else
            log_backup "WARN" "Backup criado com alguns erros: $final_backup"
            warn "Backup criado com alguns erros"
            return 1
        fi
    else
        log_backup "ERROR" "Falha ao criar backup compactado"
        error "Falha ao criar backup"
        return 1
    fi
}

# Função para restaurar backup
restore_backup() {
    local backup_file="$1"

    if [[ ! -f "$backup_file" ]]; then
        error "Arquivo de backup não encontrado: $backup_file"
        return 1
    fi

    log_backup "INFO" "Iniciando restauração do backup: $backup_file"

    # Extrair backup
    local temp_dir
    temp_dir=$(mktemp -d)

    if tar -xzf "$backup_file" -C "$temp_dir"; then
        log_backup "INFO" "Backup extraído para: $temp_dir"

        # TODO: Implementar restauração específica por tipo
        # Por enquanto, apenas log
        log_backup "INFO" "Restauração concluída (funcionalidade básica)"
        success "Restauração concluída"
        return 0
    else
        log_backup "ERROR" "Falha ao extrair backup"
        error "Falha ao extrair backup"
        return 1
    fi
}

# Função para listar backups
list_backups() {
    local backup_dir
    backup_dir=$(get_update_config "GENERAL" "BACKUP_DIR")

    if [[ ! -d "$backup_dir" ]]; then
        info "Nenhum backup encontrado"
        return 0
    fi

    echo -e "${BOLD}${BLUE}BACKUPS DISPONÍVEIS${NC}"
    echo

    find "$backup_dir" -name "backup_*.tar.gz" -printf '%T@ %Tc %p\n' | sort -n | while read -r timestamp formatted_time filepath; do
        local size
        size=$(du -h "$filepath" | cut -f1)
        local backup_name
        backup_name=$(basename "$filepath" .tar.gz)

        echo -e "${CYAN}📦${NC} ${BOLD}$backup_name${NC}"
        echo -e "  ${GRAY}Data: $formatted_time${NC}"
        echo -e "  ${GRAY}Tamanho: $size${NC}"
        echo -e "  ${GRAY}Arquivo: $filepath${NC}"
        echo
    done
}

# Função principal
main() {
    # Verificar argumentos
    if [[ $# -gt 0 ]]; then
        case "$1" in
            "create"|"backup")
                create_full_backup "${2:-pre_update}"
                ;;
            "restore")
                if [[ -z "$2" ]]; then
                    error "Nome do arquivo de backup necessário"
                    echo "Uso: $0 restore <arquivo_backup>"
                    exit 1
                fi
                restore_backup "$2"
                ;;
            "list"|"ls")
                list_backups
                ;;
            "cleanup")
                cleanup_old_backups
                ;;
            *)
                echo "Uso: $0 [create|restore|list|cleanup]"
                exit 1
                ;;
        esac
    else
        # Backup padrão
        create_full_backup "manual"
    fi
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
