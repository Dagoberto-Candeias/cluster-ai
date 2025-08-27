#!/bin/bash
# Wrapper script para o instalador universal do Cluster AI
# Este script mantém compatibilidade com a documentação existente
# mas usa o novo sistema universal de instalação

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNIVERSAL_SCRIPT="$SCRIPT_DIR/scripts/installation/universal_install.sh"
MAIN_SCRIPT="$SCRIPT_DIR/scripts/installation/main.sh"

echo "=== Cluster AI Universal Installer Wrapper ==="
echo "Sistema de instalação universal para qualquer distribuição Linux"

# Verificar se é root
if [ "$EUID" -ne 0 ]; then
    echo "Este script requer privilégios sudo"
    echo "Execute com: sudo ./install_cluster_universal.sh"
    exit 1
fi

# Mostrar opções
echo ""
echo "📋 OPÇÕES DE INSTALAÇÃO:"
echo "1. Instalação Universal Completa (Recomendado)"
echo "   - Sistema operacional + Docker + CUDA/ROCm"
echo "2. Instalação Tradicional (Menu interativo)"
echo "3. Apenas Configurar Ambiente Virtual"
echo "4. Apenas Instalar VSCode Otimizado"
echo "5. Verificar Saúde do Sistema"

read -p "Selecione a opção [1-5]: " choice

case $choice in
    1)
        echo "Executando instalação universal completa..."
        if [ -f "$UNIVERSAL_SCRIPT" ]; then
            exec "$UNIVERSAL_SCRIPT"
        else
            echo "Erro: Script universal não encontrado em $UNIVERSAL_SCRIPT"
            exit 1
        fi
        ;;
    2)
        echo "Executando instalação tradicional..."
        if [ -f "$MAIN_SCRIPT" ]; then
            exec "$MAIN_SCRIPT" "$@"
        else
            echo "Erro: Script principal não encontrado em $MAIN_SCRIPT"
            exit 1
        fi
        ;;
    3)
        echo "Configurando ambiente virtual..."
        if [ -f "$SCRIPT_DIR/scripts/installation/venv_setup.sh" ]; then
            exec "$SCRIPT_DIR/scripts/installation/venv_setup.sh"
        else
            echo "Erro: Script de ambiente virtual não encontrado"
            exit 1
        fi
        ;;
    4)
        echo "Instalando VSCode otimizado..."
        if [ -f "$SCRIPT_DIR/scripts/installation/vscode_optimized.sh" ]; then
            exec "$SCRIPT_DIR/scripts/installation/vscode_optimized.sh"
        else
            echo "Erro: Script do VSCode não encontrado"
            exit 1
        fi
        ;;
    5)
        echo "Verificando saúde do sistema..."
        if [ -f "$SCRIPT_DIR/scripts/utils/health_check.sh" ]; then
            exec "$SCRIPT_DIR/scripts/utils/health_check.sh"
        else
            echo "Erro: Script de saúde não encontrado"
            exit 1
        fi
        ;;
    *)
        echo "Opção inválida. Executando instalação universal completa..."
        if [ -f "$UNIVERSAL_SCRIPT" ]; then
            exec "$UNIVERSAL_SCRIPT"
        else
            echo "Erro: Script universal não encontrado"
            exit 1
        fi
        ;;
esac
