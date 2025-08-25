#!/bin/bash
# Wrapper script para o instalador principal do Cluster AI
# Este script mantém compatibilidade com a documentação existente
# que referencia install_cluster.sh no diretório raiz

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/scripts/installation/main.sh"

echo "=== Cluster AI Installer Wrapper ==="
echo "Chamando script principal: $MAIN_SCRIPT"

if [ -f "$MAIN_SCRIPT" ]; then
    # Passar todos os argumentos para o script principal
    exec "$MAIN_SCRIPT" "$@"
else
    echo "Erro: Script principal não encontrado em $MAIN_SCRIPT"
    echo "Verifique se o projeto foi clonado corretamente."
    exit 1
fi
