#!/bin/bash

# Script de teste simples para descoberta de workers
# Versão simplificada para debugging

set -e

echo "🔍 TESTE DE DESCOBERTA SIMPLES"
echo "=============================="

# Verificar ferramentas disponíveis
echo
echo "📋 Verificando ferramentas disponíveis:"
echo "  arp-scan: $(command -v arp-scan >/dev/null 2>&1 && echo "✅ Disponível" || echo "❌ Não encontrado")"
echo "  nmap: $(command -v nmap >/dev/null 2>&1 && echo "✅ Disponível" || echo "❌ Não encontrado")"
echo "  avahi-browse: $(command -v avahi-browse >/dev/null 2>&1 && echo "✅ Disponível" || echo "❌ Não encontrado")"

# Teste básico de conectividade
echo
echo "🌐 Teste de conectividade de rede:"
echo "  Pingando gateway (192.168.0.1):"
ping -c 2 192.168.0.1 2>/dev/null | head -3 || echo "  ❌ Gateway não responde"

# Verificar tabela ARP atual
echo
echo "📊 Tabela ARP atual:"
arp -n | grep -v incomplete | head -10

# Teste de descoberta simples
echo
echo "🔍 Teste de descoberta simples:"
echo "  Procurando dispositivos na rede 192.168.0.0/24..."

# Método 1: Ping sweep simples
echo
echo "📡 Método 1 - Ping sweep:"
for i in {1..10}; do
    ip="192.168.0.$i"
    if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
        hostname=$(getent hosts "$ip" | awk '{print $2}' || echo "unknown")
        echo "  ✅ $ip ($hostname) - responde ping"
    fi
done

# Método 2: Verificar tabela ARP
echo
echo "📊 Método 2 - Dispositivos na tabela ARP:"
arp -n | while read line; do
    if [[ $line =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        ip=$(echo "$line" | awk '{print $1}')
        mac=$(echo "$line" | awk '{print $3}')
        if [[ "$mac" != "incomplete" && "$mac" != "(incomplete)" ]]; then
            hostname=$(getent hosts "$ip" | awk '{print $2}' || echo "unknown")
            echo "  📱 $ip ($hostname) - MAC: $mac"
        fi
    fi
done

# Método 3: Verificar portas SSH abertas
echo
echo "🔐 Método 3 - Verificação de portas SSH:"
if command -v nmap >/dev/null 2>&1; then
    echo "  Usando nmap para verificar portas SSH..."
    nmap -p 22 --open 192.168.0.0/24 2>/dev/null | grep "Nmap scan report" | head -5 | while read line; do
        ip=$(echo "$line" | sed 's/.*for //' | tr -d '()')
        if [[ -n "$ip" ]]; then
            echo "  🔑 $ip - Porta SSH aberta"
        fi
    done
else
    echo "  ❌ nmap não disponível"
fi

echo
echo "✅ Teste concluído!"
echo
echo "💡 Recomendações:"
echo "  - Instale arp-scan: sudo apt install arp-scan"
echo "  - Instale nmap: sudo apt install nmap"
echo "  - Instale avahi-utils: sudo apt install avahi-utils"
echo "  - Verifique se os dispositivos estão na mesma rede"
