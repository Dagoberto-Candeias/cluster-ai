#!/bin/bash
# =============================================================================
# Cluster AI - Módulo de Gerenciamento de Workers
# =============================================================================
# Este arquivo contém funções para gerenciamento de workers remotos,
# conexões SSH, descoberta de nós e sincronização.

set -euo pipefail

# Carregar módulos dependentes
if [[ -z "${PROJECT_ROOT:-}" ]]; then
  PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
fi
source "${PROJECT_ROOT}/scripts/core/common.sh"
source "${PROJECT_ROOT}/scripts/core/security.sh"

# =============================================================================
# CONFIGURAÇÃO DE WORKERS
# =============================================================================

# Diretórios de configuração
readonly CLUSTER_CONFIG_DIR="$HOME/.cluster_config"
readonly NODES_LIST_FILE="${CLUSTER_CONFIG_DIR}/nodes_list.conf"
readonly WORKERS_AUTO_FILE="${CLUSTER_CONFIG_DIR}/workers.conf"
readonly AUTHORIZED_KEYS_DIR="${CLUSTER_CONFIG_DIR}/authorized_keys"

# Configurações SSH
readonly SSH_DEFAULT_PORT=22
readonly SSH_ANDROID_PORT=8022
readonly SSH_TIMEOUT=10
readonly SSH_CONNECT_TIMEOUT=5

# =============================================================================
# FUNÇÕES DE CONFIGURAÇÃO DE WORKERS
# =============================================================================

# Inicializar configuração de workers
init_workers_config() {
    # Criar diretórios
    ensure_dir "$CLUSTER_CONFIG_DIR"
    ensure_dir "$AUTHORIZED_KEYS_DIR"

    # Criar arquivo de configuração manual se não existir
    if ! file_exists "$NODES_LIST_FILE"; then
        cat > "$NODES_LIST_FILE" << 'EOF'
# =============================================================================
# Configuração de Workers Remotos para Cluster AI
# Formato: hostname alias IP user port status
# Exemplo: android-worker android 192.168.1.100 u0_a249 8022 active

# Adicione seus workers remotos aqui:
EOF
        info "Arquivo de configuração criado: $NODES_LIST_FILE"
    fi

    # Criar arquivo de workers automáticos se não existir
    if ! file_exists "$WORKERS_AUTO_FILE"; then
        cat > "$WORKERS_AUTO_FILE" << 'EOF'
# Workers registrados automaticamente
# Formato: worker_name worker_ip worker_user worker_port status timestamp
# Status: active, inactive, pending
EOF
        info "Arquivo de workers automáticos criado: $WORKERS_AUTO_FILE"
    fi
}

# Adicionar worker manualmente
add_manual_worker() {
    local name="$1"
    local alias="$2"
    local ip="$3"
    local user="$4"
    local port="$5"

    # Validar entradas
    validate_hostname "$name" || return 1
    validate_hostname "$alias" || return 1
    validate_ip "$ip" || return 1
    validate_username "$user" || return 1
    validate_port "$port" || return 1

    # Verificar se worker já existe
    if grep -q "^$name " "$NODES_LIST_FILE"; then
        error "Worker '$name' já existe na configuração"
        return 1
    fi

    # Adicionar à configuração
    echo "$name $alias $ip $user $port active" >> "$NODES_LIST_FILE"

    success "Worker '$name' ($alias) adicionado à configuração"
    audit_log "WORKER_ADDED" "SUCCESS" "Name: $name, Alias: $alias, IP: $ip, User: $user, Port: $port"

    return 0
}

# Remover worker
remove_worker() {
    local name="$1"

    # Verificar se worker existe
    if ! grep -q "^$name " "$NODES_LIST_FILE"; then
        error "Worker '$name' não encontrado na configuração"
        return 1
    fi

    # Confirmar remoção
    if ! confirm_operation "Remover worker '$name' da configuração?"; then
        return 1
    fi

    # Remover da configuração
    sed -i "/^$name /d" "$NODES_LIST_FILE"

    # Remover chave SSH se existir
    local key_file="${AUTHORIZED_KEYS_DIR}/${name}.pub"
    if file_exists "$key_file"; then
        rm -f "$key_file"
        info "Chave SSH removida: $key_file"
    fi

    success "Worker '$name' removido da configuração"
    audit_log "WORKER_REMOVED" "SUCCESS" "Name: $name"

    return 0
}

# =============================================================================
# FUNÇÕES DE CONECTIVIDADE SSH
# =============================================================================

