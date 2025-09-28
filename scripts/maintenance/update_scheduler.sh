#!/bin/bash
# =============================================================================
# Sistema de Agendamento de Atualizações - Cluster AI
# =============================================================================
# Gerencia agendamento de verificações e atualizações automáticas
#
# Autor: Cluster AI Team
# Data: 2025-01-20
# Versão: 1.0.0
# Arquivo: update_scheduler.sh
# =============================================================================

set -euo pipefail

# --- Configuração Inicial ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Carregar funções comuns
if [ ! -f "${SCRIPT_DIR}/../lib/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${SCRIPT_DIR}/../lib/common.sh"

# Carregar configuração
UPDATE_CONFIG="${PROJECT_ROOT}/config/update.conf"
if [ ! -f "$UPDATE_CONFIG" ]]; then
    error "Arquivo de configuração não encontrado: $UPDATE_CONFIG"
    exit 1
fi

# --- Constantes ---
LOG_DIR="${PROJECT_ROOT}/logs"
SCHEDULER_LOG="${LOG_DIR}/update_scheduler.log"
CRON_FILE="${PROJECT_ROOT}/config/cron_jobs"

# Criar diretórios necessários
mkdir -p "$LOG_DIR"
mkdir -p "$(dirname "$CRON_FILE")"

# --- Funções ---

# Função para log detalhado
log_scheduler() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" >> "$SCHEDULER_LOG"

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

# Função para verificar se cron está disponível
check_cron() {
    if ! command_exists crontab; then
        log_scheduler "ERROR" "Cron não está disponível no sistema"
        return 1
    fi

    return 0
}

# Função para gerar entrada cron
generate_cron_entry() {
    local schedule="$1"
    local command="$2"
    local comment="$3"

    echo "# $comment"
    echo "$schedule $command"
    echo
}

# Função para configurar cron jobs
setup_cron_jobs() {
    log_scheduler "INFO" "Configurando cron jobs para atualizações..."

    # Verificar se cron está disponível
    if ! check_cron; then
        log_scheduler "ERROR" "Não é possível configurar cron jobs"
        return 1
    fi

    # Criar arquivo temporário com jobs
    local temp_cron
    temp_cron=$(mktemp)

    {
        echo "# =============================================================================="
        echo "# Cron Jobs - Sistema de Auto Atualização - Cluster AI"
        echo "# =============================================================================="
        echo "# Gerado automaticamente em: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# Não edite este arquivo manualmente - use o script de agendamento"
        echo "# =============================================================================="
        echo

        # Job de verificação de atualizações
        local check_interval
        check_interval=$(get_update_config "GENERAL" "CHECK_INTERVAL")

        if [[ -n "$check_interval" && "$check_interval" -gt 0 ]]; then
            local check_schedule
            check_schedule="*/$check_interval * * * *"

            generate_cron_entry \
                "$check_schedule" \
                "cd '$PROJECT_ROOT' && bash scripts/update_checker.sh >> logs/update_checker.log 2>&1" \
                "Verificar atualizações disponíveis a cada $check_interval minutos"
        fi

        # Job de monitoramento (uma vez por hora)
        generate_cron_entry \
            "0 * * * *" \
            "cd '$PROJECT_ROOT' && bash scripts/monitor_worker_updates.sh check >> logs/monitor_updates.log 2>&1" \
            "Verificar e aplicar atualizações automáticas"

        # Job de limpeza de logs (diariamente às 2:00)
        generate_cron_entry \
            "0 2 * * *" \
            "cd '$PROJECT_ROOT' && find logs/ -name '*.log' -size +10M -delete >> logs/cleanup.log 2>&1" \
            "Limpar logs antigos maiores que 10MB"

        # Job de limpeza de backups (semanalmente aos domingos às 3:00)
        generate_cron_entry \
            "0 3 * * 0" \
            "cd '$PROJECT_ROOT' && bash scripts/backup_manager.sh cleanup >> logs/backup_cleanup.log 2>&1" \
            "Limpar backups antigos"

        # Job de verificação de integridade (diariamente às 4:00)
        generate_cron_entry \
            "0 4 * * *" \
            "cd '$PROJECT_ROOT' && bash scripts/maintenance/auto_updater.sh --integrity-check >> logs/integrity_check.log 2>&1" \
            "Verificar integridade do sistema"

    } > "$temp_cron"

    # Instalar cron jobs
    if crontab "$temp_cron" 2>/dev/null; then
        log_scheduler "INFO" "Cron jobs configurados com sucesso"
        success "Cron jobs configurados com sucesso"

        # Mostrar jobs instalados
        echo
        echo -e "${BOLD}${BLUE}CRON JOBS INSTALADOS:${NC}"
        crontab -l | grep -v "^#" | while read -r line; do
            [[ -n "$line" ]] && echo -e "  ${CYAN}▶${NC} $line"
        done
        echo

        # Limpar arquivo temporário
        rm -f "$temp_cron"

        return 0
    else
        log_scheduler "ERROR" "Falha ao instalar cron jobs"
        error "Falha ao instalar cron jobs"
        rm -f "$temp_cron"
        return 1
    fi
}

