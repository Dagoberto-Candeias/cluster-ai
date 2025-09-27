#!/bin/bash
# =============================================================================
# Verificador de Saúde e Diagnóstico do Cluster AI
# =============================================================================
# Este script centraliza as funções de status, diagnóstico e visualização de logs.
# É chamado pelo 'manager.sh'.
#
# Autor: Cluster AI Team
# Versão: 1.0.0
# =============================================================================

set -euo pipefail

# Navega para o diretório raiz do projeto para garantir que os caminhos relativos funcionem
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PID_DIR="${PROJECT_ROOT}/.pids"
cd "$PROJECT_ROOT"

# Carregar funções comuns
# shellcheck source=../lib/common.sh
source "scripts/lib/common.sh"

# =============================================================================
# FUNÇÕES DE VERIFICAÇÃO DE SAÚDE
# =============================================================================

# Verificar saúde do Ollama
check_ollama_health() {
    section "VERIFICANDO SAÚDE DO OLLAMA"

    if ! command_exists ollama; then
        error "Ollama não está instalado"
        return 1
    fi

    # Verificar se Ollama está respondendo
    if ! curl -s "http://127.0.0.1:11434/api/tags" >/dev/null 2>&1; then
        error "Ollama não está respondendo na porta 11434"
        return 1
    fi

    success "Ollama está respondendo"

    # Verificar modelos instalados
    local models
    models=$(ollama list 2>/dev/null | wc -l)
    if [ "$models" -gt 1 ]; then
        info "Modelos instalados: $((models - 1))"
    else
        warn "Nenhum modelo instalado"
    fi

    # Verificar versão
    local version
    version=$(ollama --version 2>/dev/null || echo "Unknown")
    info "Versão do Ollama: $version"

    return 0
}

