#!/bin/bash
# Gerenciador de Restauração para o Cluster AI
# Descrição: Restaura backups de configurações, modelos e workers remotos.

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="${PROJECT_ROOT}/scripts/lib"
BACKUP_DIR="${PROJECT_ROOT}/backups"

source "${LIB_DIR}/common.sh"

# --- Funções ---

show_help() {
    echo "Uso: $0"
    echo "Gerencia a restauração de backups para o Cluster AI."
}

# Função para listar backups disponíveis por tipo
list_backups_by_type() {
    local type_prefix="$1" # ex: "backup_worker_"
    local description="$2" # ex: "Worker Remoto"    

    section "Backups de $description Disponíveis"
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR"/${type_prefix}*.tar.gz* 2>/dev/null)" ]; then
        warn "Nenhum backup de '$description' encontrado."
        return 1
    fi    
    
    local i=1
    # Use mapfile para ler os arquivos em um array, ordenados pelo mais recente
    mapfile -t backups < <(ls -1t "$BACKUP_DIR"/${type_prefix}*.tar.gz*)
    for backup in "${backups[@]}"; do
        echo "  $i) $(basename "$backup")"
        ((i++))
    done    
    return 0
}

# Função para restaurar um backup de worker remoto
do_restore_remote_worker() {
    if ! list_backups_by_type "backup_worker_" "Worker Remoto"; then
        return 1
    fi
        
    echo ""
    read -p "Digite o número do backup que deseja restaurar: " choice
        
    mapfile -t backups < <(ls -1t "$BACKUP_DIR"/backup_worker_*.tar.gz*)
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#backups[@]} ]; then
        error "Seleção inválida."
        return 1    
    fi
    
    local backup_to_restore="${backups[$((choice-1))]}"
    
    subsection "Restaurando Backup de Worker Remoto"
    log "Backup selecionado: $(basename "$backup_to_restore")"
    audit_log "RESTORE_REMOTE_START" "Backup: $(basename "$backup_to_restore"), Target: $remote_user@$remote_host"
        
    echo ""
    info "Agora, forneça os detalhes do NOVO dispositivo worker para onde o backup será restaurado."
    read -p "Digite o nome de usuário do novo worker: " remote_user
    read -p "Digite o hostname ou IP do novo worker: " remote_host
    read -p "Digite a porta SSH do worker (padrão: 22 para Linux, 8022 para Android): " remote_port
    remote_port=${remote_port:-22}
    
    if [ -z "$remote_user" ] || [ -z "$remote_host" ]; then
        error "Usuário e host são obrigatórios. Abortando."
        return 1
    fi    
    
    if ! confirm_operation "Restaurar '$(basename "$backup_to_restore")' para '$remote_user@$remote_host:$remote_port'?"; then
        log "Restauração cancelada."
        audit_log "RESTORE_REMOTE_CANCEL" "User cancelled operation"
        return 0
    fi
        
    local password=""
    if [[ "$backup_to_restore" == *.enc ]]; then
        if ! command_exists openssl; then
            error "Comando 'openssl' não encontrado. Não é possível descriptografar."
            return 1
        fi
        subsection "Backup Criptografado"
        read -s -p "Digite a senha do backup: " password
        echo
        if [ -z "$password" ]; then
            error "A senha não pode estar em branco. Abortando."
            return 1
        fi
    fi    

    # Criar um diretório de preparação local para extrair o backup
    local staging_dir; staging_dir=$(mktemp -d)
    trap 'rm -rf "$staging_dir"' EXIT

    log "1. Extraindo backup localmente para preparação..."
    local extract_cmd=""
    if [ -n "$password" ]; then
        extract_cmd="openssl enc -d -aes-256-cbc -pbkdf2 -in '$backup_to_restore' -pass pass:'$password' | tar -xz -C '$staging_dir'"
    else
        extract_cmd="tar -xzf '$backup_to_restore' -C '$staging_dir'"
    fi

    if ! eval "$extract_cmd"; then
        error "Falha ao extrair o arquivo de backup localmente. O arquivo pode estar corrompido."
        return 1
    fi
    success "  -> Backup extraído com sucesso."

    # O backup contém um diretório 'user_home'
    local source_dir="$staging_dir/user_home/"
    if [ ! -d "$source_dir" ]; then
        error "Estrutura de backup inválida. Diretório 'user_home' não encontrado."
        return 1
    fi

    log "2. Sincronizando dados para o worker remoto usando rsync..."
    if rsync -a -e "ssh -p $remote_port" --info=progress2 "$source_dir" "$remote_user@$remote_host:$HOME/"; then
        success "  -> Sincronização com o worker remoto concluída."
        audit_log "RESTORE_REMOTE_SUCCESS" "Successfully restored $(basename "$backup_to_restore") to $remote_host"
    else
        error "  -> Falha ao sincronizar dados com o worker remoto."
        warn "     Verifique a conexão SSH, permissões e se 'rsync' está instalado no worker."
        audit_log "RESTORE_REMOTE_FAIL" "Failed to restore $(basename "$backup_to_restore") to $remote_host"
        return 1
    fi
    
    echo ""
    success "🎉 Restauração do worker concluída!"
    info "O novo worker '$remote_host' agora tem os dados (modelos, configs) do backup."
    info "Lembre-se de registrar este novo nó no 'nodes_list.conf' se ainda não o fez."
}

