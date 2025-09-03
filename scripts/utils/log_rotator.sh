#!/bin/bash
# Script para rotacionar e arquivar logs de auditoria do Cluster AI

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado em ${UTILS_DIR}/common.sh"
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Constantes ---
LOG_DIR="${PROJECT_ROOT}/logs"
AUDIT_LOG_FILE="${LOG_DIR}/audit.log"
ARCHIVE_DIR="${LOG_DIR}/archive"
MAX_LOG_SIZE_KB=1024 # Rotacionar quando o log atingir 1MB
RETENTION_DAYS=30    # Manter arquivos de log por 30 dias

# --- Funções ---

# Rotaciona o log de auditoria se ele exceder o tamanho máximo
rotate_log() {
    section "Verificando Log de Auditoria para Rotação"

    if [ ! -f "$AUDIT_LOG_FILE" ]; then
        info "Nenhum arquivo de log de auditoria ($AUDIT_LOG_FILE) encontrado. Nada a fazer."
        return 0
    fi

    local current_size_kb
    current_size_kb=$(du -k "$AUDIT_LOG_FILE" | cut -f1)

    log "Tamanho atual do log: ${current_size_kb}KB. Limite: ${MAX_LOG_SIZE_KB}KB."

    if [ "$current_size_kb" -lt "$MAX_LOG_SIZE_KB" ]; then
        success "O log de auditoria está dentro do limite de tamanho. Nenhuma rotação necessária."
        return 0
    fi

    warn "O log de auditoria excedeu o tamanho máximo. Iniciando rotação..."
    mkdir -p "$ARCHIVE_DIR"

    local timestamp
    timestamp=$(date +%Y%m%d-%H%M%S)
    local archive_file="${ARCHIVE_DIR}/audit-${timestamp}.log"

    # Move e comprime o log
    log "Movendo $AUDIT_LOG_FILE para $archive_file"
    mv "$AUDIT_LOG_FILE" "$archive_file"
    
    log "Comprimindo o arquivo de log arquivado..."
    gzip "$archive_file"

    # Cria um novo arquivo de log vazio
    touch "$AUDIT_LOG_FILE"
    chmod 644 "$AUDIT_LOG_FILE" # Garante permissões corretas

    success "Log rotacionado e arquivado com sucesso em: ${archive_file}.gz"
}

# Limpa arquivos de log arquivados mais antigos que o período de retenção
cleanup_old_logs() {
    section "Limpando Logs Antigos"

    if [ ! -d "$ARCHIVE_DIR" ]; then
        info "Diretório de arquivo não encontrado. Nenhum log antigo para limpar."
        return 0
    fi

    log "Procurando por logs arquivados com mais de $RETENTION_DAYS dias em $ARCHIVE_DIR..."
    
    # -mtime +N significa "modificado há mais de N*24 horas"
    local old_logs_count
    old_logs_count=$(find "$ARCHIVE_DIR" -name "audit-*.log.gz" -mtime "+$RETENTION_DAYS" -print | wc -l)

    if [ "$old_logs_count" -gt 0 ]; then
        warn "Encontrados $old_logs_count logs antigos para remover."
        find "$ARCHIVE_DIR" -name "audit-*.log.gz" -mtime "+$RETENTION_DAYS" -print -delete
        success "Logs antigos removidos com sucesso."
    else
        success "Nenhum log antigo para remover."
    fi
}

# --- Menu Principal ---
main() {
    rotate_log
    cleanup_old_logs
    section "Processo de gerenciamento de logs concluído."
}

main "$@"
