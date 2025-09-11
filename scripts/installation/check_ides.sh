#!/bin/bash

echo "=== Verificação das Instalações das IDEs ==="

# Verificar Spyder
echo "Verificando Spyder..."
if command -v spyder >/dev/null 2>&1; then
    echo "✅ Spyder instalado"
else
    echo "❌ Spyder não encontrado"
fi

# Verificar VSCode
echo "Verificando VSCode..."
if command -v code >/dev/null 2>&1; then
    echo "✅ VSCode instalado"
else
    echo "❌ VSCode não encontrado"
fi

# Verificar PyCharm
echo "Verificando PyCharm..."
if [ -f /opt/pycharm/bin/pycharm.sh ]; then
    echo "✅ PyCharm instalado"
else
    echo "❌ PyCharm não encontrado"
fi

# Verificar RStudio
echo "Verificando RStudio..."
if command -v rstudio >/dev/null 2>&1; then
    echo "✅ RStudio instalado"
else
    echo "❌ RStudio não encontrado"
fi

# Verificar Jamovi
echo "Verificando Jamovi..."
if flatpak list --app | grep -q org.jamovi.jamovi; then
    echo "✅ Jamovi instalado"
else
    echo "❌ Jamovi não encontrado"
fi

echo ""
echo "=== Verificação dos Atalhos ==="

# Verificar atalhos
SHORTCUTS_DIR=~/.local/share/applications

check_shortcut() {
    local name=$1
    local file=$2
    if [ -f "$SHORTCUTS_DIR/$file" ]; then
        echo "✅ Atalho $name encontrado"
    else
        echo "❌ Atalho $name não encontrado"
    fi
}

check_shortcut "Spyder" "spyder-cluster.desktop"
check_shortcut "VSCode" "code.desktop"
check_shortcut "PyCharm" "pycharm-cluster.desktop"
check_shortcut "RStudio" "rstudio-cluster.desktop"
check_shortcut "Jamovi" "jamovi-cluster.desktop"

echo ""
echo "=== Resumo ==="
echo "Para usar qualquer IDE com o ambiente Cluster AI:"
echo "1. Certifique-se de que o ambiente virtual está ativado"
echo "2. Execute a IDE desejada"
echo "3. Para conectar ao cluster Dask, use o código apropriado na IDE"
