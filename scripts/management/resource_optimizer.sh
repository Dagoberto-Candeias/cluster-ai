#!/bin/bash
# =============================================================================
# Otimizador de Recursos para Cluster AI - Versão Segura
# =============================================================================
# Sistema inteligente de otimização automática de recursos que previne sobrecarga
# e falta de memória através de ajustes dinâmicos baseados no hardware detectado.
#
# Funcionalidades principais:
# - Detecção automática de recursos do sistema (CPU, RAM, GPU, Disco)
# - Cálculo inteligente de configurações otimizadas para Dask e Ollama
# - Suporte a perfis de otimização (default, android)
# - Monitoramento contínuo de recursos com alertas automáticos
# - Limpeza automática de memória e disco quando necessário
#
# Autor: Cluster AI Team
# Data: 2024-12-19
# Versão: 2.0.0
# Dependências: common.sh, nvidia-smi (opcional), docker (opcional)
# =============================================================================

# =============================================================================
# CONFIGURAÇÃO GLOBAL
# =============================================================================

# Carregar funções comuns com segurança
COMMON_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils" && pwd)/common.sh"
if [ -f "$COMMON_SCRIPT_PATH" ]; then
    source "$COMMON_SCRIPT_PATH"
else
    echo "ERRO CRÍTICO: Script de funções comuns 'common.sh' não encontrado: $COMMON_SCRIPT_PATH" >&2
    exit 1
fi

# Diretórios de configuração
CONFIG_DIR="$HOME/.cluster_optimization"
CLUSTER_CONFIG_DIR="$HOME/.cluster_config"
LOG_FILE="$CONFIG_DIR/optimization.log"

# Configurações do sistema
OPENWEBUI_CONTAINER_NAME="open-webui"
CHECK_INTERVAL=60  # Verificação a cada 60 segundos

# Exportar arquivo de log para uso global
export CLUSTER_AI_LOG_FILE="$LOG_FILE"

# =============================================================================
# FUNÇÕES PRINCIPAIS
# =============================================================================

# Função: detect_system_resources
# Descrição: Detecta automaticamente todos os recursos disponíveis no sistema
# Parâmetros:
#   Nenhum
# Retorno:
#   String formatada com informações dos recursos detectados
#   Formato: VARIAVEL=valor (uma por linha)
# Exemplo:
#   resources=$(detect_system_resources)
#   cpu_cores=$(echo "$resources" | grep "CPU_CORES" | cut -d= -f2)
detect_system_resources() {
    # Detecção de CPU
    local cpu_cores=$(nproc)

    # Detecção de memória RAM total em MB
    local total_memory_mb=$(LC_ALL=C free -m | awk '/^Mem:/{print $2}')

    # Detecção de espaço em disco total
    local total_disk=$(df -h / | awk 'NR==2{print $2}')

    # Detecção Multi-GPU usando NVIDIA SMI
    local gpu_count=0
    local total_gpu_vram_mb=0
    local primary_gpu_vram_mb=0

    if command_exists nvidia-smi; then
        # Contar GPUs disponíveis
        gpu_count=$(nvidia-smi --query-gpu=count --format=csv,noheader)

        # Calcular VRAM total de todas as GPUs
        total_gpu_vram_mb=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | awk '{s+=$1} END {print s}')

        # Obter VRAM da primeira GPU para cálculos de camadas do Ollama
        primary_gpu_vram_mb=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n 1)
    fi

    # Valores padrão para evitar erros
    cpu_cores=${cpu_cores:-0}
    total_memory_mb=${total_memory_mb:-0}

    # Retornar informações formatadas
    echo "CPU_CORES=$cpu_cores"
    echo "TOTAL_MEMORY_MB=$total_memory_mb"
    echo "TOTAL_DISK=$total_disk"
    echo "GPU_COUNT=${gpu_count:-0}"
    echo "TOTAL_GPU_VRAM_MB=${total_gpu_vram_mb:-0}"
    echo "PRIMARY_GPU_VRAM_MB=${primary_gpu_vram_mb:-0}"
}

