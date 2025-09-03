#!/bin/bash
# Verificador de Recursos para Cluster AI
# Garante que o sistema tenha recursos suficientes antes da instalacao

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Requisitos minimos
MIN_CPU_CORES=2
MIN_MEMORY=4000  # 4GB em MB
MIN_DISK_SPACE=20000  # 20GB em MB
RECOMMENDED_MEMORY=8000  # 8GB em MB
RECOMMENDED_DISK=50000   # 50GB em MB

log() {
    echo -e "${GREEN}[RESOURCE CHECKER]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[RESOURCE CHECKER]${NC} $1"
}

error() {
    echo -e "${RED}[RESOURCE CHECKER]${NC} $1"
}

# Funcao para verificar se um comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Funcao para verificar CPU
check_cpu() {
    local cpu_cores=$(nproc)
    cpu_cores=${cpu_cores:-0}  # Garantir que nao seja vazio
    log "Nucleos de CPU detectados: $cpu_cores"
    
    if [ "$cpu_cores" -lt "$MIN_CPU_CORES" ]; then
        error "CPU insuficiente: Minimo $MIN_CPU_CORES nucleos requeridos (encontrado: $cpu_cores)"
        return 1
    elif [ "$cpu_cores" -eq "$MIN_CPU_CORES" ]; then
        warn "CPU no minimo requerido: $cpu_cores nucleos. Performance pode ser limitada."
        return 0
    else
        log "✓ CPU adequada: $cpu_cores nucleos"
        return 0
    fi
}

# Funcao para verificar memoria
check_memory() {
    # Usar LC_ALL=C para garantir saida em ingles
    local total_memory=$(LC_ALL=C free -m | awk '/^Mem:/{print $2}')
    total_memory=${total_memory:-0}  # Garantir que nao seja vazio
    
    log "Memoria RAM total: ${total_memory}MB"
    
    if [ "$total_memory" -lt "$MIN_MEMORY" ]; then
        error "Memoria RAM insuficiente: Minimo ${MIN_MEMORY}MB requerido (encontrado: ${total_memory}MB)"
        return 1
    elif [ "$total_memory" -lt "$RECOMMENDED_MEMORY" ]; then
        warn "Memoria RAM abaixo do recomendado: Recomendado ${RECOMMENDED_MEMORY}MB (encontrado: ${total_memory}MB)"
        warn "Alguns modelos Ollama podem nao funcionar adequadamente."
        return 0
    else
        log "✓ Memoria RAM adequada: ${total_memory}MB"
        return 0
    fi
}

# Funcao para verificar espaco em disco
check_disk_space() {
    local disk_space=$(df -m / | awk 'NR==2{print $4}')
    disk_space=${disk_space:-0}  # Garantir que nao seja vazio
    log "Espaco livre em disco: ${disk_space}MB"
    
    if [ "$disk_space" -lt "$MIN_DISK_SPACE" ]; then
        error "Espaco em disco insuficiente: Minimo ${MIN_DISK_SPACE}MB requerido (encontrado: ${disk_space}MB)"
        return 1
    elif [ "$disk_space" -lt "$RECOMMENDED_DISK" ]; then
        warn "Espaco em disco abaixo do recomendado: Recomendado ${RECOMMENDED_DISK}MB (encontrado: ${disk_space}MB)"
        warn "Limite de modelos Ollama pode ser necessario."
        return 0
    else
        log "✓ Espaco em disco adequado: ${disk_space}MB"
        return 0
    fi
}

# Funcao para verificar tipo de disco
check_disk_type() {
    local disk_type=$(lsblk -d -o rota | awk 'NR==2{print $1}')
    
    if [ "$disk_type" = "0" ]; then
        log "✓ Tipo de disco: SSD (Performance ideal)"
    elif [ "$disk_type" = "1" ]; then
        warn "Tipo de disco: HDD (Performance pode ser limitada, especialmente para swap)"
    else
        warn "Tipo de disco: Desconhecido (Assume-se HDD para configuracoes conservadoras)"
    fi
}

# Funcao para verificar suporte a virtualizacao
check_virtualization() {
    if grep -E -q '(vmx|svm)' /proc/cpuinfo; then
        log "✓ Virtualizacao habilitada no CPU"
    else
        warn "Virtualizacao nao detectada no CPU (pode afetar containers e virtualizacao)"
    fi
}

# Funcao para verificar GPU
check_gpu() {
    local has_nvidia=$(lspci | grep -i nvidia | wc -l)
    local has_amd=$(lspci | grep -i 'amd/ati' | wc -l)
    
    has_nvidia=${has_nvidia:-0}
    has_amd=${has_amd:-0}
    
    if [ "$has_nvidia" -gt 0 ]; then
        log "✓ GPU NVIDIA detectada (Aceleracao CUDA disponivel)"
        # Verificar drivers NVIDIA
        if command_exists nvidia-smi; then
            local gpu_memory=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
            gpu_memory=${gpu_memory:-0}
            log "  Memoria GPU: ${gpu_memory}MB"
        else
            warn "GPU NVIDIA detectada mas drivers nao instalados"
        fi
    elif [ "$has_amd" -gt 0 ]; then
        log "✓ GPU AMD detectada (Suporte ROCm disponivel)"
    else
        warn "GPU dedicada nao detectada (Usando CPU para processamento)"
    fi
}

