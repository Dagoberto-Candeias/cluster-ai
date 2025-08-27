#!/bin/bash
# Wrapper script principal do Cluster AI
# Oferece opções para instalação universal ou tradicional

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNIVERSAL_SCRIPT="$SCRIPT_DIR/scripts/installation/universal_install.sh"
MAIN_SCRIPT="$SCRIPT_DIR/scripts/installation/main.sh"
UNIVERSAL_WRAPPER="$SCRIPT_DIR/install_cluster_universal.sh"

echo "=== Cluster AI Installer ==="
echo "Sistema de instalação completo para clusters de IA"

# Verificar se é root para operações de sistema
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Algumas operações requerem privilégios sudo"
    echo "   Para instalação completa, execute: sudo ./install_cluster_universal.sh"
    echo ""
fi

# Mostrar opções
echo "📋 OPÇÕES DISPONÍVEIS:"
echo "1. Instalação Universal Completa (sudo requerido)"
echo "   - Qualquer distro Linux + Docker + CUDA/ROCm"
echo "2. Instalação Tradicional com Menu"
echo "   - Configuração interativa passo a passo"
echo "3. Apenas Configurar Ambiente Python"
echo "   - Ambiente virtual + PyTorch otimizado"
echo "4. Verificar Saúde do Sistema"
echo "5. Sair"

read -p "Selecione a opção [1-5]: " choice

case $choice in
    1)
        if [ "$EUID" -ne 0 ]; then
            echo "❌ Esta opção requer privilégios sudo"
            echo "Execute: sudo ./install_cluster_universal.sh"
            exit 1
        fi
        
        if [ -f "$UNIVERSAL_WRAPPER" ]; then
            exec "$UNIVERSAL_WRAPPER" "1"
        else
            echo "Executando instalação universal diretamente..."
            exec "$UNIVERSAL_SCRIPT"
        fi
        ;;
    2)
        echo "Executando instalação tradicional..."
        if [ -f "$MAIN_SCRIPT" ]; then
            exec "$MAIN_SCRIPT" "$@"
        else
            echo "Erro: Script principal não encontrado"
            exit 1
        fi
        ;;
    3)
        echo "Configurando ambiente Python..."
        if [ -f "$SCRIPT_DIR/scripts/installation/venv_setup.sh" ]; then
            bash "$SCRIPT_DIR/scripts/installation/venv_setup.sh"
        else
            echo "Erro: Script de ambiente virtual não encontrado"
            exit 1
        fi
        ;;
    4)
        echo "Verificando saúde do sistema..."
        if [ -f "$SCRIPT_DIR/scripts/utils/health_check.sh" ]; then
            bash "$SCRIPT_DIR/scripts/utils/health_check.sh"
        else
            echo "Erro: Script de saúde não encontrado"
            exit 1
        fi
        ;;
    5)
        echo "Saindo..."
        exit 0
        ;;
    *)
        echo "Opção inválida. Executando instalação tradicional..."
        if [ -f "$MAIN_SCRIPT" ]; then
            exec "$MAIN_SCRIPT" "$@"
        else
            echo "Erro: Script principal não encontrado"
            exit 1
        fi
        ;;
esac
