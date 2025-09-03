#!/bin/bash

# 🎯 SISTEMA DE DESCOBERTA AUTOMÁTICA DE WORKERS
# Descobre, configura e registra workers automaticamente na mesma rede

set -euo pipefail

# --- Carregar Funções Comuns ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Constantes ---
CONFIG_DIR="$HOME/.cluster_config"
NODES_LIST_FILE="$CONFIG_DIR/nodes_list.conf"
DISCOVERY_LOG="$CONFIG_DIR/discovery.log"
SSH_KEY_FILE="$HOME/.ssh/id_rsa"

# Portas SSH padrão
DEFAULT_LINUX_PORT=22
DEFAULT_ANDROID_PORT=8022

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Funções de Logging ---
log_discovery() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$DISCOVERY_LOG"
    log "$message"
}

# --- Funções de Rede ---

# Obter rede local
get_local_network() {
    # Obter IP local
    local local_ip=$(hostname -I | awk '{print $1}')
    if [ -z "$local_ip" ]; then
        error "Não foi possível obter o IP local"
        return 1
    fi

    # Calcular rede (assumindo máscara /24)
    local network=$(echo "$local_ip" | awk -F. '{print $1"."$2"."$3".0/24"}')
    echo "$network"
}

# Escanear portas SSH na rede
scan_ssh_ports() {
    local network="$1"
    local timeout="${2:-2}"

    log_discovery "Escaneando rede $network por portas SSH..."

    # Usar nmap se disponível, senão usar método alternativo
    if command_exists nmap; then
        # Escanear portas 22 e 8022
        nmap -sn "$network" -oG - | awk '/Up$/{print $2}' | while read -r ip; do
            # Testar porta 22 (Linux)
            if timeout "$timeout" bash -c "echo >/dev/tcp/$ip/22" 2>/dev/null; then
                echo "$ip:22"
            fi
            # Testar porta 8022 (Android)
            if timeout "$timeout" bash -c "echo >/dev/tcp/$ip/8022" 2>/dev/null; then
                echo "$ip:8022"
            fi
        done
    else
        warn "nmap não encontrado. Usando método alternativo mais lento..."
        # Método alternativo: testar range de IPs
        local base_ip=$(echo "$network" | awk -F. '{print $1"."$2"."$3}')
        for i in {1..254}; do
            local ip="$base_ip.$i"
            # Pular o próprio IP
            if [ "$ip" = "$(hostname -I | awk '{print $1}')" ]; then
                continue
            fi

            # Testar portas em background para velocidade
            (
                # Porta 22
                if timeout "$timeout" bash -c "echo >/dev/tcp/$ip/22" 2>/dev/null; then
                    echo "$ip:22"
                fi
                # Porta 8022
                if timeout "$timeout" bash -c "echo >/dev/tcp/$ip/8022" 2>/dev/null; then
                    echo "$ip:8022"
                fi
            ) &
        done
        wait
    fi
}

# --- Funções de Verificação de Worker ---

# Verificar se dispositivo é um worker do Cluster AI
check_cluster_worker() {
    local ip="$1"
    local port="$2"
    local user="${3:-}"

    # Determinar usuário baseado na porta
    if [ "$port" = "8022" ]; then
        user="${user:-u0_a249}"  # Android padrão
    else
        user="${user:-$USER}"    # Linux padrão
    fi

    log_discovery "Verificando $ip:$port (usuário: $user)..."

    # Tentar conectar via SSH
    if ssh -o StrictHostKeyChecking=no \
           -o ConnectTimeout=5 \
           -o BatchMode=yes \
           -p "$port" \
           "$user@$ip" \
           "echo 'SSH_OK'" 2>/dev/null; then

        log_discovery "✅ Conexão SSH estabelecida com $ip:$port"

        # Verificar se tem Cluster AI instalado
        local cluster_check
        cluster_check=$(ssh -o StrictHostKeyChecking=no \
                          -o ConnectTimeout=5 \
                          -p "$port" \
                          "$user@$ip" \
                          "test -d ~/Projetos/cluster-ai && echo 'CLUSTER_INSTALLED' || echo 'NO_CLUSTER'" 2>/dev/null)

        if [ "$cluster_check" = "CLUSTER_INSTALLED" ]; then
            log_discovery "🎯 Worker Cluster AI encontrado: $ip:$port"
            echo "WORKER:$ip:$port:$user"
            return 0
        else
            log_discovery "📱 Dispositivo encontrado mas sem Cluster AI: $ip:$port"
            echo "DEVICE:$ip:$port:$user"
            return 1
        fi
    else
        log_discovery "❌ Falha na conexão SSH: $ip:$port"
        return 1
    fi
}

