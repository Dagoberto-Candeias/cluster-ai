#!/bin/bash
# Sistema de Verificação de Saúde do Cluster AI - Versão Aprimorada
# Versão: 3.0 - Com validação completa, sugestões de correção e monitoramento avançado

# ==================== CONFIGURAÇÃO DE SEGURANÇA ====================

# Prevenção de execução como root
if [ "$EUID" -eq 0 ]; then
    echo "ERRO CRÍTICO: Este script NÃO deve ser executado como root."
    echo "Por favor, execute como um usuário normal com privilégios sudo quando necessário."
    exit 1
fi

# Validação do contexto de execução
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../" && pwd)"
if [ ! -f "$PROJECT_ROOT/README.md" ]; then
    echo "ERRO: Script executado fora do contexto do projeto Cluster AI"
    exit 1
fi

# Carregar funções comuns
COMMON_SCRIPT_PATH="$SCRIPT_DIR/common.sh"
if [ ! -f "$COMMON_SCRIPT_PATH" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns 'common.sh' não encontrado em $COMMON_SCRIPT_PATH"
    exit 1
fi
source "$COMMON_SCRIPT_PATH"

# Configurações
LOG_FILE="/tmp/cluster_ai_health_$(date +%Y%m%d_%H%M%S).log"
OVERALL_HEALTH=true
VENV_PRIORITY=("$PROJECT_ROOT/.venv" "$HOME/venv")  # Prioridade: .venv no projeto, depois $HOME/venv


# Funções de log aprimoradas
log() { echo -e "${CYAN}[HEALTH-CHECK $(date '+%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[HEALTH-WARN $(date '+%H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[HEALTH-ERROR $(date '+%H:%M:%S')]${NC} $1"; }
section() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
subsection() { echo -e "\n${CYAN}➤ $1${NC}"; }

# Função para verificar comando com sugestões de instalação
check_command() {
    local cmd="$1"
    local description="$2"
    local install_cmd="${3:-}"

    if command_exists "$cmd"; then
        success "✅ $description: Disponível ($(which $cmd))"
        return 0
    else
        fail "❌ $description: Não encontrado"
        if [ -n "$install_cmd" ]; then
            echo "   💡 Execute: $install_cmd"
        fi
        OVERALL_HEALTH=false
        return 1
    fi
}

# Função para verificar serviço com opção de restart
check_service() {
    local service_name="$1"
    local description="$2"

    if service_active "$service_name"; then
        success "✅ $description: Ativo"
        return 0
    else
        fail "❌ $description: Inativo"
        OVERALL_HEALTH=false
        if confirm_operation "Tentar reiniciar o serviço $service_name?"; then
            if sudo systemctl restart "$service_name"; then
                success "✅ Serviço $service_name reiniciado com sucesso."
            else
                error "❌ Falha ao reiniciar o serviço $service_name."
            fi
        fi
        return 1
    fi
}

# Função para verificar diretório com permissões
check_directory() {
    local dir="$1"
    local description="$2"
    local required="${3:-false}"

    if [ -d "$dir" ]; then
        local perms=$(stat -c "%a %U:%G" "$dir" 2>/dev/null || stat -f "%Sp %u:%g" "$dir")
        success "✅ $description: Existe ($perms)"

        # Verificar permissões de escrita
        if [ ! -w "$dir" ]; then
            warn "⚠️  $description: Sem permissão de escrita"
            echo "   💡 Execute: chmod 755 $dir"
        fi
        return 0
    else
        if [ "$required" = true ]; then
            fail "❌ $description: Não existe (OBRIGATÓRIO)"
            OVERALL_HEALTH=false
        else
            warn "⚠️  $description: Não existe"
        fi
        return 1
    fi
}

# Função para verificar arquivo com validação
check_file() {
    local file="$1"
    local description="$2"
    local required="${3:-false}"

    if [ -f "$file" ]; then
        local size=$(du -h "$file" 2>/dev/null | cut -f1 || echo "N/A")
        success "✅ $description: Existe ($size)"
        return 0
    else
        if [ "$required" = true ]; then
            fail "❌ $description: Não existe (OBRIGATÓRIO)"
            OVERALL_HEALTH=false
        else
            warn "⚠️  $description: Não existe"
        fi
        return 1
    fi
}

# Função para verificar conectividade de rede
check_network() {
    subsection "Conectividade de Rede"

    # Testar conectividade com internet
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        success "✅ Internet: Conectado"
    else
        warn "⚠️  Internet: Sem conectividade"
        OVERALL_HEALTH=false
    fi

    # Testar DNS
    if ping -c 1 -W 2 google.com >/dev/null 2>&1; then
        success "✅ DNS: Funcionando"
    else
        warn "⚠️  DNS: Problemas de resolução"
        OVERALL_HEALTH=false
    fi

    # Testar portas locais importantes
    local ports=("11434" "7860" "8787" "80" "443")
    for port in "${ports[@]}"; do
        if nc -z localhost $port 2>/dev/null; then
            success "✅ Porta $port: Aberta"
        else
            echo "   Porta $port: Fechada (esperado para alguns serviços)"
        fi
    done
}

# Função para verificar GPU
check_gpu() {
    subsection "Configuração de GPU"

    # Verificar NVIDIA
    if command_exists nvidia-smi; then
        success "✅ GPU NVIDIA: Detectada"
        nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv
        return 0
    fi
    
    # Verificar AMD
    if command_exists rocminfo || [ -d "/opt/rocm" ]; then
        success "✅ GPU AMD: Detectada"
        if command_exists rocminfo; then
            rocminfo | grep -E "Device Type|Marketing Name" | head -4
        fi
        return 0
    fi
    
    warn "⚠️  GPU: Não detectada - Modo CPU"
    return 1
}

# Função para verificar PyTorch
check_pytorch() {
    subsection "Framework PyTorch"

    if python3 -c "import torch; print(f'PyTorch {torch.__version__}'); print(f'CUDA: {torch.cuda.is_available()}')" 2>/dev/null; then
        success "✅ PyTorch: Funcionando"
        return 0
    else
        fail "❌ PyTorch: Erro na importação"
        echo "   💡 Execute: pip install torch torchvision torchaudio"
        OVERALL_HEALTH=false
        return 1
    fi
}

# Função para verificar ambiente virtual (padronizada)
check_venv() {
    subsection "Ambiente Virtual Python"
    log "Verificando ambientes virtuais (prioridade: .venv > \$HOME/venv)..."
    
    local venv_found=false
    local active_venv=""

    # Verificar ambientes na ordem de prioridade
    for venv_path in "${VENV_PRIORITY[@]}"; do
        if [ -d "$venv_path" ]; then
            venv_found=true
            active_venv="$venv_path"

            # Verificar se pode ser ativado
            if source "$venv_path/bin/activate" 2>/dev/null && python -c "import sys; print(f'Python: {sys.version}')" 2>/dev/null; then
                success "✅ $venv_path: Funcional ($(python --version 2>&1))"
                # Verificar pacotes essenciais
                local missing_packages=()
                for pkg in "torch" "numpy" "requests" "pandas" "scikit-learn"; do
                    if ! python -c "import $pkg" 2>/dev/null; then
                        missing_packages+=("$pkg")
                    fi
                done

                if [ ${#missing_packages[@]} -eq 0 ]; then
                    success "📦 Pacotes essenciais: Todos presentes"
                else
                    warn "⚠️  Pacotes ausentes: ${missing_packages[*]}"
                    if confirm_operation "Deseja instalar os pacotes ausentes?"; then
                        if python -m pip install "${missing_packages[@]}"; then
                            success "✅ Pacotes instalados com sucesso."
                        fi
                    fi
                fi

                deactivate
            else
                fail "❌ $venv_path: Corrompido ou não funcional"
                OVERALL_HEALTH=false
                echo "   💡 Para remover o ambiente corrompido, execute o comando seguro abaixo:"
                echo "      VENV_TO_DELETE=\"$venv_path\"; if [ -n \"\$VENV_TO_DELETE\" ] && [[ \"\$VENV_TO_DELETE\" == *\"$PROJECT_ROOT\"* || \"\$VENV_TO_DELETE\" == *\"$HOME\"* ]]; then rm -rf \"\$VENV_TO_DELETE\"; else echo 'Caminho inseguro, remoção abortada.'; fi"
                echo "   Depois, recrie com: ./scripts/installation/venv_setup.sh"
            fi
            break
        fi
    done
    
    if [ "$venv_found" = false ]; then
        fail "❌ Nenhum ambiente virtual encontrado"
        OVERALL_HEALTH=false
        if [ -f "$PROJECT_ROOT/scripts/installation/setup_python_env.sh" ]; then
            if confirm_operation "Deseja criar o ambiente virtual agora?"; then
                bash "$PROJECT_ROOT/scripts/installation/setup_python_env.sh"
            fi
        fi
    fi

    # Documentar padrão recomendado
    if [ "$venv_found" = true ]; then
        echo "📋 Padrão recomendado: .venv no diretório do projeto (${VENV_PRIORITY[0]})"
    fi
}

# Função para verificar Ollama com validação completa
check_ollama() {
    subsection "Serviço Ollama"

    if command_exists ollama; then
        success "✅ Ollama: Instalado ($(which ollama))"

        # Verificar serviço Ollama
        if service_active ollama; then
            success "✅ Serviço Ollama: Ativo"

            # Verificar API Ollama
            local api_response=$(curl -s -w "%{http_code}" http://localhost:11434/api/tags -o /dev/null 2>/dev/null || echo "000")
            if [ "$api_response" = "200" ]; then
                success "✅ API Ollama: Respondendo (HTTP 200)"

                # Listar e validar modelos
                local models=$(timeout 10 ollama list 2>/dev/null || echo "timeout")
                if [ "$models" != "timeout" ]; then
                    local models_count=$(echo "$models" | wc -l)
                    if [ $models_count -gt 1 ]; then
                        success "📦 Modelos Ollama: $((models_count - 1)) instalado(s)"
                        echo "   Modelos: $(echo "$models" | grep -v "NAME" | awk '{print $1}' | tr '\n' ' ' | sed 's/ $//')"

                        # --- INÍCIO DO TESTE DE LATÊNCIA ---
                        subsection "Teste de Latência dos Modelos"
                        local model_names
                        model_names=$(echo "$models" | grep -v "NAME" | awk '{print $1}')

                        for model in $model_names; do
                            log "   Testando latência para o modelo: $model..."
                            local start_time; start_time=$(date +%s.%N)
                            
                            # Envia um prompt simples e mede o tempo de resposta. Timeout de 60s.
                            local api_response; api_response=$(timeout 60 curl -s -X POST http://localhost:11434/api/generate -d "{\"model\": \"$model\", \"prompt\": \"Responda apenas com 'OK'.\", \"stream\": false}" 2>/dev/null)
                            local end_time; end_time=$(date +%s.%N)
                            
                            if echo "$api_response" | grep -q "\"response\":\"OK\""; then
                                local duration; duration=$(echo "$end_time - $start_time" | bc)
                                local duration_formatted; duration_formatted=$(printf "%.2f" "$duration")

                                # Alertas baseados na latência (valores podem ser ajustados)
                                if (( $(echo "$duration > 20" | bc -l) )); then
                                    warn "   - Latência para '$model': ${duration_formatted}s (LENTO)"
                                else
                                    success "   - Latência para '$model': ${duration_formatted}s (RÁPIDO)"
                                fi
                            else
                                local error_message; error_message=$(echo "$api_response" | grep -o '"error":"[^"]*"' | cut -d'"' -f4)
                                fail "   - Falha ao testar o modelo '$model'. Erro da API: ${error_message:-'Resposta inválida ou timeout'}"
                                OVERALL_HEALTH=false
                            fi
                        done
                        # --- FIM DO TESTE DE LATÊNCIA ---
                    else
                        warn "⚠️  Modelos Ollama: Nenhum modelo instalado"
                        if confirm_operation "Deseja baixar um modelo padrão (llama3.1:8b)?"; then
                            if ollama pull llama3.1:8b; then
                                success "✅ Modelo padrão baixado com sucesso."
                            fi
                        fi
                    fi
                else
                    warn "⚠️  Ollama: Timeout ao listar modelos"
                fi
            else
                fail "❌ API Ollama: Não responde (HTTP $api_response)"
                echo "   💡 Execute: sudo systemctl restart ollama"
                OVERALL_HEALTH=false
            fi
        else
            fail "❌ Serviço Ollama: Inativo"
            echo "   💡 Execute: sudo systemctl start ollama"
            OVERALL_HEALTH=false
        fi

        # Verificar diretório de modelos
        check_directory "$HOME/.ollama" "Diretório de modelos Ollama" false

    else
        warn "⚠️  Ollama: Não instalado"
        if confirm_operation "Deseja tentar instalar o Ollama agora?"; then
            if curl -fsSL https://ollama.com/install.sh | sh; then
                success "✅ Ollama instalado. Execute o health check novamente para configurar."
            fi
        fi
    fi
}

# Função para verificar Dask com monitoramento
check_dask() {
    subsection "Cluster Dask"
    
    # Verificar scheduler
    if process_running "dask-scheduler"; then
        local scheduler_pid=$(pgrep -f "dask-scheduler")
        success "✅ Dask Scheduler: Executando (PID: $scheduler_pid)"
    else
        warn "⚠️  Dask Scheduler: Não está executando"
        echo "   💡 Execute: dask scheduler --port 8786 &"
    fi

    # Verificar workers
    local workers_count=$(pgrep -f "dask-worker" | wc -l)
    if [ $workers_count -gt 0 ]; then
        success "✅ Dask Workers: $workers_count executando"
        # Mostrar informações dos workers
        pgrep -f "dask-worker" | xargs ps -o pid,pcpu,pmem,cmd -p 2>/dev/null | head -$((workers_count+1))
    else
        warn "⚠️  Dask Workers: Nenhum worker executando"
        echo "   💡 Execute: dask worker tcp://localhost:8786 --nworkers 4 &"
    fi

    # Verificar dashboard
    if nc -z localhost 8787 2>/dev/null; then
        success "✅ Dashboard Dask: Acessível em http://localhost:8787"
    else
        echo "   Dashboard Dask: Porta 8787 fechada"
    fi
}

# Função para verificar a conectividade dos workers remotos com o scheduler
check_remote_dask_connectivity() {
    subsection "Conectividade dos Workers Dask Remotos"
    local nodes_file="$HOME/.cluster_config/nodes_list.conf"

    if [ ! -f "$nodes_file" ] || [ ! -s "$nodes_file" ]; then
        info "Nenhum nó remoto configurado em '$nodes_file'. Pulando verificação."
        return
    fi

    local scheduler_ip
    scheduler_ip=$(hostname -I | awk '{print $1}')
    if [ -z "$scheduler_ip" ]; then
        fail "❌ Não foi possível determinar o IP do Scheduler local. Não é possível testar a conectividade remota."
        report_issue "FAIL" "Dask Remote" "IP do Scheduler local não encontrado" "Verifique a configuração de rede do nó principal."
        OVERALL_HEALTH=false
        return
    fi

    log "Verificando conectividade dos nós remotos com o Scheduler em: $scheduler_ip:8786"

    while read -r hostname ip user; do
        if [ -z "$hostname" ]; then continue; fi # Pular linhas vazias

        log "   Testando nó: $user@$hostname ($ip)..."
        
        # 1. Testar conectividade SSH
        if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "$user@$hostname" "echo 'SSH OK'" >/dev/null 2>&1; then
            fail "   - Conexão SSH com '$hostname': FALHOU"
            report_issue "FAIL" "Dask Remote ($hostname)" "Conexão SSH falhou" "Verifique a configuração de chaves SSH."
            OVERALL_HEALTH=false
            continue
        fi

        # 2. Testar conectividade de rede do worker para o scheduler
        if ssh "$user@$hostname" "timeout 5 bash -c 'cat < /dev/null > /dev/tcp/$scheduler_ip/8786'" >/dev/null 2>&1; then
            success "   - Conectividade de rede com Scheduler: OK"
        else
            fail "   - Conectividade de rede com Scheduler: FALHOU"
            report_issue "FAIL" "Dask Remote ($hostname)" "Não consegue alcançar a porta 8786 do Scheduler" "Verifique o firewall no nó principal e no remoto."
            OVERALL_HEALTH=false
        fi
    done < <(grep -vE '^\s*(#|$)' "$nodes_file")
}

# Função para verificar containers Docker com health check
check_docker_containers() {
    subsection "Containers Docker do Projeto"
    
    if ! command_exists docker; then
        warn "⚠️  Docker: Não instalado - pulando verificação de containers"
        return
    fi

    # Verificar se Docker está rodando
    if ! docker info >/dev/null 2>&1; then
        fail "❌ Docker: Daemon não está rodando"
        echo "   💡 Execute: sudo systemctl start docker"
        OVERALL_HEALTH=false
        return
    fi

    local containers=("open-webui" "openwebui-nginx")
    local container_found=false

    for container in "${containers[@]}"; do
        local container_info=$(docker ps --filter "name=$container" --format "{{.Names}}|{{.Status}}|{{.Ports}}" 2>/dev/null)

        if [ -n "$container_info" ]; then
            container_found=true
            IFS='|' read -r name status ports <<< "$container_info"

            if [[ "$status" == *"Up"* ]]; then
                success "✅ Container $name: $status"
                echo "   Portas: $ports"

                # Verificar health status se disponível
                local health=$(docker inspect --format='{{.State.Health.Status}}' "$name" 2>/dev/null || echo "N/A")
                if [ "$health" != "N/A" ]; then
                    echo "   Saúde: $health"
                fi
            else
                warn "⚠️  Container $name: $status"
                if confirm_operation "Tentar iniciar o container $name?"; then
                    if docker start "$name"; then
                        success "✅ Container $name iniciado."
                    fi
                fi
            fi
        else
            echo "   Container $container: Não encontrado"
        fi
    done

    if [ "$container_found" = false ]; then
        echo "💡 Nenhum container do projeto encontrado"
        echo "   Execute: docker-compose -f configs/docker/compose-basic.yml up -d"
    fi
}

# Função para verificar uso de recursos com alertas e sugestões
check_resources() {
    subsection "Monitoramento de Recursos"

    # Memória RAM
    local mem_info=$(free -b 2>/dev/null || vm_stat 2>/dev/null)
    local mem_total_kb=$(echo "$mem_info" | awk '/Mem:/ {print $2/1024}')
    local mem_used_kb=$(echo "$mem_info" | awk '/Mem:/ {print $3/1024}')
    local mem_used_percent=$((mem_used_kb * 100 / mem_total_kb))
    local mem_total=$(free -h | awk '/Mem:/ {print $2}' || echo "N/A")
    local mem_used=$(free -h | awk '/Mem:/ {print $3}' || echo "N/A")
    local mem_free=$(free -h | awk '/Mem:/ {print $4}' || echo "N/A")

    echo "💾 Memória RAM: Total: $mem_total, Usada: $mem_used, Livre: $mem_free"

    # Alertas de memória
    if [ $mem_used_percent -gt 90 ]; then
        error "🚨 ALERTA CRÍTICO: Uso de memória: ${mem_used_percent}%"
        echo "   💡 Execute: ./scripts/utils/memory_manager.sh --optimize"
        OVERALL_HEALTH=false
    elif [ $mem_used_percent -gt 80 ]; then
        warn "⚠️  AVISO: Uso de memória alto: ${mem_used_percent}%"
        echo "   💡 Monitor: ./scripts/utils/memory_manager.sh --monitor"
    fi

    # CPU
    local cpu_cores=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo "1")
    local cpu_load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | tr -d ',')
    local cpu_load_per_core=$(echo "scale=2; $cpu_load / $cpu_cores" | bc 2>/dev/null || echo "0")

    echo "⚡ CPU: Núcleos: $cpu_cores, Carga: $cpu_load (${cpu_load_per_core}/núcleo)"

    # Alertas de CPU
    if (( $(echo "$cpu_load_per_core > 2.0" | bc -l 2>/dev/null || echo "0") )); then
        error "🚨 ALERTA CRÍTICO: Carga de CPU: ${cpu_load_per_core}/núcleo"
        echo "   💡 Execute: ./scripts/optimization/performance_optimizer.sh"
        OVERALL_HEALTH=false
    elif (( $(echo "$cpu_load_per_core > 1.5" | bc -l 2>/dev/null || echo "0") )); then
        warn "⚠️  AVISO: Carga de CPU alta: ${cpu_load_per_core}/núcleo"
    fi

    # Disco
    local disk_info=$(df / 2>/dev/null || df /System/Volumes/Data 2>/dev/null)
    local disk_usage_percent=$(echo "$disk_info" | awk 'NR==2 {print $5}' | sed 's/%//')
    local disk_total=$(echo "$disk_info" | awk 'NR==2 {print $2}' | awk '{printf "%.1fG", $1/1024/1024}')
    local disk_used=$(echo "$disk_info" | awk 'NR==2 {print $3}' | awk '{printf "%.1fG", $1/1024/1024}')
    local disk_avail=$(echo "$disk_info" | awk 'NR==2 {print $4}' | awk '{printf "%.1fG", $1/1024/1024}')

    echo "💿 Disco: ${disk_usage_percent}% usado (${disk_used}/${disk_total}), Livre: ${disk_avail}"

    # Alertas de disco
    if [ $disk_usage_percent -gt 90 ]; then
        error "🚨 ALERTA CRÍTICO: Uso de disco: ${disk_usage_percent}%"
        echo "   💡 Execute: ./scripts/maintenance/clean-cache.sh"
        OVERALL_HEALTH=false
    elif [ $disk_usage_percent -gt 80 ]; then
        warn "⚠️  AVISO: Uso de disco alto: ${disk_usage_percent}%"
        echo "   💡 Execute: find ~ -name \"*.log\" -size +100M -exec ls -lh {} \\;"
    fi

    # GPU Memory (se disponível)
    check_gpu_memory

    # Temperatura
    check_temperature

    # I/O Performance (teste simples)
    check_io_performance
}

# Função para verificar memória GPU
check_gpu_memory() {
    if command_exists nvidia-smi; then
        local gpu_info=$(nvidia-smi --query-gpu=memory.total,memory.used,memory.free --format=csv,noheader,nounits 2>/dev/null)
        if [ -n "$gpu_info" ]; then
            IFS=',' read -r total used free <<< "$gpu_info"
            local used_percent=$((used * 100 / total))

            echo "🎮 GPU Memory: ${used}MB/${total}MB usado (${used_percent}%), Livre: ${free}MB"

            if [ $used_percent -gt 90 ]; then
                warn "⚠️  Uso de memória GPU alto: ${used_percent}%"
                echo "   💡 Execute: nvidia-smi para ver processos usando GPU"
            fi
        fi
    fi
}

# Função para verificar temperatura com alertas
check_temperature() {
    # Linux
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        local temp_c=$((temp/1000))
        echo "🌡️  Temperatura CPU: ${temp_c}°C"

        if [ $temp_c -gt 85 ]; then
            error "🚨 ALERTA: Temperatura crítica: ${temp_c}°C"
            echo "   💡 Verifique ventilação e limpeza do sistema"
            OVERALL_HEALTH=false
        elif [ $temp_c -gt 75 ]; then
            warn "⚠️  Temperatura alta: ${temp_c}°C"
        fi
    # macOS
    elif command_exists osx-cpu-temp; then
        local temp_c=$(osx-cpu-temp | grep -o '[0-9]*\.[0-9]*')
        echo "🌡️  Temperatura CPU: ${temp_c}°C"
    fi
}

# Função para verificar performance I/O
check_io_performance() {
    echo "⏱️  Teste rápido de I/O..."

    # Teste simples de write performance
    local test_file="/tmp/io_test_$(date +%s)"
    local start_time=$(date +%s.%N)

    dd if=/dev/zero of="$test_file" bs=1M count=10 oflag=direct 2>/dev/null
    local dd_exit_code=$?

    if [ $dd_exit_code -eq 0 ]; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc)
        local speed=$(echo "scale=2; 10 / $duration" | bc)
    else
        local speed="N/A"
    fi

    echo "   Velocidade de escrita: ${speed} MB/s"

    # Remoção segura do arquivo de teste
    if [ -f "$test_file" ]; then
        if safe_path_check "$test_file" "remoção de arquivo de teste de I/O"; then
            rm -f "$test_file"
        else
            error "Caminho do arquivo de teste de I/O é inseguro. Remoção manual necessária: $test_file"
        fi
    fi

    if [[ "$speed" != "N/A" ]] && (( $(echo "$speed < 50" | bc -l) )); then
        warn "⚠️  Performance de I/O baixa: ${speed} MB/s"
        echo "   💡 Verifique saúde do disco: smartctl -a /dev/sda"
    fi
}

# Função para verificar o serviço de monitoramento
check_monitor_service() {
    subsection "Serviço de Monitoramento de Recursos"
    local service_name="resource-monitor.service"

    if systemctl is-active --quiet "$service_name"; then
        success "✅ Serviço de Monitoramento ($service_name): Ativo e protegendo o sistema."
    else
        warn "⚠️  Serviço de Monitoramento ($service_name): Inativo."
        if [ -f "$PROJECT_ROOT/scripts/deployment/setup_monitor_service.sh" ]; then
            if confirm_operation "Deseja configurar e ativar o serviço de monitoramento agora?"; then
                sudo bash "$PROJECT_ROOT/scripts/deployment/setup_monitor_service.sh"
            fi
        fi
    fi
}

# Função para verificar se as extensões recomendadas do VSCode estão instaladas
check_vscode_extensions() {
    subsection "Extensões do Visual Studio Code"

    if ! command_exists code; then
        warn "⚠️  VSCode: Comando 'code' não encontrado. Pulando verificação de extensões."
        # Não reporta como problema crítico, pois o VSCode pode não ser o editor principal.
        return
    fi

    # Lista de extensões recomendadas (baseada em setup_vscode.sh)
    local recommended_extensions=(
        "ms-python.python"
        "ms-python.vscode-pylance"
        "ms-toolsai.jupyter"
        "github.copilot"
        "github.copilot-chat"
        "blackboxapp.blackbox"
        "sourcegraph.cody-ai"
        "eamodio.gitlens"
        "ms-azuretools.vscode-docker"
        "streetsidesoftware.code-spell-checker"
        "streetsidesoftware.code-spell-checker-portuguese-brazilian"
        "usernamehw.errorlens"
        "aaron-bond.better-comments"
        "yzhang.markdown-all-in-one"
        "dracula-theme.theme-dracula"
        "pkief.material-icon-theme"
        "ms-vsliveshare.vsliveshare"
    )

    log "Verificando ${#recommended_extensions[@]} extensões recomendadas..."
    local installed_extensions; installed_extensions=$(code --list-extensions 2>/dev/null)
    local missing_extensions=()

    for ext in "${recommended_extensions[@]}"; do
        if ! echo "$installed_extensions" | grep -qix "$ext"; then
            missing_extensions+=("$ext")
        fi
    done

    if [ ${#missing_extensions[@]} -eq 0 ]; then
        success "✅ Todas as extensões recomendadas do VSCode estão instaladas."
    else
        fail "❌ Extensões recomendadas ausentes: ${#missing_extensions[@]}"
        report_issue "FAIL" "VSCode Extensions" "${#missing_extensions[@]} extensões ausentes" "Execute 'code --install-extension <nome>' para cada uma."
        for missing in "${missing_extensions[@]}"; do
            echo "   - $missing"
        done
        OVERALL_HEALTH=false
    fi
}

# Função para verificar se o README.md está atualizado
check_readme_freshness() {
    subsection "Documentação (README.md)"
    local readme_file="${PROJECT_ROOT}/README.md"

    if ! check_file "$readme_file" "Arquivo README.md" true; then
        # A função check_file já reporta o erro e atualiza OVERALL_HEALTH
        return
    fi

    # 1. Verificar se o README foi gerado pelo script de documentação
    if ! grep -q "Este README foi gerado automaticamente" "$readme_file"; then
        fail "❌ README.md: Não parece ter sido gerado dinamicamente."
        report_issue "FAIL" "Documentation" "README.md não foi gerado pelo script" "Use a opção 'Gerar README.md' no manager.sh"
        OVERALL_HEALTH=false
        return
    fi

    # 2. Verificar se o README está desatualizado em relação aos scripts do projeto
    local readme_mtime
    readme_mtime=$(stat -c %Y "$readme_file")
    
    # Encontrar o script .sh modificado mais recentemente no projeto
    local latest_script_mtime
    latest_script_mtime=$(find "$PROJECT_ROOT" -name "*.sh" -printf '%T@\n' | sort -nr | head -1 | cut -d. -f1)

    if [ "$latest_script_mtime" -gt "$readme_mtime" ]; then
        local last_mod_script
        last_mod_script=$(find "$PROJECT_ROOT" -name "*.sh" -printf '%T@ %p\n' | sort -nr | head -1 | awk '{print $2}')
        last_mod_script=$(realpath --relative-to="$PROJECT_ROOT" "$last_mod_script")

        fail "❌ README.md: Desatualizado. O script '$last_mod_script' foi modificado mais recentemente."
        report_issue "FAIL" "Documentation" "README.md está desatualizado" "Use a opção 'Gerar README.md' no manager.sh"
        OVERALL_HEALTH=false
    else
        success "✅ README.md: Atualizado e sincronizado com os scripts do projeto."
    fi
}

# Função para imprimir o relatório final em formato de tabela
print_summary_report() {
    if [ ${#ISSUES_FOUND[@]} -eq 0 ]; then
        return
    fi

    section "Relatório de Problemas Encontrados"
    
    # Print table header
    printf "%-25s | %-15s | %-45s | %s\n" "Componente" "Status" "Problema Detectado" "Sugestão de Correção"
    printf "%s\n" "--------------------------|-----------------|-----------------------------------------------|--------------------------------------------------"

    # Print table rows
    for issue in "${ISSUES_FOUND[@]}"; do
        IFS='|' read -r type component problem suggestion <<< "$issue"
        [ "$type" = "FAIL" ] && color="$RED" || color="$YELLOW"
        printf "%-25s | ${color}%-15s${NC} | %-45s | %s\n" "$component" "$type" "$problem" "$suggestion"
    done
}

# Função principal
main() {
    echo -e "${BLUE}=== VERIFICAÇÃO DE SAÚDE - CLUSTER AI (VERSÃO APRIMORADA) ===${NC}"
    echo "Log: $LOG_FILE"
    exec > >(tee -a "$LOG_FILE") 2>&1

    # Verificações básicas do sistema
    echo -e "\n${CYAN}1. VERIFICAÇÕES DO SISTEMA${NC}"
    check_command "docker" "Docker"
    check_command "python3" "Python 3"
    check_command "pip" "PIP"
    check_command "git" "Git"
    check_command "curl" "cURL"

    # Verificar serviços
    echo -e "\n${CYAN}2. VERIFICAÇÃO DE SERVIÇOS${NC}"
    check_service "docker" "Serviço Docker"
    check_monitor_service

    # Verificar Ollama
    echo -e "\n${BLUE}3. VERIFICAÇÃO DO OLLAMA${NC}"
    check_ollama

    # Verificar Dask
    echo -e "\n${CYAN}4. VERIFICAÇÃO DO DASK${NC}"
    check_dask

    # Verificar conectividade dos workers remotos
    echo -e "\n${BLUE}5. VERIFICAÇÃO DOS WORKERS REMOTOS${NC}"
    check_remote_dask_connectivity

    # Verificar containers Docker
    echo -e "\n${BLUE}5. VERIFICAÇÃO DE CONTAINERS DOCKER${NC}"
    check_docker_containers

    # Verificar GPU
    echo -e "\n${CYAN}6. VERIFICAÇÃO DE GPU${NC}"
    check_gpu

    # Verificar PyTorch
    echo -e "\n${BLUE}7. VERIFICAÇÃO DO PyTorch${NC}"
    check_pytorch

    # Verificar ambiente virtual
    echo -e "\n${BLUE}8. VERIFICAÇÃO DO AMBIENTE VIRTUAL${NC}"
    check_venv

    # Verificar ambiente de desenvolvimento
    echo -e "\n${CYAN}9. AMBIENTE DE DESENVOLVIMENTO (IDEs)${NC}"
    check_vscode_extensions

    # Verificar recursos
    echo -e "\n${BLUE}10. RECURSOS DO SISTEMA${NC}"
    check_resources

    # Verificar diretórios importantes
    echo -e "\n${CYAN}11. ESTRUTURA DE DIRETÓRIOS${NC}"
    check_directory "$HOME/venv" "Diretório do ambiente virtual"
    check_directory "$HOME/cluster_scripts" "Diretório de scripts do cluster"
    check_directory "$HOME/.ollama" "Diretório do Ollama"
    check_directory ".venv" "Diretório .venv do projeto"

    # Verificar documentação
    echo -e "\n${BLUE}12. DOCUMENTAÇÃO DO PROJETO${NC}"
    check_readme_freshness

    # Imprimir tabela de problemas
    print_summary_report

    # Resumo final
    echo -e "\n${BLUE}=== RESUMO DA SAÚDE DO SISTEMA ===${NC}"

    if [ "$OVERALL_HEALTH" = true ]; then
        echo -e "${GREEN}🎉 SISTEMA SAUDÁVEL!${NC}"
        echo "Todos os componentes essenciais estão funcionando corretamente."
    else
        echo -e "${YELLOW}⚠️  SISTEMA COM PROBLEMAS${NC}"
        echo "Alguns componentes necessitam de atenção."
        echo "Consulte o log completo: $LOG_FILE"
    fi

    echo -e "\n${BLUE}📋 RECOMENDAÇÕES:${NC}"
    if ! command_exists nvidia-smi && ! [ -d "/opt/rocm" ]; then
        echo "- Instalar drivers GPU para melhor performance"
    fi

    if [ ! -d "$HOME/venv" ]; then
        echo "- Configurar ambiente virtual: ./scripts/installation/venv_setup.sh"
    fi

    if ! service_active docker; then
        echo "- Iniciar serviço Docker: sudo systemctl start docker"
    fi

    echo -e "\n${GREEN}🚀 Use './scripts/validation/run_complete_test_modified.sh' para teste completo${NC}"
}

# Executar
main "$@"
