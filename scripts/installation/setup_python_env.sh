#!/bin/bash
# Local: scripts/installation/setup_python_env.sh
# Autor: Nome: Dagoberto Candeias. email: betoallnet@gmail.com telefone/whatsapp: +5511951754945
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
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
VENV_PATH="${PROJECT_ROOT}/.venv"

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
    if ! pip install "dask[complete]" distributed numpy pandas scipy jupyterlab requests scikit-learn torch torchvision torchaudio transformers fastapi uvicorn pytest httpx > /dev/null 2>&1; then
        warn "Falha na instalação de alguns pacotes Python. Tentando instalar pacotes individualmente..."
        packages=("dask[complete]" distributed numpy pandas scipy jupyterlab requests scikit-learn torch torchvision torchaudio transformers fastapi uvicorn pytest httpx)
        for pkg in "${packages[@]}"; do
            if ! pip install "$pkg" > /dev/null 2>&1; then
                warn "Falha ao instalar pacote Python: $pkg"
            else
                success "Pacote Python instalado: $pkg"
            fi
        done
    fi

    deactivate
    success "Ambiente Python configurado com sucesso."
}

main
>>>>>>> 
