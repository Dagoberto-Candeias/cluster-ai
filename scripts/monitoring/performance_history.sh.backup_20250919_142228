#!/bin/bash
# Sistema de Rastreamento de Histórico de Performance
# Mantém histórico detalhado de métricas para análise de tendências

set -euo pipefail

# ==================== CONFIGURAÇÃO ====================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HISTORY_DIR="${PROJECT_ROOT}/metrics/history"
ARCHIVE_DIR="${PROJECT_ROOT}/metrics/archive"
CONFIG_FILE="${PROJECT_ROOT}/config/performance_history.conf"

# Configurações de histórico
RETENTION_DAYS=30
COMPRESSION_ENABLED=true
ARCHIVE_THRESHOLD_DAYS=7
MAX_HISTORY_FILES=1000

# Arquivos de dados
PERFORMANCE_HISTORY="${HISTORY_DIR}/performance_history.csv"
METRICS_HISTORY="${HISTORY_DIR}/metrics_history.json"
TREND_ANALYSIS="${HISTORY_DIR}/trend_analysis.log"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# ==================== FUNÇÕES UTILITÁRIAS ====================

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1" >&2
}

error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" >&2
}

success() {
    echo -e "${GREEN}✅ $1${NC}" >&2
}

info() {
    echo -e "${CYAN}ℹ️  $1${NC}" >&2
}

# ==================== FUNÇÕES DE INICIALIZAÇÃO ====================

# Inicializar sistema de histórico
initialize_history_system() {
    log "Inicializando sistema de histórico de performance..."

    # Criar diretórios
    mkdir -p "$HISTORY_DIR" "$ARCHIVE_DIR"

    # Criar arquivos de histórico se não existirem
    if [ ! -f "$PERFORMANCE_HISTORY" ]; then
        echo "timestamp,cpu_usage,memory_usage,disk_usage,network_rx,network_tx,load_avg,temperature" > "$PERFORMANCE_HISTORY"
        log "Arquivo de histórico de performance criado"
    fi

    if [ ! -f "$METRICS_HISTORY" ]; then
        echo "{}" > "$METRICS_HISTORY"
        log "Arquivo de histórico de métricas criado"
    fi

    if [ ! -f "$TREND_ANALYSIS" ]; then
        echo "# Performance Trend Analysis Log" > "$TREND_ANALYSIS"
        echo "# Generated on $(date)" >> "$TREND_ANALYSIS"
        log "Arquivo de análise de tendências criado"
    fi

    success "Sistema de histórico inicializado"
}

# ==================== FUNÇÕES DE COLETA DE MÉTRICAS ====================

# Coletar métricas atuais do sistema
collect_current_metrics() {
    local timestamp=$(date +%s)

    # CPU
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' | xargs printf "%.2f")

    # Memória
    local memory_usage
    memory_usage=$(free | awk 'NR==2{printf "%.2f", $3*100/$2}')

    # Disco
    local disk_usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//' | xargs printf "%.2f")

    # Rede
    local network_rx network_tx
    if [ -f /proc/net/dev ]; then
        network_rx=$(cat /proc/net/dev | grep -E "^[[:space:]]*eth0|^[[:space:]]*wlan0|^[[:space:]]*enp" | head -1 | awk '{print $2}' | xargs printf "%.0f")
        network_tx=$(cat /proc/net/dev | grep -E "^[[:space:]]*eth0|^[[:space:]]*wlan0|^[[:space:]]*enp" | head -1 | awk '{print $10}' | xargs printf "%.0f")
    else
        network_rx=0
        network_tx=0
    fi

    # Load average
    local load_avg
    load_avg=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)

    # Temperatura da CPU
    local temperature
    if command -v sensors >/dev/null 2>&1; then
        temperature=$(sensors | grep 'Core 0' | head -1 | awk '{print $3}' | sed 's/+//' | sed 's/°C//' | xargs printf "%.1f")
    else
        temperature="N/A"
    fi

    # Retornar métricas como string CSV
    echo "$timestamp,$cpu_usage,$memory_usage,$disk_usage,$network_rx,$network_tx,$load_avg,$temperature"
}

