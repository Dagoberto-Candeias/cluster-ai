#!/bin/bash
# Script para processar registro automático de workers no servidor
# Autor: Dagoberto Candeias <betoallnet@gmail.com>

set -euo pipefail

# --- Configurações ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
CONFIG_DIR="$HOME/.cluster_config"
WORKERS_CONFIG="$CONFIG_DIR/workers.conf"
AUTHORIZED_KEYS_DIR="$CONFIG_DIR/authorized_keys"

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[REGISTRO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Funções ---

# Verificar se worker já está registrado
is_worker_registered() {
    local worker_name="$1"
    local worker_ip="$2"

    if [ ! -f "$WORKERS_CONFIG" ]; then
        return 1
    fi

    grep -q "^$worker_name $worker_ip" "$WORKERS_CONFIG"
}

# Adicionar worker à configuração
add_worker_to_config() {
    local worker_name="$1"
    local worker_ip="$2"
    local worker_user="$3"
    local worker_port="$4"
    local public_key="$5"

    # Criar diretório se não existir
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$AUTHORIZED_KEYS_DIR"

    # Adicionar à configuração de workers
    echo "# Registrado automaticamente em $(date)" >> "$WORKERS_CONFIG"
    echo "$worker_name $worker_ip $worker_user $worker_port active" >> "$WORKERS_CONFIG"

    # Salvar chave pública
    echo "$public_key" > "$AUTHORIZED_KEYS_DIR/${worker_name}.pub"

    # Adicionar à authorized_keys do usuário atual (opcional)
    if [ -f "$HOME/.ssh/authorized_keys" ]; then
        if ! grep -q "$public_key" "$HOME/.ssh/authorized_keys"; then
            echo "$public_key" >> "$HOME/.ssh/authorized_keys"
            log "Chave SSH adicionada ao authorized_keys"
        fi
    else
        mkdir -p "$HOME/.ssh"
        echo "$public_key" > "$HOME/.ssh/authorized_keys"
        chmod 600 "$HOME/.ssh/authorized_keys"
        log "Arquivo authorized_keys criado"
    fi

    success "Worker '$worker_name' registrado com sucesso"
}

# Validar dados do worker
validate_worker_data() {
    local worker_name="$1"
    local worker_ip="$2"
    local worker_user="$3"
    local worker_port="$4"
    local public_key="$5"

    # Validar nome
    if [[ ! "$worker_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "Nome do worker inválido: $worker_name"
        return 1
    fi

    # Validar IP
    if ! [[ "$worker_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        error "IP inválido: $worker_ip"
        return 1
    fi

    # Validar usuário
    if [[ ! "$worker_user" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "Usuário inválido: $worker_user"
        return 1
    fi

    # Validar porta
    if ! [[ "$worker_port" =~ ^[0-9]+$ ]] || [ "$worker_port" -lt 1 ] || [ "$worker_port" -gt 65535 ]; then
        error "Porta inválida: $worker_port"
        return 1
    fi

    # Validar chave pública (formato SSH-RSA)
    if [[ ! "$public_key" =~ ^ssh-rsa ]]; then
        error "Chave pública inválida"
        return 1
    fi

    return 0
}

# Processar arquivo de registro
process_registration_file() {
    local reg_file="$1"

    if [ ! -f "$reg_file" ]; then
        error "Arquivo de registro não encontrado: $reg_file"
        return 1
    fi

    log "Processando arquivo de registro: $reg_file"

    # Ler conteúdo do arquivo JSON
    local json_content
    json_content=$(cat "$reg_file")

    # Extrair dados do JSON usando uma abordagem mais robusta
    # Remove quebras de linha e espaços extras para facilitar o parsing
    json_content=$(echo "$json_content" | tr -d '\n' | sed 's/  */ /g')

    # Extrair valores usando expressões regulares mais específicas
    local worker_name=""
    local worker_ip=""
    local worker_user=""
    local worker_port=""
    local public_key=""

    # Extrair worker_name
    if [[ "$json_content" =~ \"worker_name\"\s*:\s*\"([^\"]*)\" ]]; then
        worker_name="${BASH_REMATCH[1]}"
    fi

    # Extrair worker_ip
    if [[ "$json_content" =~ \"worker_ip\"\s*:\s*\"([^\"]*)\" ]]; then
        worker_ip="${BASH_REMATCH[1]}"
    fi

    # Extrair worker_user
    if [[ "$json_content" =~ \"worker_user\"\s*:\s*\"([^\"]*)\" ]]; then
        worker_user="${BASH_REMATCH[1]}"
    fi

    # Extrair worker_port
    if [[ "$json_content" =~ \"worker_port\"\s*:\s*\"([^\"]*)\" ]]; then
        worker_port="${BASH_REMATCH[1]}"
    fi

    # Extrair public_key (pode conter espaços, então usa uma abordagem diferente)
    if [[ "$json_content" =~ \"public_key\"\s*:\s*\"([^\"]*ssh-rsa[^\"]*)\" ]]; then
        public_key="${BASH_REMATCH[1]}"
    fi

    # Debug: mostrar valores extraídos
    log "Valores extraídos:"
    log "  worker_name: '$worker_name'"
    log "  worker_ip: '$worker_ip'"
    log "  worker_user: '$worker_user'"
    log "  worker_port: '$worker_port'"
    log "  public_key: '$public_key'"

    # Verificar se todos os campos foram extraídos
    if [ -z "$worker_name" ] || [ -z "$worker_ip" ] || [ -z "$worker_user" ] || [ -z "$worker_port" ] || [ -z "$public_key" ]; then
        error "Falha ao extrair todos os campos obrigatórios do JSON"
        error "Campos faltando:"
        [ -z "$worker_name" ] && error "  - worker_name"
        [ -z "$worker_ip" ] && error "  - worker_ip"
        [ -z "$worker_user" ] && error "  - worker_user"
        [ -z "$worker_port" ] && error "  - worker_port"
        [ -z "$public_key" ] && error "  - public_key"
        return 1
    fi

    # Validar dados
    if ! validate_worker_data "$worker_name" "$worker_ip" "$worker_user" "$worker_port" "$public_key"; then
        return 1
    fi

    # Verificar se já está registrado
    if is_worker_registered "$worker_name" "$worker_ip"; then
        warn "Worker '$worker_name' ($worker_ip) já está registrado"
        return 0
    fi

    # Adicionar worker
    add_worker_to_config "$worker_name" "$worker_ip" "$worker_user" "$worker_port" "$public_key"

    # Log do registro
    log "Worker registrado: $worker_name ($worker_ip:$worker_port) - Usuário: $worker_user"

    return 0
}

# Função principal
main() {
    local reg_file="$1"

    if [ $# -ne 1 ]; then
        error "Uso: $0 <arquivo_registro.json>"
        exit 1
    fi

    log "Iniciando processamento de registro de worker..."

    if process_registration_file "$reg_file"; then
        success "Registro de worker processado com sucesso"
        exit 0
    else
        error "Falha no processamento do registro"
        exit 1
    fi
}

# Executar função principal
main "$@"
