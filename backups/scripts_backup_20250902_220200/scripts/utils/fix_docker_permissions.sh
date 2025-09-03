#!/bin/bash

# Script para verificar e corrigir permissões do Docker

echo "=== Verificando configuração do Docker ==="

# Verificar se o usuário está no grupo docker
if groups | grep -q '\bdocker\b'; then
    echo "✓ Usuário está no grupo docker"
else
    echo "✗ Usuário NÃO está no grupo docker"
    echo "Adicionando usuário ao grupo docker..."
    sudo usermod -aG docker $USER
    echo "Reinicie a sessão ou execute: newgrp docker"
fi

# Verificar permissões do socket
echo "Permissões do socket Docker:"
ls -la /var/run/docker.sock

# Verificar se o grupo docker existe
if getent group docker > /dev/null; then
    echo "✓ Grupo docker existe"
else
    echo "✗ Grupo docker não existe"
fi

# Verificar se o Docker está rodando
if sudo systemctl is-active --quiet docker; then
    echo "✓ Serviço Docker está ativo"
else
    echo "✗ Serviço Docker não está ativo"
    sudo systemctl start docker
fi

# Testar conexão com sudo (para verificar se o Docker funciona)
echo "Testando Docker com sudo..."
sudo docker run --rm hello-world > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Docker funciona com sudo"
else
    echo "✗ Docker não funciona mesmo com sudo"
fi

echo ""
echo "=== Solução ==="
echo "1. Execute: newgrp docker"
echo "2. Ou faça logout completo e login novamente"
echo "3. Teste novamente: docker run hello-world"
