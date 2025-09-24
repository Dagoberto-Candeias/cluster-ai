#!/data/data/com.termux/files/usr/bin/bash
# =============================================================================
# Cluster AI - Android Worker Setup
# =============================================================================
# Script para configurar um dispositivo Android como um Worker do Cluster AI
# via Termux.
#
# Autor: Cluster AI Team
# Versão: 2.1.0
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# CONSTANTES
# -----------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
readonly LOG_DIR="${PROJECT_ROOT}/logs"
readonly CONFIG_DIR="${PROJECT_ROOT}/config"
readonly PID_DIR="$HOME/.termux/pids"
readonly BACKUP_DIR="${PROJECT_ROOT}/backups"

# Tenta carregar a biblioteca comum. Se não conseguir, usa funções de log locais.
if [ -f "${SCRIPT_DIR}/../lib/common.sh" ]; then
    # shellcheck source=../lib/common.sh
    source "${SCRIPT_DIR}/../lib/common.sh"
else
    # Fallback para funções de log se common.sh não estiver disponível
    # (útil para execução remota via curl)
fi

# -----------------------------------------------------------------------------
# CORES PARA OUTPUT (ANSI)
# -----------------------------------------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# FUNÇÕES DE LOGGING PADRONIZADAS
# -----------------------------------------------------------------------------
log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] ${SCRIPT_NAME}: $*${NC}" >&2
}

log_warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] [WARN] ${SCRIPT_NAME}: $*${NC}" >&2
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] ${SCRIPT_NAME}: $*${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] ${SCRIPT_NAME}: $*${NC}" >&2
}

# -----------------------------------------------------------------------------
# FUNÇÃO DE LOG PARA ARQUIVO
# -----------------------------------------------------------------------------
log_to_file() {
    local level="$1"
    local message="$2"
    local log_file="${LOG_DIR}/${SCRIPT_NAME%.sh}.log"

    # Criar diretório de logs se não existir
    mkdir -p "${LOG_DIR}"

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [${level}] ${SCRIPT_NAME}: ${message}" >> "${log_file}"
}

# Alias para compatibilidade com código existente
log() { log_info "$*"; }
success() { log_success "$*"; }
warn() { log_warn "$*"; }
error() { log_error "$*"; }
info() { log_info "$*"; }

section() {
    echo ""
    echo -e "${GREEN}=================================================${NC}"
    echo -e "${GREEN} $1 ${NC}"
    echo -e "${GREEN}=================================================${NC}"
}

# Função de confirmação (fallback se common.sh não estiver disponível)
if ! command -v confirm_operation >/dev/null 2>&1; then
    confirm_operation() {
        local message="${1:-Deseja continuar?}"
        while true; do
            read -p "$message [s/n]: " -r reply
            case "$reply" in
                [Ss]* ) return 0;;
                [Nn]* ) return 1;;
                * ) echo "Por favor, responda com 's' ou 'n'.";;
            esac
        done
    }
    info "Usando função de confirmação local (fallback)."
fi

stop_services() {
    section "Parando Serviços Anteriores"
    # Parar sshd
    if [ -f "${PID_DIR}/sshd.pid" ] && ps -p "$(cat "${PID_DIR}/sshd.pid")" > /dev/null; then
        info "Parando servidor SSH existente..."
        kill "$(cat "${PID_DIR}/sshd.pid")"
        rm -f "${PID_DIR}/sshd.pid"
    else
        pkill sshd || true
    fi

    # Parar dask-worker
    if [ -f "${PID_DIR}/dask-worker.pid" ] && ps -p "$(cat "${PID_DIR}/dask-worker.pid")" > /dev/null; then
        info "Parando Dask worker existente..."
        kill "$(cat "${PID_DIR}/dask-worker.pid")"
        rm -f "${PID_DIR}/dask-worker.pid"
    else
        pkill -f dask-worker || true
    fi
    success "Serviços parados."
}

