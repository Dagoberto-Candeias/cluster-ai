#!/bin/bash
# -*- coding: utf-8 -*-
#
# Cluster AI - Monitoring Dashboard Script
# Dashboard interativo de monitoramento do Cluster AI
#
# Projeto: Cluster AI
# Autor: Sistema de consolidação automática
# Data: 2024-12-19
# Versão: 1.0.0
#
# Descrição:
#   Script responsável por fornecer um dashboard interativo para monitoramento
#   do Cluster AI. Exibe métricas em tempo real, status de serviços,
#   utilização de recursos e alertas. Suporta modos interativo e contínuo.
#
# Uso:
#   ./scripts/monitoring/dashboard.sh [opções]
#
# Dependências:
#   - bash
#   - curl, wget
#   - jq (para parsing JSON)
#   - bc (para cálculos)
#   - dialog (para interface interativa)
#
# Changelog:
#   v1.0.0 - 2024-12-19: Criação inicial com funcionalidades completas
#
# ============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório base
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
DASHBOARD_LOG="$LOG_DIR/dashboard.log"

# Configurações
UPDATE_INTERVAL=5
MAX_HISTORY=100
DASHBOARD_PORT=8081

# Arrays para controle
METRICS_HISTORY=()
ALERTS=()

# Funções utilitárias
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar dependências
check_dependencies() {
    log_info "Verificando dependências do dashboard..."

    local missing_deps=()
    local required_commands=(
        "curl"
        "jq"
        "bc"
        "dialog"
    )

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Dependências faltando: ${missing_deps[*]}"
        log_info "Instale as dependências necessárias e tente novamente"
        return 1
    fi

    log_success "Dependências verificadas"
    return 0
}

# Função para coletar métricas do sistema
collect_system_metrics() {
    local timestamp=$(date +%s)

    # CPU
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')

    # Memória
    local mem_info=$(free | grep Mem)
    local mem_total=$(echo "$mem_info" | awk '{print $2}')
    local mem_used=$(echo "$mem_info" | awk '{print $3}')
    local mem_usage=$(echo "scale=2; $mem_used * 100 / $mem_total" | bc)

    # Disco
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

    # Rede
    local net_rx=$(cat /proc/net/dev | grep eth0 | awk '{print $2}')
    local net_tx=$(cat /proc/net/dev | grep eth0 | awk '{print $10}')

    # Criar métrica
    local metric="{\"timestamp\":$timestamp,\"cpu\":$cpu_usage,\"memory\":$mem_usage,\"disk\":$disk_usage,\"net_rx\":$net_rx,\"net_tx\":$net_tx}"

    # Adicionar ao histórico
    METRICS_HISTORY+=("$metric")

    # Manter tamanho do histórico
    if [ ${#METRICS_HISTORY[@]} -gt $MAX_HISTORY ]; then
        METRICS_HISTORY=("${METRICS_HISTORY[@]:1}")
    fi

    echo "$metric"
}

# Função para verificar status dos serviços
check_services_status() {
    local services=(
        "dask-scheduler:8786"
        "dask-worker:8787"
        "ollama:11434"
        "openwebui:3000"
        "nginx:80"
        "prometheus:9090"
        "grafana:3001"
    )

    local status_report=""

    for service in "${services[@]}"; do
        local name=$(echo "$service" | cut -d: -f1)
        local port=$(echo "$service" | cut -d: -f2)

        if curl -s "http://localhost:$port" > /dev/null 2>&1; then
            status_report+="$name: 🟢 ONLINE\n"
        else
            status_report+="$name: 🔴 OFFLINE\n"
            ALERTS+=("$name service is down on port $port")
        fi
    done

    echo -e "$status_report"
}

# Função para gerar relatório de alertas
generate_alerts_report() {
    if [ ${#ALERTS[@]} -eq 0 ]; then
        echo "✅ Nenhum alerta ativo"
        return 0
    fi

    echo "⚠️  Alertas Ativos:"
    for alert in "${ALERTS[@]}"; do
        echo "  - $alert"
    done
}

# Função para exibir dashboard interativo
show_interactive_dashboard() {
    local temp_file=$(mktemp)

    while true; do
        # Coletar métricas
        local metrics=$(collect_system_metrics)
        local services=$(check_services_status)
        local alerts=$(generate_alerts_report)

        # Criar conteúdo do dashboard
        cat > "$temp_file" << EOF
\ZbCluster AI - Monitoring Dashboard
====================================

\ZbSistema:
$(date)

\ZbMétricas em Tempo Real:
$metrics

\ZbStatus dos Serviços:
$services

\ZbAlertas:
$alerts

\ZbHistórico (últimas 5 métricas):
$(printf '%s\n' "${METRICS_HISTORY[@]: -5}")

\ZbOpções:
[1] Atualizar
[2] Exportar Relatório
[3] Configurações
[4] Sair
EOF

        # Exibir dialog
        dialog --title "Cluster AI Dashboard" --textbox "$temp_file" 20 80

        # Verificar opção selecionada
        local choice
        read -r choice

        case $choice in
            1)
                continue
                ;;
            2)
                export_report
                ;;
            3)
                show_settings
                ;;
            4)
                break
                ;;
        esac
    done

    rm -f "$temp_file"
}