# --- Funções de Configuração ---

# Gerar chave SSH se não existir
ensure_ssh_key() {
    if [ ! -f "$SSH_KEY_FILE" ]; then
        log_discovery "Gerando chave SSH para o servidor..."
        ssh-keygen -t rsa -b 4096 -N "" -f "$SSH_KEY_FILE" -C "cluster-server-$(hostname)"
        success "Chave SSH gerada"
    fi
}

# Configurar worker automaticamente
configure_worker() {
    local ip="$1"
    local port="$2"
    local user="$3"
    local worker_name="$4"

    log_discovery "Configurando worker: $worker_name ($ip:$port)"

    # Copiar chave SSH
    if ssh-copy-id -o StrictHostKeyChecking=no -p "$port" "$user@$ip" 2>/dev/null; then
        log_discovery "✅ Chave SSH copiada para $worker_name"

        # Registrar no arquivo de nós
        mkdir -p "$CONFIG_DIR"
        echo "$worker_name $ip $user $port" >> "$NODES_LIST_FILE"

        # Verificar configuração
        if ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "echo 'Worker $worker_name configurado'" 2>/dev/null; then
            success "🎉 Worker $worker_name configurado com sucesso!"
            return 0
        else
            warn "Worker configurado mas teste de conexão falhou"
            return 1
        fi
    else
        error "Falha ao copiar chave SSH para $worker_name"
        return 1
    fi
}

# --- Funções de Relatório ---

# Gerar relatório de descoberta
generate_report() {
    local discovered_workers="$1"
    local discovered_devices="$2"
    local configured_workers="$3"

    section "📊 RELATÓRIO DE DESCOBERTA"

    echo "Workers Cluster AI descobertos: $discovered_workers"
    echo "Dispositivos descobertos: $discovered_devices"
    echo "Workers configurados: $configured_workers"
    echo

    if [ -f "$NODES_LIST_FILE" ]; then
        echo "📋 Lista atual de workers:"
        cat "$NODES_LIST_FILE" | nl
    fi

    echo
    log_discovery "Relatório gerado: $discovered_workers workers, $discovered_devices dispositivos, $configured_workers configurados"
}

# --- Função Principal de Descoberta ---

# Descobrir workers automaticamente
auto_discover() {
    section "🔍 DESCOBERTA AUTOMÁTICA DE WORKERS"

    # Inicializar contadores
    local discovered_workers=0
    local discovered_devices=0
    local configured_workers=0

    # Garantir que temos chave SSH
    ensure_ssh_key

    # Obter rede local
    local network
    network=$(get_local_network)
    if [ $? -ne 0 ]; then
        error "Não foi possível determinar a rede local"
        return 1
    fi

    log_discovery "Iniciando descoberta na rede: $network"

    # Escanear portas SSH
    local ssh_hosts
    ssh_hosts=$(scan_ssh_ports "$network")

    if [ -z "$ssh_hosts" ]; then
        warn "Nenhum dispositivo com SSH encontrado na rede"
        return 0
    fi

    echo "Dispositivos SSH encontrados:"
    echo "$ssh_hosts" | nl

    # Verificar cada dispositivo
    echo "$ssh_hosts" | while read -r host_info; do
        if [ -n "$host_info" ]; then
            local ip port
            ip=$(echo "$host_info" | cut -d: -f1)
            port=$(echo "$host_info" | cut -d: -f2)

            # Verificar se é worker do Cluster AI
            local check_result
            check_result=$(check_cluster_worker "$ip" "$port")

            if [ $? -eq 0 ]; then
                # É um worker Cluster AI
                local worker_info
                worker_info=$(echo "$check_result" | grep "^WORKER:" | cut -d: -f2-)
                if [ -n "$worker_info" ]; then
                    local worker_ip worker_port worker_user
                    worker_ip=$(echo "$worker_info" | cut -d: -f1)
                    worker_port=$(echo "$worker_info" | cut -d: -f2)
                    worker_user=$(echo "$worker_info" | cut -d: -f3)

                    ((discovered_workers++))

                    # Gerar nome único para o worker
                    local worker_name="worker-$(echo "$worker_ip" | tr '.' '-')"

                    # Verificar se já está configurado
                    if grep -q "$worker_ip" "$NODES_LIST_FILE" 2>/dev/null; then
                        log_discovery "Worker $worker_name já está configurado"
                    else
                        # Configurar worker
                        if configure_worker "$worker_ip" "$worker_port" "$worker_user" "$worker_name"; then
                            ((configured_workers++))
                        fi
                    fi
                fi
            else
                # É um dispositivo mas não worker
                local device_info
                device_info=$(echo "$check_result" | grep "^DEVICE:" | cut -d: -f2-)
                if [ -n "$device_info" ]; then
                    ((discovered_devices++))
                    local device_ip device_port device_user
                    device_ip=$(echo "$device_info" | cut -d: -f1)
                    device_port=$(echo "$device_info" | cut -d: -f2)
                    device_user=$(echo "$device_info" | cut -d: -f3)

                    log_discovery "Dispositivo encontrado: $device_ip:$device_port ($device_user)"
                fi
            fi
        fi
    done

    # Aguardar processos em background
    wait

    # Gerar relatório
    generate_report "$discovered_workers" "$discovered_devices" "$configured_workers"

    success "✅ Descoberta automática concluída!"
}

