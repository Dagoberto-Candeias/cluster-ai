#!/bin/bash
# Modo de Monitoramento Contínuo para o Cluster AI
# Este script é projetado para ser executado em um TTY dedicado.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANAGER_SCRIPT="${PROJECT_ROOT}/manager.sh"
NETWORK_DISCOVERY_SCRIPT="${PROJECT_ROOT}/scripts/management/network_discovery.sh"
INTERVAL=10 # segundos

if [ ! -f "$MANAGER_SCRIPT" ]; then
    echo "ERRO: Script manager.sh não encontrado em $MANAGER_SCRIPT"
    exit 1
fi

# Capturar Ctrl+C para sair de forma limpa
trap 'clear; echo "Modo de monitoramento encerrado."; exit 0' SIGINT

# Função para mostrar status dos nós de rede
show_network_status() {
    local nodes_file="$HOME/.cluster_config/nodes_list.conf"

    if [ ! -f "$nodes_file" ]; then
        echo "📡 Rede: Nenhum nó configurado"
        return
    fi

    local online_nodes=0
    local total_nodes=0

    while IFS= read -r line; do
        [[ $line =~ ^# ]] && continue
        [[ -z $line ]] && continue

        total_nodes=$((total_nodes + 1))
        local ip
        ip=$(echo "$line" | awk '{print $2}')

        if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
            online_nodes=$((online_nodes + 1))
        fi
    done < "$nodes_file"

    echo "📡 Rede: $online_nodes/$total_nodes nós online"
}

# Função para mostrar métricas do sistema
show_system_metrics() {
    echo "💻 Sistema: $(uptime | awk '{print $1, $2, $3}' | sed 's/,//g')"
    echo "🔧 CPU: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
    echo "🧠 RAM: $(free | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
    echo "💾 Disco: $(df / | awk 'NR==2{print $5}')"
}

# Loop infinito para monitoramento
while true; do
    clear
    echo "=================================================================================="
    echo "                    🎛️  CLUSTER AI - MONITORAMENTO CONTÍNUO 🎛️"
    echo "=================================================================================="
    echo "Atualizando a cada $INTERVAL segundos | $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Pressione Ctrl+C para sair"
    echo "=================================================================================="
    echo

    # Status dos serviços principais
    echo "🔍 STATUS DOS SERVIÇOS:"
    echo "----------------------------------------------------------------------------------"

    # Verificar serviços manualmente para mais controle
    if command_exists docker && docker info >/dev/null 2>&1; then
        echo "🐳 Docker:             ✅ Ativo"
    else
        echo "🐳 Docker:             ❌ Inativo"
    fi

    if timeout 2 bash -c "echo >/dev/tcp/localhost/8786" 2>/dev/null; then
        echo "📊 Dask Scheduler:     ✅ Ativo (porta 8786)"
    else
        echo "📊 Dask Scheduler:     ❌ Inativo"
    fi

    if timeout 2 bash -c "echo >/dev/tcp/localhost/8787" 2>/dev/null; then
        echo "📈 Dask Dashboard:     ✅ Ativo (porta 8787)"
    else
        echo "📈 Dask Dashboard:     ❌ Inativo"
    fi

    if timeout 2 bash -c "echo >/dev/tcp/localhost/11434" 2>/dev/null; then
        echo "🧠 Ollama:            ✅ Ativo (porta 11434)"
    else
        echo "🧠 Ollama:            ❌ Inativo"
    fi

    if timeout 2 bash -c "echo >/dev/tcp/localhost/3000" 2>/dev/null; then
        echo "🌐 OpenWebUI:         ✅ Ativo (porta 3000)"
    else
        echo "🌐 OpenWebUI:         ❌ Inativo"
    fi

    if command_exists nginx && pgrep nginx >/dev/null; then
        echo "🌐 Nginx:             ✅ Ativo"
    else
        echo "🌐 Nginx:             ⚪ Inativo"
    fi

    echo
    echo "📊 MÉTRICAS DO SISTEMA:"
    echo "----------------------------------------------------------------------------------"
    show_system_metrics
    echo
    show_network_status
    echo

    # Status detalhado dos nós de rede (se houver)
    local nodes_file="$HOME/.cluster_config/nodes_list.conf"
    if [ -f "$nodes_file" ] && [ -s "$nodes_file" ]; then
        echo "🌐 STATUS DOS NÓS DE REDE:"
        echo "----------------------------------------------------------------------------------"

        local node_count=0
        while IFS= read -r line; do
            [[ $line =~ ^# ]] && continue
            [[ -z $line ]] && continue

            node_count=$((node_count + 1))
            local hostname ip ssh_user
            hostname=$(echo "$line" | awk '{print $1}')
            ip=$(echo "$line" | awk '{print $2}')
            ssh_user=$(echo "$line" | awk '{print $3}')

            # Verificar se está online
            if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
                echo "🟢 Nó $node_count: $hostname ($ip) - Online"
            else
                echo "🔴 Nó $node_count: $hostname ($ip) - Offline"
            fi
        done < "$nodes_file"

        if [ $node_count -eq 0 ]; then
            echo "📝 Nenhum nó configurado"
        fi
        echo
    fi

    echo "=================================================================================="
    echo "💡 DICAS:"
    echo "• Use './manager.sh' para controle completo"
    echo "• Use './scripts/management/network_discovery.sh' para gerenciar nós"
    echo "• Pressione Ctrl+C para sair do monitoramento"
    echo "=================================================================================="

    sleep "$INTERVAL"
done
