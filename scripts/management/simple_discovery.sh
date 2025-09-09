#!/bin/bash

# Script Simples de Descoberta de Workers
# Versão simplificada sem problemas de redirecionamento

set -e

echo "🔍 DESCOBERTA SIMPLES DE WORKERS"
echo "================================"

# Configurações
CONFIG_DIR="$HOME/.cluster_config"
WORKERS_FILE="$CONFIG_DIR/discovered_workers.json"
NODES_FILE="$CONFIG_DIR/nodes_list.conf"

# Criar diretório se não existir
mkdir -p "$CONFIG_DIR"

echo
echo "📊 Executando descoberta ARP..."

# Executar arp-scan e capturar saída
arp_output=$(arp-scan --localnet --quiet 2>/dev/null)

echo
echo "📋 Dispositivos descobertos:"

# Processar saída linha por linha
echo "$arp_output" | while IFS= read -r line; do
    if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        ip=$(echo "$line" | awk '{print $1}')
        mac=$(echo "$line" | awk '{print $2}')
        hostname=$(echo "$line" | awk '{print $3}')

        if [[ -n "$ip" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "  📱 $ip ($hostname) - MAC: $mac"
        fi
    fi
done

echo
echo "🔐 Verificando portas SSH abertas..."

# Verificar portas SSH
nmap_output=$(nmap -p 22 --open 192.168.0.0/24 2>/dev/null)

echo "$nmap_output" | grep "Nmap scan report" | while read line; do
    ip=$(echo "$line" | sed 's/.*for //' | tr -d '()')
    if [[ -n "$ip" ]]; then
        echo "  🔑 $ip - Porta SSH aberta"
    fi
done

echo
echo "✅ Descoberta concluída!"

# Testar conectividade SSH conhecida
echo
echo "🔗 Testando conectividade SSH conhecida..."

# Testar IPs conhecidos
known_ips=("192.168.0.5" "192.168.0.6")

for ip in "${known_ips[@]}"; do
    echo -n "  Testando $ip: "
    if ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no dcm@"$ip" "echo 'OK'" 2>/dev/null; then
        echo "✅ Conectado"
    else
        echo "❌ Falhou"
    fi
done

echo
echo "💡 Para usar o sistema completo, execute:"
echo "  ./scripts/management/auto_discovery_fixed.sh discover"
