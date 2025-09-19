#!/bin/bash
# Gerenciador de Workers Dask Remotos via SSH

set -euo pipefail

# --- Configuração Inicial ---

# --- VERIFICAÇÕES DE SEGURANÇA ---
# Verificar se está sendo executado como root (não recomendado)
if [ "$EUID" -eq 0 ]; then
    echo "ERRO DE SEGURANÇA: Este script não deve ser executado como root (sudo)."
    echo "Execute como usuário normal: ./scripts/management/remote_worker_manager.sh"
    echo ""
    echo "Razões de segurança:"
    echo "- Evita modificações acidentais no sistema"
    echo "- Previne exposição desnecessária de privilégios"
    echo "- Segue melhores práticas de segurança"
    exit 1
fi

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
    echo "  restart               - Reinicia um worker específico em um nó remoto."
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

    while read -r hostname ip user port; do
        log "Parando worker em: $user@$hostname ($ip)"
        if ssh -p "${port:-22}" -o ConnectTimeout=5 "$user@$hostname" "pkill -f dask-worker"; then
            success "  -> Comando de parada enviado para $hostname."
        else
            warn "  -> Falha ao parar worker em $hostname (ou nenhum worker estava rodando)."
        fi
    done < <(get_nodes)
}

# Reinicia um worker específico
do_restart() {
    section "Reiniciar Worker Dask Remoto Específico"
    if ! check_nodes_file; then return 1; fi

    # Listar workers para seleção
    subsection "Selecione o worker para reiniciar:"
    mapfile -t workers < <(get_nodes)
    local i=1
    for worker in "${workers[@]}"; do
        local hostname; hostname=$(echo "$worker" | awk '{print $1}')
        local ip; ip=$(echo "$worker" | awk '{print $2}')
        echo "  $i) $hostname ($ip)"
        ((i++))
    done
    echo "  0) Cancelar"
    echo

    read -p "Digite o número do worker: " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -eq 0 ] || [ "$choice" -gt ${#workers[@]} ]; then
        info "Operação cancelada."
        return 0
    fi

    local selected_worker="${workers[$((choice-1))]}"
    local hostname ip user port
    read -r hostname ip user port <<< "$selected_worker"

    read -p "Digite o IP do Dask Scheduler para reconectar: " scheduler_ip
    if [ -z "$scheduler_ip" ]; then
        error "IP do Scheduler é necessário para reiniciar o worker."
        return 1
    fi

    subsection "Reiniciando worker em: $user@$hostname ($ip)"

    # 1. Parar o worker
    log "Enviando comando de parada..."
    ssh -p "${port:-22}" -o ConnectTimeout=5 "$user@$hostname" "pkill -f dask-worker" || warn "  -> Worker já estava parado ou falha ao parar."
    sleep 2 # Aguardar a finalização do processo

    # 2. Iniciar o worker novamente
    log "Enviando comando de inicialização..."
    local remote_cmd="cd ${REMOTE_PROJECT_PATH} && nohup ./scripts/runtime/start_worker.sh ${scheduler_ip}:8786 >/dev/null 2>&1 &"
    ssh -p "${port:-22}" -o ConnectTimeout=5 "$user@$hostname" "$remote_cmd" && success "  -> Comando de reinicialização enviado com sucesso para $hostname." || error "  -> Falha ao reiniciar worker em $hostname."
}

# Verifica o status dos workers em todos os nós
do_status() {
    section "Status dos Workers Dask Remotos"
    if ! check_nodes_file; then return 1; fi

    # Cabeçalho da tabela aprimorado
    printf "%-20s | %-15s | %-18s | %-15s | %-12s | %-12s | %-12s | %-10s\n" "Hostname" "IP" "Worker Status" "Node CPU Load" "Node Mem %" "Disk Usage" "Dask Mem" "Ping (ms)"
    printf "%s\n" "----------------------|-----------------|--------------------|-----------------|--------------|--------------|--------------|-----------"
    printf "%-20s | %-15s | %-18s | %-15s | %-12s | %-12s | %-12s | %-10s | %-20s\n" "Hostname" "IP" "Worker Status" "Node CPU Load" "Node Mem %" "Disk Usage" "Dask Mem" "Ping (ms)" "Uptime"
    printf "%s\n" "----------------------|-----------------|--------------------|-----------------|--------------|--------------|--------------|-----------|---------------------"

    while read -r hostname ip user port; do
        if [ -z "$hostname" ]; then continue; fi

        # 1. Comando SSH unificado para coletar todas as métricas de uma vez
        # Isso reduz o número de conexões SSH, melhorando a performance.
        local remote_metrics_cmd="
            pgrep -fc dask-worker;
            echo '---';
            nproc 2>/dev/null || echo 1;
            echo '---';
            uptime | awk -F'load average: ' '{print \$2}' | awk '{print \$1}' | tr -d ',';
            echo '---';
            free -m | awk '/Mem:/ {printf \"%d\", \$3/\$2 * 100}';
            echo '---';
            df -h / | awk 'NR==2 {print \$5}';
            echo '---';
            ps -C dask-worker -o rss= | awk '{s+=\$1} END {printf \"%d\", s/1024}';
            echo '---';
            uptime -p;
        "
        local metrics_output
        metrics_output=$(ssh -p "${port:-22}" -o ConnectTimeout=5 "$user@$hostname" "$remote_metrics_cmd" 2>/dev/null)

        # 2. Parsear as métricas
        local worker_count; worker_count=$(echo "$metrics_output" | sed -n '1p')
        local cpu_cores; cpu_cores=$(echo "$metrics_output" | sed -n '2p')
        local node_cpu_load_raw; node_cpu_load_raw=$(echo "$metrics_output" | sed -n '3p')
        local node_mem_perc_raw; node_mem_perc_raw=$(echo "$metrics_output" | sed -n '4p')
        local disk_usage_raw; disk_usage_raw=$(echo "$metrics_output" | sed -n '5p')
        local dask_mem_mb_raw; dask_mem_mb_raw=$(echo "$metrics_output" | sed -n '6p')
        local uptime_raw; uptime_raw=$(echo "$metrics_output" | sed -n '7p')

        # 3. Formatar e colorir as métricas
        local worker_status="${RED}INATIVO${NC}"
        if [[ "${worker_count:-0}" -gt 0 ]]; then
            worker_status="${GREEN}ATIVO (${worker_count})${NC}"
        fi

        # CPU Load
        local node_cpu_load_display="N/A"
        if command_exists bc && [[ -n "$node_cpu_load_raw" ]] && [[ "$cpu_cores" -gt 0 ]]; then
            if (( $(echo "$node_cpu_load_raw > $cpu_cores" | bc -l) )); then
                node_cpu_load_display="${RED}${node_cpu_load_raw}${NC}"
            elif (( $(echo "$node_cpu_load_raw > ($cpu_cores * 0.7)" | bc -l) )); then
                node_cpu_load_display="${YELLOW}${node_cpu_load_raw}${NC}"
            else
                node_cpu_load_display="${GREEN}${node_cpu_load_raw}${NC}"
            fi
        fi

        # Memory
        local node_mem_perc_display="N/A"
        if [[ -n "$node_mem_perc_raw" ]]; then
            if [[ "$node_mem_perc_raw" -gt 85 ]]; then
                node_mem_perc_display="${RED}${node_mem_perc_raw}%${NC}"
            elif [[ "$node_mem_perc_raw" -gt 70 ]]; then
                node_mem_perc_display="${YELLOW}${node_mem_perc_raw}%${NC}"
            else
                node_mem_perc_display="${GREEN}${node_mem_perc_raw}%${NC}"
            fi
        fi

        # Disk Usage
        local disk_usage_display="N/A"
        if [[ -n "$disk_usage_raw" ]]; then
            local disk_perc; disk_perc=$(echo "$disk_usage_raw" | tr -d '%')
            if [[ "$disk_perc" -gt 90 ]]; then
                disk_usage_display="${RED}${disk_usage_raw}${NC}"
            elif [[ "$disk_perc" -gt 75 ]]; then
                disk_usage_display="${YELLOW}${disk_usage_raw}${NC}"
            else
                disk_usage_display="${GREEN}${disk_usage_raw}${NC}"
            fi
        fi

        # Dask Memory
        local dask_mem_display="N/A"
        if [[ "${dask_mem_mb_raw:-0}" -gt 0 ]]; then
            dask_mem_display="${CYAN}${dask_mem_mb_raw} MB${NC}"
        fi

        # Ping
        local ping_ms; ping_ms=$(ping -c 1 -W 1 "$ip" | tail -1 | awk -F'/' '{print $5}' | awk -F'.' '{print $1}')
        local ping_display="N/A"
        if [[ -n "$ping_ms" ]]; then
            ping_display="${GREEN}${ping_ms} ms${NC}"
        fi

        # Uptime
        local uptime_display="N/A"
        if [[ -n "$uptime_raw" ]]; then
            uptime_display="${BLUE}${uptime_raw}${NC}"
        fi

        # 4. Imprimir a linha da tabela com as novas métricas
        printf "%-20s | %-15s | " "$hostname" "$ip"
        print_padded_colored "$worker_status" 18
        printf " | "
        print_padded_colored "$node_cpu_load_display" 15
        printf " | "
        print_padded_colored "$node_mem_perc_display" 12
        printf " | "
        print_padded_colored "$disk_usage_display" 12
        printf " | "
        print_padded_colored "$dask_mem_display" 12
        printf " | "
        print_padded_colored "$ping_display" 10
        printf " | "
        print_padded_colored "$uptime_display" 20
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

    while read -r hostname ip user port; do
        subsection "Executando em: $user@$hostname ($ip)"
        ssh -p "${port:-22}" -o ConnectTimeout=10 "$user@$hostname" "$command_to_run" || error "  -> Falha ao executar comando em $hostname."
    done < <(get_nodes)
}

# --- Menu Principal ---
main() {
    case "${1:-help}" in
        start) do_start "${2-}" ;;
        stop) do_stop ;;
        restart) do_restart ;;
        status) do_status ;;
        check-ssh) check_ssh_connectivity ;;
        exec) do_exec "${*:2}" ;; # Passa todos os argumentos a partir do segundo como um único comando
        *) show_help ;;
    esac
}

main "$@"