start_sshd() {
    section "Configurando Servidor SSH"
    # Garante que o diretório de PIDs exista
    mkdir -p "$PID_DIR"

    # Para qualquer processo sshd antigo para evitar conflitos
    if [ -f "${PID_DIR}/sshd.pid" ]; then
        info "Parando instância antiga do sshd..."
        kill "$(cat "${PID_DIR}/sshd.pid")" 2>/dev/null || true
        rm -f "${PID_DIR}/sshd.pid"
    fi
    pkill sshd || true

    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        log "Gerando chave SSH para o dispositivo..."
        ssh-keygen -t rsa -b 4096 -N "" -f "$HOME/.ssh/id_rsa"
    fi

    log "Iniciando o servidor SSH na porta 8022..."
    sshd
    echo $! > "${PID_DIR}/sshd.pid"

    local user; user=$(whoami)
    local ip; ip=$(ip route get 1 | awk '{print $7; exit}')
    success "Servidor SSH iniciado! Conecte-se com: ssh $user@$ip -p 8022"
}

cleanup() {
    section "Limpeza do Ambiente"
    info "Esta ação removerá o projeto, dependências e configurações do worker."
    if ! confirm_operation "Deseja continuar com a limpeza?"; then
        warn "Limpeza cancelada."
        return
    fi

    stop_services

    info "Desinstalando pacotes Python (dask)..."
    pip uninstall -y dask distributed >/dev/null 2>&1 || true

    info "Desinstalando dependências do sistema (openssh, python, git...)"
    pkg uninstall -y openssh python git ncurses-utils socat jq curl >/dev/null 2>&1 || true

    info "Removendo diretório do projeto..."
    rm -rf "$HOME/Projetos/cluster-ai"

    info "Removendo chaves SSH geradas..."
    rm -f "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_rsa.pub"

    success "Limpeza concluída."
}

