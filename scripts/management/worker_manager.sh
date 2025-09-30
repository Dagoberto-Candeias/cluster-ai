#!/bin/bash
# =============================================================================
# Gerenciador de Workers do Cluster AI
# =============================================================================
# Este script centraliza as funções para monitorar e atualizar os workers
# remotos do cluster. É chamado pelo 'manager.sh'.
#
# Autor: Cluster AI Team
# Versão: 1.0.0
# =============================================================================

set -euo pipefail

# Navega para o diretório raiz do projeto para garantir que os caminhos relativos funcionem
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "$PROJECT_ROOT"

# Carregar funções comuns (biblioteca consolidada)
# shellcheck source=../utils/common_functions.sh
source "scripts/utils/common_functions.sh"
PID_FILE="${PROJECT_ROOT}/.monitor_updates_pid"
WORKER_CONFIG_FILE="${PROJECT_ROOT}/cluster.yaml"

# =============================================================================
# FUNÇÕES DE GERENCIAMENTO DE WORKERS
# =============================================================================

# Monitorar performance de um worker específico
monitor_worker_performance() {
    local worker_name="$1"
    section "MONITORANDO PERFORMANCE: $worker_name"

    if ! command -v yq >/dev/null; then
        error "Comando 'yq' não encontrado."
        return 1
    fi

    # Obter informações do worker
    local worker_info
    worker_info=$(yq e ".workers[\"$worker_name\"]" "$WORKER_CONFIG_FILE" 2>/dev/null)

    if [[ "$worker_info" == "null" ]]; then
        error "Worker '$worker_name' não encontrado na configuração."
        return 1
    fi

    local host user port
    host=$(echo "$worker_info" | yq e '.host' -)
    user=$(echo "$worker_info" | yq e '.user' -)
    port=$(echo "$worker_info" | yq e '.port' -)

    info "Conectando a $user@$host:$port..."

    # Verificar conectividade SSH
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes -p "$port" "$user@$host" "echo 'SSH OK'" >/dev/null 2>&1; then
        error "Não foi possível conectar ao worker $worker_name via SSH."
        return 1
    fi

    # Coletar métricas de sistema
    local cpu_usage mem_usage disk_usage load_avg
    cpu_usage=$(ssh -p "$port" "$user@$host" "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print 100 - \$1}'" 2>/dev/null || echo "N/A")
    mem_usage=$(ssh -p "$port" "$user@$host" "free | grep Mem | awk '{printf \"%.1f\", \$3/\$2 * 100.0}'" 2>/dev/null || echo "N/A")
    disk_usage=$(ssh -p "$port" "$user@$host" "df / | tail -1 | awk '{print \$5}' | sed 's/%//'" 2>/dev/null || echo "N/A")
    load_avg=$(ssh -p "$port" "$user@$host" "uptime | awk -F'load average:' '{ print \$2 }' | sed 's/^ *//'" 2>/dev/null || echo "N/A")

    echo -e "${BOLD}${BLUE}PERFORMANCE METRICS${NC}"
    echo -e "${BLUE}$(printf '%.0s=' {1..50})${NC}"
    echo -e "${CYAN}CPU Usage:${NC} ${cpu_usage}%"
    echo -e "${CYAN}Memory Usage:${NC} ${mem_usage}%"
    echo -e "${CYAN}Disk Usage:${NC} ${disk_usage}%"
    echo -e "${CYAN}Load Average:${NC} ${load_avg}"

    # Verificar processos Dask
    local dask_processes
    dask_processes=$(ssh -p "$port" "$user@$host" "pgrep -f dask" 2>/dev/null || echo "")
    if [[ -n "$dask_processes" ]]; then
        echo -e "${CYAN}Dask Processes:${NC} $(echo "$dask_processes" | wc -l) running"
    else
        echo -e "${CYAN}Dask Processes:${NC} None running"
    fi

    # Log das métricas
    audit_log 'WORKER_PERF' "Worker: $worker_name, CPU: ${cpu_usage}%, MEM: ${mem_usage}%, DISK: ${disk_usage}%"
}

