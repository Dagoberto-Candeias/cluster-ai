#!/bin/bash
# Otimizador de Recursos para Cluster AI
# Evita sobrecarga e falta de memória através de ajustes automáticos

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configurações
CONFIG_DIR="$HOME/.cluster_optimization"
LOG_FILE="$CONFIG_DIR/optimization.log"
CHECK_INTERVAL=60  # Verificação a cada 60 segundos

log() {
    echo -e "${GREEN}[RESOURCE OPTIMIZER]${NC} $1"
    echo "[$(date)] $1" >> "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[RESOURCE OPTIMIZER]${NC} $1"
    echo "[$(date)] WARN: $1" >> "$LOG_FILE"
}

error() {
    echo -e "${RED}[RESOURCE OPTIMIZER]${NC} $1"
    echo "[$(date)] ERROR: $1" >> "$LOG_FILE"
}

# Função para detectar recursos do sistema
detect_system_resources() {
    local cpu_cores=$(nproc)
    # Usar LC_ALL=C para garantir saída em inglês (igual ao resource_checker.sh)
    local total_memory=$(LC_ALL=C free -m | awk '/^Mem:/{print $2}')
    local total_disk=$(df -h / | awk 'NR==2{print $2}')
    local disk_type=$(lsblk -d -o rota | awk 'NR==2{print $1}')
    
    # Garantir que as variáveis tenham valores numéricos
    cpu_cores=${cpu_cores:-0}
    total_memory=${total_memory:-0}
    
    echo "CPU_CORES=$cpu_cores"
    echo "TOTAL_MEMORY=$total_memory"
    echo "TOTAL_DISK=$total_disk"
    echo "DISK_TYPE=$disk_type"  # 0=SSD, 1=HDD
}

# Função para calcular configurações otimizadas
calculate_optimized_settings() {
    local cpu_cores=$1
    local total_memory=$2
    local disk_type=$3
    
    # Configurações baseadas nos recursos
    local dask_workers=$((cpu_cores > 4 ? cpu_cores - 2 : 2))
    local dask_threads=$((cpu_cores > 8 ? 2 : 1))
    local memory_limit=""
    
    # Calcular limite de memória por worker (80% da memória total dividido pelos workers)
    local memory_per_worker=$((total_memory * 80 / 100 / dask_workers))
    if [ "$memory_per_worker" -ge 1024 ]; then
        memory_limit="$((memory_per_worker / 1024))GB"
    else
        memory_limit="${memory_per_worker}MB"
    fi
    
    # Configurações Ollama baseadas em memória
    local ollama_layers=""
    local ollama_models=""
    
    if [ "$total_memory" -ge 32000 ]; then  # 32GB+
        ollama_layers="35"
        ollama_models="3"
    elif [ "$total_memory" -ge 16000 ]; then  # 16GB+
        ollama_layers="20"
        ollama_models="2"
    else  # Menos de 16GB
        ollama_layers="10"
        ollama_models="1"
    fi
    
    # Ajustes para tipo de disco
    local swap_size=""
    if [ "$disk_type" = "0" ]; then  # SSD
        swap_size="16G"
    else  # HDD
        swap_size="8G"
    fi
    
    echo "DASK_WORKERS=$dask_workers"
    echo "DASK_THREADS=$dask_threads"
    echo "MEMORY_LIMIT=$memory_limit"
    echo "OLLAMA_LAYERS=$ollama_layers"
    echo "OLLAMA_MODELS=$ollama_models"
    echo "SWAP_SIZE=$swap_size"
}