# Testar conexão SSH básica
test_ssh_connection() {
    local host="$1"
    local user="$2"
    local port="${3:-$SSH_DEFAULT_PORT}"
    local key_file="${4:-}"

    # Validar entradas
    validate_hostname "$host" || return 1
    validate_username "$user" || return 1
    validate_port "$port" || return 1

    audit_log "SSH_CONNECTION_TEST_START" "INFO" "Host: $host, User: $user, Port: $port"

    # Adicionar host ao known_hosts
    ssh-keyscan -p "$port" -H "$host" >> ~/.ssh/known_hosts 2>/dev/null || true

    # Construir comando SSH
    local ssh_cmd="ssh -o BatchMode=yes -o ConnectTimeout=$SSH_CONNECT_TIMEOUT"
    ssh_cmd="$ssh_cmd -o StrictHostKeyChecking=no -p $port"

    if [[ -n "$key_file" ]] && file_exists "$key_file"; then
        ssh_cmd="$ssh_cmd -i $key_file"
    fi

    ssh_cmd="$ssh_cmd $user@$host"

    # Testar conexão
    if $ssh_cmd "echo 'SSH_OK'" >/dev/null 2>&1; then
        audit_log "SSH_CONNECTION_SUCCESS" "SUCCESS" "Host: $host, User: $user, Port: $port"
        return 0
    else
        audit_log "SSH_CONNECTION_FAILED" "ERROR" "Host: $host, User: $user, Port: $port"
        return 1
    fi
}

# Testar conectividade de rede
test_network_connectivity() {
    local host="$1"
    local port="${2:-$SSH_DEFAULT_PORT}"

    # Teste de ping
    if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
        success "✅ Ping para $host: OK"
    else
        warn "❌ Ping para $host: FALHA"
        return 1
    fi

    # Teste de porta
    if timeout 3 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
        success "✅ Porta $port em $host: ABERTA"
        return 0
    else
        error "❌ Porta $port em $host: FECHADA/BLOQUEADA"
        return 1
    fi
}

# Teste completo de conectividade de worker
test_worker_connectivity() {
    local name="$1"
    local ip="$2"
    local user="$3"
    local port="$4"
    local config_file="$5"

    subsection "Testando Conexão com: $name ($user@$ip:$port)"

    local all_ok=true

    # 1. Teste de conectividade de rede
    progress "1/3 - Verificando conectividade de rede..."
    if test_network_connectivity "$ip" "$port"; then
        audit_log "WORKER_NETWORK_OK" "SUCCESS" "Worker: $name, IP: $ip, Port: $port"
    else
        audit_log "WORKER_NETWORK_FAILED" "WARNING" "Worker: $name, IP: $ip, Port: $port"
        all_ok=false
    fi
    sleep 1

    # 2. Teste de resolução de hostname
    progress "2/3 - Verificando resolução de hostname..."
    if [[ "$name" != "$ip" ]]; then
        local resolved_ip
        resolved_ip=$(resolve_hostname "$name" || echo "")
        if [[ -n "$resolved_ip" && "$resolved_ip" == "$ip" ]]; then
            success "✅ Resolução de hostname: OK ($name -> $ip)"
        else
            warn "⚠️  Resolução de hostname: $name não resolve para $ip"
        fi
    fi
    sleep 1

    # 3. Teste de autenticação SSH
    if [[ "$all_ok" == true ]]; then
        progress "3/3 - Testando autenticação SSH..."
        if test_ssh_connection "$ip" "$user" "$port"; then
            success "✅ Autenticação SSH: OK"
            audit_log "WORKER_SSH_SUCCESS" "SUCCESS" "Worker: $name, IP: $ip, User: $user, Port: $port"
        else
            error "❌ Autenticação SSH: FALHA"
            audit_log "WORKER_SSH_FAILED" "ERROR" "Worker: $name, IP: $ip, User: $user, Port: $port"
            all_ok=false
        fi
    else
        warn "Pulando teste SSH devido a falha na conectividade de rede"
    fi

    # Atualizar status na configuração
    if [[ "$all_ok" == true ]]; then
        update_worker_status "$config_file" "$name $ip $user $port" "active"
        success "\n✅ Worker '$name' está ATIVO e pronto para uso"
        audit_log "WORKER_TEST_SUCCESS" "SUCCESS" "Worker: $name"
        return 0
    else
        update_worker_status "$config_file" "$name $ip $user $port" "inactive"
        error "\n❌ Worker '$name' está INATIVO. Verifique os erros acima"
        audit_log "WORKER_TEST_FAILED" "WARNING" "Worker: $name"
        return 1
    fi
}