main() {
    section "Configurador de Worker Android para Cluster AI"

    # 1. Atualizar pacotes do Termux
    log "Atualizando pacotes do Termux..."
    pkg update -y && pkg upgrade -y

    # 2. Instalar dependências essenciais
    log "Instalando dependências: openssh, python, git, ncurses-utils, socat, jq, curl..."
    log "Isso pode levar alguns minutos..."
    pkg install -y openssh python git ncurses-utils socat jq curl

    start_sshd
    # 4. Clonar o repositório do Cluster AI
    section "Clonando o Projeto Cluster AI"
    if [ ! -d "$HOME/Projetos/cluster-ai" ]; then
        mkdir -p "$HOME/Projetos"

        # Tentar primeiro com SSH (para repositórios privados)
        log "Tentando clonar via SSH..."
        if git clone git@github.com:Dagoberto-Candeias/cluster-ai.git "$HOME/Projetos/cluster-ai"; then
            success "Projeto clonado via SSH"
        else
            warn "Falha no SSH, tentando via HTTPS..."
            # Fallback para HTTPS (público ou com token)
            if git clone https://github.com/Dagoberto-Candeias/cluster-ai.git "$HOME/Projetos/cluster-ai"; then
                success "Projeto clonado via HTTPS"
            else
                error "Falha ao clonar repositório"
                echo
                echo "🔧 SOLUÇÕES PARA REPOSITÓRIO PRIVADO:"
                echo "1. Configure sua chave SSH no GitHub:"
                echo "   - Vá em: https://github.com/settings/keys"
                echo "   - Adicione a chave pública que será exibida no final."
                echo
                echo "2. Ou use token de acesso pessoal:"
                echo "   - Crie token em: https://github.com/settings/tokens"
                echo "   - Execute: git clone https://TOKEN@github.com/Dagoberto-Candeias/cluster-ai.git"
                echo
                echo "3. Execute este script novamente após configurar a autenticação."
                exit 1
            fi
        fi
    else
        log "Projeto já existe, atualizando..."
        cd "$HOME/Projetos/cluster-ai"
        if ! git pull; then
            warn "Falha ao atualizar. Pode ser necessário configurar autenticação."
        else
            success "Projeto atualizado com sucesso."
        fi
    fi

    # 5. Sistema Plug-and-Play Aprimorado
    section "🔌 Sistema Plug-and-Play Cluster AI"

    log "Iniciando descoberta automática inteligente de servidores..."

    # Instalar dask para o worker
    log "Instalando Dask para o worker..."
    pip install "dask[distributed]"
    success "Dask instalado com sucesso"

    # Função aprimorada para detectar servidor na rede
    detect_server() {
        local server_ip=""
        local server_port="22"
        local detection_methods=("mdns" "upnp" "broadcast" "scan")

        for method in "${detection_methods[@]}"; do
            log "Tentando método de descoberta: $method"

            case $method in
                "mdns")
                    # Descoberta via mDNS/Bonjour
                    if command_exists avahi-browse; then
                        log "🔍 Procurando servidor via mDNS/Bonjour..."
                        server_ip=$(avahi-browse -t _cluster-ai._tcp 2>/dev/null | grep "IPv4" | head -1 | awk '{print $8}' | cut -d';' -f1)
                        if [ -n "$server_ip" ]; then
                            success "✅ Servidor encontrado via mDNS: $server_ip"
                            break
                        fi
                    fi
                    ;;

                "upnp")
                    # Descoberta via UPnP/SSDP
                    if command_exists curl; then
                        log "🔍 Procurando servidor via UPnP/SSDP..."
                        # Enviar M-SEARCH para descoberta UPnP
                        local upnp_response
                        upnp_response=$(timeout 5 bash -c "
                            echo -e 'M-SEARCH * HTTP/1.1\r\nHOST: 239.255.255.250:1900\r\nMAN: \"ssdp:discover\"\r\nMX: 2\r\nST: urn:cluster-ai:service:manager:1\r\n\r\n' | \
                            socat - UDP4-DATAGRAM:239.255.255.250:1900,bind=0.0.0.0:0 2>/dev/null | \
                            grep 'cluster-ai' | head -1 | grep -oE 'LOCATION: http://[^:]+:[0-9]+' | cut -d'/' -f3 | cut -d':' -f1
                        " 2>/dev/null)

                        if [ -n "$upnp_response" ]; then
                            server_ip="$upnp_response"
                            success "✅ Servidor encontrado via UPnP: $server_ip"
                            break
                        fi
                    fi
                    ;;

                "broadcast")
                    # Broadcast UDP personalizado
                    log "🔍 Enviando broadcast UDP para descoberta..."
                    local broadcast_ip
                    broadcast_ip=$(echo "$ip" | awk -F. '{print $1"."$2"."$3".255"}')

                    # Enviar pacote de descoberta personalizado
                    local broadcast_response
                    broadcast_response=$(timeout 5 bash -c "
                        echo 'CLUSTER_AI_DISCOVERY_REQUEST' | \
                        socat - UDP4-DATAGRAM:$broadcast_ip:9999,bind=0.0.0.0:9998 2>/dev/null | \
                        grep 'CLUSTER_AI_SERVER_RESPONSE' | head -1 | cut -d' ' -f2
                    " 2>/dev/null)

                    if [ -n "$broadcast_response" ]; then
                        server_ip="$broadcast_response"
                        success "✅ Servidor encontrado via broadcast: $server_ip"
                        break
                    fi
                    ;;

                "scan")
                    # Escaneamento inteligente da rede local
                    local network_prefix
                    network_prefix=$(echo "$ip" | cut -d'.' -f1-3)

                    log "🔍 Escaneando rede local ($network_prefix.0/24) por servidores..."
                    info "Isso pode levar alguns segundos..."

                    # Escanear portas comuns onde servidores podem estar
                    local common_ports=("22" "8022" "80" "443")
                    local scan_progress=0

                    for i in {1..254}; do
                        local test_ip="${network_prefix}.${i}"
                        if [ "$test_ip" != "$ip" ]; then
                            # Mostrar progresso a cada 50 IPs
                            ((scan_progress++))
                            if (( scan_progress % 50 == 0 )); then
                                log "Progresso: $scan_progress/254 IPs escaneados..."
                            fi

                            # Testar portas comuns
                            for port in "${common_ports[@]}"; do
                                if timeout 1 bash -c "echo >/dev/tcp/$test_ip/$port" 2>/dev/null; then
                                    # Verificar se é um servidor do cluster-ai (usando usuário 'dcm' e não 'root')
                                    # O caminho do manager.sh também foi corrigido
                                    if ssh -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=no "dcm@$test_ip" "test -f /home/dcm/Projetos/cluster-ai/manager.sh" 2>/dev/null; then
                                        server_ip="$test_ip"
                                        success "✅ Servidor Cluster AI encontrado em $server_ip na porta $port"
                                        break 3
                                    fi
                                fi
                            done
                        fi
                    done
                    ;;
            esac
        done

        if [ -n "$server_ip" ]; then
            echo "$server_ip"
            return 0
        else
            warn "❌ Nenhum servidor Cluster AI encontrado na rede"
            return 1
        fi
    }

    # Função para copiar a chave SSH para o servidor
    copy_ssh_key_to_server() {
        local server_ip="$1"
        local server_user="$2"

        if ! command -v ssh-copy-id >/dev/null 2>&1; then
            warn "Comando 'ssh-copy-id' não encontrado. Pulando cópia automática da chave."
            warn "Você precisará registrar o worker manualmente."
            return 1
        fi

        info "Tentando copiar a chave SSH para o servidor $server_ip..."
        info "Você precisará digitar a senha do usuário '${server_user}' no servidor UMA ÚNICA VEZ."
        if ssh-copy-id -p 22 "${server_user}@${server_ip}"; then
            success "Chave SSH copiada com sucesso para o servidor!"
            return 0
        fi
    }

    # Função aprimorada para coletar informações do dispositivo Android
    collect_device_info() {
        local device_info="{}"

        # Informações básicas do dispositivo
        local device_model=""
        local android_version=""
        local battery_level=""
        local cpu_cores=""
        local ram_total=""
        local storage_total=""

        # Tentar obter informações do dispositivo
        if command_exists getprop; then
            device_model=$(getprop ro.product.model 2>/dev/null || echo "Android Device")
            android_version=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
        else
            device_model="Android Device"
            android_version="Unknown"
        fi

        # Informações de bateria (se disponível)
        if [ -f "/sys/class/power_supply/battery/capacity" ]; then
            battery_level=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null || echo "Unknown")
        else
            battery_level="Unknown"
        fi

        # Informações de hardware
        cpu_cores=$(nproc 2>/dev/null || echo "Unknown")
        ram_total=$(free -h 2>/dev/null | awk 'NR==2{print $2}' || echo "Unknown")
        storage_total=$(df -h "$HOME" 2>/dev/null | awk 'NR==2{print $2}' || echo "Unknown")

        # Criar JSON com informações do dispositivo
        device_info=$(cat << EOF
{
    "device_model": "$device_model",
    "android_version": "$android_version",
    "battery_level": "$battery_level",
    "cpu_cores": "$cpu_cores",
    "ram_total": "$ram_total",
    "storage_total": "$storage_total",
    "termux_version": "$(termux-info 2>/dev/null | grep -o 'termux-version=[^,]*' | cut -d'=' -f2 || echo 'Unknown')"
}
EOF
        )

        echo "$device_info"
    }

    # Função para determinar capacidades do worker baseado no hardware
    determine_worker_capabilities() {
        local device_info="$1"
        local capabilities="{}"

        # Extrair informações do JSON (simplificado)
        local cpu_cores=$(echo "$device_info" | grep -o '"cpu_cores": "[^"]*"' | cut -d'"' -f4)
        local ram_total=$(echo "$device_info" | grep -o '"ram_total": "[^"]*"' | cut -d'"' -f4)
        local battery_level=$(echo "$device_info" | grep -o '"battery_level": "[^"]*"' | cut -d'"' -f4)

        # Determinar capacidades baseado no hardware
        local max_concurrent_tasks=1
        local preferred_task_types=("light" "text-generation")
        local can_handle_heavy_tasks=false
        local battery_optimization=true

        # Lógica de determinação de capacidades
        if [[ "$cpu_cores" =~ ^[0-9]+$ ]] && [ "$cpu_cores" -ge 4 ]; then
            max_concurrent_tasks=2
            preferred_task_types=("text-generation" "code-analysis")
        fi

        if [[ "$ram_total" =~ ^[0-9]+ ]]; then
            local ram_gb=$(echo "$ram_total" | sed 's/[^0-9]//g')
            if [ "$ram_gb" -ge 4 ]; then
                max_concurrent_tasks=3
                can_handle_heavy_tasks=true
                preferred_task_types=("text-generation" "code-analysis" "image-processing")
            fi
        fi

        # Otimização para bateria
        if [[ "$battery_level" =~ ^[0-9]+$ ]] && [ "$battery_level" -lt 30 ]; then
            max_concurrent_tasks=1
            battery_optimization=true
            preferred_task_types=("light")
        fi

        # Criar JSON de capacidades
        capabilities=$(cat << EOF
{
    "max_concurrent_tasks": $max_concurrent_tasks,
    "preferred_task_types": $(printf '%s\n' "${preferred_task_types[@]}" | jq -R . | jq -s . 2>/dev/null || echo '["light", "text-generation"]'),
    "can_handle_heavy_tasks": $can_handle_heavy_tasks,
    "battery_optimization": $battery_optimization,
    "network_optimization": true,
    "auto_sleep_when_idle": true
}
EOF
        )

        echo "$capabilities"
    }

    # Função aprimorada para registrar worker no servidor
    register_worker() {
        local server_ip="$1"
        local worker_name="android-$(hostname)-$(date +%s | tail -c 5)"
        local worker_ip="$ip"
        local worker_user="$user"
        local worker_port="8022"
        local pub_key
        pub_key=$(cat "$HOME/.ssh/id_rsa.pub")

        log "🔧 Coletando informações do dispositivo..."
        local device_info
        device_info=$(collect_device_info)

        log "🧠 Determinando capacidades do worker..."
        local capabilities
        capabilities=$(determine_worker_capabilities "$device_info")

        log "📝 Registrando worker inteligente no servidor $server_ip..."

        # Criar arquivo de registro avançado
        local reg_file="/tmp/worker_registration_${worker_name}.json"
        # Usar printf para maior robustez com JSON e evitar problemas de expansão
        printf '{\n' > "$reg_file"
        printf '    "worker_name": "%s",\n' "$worker_name" >> "$reg_file"
        printf '    "worker_ip": "%s",\n' "$worker_ip" >> "$reg_file"
        printf '    "worker_user": "%s",\n' "$worker_user" >> "$reg_file"
        printf '    "worker_port": "%s",\n' "$worker_port" >> "$reg_file"
        # A chave pública pode conter caracteres especiais, melhor formatar
        printf '    "public_key": "%s",\n' "$(echo "$pub_key" | sed 's/"/\\"/g')" >> "$reg_file"
        printf '    "device_info": %s,\n' "$device_info" >> "$reg_file"
        printf '    "capabilities": %s,\n' "$capabilities" >> "$reg_file"
        printf '    "registration_type": "zero-touch-android",\n' >> "$reg_file"
        printf '    "auto_discovered": true,\n' >> "$reg_file"
        printf '    "timestamp": %s,\n' "$(date +%s)" >> "$reg_file"
        printf '    "version": "2.0"\n' >> "$reg_file"
        printf '}\n' >> "$reg_file"

        local server_user="dcm" # Use a dedicated user on the server for registration

        # Tenta copiar a chave SSH primeiro para automatizar o login
        if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "${server_user}@${server_ip}" "echo 'OK'" >/dev/null 2>&1; then
            log "🔑 Copiando chave SSH para o servidor..."
            if ! copy_ssh_key_to_server "$server_ip" "$server_user"; then
                warn "❌ Falha ao copiar chave SSH. Registro manual necessário."
                return 1
            fi
        fi

        # Enviar registro via SCP
        log "📤 Enviando dados de registro para o servidor..."
        if scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$reg_file" "${server_user}@${server_ip}:/tmp/"; then
            # Executar script de registro inteligente no servidor
            local registration_result
            registration_result=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${server_user}@${server_ip}" "
                if [ -f /opt/cluster-ai/scripts/management/worker_registration.sh ]; then
                    bash /opt/cluster-ai/scripts/management/worker_registration.sh /tmp/worker_registration_${worker_name}.json
                    echo 'SUCCESS'
                else
                    echo 'REGISTRATION_SCRIPT_NOT_FOUND'
                fi
            " 2>/dev/null)
            # Limpeza do arquivo de registro no servidor, independentemente do resultado
            ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "${server_user}@${server_ip}" "rm -f /tmp/worker_registration_${worker_name}.json" 2>/dev/null

            if [[ "$registration_result" == "SUCCESS" ]]; then
                success "✅ Worker registrado com sucesso no servidor!"
                success "🎯 Capacidades detectadas automaticamente e configuradas"

                # Iniciar o worker Dask
                log "🚀 Iniciando worker Dask..."
                nohup dask-worker "$server_ip":8786 --nthreads 1 --memory-limit 1GB --name "android-$(hostname)" > "${LOG_DIR}/dask-worker.log" 2>&1 &
                echo $! > "${PID_DIR}/dask-worker.pid"
                success "✅ Worker Dask iniciado em background! Log em ${LOG_DIR}/dask-worker.log"

                return 0
            else
                warn "⚠️ Falha no registro automático (script de registro pode não ter sido encontrado no servidor). Você pode registrar manualmente."
                return 1
            fi
        else
            warn "❌ Não foi possível conectar ao servidor para registro automático."
            return 1
        fi

        # Limpar arquivo temporário local
        rm -f "$reg_file"
    }

    # Tentar detecção e registro automático
    if server_ip=$(detect_server); then
        if register_worker "$server_ip"; then
            success "✅ Worker registrado e iniciado automaticamente!"
            info "O servidor agora pode se conectar a este worker."
        else
            warn "⚠️  Registro automático falhou, mas o worker está configurado."
        fi
    else
        warn "⚠️  Nenhum servidor detectado automaticamente."
    fi

    section "Configuração Concluída!"
    success "Seu dispositivo Android está pronto para ser usado como um worker."
    echo
    info "Informações do worker:"
    echo -e "   • ${YELLOW}Nome:${NC} android-$(hostname)"
    echo -e "   • ${YELLOW}IP:${NC} $ip"
    echo -e "   • ${YELLOW}Usuário:${NC} $user"
    echo -e "   • ${YELLOW}Porta SSH:${NC} 8022"
    echo
    echo -e "${YELLOW}Chave SSH pública (copie para registrar manualmente):${NC}"
    echo "--------------------------------------------------"
    cat "$HOME/.ssh/id_rsa.pub"
    echo "--------------------------------------------------"
    echo
    if [ -n "$server_ip" ]; then
        info "✅ Registrado automaticamente no servidor: $server_ip"
    else
        info "Para registrar manualmente no servidor:"
        echo "1. Execute no servidor: ./manager.sh"
        echo "2. Escolha 'worker' > 'add' (ou use o menu interativo)"
        echo "3. Adicione o worker com as informações acima"
    fi
}