# Função para aplicar configurações otimizadas
apply_optimized_settings() {
    local settings="$1"
    
    # Extrair configurações
    local dask_workers=$(echo "$settings" | grep "DASK_WORKERS=" | cut -d= -f2)
    local dask_threads=$(echo "$settings" | grep "DASK_THREADS=" | cut -d= -f2)
    local memory_limit=$(echo "$settings" | grep "MEMORY_LIMIT=" | cut -d= -f2)
    local ollama_layers=$(echo "$settings" | grep "OLLAMA_LAYERS=" | cut -d= -f2)
    local ollama_models=$(echo "$settings" | grep "OLLAMA_MODELS=" | cut -d= -f2)
    local swap_size=$(echo "$settings" | grep "SWAP_SIZE=" | cut -d= -f2)
    
    log "Aplicando configurações otimizadas:"
    log "  Dask Workers: $dask_workers"
    log "  Dask Threads: $dask_threads"
    log "  Memory Limit: $memory_limit"
    log "  Ollama Layers: $ollama_layers"
    log "  Ollama Models: $ollama_models"
    log "  Swap Size: $swap_size"
    
    # Atualizar script do worker
    update_worker_script "$dask_workers" "$dask_threads" "$memory_limit"
    
    # Atualizar configuração Ollama
    update_ollama_config "$ollama_layers" "$ollama_models"
    
    # Configurar swap
    configure_swap "$swap_size"
}

# Função para atualizar script do worker
update_worker_script() {
    local workers=$1
    local threads=$2
    local memory_limit=$3
    
    if [ -f "$HOME/cluster_scripts/start_worker.sh" ]; then
        # Backup do script original
        cp "$HOME/cluster_scripts/start_worker.sh" "$HOME/cluster_scripts/start_worker.sh.backup"
        
        # Atualizar com novas configurações
        sed -i "s/--nworkers auto/--nworkers $workers/" "$HOME/cluster_scripts/start_worker.sh"
        sed -i "s/--nthreads [0-9]\+/--nthreads $threads/" "$HOME/cluster_scripts/start_worker.sh"
        
        # Adicionar limite de memória se não existir
        if ! grep -q "--memory-limit" "$HOME/cluster_scripts/start_worker.sh"; then
            sed -i "s/dask-worker.*\$/dask-worker \$SERVER_IP:8786 --nworkers $workers --nthreads $threads --memory-limit \"$memory_limit\" --name \$MACHINE_NAME/" "$HOME/cluster_scripts/start_worker.sh"
        else
            sed -i "s/--memory-limit \"[^\"]*\"/--memory-limit \"$memory_limit\"/" "$HOME/cluster_scripts/start_worker.sh"
        fi
        
        log "Script do worker atualizado com configurações otimizadas"
    fi
}

# Função para atualizar configuração Ollama
update_ollama_config() {
    local layers=$1
    local max_models=$2
    
    mkdir -p ~/.ollama
    
    # Criar ou atualizar configuração
    cat > ~/.ollama/config.json << EOL
{
    "environment": {
        "OLLAMA_NUM_GPU_LAYERS": "$layers",
        "OLLAMA_MAX_LOADED_MODELS": "$max_models",
        "OLLAMA_KEEP_ALIVE": "6h"
    }
}
EOL
    
    # Reiniciar Ollama se estiver rodando
    if systemctl is-active --quiet ollama; then
        sudo systemctl restart ollama
        log "Configuração do Ollama atualizada e serviço reiniciado"
    else
        log "Configuração do Ollama atualizada"
    fi
}

# Função para configurar swap
configure_swap() {
    local size=$1
    
    # Usar o memory manager para configurar swap
    local memory_manager_path="scripts/utils/memory_manager.sh"
    
    if [ -f "$memory_manager_path" ]; then
        bash "$memory_manager_path" clean
        bash "$memory_manager_path" start
        log "Swap configurado usando memory manager"
    else
        warn "Memory manager não encontrado. Configuração de swap manual necessária."
    fi
}

