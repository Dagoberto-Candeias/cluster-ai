#!/bin/bash
# Script para autenticação via API do OpenWebUI e obtenção de token

set -euo pipefail

API_URL="http://localhost:3000"
EMAIL="${OPENWEBUI_EMAIL:-betoallnet@gmail.com}"
PASSWORD="${OPENWEBUI_PASSWORD:-your_password_here}"

# Função para realizar login e obter token
login_and_get_token() {
    echo "Tentando fazer login na API..."

    # Usar endpoint correto /api/v1/auths/signin
    local response
    response=$(curl -s -X POST "${API_URL}/api/v1/auths/signin" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}")

    echo "Resposta da API: $response"

    # Extrair token do JSON de resposta (tentar múltiplos formatos)
    local token
    token=$(echo "$response" | grep -oP '(?<="token":")[^"]+' || echo "")

    if [ -z "$token" ]; then
        # Tentar outro formato de extração
        token=$(echo "$response" | jq -r '.token // empty' 2>/dev/null || echo "")
    fi

    if [ -z "$token" ]; then
        echo "Falha ao obter token de autenticação."
        echo "Resposta completa da API: $response"
        return 1
    fi

    echo "Token extraído com sucesso: ${token:0:20}..."
    # Salvar apenas o token JWT em arquivo temporário
    echo "$token" > /tmp/token_jwt.txt
    echo "$token"
}

# Executar login e obter token
if TOKEN=$(login_and_get_token); then
    echo "Token obtido com sucesso!"

    # Salvar token em arquivo temporário para uso posterior
    mkdir -p /tmp
    echo "$TOKEN" > /tmp/token.txt
    echo "Token salvo em /tmp/token.txt"

    # Verificar se o arquivo foi criado corretamente
    if [ -f /tmp/token.txt ] && [ -s /tmp/token.txt ]; then
        echo "Arquivo de token criado com sucesso."

        # Exemplo de uso do token para listar modelos
        echo "Testando uso do token..."
        test_response=$(curl -s -X GET "${API_URL}/api/models" -H "Authorization: Bearer $TOKEN")

        # Verificar se a resposta contém dados de modelos
        if echo "$test_response" | grep -q '"data":'; then
            echo "SUCESSO: API funcionando corretamente!"
            echo "Modelos disponíveis: $(echo "$test_response" | grep -o '"id":"[^"]*"' | head -3 | tr '\n' ' ')"
        else
            echo "ERRO: Resposta inesperada da API: $test_response"
            exit 1
        fi
    else
        echo "ERRO: Falha ao criar arquivo de token"
        return 1
    fi
else
    echo "ERRO: Falha no processo de autenticação"
    exit 1
fi

