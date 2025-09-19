#!/bin/bash
# Dashboard Interativo do Cluster AI

set -euo pipefail

# ==================== CONFIGURAÇÃO ====================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MONITOR_SCRIPT="${PROJECT_ROOT}/scripts/monitoring/central_monitor.sh"
LOGS_DIR="${PROJECT_ROOT}/logs"
METRICS_DIR="${PROJECT_ROOT}/metrics"
ALERTS_DIR="${PROJECT_ROOT}/alerts"

# Função auxiliar para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Cores para o dashboard
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ==================== FUNÇÕES DE INTERFACE ====================

# Limpa tela e posiciona cursor
clear_screen() {
    clear
    tput cup 0 0
}

# Desenha borda
draw_border() {
    local width="$1"
    local height="$2"
    local title="$3"

    # Linha superior
    echo -n "╔"
    for ((i=1; i<width-1; i++)); do
        if [ $i -eq $(( (width - ${#title} - 2) / 2 )) ]; then
            echo -n " ${title} "
            ((i += ${#title} + 1))
        else
            echo -n "═"
        fi
    done
    echo "╗"

    # Linhas do meio
    for ((i=0; i<height-2; i++)); do
        echo -n "║"
        for ((j=0; j<width-2; j++)); do
            echo -n " "
        done
        echo "║"
    done

    # Linha inferior
    echo -n "╚"
    for ((i=0; i<width-2; i++)); do
        echo -n "═"
    done
    echo "╝"
}

# Mostra cabeçalho
show_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                           CLUSTER AI DASHBOARD                            ║"
    echo "╠══════════════════════════════════════════════════════════════════════════════╣"
    echo -e "║ $(date '+%Y-%m-%d %H:%M:%S')                                              ${NC}║"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Mostra métricas de sistema
show_system_metrics() {
    echo -e "${YELLOW}🔥 SISTEMA${NC}"
    echo -e "${WHITE}CPU:${NC}"

    # CPU Usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' | cut -d. -f1)
    if [ -z "$cpu_usage" ] || ! [[ "$cpu_usage" =~ ^[0-9]+$ ]]; then
        cpu_usage=0
    fi
    if [ "$cpu_usage" -gt 80 ]; then
        echo -e "  Uso: ${RED}${cpu_usage}%${NC}"
    elif [ "$cpu_usage" -gt 60 ]; then
        echo -e "  Uso: ${YELLOW}${cpu_usage}%${NC}"
    else
        echo -e "  Uso: ${GREEN}${cpu_usage}%${NC}"
    fi

    # Memory
    local mem_info=$(free | grep Mem)
    local mem_total=$(echo $mem_info | awk '{print $2}')
    local mem_used=$(echo $mem_info | awk '{print $3}')
    if [ -z "$mem_total" ] || [ "$mem_total" -eq 0 ]; then
        mem_usage=0
    else
        mem_usage=$((mem_used * 100 / mem_total))
    fi

    echo -e "${WHITE}Memória:${NC}"
    if [ "$mem_usage" -gt 85 ]; then
        echo -e "  Uso: ${RED}${mem_usage}%${NC} (${mem_used}MB / ${mem_total}MB)"
    elif [ "$mem_usage" -gt 70 ]; then
        echo -e "  Uso: ${YELLOW}${mem_usage}%${NC} (${mem_used}MB / ${mem_total}MB)"
    else
        echo -e "  Uso: ${GREEN}${mem_usage}%${NC} (${mem_used}MB / ${mem_total}MB)"
    fi

    # Disk
    local disk_info=$(df / | tail -1)
    local disk_usage=$(echo $disk_info | awk '{print $5}' | sed 's/%//')

    echo -e "${WHITE}Disco:${NC}"
    if [ "$disk_usage" -gt 90 ]; then
        echo -e "  Uso: ${RED}${disk_usage}%${NC}"
    elif [ "$disk_usage" -gt 75 ]; then
        echo -e "  Uso: ${YELLOW}${disk_usage}%${NC}"
    else
        echo -e "  Uso: ${GREEN}${disk_usage}%${NC}"
    fi

    echo ""
}

# Mostra status dos serviços
show_services_status() {
    echo -e "${YELLOW}⚙️ SERVIÇOS${NC}"

    # Ollama
    if pgrep -f "ollama" >/dev/null 2>&1; then
        echo -e "${WHITE}Ollama:${NC} ${GREEN}● Rodando${NC}"
    else
        echo -e "${WHITE}Ollama:${NC} ${RED}● Parado${NC}"
    fi

    # Dask
    if pgrep -f "dask-scheduler\|dask-worker" >/dev/null 2>&1; then
        local worker_count=$(pgrep -f "dask-worker" | wc -l)
        echo -e "${WHITE}Dask:${NC} ${GREEN}● Rodando${NC} (${worker_count} workers)"
    else
        echo -e "${WHITE}Dask:${NC} ${RED}● Parado${NC}"
    fi

    # Open WebUI
    if pgrep -f "open-webui" >/dev/null 2>&1; then
        echo -e "${WHITE}WebUI:${NC} ${GREEN}● Rodando${NC}"
    else
        echo -e "${WHITE}WebUI:${NC} ${RED}● Parado${NC}"
    fi

    # Docker
    if command_exists docker && docker info >/dev/null 2>&1; then
        echo -e "${WHITE}Docker:${NC} ${GREEN}● Rodando${NC}"
    else
        echo -e "${WHITE}Docker:${NC} ${RED}● Parado${NC}"
    fi

    echo ""
}

# Mostra métricas dos workers Android
show_android_workers() {
    echo -e "${YELLOW}🤖 ANDROID WORKERS${NC}"

    # Simulação de dados dos workers (em produção seria coletado via API)
    local workers_online=3
    local workers_total=5
    local avg_battery=78
    local avg_cpu=45
    local avg_memory=62

    echo -e "${WHITE}Status:${NC} ${GREEN}${workers_online}/${workers_total}${NC} online"
    echo -e "${WHITE}Bateria Média:${NC} ${GREEN}${avg_battery}%${NC}"
    echo -e "${WHITE}CPU Médio:${NC} ${GREEN}${avg_cpu}%${NC}"
    echo -e "${WHITE}Memória Média:${NC} ${GREEN}${avg_memory}%${NC}"

    echo ""
}

# Mostra alertas recentes
show_recent_alerts() {
    echo -e "${YELLOW}🚨 ALERTAS RECENTES${NC}"

    local alerts_file="${ALERTS_DIR}/alerts.log"
    if [ -f "$alerts_file" ]; then
        local alert_count=$(tail -10 "$alerts_file" | wc -l)
        if [ "$alert_count" -gt 0 ]; then
            tail -5 "$alerts_file" | while read -r line; do
                # Colorir baseado na severidade
                if echo "$line" | grep -q "CRITICAL"; then
                    echo -e "${RED}  $line${NC}"
                elif echo "$line" | grep -q "WARNING"; then
                    echo -e "${YELLOW}  $line${NC}"
                else
                    echo -e "${WHITE}  $line${NC}"
                fi
            done
        else
            echo -e "${GREEN}  Nenhum alerta recente${NC}"
        fi
    else
        echo -e "${GREEN}  Nenhum alerta registrado${NC}"
    fi

    echo ""
}

# Mostra estatísticas rápidas
show_quick_stats() {
    echo -e "${YELLOW}📊 ESTATÍSTICAS RÁPIDAS${NC}"

    # Uptime
    local uptime=$(uptime -p)
    echo -e "${WHITE}Uptime:${NC} ${CYAN}${uptime}${NC}"

    # Load average
    local load=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)
    echo -e "${WHITE}Load Average:${NC} ${CYAN}${load}${NC}"

    # Processos ativos
    local processes=$(ps aux | wc -l)
    echo -e "${WHITE}Processos:${NC} ${CYAN}${processes}${NC}"

    # Usuários conectados
    local users=$(who | wc -l)
    echo -e "${WHITE}Usuários:${NC} ${CYAN}${users}${NC}"

    echo ""
}

# Mostra menu de ações
show_menu() {
    echo -e "${YELLOW}🎮 CONTROLES${NC}"
    echo -e "${WHITE}r${NC} - Atualizar dashboard"
    echo -e "${WHITE}d${NC} - Ver detalhes dos serviços"
    echo -e "${WHITE}l${NC} - Ver logs recentes"
    echo -e "${WHITE}a${NC} - Ver todos os alertas"
    echo -e "${WHITE}m${NC} - Ver métricas detalhadas"
    echo -e "${WHITE}q${NC} - Sair"
    echo ""
    echo -e "${CYAN}Aguardando comando...${NC}"
}

# ==================== FUNÇÕES DE AÇÃO ====================

# Mostra detalhes dos serviços
show_service_details() {
    clear_screen
    show_header

    echo -e "${YELLOW}🔍 DETALHES DOS SERVIÇOS${NC}"
    echo ""

    # Ollama
    echo -e "${WHITE}Ollama:${NC}"
    if pgrep -f "ollama" >/dev/null 2>&1; then
        local ollama_pid=$(pgrep -f "ollama")
        local ollama_mem=$(ps -o pmem= -p "$ollama_pid" | xargs)
        echo -e "  Status: ${GREEN}Rodando${NC} (PID: $ollama_pid)"
        echo -e "  Memória: ${ollama_mem}%"
    else
        echo -e "  Status: ${RED}Parado${NC}"
    fi
    echo ""

    # Dask
    echo -e "${WHITE}Dask:${NC}"
    if pgrep -f "dask-scheduler" >/dev/null 2>&1; then
        local scheduler_pid=$(pgrep -f "dask-scheduler")
        echo -e "  Scheduler: ${GREEN}Rodando${NC} (PID: $scheduler_pid)"
    else
        echo -e "  Scheduler: ${RED}Parado${NC}"
    fi

    local worker_count=$(pgrep -f "dask-worker" | wc -l)
    if [ "$worker_count" -gt 0 ]; then
        echo -e "  Workers: ${GREEN}${worker_count} ativos${NC}"
    else
        echo -e "  Workers: ${RED}Nenhum ativo${NC}"
    fi
    echo ""

    # Docker
    echo -e "${WHITE}Docker:${NC}"
    if command_exists docker && docker info >/dev/null 2>&1; then
        local containers=$(docker ps | wc -l)
        local containers_running=$((containers - 1))  # Subtrai o header
        echo -e "  Status: ${GREEN}Rodando${NC}"
        echo -e "  Containers: ${containers_running}"
    else
        echo -e "  Status: ${RED}Parado${NC}"
    fi

    echo ""
    echo -e "${CYAN}Pressione qualquer tecla para voltar...${NC}"
    read -n 1
}

# Mostra logs recentes
show_recent_logs() {
    clear_screen
    show_header

    echo -e "${YELLOW}📝 LOGS RECENTES${NC}"
    echo ""

    # Monitor logs
    if [ -f "${LOGS_DIR}/monitor.log" ]; then
        echo -e "${WHITE}Monitor Log:${NC}"
        tail -10 "${LOGS_DIR}/monitor.log" | sed 's/^/  /'
        echo ""
    fi

    # Alert logs
    if [ -f "${ALERTS_DIR}/alerts.log" ]; then
        echo -e "${WHITE}Alert Log:${NC}"
        tail -10 "${ALERTS_DIR}/alerts.log" | sed 's/^/  /'
        echo ""
    fi

    echo -e "${CYAN}Pressione qualquer tecla para voltar...${NC}"
    read -n 1
}

# Mostra todos os alertas
show_all_alerts() {
    clear_screen
    show_header

    echo -e "${YELLOW}🚨 TODOS OS ALERTAS${NC}"
    echo ""

    local alerts_file="${ALERTS_DIR}/alerts.log"
    if [ -f "$alerts_file" ]; then
        local alert_count=$(wc -l < "$alerts_file")
        echo -e "${WHITE}Total de alertas: ${alert_count}${NC}"
        echo ""

        if [ "$alert_count" -gt 0 ]; then
            cat "$alerts_file" | while read -r line; do
                if echo "$line" | grep -q "CRITICAL"; then
                    echo -e "${RED}  $line${NC}"
                elif echo "$line" | grep -q "WARNING"; then
                    echo -e "${YELLOW}  $line${NC}"
                else
                    echo -e "${WHITE}  $line${NC}"
                fi
            done
        fi
    else
        echo -e "${GREEN}Nenhum alerta registrado${NC}"
    fi

    echo ""
    echo -e "${CYAN}Pressione qualquer tecla para voltar...${NC}"
    read -n 1
}

# Mostra métricas detalhadas
show_detailed_metrics() {
    clear_screen
    show_header

    echo -e "${YELLOW}📊 MÉTRICAS DETALHADAS${NC}"
    echo ""

    # CPU detalhado
    echo -e "${WHITE}CPU:${NC}"
    local cpu_info=$(top -bn1 | grep "Cpu(s)")
    echo -e "  $cpu_info"
    echo ""

    # Memória detalhada
    echo -e "${WHITE}Memória:${NC}"
    free -h | sed 's/^/  /'
    echo ""

    # Disco detalhado
    echo -e "${WHITE}Disco:${NC}"
    df -h / | sed 's/^/  /'
    echo ""

    # Rede
    echo -e "${WHITE}Rede:${NC}"
    if command_exists ifconfig; then
        ifconfig | grep -E "RX packets|TX packets" | head -2 | sed 's/^/  /'
    else
        ip -s link | grep -E "RX:|TX:" | head -4 | sed 's/^/  /'
    fi

    echo ""
    echo -e "${CYAN}Pressione qualquer tecla para voltar...${NC}"
    read -n 1
}

# ==================== FUNÇÃO PRINCIPAL ====================

main() {
    # Verificar se estamos em um terminal adequado
    if [ ! -t 1 ]; then
        echo "Este dashboard requer um terminal interativo."
        exit 1
    fi

    # Criar diretórios necessários
    mkdir -p "$ALERTS_DIR"

    # Loop principal do dashboard
    while true; do
        clear_screen
        show_header

        # Mostrar seções do dashboard
        show_system_metrics
        show_services_status
        show_android_workers
        show_recent_alerts
        show_quick_stats
        show_menu

        # Aguardar entrada do usuário
        read -n 1 -s input
        case "$input" in
            r|R)
                # Atualizar - apenas continua o loop
                ;;
            d|D)
                show_service_details
                ;;
            l|L)
                show_recent_logs
                ;;
            a|A)
                show_all_alerts
                ;;
            m|M)
                show_detailed_metrics
                ;;
            q|Q)
                clear_screen
                echo -e "${GREEN}Dashboard encerrado. Até logo!${NC}"
                exit 0
                ;;
            *)
                # Comando inválido - continua
                ;;
        esac
    done
}

main "$@"
