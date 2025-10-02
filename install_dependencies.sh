#!/bin/bash

# Script para instalar dependências do Cluster AI
# Este script configura o ambiente virtual e instala todas as dependências necessárias

set -e  # Parar em caso de erro

echo "🚀 Iniciando instalação de dependências do Cluster AI..."

# Verificar se Python 3.8+ está instalado
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 não encontrado. Instale Python 3.8 ou superior."
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
REQUIRED_VERSION="3.8"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ Python $PYTHON_VERSION encontrado, mas é necessário Python $REQUIRED_VERSION ou superior."
    exit 1
fi

echo "✅ Python $PYTHON_VERSION encontrado."

# Criar ambiente virtual se não existir
if [ ! -d "cluster-ai-env" ]; then
    echo "📦 Criando ambiente virtual cluster-ai-env..."
    python3 -m venv cluster-ai-env
else
    echo "✅ Ambiente virtual cluster-ai-env já existe."
fi

# Ativar ambiente virtual
echo "🔄 Ativando ambiente virtual..."
source cluster-ai-env/bin/activate

# Atualizar pip
echo "⬆️  Atualizando pip..."
pip install --upgrade pip

# Instalar dependências principais
echo "📚 Instalando dependências do requirements.txt..."
pip install -r requirements.txt

# Instalar dependências de desenvolvimento se existir
if [ -f "requirements-dev.txt" ]; then
    echo "📚 Instalando dependências de desenvolvimento..."
    pip install -r requirements-dev.txt
fi

# Verificar instalação
echo "🔍 Verificando instalação..."
python -c "import flask, fastapi, dask, torch; print('✅ Dependências principais instaladas com sucesso!')"

# Criar diretório models se não existir
if [ ! -d "models" ]; then
    echo "📁 Criando diretório models..."
    mkdir -p models
fi

echo "🎉 Instalação concluída com sucesso!"
echo ""
echo "Para ativar o ambiente virtual em futuras sessões:"
echo "  source cluster-ai-env/bin/activate"
echo ""
echo "Para executar testes:"
echo "  source cluster-ai-env/bin/activate && pytest"
echo ""
echo "Para iniciar serviços:"
echo "  source cluster-ai-env/bin/activate && bash scripts/auto_start_services.sh"
