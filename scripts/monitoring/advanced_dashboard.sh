#!/bin/bash
#
# Dashboard Avançado de Monitoramento
# Recursos: Métricas em tempo real, gráficos, alertas inteligentes
#

set -euo pipefail

# Carregar funções comuns
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# Configurações
DASHBOARD_DIR="${PROJECT_ROOT}/dashboards"
METRICS_DIR="${PROJECT_ROOT}/metrics"
LOG_FILE="${PROJECT_ROOT}/logs/dashboard.log"

# Criar diretórios necessários
mkdir -p "$DASHBOARD_DIR" "$METRICS_DIR"

# Cores para gráficos ASCII
declare -A COLORS=(
    ["RED"]='\033[0;31m'
    ["GREEN"]='\033[0;32m'
    ["YELLOW"]='\033[1;33m'
    ["BLUE"]='\033[0;34m'
    ["MAGENTA"]='\033[0;35m'
    ["CYAN"]='\033[0;36m'
    ["WHITE"]='\033[1;37m'
    ["NC"]='\033[0m'
)

# Função de logging para dashboard
log_dashboard() {
    local level="$1"
    local message="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

# Função para coletar métricas do sistema
collect_system_metrics() {
    local metrics_file="$METRICS_DIR/system_$(date +%Y%m%d_%H%M%S).json"

    # CPU
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

    # Memória
    local mem_total mem_used mem_free
    read -r mem_total mem_used mem_free <<< "$(free -m | awk 'NR==2{printf "%.0f %.0f %.0f", $2, $3, $4}')"

    # Disco
    local disk_usage
    disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

    # Rede (simplificado)
    local network_rx network_tx
    network_rx=$(cat /proc/net/dev | grep -E "^\s*enp|^\s*wlan|^\s*eth" | awk '{sum += $2} END {print sum/1024/1024}') 2>/dev/null || network_rx=0
    network_tx=$(cat /proc/net/dev | grep -E "^\s*enp|^\s*wlan|^\s*eth" | awk '{sum += $10} END {print sum/1024/1024}') 2>/dev/null || network_tx=0

    # Criar JSON de métricas
    jq -n \
        --argjson timestamp "$(date +%s)" \
        --argjson cpu "$cpu_usage" \
        --argjson mem_total "$mem_total" \
        --argjson mem_used "$mem_used" \
        --argjson mem_free "$mem_free" \
        --argjson disk "$disk_usage" \
        --argjson network_rx "$network_rx" \
        --argjson network_tx "$network_tx" \
        '{
            timestamp: $timestamp,
            cpu: {
                usage_percent: $cpu
            },
            memory: {
                total_mb: $mem_total,
                used_mb: $mem_used,
                free_mb: $mem_free,
                usage_percent: (($mem_used / $mem_total) * 100)
            },
            disk: {
                usage_percent: $disk
            },
            network: {
                rx_mb: $network_rx,
                tx_mb: $network_tx
            }
        }' > "$metrics_file"

    log_dashboard "INFO" "Métricas do sistema coletadas: CPU=${cpu_usage}%, MEM=${mem_used}/${mem_total}MB"
}

# Função para coletar métricas do Dask
collect_dask_metrics() {
    local metrics_file="$METRICS_DIR/dask_$(date +%Y%m%d_%H%M%S).json"

    # Verificar se Dask está rodando
    if pgrep -f "dask-scheduler" > /dev/null; then
        local scheduler_status="running"

        # Tentar obter métricas do scheduler (se disponível)
        local workers_count=0
        local tasks_completed=0

        # Simulação - em produção, isso viria da API do Dask
        if command_exists curl; then
            # Tentar conectar ao dashboard do Dask
            if curl -s "http://localhost:8787" > /dev/null 2>&1; then
                workers_count=$(curl -s "http://localhost:8787/workers" | jq '. | length' 2>/dev/null || echo "0")
                tasks_completed=$(curl -s "http://localhost:8787/tasks" | jq '. | length' 2>/dev/null || echo "0")
            fi
        fi
    else
        local scheduler_status="stopped"
        local workers_count=0
        local tasks_completed=0
    fi

    # Criar JSON de métricas
    jq -n \
        --argjson timestamp "$(date +%s)" \
        --arg status "$scheduler_status" \
        --argjson workers "$workers_count" \
        --argjson tasks "$tasks_completed" \
        '{
            timestamp: $timestamp,
            scheduler: {
                status: $status,
                workers_count: $workers,
                tasks_completed: $tasks
            }
        }' > "$metrics_file"

    log_dashboard "INFO" "Métricas do Dask coletadas: Status=$scheduler_status, Workers=$workers_count"
}