# Atualizar status do worker no arquivo de configuração
update_worker_status() {
    local config_file="$1"
    local worker_info="$2"
    local status="$3"

    local name ip user port
    read -r name ip user port <<< "$worker_info"

    # Usar sed para atualizar o status
    sed -i "s/^$name $ip $user $port .*/$name $ip $user $port $status/" "$config_file"
}

# =============================================================================
# GERENCIAMENTO DE CHAVES SSH
# =============================================================================

# Copiar chave SSH para worker
copy_ssh_key_to_worker() {
    local name="$1"
    local ip="$2"
    local user="$3"
    local port="$4"

    if ! command_exists ssh-copy-id; then
        error "ssh-copy-id não encontrado. Instale openssh-client"
        return 1
    fi

    info "Copiando chave SSH para $user@$ip:$port..."
    info "Será solicitada a senha do usuário remoto uma vez"

    if ssh-copy-id -p "$port" "$user@$ip" 2>/dev/null; then
        success "Chave SSH copiada com sucesso"
        audit_log "SSH_KEY_COPIED" "SUCCESS" "Worker: $name, IP: $ip, User: $user, Port: $port"
        return 0
    else
        error "Falha ao copiar chave SSH"
        audit_log "SSH_KEY_COPY_FAILED" "ERROR" "Worker: $name, IP: $ip, User: $user, Port: $port"
        return 1
    fi
}

# Salvar chave SSH autorizada
save_authorized_key() {
    local name="$1"
    local key_content="$2"

    local key_file="${AUTHORIZED_KEYS_DIR}/${name}.pub"

    echo "$key_content" > "$key_file"
    chmod 600 "$key_file"

    success "Chave SSH salva: $key_file"
    audit_log "SSH_KEY_SAVED" "SUCCESS" "Worker: $name"
}

# Carregar chave SSH autorizada
load_authorized_key() {
    local name="$1"

    local key_file="${AUTHORIZED_KEYS_DIR}/${name}.pub"

    if file_exists "$key_file"; then
        cat "$key_file"
        return 0
    else
        return 1
    fi
}

# =============================================================================
# DESCOBERTA DE WORKERS
# =============================================================================

