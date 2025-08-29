#!/bin/bash
# Script de Setup para o Ollama
# Instala o serviço, baixa modelos e configura para uso com o cluster.

# Carregar funções comuns
COMMON_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO: Script de funções comuns não encontrado em $COMMON_SCRIPT_PATH" >&2
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# --- Variáveis de Configuração ---
# Lista de modelos essenciais para o cluster
OLLAMA_MODELS=(
    "llama3.1:8b"
    "codestral"
    "nomic-embed-text"
    "llava"
)

# --- Funções de Instalação ---

# Instala o serviço Ollama
install_ollama_service() {
    if command_exists ollama; then
        log "Ollama já está instalado."
        return 0
    fi

    log "Instalando Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh

    if ! command_exists ollama; then
        error "A instalação do Ollama falhou."
        return 1
    fi
    success "Ollama instalado com sucesso."
}

# Configura o serviço Ollama (systemd)
configure_ollama_service() {
    log "Configurando serviço Ollama para iniciar com o sistema e escutar em todas as interfaces..."
    sudo systemctl enable ollama >/dev/null 2>&1

    # Configurar para escutar em todas as interfaces e otimizar para GPU
    sudo mkdir -p /etc/systemd/system/ollama.service.d/
    sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null << EOL
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_NUM_PARALLEL=4"
Environment="OLLAMA_MAX_LOADED_MODELS=2"
EOL

    sudo systemctl daemon-reload
    sudo systemctl restart ollama
    success "Serviço Ollama configurado e reiniciado."
}

# Baixa os modelos de IA definidos na lista
download_models() {
    if ! command_exists ollama; then
        error "Comando 'ollama' não encontrado. Não é possível baixar modelos."
        return 1
    fi

    log "Iniciando download dos modelos essenciais do Ollama..."
    for model in "${OLLAMA_MODELS[@]}"; do
        log "Verificando modelo: $model..."
        ollama pull "$model"
    done

    success "Download de modelos concluído."
    ollama list
}

# --- Função Principal ---
main() {
    section "Configurando Ollama e Modelos de IA"
    install_ollama_service
    configure_ollama_service
    download_models
    success "Setup completo do Ollama finalizado."
}

main