# Função para coletar métricas do Ollama
collect_ollama_metrics() {
    local metrics_file="$METRICS_DIR/ollama_$(date +%Y%m%d_%H%M%S).json"

    if command_exists ollama; then
        # Verificar se Ollama está rodando
        if pgrep -f "ollama serve" > /dev/null || sudo systemctl is-active --quiet ollama 2>/dev/null; then
            local ollama_status="running"

            # Obter lista de modelos
            local models_count=0
            local models_size_mb=0

            if models_list=$(ollama list 2>/dev/null); then
                models_count=$(echo "$models_list" | wc -l)
                models_count=$((models_count - 1))  # Subtrair header

                # Estimar tamanho (simplificado)
                if [[ -d "$HOME/.ollama/models" ]]; then
                    models_size_mb=$(du -sm "$HOME/.ollama/models" 2>/dev/null | cut -f1 || echo "0")
                fi
            fi
        else
            local ollama_status="stopped"
            local models_count=0
            local models_size_mb=0
        fi
    else
        local ollama_status="not_installed"
        local models_count=0
        local models_size_mb=0
    fi

    # Criar JSON de métricas
    jq -n \
        --argjson timestamp "$(date +%s)" \
        --arg status "$ollama_status" \
        --argjson models_count "$models_count" \
        --argjson models_size_mb "$models_size_mb" \
        '{
            timestamp: $timestamp,
            ollama: {
                status: $status,
                models_count: $models_count,
                models_size_mb: $models_size_mb
            }
        }' > "$metrics_file"

    log_dashboard "INFO" "Métricas do Ollama coletadas: Status=$ollama_status, Modelos=$models_count"
}

