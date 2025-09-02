#!/bin/bash
# Cluster Health Monitor - Integração do Health Check com Workers
# Versão: 1.0 - Monitoramento Integrado

set -euo pipefail

# ==================== CONFIGURAÇÃO ====================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"
HEALTH_CHECK_SCRIPT="${UTILS_DIR}/health_check.sh"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# Configurações
NODES_CONFIG_FILE="$HOME/.cluster_config/nodes_list.conf"
LOG_FILE="/tmp/cluster_health_monitor_$(date +%Y%m%d_%H%M%S).log"
REPORT_FILE="/tmp/cluster_health_report_$(date +%Y%m%d_%H%M%S).txt"

# ==================== FUNÇÕES ====================

show_help() {
    echo "Cluster Health Monitor - Monitoramento Integrado de Workers"
    echo
    echo "Uso: $0 [comando] [opções]"
    echo
    echo "Comandos:"
    echo "  local                 Executar health check apenas no nó local"
    echo "  remote                Executar health check em todos os workers remotos"
    echo "  all                   Executar health check local + todos os workers remotos"
    echo "  worker <host>         Executar health check em um worker específico"
    echo "  status                Mostrar status resumido de todos os nós"
    echo "  report                Gerar relatório detalhado de saúde do cluster"
    echo "  monitor               Modo de monitoramento contínuo"
    echo "  help                  Mostrar esta ajuda"
    echo
    echo "Opções:"
    echo "  --quiet, -q          Modo silencioso"
    echo "  --interval <seg>     Intervalo para monitoramento (padrão: 300s)"
    echo "  --output <arquivo>   Arquivo de saída para relatório"
    echo
    echo "Exemplos:"
    echo "  $0 local                    # Health check local"
    echo "  $0 remote                   # Health check em todos os workers"
    echo "  $0 worker worker1           # Health check em worker específico"
    echo "  $0 all                      # Health check completo"
    echo "  $0 monitor --interval 600   # Monitoramento contínuo a cada 10min"
}

# Executar health check local
run_local_health_check() {
    local quiet="${1:-false}"

    section "HEALTH CHECK LOCAL"
    info "Executando verificação de saúde no nó local..."

    if [ "$quiet" = true ]; then
        "$HEALTH_CHECK_SCRIPT" --quiet
    else
        "$HEALTH_CHECK_SCRIPT"
    fi

    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        success "✅ Health check local concluído com sucesso"
    else
        warn "⚠️  Health check local detectou problemas"
    fi

    return $exit_code
}

# Executar health check remoto em um worker específico
run_remote_worker_health_check() {
    local target_host="$1"
    local target_user="${2:-$USER}"
    local quiet="${3:-false}"

    subsection "Health Check Remoto: $target_user@$target_host"

    # Verificar conectividade SSH
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no "$target_user@$target_host" "echo 'SSH OK'" >/dev/null 2>&1; then
        error "❌ Falha na conexão SSH com $target_host"
        return 1
    fi

    # Verificar se o projeto existe
    if ! ssh "$target_user@$target_host" "test -d ~/Projetos/cluster-ai" >/dev/null 2>&1; then
        error "❌ Projeto Cluster AI não encontrado em $target_host"
        return 1
    fi

    # Executar health check remoto
    success "✅ Executando health check remoto em $target_host..."

    if [ "$quiet" = true ]; then
        ssh "$target_user@$target_host" "cd ~/Projetos/cluster-ai && ./scripts/utils/health_check.sh --quiet"
    else
        ssh "$target_user@$target_host" "cd ~/Projetos/cluster-ai && ./scripts/utils/health_check.sh"
    fi

    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        success "✅ Health check remoto concluído com sucesso em $target_host"
    else
        warn "⚠️  Health check remoto detectou problemas em $target_host"
    fi

    return $exit_code
}