# Função: calculate_optimized_settings
# Descrição: Calcula configurações otimizadas para Dask, Ollama e Docker baseadas
#           nos recursos detectados do sistema e no perfil de uso especificado
# Parâmetros:
#   $1 - Número de cores de CPU disponíveis
#   $2 - Memória RAM total em MB
#   $3 - Número de GPUs disponíveis
#   $4 - VRAM total de todas as GPUs em MB
#   $5 - VRAM da GPU primária em MB
#   $6 - Perfil de otimização (default, android)
# Retorno:
#   String formatada com configurações calculadas (uma por linha)
#   Formato: VARIAVEL=valor
# Exemplo:
#   settings=$(calculate_optimized_settings 8 16384 1 8192 8192 "default")
#   dask_workers=$(echo "$settings" | grep "DASK_WORKERS" | cut -d= -f2)
calculate_optimized_settings() {
    local cpu_cores=$1
    local total_memory_mb=$2
    local gpu_count=$3
    local total_gpu_vram_mb=$4
    local primary_gpu_vram_mb=$5
    local profile="${6:-default}"

    # =============================================================================
    # ALGORITMO DE CÁLCULO DE CONFIGURAÇÕES OTIMIZADAS
    #
    # Este algoritmo considera:
    # 1. Recursos disponíveis (CPU, RAM, GPU)
    # 2. Perfil de uso (default vs android)
    # 3. Reserva de recursos para SO e aplicações críticas
    # 4. Balanceamento entre performance e estabilidade
    # =============================================================================

    # --- Configurações Dinâmicas Iniciais ---
    local dask_workers=0
    local dask_threads=0
    local memory_limit="1GB"
    local dask_worker_class="dask.distributed.Nanny" # Worker padrão (CPU)
    local ollama_num_gpu_layers=0
    local ollama_max_loaded_models=1
    local reserved_mem_for_os=2048 # Reservar 2GB para o SO

    # Limites para o container Docker (OpenWebUI)
    local docker_openwebui_cpus="1.0"
    local docker_openwebui_memory="1g"

    # =============================================================================
    # PERFIL DE OTIMIZAÇÃO: ANDROID (Recursos Limitados)
    #
    # Estratégia: Conservadora e adaptativa baseada no hardware
    # Objetivos:
    # - Evitar superaquecimento em dispositivos móveis
    # - Reservar memória suficiente para SO Android e UI
    # - Manter estabilidade em hardwares limitados
    # =============================================================================
    if [ "$profile" == "android" ]; then
        log "Perfil de otimização: Android-Dynamic"

        # Reserva adaptativa de memória para SO Android
        # Baseado em: https://developer.android.com/topic/performance/memory
        local reserved_mem_for_android_os=3072 # 3GB base para SO + UI
        if [ "$total_memory_mb" -gt 8000 ]; then
            reserved_mem_for_android_os=4096 # 4GB para dispositivos high-end
        fi

        local available_mem_for_dask=$((total_memory_mb - reserved_mem_for_android_os))

        # Cálculo conservador de workers Dask
        # Metade dos cores para evitar thermal throttling
        dask_workers=$((cpu_cores / 2))
        [ "$dask_workers" -lt 1 ] && dask_workers=1
        [ "$dask_workers" -gt 4 ] && dask_workers=4 # Limite para dispositivos móveis

        dask_threads=1 # Single thread por worker para estabilidade térmica

        # Cálculo de memória por worker com validação
        if [ "$dask_workers" -gt 0 ] && [ "$available_mem_for_dask" -gt 512 ]; then
            local memory_per_worker=$((available_mem_for_dask / dask_workers))
            memory_limit="${memory_per_worker}M"
        else
            memory_limit="256M" # Fallback para dispositivos muito limitados
        fi

        dask_worker_class="dask.distributed.Nanny"

        # Ollama em modo CPU (Android geralmente não tem GPU dedicada)

    elif [ "$gpu_count" -gt 0 ] && [ "$primary_gpu_vram_mb" -ge 4000 ]; then
        log "Perfil de otimização: GPU-Focused"
        dask_worker_class="dask_cuda.CUDAWorker"

        # --- Configuração OLLAMA (baseada na VRAM da GPU primária e total) ---
        if [ "$primary_gpu_vram_mb" -ge 20000 ]; then # 20GB+
            ollama_num_gpu_layers=99; ollama_max_loaded_models=3
        elif [ "$primary_gpu_vram_mb" -ge 10000 ]; then # 10GB+
            ollama_num_gpu_layers=43; ollama_max_loaded_models=2
        elif [ "$primary_gpu_vram_mb" -ge 6000 ]; then # 6GB+
            ollama_num_gpu_layers=33; ollama_max_loaded_models=1
        else # 4-6GB
            ollama_num_gpu_layers=25; ollama_max_loaded_models=1
        fi
        # Ajustar modelos carregados com base na VRAM total
        ollama_max_loaded_models=$(( total_gpu_vram_mb / 8000 ))
        [ "$ollama_max_loaded_models" -lt 1 ] && ollama_max_loaded_models=1

        # --- Configuração DASK (um worker por GPU) ---
        dask_workers=$gpu_count
        dask_threads=2 # GPU workers geralmente usam menos threads de CPU
        
        # Reservar memória RAM para Ollama e SO
        local reserved_mem_for_ollama=8192 # 8GB
        local available_mem_for_dask=$((total_memory_mb - reserved_mem_for_os - reserved_mem_for_ollama))

    else
        log "Perfil de otimização: CPU-Focused"
        # --- Configuração OLLAMA (modo CPU) ---
        ollama_num_gpu_layers=0
        ollama_max_loaded_models=1

        # --- Configuração DASK (agressiva, pois é o consumidor principal) ---
        dask_workers=$((cpu_cores - 1))
        [ "$dask_workers" -lt 1 ] && dask_workers=1
        dask_threads=2

        # Reservar memória RAM para Ollama (CPU) e SO
        local reserved_mem_for_ollama=4096 # 4GB
        local available_mem_for_dask=$((total_memory_mb - reserved_mem_for_os - reserved_mem_for_ollama))
    fi

    # --- Cálculo do Limite de Memória do Dask ---
    if [ "$dask_workers" -gt 0 ] && [ "$available_mem_for_dask" -gt 1024 ]; then
        local memory_per_worker=$((available_mem_for_dask / dask_workers))
        if [ "$memory_per_worker" -ge 1024 ]; then
            memory_limit="$((memory_per_worker / 1024))GB"
        else
            memory_limit="${memory_per_worker}MB"
        fi
    fi
    
    echo "DASK_WORKERS=$dask_workers"
    echo "DASK_THREADS=$dask_threads"
    echo "MEMORY_LIMIT=$memory_limit"
    echo "DASK_WORKER_CLASS=$dask_worker_class"
    echo "OLLAMA_NUM_GPU_LAYERS=$ollama_num_gpu_layers"
    echo "OLLAMA_MAX_LOADED_MODELS=$ollama_max_loaded_models"
    echo "DOCKER_OPENWEBUI_CPUS=$docker_openwebui_cpus"
    echo "DOCKER_OPENWEBUI_MEMORY=$docker_openwebui_memory"
}