# Function to optimize battery usage
optimize_battery_usage() {
    log "Otimizando uso de bateria para worker Android..."

    # Disable unnecessary services
    if command_exists termux-wake-lock; then
        termux-wake-lock
        success "Wake lock ativado para manter o dispositivo acordado"
    fi

    # Set CPU governor to powersave when idle
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
        echo "powersave" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
        success "Governor de CPU configurado para economia de energia"
    fi

    # Disable animations and effects
    settings put system animator_duration_scale 0.5 2>/dev/null || true
    settings put system transition_animation_scale 0.5 2>/dev/null || true
    settings put system window_animation_scale 0.5 2>/dev/null || true

    success "Otimização de bateria aplicada"
}

show_help() {
    echo "Uso: $0 [comando]"
    echo
    echo "Comandos:"
    echo -e "  ${GREEN}install${NC}   - (Padrão) Instala e configura o worker."
    echo -e "  ${GREEN}stop${NC}      - Para os serviços do worker (sshd, dask-worker)."
    echo -e "  ${GREEN}start${NC}     - Inicia os serviços do worker."
    echo -e "  ${GREEN}restart${NC}   - Reinicia os serviços do worker."
    echo -e "  ${YELLOW}cleanup${NC}   - Desinstala o worker, removendo projeto, dependências e configurações."
    echo -e "  ${GREEN}help${NC}      - Mostra esta ajuda."
}


