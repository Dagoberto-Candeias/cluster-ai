#!/bin/bash

# 💾 Script para Criação de Backup - Cluster AI
# Descrição: Executa a rotina de backup do sistema.

set -e

# Encontra o diretório raiz do projeto
PROJECT_ROOT=$(dirname "$0")/../..

# Script principal de instalação que contém a lógica de backup
MAIN_SCRIPT="$PROJECT_ROOT/scripts/installation/main.sh"

if [ ! -f "$MAIN_SCRIPT" ]; then
    echo "❌ Erro: Script principal não encontrado em $MAIN_SCRIPT"
    exit 1
fi

echo "▶️  Iniciando processo de backup através do script principal..."
exec "$MAIN_SCRIPT" --backup