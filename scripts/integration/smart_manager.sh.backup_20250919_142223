#!/bin/bash
#
# Gerenciador Inteligente Integrado
# Combina gestão de modelos, monitoramento e automação
#

set -euo pipefail

# Carregar funções comuns
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# Caminhos dos scripts
MODEL_MANAGER="${PROJECT_ROOT}/scripts/ollama/model_manager.sh"
ADVANCED_DASHBOARD="${PROJECT_ROOT}/scripts/monitoring/advanced_dashboard.sh"

# Configurações
CONFIG_FILE="${PROJECT_ROOT}/config/smart_manager.conf"
LOG_FILE="${PROJECT_ROOT}/logs/smart_manager.log"

# Criar arquivo de configuração se não existir
create_default_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << EOF
# Configuração do Gerenciador Inteligente

# Gestão de Modelos
AUTO_CLEANUP_DAYS=30
CACHE_ENABLED=true
METRICS_ENABLED=true

# Monitoramento
MONITORING_INTERVAL=300
ALERT_CPU_THRESHOLD=90
ALERT_MEMORY_THRESHOLD=90
ALERT_DISK_THRESHOLD=90

# Automação
AUTO_START_SERVICES=true
SCHEDULED_MAINTENANCE="02:00"
BACKUP_ENABLED=true
BACKUP_INTERVAL_DAYS=7

# Logs
LOG_LEVEL=INFO
LOG_MAX_SIZE_MB=100
LOG_RETENTION_DAYS=30
EOF
        log "Arquivo de configuração criado: $CONFIG_FILE"
    fi
}

# Função de logging
smart_log() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
    echo -e "${CYAN}[SMART_MANAGER]${NC} $message"
}

# Função para verificar saúde do sistema
check_system_health() {
    subsection "🏥 Verificação de Saúde do Sistema"

    local issues_found=0

    # Verificar espaço em disco
    local disk_usage
    disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $disk_usage -gt 90 ]]; then
        warn "Espaço em disco crítico: ${disk_usage}%"
        ((issues_found++))
    fi

    # Verificar memória
    local mem_usage
    mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2 }')
    if [[ $mem_usage -gt 90 ]]; then
        warn "Uso de memória alto: ${mem_usage}%"
        ((issues_found++))
    fi

    # Verificar serviços críticos
    if ! pgrep -f "dask-scheduler" > /dev/null; then
        warn "Dask Scheduler não está rodando"
        ((issues_found++))
    fi

    if ! pgrep -f "ollama serve" > /dev/null && ! sudo systemctl is-active --quiet ollama 2>/dev/null; then
        warn "Ollama não está rodando"
        ((issues_found++))
    fi

    if [[ $issues_found -eq 0 ]]; then
        success "Sistema saudável - nenhum problema detectado"
    else
        warn "$issues_found problema(s) encontrado(s)"
    fi

    return $issues_found
}

# Função para otimização automática
auto_optimize() {
    subsection "⚡ Otimização Automática"

    # Limpeza de modelos não utilizados
    if [[ -x "$MODEL_MANAGER" ]]; then
        info "Executando limpeza de modelos..."
        bash "$MODEL_MANAGER" cleanup 30
    fi

    # Otimização de disco
    if [[ -x "$MODEL_MANAGER" ]]; then
        info "Otimizando uso de disco..."
        bash "$MODEL_MANAGER" optimize
    fi

    # Limpeza de logs antigos
    info "Limpando logs antigos..."
    find "${PROJECT_ROOT}/logs" -name "*.log" -mtime +30 -delete 2>/dev/null || true

    success "Otimização automática concluída"
}

# Função para relatório inteligente
generate_smart_report() {
    subsection "📊 Relatório Inteligente do Sistema"

    local report_file="${PROJECT_ROOT}/reports/smart_report_$(date +%Y%m%d_%H%M%S).md"

    {
        echo "# Relatório Inteligente do Sistema"
        echo "Gerado em: $(date)"
        echo

        echo "## 📈 Status dos Serviços"
        echo

        # Status do Dask
        if pgrep -f "dask-scheduler" > /dev/null; then
            echo "✅ **Dask Scheduler**: Rodando"
            if command_exists curl && curl -s "http://localhost:8787" > /dev/null 2>&1; then
                local workers
                workers=$(curl -s "http://localhost:8787/workers" | jq '. | length' 2>/dev/null || echo "N/A")
                echo "   - Workers ativos: $workers"
            fi
        else
            echo "❌ **Dask Scheduler**: Parado"
        fi
        echo

        # Status do Ollama
        if pgrep -f "ollama serve" > /dev/null || sudo systemctl is-active --quiet ollama 2>/dev/null; then
            echo "✅ **Ollama**: Rodando"
            if command_exists ollama; then
                local models_count
                models_count=$(ollama list 2>/dev/null | wc -l)
                models_count=$((models_count - 1))
                echo "   - Modelos instalados: $models_count"
            fi
        else
            echo "❌ **Ollama**: Parado"
        fi
        echo

        echo "## 💾 Recursos do Sistema"
        echo
        echo "### CPU e Memória"
        echo "\`\`\`"
        top -bn1 | head -5
        echo "\`\`\`"
        echo

        echo "### Disco"
        echo "\`\`\`"
        df -h /
        echo "\`\`\`"
        echo

        echo "## 🤖 Modelos IA"
        if [[ -x "$MODEL_MANAGER" ]]; then
            echo "### Modelos com Mais Uso"
            echo "\`\`\`"
            bash "$MODEL_MANAGER" list | head -10
            echo "\`\`\`"
        fi
        echo

        echo "## 📋 Recomendações"
        echo

        # Análise e recomendações
        local disk_usage mem_usage
        disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
        mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2 }')

        if [[ $disk_usage -gt 85 ]]; then
            echo "⚠️  **Disco quase cheio**: Considere limpeza de modelos não utilizados"
        fi

        if [[ $mem_usage -gt 85 ]]; then
            echo "⚠️  **Memória alta**: Monitore processos e considere otimização"
        fi

        if [[ ! -d "${PROJECT_ROOT}/backups" ]] || [[ -z "$(find "${PROJECT_ROOT}/backups" -name "*.tar.gz" -mtime -7 2>/dev/null)" ]]; then
            echo "💡 **Backup recomendado**: Último backup há mais de 7 dias"
        fi

        echo
        echo "---"
        echo "*Relatório gerado automaticamente pelo Smart Manager*"

    } > "$report_file"

    success "Relatório inteligente gerado: $report_file"
    smart_log "INFO" "Relatório inteligente gerado: $report_file"
}

