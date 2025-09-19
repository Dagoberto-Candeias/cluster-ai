#!/bin/bash

# Script para configurar automaticamente a autenticação SSH sem senha para os workers listados
# Executar este script no servidor principal do Cluster AI

set -e

# Tentar múltiplos caminhos possíveis para o arquivo de configuração
CONFIG_FILES=(
    "/home/.cluster_config/nodes_list.conf"
    "$HOME/.cluster_config/nodes_list.conf"
    "../../.cluster_config/nodes_list.conf"
    "./.cluster_config/nodes_list.conf"
)

CONFIG_FILE=""
for file in "${CONFIG_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        CONFIG_FILE="$file"
        break
    fi
done

SSH_KEY_PATH="$HOME/.ssh/id_rsa"

log_info() {
    echo -e "\033[0;34m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

log_warning() {
    echo -e "\033[1;33m[WARNING]\033[0m $1"
}

log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar se chave SSH existe, se não, gerar uma
setup_ssh_key() {
    if [[ ! -f "$SSH_KEY_PATH" ]]; then
        log_info "Chave SSH não encontrada. Gerando nova chave..."
        mkdir -p "$HOME/.ssh"
        ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -N "" -C "cluster-ai-auto-$(date +%Y%m%d)"
        log_success "Chave SSH gerada em $SSH_KEY_PATH"
    else
        log_info "Chave SSH já existe em $SSH_KEY_PATH"
    fi
}

# Testar conectividade básica com ping
test_connectivity() {
    local ip="$1"
    local hostname="$2"

    log_info "Testando conectividade com $hostname ($ip)..."

    if ping -c 2 -W 3 "$ip" >/dev/null 2>&1; then
        log_success "Ping para $hostname ($ip) bem-sucedido"
        return 0
    else
        log_warning "Ping para $hostname ($ip) falhou. Worker pode estar offline."
        return 1
    fi
}

# Testar conectividade SSH
test_ssh_connectivity() {
    local ip="$1"
    local user="$2"
    local port="$3"
    local hostname="$4"

    log_info "Testando conectividade SSH com $hostname ($user@$ip:$port)..."

    # Primeiro tentar sem senha (chave já configurada)
    if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "echo 'SSH test successful'" >/dev/null 2>&1; then
        log_success "SSH já configurado para $hostname"
        return 0
    fi

    # Se falhou, tentar com senha (usuário precisa interagir)
    log_info "SSH não configurado. Tentando copiar chave SSH..."
    return 1
}

# Copiar chave SSH para o worker
copy_ssh_key() {
    local ip="$1"
    local user="$2"
    local port="$3"
    local hostname="$4"

    log_info "Copiando chave SSH para $hostname ($user@$ip:$port)..."

    # Adicionar a chave do host ao known_hosts para evitar prompts interativos de segurança
    ssh-keyscan -p "$port" -H "$ip" >> ~/.ssh/known_hosts 2>/dev/null

    # Verificar se ssh-copy-id está disponível
    if ! command_exists ssh-copy-id; then
        log_error "ssh-copy-id não encontrado. Instale-o com: sudo apt install openssh-client"
        return 1
    fi

    # Tentar copiar a chave SSH
    if ssh-copy-id -o ConnectTimeout=10 -p "$port" "$user@$ip"; then
        log_success "Chave SSH copiada com sucesso para $hostname"

        # Verificar se a configuração funcionou
        if ssh -o BatchMode=yes -o ConnectTimeout=5 -p "$port" "$user@$ip" "echo 'SSH verification successful'" >/dev/null 2>&1; then
            log_success "Configuração SSH verificada com sucesso para $hostname"
            return 0
        else
            log_warning "Chave SSH copiada mas verificação falhou para $hostname"
            return 1
        fi
    else
        log_warning "Falha ao copiar chave SSH para $hostname. Você pode precisar:"
        echo "  1. Verificar se o worker está online"
        echo "  2. Digitar a senha do usuário $user quando solicitado"
        echo "  3. Ou configurar manualmente com: ssh-copy-id -p $port $user@$ip"
        return 1
    fi
}

# Função principal
main() {
    echo
    echo "🔐 CONFIGURAÇÃO AUTOMÁTICA DE SSH PARA WORKERS"
    echo "==============================================="
    echo

    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "Arquivo de configuração dos workers não encontrado: $CONFIG_FILE"
        log_info "Execute primeiro: ./manager.sh configure"
        exit 1
    fi

    # Verificar e gerar chave SSH se necessário
    setup_ssh_key

    log_info "Iniciando configuração automática de SSH para workers listados em $CONFIG_FILE"
    echo

    local total_workers=0
    local successful_configs=0
    local failed_configs=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Ignorar linhas vazias e comentários
        if [[ -z "$line" || "$line" =~ ^# ]]; then
            continue
        fi

        # Usar read para parsear a linha de forma mais segura
        local hostname ip user port
        read -r hostname _ ip user port _ <<< "$line"

        if [[ -z "$hostname" ]]; then
            log_warning "Erro ao ler linha: $line"
            continue
        fi

        # Verificar se temos pelo menos hostname e IP
        if [[ -z "$hostname" || -z "$ip" || "$ip" == " " ]]; then
            log_warning "Informações incompletas para worker (hostname: '$hostname', ip: '$ip'), pulando..."
            continue
        fi

        # Definir valores padrão se não especificados
        user="${user:-$USER}"
        port="${port:-22}"

        ((total_workers++))
        echo
        log_info "=== CONFIGURANDO WORKER $total_workers: $hostname ==="

        # Testar conectividade básica
        if ! test_connectivity "$ip" "$hostname"; then
            ((failed_configs++))
            continue
        fi

        # Testar se SSH já está configurado
        if test_ssh_connectivity "$ip" "$user" "$port" "$hostname"; then
            ((successful_configs++))
            continue
        fi

        # Tentar configurar SSH
        if copy_ssh_key "$ip" "$user" "$port" "$hostname"; then
            ((successful_configs++))
        else
            ((failed_configs++))
        fi

    done < "$CONFIG_FILE"

    echo
    echo "==============================================="
    log_success "CONFIGURAÇÃO CONCLUÍDA!"
    echo
    log_info "Resumo:"
    echo "  • Total de workers processados: $total_workers"
    echo "  • Configurações bem-sucedidas: $successful_configs"
    echo "  • Configurações com falha: $failed_configs"

    if [[ $successful_configs -gt 0 ]]; then
        echo
        log_success "✅ Configuração SSH bem-sucedida para $successful_configs worker(s)."
        echo
        log_info "Para verificar o status atualizado, execute:"
        echo "   ./manager.sh status"
    fi

    if [[ $failed_configs -gt 0 ]]; then
        echo
        log_warning "⚠️  Alguns workers não puderam ser configurados automaticamente."
        log_info "Verifique os logs acima e tente configurar manualmente se necessário."
    fi
}

# Executar função principal
main "$@"
