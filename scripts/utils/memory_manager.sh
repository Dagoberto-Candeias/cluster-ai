#!/bin/bash
# Sistema de Gerenciamento de Memória Auxiliar Auto-Expansível - Versão Segura
# Utiliza SSD como memória virtual para evitar falta de memória

# Adicionar /usr/sbin ao PATH para garantir que swapon seja encontrado
export PATH=$PATH:/usr/sbin

# Carregar funções comuns com segurança
COMMON_SCRIPT_PATH="$(dirname "${BASH_SOURCE[0]}")/common.sh"
if [ -f "$COMMON_SCRIPT_PATH" ]; then
    source "$COMMON_SCRIPT_PATH"
else
    echo "ERRO CRÍTICO: Script de funções comuns 'common.sh' não encontrado: $COMMON_SCRIPT_PATH" >&2
    exit 1
fi

# Configurações
SWAP_DIR="$HOME/cluster_swap"
SWAP_FILE="$SWAP_DIR/swapfile"
MIN_SWAP_SIZE="2G"      # Tamanho mínimo do swap
MAX_SWAP_SIZE="16G"     # Tamanho máximo do swap
SWAP_INCREMENT="1G"     # Incremento para expansão
MEMORY_THRESHOLD=80     # Percentual de uso de memória para ativar expansão
CHECK_INTERVAL=30       # Intervalo de verificação em segundos

# Função para verificar uso de memória
check_memory_usage() {
    # Usar LC_ALL=C para garantir saída em inglês
    local total_mem=$(LC_ALL=C free -m | awk '/^Mem:/{print $2}')
    local used_mem=$(LC_ALL=C free -m | awk '/^Mem:/{print $3}')
    
    # Garantir que não haja divisão por zero
    total_mem=${total_mem:-1}  # Evitar divisão por zero
    used_mem=${used_mem:-0}    # Garantir valor padrão
    
    # Verificar se os valores são numéricos
    if ! [[ "$total_mem" =~ ^[0-9]+$ ]] || ! [[ "$used_mem" =~ ^[0-9]+$ ]]; then
        echo "0"
        return
    fi
    
    # Calcular porcentagem de uso
    local usage_percent=$((used_mem * 100 / total_mem))
    echo $usage_percent
}

# Função para verificar uso de swap
check_swap_usage() {
    local swap_usage=$(free -m | awk '/^Swap:/{print $3}')
    echo $swap_usage
}

# Função para criar arquivo de swap
create_swap_file() {
    local size="$1"
    
    # Criar diretório se não existir
    if ! safe_path_check "$SWAP_DIR" "criação de diretório de swap"; then return 1; fi
    mkdir -p "$SWAP_DIR"
    
    # Verificar se arquivo de swap já existe
    if [ -f "$SWAP_FILE" ]; then
        warn "Arquivo de swap '$SWAP_FILE' já existe."
        if confirm_operation "Deseja remover o swap existente e criar um novo?"; then
            cleanup_swap
        else
            warn "Operação cancelada. Usando o arquivo de swap existente."
            return 0
        fi
    fi
    
    if ! safe_path_check "$SWAP_FILE" "criação de arquivo de swap"; then return 1; fi

    log "Criando arquivo de swap de $size..."
    
    # Converter tamanho para megabytes
    local size_mb
    size_mb=$(echo "$size" | sed 's/G/*1024/;s/M//' | bc)
    
    # Validar tamanho
    if [ -z "$size_mb" ] || [ "$size_mb" -le 0 ]; then
        error "Tamanho de swap inválido: $size"
        return 1
    fi
    
    # Criar arquivo com validação
    sudo dd if=/dev/zero of="$SWAP_FILE" bs=1M count="$size_mb" status=progress
    if [ $? -ne 0 ]; then
        error "Falha ao criar arquivo de swap"
        return 1
    fi
    
    # Configurar permissões
    chmod 600 "$SWAP_FILE"
    
    # Formatar como swap
    sudo mkswap "$SWAP_FILE"
    
    # Ativar swap
    sudo swapon "$SWAP_FILE"
    
    # Adicionar ao fstab para persistência
    if ! grep -q "$SWAP_FILE" /etc/fstab; then
        echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab
    fi
    
    log "Arquivo de swap criado e ativado com sucesso: $size"
}

