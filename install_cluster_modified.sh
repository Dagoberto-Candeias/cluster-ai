#!/bin/bash
# Wrapper script para o instalador principal modificado do Cluster AI
# Este script inclui opções de reset, reconfiguração, reaproveitamento e limpeza

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/scripts/installation/main_modified.sh"

echo "=== Cluster AI Installer Wrapper Modificado ==="
echo "Chamando script principal modificado: $MAIN_SCRIPT"

if [ -f "$MAIN_SCRIPT" ]; then
    # Passar todos os argumentos para o script principal
    exec "$MAIN_SCRIPT" "$@"
else
    echo "Erro: Script principal modificado não encontrado em $MAIN_SCRIPT"
    echo "Verifique se o projeto foi clonado corretamente."
    exit 1
fi
