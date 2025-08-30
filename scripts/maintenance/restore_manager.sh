#!/bin/bash
# Gerenciador de Restauração para o Cluster AI
# Descrição: Restaura configurações, modelos Ollama e dados de containers a partir de um backup.

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Configurações ---
BACKUP_BASE_DIR="${PROJECT_ROOT}/backups"
OPENWEBUI_CONTAINER_NAME="open-webui"

# --- Funções ---

show_help() {
    echo "Uso: $0"
    echo "Inicia um assistente interativo para restaurar o sistema a partir de um backup."
}

list_backups() {
    section "Backups Disponíveis em $BACKUP_BASE_DIR"
    if [ ! -d "$BACKUP_BASE_DIR" ] || [ -z "$(ls -A "$BACKUP_BASE_DIR"/*.tar.gz 2>/dev/null)" ]; then
        warn "Nenhum backup encontrado."
        return 1
    fi
    
    local i=1
    # Usa mapfile para ler arquivos em um array, ls -1t ordena por tempo (mais novo primeiro)
    mapfile -t backups < <(ls -1t "$BACKUP_BASE_DIR"/*.tar.gz)
    for backup in "${backups[@]}"; do
        echo "  $i) $(basename "$backup")"
        ((i++))
    done
    return 0
}

# Para os serviços que serão afetados pela restauração
stop_services_for_restore() {
    subsection "Parando serviços necessários para a restauração"
    if command_exists docker && docker ps --format '{{.Names}}' | grep -q "^${OPENWEBUI_CONTAINER_NAME}$"; then
        log "Parando container OpenWebUI..."
        sudo docker stop "$OPENWEBUI_CONTAINER_NAME" >/dev/null
        success "Container OpenWebUI parado."
    fi
    if service_active ollama; then
        log "Parando serviço Ollama..."
        sudo systemctl stop ollama
        success "Serviço Ollama parado."
    fi
}

# Reinicia os serviços após a restauração
start_services_after_restore() {
    subsection "Reiniciando serviços após a restauração"
    if command_exists docker && docker ps -a --format '{{.Names}}' | grep -q "^${OPENWEBUI_CONTAINER_NAME}$"; then
        log "Iniciando container OpenWebUI..."
        sudo docker start "$OPENWEBUI_CONTAINER_NAME" >/dev/null
        success "Container OpenWebUI iniciado."
    fi
    if ! service_active ollama; then
        log "Iniciando serviço Ollama..."
        sudo systemctl start ollama
        success "Serviço Ollama iniciado."
    fi
}

# Função para obter o caminho de um volume Docker
get_docker_volume_path() {
    local volume_name="$1"
    if ! command_exists docker; then return 1; fi
    if command_exists jq; then
        sudo docker volume inspect "$volume_name" | jq -r '.[0].Mountpoint' 2>/dev/null
    else
        sudo docker volume inspect "$volume_name" | grep "Mountpoint" | awk -F'"' '{print $4}' 2>/dev/null
    fi
}

# Função principal de restauração
do_restore() {
    section "Assistente de Restauração do Cluster AI"
    
    if ! list_backups; then return 1; fi
    
    echo ""
    read -p "Digite o número do backup que deseja restaurar (ou 'q' para cancelar): " choice

    if [[ "$choice" == "q" || "$choice" == "Q" ]]; then
        log "Restauração cancelada."
        return 0
    fi

    mapfile -t backups < <(ls -1t "$BACKUP_BASE_DIR"/*.tar.gz)
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#backups[@]} ]; then
        error "Seleção inválida."
        return 1
    fi

    local backup_to_restore="${backups[$((choice-1))]}"
    log "Restaurando a partir de: $(basename "$backup_to_restore")"

    if ! confirm_operation "Esta ação irá SOBRESCREVER dados atuais com o conteúdo do backup. Deseja continuar?"; then
        log "Restauração cancelada."
        return 0
    fi

    local staging_dir; staging_dir=$(mktemp -d); trap 'rm -rf "$staging_dir"' EXIT
    log "Extraindo backup para um diretório temporário..."
    tar -xzf "$backup_to_restore" -C "$staging_dir"

    stop_services_for_restore

    # Restaurar arquivos do HOME do usuário (inclui .ollama, .ssh, .cluster_config, etc.)
    if [ -d "$staging_dir/user_home" ]; then
        subsection "Restaurando configurações e dados do usuário"
        rsync -av --chown=$(whoami):$(whoami) "$staging_dir/user_home/" "$HOME/"
        success "Configurações e dados do usuário restaurados."
    fi

    # Restaurar dados do Docker
    if [ -d "$staging_dir/docker_volumes_data" ]; then
        subsection "Restaurando dados de volumes Docker"
        local webui_volume_path; webui_volume_path=$(get_docker_volume_path "open-webui")
        if [ -n "$webui_volume_path" ] && [ -d "$webui_volume_path" ]; then
            log "Restaurando dados para o volume 'open-webui' em $webui_volume_path..."
            sudo rsync -av --delete "$staging_dir/docker_volumes_data/" "$webui_volume_path/"
            success "Dados do volume 'open-webui' restaurados."
        else
            warn "Volume Docker 'open-webui' não encontrado no sistema. Pulando restauração de dados Docker."
        fi
    fi

    start_services_after_restore

    echo ""
    success "🎉 Restauração concluída com sucesso!"
    info "Verifique se os serviços estão funcionando como esperado."
}

# --- Execução ---
main() {
    if [[ "${1:-}" == "help" ]]; then
        show_help
    else
        if [[ $EUID -eq 0 ]]; then
            error "Este script não deve ser executado como root. Use sudo quando solicitado."
            return 1
        fi
        do_restore
    fi
}

main "$@"