# Função para expandir swap
expand_swap() {
    if ! safe_path_check "$SWAP_FILE" "expansão de swap"; then return 1; fi
    local current_size=$(du -h "$SWAP_FILE" 2>/dev/null | cut -f1)
    local new_size=""
    
    if [ -z "$current_size" ]; then
        # Swap não existe, criar tamanho mínimo
        create_swap_file "$MIN_SWAP_SIZE"
        return
    fi
    
    # Converter tamanho atual para megabytes
    local current_mb
    current_mb=$(echo "$current_size" | sed 's/G/*1024/;s/M//' | bc)
    local increment_mb
    increment_mb=$(echo "$SWAP_INCREMENT" | sed 's/G/*1024/;s/M//' | bc)
    local max_mb
    max_mb=$(echo "$MAX_SWAP_SIZE" | sed 's/G/*1024/;s/M//' | bc)

    # Validar valores numéricos
    if ! [[ "$current_mb" =~ ^[0-9]+$ ]] || ! [[ "$increment_mb" =~ ^[0-9]+$ ]] || ! [[ "$max_mb" =~ ^[0-9]+$ ]]; then error "Cálculo de tamanho de swap inválido."; return 1; fi
    
    local new_mb=$((current_mb + increment_mb))
    
    if [ "$new_mb" -gt "$max_mb" ]; then
        warn "Tamanho máximo de swap ($MAX_SWAP_SIZE) atingido."
        return
    fi
    
    # Converter de volta para formato legível
    if [ "$new_mb" -ge 1024 ]; then
        new_size="$((new_mb / 1024))G"
    else
        new_size="${new_mb}M"
    fi
    
    # Desativar swap atual
    sudo swapoff "$SWAP_FILE"
    
    # Expandir arquivo
    log "Expandindo swap de $current_size para $new_size..."
    sudo dd if=/dev/zero of="$SWAP_FILE" bs=1M count=$((new_mb)) oflag=append conv=notrunc status=progress
    
    # Reformatar e reativar
    sudo mkswap "$SWAP_FILE"
    sudo swapon "$SWAP_FILE"
    
    log "Swap expandido para $new_size"
}

# Função para reduzir swap (se necessário)
reduce_swap() {
    if ! safe_path_check "$SWAP_FILE" "redução de swap"; then return 1; fi
    # Verificar se o arquivo de swap existe
    if [ ! -f "$SWAP_FILE" ]; then
        warn "Arquivo de swap não encontrado: $SWAP_FILE"
        return
    fi
    
    # Obter tamanho atual em megabytes (mais confiável que bytes)
    local current_size_mb
    current_size_mb=$(du --block-size=1M "$SWAP_FILE" 2>/dev/null | cut -f1)
    local min_size_mb=2048  # 2GB em MB
    
    # Garantir valores numéricos
    current_size_mb=${current_size_mb:-0}
    
    if [ "$current_size_mb" -le "$min_size_mb" ] 2>/dev/null; then
        log "Swap já está no tamanho mínimo (2GB)"
        return  # Já está no tamanho mínimo
    fi
    
    # Calcular novo tamanho (reduzir pela metade, mas não abaixo do mínimo)
    local new_size_mb
    new_size_mb=$((current_size_mb / 2))
    if [ "$new_size_mb" -lt "$min_size_mb" ] 2>/dev/null; then
        new_size_mb=$min_size_mb
    fi
    
    # Converter para formato legível
    local new_size
    if [ "$new_size_mb" -ge 1024 ]; then
        new_size="$((new_size_mb / 1024))G"
    else
        new_size="${new_size_mb}M"
    fi
    
    # Desativar swap
    sudo swapoff "$SWAP_FILE"
    
    # Reduzir arquivo
    log "Reduzindo swap de $(du -h "$SWAP_FILE" | cut -f1) para $new_size..."
    sudo truncate -s "${new_size_mb}M" "$SWAP_FILE"
    
    # Reformatar e reativar
    sudo mkswap "$SWAP_FILE"
    sudo swapon "$SWAP_FILE"
    
    log "Swap reduzido para $new_size"
}

# Função para otimizar configurações de memória
optimize_memory_settings() {
    log "Otimizando configurações de memória do sistema..."
    
    # Ajustar swappiness (quanto o sistema usa swap)
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
    
    # Ajustar cache pressure
    echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
    
    # Aplicar configurações
    sudo sysctl -p
    
    log "Configurações de memória otimizadas"
}

# Função para configurar limites de memória para processos
setup_process_limits() {
    local process_name="$1"
    local memory_limit="$2"
    
    # Configurar cgroups para limitar memória de processos específicos
    if command_exists systemd-run; then
        # Exemplo: limitar processo Ollama para 4GB
        # systemd-run --scope -p MemoryMax=4G ollama serve
        log "Configurando limite de $memory_limit para $process_name"
    fi
}