# Ponto de entrada principal
case "${1:-install}" in
    install)
        main
        ;;
    stop)
        stop_services
        ;;
    start)
        start_sshd
        # Adicionar lógica para iniciar dask-worker se necessário
        ;;
    restart)
        stop_services
        start_sshd
        # Adicionar lógica para iniciar dask-worker se necessário
        ;;
    cleanup)
        cleanup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Comando inválido: $1"
        show_help
        exit 1
        ;;
esac
            " 2>/dev/null)

            if [[ "$registration_result" == "SUCCESS" ]]; then
                success "✅ Worker registrado com sucesso no servidor!"
                success "🎯 Capacidades detectadas automaticamente e configuradas"

                # Iniciar o worker Dask
                log "🚀 Iniciando worker Dask..."
                nohup dask-worker "$server_ip":8786 --nthreads 1 --memory-limit 1GB --name "android-$(hostname)" >/dev/null 2>&1 &
                success "✅ Worker Dask iniciado em background!"

                return 0
            else
                warn "⚠️ Falha no registro automático. Você pode registrar manualmente."
                return 1
            fi
        else
            warn "❌ Não foi possível conectar ao servidor para registro automático."
            return 1
        fi

        # Limpar arquivo temporário
        rm -f "$reg_file"
    }

    # Tentar detecção e registro automático
    if server_ip=$(detect_server); then
        if register_worker "$server_ip"; then
            success "✅ Worker registrado automaticamente!"
            info "O servidor agora pode se conectar a este worker automaticamente."
        else
            warn "⚠️  Registro automático falhou, mas o worker está configurado."
        fi
    else
        warn "⚠️  Nenhum servidor detectado automaticamente."
    fi

    section "Configuração Concluída!"
    success "Seu dispositivo Android está pronto para ser usado como um worker."
    echo
    info "Informações do worker:"
    echo -e "   • ${YELLOW}Nome:${NC} android-$(hostname)"
    echo -e "   • ${YELLOW}IP:${NC} $ip"
    echo -e "   • ${YELLOW}Usuário:${NC} $user"
    echo -e "   • ${YELLOW}Porta SSH:${NC} 8022"
    echo
    echo -e "${YELLOW}Chave SSH pública:${NC}"
    echo "--------------------------------------------------"
    cat "$HOME/.ssh/id_rsa.pub"
    echo "--------------------------------------------------"
    echo
    if [ -n "$server_ip" ]; then
        info "✅ Registrado automaticamente no servidor: $server_ip"
    else
        info "Para registrar manualmente no servidor:"
        echo "1. Execute no servidor: ./manager.sh"
        echo "2. Escolha 'Configurar Cluster' > 'Gerenciar Workers Remotos'"
        echo "3. Adicione o worker com as informações acima"
    fi
}

# Function to optimize battery usage
optimize_battery_usage() {
    log "Otimizando uso de bateria para worker Android..."

    # Disable unnecessary services
    if command_exists termux-wake-lock; then
        termux-wake-lock
        success "Wake lock ativado para manter o dispositivo acordado"
    fi

    # Set CPU governor to powersave when idle
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
        echo "powersave" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || true
        success "Governor de CPU configurado para economia de energia"
    fi

    # Disable animations and effects
    settings put system animator_duration_scale 0.5 2>/dev/null || true
    settings put system transition_animation_scale 0.5 2>/dev/null || true
    settings put system window_animation_scale 0.5 2>/dev/null || true

    success "Otimização de bateria aplicada"
}

main