# Função para aplicar configurações otimizadas
apply_optimized_settings() {
    local settings="$1"
    local non_interactive="${2:-false}"
    local profile="${3:-default}"
    
    # Extrair configurações
    local dask_workers=$(echo "$settings" | grep "DASK_WORKERS=" | cut -d= -f2)
    local dask_threads=$(echo "$settings" | grep "DASK_THREADS=" | cut -d= -f2)
    local memory_limit=$(echo "$settings" | grep "MEMORY_LIMIT=" | cut -d= -f2)
    local dask_worker_class=$(echo "$settings" | grep "DASK_WORKER_CLASS=" | cut -d= -f2)
    local ollama_num_gpu_layers=$(echo "$settings" | grep "OLLAMA_NUM_GPU_LAYERS=" | cut -d= -f2)
    local ollama_max_loaded_models=$(echo "$settings" | grep "OLLAMA_MAX_LOADED_MODELS=" | cut -d= -f2)
    local docker_cpus=$(echo "$settings" | grep "DOCKER_OPENWEBUI_CPUS=" | cut -d= -f2)
    local docker_memory=$(echo "$settings" | grep "DOCKER_OPENWEBUI_MEMORY=" | cut -d= -f2)
    
    log "Aplicando configurações otimizadas:"
    log "  Dask Workers: $dask_workers"
    log "  Dask Threads: $dask_threads"
    log "  Dask Memory Limit: $memory_limit"
    log "  Dask Worker Class: $dask_worker_class"
    log "  Ollama GPU Layers: $ollama_num_gpu_layers"
    log "  Ollama Max Loaded Models: $ollama_max_loaded_models"
    log "  OpenWebUI Docker CPUs: $docker_cpus"
    log "  OpenWebUI Docker Memory: $docker_memory"
    
    # Atualizar configuração do Dask
    update_dask_config "$dask_workers" "$dask_threads" "$memory_limit" "$dask_worker_class"
    
    # Atualizar configuração Ollama
    if [ "$profile" == "android" ]; then
        # No Android, não usamos systemd. Criamos um arquivo de ambiente.
        local ollama_env_file="$HOME/.cluster_config/ollama_env.conf"
        log "Gerando arquivo de ambiente para Ollama em $ollama_env_file"
        mkdir -p "$(dirname "$ollama_env_file")"
        cat > "$ollama_env_file" << EOL
# Para usar, inicie o Ollama com: source $ollama_env_file && ollama serve
export OLLAMA_NUM_GPU=${ollama_num_gpu_layers}
export OLLAMA_MAX_LOADED_MODELS=${ollama_max_loaded_models}
EOL
        success "Arquivo de ambiente do Ollama para Android gerado."
        info "Use 'source $ollama_env_file' antes de 'ollama serve'."
    else
        # Para Linux, usamos systemd
        if [ "$non_interactive" = true ] || confirm_operation "As configurações do Ollama exigem privilégios de root para serem aplicadas. Continuar?"; then
            sudo bash -c "$(declare -f log success error info section subsection; declare -f update_ollama_config); update_ollama_config '$ollama_num_gpu_layers' '$ollama_max_loaded_models'"
        else
            warn "A atualização da configuração do Ollama foi pulada."
        fi
    fi

    # Atualizar limites do container Docker
    if [ "$profile" != "android" ]; then
        update_docker_container_limits "$OPENWEBUI_CONTAINER_NAME" "$docker_cpus" "$docker_memory"
    else
        log "Pulando atualização de container Docker para o perfil Android."
    fi
}