# Funcao para verificar conectividade de rede
check_network() {
    # Verificar todas as interfaces de rede ativas
    local active_interfaces=()
    local interfaces=$(ip -o link show | awk -F': ' '{print $2}')
    
    for interface in $interfaces; do
        # Ignorar interfaces loopback e docker
        if [[ "$interface" != "lo" && ! "$interface" =~ ^docker ]] && ip link show "$interface" | grep -q "state UP"; then
            active_interfaces+=("$interface")
            log "✓ Interface de rede ativa: $interface"
            
            # Verificar se tem endereço IP
            local ip_addr=$(ip -4 addr show "$interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
            if [ -n "$ip_addr" ]; then
                log "  Endereço IP: $ip_addr"
            fi
            
            # Verificar velocidade se disponível
            local speed=$(cat "/sys/class/net/$interface/speed" 2>/dev/null || echo "desconhecida")
            if [ "$speed" != "desconhecida" ] && [ "$speed" -gt 0 ]; then
                log "  Velocidade: ${speed}Mbps"
                if [ "$speed" -lt 100 ]; then
                    warn "  Rede lenta na interface $interface (pode afetar performance)"
                fi
            fi
        fi
    done
    
    # Verificar conectividade de internet
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
        log "✓ Conectividade de internet OK"
        log "✓ Múltiplas interfaces podem ser utilizadas simultaneamente"
    else
        warn "Sem conectividade de internet (download de modelos será afetado)"
        warn "Verifique se pelo menos uma interface tem acesso à internet"
    fi
    
    # Verificar se há múltiplas interfaces ativas
    if [ "${#active_interfaces[@]}" -gt 1 ]; then
        log "✓ Múltiplas interfaces ativas detectadas: ${active_interfaces[*]}"
        log "  O sistema pode utilizar Wi-Fi e Ethernet simultaneamente"
    elif [ "${#active_interfaces[@]}" -eq 1 ]; then
        log "✓ Interface ativa: ${active_interfaces[0]}"
    else
        warn "Nenhuma interface de rede ativa detectada"
    fi
}

# Funcao para calcular score de performance
calculate_performance_score() {
    local score=0
    local cpu_cores=$(nproc)
    local total_memory=$(free -m | awk '/^Mem:/{print $2}')
    local disk_space=$(df -m / | awk 'NR==2{print $4}')
    local disk_type=$(lsblk -d -o rota | awk 'NR==2{print $1}')
    
    # Garantir que as variaveis tenham valores numericos
    cpu_cores=${cpu_cores:-0}
    total_memory=${total_memory:-0}
    disk_space=${disk_space:-0}
    
    # Pontuacao baseada em CPU
    if [ "$cpu_cores" -ge 8 ]; then
        score=$((score + 30))
    elif [ "$cpu_cores" -ge 4 ]; then
        score=$((score + 20))
    else
        score=$((score + 10))
    fi
    
    # Pontuacao baseada em memoria
    if [ "$total_memory" -ge 16000 ]; then  # 16GB+
        score=$((score + 30))
    elif [ "$total_memory" -ge 8000 ]; then   # 8GB+
        score=$((score + 20))
    else
        score=$((score + 10))
    fi
    
    # Pontuacao baseada em disco
    if [ "$disk_type" = "0" ]; then  # SSD
        score=$((score + 20))
    else  # HDD
        score=$((score + 10))
    fi
    
    # Pontuacao baseada em espaco livre
    if [ "$disk_space" -ge 50000 ]; then  # 50GB+
        score=$((score + 20))
    elif [ "$disk_space" -ge 20000 ]; then  # 20GB+
        score=$((score + 15))
    else
        score=$((score + 5))
    fi
    
    echo $score
}

# Funcao para recomendar configuracao
recommend_configuration() {
    local score=$(calculate_performance_score)
    local cpu_cores=$(nproc)
    local total_memory=$(free -m | awk '/^Mem:/{print $2}')
    
    # Garantir que as variaveis tenham valores numericos
    cpu_cores=${cpu_cores:-0}
    total_memory=${total_memory:-0}
    
    echo -e "\n${BLUE}=== RECOMENDACAO DE CONFIGURACAO ===${NC}"
    echo -e "Score de Performance: ${score}/100"
    
    if [ "$score" -ge 80 ]; then
        echo -e "${GREEN}Configuracao: SERVIDOR PRINCIPAL${NC}"
        echo "  - Pode hospedar todos os servicos (Scheduler, Ollama, OpenWebUI)"
        echo "  - Suporta multiplos modelos Ollama simultaneamente"
        echo "  - Ideal para processamento intensivo"
    elif [ "$score" -ge 60 ]; then
        echo -e "${YELLOW}Configuracao: ESTACAO DE TRABALHO${NC}"
        echo "  - Pode atuar como worker e ter ferramentas de desenvolvimento"
        echo "  - Suporta 1-2 modelos Ollama"
        echo "  - Bom para desenvolvimento e processamento moderado"
    else
        echo -e "${RED}Configuracao: APENAS WORKER${NC}"
        echo "  - Dedica-se apenas ao processamento distribuido"
        echo "  - Limitar a 1 modelo Ollama ou usar apenas CPU"
        echo "  - Recomendado uso conservador de recursos"
    fi
    
    echo -e "\n${CYAN}Recomendacoes Especificas:${NC}"
    
    # Recomendacoes baseadas em CPU
    if [ "$cpu_cores" -lt 4 ]; then
        echo "  - Limitar workers Dask para 2-3"
        echo "  - Usar 1 thread por worker"
    fi
    
    # Recomendacoes baseadas em memoria
    if [ "$total_memory" -lt 8000 ]; then
        echo "  - Limitar memoria por worker para 1-2GB"
        echo "  - Usar modelos Ollama menores (7B parametros)"
        echo "  - Configurar swap no SSD se disponivel"
    fi
}

# Funcao principal de verificacao
main_check() {
    echo -e "${BLUE}=== VERIFICACAO DE RECURSOS DO SISTEMA ===${NC}"
    
    local has_errors=0
    local has_warnings=0
    
    # Executar verificacoes
    echo -e "\n${CYAN}Verificando CPU...${NC}"
    if ! check_cpu; then has_errors=1; fi
    
    echo -e "\n${CYAN}Verificando Memoria...${NC}"
    if ! check_memory; then has_errors=1; fi
    
    echo -e "\n${CYAN}Verificando Disco...${NC}"
    if ! check_disk_space; then has_errors=1; fi
    
    echo -e "\n${CYAN}Verificando Tipo de Disco...${NC}"
    check_disk_type
    
    echo -e "\n${CYAN}Verificando Virtualizacao...${NC}"
    check_virtualization
    
    echo -e "\n${CYAN}Verificando GPU...${NC}"
    check_gpu
    
    echo -e "\n${CYAN}Verificando Rede...${NC}"
    check_network
    
    # Mostrar recomendacao
    recommend_configuration
    
    echo -e "\n${BLUE}=== RESULTADO DA VERIFICACAO ===${NC}"
    if [ $has_errors -eq 1 ]; then
        error "SISTEMA NAO ATENDE AOS REQUISITOS MINIMOS"
        echo "A instalacao pode falhar ou ter performance muito limitada."
        echo "Considere atualizar o hardware antes de prosseguir."
        return 1
    elif [ $has_warnings -eq 1 ] || [ $has_errors -eq 0 ]; then
        warn "Sistema atende aos requisitos minimos com algumas limitacoes"
        echo "A instalacao pode prosseguir, mas com configuracoes otimizadas."
        return 0
    else
        log "Sistema atende ou excede todos os requisitos recomendados"
        echo "Instalacao deve ter performance ideal."
        return 0
    fi
}

# Funcao para verificacao rapida (usada pelo script principal)
quick_check() {
    local cpu_cores=$(nproc)
    # Usar LC_ALL=C para garantir saida em ingles (igual a funcao check_memory)
    local total_memory=$(LC_ALL=C free -m | awk '/^Mem:/{print $2}')
    local disk_space=$(df -m / | awk 'NR==2{print $4}')
    
    # Garantir que as variaveis tenham valores numericos
    cpu_cores=${cpu_cores:-0}
    total_memory=${total_memory:-0}
    disk_space=${disk_space:-0}
    
    if [ "$cpu_cores" -ge "$MIN_CPU_CORES" ] && \
       [ "$total_memory" -ge "$MIN_MEMORY" ] && \
       [ "$disk_space" -ge "$MIN_DISK_SPACE" ]; then
        return 0
    else
        return 1
    fi
}

# Menu principal
case "$1" in
    "full")
        main_check
        ;;
    "quick")
        if quick_check; then
            log "Verificacao rapida: Sistema atende aos requisitos minimos"
            exit 0
        else
            error "Verificacao rapida: Sistema nao atende aos requisitos minimos"
            exit 1
        fi
        ;;
    *)
        echo -e "${BLUE}Uso: $0 [comando]${NC}"
        echo "Comandos:"
        echo "  full   - Verificacao completa com recomendacoes"
        echo "  quick  - Verificacao rapida apenas dos requisitos minimos"
        ;;
esac