# Função para remover cron jobs
remove_cron_jobs() {
    log_scheduler "INFO" "Removendo cron jobs de atualização..."

    # Verificar se cron está disponível
    if ! check_cron; then
        return 1
    fi

    # Remover apenas os jobs relacionados ao sistema de atualização
    local temp_cron
    temp_cron=$(mktemp)

    # Obter cron atual
    crontab -l 2>/dev/null | grep -v "update_checker\|monitor_worker_updates\|backup_manager\|auto_updater" > "$temp_cron" 2>/dev/null || echo "" > "$temp_cron"

    # Instalar cron limpo
    if crontab "$temp_cron" 2>/dev/null; then
        log_scheduler "INFO" "Cron jobs removidos com sucesso"
        success "Cron jobs removidos com sucesso"
        rm -f "$temp_cron"
        return 0
    else
        log_scheduler "ERROR" "Falha ao remover cron jobs"
        error "Falha ao remover cron jobs"
        rm -f "$temp_cron"
        return 1
    fi
}

# Função para mostrar cron jobs atuais
show_cron_jobs() {
    echo -e "${BOLD}${BLUE}CRON JOBS DO SISTEMA DE ATUALIZAÇÃO:${NC}"
    echo

    if check_cron; then
        # Mostrar apenas jobs relacionados ao sistema de atualização
        crontab -l 2>/dev/null | grep -A1 -B1 "update_checker\|monitor_worker_updates\|backup_manager\|auto_updater" | grep -v "^--$" || echo "  Nenhum cron job encontrado"
    else
        echo -e "${RED}✗${NC} Cron não disponível"
    fi

    echo
}

# Função para verificar status do agendamento
check_schedule_status() {
    echo -e "${BOLD}${BLUE}STATUS DO AGENDAMENTO:${NC}"
    echo

    # Verificar cron jobs
    if check_cron; then
        local job_count
        job_count=$(crontab -l 2>/dev/null | grep -c "update_checker\|monitor_worker_updates\|backup_manager\|auto_updater" || echo "0")

        if [[ "$job_count" -gt 0 ]]; then
            echo -e "${GREEN}✓${NC} ${BOLD}Cron jobs configurados${NC} ($job_count jobs)"
        else
            echo -e "${YELLOW}⚠${NC} ${BOLD}Nenhum cron job configurado${NC}"
        fi
    else
        echo -e "${RED}✗${NC} ${BOLD}Cron não disponível${NC}"
    fi

    echo

    # Verificar se o monitor está rodando
    if [[ -f "${PROJECT_ROOT}/.monitor_updates_pid" ]]; then
        local pid
        pid=$(cat "${PROJECT_ROOT}/.monitor_updates_pid" 2>/dev/null || echo "")

        if [[ -n "$pid" ]] && ps -p "$pid" >/dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} ${BOLD}Monitor de atualizações rodando${NC} (PID: $pid)"
        else
            echo -e "${YELLOW}⚠${NC} ${BOLD}Monitor de atualizações não está rodando${NC}"
        fi
    else
        echo -e "${YELLOW}⚠${NC} ${BOLD}Monitor de atualizações não está rodando${NC}"
    fi

    echo

    # Mostrar próxima verificação
    local check_interval
    check_interval=$(get_update_config "GENERAL" "CHECK_INTERVAL")

    if [[ -n "$check_interval" && "$check_interval" -gt 0 ]]; then
        echo -e "${CYAN}⏰${NC} ${BOLD}Próxima verificação:${NC} A cada $check_interval minutos"
    fi

    echo
}

