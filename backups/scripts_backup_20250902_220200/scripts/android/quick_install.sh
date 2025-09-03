#!/bin/bash
# INSTALAÇÃO RÁPIDA - COPIE E COLE NO TERMUX
# Versão ultra-simplificada para resolver problemas de download

echo "🤖 CLUSTER AI - INSTALAÇÃO ULTRA-RÁPIDA"
echo "======================================"

# Verificar Termux
if [ ! -d "/data/data/com.termux" ]; then
    echo "❌ Este script deve ser executado no Termux!"
    exit 1
fi
echo "✅ Termux detectado"

# Configurar armazenamento
echo "📱 Configurando armazenamento..."
if [ ! -d "$HOME/storage" ]; then
    termux-setup-storage
    sleep 3
fi
echo "✅ Armazenamento OK"

# Corrigir dpkg
echo "🔧 Corrigindo pacotes..."
dpkg --configure -a 2>/dev/null || true

# Atualizar pacotes
echo "📦 Atualizando pacotes..."
pkg update -y

# Instalar dependências
echo "⚙️ Instalando dependências..."
pkg install -y openssh python git curl

# Configurar SSH
echo "🔐 Configurando SSH..."
mkdir -p "$HOME/.ssh"
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    ssh-keygen -t rsa -b 2048 -N "" -f "$HOME/.ssh/id_rsa" -C "termux-$(date +%s)"
fi
sshd

# Baixar projeto
echo "📥 Baixando projeto..."
mkdir -p "$HOME/Projetos"
cd "$HOME/Projetos"

# Tentar múltiplos métodos
if git clone https://github.com/Dagoberto-Candeias/cluster-ai.git cluster-ai 2>/dev/null; then
    echo "✅ Projeto baixado via HTTPS"
elif curl -L -o cluster-ai.zip https://github.com/Dagoberto-Candeias/cluster-ai/archive/main.zip && unzip cluster-ai.zip && mv cluster-ai-main cluster-ai && rm cluster-ai.zip; then
    echo "✅ Projeto baixado via ZIP"
else
    echo "⚠️ Download falhou - configure autenticação posteriormente"
fi

echo ""
echo "=================================================="
echo "🎉 INSTALAÇÃO CONCLUÍDA!"
echo "=================================================="
echo ""
echo "🔑 CHAVE SSH (copie para o servidor principal):"
echo "--------------------------------------------------"
cat "$HOME/.ssh/id_rsa.pub"
echo "--------------------------------------------------"
echo ""
echo "🌐 CONEXÃO:"
echo "   Usuário: $(whoami)"
echo "   IP: $(ip route get 1 | awk '{print $7}' | head -1)"
echo "   Porta: 8022"
echo ""
echo "📋 PRÓXIMOS PASSOS:"
echo "1. Copie a chave SSH acima"
echo "2. No servidor principal: ./manager.sh"
echo "3. Escolha: Gerenciar Workers Remotos (SSH)"
echo ""
echo "🧪 TESTE:"
echo "ssh $(whoami)@$(ip route get 1 | awk '{print $7}' | head -1) -p 8022"