# Função para monitorar e gerenciar memória automaticamente
monitor_memory() {
    log "Iniciando monitoramento automático de memória..."
    log "Swap directory: $SWAP_DIR"
    log "Check interval: ${CHECK_INTERVAL}s"
    log "Memory threshold: ${MEMORY_THRESHOLD}%"
    
    while true; do
        local mem_usage=$(check_memory_usage)
        local swap_usage=$(check_swap_usage)
        
        # Log do estado atual
        echo "[$(date)] Memória: ${mem_usage}% usado | Swap: ${swap_usage}MB usado"
        
        # Garantir que mem_usage e swap_usage não sejam vazios
        mem_usage=${mem_usage:-0}  # Evitar divisão por zero
        swap_usage=${swap_usage:-0}  # Garantir valor padrão
        
        # Usar comparações numéricas seguras
        if [ "$mem_usage" -ge "$MEMORY_THRESHOLD" ] 2>/dev/null; then
            warn "Uso de memória alto (${mem_usage}%). Verificando necessidade de expansão..."
            
            # Se swap está sendo pouco usado, expandir
            if [ "$swap_usage" -lt 100 ] 2>/dev/null; then  # Menos de 100MB usado
                expand_swap
            else
                warn "Swap já está sendo utilizado (${swap_usage}MB). Considerando otimizações adicionais..."
                
                # Tentar liberar cache se memória ainda estiver alta
                if [ "$mem_usage" -ge 90 ] 2>/dev/null; then
                    warn "Memória crítica (${mem_usage}%). Liberando cache..."
                    sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
                fi
            fi
        elif [ "$mem_usage" -lt 50 ] 2>/dev/null && [ "$swap_usage" -gt 0 ] 2>/dev/null; then
            # Memória baixa e swap sendo usado, reduzir swap
            log "Memória livre disponível. Reduzindo swap se seguro..."
            reduce_swap
        fi
        
        sleep $CHECK_INTERVAL
    done
}

# Função para mostrar status da memória
show_memory_status() {
    echo -e "${BLUE}=== STATUS DA MEMÓRIA ===${NC}"
    echo -e "Memória RAM:"
    free -h | awk '/^Mem:/ {print "  Total: " $2 ", Usado: " $3 ", Livre: " $4 ", Cache: " $6}'
    
    echo -e "\nSwap:"
    free -h | awk '/^Swap:/ {print "  Total: " $2 ", Usado: " $3 ", Livre: " $4}'
    
    if [ -f "$SWAP_FILE" ]; then
        echo -e "\nArquivo de Swap:"
        echo "  Local: $SWAP_FILE"
        echo "  Tamanho: $(du -h "$SWAP_FILE" | cut -f1)"
        echo "  Ativo: $(swapon --show | grep -q "$SWAP_FILE" && echo "Sim" || echo "Não")"
    else
        echo -e "\nArquivo de Swap: Não configurado"
    fi
    
    echo -e "\nUso atual: $(check_memory_usage)% da memória"
}

# Função para limpar e remover swap
cleanup_swap() {
    log "Limpando configuração de swap..."
    
    if ! safe_path_check "$SWAP_FILE" "limpeza de swap"; then return 1; fi

    if swapon --show | grep -q "$SWAP_FILE"; then
        log "Desativando swap: $SWAP_FILE"
        sudo swapoff "$SWAP_FILE"
    fi

    if [ -f "$SWAP_FILE" ] && confirm_operation "Remover o arquivo de swap '$SWAP_FILE'?"; then
        sudo rm -f "$SWAP_FILE"
        log "Arquivo de swap removido."
        sudo sed -i.bak "\|$SWAP_FILE|d" /etc/fstab
        log "Entrada removida do /etc/fstab (backup criado em /etc/fstab.bak)."
    fi
    
    # Remover diretório se vazio
    if [ -d "$SWAP_DIR" ] && [ -z "$(ls -A "$SWAP_DIR")" ]; then
        rmdir "$SWAP_DIR"
    fi
    
    log "Limpeza concluída"
}

# Menu principal
main() {
    # Verificar privilégios de sudo no início, pois quase todas as operações exigem
    if [[ $EUID -ne 0 ]] && [[ "$1" != "status" ]]; then
        error "Este comando precisa ser executado com privilégios de sudo (ex: sudo $0 $1)"
        exit 1
    fi

    case "$1" in
        "start")
            create_swap_file "$MIN_SWAP_SIZE"
            optimize_memory_settings
            monitor_memory &
            ;;
        "stop")
            pkill -f "$(basename "$0")"
            cleanup_swap
            ;;
        "status")
            show_memory_status
            ;;
        "expand")
            expand_swap
            ;;
        "reduce")
            reduce_swap
            ;;
        "optimize")
            optimize_memory_settings
            ;;
        "clean")
            cleanup_swap
            ;;
        *)
            echo -e "${BLUE}Uso: $0 [comando]${NC}"
            echo "Comandos:"
            echo "  start     - Iniciar gerenciamento automático"
            echo "  stop      - Parar gerenciamento e limpar"
            echo "  status    - Mostrar status da memória"
            echo "  expand    - Expandir manualmente o swap"
            echo "  reduce    - Reduzir manualmente o swap"
            echo "  optimize  - Apenas otimizar configurações"
            echo "  clean     - Limpar configuração de swap"
            ;;
    esac
}

# Executar comando solicitado
main "$@"
