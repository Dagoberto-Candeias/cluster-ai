#!/bin/bash
# Script para verificar a integridade de um arquivo de backup.
# Garante que o arquivo .tar.gz não está corrompido e pode ser lido.

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="${PROJECT_ROOT}/scripts/lib"
BACKUP_DIR="${PROJECT_ROOT}/backups"

# Carregar funções comuns
if [ ! -f "${LIB_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado em $LIB_DIR."
    exit 1
fi
source "${LIB_DIR}/common.sh"

# --- Funções ---

# Lista todos os backups disponíveis
list_all_backups() {
    section "Backups Disponíveis para Verificação"
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR"/*.tar.gz* 2>/dev/null)" ]; then
        warn "Nenhum backup encontrado em $BACKUP_DIR."
        return 1
    fi

    local i=1
    mapfile -t backups < <(ls -1t "$BACKUP_DIR"/*.tar.gz*)
    for backup in "${backups[@]}"; do
        local size
        size=$(du -h "$backup" | cut -f1)
        echo "  $i) $(basename "$backup") ($size)"
        ((i++))
    done
    return 0
}

# Verifica a integridade de um único arquivo de backup
verify_backup_integrity() {
    local backup_file="$1"
    subsection "Verificando: $(basename "$backup_file")"
    audit_log "VERIFY_START" "Backup: $(basename "$backup_file")"

    progress "Verificando se o arquivo existe e é legível..."
    if [ ! -r "$backup_file" ]; then
        error "Arquivo de backup não encontrado ou sem permissão de leitura: $backup_file"
        return 1
    fi
    success "Arquivo encontrado e legível."

    if [[ "$backup_file" == *.enc ]]; then
        subsection "Verificando Backup Criptografado"
        if ! command_exists openssl; then
            error "Comando 'openssl' não encontrado. Não é possível verificar o backup."
            return 1
        fi

        local password
        read -s -p "Digite a senha do backup para verificação: " password
        echo
        if [ -z "$password" ]; then
            error "A senha não pode estar em branco. Abortando."
            return 1
        fi

        progress "Tentando descriptografar e verificar a integridade (Gzip e Tar)..."
        # Este pipeline descriptografa, descomprime e lista o conteúdo para /dev/null.
        # Uma falha em qualquer etapa (senha, Gzip, Tar) resultará em um código de saída diferente de zero.
        if openssl enc -d -aes-256-cbc -pbkdf2 -in "$backup_file" -pass pass:"$password" 2>/dev/null | tar -tz > /dev/null; then
            success "🎉 O arquivo de backup criptografado '$(basename "$backup_file")' parece estar íntegro."
            audit_log "VERIFY_SUCCESS" "Encrypted backup $(basename "$backup_file") is integral"
        else
            error "Arquivo corrompido ou senha incorreta! A verificação de integridade falhou."
            audit_log "VERIFY_FAIL" "Encrypted backup $(basename "$backup_file") failed integrity check"
            return 1
        fi
    else
        subsection "Verificando Backup Não Criptografado"
        progress "Verificando a integridade da compressão (Gzip)..."
        if ! gzip -t "$backup_file"; then
            error "Arquivo corrompido! Falha na verificação do Gzip."
            audit_log "VERIFY_FAIL" "Backup $(basename "$backup_file") failed Gzip check"
            return 1
        fi
        success "Integridade do Gzip está OK."

        progress "Verificando a integridade da estrutura (Tar)..."
        if ! tar -tzf "$backup_file" > /dev/null; then
            error "Arquivo corrompido! Falha na verificação da estrutura do Tar."
            audit_log "VERIFY_FAIL" "Backup $(basename "$backup_file") failed Tar check"
            return 1
        fi
        success "Integridade do Tar está OK."
        echo
        success "🎉 O arquivo de backup '$(basename "$backup_file")' parece estar íntegro."
        audit_log "VERIFY_SUCCESS" "Backup $(basename "$backup_file") is integral"
    fi
}

# --- Menu Principal ---
main() {
    section "🔍 Verificador de Integridade de Backup"

    if ! list_all_backups; then
        return 1
    fi

    echo ""
    read -p "Digite o número do backup que deseja verificar (ou 0 para sair): " choice

    if [[ "$choice" -eq 0 ]]; then
        info "Verificação cancelada."
        exit 0
    fi

    mapfile -t backups < <(ls -1t "$BACKUP_DIR"/*.tar.gz* 2>/dev/null)
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#backups[@]} ]; then
        error "Seleção inválida."
        return 1
    fi

    local backup_to_verify="${backups[$((choice-1))]}"
    verify_backup_integrity "$backup_to_verify"
}

main "$@"