# Auto-scaling baseado em métricas de performance
auto_scale_workers() {
    local cpu_threshold="${1:-80}"
    local mem_threshold="${2:-85}"
    section "AUTO-SCALING WORKERS (CPU>${cpu_threshold}%, MEM>${mem_threshold}%)"

    if ! command -v yq >/dev/null; then
        error "Comando 'yq' não encontrado."
        return 1
    fi

    local workers
    mapfile -t workers < <(yq e '.workers | keys | .[]' "$WORKER_CONFIG_FILE" 2>/dev/null || echo "")

    if [ ${#workers[@]} -eq 0 ]; then
        warn "Nenhum worker configurado para auto-scaling."
        return 1
    fi

    local overloaded_workers=()
    local underutilized_workers=()

    for worker in "${workers[@]}"; do
        local worker_info
        worker_info=$(yq e ".workers[\"$worker\"]" "$WORKER_CONFIG_FILE")

        local host user port
        host=$(echo "$worker_info" | yq e '.host' -)
        user=$(echo "$worker_info" | yq e '.user' -)
        port=$(echo "$worker_info" | yq e '.port' -)

        # Coletar métricas
        local cpu_usage mem_usage
        cpu_usage=$(ssh -o ConnectTimeout=5 -p "$port" "$user@$host" "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print 100 - \$1}'" 2>/dev/null || echo "0")
        mem_usage=$(ssh -o ConnectTimeout=5 -p "$port" "$user@$host" "free | grep Mem | awk '{printf \"%.0f\", \$3/\$2 * 100.0}'" 2>/dev/null || echo "0")

        # Verificar thresholds
        if (( $(echo "$cpu_usage > $cpu_threshold" | bc -l 2>/dev/null || echo "0") )) || \
           (( $(echo "$mem_usage > $mem_threshold" | bc -l 2>/dev/null || echo "0") )); then
            overloaded_workers+=("$worker")
            warn "Worker $worker sobrecarregado (CPU: ${cpu_usage}%, MEM: ${mem_usage}%)"
        elif (( $(echo "$cpu_usage < 20" | bc -l 2>/dev/null || echo "0") )) && \
             (( $(echo "$mem_usage < 30" | bc -l 2>/dev/null || echo "0") )); then
            underutilized_workers+=("$worker")
            info "Worker $worker subutilizado (CPU: ${cpu_usage}%, MEM: ${mem_usage}%)"
        fi
    done

    # Recomendações de auto-scaling
    if [ ${#overloaded_workers[@]} -gt 0 ]; then
        warn "Workers sobrecarregados detectados: ${overloaded_workers[*]}"
        echo "Recomendações:"
        echo "  - Consider redistributing workload"
        echo "  - Add more workers to the cluster"
        echo "  - Check for resource-intensive tasks"
    fi

    if [ ${#underutilized_workers[@]} -gt 0 ]; then
        info "Workers subutilizados detectados: ${underutilized_workers[*]}"
        echo "Recomendações:"
        echo "  - Consider consolidating workload"
        echo "  - Evaluate removing underutilized workers"
    fi

    audit_log 'AUTO_SCALE_CHECK' "Overloaded: ${#overloaded_workers[@]}, Underutilized: ${#underutilized_workers[@]}"
}

# Health check abrangente para workers
health_check_worker() {
    local worker_name="$1"
    section "HEALTH CHECK: $worker_name"

    if ! command -v yq >/dev/null; then
        error "Comando 'yq' não encontrado."
        return 1
    fi

    # Obter informações do worker
    local worker_info
    worker_info=$(yq e ".workers[\"$worker_name\"]" "$WORKER_CONFIG_FILE" 2>/dev/null)

    if [[ "$worker_info" == "null" ]]; then
        error "Worker '$worker_name' não encontrado na configuração."
        return 1
    fi

    local host user port
    host=$(echo "$worker_info" | yq e '.host' -)
    user=$(echo "$worker_info" | yq e '.user' -)
    port=$(echo "$worker_info" | yq e '.port' -)

    local health_status="HEALTHY"
    local issues=()

    echo -e "${BOLD}${BLUE}HEALTH CHECK RESULTS${NC}"
    echo -e "${BLUE}$(printf '%.0s=' {1..50})${NC}"

    # 1. Verificar conectividade SSH
    echo -n "SSH Connectivity: "
    if ssh -o ConnectTimeout=5 -o BatchMode=yes -p "$port" "$user@$host" "echo 'OK'" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        health_status="UNHEALTHY"
        issues+=("SSH connection failed")
    fi

    # 2. Verificar recursos do sistema
    if ssh -p "$port" "$user@$host" "echo 'OK'" >/dev/null 2>&1; then
        # CPU Usage
        local cpu_usage
        cpu_usage=$(ssh -p "$port" "$user@$host" "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\([0-9.]*\)%* id.*/\1/' | awk '{print 100 - \$1}'" 2>/dev/null || echo "N/A")
        echo -n "CPU Usage: "
        if [[ "$cpu_usage" == "N/A" ]]; then
            echo -e "${YELLOW}UNKNOWN${NC}"
        elif (( $(echo "$cpu_usage > 90" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "${RED}${cpu_usage}% (CRITICAL)${NC}"
            health_status="UNHEALTHY"
            issues+=("High CPU usage: ${cpu_usage}%")
        elif (( $(echo "$cpu_usage > 80" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "${YELLOW}${cpu_usage}% (WARNING)${NC}"
            issues+=("High CPU usage: ${cpu_usage}%")
        else
            echo -e "${GREEN}${cpu_usage}% (OK)${NC}"
        fi

        # Memory Usage
        local mem_usage
        mem_usage=$(ssh -p "$port" "$user@$host" "free | grep Mem | awk '{printf \"%.1f\", \$3/\$2 * 100.0}'" 2>/dev/null || echo "N/A")
        echo -n "Memory Usage: "
        if [[ "$mem_usage" == "N/A" ]]; then
            echo -e "${YELLOW}UNKNOWN${NC}"
        elif (( $(echo "$mem_usage > 95" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "${RED}${mem_usage}% (CRITICAL)${NC}"
            health_status="UNHEALTHY"
            issues+=("High memory usage: ${mem_usage}%")
        elif (( $(echo "$mem_usage > 85" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "${YELLOW}${mem_usage}% (WARNING)${NC}"
            issues+=("High memory usage: ${mem_usage}%")
        else
            echo -e "${GREEN}${mem_usage}% (OK)${NC}"
        fi

        # Disk Usage
        local disk_usage
        disk_usage=$(ssh -p "$port" "$user@$host" "df / | tail -1 | awk '{print \$5}' | sed 's/%//'" 2>/dev/null || echo "N/A")
        echo -n "Disk Usage: "
        if [[ "$disk_usage" == "N/A" ]]; then
            echo -e "${YELLOW}UNKNOWN${NC}"
        elif [ "$disk_usage" -gt 95 ]; then
            echo -e "${RED}${disk_usage}% (CRITICAL)${NC}"
            health_status="UNHEALTHY"
            issues+=("High disk usage: ${disk_usage}%")
        elif [ "$disk_usage" -gt 85 ]; then
            echo -e "${YELLOW}${disk_usage}% (WARNING)${NC}"
            issues+=("High disk usage: ${disk_usage}%")
        else
            echo -e "${GREEN}${disk_usage}% (OK)${NC}"
        fi

        # Load Average
        local load_avg
        load_avg=$(ssh -p "$port" "$user@$host" "uptime | awk -F'load average:' '{ print \$2 }' | sed 's/^ *//'" 2>/dev/null || echo "N/A")
        echo -n "Load Average: "
        if [[ "$load_avg" == "N/A" ]]; then
            echo -e "${YELLOW}UNKNOWN${NC}"
        else
            echo -e "${GREEN}${load_avg}${NC}"
        fi
    fi

    # 3. Verificar processos Dask
    echo -n "Dask Processes: "
    if ssh -p "$port" "$user@$host" "echo 'OK'" >/dev/null 2>&1; then
        local dask_count
        dask_count=$(ssh -p "$port" "$user@$host" "pgrep -f dask | wc -l" 2>/dev/null || echo "0")
        if [ "$dask_count" -gt 0 ]; then
            echo -e "${GREEN}${dask_count} running${NC}"
        else
            echo -e "${YELLOW}None running${NC}"
            issues+=("No Dask processes running")
        fi
    else
        echo -e "${RED}Cannot check${NC}"
    fi

    # 4. Verificar conectividade de rede
    echo -n "Network Connectivity: "
    if ssh -p "$port" "$user@$host" "ping -c 1 8.8.8.8" >/dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        health_status="UNHEALTHY"
        issues+=("Network connectivity issues")
    fi

    # 5. Verificar serviços críticos (se aplicável)
    echo -n "Critical Services: "
    local services_ok=true
    if ssh -p "$port" "$user@$host" "systemctl is-active sshd" >/dev/null 2>&1; then
        echo -n "SSH "
    else
        services_ok=false
    fi

    if ssh -p "$port" "$user@$host" "systemctl is-active systemd-networkd" >/dev/null 2>&1 2>/dev/null; then
        echo -n "Network "
    fi

    if $services_ok; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}ISSUES${NC}"
        health_status="UNHEALTHY"
        issues+=("Critical services not running")
    fi

    # Resumo final
    echo ""
    echo -e "${BOLD}OVERALL STATUS:${NC} ${health_status}"
    if [ ${#issues[@]} -gt 0 ]; then
        echo -e "${BOLD}ISSUES FOUND:${NC}"
        for issue in "${issues[@]}"; do
            echo -e "  - $issue"
        done
    fi

    # Log do health check
    audit_log 'WORKER_HEALTH' "Worker: $worker_name, Status: $health_status, Issues: ${#issues[@]}"

    # Retornar status
    if [[ "$health_status" == "HEALTHY" ]]; then
        return 0
    else
        return 1
    fi
}

# Health check para todos os workers
health_check_all_workers() {
    section "HEALTH CHECK - ALL WORKERS"

    if ! command -v yq >/dev/null; then
        error "Comando 'yq' não encontrado."
        return 1
    fi

    local workers
    mapfile -t workers < <(yq e '.workers | keys | .[]' "$WORKER_CONFIG_FILE" 2>/dev/null || echo "")

    if [ ${#workers[@]} -eq 0 ]; then
        warn "Nenhum worker configurado para health check."
        return 1
    fi

    local healthy=0
    local unhealthy=0
    local total=${#workers[@]}

    echo -e "${BOLD}${BLUE}CHECKING ALL WORKERS${NC}"
    echo -e "${BLUE}$(printf '%.0s=' {1..50})${NC}"

    for worker in "${workers[@]}"; do
        echo -e "\n${CYAN}Checking worker: $worker${NC}"
        if health_check_worker "$worker" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ $worker is HEALTHY${NC}"
            ((healthy++))
        else
            echo -e "${RED}✗ $worker is UNHEALTHY${NC}"
            ((unhealthy++))
        fi
    done

    echo ""
    echo -e "${BOLD}${BLUE}SUMMARY${NC}"
    echo -e "${BLUE}$(printf '%.0s=' {1..50})${NC}"
    echo -e "Total workers: $total"
    echo -e "Healthy: ${GREEN}$healthy${NC}"
    echo -e "Unhealthy: ${RED}$unhealthy${NC}"

    if [ $unhealthy -gt 0 ]; then
        warn "$unhealthy worker(s) reported health issues"
        audit_log 'WORKER_HEALTH_SUMMARY' "Total: $total, Healthy: $healthy, Unhealthy: $unhealthy"
        return 1
    else
        success "All workers are healthy"
        audit_log 'WORKER_HEALTH_SUMMARY' "Total: $total, All healthy"
        return 0
    fi
}

# Validar SSH key antes de adicionar worker
validate_ssh_key() {
    local host="$1"
    local user="$2"
    local port="$3"
    section "VALIDANDO CHAVE SSH: $user@$host:$port"

    # Testar conectividade básica
    if ! ssh -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p "$port" "$user@$host" "echo 'SSH connection successful'" >/dev/null 2>&1; then
        error "Falha na conexão SSH com $user@$host:$port"
        echo "Possíveis causas:"
        echo "  - Host inacessível"
        echo "  - Porta incorreta"
        echo "  - Chave SSH não configurada"
        echo "  - Firewall bloqueando conexão"
        return 1
    fi

    success "Conexão SSH estabelecida com sucesso"

    # Verificar se o host tem Python instalado (necessário para Dask)
    if ! ssh -p "$port" "$user@$host" "python3 --version" >/dev/null 2>&1; then
        warn "Python3 não encontrado no worker. Pode ser necessário instalar."
    else
        info "Python3 encontrado no worker"
    fi

    # Verificar espaço em disco
    local disk_space
    disk_space=$(ssh -p "$port" "$user@$host" "df / | tail -1 | awk '{print \$4}'" 2>/dev/null || echo "0")
    if [ "$disk_space" -lt 1000000 ]; then  # Menos de ~1GB
        warn "Espaço em disco baixo no worker: $((disk_space / 1024))MB disponível"
    fi

    # Verificar memória disponível
    local total_mem
    total_mem=$(ssh -p "$port" "$user@$host" "free -m | grep '^Mem:' | awk '{print \$2}'" 2>/dev/null || echo "0")
    if [ "$total_mem" -lt 1024 ]; then  # Menos de 1GB
        warn "Memória baixa no worker: ${total_mem}MB total"
    fi

    success "Validação SSH concluída com sucesso"
    audit_log 'SSH_VALIDATION' "Worker SSH validated: $user@$host:$port"
    return 0
}

start_worker_monitor() {
    section "INICIANDO MONITOR DE WORKERS"
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        warn "Monitor de workers já está rodando."
    else
        info "Iniciando monitor em segundo plano..."
        # O script monitor_worker_updates.sh gerencia seu próprio PID
        nohup bash scripts/monitor_worker_updates.sh start > logs/worker_monitor.log 2>&1 &
        success "Monitor de workers iniciado."
    fi
}

stop_worker_monitor() {
    section "PARANDO MONITOR DE WORKERS"
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        info "Enviando comando de parada para o monitor de workers..."
        # Chama o próprio script do monitor para um encerramento gracioso
        if bash scripts/monitor_worker_updates.sh stop; then
            success "Monitor de workers parado."
        else
            error "Falha ao parar o monitor de workers."
        fi
    else
        warn "Monitor de workers não está rodando."
    fi
}

check_worker_monitor() {
    section "STATUS DO MONITOR DE WORKERS"
    if [ -f "$PID_FILE" ] && ps -p "$(cat "$PID_FILE")" > /dev/null; then
        info "Monitor de workers está ${GREEN}ATIVO${NC}."
        local pid
        pid=$(cat "$PID_FILE")
        echo "PID: $pid"
        echo "Log: $(pwd)/logs/worker_monitor.log"
    else
        info "Monitor de workers está ${RED}INATIVO${NC}."
        rm -f "$PID_FILE" # Limpa o arquivo de PID obsoleto
    fi
}

update_all_workers() {
    section "ATUALIZANDO TODOS OS WORKERS"
    info "Iniciando atualização manual de todos os workers..."
    if python3 scripts/utils/auto_worker_updates.py update; then
        success "Atualização dos workers concluída com sucesso."
    else
        error "Falha na atualização dos workers."
        exit 1
    fi
}

list_workers() {
    section "LISTANDO WORKERS CONFIGURADOS"
    if [ ! -f "$WORKER_CONFIG_FILE" ]; then
        warn "Arquivo de configuração de workers '$WORKER_CONFIG_FILE' não encontrado."
        return 1
    fi

    info "Lendo workers de '$WORKER_CONFIG_FILE'..."
    # Usa yq para ler e formatar a saída do YAML.
    if command -v yq >/dev/null; then
        yq e '.workers | to_entries | .[] | "Worker: " + .key + " | IP: " + .value.host + " | Usuário: " + .value.user + " | Porta: " + .value.port' "$WORKER_CONFIG_FILE"
    else
        error "Comando 'yq' não encontrado. Não é possível listar os workers."
        info "Instale com: sudo pip install yq"
    fi
}

add_worker() {
    section "ADICIONANDO NOVO WORKER"
    # Esta função é interativa e será chamada pelo menu.
    # Para uso em linha de comando, seriam necessários argumentos.

    # Solicitar e validar nome do worker
    local name
    while true; do
        name=$(whiptail --inputbox "Digite um nome único para o worker (ex: worker-01):" 8 78 --title "Adicionar Worker" 3>&1 1>&2 2>&3)
        exit_status=$?
        [ $exit_status -ne 0 ] && warn "Adição cancelada." && return 1

        # Validar nome do worker
        if validate_worker_id "$name" >/dev/null 2>&1; then
            break
        else
            whiptail --msgbox "Nome de worker inválido. Use apenas letras, números, hífens e underscores (máx. 50 caracteres)." 8 78 --title "Erro de Validação"
        fi
    done

    # Solicitar e validar IP
    local host
    while true; do
        host=$(whiptail --inputbox "Digite o endereço IP do worker:" 8 78 --title "Adicionar Worker" 3>&1 1>&2 2>&3)
        exit_status=$?
        [ $exit_status -ne 0 ] && warn "Adição cancelada." && return 1

        # Validar IP
        if validate_input "ip" "$host" >/dev/null 2>&1; then
            break
        else
            whiptail --msgbox "Endereço IP inválido. Use formato IPv4 válido (ex: 192.168.1.100)." 8 78 --title "Erro de Validação"
        fi
    done

    local user
    user=$(whiptail --inputbox "Digite o nome de usuário para a conexão SSH:" 8 78 "dcm" --title "Adicionar Worker" 3>&1 1>&2 2>&3)
    exit_status=$?
    [ $exit_status -ne 0 ] && warn "Adição cancelada." && return 1

    # Solicitar e validar porta
    local port
    while true; do
        port=$(whiptail --inputbox "Digite a porta SSH do worker:" 8 78 "22" --title "Adicionar Worker" 3>&1 1>&2 2>&3)
        exit_status=$?
        [ $exit_status -ne 0 ] && warn "Adição cancelada." && return 1

        # Validar porta
        if validate_input "port" "$port" >/dev/null 2>&1; then
            break
        else
            whiptail --msgbox "Porta inválida. Use um número entre 1-65535." 8 78 --title "Erro de Validação"
        fi
    done

    # Validar conexão SSH antes de adicionar
    info "Validando conexão SSH..."
    if ! validate_ssh_key "$host" "$user" "$port"; then
        if ! (whiptail --title "Continuar Mesmo Assim?" --yesno "Validação SSH falhou. Deseja adicionar o worker mesmo assim?" 8 78); then
            warn "Adição cancelada devido a falha na validação SSH."
            return 1
        fi
    fi

    if (whiptail --title "Confirmar Adição" --yesno "Adicionar o worker '$name' com IP '$host'?" 8 78); then
        if command -v yq >/dev/null; then
            yq e -i ".workers[\"$name\"] = {\"host\": \"$host\", \"user\": \"$user\", \"port\": $port, \"enabled\": true}" "$WORKER_CONFIG_FILE"
            success "Worker '$name' adicionado a '$WORKER_CONFIG_FILE'."
            audit_log 'WORKER_ADD' "Worker added: $name ($user@$host:$port)"
        else
            error "Comando 'yq' não encontrado. Não é possível adicionar o worker."
        fi
    else
        warn "Adição cancelada."
    fi
}

remove_worker() {
    section "REMOVENDO WORKER"
    if ! command -v yq >/dev/null; then
        error "Comando 'yq' não encontrado. Não é possível remover workers."
        return 1
    fi

    local workers
    mapfile -t workers < <(yq e '.workers | keys | .[]' "$WORKER_CONFIG_FILE")
    
    if [ ${#workers[@]} -eq 0 ]; then
        warn "Nenhum worker configurado para remover."
        return 1
    fi

    local menu_options=()
    for worker in "${workers[@]}"; do
        menu_options+=("$worker" "")
    done

    local choice
    choice=$(whiptail --menu "Selecione o worker para remover:" 20 78 10 "${menu_options[@]}" --title "Remover Worker" 3>&1 1>&2 2>&3)
    exit_status=$?
    [ $exit_status -ne 0 ] && warn "Remoção cancelada." && return 1

    if (whiptail --title "Confirmar Remoção" --yesno "Tem certeza que deseja remover o worker '$choice'?" 8 78); then
        yq e -i "del(.workers[\"$choice\"])" "$WORKER_CONFIG_FILE"
        success "Worker '$choice' removido de '$WORKER_CONFIG_FILE'."
    else
        warn "Remoção cancelada."
    fi
}

show_worker_help() {
    echo "Uso: $0 [comando] [opções]"
    echo
    echo "Comandos de gerenciamento de workers:"
    echo -e "  ${GREEN}add${NC}             - Adiciona um novo worker (interativo com validação)."
    echo -e "  ${GREEN}remove${NC}          - Remove um worker existente (interativo)."
    echo -e "  ${GREEN}list${NC}            - Lista todos os workers configurados."
    echo -e "  ${GREEN}monitor <worker>${NC} - Monitora performance de um worker específico."
    echo -e "  ${GREEN}health <worker>${NC}  - Executa health check abrangente em um worker."
    echo -e "  ${GREEN}health-all${NC}       - Executa health check em todos os workers."
    echo -e "  ${GREEN}auto-scale${NC}       - Verifica auto-scaling baseado em carga [cpu_threshold] [mem_threshold]."
    echo -e "  ${GREEN}validate-ssh${NC}     - Valida conexão SSH com um host [host] [user] [port]."
    echo -e "  ${GREEN}start-monitor${NC}   - Inicia o monitor de workers em background."
    echo -e "  ${GREEN}stop-monitor${NC}    - Para o monitor de workers."
    echo -e "  ${GREEN}status-monitor${NC}  - Verifica o status do monitor de workers."
    echo -e "  ${GREEN}update-all${NC}      - Força a atualização de todos os workers."
}

# =============================================================================
# PONTO DE ENTRADA DO SCRIPT
# =============================================================================
case "${1:-help}" in
    start-monitor) start_worker_monitor ;;
    stop-monitor) stop_worker_monitor ;;
    status-monitor) check_worker_monitor ;;
    update-all) update_all_workers ;;
    add) add_worker ;;
    remove) remove_worker ;;
    list) list_workers ;;
    monitor)
        if [ -n "${2:-}" ]; then
            monitor_worker_performance "$2"
        else
            error "Uso: $0 monitor <worker_name>"
            exit 1
        fi ;;
    health)
        if [ -n "${2:-}" ]; then
            health_check_worker "$2"
        else
            error "Uso: $0 health <worker_name>"
            exit 1
        fi ;;
    health-all) health_check_all_workers ;;
    auto-scale) auto_scale_workers "${2:-80}" "${3:-85}" ;;
    validate-ssh)
        if [ -n "${2:-}" ] && [ -n "${3:-}" ] && [ -n "${4:-}" ]; then
            validate_ssh_key "$2" "$3" "$4"
        else
            error "Uso: $0 validate-ssh <host> <user> <port>"
            exit 1
        fi ;;
    *)
      show_worker_help
      exit 1
      ;;
esac