# Função para atualizar a configuração do Dask
update_dask_config() {
    local workers=$1
    local threads=$2
    local memory_limit=$3
    local worker_class=$4
    local dask_config_file="$CLUSTER_CONFIG_DIR/dask.conf"

    mkdir -p "$CLUSTER_CONFIG_DIR"

    # Backup da configuração anterior
    [ -f "$dask_config_file" ] && cp "$dask_config_file" "${dask_config_file}.bak"

    log "Atualizando configuração do Dask em $dask_config_file"
    cat > "$dask_config_file" << EOL
# Configuração do Dask Worker gerada pelo otimizador
DASK_WORKERS=${workers}
DASK_THREADS=${threads}
DASK_MEMORY_LIMIT=${memory_limit}
DASK_WORKER_CLASS=${worker_class}
EOL
    success "Configuração do Dask Worker atualizada."
    info "Reinicie os workers Dask para aplicar as mudanças."
}

# Função para atualizar configuração Ollama
update_ollama_config() {
    local num_gpu_layers=$1
    local max_models=$2
    local ollama_config_dir="/etc/systemd/system/ollama.service.d"
    local ollama_config_file="$ollama_config_dir/override.conf"

    # Esta função deve ser chamada com sudo
    mkdir -p "$ollama_config_dir"
    # Backup da configuração anterior
    [ -f "$ollama_config_file" ] && cp "$ollama_config_file" "${ollama_config_file}.bak"

    log "Atualizando configuração do serviço Ollama em $ollama_config_file"
    tee "$ollama_config_file" > /dev/null << EOL
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_NUM_GPU=${num_gpu_layers}"
Environment="OLLAMA_MAX_LOADED_MODELS=${max_models}"
EOL
    
    # Reiniciar Ollama se estiver rodando
    if systemctl is-active --quiet ollama; then
        log "Recarregando daemon e reiniciando serviço Ollama..."
        systemctl daemon-reload
        systemctl restart ollama
        log "Configuração do Ollama atualizada e serviço reiniciado"
    else
        log "Configuração do Ollama atualizada. Inicie o serviço para aplicar."
    fi
}