# Função para configurar agendamento otimizado
setup_optimized_schedule() {
    log_scheduler "INFO" "Configurando agendamento otimizado..."

    # Configurar cron jobs
    if setup_cron_jobs; then
        log_scheduler "INFO" "Agendamento otimizado configurado com sucesso"
        success "Agendamento otimizado configurado com sucesso"

        # Iniciar monitor se não estiver rodando
        if [[ ! -f "${PROJECT_ROOT}/.monitor_updates_pid" ]] || ! ps -p "$(cat "${PROJECT_ROOT}/.monitor_updates_pid" 2>/dev/null)" >/dev/null 2>&1; then
            log_scheduler "INFO" "Iniciando monitor de atualizações..."
            bash "${SCRIPT_DIR}/../monitor_worker_updates.sh" start
        fi

        return 0
    else
        log_scheduler "ERROR" "Falha ao configurar agendamento otimizado"
        error "Falha ao configurar agendamento otimizado"
        return 1
    fi
}

# Função para verificar integridade do agendamento
verify_schedule_integrity() {
    log_scheduler "INFO" "Verificando integridade do agendamento..."

    local issues_found=0

    # Verificar se cron jobs estão corretos
    if check_cron; then
        local expected_jobs=("update_checker" "monitor_worker_updates" "backup_manager")
        for job in "${expected_jobs[@]}"; do
            if ! crontab -l 2>/dev/null | grep -q "$job"; then
                log_scheduler "WARN" "Cron job não encontrado: $job"
                ((issues_found++))
            fi
        done
    fi

    # Verificar se scripts existem
    local required_scripts=(
        "scripts/update_checker.sh"
        "scripts/monitor_worker_updates.sh"
        "scripts/backup_manager.sh"
        "scripts/maintenance/auto_updater.sh"
    )

    for script in "${required_scripts[@]}"; do
        if [[ ! -f "$PROJECT_ROOT/$script" ]]; then
            log_scheduler "ERROR" "Script não encontrado: $script"
            ((issues_found++))
        fi
    done

    # Verificar configuração
    if [[ ! -f "$UPDATE_CONFIG" ]]; then
        log_scheduler "ERROR" "Arquivo de configuração não encontrado: $UPDATE_CONFIG"
        ((issues_found++))
    fi

    if [[ $issues_found -eq 0 ]]; then
        log_scheduler "INFO" "Verificação de integridade concluída - tudo OK"
        success "Integridade do agendamento verificada com sucesso"
        return 0
    else
        log_scheduler "WARN" "Encontrados $issues_found problemas de integridade"
        warn "Encontrados $issues_found problemas - execute 'setup' para corrigir"
        return 1
    fi
}

# Função principal
main() {
    # Verificar argumentos
    case "${1:-status}" in
        "setup"|"install")
            setup_optimized_schedule
            ;;
        "remove"|"uninstall")
            remove_cron_jobs
            ;;
        "show"|"list")
            show_cron_jobs
            ;;
        "status")
            check_schedule_status
            ;;
        "verify"|"check")
            verify_schedule_integrity
            ;;
        "restart")
            remove_cron_jobs
            sleep 2
            setup_optimized_schedule
            ;;
        *)
            echo "Uso: $0 [setup|remove|show|status|verify|restart]"
            echo
            echo "Comandos:"
            echo "  setup   - Configurar agendamento otimizado"
            echo "  remove  - Remover todos os cron jobs"
            echo "  show    - Mostrar cron jobs atuais"
            echo "  status  - Verificar status do agendamento"
            echo "  verify  - Verificar integridade do agendamento"
            echo "  restart - Reiniciar agendamento"
            exit 1
            ;;
    esac
}

# Executar se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
