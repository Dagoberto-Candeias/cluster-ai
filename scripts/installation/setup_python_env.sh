#!/bin/bash
# Script de Setup para o Ambiente Python Universal
# Cria um ambiente virtual e instala todas as dependências de Python.

# Carregar funções comuns para logging e cores
# O caminho é relativo à localização deste script
COMMON_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO: Script de funções comuns não encontrado em $COMMON_SCRIPT_PATH" >&2
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# --- Variáveis de Configuração ---
VENV_PATH="$HOME/cluster_env"

# --- Função Principal ---
main() {
    section "Configurando Ambiente Python Universal"

    if [ ! -d "$VENV_PATH" ]; then
        log "Criando ambiente virtual em '$VENV_PATH'..."
        python3 -m venv "$VENV_PATH"
    else
        log "Ambiente virtual já existe em '$VENV_PATH'."
    fi

    log "Ativando ambiente virtual para instalar pacotes..."
    source "$VENV_PATH/bin/activate"

    log "Atualizando pip..."
    pip install --upgrade pip > /dev/null

    log "Instalando pacotes Python (dask, torch, fastapi, etc.)... Isso pode levar vários minutos."
    pip install "dask[complete]" distributed numpy pandas scipy jupyterlab requests scikit-learn torch torchvision torchaudio transformers fastapi uvicorn pytest httpx > /dev/null

    deactivate
    success "Ambiente Python configurado com sucesso."
}

main