# Função para atualizar os limites de um container Docker
update_docker_container_limits() {
    local container_name="$1"
    local cpus="$2"
    local memory="$3"

    subsection "Atualizando Limites do Container Docker: $container_name"

    if ! command_exists docker; then
        warn "Comando 'docker' não encontrado. Pulando atualização de container."
        return 1
    fi

    if ! sudo docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        warn "Container '$container_name' não encontrado. Pulando atualização."
        return 1
    fi

    log "Aplicando limites: --cpus $cpus --memory $memory para o container '$container_name'..."
    if sudo docker update --cpus "$cpus" --memory "$memory" "$container_name" > /dev/null; then
        success "Limites de recursos para o container '$container_name' atualizados."
    else
        error "Falha ao atualizar os limites do container '$container_name'."
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
        warn "Uso de CPU crítico (${cpu_usage}%). Ação de redução de carga recomendada."
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
    warn "Carga de CPU alta detectada."
    info "Recomendação: Reduza o número de Dask workers ou a intensidade das tarefas."
    info "Para ajustar, execute: ./manager.sh, pare os serviços, execute o otimizador e reinicie."
    # A lógica de redução automática foi removida para evitar instabilidade. A ação agora é manual.
}

# Função para liberar memória
free_memory() {
    # Verificar se temos privilégios sudo antes de executar comandos destrutivos
    if ! sudo -n true 2>/dev/null; then
        warn "Privilégios sudo necessários para liberar memória. Execute com sudo."
        return 1
    fi
    
    # Limpar cache do Ollama se estiver usando muita memória
    if command_exists ollama; then
        warn "Uso de memória alto. Descarregando modelos Ollama não utilizados..."
        ollama ps | grep -v "NAME" | awk '{print $1}' | xargs -I {} ollama rm {} 2>/dev/null
        success "Modelos Ollama descarregados."
    fi

    if confirm_operation "O uso de memória ainda está crítico. Deseja limpar os caches de página do sistema (pode impactar a performance de I/O temporariamente)?"; then
        warn "Liberando cache de memória do sistema..."
        sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
        success "Caches de página do sistema limpos."
    fi
}