# Função para exportar relatório
export_report() {
    local report_file="$LOG_DIR/dashboard_report_$(date +%Y%m%d_%H%M%S).json"

    cat > "$report_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "system_metrics": [$(printf '"%s",' "${METRICS_HISTORY[@]}" | sed 's/,$//')],
    "services_status": "$(check_services_status | tr '\n' ' ')",
    "alerts": ["$(printf '"%s",' "${ALERTS[@]}" | sed 's/,$//')"]
}
EOF

    log_success "Relatório exportado: $report_file"
}

# Função para exibir configurações
show_settings() {
    dialog --title "Configurações do Dashboard" --msgbox "Intervalo de atualização: $UPDATE_INTERVAL segundos\nPorta do dashboard: $DASHBOARD_PORT\nMáximo de histórico: $MAX_HISTORY" 10 50
}

# Função para modo contínuo
run_continuous_mode() {
    log_info "Iniciando modo contínuo (Ctrl+C para parar)..."

    while true; do
        clear
        echo "=== Cluster AI - Monitoring Dashboard ==="
        echo "$(date)"
        echo ""

        collect_system_metrics
        echo "Status dos Serviços:"
        check_services_status
        echo ""
        echo "Alertas:"
        generate_alerts_report
        echo ""
        echo "Próxima atualização em $UPDATE_INTERVAL segundos..."

        sleep $UPDATE_INTERVAL
    done
}

# Função para iniciar servidor web
start_web_server() {
    log_info "Iniciando servidor web do dashboard na porta $DASHBOARD_PORT..."

    # Verificar se porta está em uso
    if netstat -tuln 2>/dev/null | grep -q ":$DASHBOARD_PORT "; then
        log_warning "Porta $DASHBOARD_PORT já está em uso"
        return 1
    fi

    # Criar página HTML simples
    cat > /tmp/dashboard.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Cluster AI Dashboard</title>
    <meta http-equiv="refresh" content="5">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .metric { background: #f0f0f0; padding: 10px; margin: 5px; }
        .alert { color: red; }
        .success { color: green; }
    </style>
</head>
<body>
    <h1>Cluster AI - Monitoring Dashboard</h1>
    <div id="content">Carregando...</div>

    <script>
        async function updateDashboard() {
            try {
                const response = await fetch('/api/metrics');
                const data = await response.json();
                document.getElementById('content').innerHTML = `
                    <p><strong>Última atualização:</strong> ${new Date().toLocaleString()}</p>
                    <div class="metric"><strong>CPU:</strong> ${data.cpu}%</div>
                    <div class="metric"><strong>Memória:</strong> ${data.memory}%</div>
                    <div class="metric"><strong>Disco:</strong> ${data.disk}%</div>
                    <div class="metric"><strong>Serviços:</strong> ${data.services}</div>
                    <div class="alert"><strong>Alertas:</strong> ${data.alerts}</div>
                `;
            } catch (error) {
                document.getElementById('content').innerHTML = '<p>Erro ao carregar dados</p>';
            }
        }

        setInterval(updateDashboard, 5000);
        updateDashboard();
    </script>
</body>
</html>
EOF

    # Iniciar servidor Python simples
    python3 -m http.server $DASHBOARD_PORT > "$DASHBOARD_LOG" 2>&1 &
    local server_pid=$!

    log_success "Servidor web iniciado (PID: $server_pid)"
    log_info "Acesse: http://localhost:$DASHBOARD_PORT"

    # Aguardar interrupção
    trap "kill $server_pid; rm -f /tmp/dashboard.html" INT
    wait $server_pid
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    # Criar diretório de logs
    mkdir -p "$LOG_DIR"
    touch "$DASHBOARD_LOG"

    local mode="${1:-interactive}"

    case "$mode" in
        "interactive")
            check_dependencies || exit 1
            show_interactive_dashboard
            ;;
        "continuous")
            check_dependencies || exit 1
            run_continuous_mode
            ;;
        "web")
            start_web_server
            ;;
        "export")
            check_dependencies || exit 1
            collect_system_metrics
            export_report
            ;;
        "help"|*)
            echo "Cluster AI - Monitoring Dashboard Script"
            echo ""
            echo "Uso: $0 [modo]"
            echo ""
            echo "Modos:"
            echo "  interactive   - Dashboard interativo (padrão)"
            echo "  continuous    - Modo contínuo no terminal"
            echo "  web           - Servidor web do dashboard"
            echo "  export        - Exportar relatório JSON"
            echo "  help          - Mostra esta mensagem"
            echo ""
            echo "Configurações:"
            echo "  - Intervalo de atualização: $UPDATE_INTERVAL segundos"
            echo "  - Porta do servidor web: $DASHBOARD_PORT"
            echo "  - Máximo de histórico: $MAX_HISTORY"
            echo ""
            echo "Exemplos:"
            echo "  $0 interactive"
            echo "  $0 continuous"
            echo "  $0 web"
            echo "  $0 export"
            ;;
    esac
}

# Executar função principal
main "$@"