# ==================== FUNÇÕES DE ARMAZENAMENTO ====================

# Adicionar entrada ao histórico de performance
add_performance_entry() {
    local metrics_csv="$1"

    echo "$metrics_csv" >> "$PERFORMANCE_HISTORY"
    log "Entrada de performance adicionada: $(echo "$metrics_csv" | cut -d',' -f1)"
}

# Adicionar entrada detalhada ao histórico de métricas
add_detailed_metrics() {
    local timestamp="$1"
    local cpu="$2"
    local memory="$3"
    local disk="$4"
    local network_rx="$5"
    local network_tx="$6"
    local load_avg="$7"
    local temperature="$8"

    # Ler histórico atual
    local current_history
    current_history=$(cat "$METRICS_HISTORY")

    # Adicionar nova entrada (manter apenas últimas 1000 entradas)
    local new_entry
    new_entry=$(cat << EOF
{
  "timestamp": "$timestamp",
  "date": "$(date -d "@$timestamp" 2>/dev/null || date)",
  "cpu_usage": $cpu,
  "memory_usage": $memory,
  "disk_usage": $disk,
  "network_rx": $network_rx,
  "network_tx": $network_tx,
  "load_average": $load_avg,
  "temperature": "$temperature"
}
EOF
)

    # Atualizar arquivo JSON (simplificado - em produção usaria jq)
    if [ "$current_history" = "{}" ]; then
        echo "[$new_entry]" > "$METRICS_HISTORY"
    else
        # Adicionar ao array existente (versão simplificada)
        sed -i '$ s/]$/,/' "$METRICS_HISTORY"
        echo "$new_entry" >> "$METRICS_HISTORY"
        echo "]" >> "$METRICS_HISTORY"
    fi
}

# ==================== FUNÇÕES DE ANÁLISE ====================

# Analisar tendências de performance
analyze_performance_trends() {
    log "Analisando tendências de performance..."

    # Verificar se temos dados suficientes
    local line_count
    line_count=$(wc -l < "$PERFORMANCE_HISTORY")

    if [ "$line_count" -lt 10 ]; then
        warning "Dados insuficientes para análise de tendências ($line_count entradas)"
        return
    fi

    # Analisar últimas 24 horas (assumindo coleta a cada 5 minutos = 288 entradas)
    local recent_data
    recent_data=$(tail -n 288 "$PERFORMANCE_HISTORY" 2>/dev/null || tail -n 50 "$PERFORMANCE_HISTORY")

    # Calcular médias
    local cpu_avg memory_avg disk_avg
    cpu_avg=$(echo "$recent_data" | awk -F',' 'NR>1 {sum+=$2} END {if(NR>1) print sum/(NR-1); else print 0}')
    memory_avg=$(echo "$recent_data" | awk -F',' 'NR>1 {sum+=$3} END {if(NR>1) print sum/(NR-1); else print 0}')
    disk_avg=$(echo "$recent_data" | awk -F',' 'NR>1 {sum+=$4} END {if(NR>1) print sum/(NR-1); else print 0}')

    # Detectar tendências
    local trend_report=""
    local timestamp=$(date +%s)

    # Tendência de CPU
    if (( $(echo "$cpu_avg > 70" | bc -l 2>/dev/null || echo "0") )); then
        trend_report="${trend_report}CPU_HIGH: Média de uso alto (${cpu_avg}%); "
    fi

    # Tendência de Memória
    if (( $(echo "$memory_avg > 80" | bc -l 2>/dev/null || echo "0") )); then
        trend_report="${trend_report}MEMORY_HIGH: Média de uso alto (${memory_avg}%); "
    fi

    # Tendência de Disco
    if (( $(echo "$disk_avg > 85" | bc -l 2>/dev/null || echo "0") )); then
        trend_report="${trend_report}DISK_HIGH: Média de uso alto (${disk_avg}%); "
    fi

    # Registrar análise
    if [ -n "$trend_report" ]; then
        echo "[$timestamp] $(date) - $trend_report" >> "$TREND_ANALYSIS"
        warning "Tendências detectadas: $trend_report"
    else
        echo "[$timestamp] $(date) - PERFORMANCE_NORMAL: Todas as métricas dentro dos limites aceitáveis" >> "$TREND_ANALYSIS"
    fi

    success "Análise de tendências concluída"
}

