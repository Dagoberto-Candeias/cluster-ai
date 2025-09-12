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
        log "INFO" "Ollama já está instalado."
        return 0
    fi

    log "INFO" "Instalando Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh

    if ! command_exists ollama; then
        error "A instalação do Ollama falhou."
        return 1
    fi
    success "Ollama instalado com sucesso."
}

# Configura o serviço Ollama (systemd)
configure_ollama_service() {
    log "INFO" "Configurando serviço Ollama para iniciar com o sistema e escutar em todas as interfaces..."
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

# Verifica espaço em disco disponível
check_disk_space() {
    local required_gb="$1"
    local available_gb
    
    available_gb=$(df -BG ~ | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if [ "$available_gb" -lt "$required_gb" ]; then
        warn "Espaço em disco insuficiente. Disponível: ${available_gb}GB, Necessário: ${required_gb}GB"
        return 1
    fi
    return 0
}

# Verifica memória disponível
check_memory() {
    local required_gb="$1"
    local available_gb

    available_gb=$(free -g | awk '/Mem:/ {print $7}')

    # Validar se available_gb é um número antes da comparação
    if ! [[ "$available_gb" =~ ^[0-9]+$ ]] || [ -z "$available_gb" ]; then
        warn "Não foi possível determinar a memória disponível do sistema"
        return 1
    fi

    if [ "$available_gb" -lt "$required_gb" ]; then
        warn "Memória RAM insuficiente. Disponível: ${available_gb}GB, Recomendado: ${required_gb}GB"
        return 1
    fi
    return 0
}

# Baixa modelos com verificação de recursos
download_models() {
    if ! command_exists ollama; then
        error "Comando 'ollama' não encontrado. Não é possível baixar modelos."
        return 1
    fi

    log "INFO" "Iniciando download dos modelos essenciais do Ollama..."
    
    local failed_models=()
    local skipped_models=()
    
    for model in "${OLLAMA_MODELS[@]}"; do
        log "INFO" "Verificando modelo: $model..."
        
        # Verificar requisitos antes de baixar
        case $model in
            *8b*|*7b*)
                if ! check_disk_space 20 || ! check_memory 8; then
                    warn "Pulando modelo $model devido a recursos insuficientes"
                    skipped_models+=("$model")
                    continue
                fi
                ;;
            *13b*|*large*)
                if ! check_disk_space 40 || ! check_memory 16; then
                    warn "Pulando modelo $model devido a recursos insuficientes"
                    skipped_models+=("$model")
                    continue
                fi
                ;;
            *)
                if ! check_disk_space 10 || ! check_memory 4; then
                    warn "Pulando modelo $model devido a recursos insuficientes"
                    skipped_models+=("$model")
                    continue
                fi
                ;;
        esac
        
        # Tentar baixar o modelo
        if ollama pull "$model"; then
            success "Modelo $model baixado com sucesso"
        else
            error "Falha ao baixar modelo $model"
            failed_models+=("$model")
        fi
    done

    # Relatório final
    if [ ${#failed_models[@]} -eq 0 ] && [ ${#skipped_models[@]} -eq 0 ]; then
        success "Download de todos os modelos concluído com sucesso."
    else
        if [ ${#skipped_models[@]} -gt 0 ]; then
            warn "Modelos pulados devido a recursos insuficientes: ${skipped_models[*]}"
        fi
        if [ ${#failed_models[@]} -gt 0 ]; then
            error "Modelos que falharam no download: ${failed_models[*]}"
        fi
        info "Alguns modelos podem não estar disponíveis devido a limitações do sistema"
    fi
    
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