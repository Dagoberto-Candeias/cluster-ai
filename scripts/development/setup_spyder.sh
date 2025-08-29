#!/bin/bash
# Script de Setup para a IDE Spyder
# Instala o Spyder no ambiente virtual principal do projeto.

# Carregar funções comuns para logging e cores
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
    section "Configurando Spyder IDE"

    if [ ! -d "$VENV_PATH" ]; then
        error "Ambiente virtual '$VENV_PATH' não encontrado. Execute a configuração do Python primeiro."
        return 1
    fi

    log "Ativando ambiente virtual: $VENV_PATH"
    source "$VENV_PATH/bin/activate"

    if python -c "import spyder" >/dev/null 2>&1; then
        log "Spyder já está instalado no ambiente."
    else
        log "Instalando Spyder... Isso pode levar alguns minutos."
        pip install spyder >/dev/null
        success "Spyder instalado com sucesso."
    fi

    deactivate
    log "Ambiente virtual desativado."
}

main