# --- Menu Interativo ---

show_menu() {
    echo
    echo "🎯 SISTEMA DE DESCOBERTA AUTOMÁTICA DE WORKERS"
    echo
    echo "1) 🔍 Executar Descoberta Automática Completa"
    echo "2) 📋 Mostrar Workers Configurados"
    echo "3) 🧪 Testar Conexão com Worker Específico"
    echo "4) 🗑️  Limpar Lista de Workers"
    echo "5) 📊 Ver Log de Descoberta"
    echo "0) ❌ Sair"
    echo
}

# Testar conexão com worker específico
test_worker_connection() {
    subsection "🧪 Teste de Conexão com Worker"

    read -p "Digite o IP do worker: " worker_ip
    read -p "Digite a porta SSH (padrão 22/8022): " worker_port
    worker_port=${worker_port:-22}
    read -p "Digite o usuário (padrão u0_a249 para Android): " worker_user
    worker_user=${worker_user:-u0_a249}

    log "Testando conexão com $worker_ip:$worker_port ($worker_user)..."

    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "$worker_port" "$worker_user@$worker_ip" "echo 'Teste bem-sucedido!' && hostname && uptime" 2>/dev/null; then
        success "✅ Conexão estabelecida com sucesso!"
    else
        error "❌ Falha na conexão. Verifique:"
        echo "  - IP e porta estão corretos"
        echo "  - SSH está rodando no dispositivo"
        echo "  - Chave SSH foi copiada"
        echo "  - Firewall não está bloqueando"
    fi
}

# Mostrar workers configurados
show_configured_workers() {
    subsection "📋 Workers Configurados"

    if [ -f "$NODES_LIST_FILE" ]; then
        echo "Workers registrados:"
        echo
        cat "$NODES_LIST_FILE" | nl
        echo
        local worker_count=$(wc -l < "$NODES_LIST_FILE")
        success "Total: $worker_count workers configurados"
    else
        warn "Nenhum worker configurado ainda"
        info "Execute a descoberta automática para encontrar workers"
    fi
}

# Limpar lista de workers
clear_worker_list() {
    subsection "🗑️ Limpar Lista de Workers"

    if [ -f "$NODES_LIST_FILE" ]; then
        local worker_count=$(wc -l < "$NODES_LIST_FILE")

        if confirm_operation "Remover todos os $worker_count workers configurados?"; then
            rm -f "$NODES_LIST_FILE"
            success "✅ Lista de workers limpa"
        else
            warn "Operação cancelada"
        fi
    else
        warn "Nenhum worker configurado para remover"
    fi
}

# Ver log de descoberta
show_discovery_log() {
    subsection "📊 Log de Descoberta"

    if [ -f "$DISCOVERY_LOG" ]; then
        echo "Últimas 20 entradas do log:"
        echo
        tail -20 "$DISCOVERY_LOG"
        echo
        info "Log completo: $DISCOVERY_LOG"
    else
        warn "Log de descoberta não encontrado"
    fi
}

# --- Script Principal ---

main() {
    # Criar diretório de configuração se não existir
    mkdir -p "$CONFIG_DIR"

    while true; do
        show_menu
        read -p "Digite sua opção: " choice

        case $choice in
            1) auto_discover ;;
            2) show_configured_workers ;;
            3) test_worker_connection ;;
            4) clear_worker_list ;;
            5) show_discovery_log ;;
            0)
                success "Sistema de descoberta finalizado!"
                exit 0
                ;;
            *)
                error "Opção inválida. Tente novamente."
                ;;
        esac

        echo
        read -p "Pressione Enter para continuar..."
        clear
    done
}

# Executar script principal
main "$@"