# Função para restaurar um backup de configurações locais
do_restore_local_config() {
    if ! list_backups_by_type "backup_config_" "Configurações Locais"; then
        return 1
    fi
    
    echo ""
    read -p "Digite o número do backup de configuração que deseja restaurar: " choice

    mapfile -t backups < <(ls -1t "$BACKUP_DIR"/backup_config_*.tar.gz* 2>/dev/null)
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#backups[@]} ]; then
        error "Seleção inválida."
        return 1
    fi    

    local backup_to_restore="${backups[$((choice-1))]}"

    subsection "Restaurando Backup de Configurações Locais"
    log "Backup selecionado: $(basename "$backup_to_restore")"
    audit_log "RESTORE_LOCAL_START" "Backup: $(basename "$backup_to_restore")"

    # Paths que serão sobrescritos    
    local paths_to_overwrite=("$HOME/.cluster_config" "$HOME/.cluster_optimization" "$HOME/.ssh")

    warn "A restauração irá sobrescrever os seguintes diretórios, se existirem:"    
    for path in "${paths_to_overwrite[@]}"; do echo "  - $path"; done

    if ! confirm_operation "Deseja criar um backup das configurações atuais antes de continuar?"; then
        warn "Backup das configurações atuais cancelado."
    else
        local current_config_backup="$BACKUP_DIR/pre-restore-backup_$(date +%Y%m%d_%H%M%S).tar.gz"
        log "Criando backup das configurações atuais em $(basename "$current_config_backup")..."
                
        local existing_paths=()
        for path in "${paths_to_overwrite[@]}"; do
            if [ -e "$path" ]; then
                existing_paths+=("$(realpath --relative-to="$HOME" "$path")")
            fi
        done

        if [ ${#existing_paths[@]} -gt 0 ]; then            
            tar -czf "$current_config_backup" -C "$HOME" "${existing_paths[@]}"
            success "Backup das configurações atuais criado com sucesso."
        else
            info "Nenhuma configuração atual encontrada para fazer backup."
        fi        
    fi

    if ! confirm_operation "Prosseguir com a restauração de '$(basename "$backup_to_restore")'?"; then
        log "Restauração cancelada."
        audit_log "RESTORE_LOCAL_CANCEL" "User cancelled operation"
        return 0
    fi
    
    # Criar um diretório de preparação para extrair o backup
    local staging_dir; staging_dir=$(mktemp -d)
    trap 'rm -rf "$staging_dir"' EXIT

    log "1. Extraindo backup para a área de preparação..."
    local extract_cmd=""
    if [[ "$backup_to_restore" == *.enc ]]; then
        if ! command_exists openssl; then
            error "Comando 'openssl' não encontrado. Não é possível descriptografar."
            return 1
        fi
        local password
        read -s -p "Digite a senha do backup: " password
        echo
        if [ -z "$password" ]; then
            error "A senha não pode estar em branco. Abortando."
            return 1
        fi
        extract_cmd="openssl enc -d -aes-256-cbc -pbkdf2 -in '$backup_to_restore' -pass pass:'$password' | tar -xz -C '$staging_dir'"
    else
        extract_cmd="tar -xzf '$backup_to_restore' -C '$staging_dir'"
    fi

    if ! eval "$extract_cmd"; then
        error "Falha ao extrair o arquivo de backup. O arquivo pode estar corrompido ou a senha incorreta."
        return 1
    fi
    success "  -> Backup extraído com sucesso."

    local source_dir="$staging_dir/user_home/"
    if [ ! -d "$source_dir" ]; then
        error "Estrutura de backup inválida. Diretório 'user_home' não encontrado."
        return 1
    fi

    log "2. Sincronizando dados para o diretório HOME..."
    if rsync -a --info=progress2 "$source_dir" "$HOME/"; then
        success "🎉 Restauração das configurações locais concluída!"
        audit_log "RESTORE_LOCAL_SUCCESS" "Successfully restored $(basename "$backup_to_restore")"
    else
        error "Falha ao sincronizar os arquivos de backup para o diretório HOME."
        audit_log "RESTORE_LOCAL_FAIL" "Failed to restore $(basename "$backup_to_restore")"
        return 1
    fi
}

# Função para restaurar logs a partir de um arquivo de arquivamento
do_restore_logs() {
    if ! list_backups_by_type "logs_archive_" "Logs Arquivados"; then
        return 1
    fi

    echo ""
    read -p "Digite o número do backup de logs que deseja restaurar: " choice

    mapfile -t backups < <(ls -1t "$BACKUP_DIR"/logs_archive_*.tar.gz* 2>/dev/null)
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#backups[@]} ]; then
        error "Seleção inválida."
        return 1
    fi

    local backup_to_restore="${backups[$((choice-1))]}"
    local log_dir="${PROJECT_ROOT}/logs"

    subsection "Restaurando Backup de Logs"
    log "Backup selecionado: $(basename "$backup_to_restore")"
    audit_log "RESTORE_LOGS_START" "Backup: $(basename "$backup_to_restore")"

    warn "Esta operação irá sobrescrever o conteúdo do diretório de logs: $log_dir"
    if ! confirm_operation "Deseja continuar com a restauração?"; then
        log "Restauração de logs cancelada."
        audit_log "RESTORE_LOGS_CANCEL" "User cancelled operation"
        return 0
    fi

    progress "Extraindo logs do arquivo de arquivamento..."
    # O arquivamento foi feito com -C, então os caminhos são relativos ao diretório de logs.
    if tar -xzf "$backup_to_restore" -C "$log_dir/"; then
        success "🎉 Logs restaurados com sucesso para o diretório '$log_dir'."
        audit_log "RESTORE_LOGS_SUCCESS" "Successfully restored $(basename "$backup_to_restore")"
    else
        error "Falha ao extrair o arquivo de backup."
        warn "O arquivo pode estar corrompido."
        audit_log "RESTORE_LOGS_FAIL" "Failed to restore $(basename "$backup_to_restore")"
        return 1
    fi
}

# --- Menu Principal ---
main() {
    while true; do
        clear
        section "Gerenciador de Restauração - Cluster AI"
        echo "1. 🖧 Restaurar um Worker Remoto para um novo dispositivo"
        echo "2. 🖥️ Restaurar Backup Local (Configurações, Modelos, etc.)"
        echo "2. 🖥️ Restaurar Backup de Configurações Locais"
        echo "3. 📜 Restaurar Logs a partir de um Arquivo"
        echo "---"
        echo "3. ↩️ Voltar ao menu principal"
        read -p "Selecione uma opção [1-3]: " choice
        echo "0. ↩️ Voltar ao menu principal"
        read -p "Selecione uma opção [0-3]: " choice

        case $choice in
            1) do_restore_remote_worker ;;
            2) do_restore_local_config ;;
            3) break ;;
            3) do_restore_logs ;;
            0) break ;;
            *) warn "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main "$@"