# ==================== FUNÇÕES DE LIMPEZA ====================

# Limpar histórico antigo
cleanup_old_history() {
    log "Limpando histórico antigo..."

    local current_time=$(date +%s)
    local cutoff_time=$((current_time - (RETENTION_DAYS * 24 * 3600)))

    # Arquivar dados antigos se compressão estiver habilitada
    if [ "$COMPRESSION_ENABLED" = true ]; then
        local archive_file="${ARCHIVE_DIR}/performance_archive_$(date +%Y%m%d_%H%M%S).tar.gz"

        # Criar arquivo de dados para arquivar (últimas 1000 linhas antigas)
        local old_data_file="${HISTORY_DIR}/old_data_$(date +%s).csv"
        head -n 1000 "$PERFORMANCE_HISTORY" > "$old_data_file" 2>/dev/null || true

        if [ -s "$old_data_file" ]; then
            tar -czf "$archive_file" -C "$HISTORY_DIR" "$(basename "$old_data_file")" 2>/dev/null || true
            rm -f "$old_data_file"
            log "Dados arquivados: $archive_file"
        fi
    fi

    # Manter apenas dados recentes no arquivo principal
    local temp_file="${PERFORMANCE_HISTORY}.tmp"
    head -n 1 "$PERFORMANCE_HISTORY" > "$temp_file"  # Manter cabeçalho
    tail -n +2 "$PERFORMANCE_HISTORY" | awk -F',' -v cutoff="$cutoff_time" '$1 >= cutoff' >> "$temp_file"
    mv "$temp_file" "$PERFORMANCE_HISTORY"

    # Limpar arquivos de análise antigos
    find "$HISTORY_DIR" -name "trend_analysis.log.*" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true

    # Limpar arquivos arquivados muito antigos
    find "$ARCHIVE_DIR" -name "*.tar.gz" -mtime +$((RETENTION_DAYS * 2)) -delete 2>/dev/null || true

    success "Limpeza de histórico concluída"
}

# ==================== FUNÇÕES DE RELATÓRIOS ====================