# Função para gerar gráfico ASCII de barras
generate_bar_chart() {
    local title="$1"
    local value="$2"
    local max_value="$3"
    local width="${4:-20}"
    local color="${5:-GREEN}"

    # Calcular largura da barra
    local bar_width=0
    if [[ $max_value -gt 0 ]]; then
        bar_width=$(( (value * width) / max_value ))
    fi

    # Limitar largura máxima
    if [[ $bar_width -gt $width ]]; then
        bar_width=$width
    fi

    # Criar barra
    local bar=""
    for ((i=0; i<bar_width; i++)); do
        bar="${bar}█"
    done

    # Preencher resto com espaços
    while [[ ${#bar} -lt $width ]]; do
        bar="${bar}░"
    done

    # Aplicar cor
    local color_code="${COLORS[$color]}"
    local nc="${COLORS[NC]}"

    printf "%-15s [%s%s%s] %3d%%\n" "$title" "$color_code" "$bar" "$nc" "$value"
}

# Função para exibir dashboard em tempo real
show_live_dashboard() {
    clear
    section "📊 Dashboard Avançado - Monitoramento em Tempo Real"
    echo "Atualizado em: $(date)"
    echo

    # Coletar métricas atuais
    collect_system_metrics
    collect_dask_metrics
    collect_ollama_metrics

    # Obter métricas mais recentes
    local latest_system_metrics
    latest_system_metrics=$(ls -t "$METRICS_DIR"/system_*.json 2>/dev/null | head -1)
    local latest_dask_metrics
    latest_dask_metrics=$(ls -t "$METRICS_DIR"/dask_*.json 2>/dev/null | head -1)
    local latest_ollama_metrics
    latest_ollama_metrics=$(ls -t "$METRICS_DIR"/ollama_*.json 2>/dev/null | head -1)

    # Sistema
    subsection "🖥️  Sistema"
    if [[ -f "$latest_system_metrics" ]]; then
        local cpu_usage mem_usage disk_usage
        cpu_usage=$(jq -r '.cpu.usage_percent' "$latest_system_metrics" 2>/dev/null || echo "0")
        mem_usage=$(jq -r '.memory.usage_percent' "$latest_system_metrics" 2>/dev/null || echo "0")
        disk_usage=$(jq -r '.disk.usage_percent' "$latest_system_metrics" 2>/dev/null || echo "0")

        generate_bar_chart "CPU" "${cpu_usage%.*}" 100 20 "CYAN"
        generate_bar_chart "Memória" "${mem_usage%.*}" 100 20 "BLUE"
        generate_bar_chart "Disco" "$disk_usage" 100 20 "YELLOW"
    else
        echo "  📊 Métricas do sistema não disponíveis"
    fi
    echo

    # Serviços
    subsection "🔧 Serviços"
    if [[ -f "$latest_dask_metrics" ]]; then
        local dask_status workers_count
        dask_status=$(jq -r '.scheduler.status' "$latest_dask_metrics" 2>/dev/null || echo "unknown")
        workers_count=$(jq -r '.scheduler.workers_count' "$latest_dask_metrics" 2>/dev/null || echo "0")

        if [[ "$dask_status" == "running" ]]; then
            echo -e "  Dask Scheduler: ${COLORS[GREEN]}● Rodando${COLORS[NC]} ($workers_count workers)"
        else
            echo -e "  Dask Scheduler: ${COLORS[RED]}● Parado${COLORS[NC]}"
        fi
    fi

    if [[ -f "$latest_ollama_metrics" ]]; then
        local ollama_status models_count
        ollama_status=$(jq -r '.ollama.status' "$latest_ollama_metrics" 2>/dev/null || echo "unknown")
        models_count=$(jq -r '.ollama.models_count' "$latest_ollama_metrics" 2>/dev/null || echo "0")

        if [[ "$ollama_status" == "running" ]]; then
            echo -e "  Ollama: ${COLORS[GREEN]}● Rodando${COLORS[NC]} ($models_count modelos)"
        elif [[ "$ollama_status" == "not_installed" ]]; then
            echo -e "  Ollama: ${COLORS[YELLOW]}● Não instalado${COLORS[NC]}"
        else
            echo -e "  Ollama: ${COLORS[RED]}● Parado${COLORS[NC]}"
        fi
    fi
    echo

    # Alertas
    subsection "🚨 Alertas"
    local alerts_count=0

    if [[ -f "$latest_system_metrics" ]]; then
        local cpu_usage mem_usage disk_usage
        cpu_usage=$(jq -r '.cpu.usage_percent' "$latest_system_metrics" 2>/dev/null || echo "0")
        mem_usage=$(jq -r '.memory.usage_percent' "$latest_system_metrics" 2>/dev/null || echo "0")
        disk_usage=$(jq -r '.disk.usage_percent' "$latest_system_metrics" 2>/dev/null || echo "0")

        if (( $(echo "$cpu_usage > 90" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "  ${COLORS[RED]}⚠️  CPU alta: ${cpu_usage}%${COLORS[NC]}"
            ((alerts_count++))
        fi

        if (( $(echo "$mem_usage > 90" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "  ${COLORS[RED]}⚠️  Memória alta: ${mem_usage}%${COLORS[NC]}"
            ((alerts_count++))
        fi

        if [[ $disk_usage -gt 90 ]]; then
            echo -e "  ${COLORS[RED]}⚠️  Disco cheio: ${disk_usage}%${COLORS[NC]}"
            ((alerts_count++))
        fi
    fi

    if [[ $alerts_count -eq 0 ]]; then
        echo -e "  ${COLORS[GREEN]}✅ Nenhum alerta ativo${COLORS[NC]}"
    fi
    echo

    # Estatísticas rápidas
    subsection "📈 Estatísticas Rápidas"
    local total_metrics
    total_metrics=$(find "$METRICS_DIR" -name "*.json" | wc -l)
    echo "  📊 Métricas coletadas: $total_metrics"
    echo "  📁 Arquivos de log: $(find "${PROJECT_ROOT}/logs" -name "*.log" | wc -l)"
    echo "  🤖 Modelos IA: $(find "${PROJECT_ROOT}/metrics/models" -name "*.json" 2>/dev/null | wc -l || echo "0")"
    echo
}

# Função para modo contínuo
continuous_monitoring() {
    local interval="${1:-5}"

    info "Iniciando monitoramento contínuo (intervalo: ${interval}s)"
    info "Pressione Ctrl+C para parar"

    while true; do
        show_live_dashboard
        sleep "$interval"
    done
}

# Função para exportar métricas
export_metrics() {
    local format="${1:-json}"
    local output_file="$DASHBOARD_DIR/metrics_export_$(date +%Y%m%d_%H%M%S).$format"

    subsection "📤 Exportando métricas para: $output_file"

    case "$format" in
        "json")
            # Combinar todas as métricas em um arquivo JSON
            jq -n '{
                export_timestamp: now,
                system_metrics: [inputs] | map(select(.cpu?))
            }' "$METRICS_DIR"/system_*.json > "$output_file" 2>/dev/null || echo "{}" > "$output_file"
            ;;
        "csv")
            # Exportar como CSV
            {
                echo "timestamp,cpu_usage,memory_usage,disk_usage"
                for file in "$METRICS_DIR"/system_*.json; do
                    if [[ -f "$file" ]]; then
                        timestamp=$(jq -r '.timestamp' "$file" 2>/dev/null || echo "")
                        cpu=$(jq -r '.cpu.usage_percent' "$file" 2>/dev/null || echo "")
                        mem=$(jq -r '.memory.usage_percent' "$file" 2>/dev/null || echo "")
                        disk=$(jq -r '.disk.usage_percent' "$file" 2>/dev/null || echo "")
                        echo "$timestamp,$cpu,$mem,$disk"
                    fi
                done
            } > "$output_file"
            ;;
        *)
            error "Formato não suportado: $format"
            return 1
            ;;
    esac

    success "Métricas exportadas com sucesso!"
    log_dashboard "INFO" "Métricas exportadas para $output_file (formato: $format)"
}

# Função principal
main() {
    local command="${1:-live}"

    case "$command" in
        "live")
            show_live_dashboard
            ;;
        "continuous")
            local interval="${2:-5}"
            continuous_monitoring "$interval"
            ;;
        "collect")
            collect_system_metrics
            collect_dask_metrics
            collect_ollama_metrics
            success "Métricas coletadas com sucesso!"
            ;;
        "export")
            local format="${2:-json}"
            export_metrics "$format"
            ;;
        "help"|*)
            section "📊 Dashboard Avançado de Monitoramento"
            echo
            echo "Uso: $0 <comando> [opções]"
            echo
            echo "Comandos disponíveis:"
            echo "  live                    - Mostra dashboard em tempo real (único)"
            echo "  continuous [segundos]   - Monitoramento contínuo (padrão: 5s)"
            echo "  collect                 - Coleta métricas uma vez"
            echo "  export [formato]        - Exporta métricas (json/csv, padrão: json)"
            echo "  help                    - Mostra esta ajuda"
            echo
            echo "Exemplos:"
            echo "  $0 live"
            echo "  $0 continuous 10"
            echo "  $0 collect"
            echo "  $0 export csv"
            echo
            echo "Recursos:"
            echo "  • Métricas em tempo real do sistema"
            echo "  • Status dos serviços (Dask, Ollama)"
            echo "  • Gráficos ASCII interativos"
            echo "  • Alertas inteligentes"
            echo "  • Exportação de dados"
            ;;
    esac
}

main "$@"