# Verificar saúde dos workers
check_workers_health() {
    section "VERIFICANDO SAÚDE DOS WORKERS"

    local worker_config="${PROJECT_ROOT}/cluster.yaml"
    if [ ! -f "$worker_config" ]; then
        warn "Arquivo de configuração de workers não encontrado: $worker_config"
        return 1
    fi

    if ! command_exists yq; then
        error "yq não encontrado. Não é possível verificar workers."
        return 1
    fi

    local workers
    mapfile -t workers < <(yq e '.workers | keys | .[]' "$worker_config" 2>/dev/null || echo "")

    if [ ${#workers[@]} -eq 0 ]; then
        warn "Nenhum worker configurado"
        return 0
    fi

    local healthy_workers=0
    local total_workers=${#workers[@]}

    echo -e "${CYAN}Verificando ${total_workers} workers...${NC}"

    for worker in "${workers[@]}"; do
        echo -n "Worker $worker: "

        local worker_info
        worker_info=$(yq e ".workers[\"$worker\"]" "$worker_config")
        local host user port
        host=$(echo "$worker_info" | yq e '.host' -)
        user=$(echo "$worker_info" | yq e '.user' -)
        port=$(echo "$worker_info" | yq e '.port' -)

        # Testar conectividade SSH
        if ssh -o ConnectTimeout=5 -o BatchMode=yes -p "$port" "$user@$host" "echo 'OK'" >/dev/null 2>&1; then
            # Verificar se Dask está rodando
            if ssh -p "$port" "$user@$host" "pgrep -f dask" >/dev/null 2>&1; then
                echo -e "${GREEN}HEALTHY${NC} (Dask running)"
                ((healthy_workers++))
            else
                echo -e "${YELLOW}REACHABLE${NC} (SSH OK, Dask not running)"
            fi
        else
            echo -e "${RED}UNREACHABLE${NC} (SSH failed)"
        fi
    done

    echo
    echo -e "Workers saudáveis: ${healthy_workers}/${total_workers}"

    if [ "$healthy_workers" -eq "$total_workers" ]; then
        success "Todos os workers estão saudáveis"
        return 0
    else
        warn "Alguns workers têm problemas"
        return 1
    fi
}

# Executar benchmarks de performance
run_performance_benchmarks() {
    section "EXECUTANDO BENCHMARKS DE PERFORMANCE"

    local benchmark_results="${PROJECT_ROOT}/logs/benchmark_$(date +%Y%m%d_%H%M%S).log"

    echo -e "${CYAN}Resultados serão salvos em: $benchmark_results${NC}"
    echo "Resultados dos Benchmarks - $(date)" > "$benchmark_results"

    # Benchmark de CPU
    echo -e "\n${CYAN}=== CPU BENCHMARK ===${NC}" | tee -a "$benchmark_results"
    local cpu_score
    if command_exists sysbench; then
        cpu_score=$(sysbench cpu --cpu-max-prime=10000 run 2>/dev/null | grep "events per second" | awk '{print $4}' || echo "N/A")
        echo "CPU Score: $cpu_score events/sec" | tee -a "$benchmark_results"
    else
        echo "Sysbench não encontrado. Pulando benchmark de CPU." | tee -a "$benchmark_results"
    fi

    # Benchmark de memória
    echo -e "\n${CYAN}=== MEMORY BENCHMARK ===${NC}" | tee -a "$benchmark_results"
    local mem_score
    if command_exists sysbench; then
        mem_score=$(sysbench memory run 2>/dev/null | grep "transferred" | awk '{print $4, $5}' || echo "N/A")
        echo "Memory Score: $mem_score" | tee -a "$benchmark_results"
    else
        echo "Sysbench não encontrado. Pulando benchmark de memória." | tee -a "$benchmark_results"
    fi

    # Benchmark de disco
    echo -e "\n${CYAN}=== DISK BENCHMARK ===${NC}" | tee -a "$benchmark_results"
    local disk_score
    disk_score=$(dd if=/dev/zero of=/tmp/benchmark_test bs=1M count=100 2>&1 | tail -1 | awk '{print $8, $9}' || echo "N/A")
    echo "Disk Write Speed: $disk_score" | tee -a "$benchmark_results"
    rm -f /tmp/benchmark_test

    # Benchmark de rede (se disponível)
    echo -e "\n${CYAN}=== NETWORK BENCHMARK ===${NC}" | tee -a "$benchmark_results"
    if command_exists iperf3; then
        # Teste simples de loopback
        timeout 10 iperf3 -c 127.0.0.1 -t 5 2>/dev/null | grep "sender" | tail -1 | awk '{print "Network: " $7, $8}' >> "$benchmark_results" || echo "Network benchmark failed" >> "$benchmark_results"
    else
        echo "iperf3 não encontrado. Pulando benchmark de rede." | tee -a "$benchmark_results"
    fi

    # Benchmark do Ollama (se disponível)
    echo -e "\n${CYAN}=== OLLAMA BENCHMARK ===${NC}" | tee -a "$benchmark_results"
    if command_exists ollama && curl -s "http://127.0.0.1:11434/api/tags" >/dev/null 2>&1; then
        local models
        models=$(ollama list 2>/dev/null | awk 'NR>1 {print $1}' | head -1)
        if [ -n "$models" ]; then
            local model=${models[0]}
            echo "Testando modelo: $model" | tee -a "$benchmark_results"

            # Medir tempo de resposta
            local start_time end_time response_time
            start_time=$(date +%s.%3N)
            timeout 30 ollama run "$model" "Hello, how are you?" --format json 2>/dev/null | head -1 >/dev/null
            end_time=$(date +%s.%3N)
            response_time=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "N/A")
            echo "Response time: ${response_time}s" | tee -a "$benchmark_results"
        else
            echo "Nenhum modelo disponível para benchmark." | tee -a "$benchmark_results"
        fi
    else
        echo "Ollama não disponível. Pulando benchmark do Ollama." | tee -a "$benchmark_results"
    fi

    success "Benchmarks concluídos. Resultados salvos em: $benchmark_results"
}

# Verificar latência dos workers
check_worker_latency() {
    section "VERIFICANDO LATÊNCIA DOS WORKERS"

    local worker_config="${PROJECT_ROOT}/cluster.yaml"
    if [ ! -f "$worker_config" ]; then
        warn "Arquivo de configuração de workers não encontrado: $worker_config"
        return 1
    fi

    if ! command_exists yq; then
        error "yq não encontrado. Não é possível verificar latência."
        return 1
    fi

    local workers
    mapfile -t workers < <(yq e '.workers | keys | .[]' "$worker_config" 2>/dev/null || echo "")

    if [ ${#workers[@]} -eq 0 ]; then
        warn "Nenhum worker configurado"
        return 0
    fi

    echo -e "${CYAN}Testando latência de ${#workers[@]} workers...${NC}"
    echo -e "${BOLD}Worker\t\tLatency${NC}"

    for worker in "${workers[@]}"; do
        local worker_info
        worker_info=$(yq e ".workers[\"$worker\"]" "$worker_config")
        local host user port
        host=$(echo "$worker_info" | yq e '.host' -)
        user=$(echo "$worker_info" | yq e '.user' -)
        port=$(echo "$worker_info" | yq e '.port' -)

        # Medir latência SSH
        local latency
        latency=$(ssh -o ConnectTimeout=10 -p "$port" "$user@$host" "echo 'pong'" 2>/dev/null | wc -c || echo "0")

        if [ "$latency" -gt 0 ]; then
            # Medir tempo de resposta mais preciso
            local start_time end_time response_time
            start_time=$(date +%s%N)
            ssh -o ConnectTimeout=5 -p "$port" "$user@$host" "echo 'test'" >/dev/null 2>&1
            end_time=$(date +%s%N)
            response_time=$(( (end_time - start_time) / 1000000 )) # em ms

            printf "%-15s %dms\n" "$worker" "$response_time"
        else
            printf "%-15s %s\n" "$worker" "UNREACHABLE"
        fi
    done
}

show_detailed_status() {
    section "STATUS DETALHADO DO CLUSTER AI"

    echo -e "${CYAN}=== DASK SERVICES ==="${NC}
    local dask_pid_file="${PID_DIR}/dask_cluster.pid"
    if [ -f "$dask_pid_file" ] && ps -p "$(cat "$dask_pid_file")" > /dev/null; then
        echo -e "${GREEN}✓${NC} Dask Cluster (Scheduler + Workers): Rodando (PID: $(cat "$dask_pid_file"))"
    else
        echo -e "${RED}✗${NC} Dask Cluster: Parado"
        # Limpa o arquivo de PID se o processo não estiver rodando
        [ -f "$dask_pid_file" ] && rm -f "$dask_pid_file"
    fi

    echo -e "\n${CYAN}=== WEB SERVICES ==="${NC}
    # Assumindo que web_server.sh cria um .web_server_pid na raiz do projeto
    local web_pid_file="${PROJECT_ROOT}/.web_server_pid"
    if [ -f "$web_pid_file" ] && ps -p "$(cat "$web_pid_file")" > /dev/null; then
        echo -e "${GREEN}✓${NC} Web Server: Rodando (PID: $(cat "$web_pid_file"))"
    else
        echo -e "${RED}✗${NC} Web Server: Parado"
        [ -f "$web_pid_file" ] && rm -f "$web_pid_file"
    fi

    echo -e "\n${CYAN}=== SYSTEM STATUS ==="${NC}
    echo -e "Uptime: $(uptime -p)"
    echo -e "Memory: $(free -h | awk 'NR==2{printf "%.1f%%", $3/$2 * 100.0}')"
    echo -e "Disk: $(df -h . | tail -1 | awk '{print $5}')"
}

show_diagnostics() {
    section "DIAGNÓSTICO DO SISTEMA"

    echo -e "${CYAN}=== SYSTEM INFO ==="${NC}
    echo -e "OS: $(detect_os)"
    echo -e "Distro: $(detect_linux_distro)"
    echo -e "Architecture: $(detect_arch)"
    echo -e "Kernel: $(uname -r)"

    echo -e "\n${CYAN}=== HARDWARE ==="${NC}
    echo -e "CPU: $(nproc) cores"
    echo -e "Memory: $(free -h | awk 'NR==2{printf "%.1fGB/%s", $3/1024, $2}')"
    echo -e "Disk: $(df -h . | tail -1 | awk '{print $3"/"$2" ("$5" usado)"}')"

    echo -e "\n${CYAN}=== NETWORK ==="${NC}
    echo -e "Public IP: $(get_public_ip)"
    echo -e "Local IP: $(hostname -I | awk '{print $1}')"

    echo -e "\n${CYAN}=== SERVICES ==="${NC}
    show_detailed_status
}

view_system_logs() {
    section "VISUALIZANDO LOGS DO SISTEMA"

    if [ -f "logs/cluster_ai.log" ]; then
        echo -e "${CYAN}=== ÚLTIMAS 20 LINHAS DO LOG PRINCIPAL ==="${NC}
        tail -20 logs/cluster_ai.log
    else
        warn "Log principal não encontrado"
    fi

    if [ -f "logs/dask_scheduler.log" ]; then
        echo -e "\n${CYAN}=== ÚLTIMAS 10 LINHAS DO LOG DO SCHEDULER ==="${NC}
        tail -10 logs/dask_scheduler.log
    fi
}

show_health_help() {
    echo "Uso: $0 [comando]"
    echo
    echo "Comandos de verificação de saúde:"
    echo "  status        - Mostra o status detalhado dos serviços."
    echo "  diag          - Executa um diagnóstico completo do sistema."
    echo "  logs          - Exibe os logs recentes do sistema."
    echo "  ollama        - Verifica a saúde do serviço Ollama."
    echo "  workers       - Verifica a saúde de todos os workers."
    echo "  benchmark     - Executa benchmarks de performance do sistema."
    echo "  latency       - Verifica latência de conexão com workers."
}

# =============================================================================
# PONTO DE ENTRADA DO SCRIPT
# =============================================================================
case "${1:-help}" in
    status) show_detailed_status ;;
    diag) show_diagnostics ;;
    logs) view_system_logs ;;
    ollama) check_ollama_health ;;
    workers) check_workers_health ;;
    benchmark) run_performance_benchmarks ;;
    latency) check_worker_latency ;;
    *)
      show_health_help
      exit 1
      ;;
esac
