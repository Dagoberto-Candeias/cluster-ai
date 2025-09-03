#!/bin/bash
# Script para configurar um cron job para rotacionar logs automaticamente.

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

# --- Configuração do Cron Job ---
LOG_ROTATOR_SCRIPT="${PROJECT_ROOT}/scripts/maintenance/log_rotator.sh"
CRON_LOG_FILE="${PROJECT_ROOT}/logs/cron_jobs.log"
# Executar todo dia às 3:00 da manhã
CRON_SCHEDULE="0 3 * * *"
CRON_COMMAND="cd ${PROJECT_ROOT} && bash ${LOG_ROTATOR_SCRIPT} >> ${CRON_LOG_FILE} 2>&1"
CRON_JOB="${CRON_SCHEDULE} ${CRON_COMMAND}"

# --- Funções ---

main() {
    section "Configurando Cron Job para Rotação de Logs"

    if ! command_exists crontab; then
        error "Comando 'crontab' não encontrado. Não é possível agendar a tarefa."
        info "Instale o cliente cron do seu sistema (ex: sudo apt install cron)."
        return 1
    fi

    # Verificar se o cron job já existe para evitar duplicatas
    if crontab -l 2>/dev/null | grep -qF -- "$LOG_ROTATOR_SCRIPT"; then
        success "O cron job para rotação de logs já está configurado."
        info "Para editar, use o comando: crontab -e"
        return 0
    fi

    log "Adicionando o seguinte cron job ao seu crontab:"
    echo "  -> ${CRON_JOB}"

    if confirm_operation "Deseja continuar?"; then
        # Adiciona o novo cron job sem remover os existentes
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        
        if crontab -l | grep -qF -- "$LOG_ROTATOR_SCRIPT"; then
            success "Cron job configurado com sucesso!"
            log "Os logs serão rotacionados diariamente às 3:00 da manhã."
            log "A saída do cron job será registrada em: ${CRON_LOG_FILE}"
        else
            error "Falha ao configurar o cron job."
        fi
    else
        warn "Configuração do cron job cancelada."
    fi
}

main "$@"