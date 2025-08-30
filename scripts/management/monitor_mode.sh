#!/bin/bash
# Modo de Monitoramento Contínuo para o Cluster AI
# Este script é projetado para ser executado em um TTY dedicado.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANAGER_SCRIPT="${PROJECT_ROOT}/manager.sh"
INTERVAL=5 # segundos

if [ ! -f "$MANAGER_SCRIPT" ]; then
    echo "ERRO: Script manager.sh não encontrado em $MANAGER_SCRIPT"
    exit 1
fi

# Capturar Ctrl+C para sair de forma limpa
trap 'clear; echo "Modo de monitoramento encerrado."; exit 0' SIGINT

# Loop infinito para monitoramento
while true; do
    clear
    echo "=== MODO DE MONITORAMENTO - CLUSTER AI (Pressione Ctrl+C para sair) ==="
    echo "Atualizando a cada $INTERVAL segundos... | Última atualização: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "--------------------------------------------------------------------"
    bash "$MANAGER_SCRIPT" show_status
    sleep "$INTERVAL"
done