# Função para limpar espaço em disco
cleanup_disk() {
    warn "Iniciando limpeza de disco..."
    
    if ! confirm_operation "Esta operação tentará remover logs antigos e limpar caches do sistema (pip, docker)."; then
        log "Limpeza de disco cancelada pelo usuário."
        return 1
    fi
    
    # Limpar logs antigos com validação de caminhos
    log "Limpando logs antigos..."
    local log_dirs=("/var/log" "$HOME/.local/state" "$HOME/.cache")
    for log_dir in "${log_dirs[@]}"; do
        if safe_path_check "$log_dir" "limpeza de logs em $log_dir"; then
            log "Procurando logs com mais de 7 dias em: $log_dir"
            # Usar -print0 e xargs para mais segurança com nomes de arquivo
            find "$log_dir" -name "*.log" -type f -mtime +7 -print0 | xargs -0 -r -- sudo rm -f
        else
            error "Caminho para limpeza de log é inseguro, pulando: $log_dir"
        fi
    done
    
    # Limpar cache do pip
    if command_exists pip; then log "Limpando cache do pip..."; pip cache purge >/dev/null 2>&1; fi
    
    # Limpar cache do Docker com validação
    if command_exists docker; then
        if confirm_operation "Limpar cache do Docker (imagens, contêineres e volumes não utilizados)?"; then log "Limpando cache do Docker..."; sudo docker system prune -af; fi
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
    if [ -f "$CLUSTER_CONFIG_DIR/dask.conf" ]; then
        source "$CLUSTER_CONFIG_DIR/dask.conf"
        echo "  Dask Workers: ${DASK_WORKERS:-Padrão}"
        echo "  Dask Threads: ${DASK_THREADS:-Padrão}"
        echo "  Memory Limit: ${DASK_MEMORY_LIMIT:-Padrão}"
    fi
    
    if [ -f "/etc/systemd/system/ollama.service.d/override.conf" ]; then
        echo "  Ollama GPU Layers: $(grep "OLLAMA_NUM_GPU" /etc/systemd/system/ollama.service.d/override.conf | cut -d'=' -f2 || echo "Padrão")"
        echo "  Ollama Max Loaded Models: $(grep "OLLAMA_MAX_LOADED_MODELS" /etc/systemd/system/ollama.service.d/override.conf | cut -d'=' -f2 || echo "Padrão")"
    fi
    
    # Uso atual - corrigido para garantir valores sempre exibidos
    echo -e "\n${CYAN}Uso Atual:${NC}"
    
    local cpu_line=$(LC_ALL=C top -bn1 | grep "Cpu(s)")
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

# Função para restaurar configurações de backup
restore_settings() {
    section "Restaurando Configurações Anteriores"
    local dask_config_file="$CLUSTER_CONFIG_DIR/dask.conf"
    local ollama_config_file="/etc/systemd/system/ollama.service.d/override.conf"

    [ -f "${dask_config_file}.bak" ] && mv "${dask_config_file}.bak" "$dask_config_file" && success "Configuração do Dask restaurada."
    if [ -f "${ollama_config_file}.bak" ]; then
        sudo mv "${ollama_config_file}.bak" "$ollama_config_file" && success "Configuração do Ollama restaurada."
        log "Recarregando daemon e reiniciando Ollama..."
        sudo systemctl daemon-reload && sudo systemctl restart ollama
    fi
}

# Menu principal
main() {
    # Criar diretório de configuração
    if ! safe_path_check "$CONFIG_DIR" "criação de diretório de configuração"; then
        exit 1
    fi
    mkdir -p "$CONFIG_DIR"
    # Touch log file to ensure it exists
    touch "$LOG_FILE"
    
    case "$1" in
        "optimize")
            local profile="default"
            local non_interactive=false
            # Simple argument parsing
            if [[ "$2" == "--profile" ]]; then
                profile="$3"
                shift 2
            fi
            if [[ "$2" == "-y" || "$2" == "--yes" ]] || [[ "$3" == "-y" || "$3" == "--yes" ]]; then
                non_interactive=true
            fi

            # A otimização do Ollama requer sudo, então verificamos no início.
            if [[ $EUID -ne 0 ]]; then
                warn "A otimização completa requer privilégios de root para configurar o serviço Ollama."
                warn "Executando novamente com 'sudo'..."
                sudo -E "$0" "$@"
                exit $?
            fi
            log "Otimizando configurações baseadas nos recursos do sistema..."
            local resources=$(detect_system_resources)
            local cpu_cores=$(echo "$resources" | grep "CPU_CORES" | cut -d= -f2)
            local total_memory_mb=$(echo "$resources" | grep "TOTAL_MEMORY_MB" | cut -d= -f2)
            local gpu_count=$(echo "$resources" | grep "GPU_COUNT" | cut -d= -f2)
            local total_gpu_vram_mb=$(echo "$resources" | grep "TOTAL_GPU_VRAM_MB" | cut -d= -f2)
            local primary_gpu_vram_mb=$(echo "$resources" | grep "PRIMARY_GPU_VRAM_MB" | cut -d= -f2)
            
            local optimized_settings
            optimized_settings=$(calculate_optimized_settings "$cpu_cores" "$total_memory_mb" "$gpu_count" "$total_gpu_vram_mb" "$primary_gpu_vram_mb" "$profile")
            apply_optimized_settings "$optimized_settings" "$non_interactive" "$profile"
            ;;
        "monitor")
            log "Iniciando monitoramento contínuo..."
            monitor_resource_usage
            ;;
        "get-settings")
            # Apenas calcula e imprime as configurações, não as aplica.
            # Útil para outros scripts que precisam dos valores.
            local resources=$(detect_system_resources)
            local cpu_cores=$(echo "$resources" | grep "CPU_CORES" | cut -d= -f2)
            local total_memory_mb=$(echo "$resources" | grep "TOTAL_MEMORY_MB" | cut -d= -f2)
            local gpu_count=$(echo "$resources" | grep "GPU_COUNT" | cut -d= -f2)
            local total_gpu_vram_mb=$(echo "$resources" | grep "TOTAL_GPU_VRAM_MB" | cut -d= -f2)
            local primary_gpu_vram_mb=$(echo "$resources" | grep "PRIMARY_GPU_VRAM_MB" | cut -d= -f2)
            calculate_optimized_settings "$cpu_cores" "$total_memory_mb" "$gpu_count" "$total_gpu_vram_mb" "$primary_gpu_vram_mb"
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
        "restore")
            restore_settings
            ;;
        *)
            echo -e "${BLUE}Uso: $0 [comando]${NC}"
            echo "Comandos:"
            echo "  optimize [--profile <name>] [-y] - Otimizar configurações. Perfis: default, android."
            echo "  monitor      - Iniciar monitoramento contínuo"
            echo "  get-settings - Obter configurações calculadas sem aplicar"
            echo "  restore      - Restaurar configurações anteriores ao último 'optimize'"
            echo "  status       - Mostrar status atual"
            echo "  free-memory  - Liberar memória imediatamente"
            echo "  clean-disk   - Limpar espaço em disco"
            ;;
    esac
}

# Executar comando solicitado
main "$@"
