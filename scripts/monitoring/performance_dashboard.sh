#!/bin/bash
# Performance Dashboard em Tempo Real
# Dashboard interativo para monitoramento de performance do Cluster AI

set -euo pipefail

# ==================== CONFIGURAÇÃO ====================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MONITOR_DIR="${PROJECT_ROOT}/scripts/monitoring"
LOGS_DIR="${PROJECT_ROOT}/logs"
METRICS_DIR="${PROJECT_ROOT}/metrics"

# Arquivos de configuração
MONITOR_CONFIG="${PROJECT_ROOT}/config/monitor.conf"
DASHBOARD_CONFIG="${PROJECT_ROOT}/config/dashboard.conf"

# Arquivos de dados
METRICS_FILE="${METRICS_DIR}/cluster_metrics.json"
PERFORMANCE_LOG="${LOGS_DIR}/performance_history.log"
ALERTS_LOG="${LOGS_DIR}/alerts.log"

# Configurações do dashboard
REFRESH_INTERVAL=5
HISTORY_LENGTH=100
ALERT_THRESHOLD_HIGH=80
ALERT_THRESHOLD_CRITICAL=90

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Arrays para armazenar histórico
declare -a CPU_HISTORY
declare -a MEMORY_HISTORY
declare -a DISK_HISTORY
declare -a NETWORK_HISTORY

# ==================== FUNÇÕES UTILITÁRIAS ====================

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Função para obter status colorido baseado no valor
get_status_color() {
    local value="$1"
    local threshold_high="$2"
    local threshold_critical="$3"

    if (( $(echo "$value >= $threshold_critical" | bc -l) )); then
        echo "$RED"
    elif (( $(echo "$value >= $threshold_high" | bc -l) )); then
        echo "$YELLOW"
    else
        echo "$GREEN"
    fi
}

# Função para criar gráfico ASCII simples
create_ascii_chart() {
    local values=("$@")
    local max_value=100
    local chart_width=20
    local chart_height=5

    # Encontrar valor máximo nos últimos valores
    local recent_values=("${values[@]: -20}")  # Últimos 20 valores
    local local_max=0
    for val in "${recent_values[@]}"; do
        if (( $(echo "$val > $local_max" | bc -l) )); then
            local_max=$val
        fi
    done

    if (( $(echo "$local_max > 0" | bc -l) )); then
        max_value=$local_max
    fi

    # Criar gráfico
    for ((i=chart_height; i>=0; i--)); do
        local threshold=$(( (i * max_value) / chart_height ))
        printf "%3d| " "$threshold"

        for val in "${recent_values[@]}"; do
            if (( $(echo "$val >= $threshold" | bc -l) )); then
                printf "█"
            else
                printf " "
            fi
        done
        printf "\n"
    done

    printf "    +"
    for ((i=0; i<chart_width; i++)); do
        printf "-"
    done
    printf "\n"
}

# ==================== FUNÇÕES DE COLETA DE MÉTRICAS ====================