# Executar health check em todos os workers remotos
run_all_remote_health_checks() {
    local quiet="${1:-false}"

    section "HEALTH CHECK REMOTO - TODOS OS WORKERS"

    # Verificar arquivo de configuração
    if [ ! -f "$NODES_CONFIG_FILE" ]; then
        error "Arquivo de configuração de nós não encontrado: $NODES_CONFIG_FILE"
        info "Execute: ./scripts/management/remote_worker_manager.sh help"
        return 1
    fi

    local total_workers=0
    local successful_checks=0
    local failed_checks=0

    while read -r hostname ip user port; do
        if [ -z "$hostname" ] || [[ "$hostname" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        ((total_workers++))

        if run_remote_worker_health_check "$hostname" "$user" "$quiet"; then
            ((successful_checks++))
        else
            ((failed_checks++))
        fi

        echo
    done < "$NODES_CONFIG_FILE"

    # Resumo
    subsection "Resumo dos Health Checks Remotos"
    echo "Total de workers: $total_workers"
    echo "Checks bem-sucedidos: $successful_checks"
    echo "Checks com falha: $failed_checks"

    if [ $failed_checks -gt 0 ]; then
        warn "⚠️  Alguns workers apresentaram problemas"
        return 1
    else
        success "✅ Todos os workers passaram no health check"
        return 0
    fi
}

# Executar health check completo (local + remoto)
run_complete_health_check() {
    local quiet="${1:-false}"

    section "HEALTH CHECK COMPLETO DO CLUSTER"

    local local_result=0
    local remote_result=0

    # Health check local
    if run_local_health_check "$quiet"; then
        success "✅ Nó local: OK"
    else
        error "❌ Nó local: PROBLEMAS DETECTADOS"
        local_result=1
    fi

    echo

    # Health check remoto
    if run_all_remote_health_checks "$quiet"; then
        success "✅ Workers remotos: OK"
    else
        error "❌ Workers remotos: PROBLEMAS DETECTADOS"
        remote_result=1
    fi

    # Resultado final
    echo
    if [ $local_result -eq 0 ] && [ $remote_result -eq 0 ]; then
        success "🎉 CLUSTER SAUDÁVEL - Todos os nós passaram nas verificações!"
        return 0
    else
        error "🚨 CLUSTER COM PROBLEMAS - Verifique os detalhes acima"
        return 1
    fi
}

# Mostrar status resumido
show_cluster_status() {
    section "STATUS RESUMIDO DO CLUSTER"

    # Status local
    echo "🏠 Nó Local:"
    if "$HEALTH_CHECK_SCRIPT" --quiet >/dev/null 2>&1; then
        success "   ✅ Saudável"
    else
        error "   ❌ Com problemas"
    fi

    # Status dos workers
    if [ -f "$NODES_CONFIG_FILE" ]; then
        echo
        echo "👥 Workers Remotos:"
        local worker_count=0
        local active_workers=0

        while read -r hostname ip user port; do
            if [ -z "$hostname" ] || [[ "$hostname" =~ ^[[:space:]]*# ]]; then
                continue
            fi

            ((worker_count++))
            if ssh -p "${port:-22}" -o ConnectTimeout=3 -o BatchMode=yes "$user@$hostname" "pgrep -f dask-worker >/dev/null 2>&1 && echo 'OK'" >/dev/null 2>&1; then
                success "   ✅ $hostname: Ativo"
                ((active_workers++))
            else
                error "   ❌ $hostname: Inativo/Problemas"
            fi
        done < "$NODES_CONFIG_FILE"

        echo
        echo "📊 Resumo: $active_workers/$worker_count workers ativos"
    else
        echo
        echo "👥 Workers Remotos: Nenhum configurado"
    fi
}

# Gerar relatório detalhado
generate_detailed_report() {
    local output_file="${1:-$REPORT_FILE}"

    section "GERANDO RELATÓRIO DETALHADO"

    {
        echo "========================================"
        echo "RELATÓRIO DE SAÚDE DO CLUSTER AI"
        echo "========================================"
        echo "Data/Hora: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Host: $(hostname)"
        echo "Usuário: $USER"
        echo ""

        echo "1. HEALTH CHECK LOCAL"
        echo "======================"
        "$HEALTH_CHECK_SCRIPT" --quiet 2>/dev/null || echo "ERRO: Falha no health check local"

        echo
        echo "2. HEALTH CHECK WORKERS REMOTOS"
        echo "================================"

        if [ -f "$NODES_CONFIG_FILE" ]; then
            local worker_num=1
            while read -r hostname ip user port; do
                if [ -z "$hostname" ] || [[ "$hostname" =~ ^[[:space:]]*# ]]; then
                    continue
                fi

                echo
                echo "Worker $worker_num: $hostname ($ip)"
                echo "---"

                if ssh -p "${port:-22}" -o ConnectTimeout=5 -o BatchMode=yes "$user@$hostname" "cd ~/Projetos/cluster-ai && ./scripts/utils/health_check.sh --quiet" 2>/dev/null; then
                    echo "Status: OK"
                else
                    echo "Status: PROBLEMAS DETECTADOS"
                fi

                ((worker_num++))
            done < "$NODES_CONFIG_FILE"
        else
            echo "Nenhum worker remoto configurado"
        fi

        echo
        echo "3. RECOMENDAÇÕES"
        echo "================="
        echo "- Execute '$0 all' para verificação completa"
        echo "- Use '$0 monitor' para monitoramento contínuo"
        echo "- Verifique logs em: $LOG_FILE"

    } > "$output_file"

    success "✅ Relatório gerado: $output_file"
    info "Para visualizar: cat $output_file"
}

# Modo de monitoramento contínuo
start_monitoring_mode() {
    local interval="${1:-300}"

    section "MODO DE MONITORAMENTO CONTÍNUO"
    info "Intervalo: $interval segundos"
    info "Pressione Ctrl+C para parar"
    echo

    trap 'echo -e "\n"; info "Monitoramento interrompido."; exit 0' SIGINT

    while true; do
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        echo "[$timestamp] Executando verificação de saúde..."

        if run_complete_health_check true; then
            success "[$timestamp] ✅ Cluster saudável"
        else
            error "[$timestamp] ❌ Problemas detectados no cluster"
        fi

        echo "Aguardando $interval segundos para próxima verificação..."
        sleep "$interval"
    done
}

# ==================== FUNÇÃO PRINCIPAL ====================

main() {
    # Processar argumentos
    local command=""
    local quiet=false
    local interval=300
    local output_file=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            local|remote|all|worker|status|report|monitor)
                command="$1"
                shift
                break
                ;;
            --quiet|-q)
                quiet=true
                shift
                ;;
            --interval)
                interval="$2"
                shift 2
                ;;
            --output)
                output_file="$2"
                shift 2
                ;;
            help|--help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Comando desconhecido: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Comando padrão
    if [ -z "$command" ]; then
        command="all"
    fi

    # Executar comando
    case "$command" in
        local)
            run_local_health_check "$quiet"
            ;;
        remote)
            run_all_remote_health_checks "$quiet"
            ;;
        all)
            run_complete_health_check "$quiet"
            ;;
        worker)
            if [ $# -lt 1 ]; then
                error "Host do worker não especificado"
                echo "Uso: $0 worker <hostname> [usuario]"
                exit 1
            fi
            local worker_host="$1"
            local worker_user="${2:-$USER}"
            run_remote_worker_health_check "$worker_host" "$worker_user" "$quiet"
            ;;
        status)
            show_cluster_status
            ;;
        report)
            generate_detailed_report "$output_file"
            ;;
        monitor)
            start_monitoring_mode "$interval"
            ;;
        *)
            error "Comando não reconhecido: $command"
            show_help
            exit 1
            ;;
    esac
}

# ==================== EXECUÇÃO ====================

# Verificar se o script de health check existe
if [ ! -f "$HEALTH_CHECK_SCRIPT" ]; then
    error "Script de health check não encontrado: $HEALTH_CHECK_SCRIPT"
    exit 1
fi

# Executar função principal
main "$@"
