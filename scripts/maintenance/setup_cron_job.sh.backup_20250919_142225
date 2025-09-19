#!/bin/bash
# Script para configurar um cron job para executar a limpeza semanalmente.

set -euo pipefail

# =============================================================================
# CONFIGURAÇÃO
# =============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB_DIR="${PROJECT_ROOT}/scripts/lib"

# Carregar funções comuns
if [ ! -f "${LIB_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado em $LIB_DIR."
    exit 1
fi
source "${LIB_DIR}/common.sh"

# --- Configuração do Cron Job ---
MANAGER_SCRIPT="${PROJECT_ROOT}/manager.sh"
CRON_LOG_FILE="${PROJECT_ROOT}/logs/cron_cleanup.log"
# Executar todo domingo às 3:00 da manhã
CRON_SCHEDULE="0 3 * * 0"
CRON_COMMAND="${MANAGER_SCRIPT} cleanup --yes"
CRON_JOB="${CRON_SCHEDULE} cd ${PROJECT_ROOT} && ${CRON_COMMAND} >> ${CRON_LOG_FILE} 2>&1"

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    section "Configurando Cron Job para Limpeza Semanal"

    if ! command_exists crontab; then
        error "Comando 'crontab' não encontrado. Não é possível agendar a tarefa."
        info "Instale o cliente cron do seu sistema (ex: sudo apt install cron)."
        return 1
    fi

    # Verificar se o cron job já existe para evitar duplicatas
    if crontab -l 2>/dev/null | grep -qF -- "$CRON_COMMAND"; then
        success "O cron job para limpeza semanal já está configurado."
        info "Para editar, use o comando: crontab -e"
        return 0
    fi

    info "Adicionando o seguinte cron job ao seu crontab:"
    echo "  -> ${CRON_JOB}"

    if confirm_operation "Deseja continuar?"; then
        # Adiciona o novo cron job sem remover os existentes
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        success "Cron job configurado com sucesso!"
        info "A limpeza será executada todo domingo às 3:00 da manhã."
        info "A saída do cron job será registrada em: ${CRON_LOG_FILE}"
    else
        warn "Configuração do cron job cancelada."
    fi
}

main "$@"