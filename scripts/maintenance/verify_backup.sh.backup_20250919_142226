#!/bin/bash
# Script para Verificar a Integridade de Backups
# Descrição: Verifica um arquivo de backup usando seu checksum SHA256.

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

# --- Configurações ---
BACKUP_BASE_DIR="${PROJECT_ROOT}/backups"

# --- Funções ---

show_help() {
    echo "Uso: $0 [caminho_para_backup]"
    echo "Verifica a integridade de um arquivo de backup usando seu checksum SHA256."
    echo ""
    echo "Se nenhum caminho for fornecido, um menu interativo será exibido."
}

# Função para verificar um único arquivo de backup
verify_single_backup() {
    local backup_file="$1"
    local checksum_file="${backup_file}.sha256"

    subsection "Verificando: $(basename "$backup_file")"

    if [ ! -f "$backup_file" ]; then
        error "Arquivo de backup não encontrado: $backup_file"
        return 1
    fi

    if [ ! -f "$checksum_file" ]; then
        warn "Arquivo de checksum não encontrado: $checksum_file"
        info "Não é possível verificar a integridade deste backup."
        return 1
    fi

    # Lidar com arquivos criptografados
    local file_to_check="$backup_file"
    local temp_decrypted_file=""
    if [[ "$backup_file" == *.enc ]]; then
        if ! command_exists openssl; then
            error "Comando 'openssl' não encontrado. Não é possível verificar backup criptografado."
            return 1
        fi
        info "Este backup está criptografado."
        local password
        read -s -p "Digite a senha para descriptografar e verificar: " password
        echo
        if [ -z "$password" ]; then
            error "Senha não fornecida. Verificação cancelada."
            return 1
        fi

        temp_decrypted_file=$(mktemp)
        trap 'rm -f "$temp_decrypted_file"' EXIT

        progress "Descriptografando para verificação (arquivo temporário)..."
        if ! openssl enc -d -aes-256-cbc -pbkdf2 -in "$backup_file" -out "$temp_decrypted_file" -pass pass:"$password"; then
            error "Falha ao descriptografar. Senha incorreta ou arquivo corrompido."
            return 1
        fi
        file_to_check="$temp_decrypted_file"
    fi

    progress "Calculando checksum do arquivo..."
    if sha256sum --check --status "$checksum_file"; then
        success "✅ Integridade confirmada! O backup está consistente."
        audit_log "VERIFY_SUCCESS" "File: $(basename "$backup_file")"
    else
        error "❌ CORROMPIDO! A verificação de integridade falhou."
        warn "O arquivo de backup pode estar danificado ou foi modificado."
        audit_log "VERIFY_FAIL" "File: $(basename "$backup_file")"
    fi
}

# --- Execução ---
main() {
    section "Verificador de Integridade de Backup"

    if [ -n "${1:-}" ]; then
        verify_single_backup "$1"
        return
    fi

    # Menu interativo
    mapfile -t backups < <(find "$BACKUP_BASE_DIR" -name "*.tar.*" ! -name "*.sha256" -printf "%f\n" | sort -r)
    if [ ${#backups[@]} -eq 0 ]; then
        warn "Nenhum backup encontrado para verificar."
        return
    fi

    info "Selecione o backup que deseja verificar:"
    select backup_choice in "${backups[@]}"; do
        if [ -n "$backup_choice" ]; then
            verify_single_backup "${BACKUP_BASE_DIR}/${backup_choice}"
            break
        else
            error "Seleção inválida."
        fi
    done
}

main "$@"