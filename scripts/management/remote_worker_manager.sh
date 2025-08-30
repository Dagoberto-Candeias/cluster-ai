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
    echo "  exec \"<command>\"      - Executa um comando arbitrário em todos os nós remotos."
    echo "  help                  - Mostra esta ajuda."
}

# Função para imprimir uma string colorida com preenchimento para alinhamento de tabela
print_padded_colored() {
    local str_colored="$1"
    local width="$2"
    # Remove códigos de cor para calcular o comprimento real do texto
    local str_uncolored; str_uncolored=$(echo -e "$str_colored" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g")
    local len=${#str_uncolored}
    local padding=$((width - len))

    # Imprime a string colorida e o preenchimento
    echo -ne "$str_colored"
    printf '%*s' "$padding" ''
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
    printf "%-25s | %-15s | %-18s | %-15s | %-12s\n" "Hostname" "IP" "Worker Status" "Node CPU Load" "Node Mem %"
    printf "%s\n" "--------------------------|-----------------|--------------------|-----------------|-------------"

    while read -r hostname ip user; do
        if [ -z "$hostname" ]; then continue; fi

        # 1. Verificar status do worker Dask
        local worker_check_cmd="pgrep -fc dask-worker"
        local worker_count
        worker_count=$(ssh -o ConnectTimeout=5 "$user@$hostname" "$worker_check_cmd" 2>/dev/null || echo 0)

        local worker_status
        if [ "$worker_count" -gt 0 ]; then
            worker_status="${GREEN}ATIVO ($worker_count)${NC}"
        else
            worker_status="${RED}INATIVO${NC}"
        fi

        # 2. Obter métricas gerais do nó (CPU Load e Memória)
        local node_metrics_cmd="uptime | awk -F'load average: ' '{print \$2}' | awk '{print \$1}' | tr -d ','; echo '|'; free -m | awk '/Mem:/ {printf \"%d\", \$3/\$2 * 100}'"
        local metrics_output
        metrics_output=$(ssh -o ConnectTimeout=5 "$user@$hostname" "$node_metrics_cmd" 2>/dev/null)

        local node_cpu_load="N/A"
        local node_mem_perc_raw="N/A"
        local node_mem_perc_display="N/A"

        if [ -n "$metrics_output" ]; then
            node_cpu_load=$(echo "$metrics_output" | cut -d'|' -f1)
            node_mem_perc_raw=$(echo "$metrics_output" | cut -d'|' -f2)

            if [[ "$node_mem_perc_raw" -gt 85 ]]; then
                node_mem_perc_display="${RED}${node_mem_perc_raw}%${NC}"
            elif [[ "$node_mem_perc_raw" -gt 70 ]]; then
                node_mem_perc_display="${YELLOW}${node_mem_perc_raw}%${NC}"
            else
                node_mem_perc_display="${GREEN}${node_mem_perc_raw}%${NC}"
            fi
        fi

        # Imprimir linha da tabela com preenchimento manual para alinhamento
        printf "%-25s | %-15s | " "$hostname" "$ip"
        print_padded_colored "$worker_status" 18
        printf " | %-15s | " "$node_cpu_load"
        print_padded_colored "$node_mem_perc_display" 12
        printf "\n"
    done < <(get_nodes)
}

# Executa um comando arbitrário em todos os nós
do_exec() {
    local command_to_run="$1"
    if [ -z "$command_to_run" ]; then
        error "Nenhum comando fornecido para execução."
        show_help
        return 1
    fi

    section "Executando Comando Remoto em Todos os Nós"
    info "Comando: $command_to_run"
    if ! check_nodes_file; then return 1; fi

    while read -r hostname ip user; do
        subsection "Executando em: $user@$hostname ($ip)"
        ssh -o ConnectTimeout=10 "$user@$hostname" "$command_to_run" || error "  -> Falha ao executar comando em $hostname."
    done < <(get_nodes)
}

# --- Menu Principal ---
main() {
    case "${1:-help}" in
        start) do_start "${2-}" ;;
        stop) do_stop ;;
        status) do_status ;;
        check-ssh) check_ssh_connectivity ;;
        exec) do_exec "${*:2}" ;; # Passa todos os argumentos a partir do segundo como um único comando
        *) show_help ;;
    esac
}

main "$@"