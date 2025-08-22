#!/bin/bash
# Wrapper script para o instalador principal do Cluster AI
# Este script mantém compatibilidade com a documentação existente
# que referencia install_cluster.sh no diretório raiz

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/scripts/installation/main.sh"

echo "=== Cluster AI Installer Wrapper ==="
echo "Chamando script principal: $MAIN_SCRIPT"

echo -e "\n=== MENU PRINCIPAL ==="
echo "1. Instalar dependências básicas"
echo "2. Configurar ambiente Python"
echo "3. Configurar SSH e trocar chaves"
echo "4. Executar configuração baseada no papel"
echo "5. Alterar papel desta máquina"
echo "6. Ver status do sistema"
echo "7. Reiniciar serviços"
echo "8. Configurar Ambiente de Desenvolvimento"
echo "9. Backup e Restauração"

read -p "Selecione uma opção [1-9]: " choice

case $choice in
    1) install_dependencies ;;
    2) setup_python_env ;;
    3) setup_ssh ;;
    4) setup_based_on_role ;;
    5) define_role ;;
    6) show_status ;;
    7) restart_services ;;
    8) ./scripts/development/setup_dev_environment.sh ;;
    9) install_backup ;;
    *) echo "Opção inválida." ;;
esac

if [ -f "$MAIN_SCRIPT" ]; then
    # Passar todos os argumentos para o script principal
    exec "$MAIN_SCRIPT" "$@"
else
    echo "Erro: Script principal não encontrado em $MAIN_SCRIPT"
    echo "Verifique se o projeto foi clonado corretamente."
    exit 1
fi
