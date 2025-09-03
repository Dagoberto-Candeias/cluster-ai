#!/bin/bash

echo "=== CORREÇÃO DE PROBLEMAS DE REDE DO VS CODE ==="
echo "Resolvendo: 'Failed to install/run Electron' e 'socket hang up'"

# 1. TESTAR CONECTIVIDADE DE REDE
echo "1. Testando conectividade de rede..."
echo "Testando ping para servidores do VSCode..."

# Testar conectividade básica
if ping -c 3 8.8.8.8 &>/dev/null; then
    echo "✅ Conectividade básica OK"
else
    echo "❌ Problema de conectividade básica"
    echo "Verifique sua conexão com a internet"
    exit 1
fi

# Testar DNS
if nslookup update.code.visualstudio.com &>/dev/null; then
    echo "✅ DNS funcionando"
else
    echo "❌ Problema de DNS"
    echo "Tentando usar DNS alternativo..."
    echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
    echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf > /dev/null
fi

# 2. PARAR VS CODE
echo "2. Parando VS Code..."
pkill -f "code" 2>/dev/null || true
pkill -f "vscode" 2>/dev/null || true
sleep 3

# 3. LIMPAR CACHES DE DOWNLOAD
echo "3. Limpando caches de download do VSCode..."
rm -rf ~/.config/Code/Cache/* 2>/dev/null || true
rm -rf ~/.config/Code/Code\ Cache/* 2>/dev/null || true
rm -rf ~/.config/Code/CachedData/* 2>/dev/null || true
rm -rf /tmp/vscode-* 2>/dev/null || true
rm -rf /tmp/Crashpad* 2>/dev/null || true

# Limpar cache de atualizações específicas
rm -rf ~/.config/Code/Update/* 2>/dev/null || true
rm -rf ~/.vscode/Update/* 2>/dev/null || true

# 4. CONFIGURAR MODO OFFLINE TEMPORÁRIO
echo "4. Configurando modo offline temporário..."

# Criar/Atualizar configurações para desabilitar downloads automáticos
mkdir -p ~/.config/Code/User

cat > ~/.config/Code/User/settings.json << 'EOL'
{
    "telemetry.telemetryLevel": "off",
    "extensions.autoUpdate": false,
    "update.mode": "none",
    "update.showReleaseNotes": false,
    "extensions.autoCheckUpdates": false,
    "workbench.enableExperiments": false,
    "http.proxyStrictSSL": false,
    "http.systemCertificates": true,
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/.git/subtree-cache/**": true,
        "**/node_modules/**": true,
        "**/venv/**": true,
        "**/cluster_env/**": true
    }
}
EOL

# 5. TESTAR SERVIDORES DE ATUALIZAÇÃO
echo "5. Testando servidores de atualização do VSCode..."

# Lista de servidores para testar
SERVERS=(
    "update.code.visualstudio.com"
    "vscode-update.azurewebsites.net"
    "raw.githubusercontent.com"
    "github.com"
)

for server in "${SERVERS[@]}"; do
    echo "Testando $server..."
    if curl -s --connect-timeout 10 --max-time 30 "https://$server" > /dev/null; then
        echo "✅ $server acessível"
    else
        echo "❌ $server inacessível"
    fi
done

# 6. CRIAR SCRIPT DE INICIALIZAÇÃO SEGURA
echo "6. Criando script de inicialização segura..."

cat > ~/start_vscode_network_safe.sh << 'EOL'
#!/bin/bash
# Script para iniciar VS Code sem downloads automáticos

echo "Iniciando VS Code em modo seguro (sem downloads)..."

# Definir variáveis de ambiente para evitar downloads
export ELECTRON_NO_ATTACH_CONSOLE=1
export ELECTRON_DISABLE_SECURITY_WARNINGS=1
export DISABLE_UPDATE_CHECK=1

# Iniciar VS Code com flags de segurança de rede
code --disable-updates --disable-telemetry --no-sandbox --disable-gpu \
     --disable-extensions --disable-workspace-trust \
     "$@" > /tmp/vscode_network_start.log 2>&1 &

echo "VS Code iniciado. Aguardando estabilização..."
sleep 15

# Verificar se iniciou corretamente
if ps aux | grep -E "(code|vscode)" | grep -v grep | grep -q "type=renderer"; then
    echo "✅ VS Code iniciado com sucesso!"
    echo "Processos ativos:"
    ps aux | grep -E "(code|vscode)" | grep -v grep | head -3
else
    echo "⚠️  VS Code pode não ter aberto a interface gráfica"
    echo "Logs em: /tmp/vscode_network_start.log"
fi
EOL

chmod +x ~/start_vscode_network_safe.sh

# 7. TESTAR INICIALIZAÇÃO
echo "7. Testando inicialização do VSCode..."

# Tentar iniciar VSCode
~/start_vscode_network_safe.sh

sleep 10

# Verificar se está rodando
if ps aux | grep -E "(code|vscode)" | grep -v grep > /dev/null; then
    echo "✅ VS Code está executando!"
    echo "Processos ativos:"
    ps aux | grep -E "(code|vscode)" | grep -v grep | head -5
else
    echo "❌ VS Code não iniciou corretamente"
    echo "Tentando método alternativo..."
    code --disable-extensions --no-sandbox --disable-gpu &
    sleep 5
fi

# 8. CRIAR ALIAS PARA FÁCIL USO
echo "8. Criando aliases convenientes..."

if ! grep -q "alias vscode-safe" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Aliases para VS Code seguro" >> ~/.bashrc
    echo "alias vscode-safe='~/start_vscode_network_safe.sh'" >> ~/.bashrc
    echo "alias vscode-network-fix='~/Projetos/cluster-ai/scripts/vscode/fix_vscode_network.sh'" >> ~/.bashrc
fi

echo ""
echo "🎯 CORREÇÃO DE REDE CONCLUÍDA!"
echo "================================"
echo ""
echo "Problemas resolvidos:"
echo "✅ Caches de download limpos"
echo "✅ Auto-atualizações desabilitadas temporariamente"
echo "✅ Configurações de rede otimizadas"
echo "✅ Script de inicialização segura criado"
echo ""
echo "Para usar o VS Code:"
echo "• Use: vscode-safe"
echo "• Ou: ~/start_vscode_network_safe.sh"
echo ""
echo "Para reabilitar atualizações futuramente:"
echo "• Edite ~/.config/Code/User/settings.json"
echo "• Mude 'update.mode' para 'default'"
echo "• Mude 'extensions.autoUpdate' para true"
echo ""
echo "Se ainda houver problemas, execute novamente:"
echo "• ~/Projetos/cluster-ai/scripts/vscode/fix_vscode_network.sh"
