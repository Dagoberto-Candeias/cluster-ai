#!/bin/bash
# Script de Setup para o OpenWebUI
# Descrição: Cria o container Docker para o OpenWebUI com limites de recursos otimizados.

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"
OPTIMIZER_SCRIPT="${PROJECT_ROOT}/scripts/management/resource_optimizer.sh"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Constantes ---
CONTAINER_NAME="open-webui"

# --- Funções ---

get_optimized_limits() {
    log "Calculando limites de recursos otimizados para o container..."
    if [ ! -f "$OPTIMIZER_SCRIPT" ]; then
        error "Script otimizador não encontrado em $OPTIMIZER_SCRIPT"
        # Retorna valores padrão se o otimizador não for encontrado
        echo "DOCKER_OPENWEBUI_CPUS=1.0"
        echo "DOCKER_OPENWEBUI_MEMORY=1g"
        return
    fi
    # Executa o otimizador no modo 'get-settings' para obter os valores
    bash "$OPTIMIZER_SCRIPT" get-settings
}

main() {
    section "Configurando OpenWebUI com Limites Otimizados"

    if ! command_exists docker; then
        error "Docker não está instalado ou o daemon não está rodando. Pule a configuração do OpenWebUI."
        return 1
    fi

    if sudo docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        success "O container '$CONTAINER_NAME' já existe. Nenhuma ação necessária."
        log "Para recriá-lo, pare e remova o container primeiro: sudo docker stop $CONTAINER_NAME && sudo docker rm $CONTAINER_NAME"
        return 0
    fi

    local settings; settings=$(get_optimized_limits)
    local cpus; cpus=$(echo "$settings" | grep "DOCKER_OPENWEBUI_CPUS" | cut -d= -f2)
    local memory; memory=$(echo "$settings" | grep "DOCKER_OPENWEBUI_MEMORY" | cut -d= -f2)

    log "Criando container '$CONTAINER_NAME' com os seguintes limites:"
    log "  -> CPUs: $cpus"
    log "  -> Memória: $memory"

    if confirm_operation "Deseja continuar com a criação do container?"; then
        log "Baixando a imagem mais recente do OpenWebUI..."
        sudo docker pull ghcr.io/open-webui/open-webui:main

        log "Criando e iniciando o container..."
        sudo docker run -d -p 3000:8080 \
            --add-host=host.docker.internal:host-gateway \
            --name "$CONTAINER_NAME" \
            --restart always \
            --cpus "$cpus" \
            --memory "$memory" \
            -v open-webui:/app/backend/data \
            ghcr.io/open-webui/open-webui:main

        sleep 5 # Aguardar um momento para o container estabilizar

        if sudo docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            success "Container '$CONTAINER_NAME' criado e iniciado com sucesso!"
            log "Acesse a interface em: http://localhost:3000"
        else
            error "Falha ao criar o container '$CONTAINER_NAME'. Verifique os logs do Docker."
            return 1
        fi
    else
        warn "Criação do container cancelada pelo usuário."
    fi
}

main "$@"