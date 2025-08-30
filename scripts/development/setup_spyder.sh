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

# Carregar script de verificação pré-instalação
PRE_INSTALL_CHECK_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../installation" && pwd)/pre_install_check.sh"
if [ ! -f "$PRE_INSTALL_CHECK_PATH" ]; then
    error "Script de verificação pré-instalação não encontrado em $PRE_INSTALL_CHECK_PATH"
    exit 1
fi

# --- Variáveis de Configuração ---
VENV_PATH="$HOME/cluster_env"

# --- Função Principal ---
main() {
    section "Configurando Spyder IDE"
    
    # Executar verificação pré-instalação
    log "Executando verificação pré-instalação..."
    if ! bash "$PRE_INSTALL_CHECK_PATH"; then
        warn "Alguns requisitos não foram atendidos, mas prosseguindo com a instalação..."
    fi

    if [ ! -d "$VENV_PATH" ]; then
        error "Ambiente virtual '$VENV_PATH' não encontrado. Execute a configuração do Python primeiro."
        error "Execute: python3 -m venv $VENV_PATH"
        return 1
    fi

    log "Ativando ambiente virtual: $VENV_PATH"
    source "$VENV_PATH/bin/activate"

    if python -c "import spyder" >/dev/null 2>&1; then
        success "Spyder já está instalado no ambiente."
        log "Para iniciar o Spyder, execute: spyder"
    else
        log "Instalando Spyder... Isso pode levar alguns minutos."
        if pip install spyder; then
            success "Spyder instalado com sucesso."
            log "Para iniciar o Spyder, execute: spyder"
        else
            error "Falha ao instalar Spyder."
            warn "Tente instalar manualmente:"
            warn "1. Ative o ambiente virtual: source $VENV_PATH/bin/activate"
            warn "2. Instale o Spyder: pip install spyder"
            return 1
        fi
    fi

    deactivate
    log "Ambiente virtual desativado."
    
    success "✅ Configuração do Spyder concluída com sucesso!"
}

main
