#!/bin/bash
# Worker avançado para Android - Cluster AI

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
SERVER_IP="$1"
MACHINE_NAME="android-$(getprop ro.product.model 2>/dev/null | tr ' ' '-' | tr -d '\n' || echo "unknown")"
MAX_RETRIES=20
RETRY_DELAY=30
LOG_FILE="$HOME/worker_$(date +%Y%m%d_%H%M%S).log"

# Funções de log
log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${GREEN}$message${NC}"
    echo "$message" >> "$LOG_FILE"
}

error() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1"
    echo -e "${RED}$message${NC}"
    echo "$message" >> "$LOG_FILE"
}

warn() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] WARN: $1"
    echo -e "${YELLOW}$message${NC}"
    echo "$message" >> "$LOG_FILE"
}

# Verificar se Termux está instalado
check_termux() {
    if ! command -v termux-setup-storage >/dev/null 2>&1; then
        error "Termux não está instalado. Instale da F-Droid: https://f-droid.org/en/packages/com.termux/"
        exit 1
    fi
    log "Termux verificado ✓"
}

# Verificar argumentos
check_arguments() {
    if [ -z "$SERVER_IP" ]; then
        error "Uso: $0 <IP_DO_SERVIDOR>"
        echo "Exemplo: $0 192.168.1.100"
        exit 1
    fi
    
    # Validar formato do IP
    if ! [[ $SERVER_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        error "IP inválido: $SERVER_IP"
        exit 1
    fi
    
    log "Servidor alvo: $SERVER_IP"
    log "Nome da máquina: $MACHINE_NAME"
}

# Instalar dependências
install_dependencies() {
    log "Instalando dependências..."
    
    # Atualizar pacotes
    pkg update -y && pkg upgrade -y
    
    # Instalar pacotes essenciais
    pkg install -y \
        python \
        git \
        curl \
        proot \
        net-tools \
        termux-api
    
    # Instalar Python packages
    pip install --upgrade pip
    pip install \
        dask \
        distributed \
        numpy \
        pandas \
        psutil
    
    log "Dependências instaladas ✓"
}

# Verificar conexão com servidor
check_connection() {
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if ping -c 1 -W 2 "$SERVER_IP" >/dev/null 2>&1; then
            if nc -z -w 5 "$SERVER_IP" 8786; then
                log "Conexão estabelecida com $SERVER_IP:8786 ✓"
                return 0
            else
                warn "Servidor alcançável mas porta 8786 não respondendo"
            fi
        else
            warn "Servidor $SERVER_IP não alcançável"
        fi
        
        retry_count=$((retry_count + 1))
        log "Tentativa $retry_count/$MAX_RETRIES - Próxima em ${RETRY_DELAY}s..."
        sleep $RETRY_DELAY
    done
    
    error "Não foi possível conectar ao servidor após $MAX_RETRIES tentativas"
    return 1
}

# Verificar status da bateria
check_battery() {
    if command -v termux-battery-status >/dev/null 2>&1; then
        local battery_status=$(termux-battery-status 2>/dev/null)
        local battery_level=$(echo "$battery_status" | grep -o '"percentage": [0-9]*' | cut -d' ' -f2)
        local charging=$(echo "$battery_status" | grep -o '"status": "[^"]*"' | cut -d'"' -f4)
        
        if [ "$charging" != "CHARGING" ] && [ "${battery_level:-100}" -lt 20 ]; then
            warn "Bateria baixa ($battery_level%) e não está carregando"
            read -p "Continuar mesmo assim? (s/n): " confirm
            if [ "$confirm" != "s" ] && [ "$confirm" != "S" ]; then
                exit 0
            fi
        fi
        
        if [ "$charging" = "CHARGING" ]; then
            log "Dispositivo carregando ✓ (Bateria: $battery_level%)"
        else
            warn "Dispositivo não está carregando (Bateria: $battery_level%)"
        fi
    fi
}

# Verificar temperatura (se disponível)
check_temperature() {
    if command -v termux-sensor >/dev/null 2>&1; then
        local temp=$(termux-sensor -s temperature 2>/dev/null | grep -o '"values": \[[^]]*\]' | grep -o '[0-9.]*' | head -1)
        if [ -n "$temp" ] && [ $(echo "$temp > 45" | bc -l) -eq 1 ]; then
            warn "Temperatura elevada: ${temp}°C"
        fi
    fi
}

# Configurar limites de recursos baseado no hardware
configure_resources() {
    local total_memory=$(free -m | awk '/Mem:/ {print $2}')
    local cpu_cores=$(nproc 2>/dev/null || echo 1)
    
    # Configurações conservadoras para Android
    local nworkers=$((cpu_cores > 2 ? 2 : 1))
    local nthreads=1
    local memory_limit="512MB"
    
    # Ajustar baseado na memória disponível
    if [ "$total_memory" -gt 4000 ]; then
        memory_limit="1GB"
        nworkers=2
    elif [ "$total_memory" -gt 2000 ]; then
        memory_limit="512MB"
        nworkers=1
    else
        memory_limit="256MB"
        nworkers=1
    fi
    
    log "Hardware detectado: ${cpu_cores} cores, ${total_memory}MB RAM"
    log "Configuração: $nworkers workers, $nthreads threads/worker, $memory_limit RAM"
    
    echo "$nworkers $nthreads $memory_limit"
}

# Iniciar worker
start_worker() {
    local resources=$(configure_resources)
    local nworkers=$(echo $resources | awk '{print $1}')
    local nthreads=$(echo $resources | awk '{print $2}')
    local memory_limit=$(echo $resources | awk '{print $3}')
    
    log "Iniciando worker com configuração otimizada..."
    
    # Criar diretório temporário
    mkdir -p "$HOME/tmp"
    
    # Comando do worker
    local worker_cmd="dask-worker $SERVER_IP:8786 \
        --nworkers $nworkers \
        --nthreads $nthreads \
        --name \"$MACHINE_NAME\" \
        --memory-limit \"$memory_limit\" \
        --local-directory \"$HOME/tmp\" \
        --death-timeout 60 \
        --reconnect true"
    
    log "Executando: $worker_cmd"
    
    # Executar worker
    eval $worker_cmd
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log "Worker finalizado normalmente"
    else
        error "Worker finalizado com código de erro: $exit_code"
    fi
    
    return $exit_code
}

# Função principal
main() {
    log "=== INICIANDO WORKER ANDROID CLUSTER AI ==="
    log "Log detalhado: $LOG_FILE"
    
    check_termux
    check_arguments
    check_battery
    check_temperature
    
    # Verificar se dependências estão instaladas
    if ! command -v python >/dev/null 2>&1 || ! python -c "import dask" 2>/dev/null; then
        warn "Dependências não encontradas, instalando..."
        install_dependencies
    fi
    
    # Verificar conexão
    if ! check_connection; then
        error "Não foi possível estabelecer conexão com o servidor"
        exit 1
    fi
    
    # Manter worker rodando com reinício automático
    local restart_count=0
    local max_restarts=10
    
    while [ $restart_count -lt $max_restarts ]; do
        restart_count=$((restart_count + 1))
        log "Iniciando worker (tentativa $restart_count/$max_restarts)"
        
        if start_worker; then
            log "Worker finalizado com sucesso"
            break
        else
            warn "Worker falhou, reiniciando em 10 segundos..."
            sleep 10
            
            # Verificar conexão antes de reiniciar
            if ! check_connection; then
                error "Conexão perdida, aguardando reconexão..."
                sleep 30
            fi
        fi
    done
    
    if [ $restart_count -ge $max_restarts ]; then
        error "Máximo de reinicializações atingido ($max_restarts)"
        exit 1
    fi
    
    log "Worker Android finalizado"
}

# Executar função principal
main "$@"
