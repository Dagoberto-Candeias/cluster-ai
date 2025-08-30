#!/bin/bash
# Gerenciador de Workers Dask Remotos via SSH

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

# --- Arquivos de Configuração ---
NODES_CONFIG_FILE="$HOME/.cluster_config/nodes_list.conf"
# Caminho para o projeto nos nós remotos. ASSUME-SE que seja o mesmo.
REMOTE_PROJECT_PATH="~/Projetos/cluster-ai" # Ajuste se necessário

# --- Funções ---

show_help() {
    echo "Uso: $0 [comando] [argumentos...]"
    echo "Gerencia workers Dask em nós remotos definidos em $NODES_CONFIG_FILE."
    echo ""
    echo "Comandos:"
    echo "  start <scheduler_ip>  - Inicia workers em todos os nós remotos, conectando ao scheduler especificado."
    echo "  stop                  - Para todos os workers em todos os nós remotos."
    echo "  status                - Verifica o status dos workers em todos os nós remotos."
    echo "  check-ssh             - Verifica a conectividade SSH sem senha para todos os nós."
    echo "  help                  - Mostra esta ajuda."
}

# Verifica se o arquivo de nós existe e não está vazio
check_nodes_file() {
    if [ ! -f "$NODES_CONFIG_FILE" ] || [ ! -s "$NODES_CONFIG_FILE" ]; then
        error "Arquivo de lista de nós não encontrado ou vazio em: $NODES_CONFIG_FILE"
        info "Crie o arquivo com o formato 'usuario@hostname' por linha."
        return 1
    fi
    return 0
}

# Lê os nós do arquivo de configuração, ignorando comentários e linhas vazias
get_nodes() {
    grep -vE '^\s*(#|$)' "$NODES_CONFIG_FILE"
}

# Verifica a conectividade SSH sem senha
check_ssh_connectivity() {
    section "Verificando Conectividade SSH"
    if ! check_nodes_file; then return 1; fi
    
    local all_ok=true
    while read -r hostname ip user; do
        log "Testando conexão com: $user@$hostname ($ip)"
        if ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no "$user@$hostname" "echo 'Conexão bem-sucedida'" >/dev/null 2>&1; then
            success "  -> Conexão com $hostname: OK"
        else
            error "  -> Falha na conexão com $hostname. Verifique se a autenticação por chave SSH está configurada."
            all_ok=false
        fi
    done < <(get_nodes)

    if [ "$all_ok" = false ]; then
        return 1
    fi
    return 0
}

# Inicia workers em todos os nós
do_start() {
    local scheduler_ip="$1"
    if [ -z "$scheduler_ip" ]; then
        error "IP do Scheduler não fornecido."
        show_help
        return 1
    fi

    section "Iniciando Workers Dask Remotos"
    if ! check_nodes_file; then return 1; fi

    while read -r hostname ip user; do
        log "Iniciando worker em: $user@$hostname ($ip)"
        # O comando é executado em background no nó remoto
        local remote_cmd="cd ${REMOTE_PROJECT_PATH} && nohup ./scripts/runtime/start_worker.sh ${scheduler_ip}:8786 >/dev/null 2>&1 &"
        
        if ssh -o ConnectTimeout=5 "$user@$hostname" "$remote_cmd"; then
            success "  -> Comando de inicialização enviado para $hostname."
        else
            error "  -> Falha ao enviar comando para $hostname."
        fi
    done < <(get_nodes)
}

# Para workers em todos os nós
do_stop() {
    section "Parando Workers Dask Remotos"
    if ! check_nodes_file; then return 1; fi

    while read -r hostname ip user; do
        log "Parando worker em: $user@$hostname ($ip)"
        if ssh -o ConnectTimeout=5 "$user@$hostname" "pkill -f dask-worker"; then
            success "  -> Comando de parada enviado para $hostname."
        else
            warn "  -> Falha ao parar worker em $hostname (ou nenhum worker estava rodando)."
        fi
    done < <(get_nodes)
}

# Verifica o status dos workers em todos os nós
do_status() {
    section "Status dos Workers Dask Remotos"
    if ! check_nodes_file; then return 1; fi
    
    # Cabeçalho da tabela
    printf "%-25s | %-15s | %-12s | %-8s | %-8s\n" "Hostname" "IP" "Status" "CPU %" "Mem %"
    printf "%s\n" "--------------------------|-----------------|--------------|----------|----------"

    while read -r hostname ip user; do
        if [ -z "$hostname" ]; then continue; fi

        # Comando para obter o uso de CPU e Memória dos processos dask-worker
        local remote_cmd="ps -C dask-worker -o %cpu,%mem --no-headers"
        local status_output
        status_output=$(ssh -o ConnectTimeout=5 "$user@$hostname" "$remote_cmd" 2>/dev/null)

        if [ -n "$status_output" ]; then
            # Agrega os valores se houver múltiplos workers no mesmo nó
            local total_cpu=0
            local total_mem=0
            local worker_count=0
            while read -r cpu mem; do
                total_cpu=$(echo "$total_cpu + $cpu" | bc)
                total_mem=$(echo "$total_mem + $mem" | bc)
                ((worker_count++))
            done <<< "$status_output"
            printf "%-25s | %-15s | ${GREEN}%-12s${NC} | %-8.1f | %-8.1f\n" "$hostname" "$ip" "ATIVO ($worker_count)" "$total_cpu" "$total_mem"
        else
            printf "%-25s | %-15s | ${RED}%-12s${NC} | %-8s | %-8s\n" "$hostname" "$ip" "INATIVO" "N/A" "N/A"
        fi
    done < <(get_nodes)
}

# --- Menu Principal ---
main() {
    case "${1:-help}" in
        start) do_start "${2-}" ;;
        stop) do_stop ;;
        status) do_status ;;
        check-ssh) check_ssh_connectivity ;;
        *) show_help ;;
    esac
}

main "$@"