# Função para monitorar uso de recursos
monitor_resource_usage() {
    log "Iniciando monitoramento de recursos..."
    
    while true; do
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        local mem_usage=$(free | awk '/Mem:/{printf("%.0f"), $3/$2 * 100}')
        local disk_usage=$(df -h / | awk 'NR==2{print $5}' | cut -d'%' -f1)
        
        # Log do estado atual
        echo "[$(date)] CPU: ${cpu_usage}% | Memória: ${mem_usage}% | Disco: ${disk_usage}%"
        
        # Verificar condições críticas
    if [ "$cpu_usage" -gt 90 ]; then
        warn "Uso de CPU crítico (${cpu_usage}%). Considerando redução de carga..."
            reduce_workload
        fi
        
        if [ $mem_usage -gt 85 ]; then
            warn "Uso de memória crítico (${mem_usage}%). Ativando medidas emergenciais..."
            free_memory
        fi
        
        if [ $disk_usage -gt 90 ]; then
            warn "Uso de disco crítico (${disk_usage}%). Limpando espaço..."
            cleanup_disk
        fi
        
        sleep $CHECK_INTERVAL
    done
}

# Função para reduzir carga de trabalho
reduce_workload() {
    # Reduzir número de workers temporariamente
    if [ -f "$HOME/cluster_scripts/start_worker.sh" ]; then
        local current_workers=$(grep -oP '--nworkers \K[0-9]+' "$HOME/cluster_scripts/start_worker.sh")
        if [ -n "$current_workers" ] && [ $current_workers -gt 1 ]; then
            local new_workers=$((current_workers / 2))
            sed -i "s/--nworkers $current_workers/--nworkers $new_workers/" "$HOME/cluster_scripts/start_worker.sh"
            warn "Workers reduzidos de $current_workers para $new_workers devido a alta carga de CPU"
            
            # Reiniciar workers
            pkill -f "dask-worker"
            sleep 2
            nohup bash "$HOME/cluster_scripts/start_worker.sh" > /dev/null 2>&1 &
        fi
    fi
}

# Função para liberar memória
free_memory() {
    # Verificar se temos privilégios sudo antes de executar comandos destrutivos
    if ! sudo -n true 2>/dev/null; then
        warn "Privilégios sudo necessários para liberar memória. Execute com sudo."
        return 1
    fi
    
    # Liberar cache de memória com validação
    warn "Liberando cache de memória do sistema..."
    sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    
    # Limpar cache do Ollama se estiver usando muita memória
    if command_exists ollama; then
        warn "Limpando cache do Ollama..."
        ollama ps | grep -v "NAME" | awk '{print $1}' | xargs -I {} ollama rm {} 2>/dev/null
    fi
    
    warn "Memória liberada através de limpeza de cache"
}

# Função para limpar espaço em disco
cleanup_disk() {
    # Solicitar confirmação do usuário para operações destrutivas
    if ! confirm_operation "Esta operação irá limpar logs antigos e caches. Deseja continuar?"; then
        warn "Limpeza de disco cancelada pelo usuário"
        return 1
    fi
    
    warn "Iniciando limpeza segura de disco..."
    
    # Limpar logs antigos com validação de caminhos
    local log_dirs=("/var/log" "$HOME")
    for log_dir in "${log_dirs[@]}"; do
        if safe_path_check "$log_dir" "limpeza de logs"; then
            warn "Limpando logs em: $log_dir"
            find "$log_dir" -name "*.log" -type f -mtime +7 -delete 2>/dev/null
        fi
    done
    
    # Limpar cache do pip
    warn "Limpando cache do pip..."
    pip cache purge 2>/dev/null
    
    # Limpar cache do Docker com validação
    if command_exists docker; then
        warn "Limpando cache do Docker..."
        docker system prune -af 2>/dev/null
    fi
    
    warn "Espaço em disco liberado através de limpeza segura de arquivos temporários"
}