# Função para manutenção agendada
scheduled_maintenance() {
    subsection "🛠️ Manutenção Agendada"

    # Verificar se é hora da manutenção
    local scheduled_time
    scheduled_time=$(grep "^SCHEDULED_MAINTENANCE=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 || echo "02:00")
    local current_time
    current_time=$(date +%H:%M)

    if [[ "$current_time" != "$scheduled_time" ]]; then
        info "Manutenção agendada para $scheduled_time (atual: $current_time)"
        return 0
    fi

    info "Iniciando manutenção agendada..."

    # Backup automático
    if [[ "$(grep "^BACKUP_ENABLED=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 || echo "true")" == "true" ]]; then
        info "Executando backup automático..."
        bash "${PROJECT_ROOT}/scripts/backup/create_backup.sh" 2>/dev/null || warn "Backup falhou"
    fi

    # Otimização automática
    auto_optimize

    # Gerar relatório
    generate_smart_report

    success "Manutenção agendada concluída"
    smart_log "INFO" "Manutenção agendada concluída com sucesso"
}

# Função para dashboard integrado
integrated_dashboard() {
    clear
    section "🚀 Dashboard Integrado - Smart Manager"
    echo "Sistema inteligente de monitoramento e gestão"
    echo "Atualizado em: $(date)"
    echo

    # Status geral
    subsection "📊 Status Geral"

    # Verificar saúde
    if check_system_health; then
        echo -e "  ${GREEN}● Sistema saudável${NC}"
    else
        echo -e "  ${RED}● Atenção necessária${NC}"
    fi
    echo

    # Dashboard em tempo real
    if [[ -x "$ADVANCED_DASHBOARD" ]]; then
        subsection "📈 Métricas em Tempo Real"
        bash "$ADVANCED_DASHBOARD" live | head -20
    fi

    # Ações rápidas
    subsection "⚡ Ações Rápidas Disponíveis"
    echo "  1. Verificar saúde completa do sistema"
    echo "  2. Executar otimização automática"
    echo "  3. Gerar relatório inteligente"
    echo "  4. Gestão de modelos IA"
    echo "  5. Monitoramento contínuo"
    echo "  6. Manutenção agendada"
    echo
    read -p "Escolha uma ação (1-6) ou Enter para sair: " choice

    case "$choice" in
        1) check_system_health ;;
        2) auto_optimize ;;
        3) generate_smart_report ;;
        4) [[ -x "$MODEL_MANAGER" ]] && bash "$MODEL_MANAGER" ;;
        5) [[ -x "$ADVANCED_DASHBOARD" ]] && bash "$ADVANCED_DASHBOARD" continuous ;;
        6) scheduled_maintenance ;;
        *) info "Saindo..." ;;
    esac
}

# Função principal
main() {
    local command="${1:-dashboard}"

    # Criar configuração padrão se necessário
    create_default_config

    case "$command" in
        "health")
            check_system_health
            ;;
        "optimize")
            auto_optimize
            ;;
        "report")
            generate_smart_report
            ;;
        "maintenance")
            scheduled_maintenance
            ;;
        "dashboard")
            integrated_dashboard
            ;;
        "auto")
            # Modo automático - executar verificações e otimizações
            check_system_health
            auto_optimize
            ;;
        "help"|*)
            section "🚀 Gerenciador Inteligente Integrado"
            echo
            echo "Uso: $0 <comando>"
            echo
            echo "Comandos disponíveis:"
            echo "  dashboard     - Dashboard integrado interativo"
            echo "  health        - Verificar saúde do sistema"
            echo "  optimize      - Executar otimização automática"
            echo "  report        - Gerar relatório inteligente"
            echo "  maintenance   - Executar manutenção agendada"
            echo "  auto          - Modo automático (verificação + otimização)"
            echo "  help          - Mostra esta ajuda"
            echo
            echo "Recursos:"
            echo "  • Dashboard integrado com métricas em tempo real"
            echo "  • Verificação automática de saúde do sistema"
            echo "  • Otimização inteligente de recursos"
            echo "  • Relatórios detalhados com recomendações"
            echo "  • Manutenção agendada automática"
            echo "  • Integração com gestão de modelos IA"
            ;;
    esac
}

main "$@"