# Descobrir workers na rede local
discover_network_workers() {
    local subnet="${1:-192.168.1.0/24}"
    local ports=("22" "8022")  # SSH padrão e Android

    section "Descobrindo Workers na Rede"

    info "Procurando workers na sub-rede: $subnet"
    info "Portas testadas: ${ports[*]}"

    if ! command_exists nmap; then
        warn "nmap não encontrado. Usando método alternativo..."
        discover_workers_fallback "$subnet" "${ports[@]}"
        return $?
    fi

    # Usar nmap para descoberta
    local discovered_hosts=()
    for port in "${ports[@]}"; do
        subsection "Procurando na porta $port..."

        # Executar nmap e capturar hosts com porta aberta
        local hosts
        mapfile -t hosts < <(nmap -p "$port" --open "$subnet" -oG - 2>/dev/null | \
                             grep "Ports:" | awk '{print $2}' | sort -u)

        for host in "${hosts[@]}"; do
            if [[ ! " ${discovered_hosts[*]} " =~ " $host " ]]; then
                discovered_hosts+=("$host:$port")
                info "Host descoberto: $host (porta $port)"
            fi
        done
    done

    # Testar hosts descobertos
    if (( ${#discovered_hosts[@]} > 0 )); then
        subsection "Testando Hosts Descobertos"
        for host_port in "${discovered_hosts[@]}"; do
            local host="${host_port%:*}"
            local port="${host_port#*:}"

            info "Testando $host:$port..."
            if test_network_connectivity "$host" "$port"; then
                # Tentar identificar o tipo de worker
                identify_worker_type "$host" "$port"
            fi
        done
    else
        warn "Nenhum host com portas SSH abertas encontrado"
    fi
}

# Método alternativo de descoberta (sem nmap)
discover_workers_fallback() {
    local subnet="$1"
    shift
    local ports=("$@")

    warn "Usando método de descoberta limitado (sem nmap)"

    # Extrair base da sub-rede
    local base_ip
    if [[ "$subnet" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\. ]]; then
        base_ip="${BASH_REMATCH[1]}"
    else
        error "Formato de sub-rede inválido: $subnet"
        return 1
    fi

    # Testar range limitado (último octeto 1-254)
    subsection "Testando range limitado (1-20)..."
    for i in {1..20}; do
        local test_ip="$base_ip.$i"

        for port in "${ports[@]}"; do
            if test_network_connectivity "$test_ip" "$port" >/dev/null 2>&1; then
                info "Host potencial encontrado: $test_ip:$port"
                identify_worker_type "$test_ip" "$port"
            fi
        done
    done
}

# Identificar tipo de worker
identify_worker_type() {
    local ip="$1"
    local port="$2"

    # Tentar conexão SSH para identificar
    local ssh_output
    ssh_output=$(ssh -o BatchMode=yes -o ConnectTimeout=5 \
                    -o StrictHostKeyChecking=no \
                    -p "$port" "root@$ip" "uname -a" 2>/dev/null || \
                ssh -o BatchMode=yes -o ConnectTimeout=5 \
                    -o StrictHostKeyChecking=no \
                    -p "$port" "u0_a249@$ip" "uname -a" 2>/dev/null || \
                echo "UNKNOWN")

    if [[ "$ssh_output" != "UNKNOWN" ]]; then
        if [[ "$ssh_output" =~ Android ]]; then
            info "✅ Worker Android identificado: $ip:$port"
            suggest_worker_config "android-worker-$ip" "$ip" "u0_a249" "$port" "Android"
        elif [[ "$ssh_output" =~ Linux ]]; then
            info "✅ Worker Linux identificado: $ip:$port"
            suggest_worker_config "linux-worker-$ip" "$ip" "user" "$port" "Linux"
        else
            info "✅ Worker identificado: $ip:$port"
            suggest_worker_config "worker-$ip" "$ip" "user" "$port" "Unknown"
        fi
    fi
}

# Sugerir configuração de worker
suggest_worker_config() {
    local name="$1"
    local ip="$2"
    local user="$3"
    local port="$4"
    local type="$5"

    echo
    info "Sugestão de configuração para worker $type:"
    echo "  Nome: $name"
    echo "  IP: $ip"
    echo "  Usuário: $user"
    echo "  Porta: $port"
    echo

    if confirm_operation "Adicionar este worker à configuração?"; then
        add_manual_worker "$name" "${name//-/_}" "$ip" "$user" "$port"
    fi
}

# =============================================================================
# SINCRONIZAÇÃO DE WORKERS
# =============================================================================

# Sincronizar configuração de workers
sync_workers_config() {
    section "Sincronização de Workers"

    # Sincronizar com cluster.conf se existir
    local cluster_conf="${PROJECT_ROOT}/cluster.conf"
    if file_exists "$cluster_conf"; then
        info "Sincronizando com cluster.conf..."

        # Mesclar workers manuais
        while IFS= read -r line; do
            if [[ $line =~ ^# ]] || [[ -z "$line" ]]; then
                continue
            fi

            local name ip user port status
            read -r name ip user port status <<< "$line"

            if ! grep -q "^$name " "$NODES_LIST_FILE"; then
                echo "$name ${name//-/_} $ip $user $port $status" >> "$NODES_LIST_FILE"
                info "Worker sincronizado: $name"
            fi
        done < "$NODES_LIST_FILE"

        success "Configuração sincronizada"
        audit_log "WORKERS_CONFIG_SYNCED" "SUCCESS"
    else
        info "Arquivo cluster.conf não encontrado, pulando sincronização"
    fi
}

# Verificar status de todos os workers
check_all_workers_status() {
    section "Verificando Status de Todos os Workers"

    local total_workers=0
    local online_workers=0

    # Verificar workers manuais
    if file_exists "$NODES_LIST_FILE" && grep -vE '^\s*#|^\s*$' "$NODES_LIST_FILE" | grep -q .; then
        subsection "Workers Manuais"

        while IFS= read -r line; do
            if [[ $line =~ ^# ]] || [[ -z "$line" ]]; then
                continue
            fi

            local name alias ip user port status
            read -r name alias ip user port status <<< "$line"

            ((total_workers++))
            echo -n -e "  -> Testando ${YELLOW}$name${NC} ($user@$ip:$port)... "

            if test_ssh_connection "$ip" "$user" "$port" >/dev/null 2>&1; then
                echo -e "${GREEN}ONLINE${NC}"
                ((online_workers++))
                update_worker_status "$NODES_LIST_FILE" "$name $ip $user $port" "active"
            else
                echo -e "${RED}OFFLINE${NC}"
                update_worker_status "$NODES_LIST_FILE" "$name $ip $user $port" "inactive"
            fi
        done < <(grep -vE '^\s*#|^\s*$' "$NODES_LIST_FILE")
    fi

    # Verificar workers automáticos
    if file_exists "$WORKERS_AUTO_FILE" && grep -vE '^\s*#|^\s*$' "$WORKERS_AUTO_FILE" | grep -q .; then
        subsection "Workers Automáticos"

        while IFS= read -r line; do
            if [[ $line =~ ^# ]] || [[ -z "$line" ]]; then
                continue
            fi

            local name ip user port status timestamp
            read -r name ip user port status timestamp <<< "$line"

            ((total_workers++))
            echo -n -e "  -> Testando ${YELLOW}$name${NC} ($user@$ip:$port)... "

            if test_ssh_connection "$ip" "$user" "$port" >/dev/null 2>&1; then
                echo -e "${GREEN}ONLINE${NC}"
                ((online_workers++))
                sed -i "s/^$name $ip $user $port .*/$name $ip $user $port active $(date +%s)/" "$WORKERS_AUTO_FILE"
            else
                echo -e "${RED}OFFLINE${NC}"
                sed -i "s/^$name $ip $user $port .*/$name $ip $user $port inactive $(date +%s)/" "$WORKERS_AUTO_FILE"
            fi
        done < <(grep -vE '^\s*#|^\s*$' "$WORKERS_AUTO_FILE")
    fi

    subsection "Resumo da Verificação"
    if (( total_workers > 0 )); then
        success "Verificação concluída: ${GREEN}$online_workers de $total_workers${NC} workers estão online"
    else
        warn "Nenhum worker configurado para verificação"
        info "Use a opção de gerenciamento de workers para adicionar workers"
    fi

    audit_log "WORKERS_STATUS_CHECKED" "SUCCESS" "Total: $total_workers, Online: $online_workers"
}

# =============================================================================
# LISTAGEM E RELATÓRIOS
# =============================================================================

# Listar todos os workers
list_workers() {
    local detailed="${1:-false}"

    section "Workers Configurados"

    # Workers manuais
    if file_exists "$NODES_LIST_FILE" && grep -vE '^\s*#|^\s*$' "$NODES_LIST_FILE" | grep -q .; then
        subsection "Workers Manuais"
        echo "Nome                Alias               IP              Usuário      Porta   Status"
        echo "------------------- ------------------- --------------- ------------ ------- --------"

        while IFS= read -r line; do
            if [[ $line =~ ^# ]] || [[ -z "$line" ]]; then
                continue
            fi

            local name alias ip user port status
            read -r name alias ip user port status <<< "$line"

            printf "%-19s %-19s %-15s %-12s %-7s %s\n" \
                   "$name" "$alias" "$ip" "$user" "$port" "$status"
        done < <(grep -vE '^\s*#|^\s*$' "$NODES_LIST_FILE")
        echo
    fi

    # Workers automáticos
    if file_exists "$WORKERS_AUTO_FILE" && grep -vE '^\s*#|^\s*$' "$WORKERS_AUTO_FILE" | grep -q .; then
        subsection "Workers Registrados Automaticamente"
        echo "Nome                IP              Usuário      Porta   Status      Registrado"
        echo "------------------- --------------- ------------ ------- ----------- --------------"

        while IFS= read -r line; do
            if [[ $line =~ ^# ]] || [[ -z "$line" ]]; then
                continue
            fi

            local name ip user port status timestamp
            read -r name ip user port status timestamp <<< "$line"

            local date_str="N/A"
            if [[ -n "$timestamp" ]] && (( timestamp > 0 )); then
                date_str=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M' 2>/dev/null || echo "$timestamp")
            fi

            printf "%-19s %-15s %-12s %-7s %-11s %s\n" \
                   "$name" "$ip" "$user" "$port" "$status" "$date_str"
        done < <(grep -vE '^\s*#|^\s*$' "$WORKERS_AUTO_FILE")
        echo
    fi

    if [[ "$detailed" == "true" ]]; then
        subsection "Estatísticas"
        local manual_count=$(grep -vE '^\s*#|^\s*$' "$NODES_LIST_FILE" 2>/dev/null | wc -l)
        local auto_count=$(grep -vE '^\s*#|^\s*$' "$WORKERS_AUTO_FILE" 2>/dev/null | wc -l)
        local total=$((manual_count + auto_count))

        echo "Workers manuais: $manual_count"
        echo "Workers automáticos: $auto_count"
        echo "Total: $total"
    fi
}

# =============================================================================
# INICIALIZAÇÃO DO MÓDULO
# =============================================================================

# Inicializar módulo de workers
init_workers_module() {
    init_workers_config

    # Verificar se SSH está disponível
    if command_exists ssh; then
        info "SSH detectado - funcionalidades de workers remotas disponíveis"
    else
        warn "SSH não encontrado - funcionalidades de workers remotas limitadas"
    fi

    audit_log "WORKERS_MODULE_INITIALIZED" "SUCCESS" "Workers module loaded"
}

# Verificar se módulo foi carregado corretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_environment
    init_security_module
    init_workers_module
    info "Módulo workers.sh carregado com sucesso"
fi
