#!/bin/bash

# Script para verificar e instalar modelos Ollama

echo "=== Verificando modelos instalados ==="

# Lista de modelos a serem verificados
MODELS=("llama3" "deepseek-coder" "mistral" "llava" "phi3" "codellama" "mixtral")

# Função para verificar se um modelo está instalado
check_model_installed() {
    local model=$1
    if ollama list | grep -q "$model"; then
        echo "✓ Modelo $model já está instalado."
        return 0
    else
        echo "✗ Modelo $model não está instalado."
        return 1
    fi
}

# Verificar cada modelo
for model in "${MODELS[@]}"; do
    check_model_installed "$model"
done

# Perguntar ao usuário se deseja instalar o modelo mixtral
read -p "Deseja instalar o modelo mixtral? (s/n): " install_mixtral
if [[ "$install_mixtral" == "s" ]]; then
    echo "Instalando modelo mixtral..."
    ollama pull "mixtral"
    echo "Modelo mixtral instalado com sucesso."
else
    echo "Modelo mixtral não será instalado."
fi
