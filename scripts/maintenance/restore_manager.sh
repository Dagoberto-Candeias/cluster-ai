#!/bin/bash
# Gerenciador de Restauração para o Cluster AI
# Descrição: Restaura backups de configurações, modelos e workers remotos.

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"
BACKUP_DIR="${PROJECT_ROOT}/backups"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

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

    local remote_tmp_file="/tmp/$(basename "$backup_to_restore")"
    
    log "1. Enviando arquivo de backup para $remote_host..."
    if scp -P "$remote_port" "$backup_to_restore" "$remote_user@$remote_host:$remote_tmp_file" >/dev/null; then
        success "  -> Arquivo de backup enviado com sucesso."
    else
        error "  -> Falha ao enviar o arquivo de backup. Verifique a conexão e as permissões."
        return 1
    fi
    
    log "2. Extraindo backup no dispositivo remoto..."
    local remote_cmd=""
    if [ -n "$password" ]; then
        # Descriptografa e extrai em um único pipeline no lado remoto
        log "O backup será descriptografado no dispositivo remoto."
        remote_cmd="openssl enc -d -aes-256-cbc -pbkdf2 -in '$remote_tmp_file' -pass pass:'$password' | tar -xz -C '$HOME' && rm '$remote_tmp_file'"
    else
        # Extração normal para backups não criptografados
        remote_cmd="tar -xzf '$remote_tmp_file' -C '$HOME' && rm '$remote_tmp_file'"
    fi
    
    if ssh -p "$remote_port" "$remote_user@$remote_host" "$remote_cmd"; then
        success "  -> Backup extraído e arquivo temporário removido com sucesso."
        audit_log "RESTORE_REMOTE_SUCCESS" "Successfully restored $(basename "$backup_to_restore") to $remote_host"
    else
        error "  -> Falha ao extrair o backup no dispositivo remoto."
        warn "  -> O arquivo temporário '$remote_tmp_file' pode não ter sido removido."
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

    log "Extraindo backup para o diretório HOME..."
    # O backup foi criado com um diretório 'user_home' na raiz.
    
    local restore_cmd=""
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
        # Pipeline: descriptografa e extrai
        restore_cmd="openssl enc -d -aes-256-cbc -pbkdf2 -in '$backup_to_restore' -pass pass:'$password' | tar -xz -C '$HOME' --strip-components=1 user_home"
    else
        restore_cmd="tar -xzf '$backup_to_restore' -C '$HOME' --strip-components=1 user_home"
    fi

    if eval "$restore_cmd"; then
        success "🎉 Restauração das configurações locais concluída!"
        audit_log "RESTORE_LOCAL_SUCCESS" "Successfully restored $(basename "$backup_to_restore")"
    else
        error "Falha ao extrair o backup. Verifique o arquivo e as permissões."
        audit_log "RESTORE_LOCAL_FAIL" "Failed to restore $(basename "$backup_to_restore")"
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
        echo "---"
        echo "3. ↩️ Voltar ao menu principal"
        read -p "Selecione uma opção [1-3]: " choice

        case $choice in
            1) do_restore_remote_worker ;;
            2) do_restore_local_config ;;
            3) break ;;
            *) warn "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

main "$@"