# Função para mostrar status
show_status() {
    echo -e "${BLUE}=== STATUS DO OTIMIZADOR DE RECURSOS ===${NC}"
    
    # Informações do sistema
    local resources=$(detect_system_resources)
    echo -e "${CYAN}Recursos Detectados:${NC}"
    echo "$resources" | sed 's/^/  /'
    
    # Configurações atuais
    echo -e "\n${CYAN}Configurações Atuais:${NC}"
    if [ -f "$HOME/cluster_scripts/start_worker.sh" ]; then
        echo "  Dask Workers: $(grep -oP '--nworkers \K[0-9]+' "$HOME/cluster_scripts/start_worker.sh" || echo "auto")"
        echo "  Dask Threads: $(grep -oP '--nthreads \K[0-9]+' "$HOME/cluster_scripts/start_worker.sh" || echo "2")"
        echo "  Memory Limit: $(grep -oP '--memory-limit \"\K[^\"]+' "$HOME/cluster_scripts/start_worker.sh" || echo "Não configurado")"
    fi
    
    if [ -f ~/.ollama/config.json ]; then
        echo "  Ollama Layers: $(jq -r '.environment.OLLAMA_NUM_GPU_LAYERS' ~/.ollama/config.json 2>/dev/null || echo "Padrão")"
        echo "  Ollama Models: $(jq -r '.environment.OLLAMA_MAX_LOADED_MODELS' ~/.ollama/config.json 2>/dev/null || echo "Padrão")"
    fi
    
    # Uso atual - corrigido para garantir valores sempre exibidos
    echo -e "\n${CYAN}Uso Atual:${NC}"
    
    # CPU usage - usando método compatível com saída em português
    local cpu_line=$(top -bn1 | grep "%CPU(s)")
    local cpu_idle=$(echo "$cpu_line" | awk '{print $8}' | cut -d'.' -f1)
    local cpu_usage=$((100 - cpu_idle))
    cpu_usage=${cpu_usage:-0}
    echo "  CPU: ${cpu_usage}%"
    
    # Memory usage - usando LC_ALL=C para garantir saída em inglês
    local mem_info=$(LC_ALL=C free | grep "Mem:")
    local mem_total=$(echo "$mem_info" | awk '{print $2}')
    local mem_used=$(echo "$mem_info" | awk '{print $3}')
    
    # Garantir que os valores sejam numéricos
    mem_total=${mem_total:-1}
    mem_used=${mem_used:-0}
    
    # Calcular a porcentagem de memória usada
    local mem_percent=0
    if [ "$mem_total" -gt 0 ] 2>/dev/null && [ "$mem_used" -ge 0 ] 2>/dev/null; then
        mem_percent=$((mem_used * 100 / mem_total))
    fi
    echo "  Memória: ${mem_percent}%"
    
    # Disk usage
    echo "  Disco: $(df -h / | awk 'NR==2{print $5}' || echo "0%") usado"
}

# Menu principal
main() {
    # Criar diretório de configuração
    mkdir -p "$CONFIG_DIR"
    
    case "$1" in
        "optimize")
            log "Otimizando configurações baseadas nos recursos do sistema..."
            local resources=$(detect_system_resources)
            local cpu_cores=$(echo "$resources" | grep "CPU_CORES=" | cut -d= -f2)
            local total_memory=$(echo "$resources" | grep "TOTAL_MEMORY=" | cut -d= -f2 | sed 's/MB//')
            local disk_type=$(echo "$resources" | grep "DISK_TYPE=" | cut -d= -f2)
            
            local optimized_settings=$(calculate_optimized_settings "$cpu_cores" "$total_memory" "$disk_type")
            apply_optimized_settings "$optimized_settings"
            ;;
        "monitor")
            log "Iniciando monitoramento contínuo..."
            monitor_resource_usage
            ;;
        "status")
            show_status
            ;;
        "free-memory")
            free_memory
            ;;
        "clean-disk")
            cleanup_disk
            ;;
        *)
            echo -e "${BLUE}Uso: $0 [comando]${NC}"
            echo "Comandos:"
            echo "  optimize     - Otimizar configurações baseadas nos recursos"
            echo "  monitor      - Iniciar monitoramento contínuo"
            echo "  status       - Mostrar status atual"
            echo "  free-memory  - Liberar memória imediatamente"
            echo "  clean-disk   - Limpar espaço em disco"
            ;;
    esac
}

# Executar comando solicitado
main "$@"