# Gerar relatório de performance
generate_performance_report() {
    local report_file="${HISTORY_DIR}/performance_report_$(date +%Y%m%d_%H%M%S).txt"

    log "Gerando relatório de performance..."

    {
        echo "=== RELATÓRIO DE PERFORMANCE DO CLUSTER AI ==="
        echo "Gerado em: $(date)"
        echo "Período: Últimas 24 horas"
        echo ""

        # Estatísticas básicas
        local total_entries
        total_entries=$(wc -l < "$PERFORMANCE_HISTORY")
        echo "Total de entradas no histórico: $((total_entries - 1))"  # -1 para cabeçalho
        echo ""

        # Calcular estatísticas das últimas 24 horas
        local recent_data
        recent_data=$(tail -n 288 "$PERFORMANCE_HISTORY" 2>/dev/null || tail -n 50 "$PERFORMANCE_HISTORY")

        if [ -n "$recent_data" ]; then
            echo "=== ESTATÍSTICAS DAS ÚLTIMAS 24 HORAS ==="

            # CPU
            local cpu_max cpu_min cpu_avg
            cpu_max=$(echo "$recent_data" | awk -F',' 'NR>1 {if(max=="") max=$2; if($2>max) max=$2} END {print max}')
            cpu_min=$(echo "$recent_data" | awk -F',' 'NR>1 {if(min=="") min=$2; if($2<min) min=$2} END {print min}')
            cpu_avg=$(echo "$recent_data" | awk -F',' 'NR>1 {sum+=$2} END {if(NR>1) print sum/(NR-1); else print 0}')

            echo "CPU Usage:"
            echo "  Máximo: ${cpu_max}%"
            echo "  Mínimo: ${cpu_min}%"
            echo "  Média: ${cpu_avg}%"
            echo ""

            # Memória
            local mem_max mem_min mem_avg
            mem_max=$(echo "$recent_data" | awk -F',' 'NR>1 {if(max=="") max=$3; if($3>max) max=$3} END {print max}')
            mem_min=$(echo "$recent_data" | awk -F',' 'NR>1 {if(min=="") min=$3; if($3<min) min=$3} END {print min}')
            mem_avg=$(echo "$recent_data" | awk -F',' 'NR>1 {sum+=$3} END {if(NR>1) print sum/(NR-1); else print 0}')

            echo "Memory Usage:"
            echo "  Máximo: ${mem_max}%"
            echo "  Mínimo: ${mem_min}%"
            echo "  Média: ${mem_avg}%"
            echo ""

            # Disco
            local disk_max disk_min disk_avg
            disk_max=$(echo "$recent_data" | awk -F',' 'NR>1 {if(max=="") max=$4; if($4>max) max=$4} END {print max}')
            disk_min=$(echo "$recent_data" | awk -F',' 'NR>1 {if(min=="") min=$4; if($4<min) min=$4} END {print min}')
            disk_avg=$(echo "$recent_data" | awk -F',' 'NR>1 {sum+=$4} END {if(NR>1) print sum/(NR-1); else print 0}')

            echo "Disk Usage:"
            echo "  Máximo: ${disk_max}%"
            echo "  Mínimo: ${disk_min}%"
            echo "  Média: ${disk_avg}%"
            echo ""
        fi

        # Últimas tendências
        echo "=== ÚLTIMAS TENDÊNCIAS ==="
        if [ -f "$TREND_ANALYSIS" ]; then
            tail -n 5 "$TREND_ANALYSIS" | while read -r line; do
                echo "$line"
            done
        else
            echo "Nenhuma análise de tendências disponível"
        fi

    } > "$report_file"

    success "Relatório gerado: $report_file"
}

# ==================== FUNÇÃO PRINCIPAL ====================

main() {
    case "${1:-collect}" in
        init)
            initialize_history_system
            ;;
        collect)
            # Coletar métricas atuais
            local metrics
            metrics=$(collect_current_metrics)

            # Adicionar ao histórico
            add_performance_entry "$metrics"

            # Extrair valores para histórico detalhado
            IFS=',' read -r timestamp cpu memory disk network_rx network_tx load_avg temperature <<< "$metrics"
            add_detailed_metrics "$timestamp" "$cpu" "$memory" "$disk" "$network_rx" "$network_tx" "$load_avg" "$temperature"

            log "Métricas coletadas e armazenadas"
            ;;
        analyze)
            analyze_performance_trends
            ;;
        cleanup)
            cleanup_old_history
            ;;
        report)
            generate_performance_report
            ;;
        stats)
            # Mostrar estatísticas rápidas
            local total_entries
            total_entries=$(wc -l < "$PERFORMANCE_HISTORY" 2>/dev/null || echo "0")
            echo "Total entries: $((total_entries - 1))"
            echo "Last update: $(tail -n 1 "$PERFORMANCE_HISTORY" | cut -d',' -f1 | xargs -I {} date -d "@{}" 2>/dev/null || echo "Unknown")"
            echo "History size: $(du -h "$PERFORMANCE_HISTORY" 2>/dev/null | cut -f1)"
            ;;
        *)
            echo "Uso: $0 [init|collect|analyze|cleanup|report|stats]"
            echo ""
            echo "Comandos:"
            echo "  init     - Inicializar sistema de histórico"
            echo "  collect  - Coletar métricas atuais"
            echo "  analyze  - Analisar tendências de performance"
            echo "  cleanup  - Limpar dados antigos"
            echo "  report   - Gerar relatório de performance"
            echo "  stats    - Mostrar estatísticas rápidas"
            ;;
    esac
}

# Executar função principal
main "$@"