collect_dashboard_metrics() {
    # CPU
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' | xargs printf "%.1f")

    # Memória
    local mem_usage
    mem_usage=$(free | awk 'NR==2{printf "%.1f", $3*100/$2}')

    # Disco
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//' | xargs printf "%.1f")

    # Rede (simplificado)
    local network_rx
    network_rx=$(cat /proc/net/dev | grep -E "^[[:space:]]*eth0|^[[:space:]]*wlan0|^[[:space:]]*enp" | head -1 | awk '{print $2}' | xargs printf "%.0f")

    # Atualizar histórico
    CPU_HISTORY+=("$cpu_usage")
    MEMORY_HISTORY+=("$mem_usage")
    DISK_HISTORY+=("$disk_usage")
    NETWORK_HISTORY+=("$network_rx")

    # Manter apenas os últimos valores
    if [ ${#CPU_HISTORY[@]} -gt $HISTORY_LENGTH ]; then
        CPU_HISTORY=("${CPU_HISTORY[@]:1}")
        MEMORY_HISTORY=("${MEMORY_HISTORY[@]:1}")
        DISK_HISTORY=("${DISK_HISTORY[@]:1}")
        NETWORK_HISTORY=("${NETWORK_HISTORY[@]:1}")
    fi

    # Salvar no log de performance
    echo "$(date +%s),$cpu_usage,$mem_usage,$disk_usage,$network_rx" >> "$PERFORMANCE_LOG"
}

# ==================== FUNÇÕES DE DASHBOARD ====================

show_header() {
    clear
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                        CLUSTER AI PERFORMANCE DASHBOARD                   ║${NC}"
    echo -e "${PURPLE}╠══════════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${PURPLE}║ $(date '+%Y-%m-%d %H:%M:%S') | Refresh: ${REFRESH_INTERVAL}s | History: ${#CPU_HISTORY[@]} samples ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

show_system_overview() {
    local cpu_color mem_color disk_color

    # Valores atuais
    local cpu_current=${CPU_HISTORY[-1]:-0}
    local mem_current=${MEMORY_HISTORY[-1]:-0}
    local disk_current=${DISK_HISTORY[-1]:-0}

    # Cores baseadas nos thresholds
    cpu_color=$(get_status_color "$cpu_current" "$ALERT_THRESHOLD_HIGH" "$ALERT_THRESHOLD_CRITICAL")
    mem_color=$(get_status_color "$mem_current" "$ALERT_THRESHOLD_HIGH" "$ALERT_THRESHOLD_CRITICAL")
    disk_color=$(get_status_color "$disk_current" "$ALERT_THRESHOLD_HIGH" "$ALERT_THRESHOLD_CRITICAL")

    echo -e "${WHITE}📊 SYSTEM OVERVIEW${NC}"
    echo -e "┌─────────────────────────────────────────────────────────────────────────┐"
    printf "│ CPU: ${cpu_color}%6.1f%%%s │ MEM: ${mem_color}%6.1f%%%s │ DISK: ${disk_color}%6.1f%%%s │\n" \
           "$cpu_current" "${NC}" "$mem_current" "${NC}" "$disk_current" "${NC}"
    echo -e "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""
}

show_performance_charts() {
    echo -e "${WHITE}📈 PERFORMANCE CHARTS (Últimos 20 pontos)${NC}"
    echo ""

    # CPU Chart
    echo -e "${CYAN}🔥 CPU Usage (%) ${NC}"
    create_ascii_chart "${CPU_HISTORY[@]}"
    echo ""

    # Memory Chart
    echo -e "${CYAN}🧠 Memory Usage (%) ${NC}"
    create_ascii_chart "${MEMORY_HISTORY[@]}"
    echo ""

    # Disk Chart
    echo -e "${CYAN}💾 Disk Usage (%) ${NC}"
    create_ascii_chart "${DISK_HISTORY[@]}"
    echo ""
}

show_cluster_status() {
    echo -e "${WHITE}⚙️ CLUSTER STATUS${NC}"
    echo -e "┌─────────────────────────────────────────────────────────────────────────┐"

    # Verificar processos do cluster
    local ollama_status dask_status webui_status
    if pgrep -f "ollama" >/dev/null 2>&1; then
        ollama_status="${GREEN}● RUNNING${NC}"
    else
        ollama_status="${RED}● STOPPED${NC}"
    fi

    if pgrep -f "dask-scheduler\|dask-worker" >/dev/null 2>&1; then
        dask_status="${GREEN}● RUNNING${NC}"
    else
        dask_status="${RED}● STOPPED${NC}"
    fi

    if pgrep -f "open-webui" >/dev/null 2>&1; then
        webui_status="${GREEN}● RUNNING${NC}"
    else
        webui_status="${RED}● STOPPED${NC}"
    fi

    printf "│ Ollama: %-12s │ Dask: %-12s │ WebUI: %-12s │\n" \
           "$ollama_status" "$dask_status" "$webui_status"
    echo -e "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""
}

show_recent_alerts() {
    echo -e "${WHITE}🚨 RECENT ALERTS${NC}"
    echo -e "┌─────────────────────────────────────────────────────────────────────────┐"

    if [ -f "$ALERTS_LOG" ]; then
        local alert_count=0
        while IFS= read -r line && [ $alert_count -lt 3 ]; do
            # Filtrar apenas alertas das últimas 24 horas
            local alert_time
            alert_time=$(echo "$line" | grep -o '\[[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\]' | sed 's/\[\|\]//g')

            if [ -n "$alert_time" ]; then
                local alert_timestamp
                alert_timestamp=$(date -d "$alert_time" +%s 2>/dev/null || echo "0")
                local current_timestamp
                current_timestamp=$(date +%s)
                local time_diff=$((current_timestamp - alert_timestamp))

                # Mostrar apenas alertas das últimas 24 horas
                if [ $time_diff -lt 86400 ]; then
                    printf "│ %-71s │\n" "$(echo "$line" | cut -d']' -f4- | sed 's/^ *//')"
                    ((alert_count++))
                fi
            fi
        done < <(tac "$ALERTS_LOG")

        if [ $alert_count -eq 0 ]; then
            printf "│ %-71s │\n" "No recent alerts (last 24h)"
        fi
    else
        printf "│ %-71s │\n" "No alerts log found"
    fi

    echo -e "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""
}

show_performance_trends() {
    echo -e "${WHITE}📊 PERFORMANCE TRENDS${NC}"
    echo -e "┌─────────────────────────────────────────────────────────────────────────┐"

    # Calcular tendências (comparar com valores anteriores)
    local cpu_trend="→" mem_trend="→" disk_trend="→"

    if [ ${#CPU_HISTORY[@]} -gt 5 ]; then
        local cpu_recent_avg mem_recent_avg disk_recent_avg
        local cpu_old_avg mem_old_avg disk_old_avg

        # Média dos últimos 3 valores
        cpu_recent_avg=$(echo "scale=1; (${CPU_HISTORY[-1]} + ${CPU_HISTORY[-2]} + ${CPU_HISTORY[-3]}) / 3" | bc 2>/dev/null || echo "0")
        mem_recent_avg=$(echo "scale=1; (${MEMORY_HISTORY[-1]} + ${MEMORY_HISTORY[-2]} + ${MEMORY_HISTORY[-3]}) / 3" | bc 2>/dev/null || echo "0")
        disk_recent_avg=$(echo "scale=1; (${DISK_HISTORY[-1]} + ${DISK_HISTORY[-2]} + ${DISK_HISTORY[-3]}) / 3" | bc 2>/dev/null || echo "0")

        # Média dos valores anteriores
        cpu_old_avg=$(echo "scale=1; (${CPU_HISTORY[-4]} + ${CPU_HISTORY[-5]} + ${CPU_HISTORY[-6]:-${CPU_HISTORY[-4]:-0}}) / 3" | bc 2>/dev/null || echo "0")
        mem_old_avg=$(echo "scale=1; (${MEMORY_HISTORY[-4]} + ${MEMORY_HISTORY[-5]} + ${MEMORY_HISTORY[-6]:-${MEMORY_HISTORY[-4]:-0}}) / 3" | bc 2>/dev/null || echo "0")
        disk_old_avg=$(echo "scale=1; (${DISK_HISTORY[-4]} + ${DISK_HISTORY[-5]} + ${DISK_HISTORY[-6]:-${DISK_HISTORY[-4]:-0}}) / 3" | bc 2>/dev/null || echo "0")

        # Determinar tendências
        cpu_trend=$( [ $(echo "$cpu_recent_avg > $cpu_old_avg + 2" | bc 2>/dev/null) ] && echo "📈" || ([ $(echo "$cpu_recent_avg < $cpu_old_avg - 2" | bc 2>/dev/null) ] && echo "📉" || echo "→") )
        mem_trend=$( [ $(echo "$mem_recent_avg > $mem_old_avg + 2" | bc 2>/dev/null) ] && echo "📈" || ([ $(echo "$mem_recent_avg < $mem_old_avg - 2" | bc 2>/dev/null) ] && echo "📉" || echo "→") )
        disk_trend=$( [ $(echo "$disk_recent_avg > $disk_old_avg + 2" | bc 2>/dev/null) ] && echo "📈" || ([ $(echo "$disk_recent_avg < $disk_old_avg - 2" | bc 2>/dev/null) ] && echo "📉" || echo "→") )
    fi

    printf "│ CPU Trend: %-3s │ MEM Trend: %-3s │ DISK Trend: %-3s │\n" \
           "$cpu_trend" "$mem_trend" "$disk_trend"
    echo -e "└─────────────────────────────────────────────────────────────────────────┘"
    echo ""
}

show_footer() {
    echo -e "${CYAN}Commands: [q]uit | [r]efresh | [h]elp | [l]ogs${NC}"
    echo ""
}

# ==================== FUNÇÃO PRINCIPAL ====================

main() {
    # Criar diretórios necessários
    mkdir -p "$METRICS_DIR" "$LOGS_DIR"

    # Inicializar arrays
    CPU_HISTORY=()
    MEMORY_HISTORY=()
    DISK_HISTORY=()
    NETWORK_HISTORY=()

    # Coletar dados iniciais
    for ((i=0; i<20; i++)); do
        collect_dashboard_metrics
        sleep 0.1
    done

    log "Dashboard de Performance iniciado. Pressione 'q' para sair."

    # Loop principal do dashboard
    while true; do
        # Coletar novas métricas
        collect_dashboard_metrics

        # Exibir dashboard
        show_header
        show_system_overview
        show_performance_charts
        show_cluster_status
        show_recent_alerts
        show_performance_trends
        show_footer

        # Aguardar entrada do usuário ou timeout
        read -t "$REFRESH_INTERVAL" -n 1 input 2>/dev/null || true

        case "$input" in
            q|Q)
                echo ""
                success "Dashboard encerrado pelo usuário"
                exit 0
                ;;
            r|R)
                log "Atualização manual solicitada"
                ;;
            h|H)
                echo ""
                echo "Comandos disponíveis:"
                echo "  q - Sair do dashboard"
                echo "  r - Atualizar manualmente"
                echo "  l - Mostrar logs detalhados"
                echo "  h - Esta ajuda"
                echo ""
                read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
                ;;
            l|L)
                echo ""
                echo "Últimas 10 entradas do log de performance:"
                echo "----------------------------------------"
                tail -10 "$PERFORMANCE_LOG" 2>/dev/null || echo "Log não encontrado"
                echo ""
                read -n 1 -s -r -p "Pressione qualquer tecla para continuar..."
                ;;
        esac
    done
}

# Verificar dependências
check_dependencies() {
    local deps=("bc" "top" "free" "df" "pgrep")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "Dependência '$dep' não encontrada. Instale-a antes de continuar."
            exit 1
        fi
    done
}

# Executar verificações
check_dependencies

# Executar dashboard
main "$@"
