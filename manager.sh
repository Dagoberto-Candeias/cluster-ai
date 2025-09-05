#!/bin/bash
# Local: manager.sh
# Autor: Nome: Dagoberto Candeias. email: betoallnet@gmail.com telefone/whatsapp: +5511951754945

# =============================================================================
# Cluster AI - Gerenciador do Cluster
# =============================================================================
# Este é o painel de controle principal do Cluster AI. Permite iniciar,
# parar, configurar e monitorar todos os componentes do sistema.

set -euo pipefail  # Modo estrito: para em erros, variáveis não definidas e falhas em pipelines

# =============================================================================
# INICIALIZAÇÃO
# =============================================================================

# Carrega funções comuns
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR" # Assumindo que manager.sh está na raiz
source "${SCRIPT_DIR}/scripts/lib/common.sh"

# Função de log adicional (se não estiver definida em common.sh)
log() {
    echo -e "${CYAN}[LOG] $1${NC}"
}

# Função para solicitar confirmação do usuário
confirm_operation() {
    local message="$1"
    read -p "$(echo -e "${YELLOW}AVISO:${NC} $message Deseja continuar? (s/N) ")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        return 0
    else
        return 1
    fi
}
# =============================================================================
# FUNÇÕES DO GERENCIADOR
# =============================================================================

# Exibe banner do gerenciador
show_banner() {
    echo
    echo -e "${CYAN}================================================================================${NC}"
    echo -e "${CYAN}                    🎛️  CLUSTER AI - GERENCIADOR 🎛️${NC}"
    echo -e "${CYAN}================================================================================${NC}"
    echo
    echo -e "${GREEN}Gerencie todos os componentes do Cluster AI em um só lugar${NC}"
    echo
}

# Inicia um processo em background, salva seu PID e log.
# Uso: start_process <nome_serviço> <arquivo_pid> <comando> <arquivo_log>
start_process() {
    local service_name="$1"
    local pid_file="$2"
    local command_to_run="$3"
    local log_file="$4"
    local venv_path="${PROJECT_ROOT}/.venv"

    # Verifica se o diretório de PID existe
    mkdir -p "$(dirname "$pid_file")"

    # Verifica se o processo já está rodando
    if [ -f "$pid_file" ] && ps -p "$(cat "$pid_file")" > /dev/null; then
        success "$service_name já está em execução (PID: $(cat "$pid_file"))."
        return 0
    fi

    progress "Iniciando $service_name..."

    # Ativa o ambiente virtual para executar o comando
    source "${venv_path}/bin/activate"

    # Executa o comando em background
    nohup ${command_to_run} > "$log_file" 2>&1 &
    local pid=$!

    # Desativa o ambiente virtual
    deactivate

    # Salva o PID
    echo "$pid" > "$pid_file"
    sleep 2 # Dá um tempo para o processo iniciar

    if ps -p "$pid" > /dev/null; then
        success "$service_name iniciado com sucesso (PID: $pid)."
    else
        error "Falha ao iniciar $service_name. Verifique o log: $log_file"
    fi
}

# =============================================================================
# FUNÇÃO UNIFICADA DE STATUS
# =============================================================================

# Função unificada para exibir o status do cluster com diferentes níveis de detalhe.
# Argumento: "simple" ou "detailed". Padrão é "simple".
display_cluster_status() {
    local mode="${1:-simple}"

    if [[ "$mode" == "detailed" ]]; then
        section "Status Detalhado do Cluster"
        # Informações do sistema
        subsection "Sistema"
        echo "📍 Diretório: $(pwd)"
        echo "👤 Usuário: $(whoami)"
        echo "🖥️  Hostname: $(hostname)"
        echo "💻 OS: $(detect_os) $(detect_linux_distro)"
        echo "🔧 CPU: $(nproc) cores"
        echo "🧠 RAM: $(free -h | awk 'NR==2{printf "%.1fGB", $2}')"
        echo
    else
        section "Status do Cluster"
    fi

    # --- Status dos Serviços (Comum a ambos os modos) ---
    if [[ "$mode" == "detailed" ]]; then
        subsection "Serviços"
    else
        echo "🔍 Verificando serviços..."
        echo
    fi

    if ! file_exists "$CONFIG_FILE"; then
        warn "Arquivo de configuração não encontrado: $CONFIG_FILE"
        info "Execute ./install.sh primeiro"
        return 1
    fi

    local DASK_SCHEDULER_PORT; DASK_SCHEDULER_PORT=$(get_config_value "dask" "scheduler_port" "$CONFIG_FILE" "8786")
    local DASK_DASHBOARD_PORT; DASK_DASHBOARD_PORT=$(get_config_value "dask" "dashboard_port" "$CONFIG_FILE" "8787")
    local OLLAMA_PORT; OLLAMA_PORT=$(get_config_value "services" "ollama_port" "$CONFIG_FILE" "11434")
    local OPENWEBUI_PORT; OPENWEBUI_PORT=$(get_config_value "services" "openwebui_port" "$CONFIG_FILE" "3000")

    # Verificações de serviço
    (command_exists docker && docker info >/dev/null 2>&1 && success "🐳 Docker: Ativo") || error "🐳 Docker: Inativo"
    (is_port_open "$DASK_SCHEDULER_PORT" && success "📊 Dask Scheduler: Ativo (porta $DASK_SCHEDULER_PORT)") || warn "📊 Dask Scheduler: Inativo"
    (is_port_open "$DASK_DASHBOARD_PORT" && success "📈 Dask Dashboard: Ativo (porta $DASK_DASHBOARD_PORT)") || warn "📈 Dask Dashboard: Inativo"
    (is_port_open "$OLLAMA_PORT" && success "🧠 Ollama: Ativo (porta $OLLAMA_PORT)") || warn "🧠 Ollama: Inativo"
    (is_port_open "$OPENWEBUI_PORT" && success "🌐 OpenWebUI: Ativo (porta $OPENWEBUI_PORT)") || warn "🌐 OpenWebUI: Inativo"
    (command_exists nginx && pgrep nginx >/dev/null && success "🌐 Nginx: Ativo") || warn "🌐 Nginx: Inativo"
    echo

    # --- Seções Detalhadas ---
    if [[ "$mode" == "detailed" ]]; then
        # Recursos do sistema
        subsection "Recursos"
        echo "📊 Uso de CPU: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
        echo "🧠 Uso de RAM: $(free | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
        echo "💾 Uso de Disco: $(df -h . | awk 'NR==2{print $5}')"

        local OLLAMA_MODELS_DIR="$HOME/.ollama"
        if dir_exists "$OLLAMA_MODELS_DIR"; then
            local ollama_size; ollama_size=$(du -sh "$OLLAMA_MODELS_DIR" | awk '{print $1}')
            echo "🧠 Espaço Ollama: $ollama_size"
        else
            echo "🧠 Espaço Ollama: (diretório não encontrado)"
        fi
        echo

        # Portas abertas
        subsection "Portas"
        if command_exists netstat; then
            netstat -tln | grep LISTEN | head -10
        elif command_exists ss; then
            ss -tln | grep LISTEN | head -10
        fi
    else
        info "Para mais detalhes, use: ./manager.sh status"
    fi
}

# Exibe status do cluster
show_status() {
    section "Status do Cluster"

    # Verifica se configuração existe
    if ! file_exists "$CONFIG_FILE"; then
        warn "Arquivo de configuração não encontrado: $CONFIG_FILE"
        info "Execute ./install.sh primeiro"
        return 1
    fi

    # Carrega configurações usando a nova função
    DASK_SCHEDULER_PORT=$(get_config_value "dask" "scheduler_port" "$CONFIG_FILE" "8786")
    DASK_DASHBOARD_PORT=$(get_config_value "dask" "dashboard_port" "$CONFIG_FILE" "8787")
    OLLAMA_PORT=$(get_config_value "services" "ollama_port" "$CONFIG_FILE" "11434")
    OPENWEBUI_PORT=$(get_config_value "services" "openwebui_port" "$CONFIG_FILE" "3000")

    info "Configurações carregadas do formato INI."

    # Status dos serviços
    echo "🔍 Verificando serviços..."
    echo

    # Docker
    if command_exists docker && docker info >/dev/null 2>&1; then
        success "🐳 Docker: Ativo"
    else
        error "🐳 Docker: Inativo"
    fi

    # Dask Scheduler
    if is_port_open "$DASK_SCHEDULER_PORT"; then
        success "📊 Dask Scheduler: Ativo (porta $DASK_SCHEDULER_PORT)"
    else
        warn "📊 Dask Scheduler: Inativo"
    fi

    # Dask Dashboard
    if is_port_open "$DASK_DASHBOARD_PORT"; then
        success "📈 Dask Dashboard: Ativo (porta $DASK_DASHBOARD_PORT)"
    else
        warn "📈 Dask Dashboard: Inativo"
    fi

    # Ollama
    if is_port_open "$OLLAMA_PORT"; then
        success "🧠 Ollama: Ativo (porta $OLLAMA_PORT)"
    else
        warn "🧠 Ollama: Inativo"
    fi

    # OpenWebUI
    if is_port_open "$OPENWEBUI_PORT"; then
        success "🌐 OpenWebUI: Ativo (porta $OPENWEBUI_PORT)"
    else
        warn "🌐 OpenWebUI: Inativo"
    fi

    # Nginx
    if command_exists nginx && pgrep nginx >/dev/null; then
        success "🌐 Nginx: Ativo"
    else
        warn "🌐 Nginx: Inativo"
    fi

    echo
    display_cluster_status "simple"
}

# Função para verificar o status de todos os workers (manuais e automáticos)
check_all_workers_status() {
    section "Verificando Status de Todos os Workers"

    local remote_workers_conf="$HOME/.cluster_config/nodes_list.conf"
    local auto_workers_conf="$HOME/.cluster_config/workers.conf"
    local total_workers=0
    local online_workers=0

    # --- Processar workers manuais ---
    if [ -f "$remote_workers_conf" ] && grep -vE '^\s*#|^\s*$' "$remote_workers_conf" | grep -q .; then
        subsection "Workers Manuais ($remote_workers_conf)"
        
        # Usar um loop while com process substitution para evitar subshell
        while IFS= read -r line; do
            local name ip user port status
            read -r name ip user port status <<< "$line"
            
            ((total_workers++))
            echo -n -e "  -> Testando ${YELLOW}$name${NC} ($user@$ip:$port)... "
            
            if ssh -o BatchMode=yes -o ConnectTimeout=5 -p "$port" "$user@$ip" "echo 'OK'" >/dev/null 2>&1; then
                echo -e "${GREEN}ONLINE${NC}"
                ((online_workers++))
                sed -i "s/^\($name $ip $user $port\).*/\1 active/" "$remote_workers_conf"
            else
                echo -e "${RED}OFFLINE${NC}"
                sed -i "s/^\($name $ip $user $port\).*/\1 inactive/" "$remote_workers_conf"
            fi
        done < <(grep -vE '^\s*#|^\s*$' "$remote_workers_conf")
    fi

    # --- Processar workers registrados automaticamente ---
    if [ -f "$auto_workers_conf" ] && grep -vE '^\s*#|^\s*$' "$auto_workers_conf" | grep -q .; then
        subsection "Workers Registrados Automaticamente ($auto_workers_conf)"
        
        while IFS= read -r line; do
            local name ip user port status timestamp
            read -r name ip user port status timestamp <<< "$line"

            ((total_workers++))
            echo -n -e "  -> Testando ${YELLOW}$name${NC} ($user@$ip:$port)... "

            if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "echo 'OK'" >/dev/null 2>&1; then
                echo -e "${GREEN}ONLINE${NC}"
                ((online_workers++))
                sed -i "s/^$name $ip $user $port .*/$name $ip $user $port active $(date +%s)/" "$auto_workers_conf"
            else
                echo -e "${RED}OFFLINE${NC}"
                sed -i "s/^$name $ip $user $port .*/$name $ip $user $port inactive $(date +%s)/" "$auto_workers_conf"
            fi
        done < <(grep -vE '^\s*#|^\s*$' "$auto_workers_conf")
    fi

    subsection "Resumo da Verificação"
    if [ $total_workers -eq 0 ]; then
        warn "Nenhum worker configurado para verificação."
    else
        success "Verificação concluída: ${GREEN}$online_workers de $total_workers${NC} workers estão online."
    fi
}

# --- Funções do Sub-menu de Informações do Sistema ---

show_general_system_info() {
    subsection "Informações Gerais do Sistema"
    local os; os=$(detect_os)
    local distro; distro=$(detect_linux_distro)
    local arch; arch=$(detect_arch)
    info "Sistema Operacional: $os"
    info "Distribuição: $distro"
    info "Arquitetura: $arch"
    info "Hostname: $(hostname)"
    info "Kernel: $(uname -r)"
    info "Diretório do Projeto: $PROJECT_ROOT"
}

show_cpu_details() {
    subsection "Detalhes da CPU"
    if command_exists lscpu; then
        lscpu | grep -E 'Architecture|CPU op-mode|CPU\(s\)|Model name|Vendor ID|CPU MHz|L1d cache|L1i cache|L2 cache|L3 cache'
    else
        warn "Comando 'lscpu' não encontrado. Mostrando informações de /proc/cpuinfo."
        grep -E 'model name|vendor_id|cpu cores|cpu MHz' /proc/cpuinfo | uniq
    fi
}

show_memory_details() {
    subsection "Detalhes da Memória"
    if command_exists free; then
        info "Uso de Memória (free -h):"
        free -h
        echo
    fi
    if command_exists vmstat; then
        info "Estatísticas de Memória Virtual (vmstat -s):"
        vmstat -s | head -n 8
    else
        warn "Comandos 'free' ou 'vmstat' não encontrados."
    fi
}

show_disk_details() {
    subsection "Detalhes do Disco"
    if command_exists df; then
        info "Uso do Sistema de Arquivos (df -hT):"
        df -hT --exclude-type=tmpfs --exclude-type=squashfs
        echo
    fi
    if command_exists lsblk; then
        info "Dispositivos de Bloco (lsblk):"
        lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
    else
         warn "Comandos 'df' ou 'lsblk' não encontrados."
    fi
}

# Sub-menu para a opção "Informações do Sistema"
show_system_info_submenu() {
    while true; do
        section "ℹ️  Informações do Sistema"
        echo "1) Informações Gerais"
        echo "2) Detalhes da CPU"
        echo "3) Detalhes da Memória"
        echo "4) Detalhes do Disco"
        echo "5) Processos com Maior Consumo"
        echo "0) Voltar ao Menu Principal"
        echo

        read -p "Digite sua opção: " choice

        case $choice in
            1) show_general_system_info ;;
            2) show_cpu_details ;;
            3) show_memory_details ;;
            4) show_disk_details ;;
            5)
                local filter_user=""
                local filter_command=""
                while true; do
                    show_top_processes "$filter_user" "$filter_command"
                    echo
                    if [ -n "$filter_user" ] || [ -n "$filter_command" ]; then
                        echo -e "${YELLOW}Filtros ativos: [Usuário: ${filter_user:-nenhum}] [Comando: ${filter_command:-nenhum}]${NC}"
                    fi
                    echo "Opções:"
                    echo "  'k' - Matar (kill) um processo"
                    echo "  'f' - Filtrar a lista"
                    echo "  'r' - Atualizar a lista"
                    echo "  'c' - Limpar filtros"
                    echo "  'q' - Voltar ao menu anterior"
                    echo
                    read -p "Digite sua opção [k/f/r/c/q]: " action

                    case $action in
                        k|K) kill_process_interactive ;;
                        f|F)
                            subsection "Filtrar Lista de Processos"
                            read -p "Filtrar por nome de usuário (deixe em branco para ignorar): " filter_user
                            read -p "Filtrar por nome de comando (deixe em branco para ignorar): " filter_command
                            info "Filtros aplicados. A lista será atualizada."
                            sleep 1
                            ;;
                        r|R)
                            info "Atualizando lista..."
                            sleep 1
                            continue
                            ;;
                        c|C)
                            if [ -n "$filter_user" ] || [ -n "$filter_command" ]; then
                                filter_user=""
                                filter_command=""
                                success "Filtros removidos."
                            else
                                info "Nenhum filtro ativo para limpar."
                            fi
                            sleep 1
                            ;;
                        q|Q) break ;;
                        *) error "Opção inválida." ;;
                    esac
                done
                ;;
            0) return ;;
            *) error "Opção inválida." ;;
        esac
        echo
        read -p "Pressione Enter para continuar..."
    done
}

# Menu principal
show_menu() {
    subsection "Menu Principal"

    echo "Escolha uma operação:"
    echo -e "\n${CYAN}🚀 OPERAÇÕES DO CLUSTER${NC}"
    echo " 1) ▶️  Iniciar Cluster"
    echo " 2) ⏹️  Parar Cluster"
    echo " 3) 🔄 Reiniciar Cluster"
    echo " ⚡) Quick Start (Ativa servidor, rede e monitor)"
    echo " 4) 📈 Status Detalhado do Cluster"
    
    echo -e "\n${YELLOW}🔧 MANUTENÇÃO & DIAGNÓSTICO${NC}"
    echo " 5) 🧹 Limpeza Geral (Logs, PIDs)"
    echo " 6) ️ Arquivar Logs (Compacta e Limpa)"
    echo " 7) 🧽 Limpar TODOS os Logs"
    echo " 8) 🩺 Verificar Status dos Workers"
    echo " 9) 📜 Visualizar Logs do Sistema"
    echo "10) 🧪 Executar Testes & Diagnóstico"
    echo "11) 🔎 Executar Linter (Qualidade do Código)"
    echo "12) ℹ️  Informações do Sistema"

    echo -e "\n${PURPLE}⚙️ CONFIGURAÇÃO & FERRAMENTAS${NC}"
    echo "13) 🧩 Instalar Dependências (openssl, pv)"
    echo "14) 💾 Backup e Restauração"
    echo "15) 🗓️  Agendar Limpeza Automática (Cron)"
    echo "16) 🔄 Atualizar Sistema (Git Pull)"
    echo "17) ⚙️  Configurar Workers (Remoto/Android)"
    echo "18) ⚡ Otimizador de Performance"
    echo "19) 💻 Gerenciador VSCode"
    echo "20) 🔒 Ferramentas de Segurança"
    echo "21) 📊 Monitor Central"
    
    echo -e "\n${BLUE}📚 AJUDA${NC}"
    echo "22) 📚 Documentação (Em desenvolvimento)"
    echo
    echo "0) ❌ Sair"
    echo
}

# Para um processo usando seu arquivo PID
# Uso: stop_process_by_pid <nome_serviço> <arquivo_pid>
stop_process_by_pid() {
    local service_name="$1"
    local pid_file="$2"

    if [ ! -f "$pid_file" ]; then
        info "$service_name não parece estar rodando (arquivo PID não encontrado)."
        return
    fi

    local pid
    pid=$(cat "$pid_file")

    if [ -z "$pid" ]; then
        warn "Arquivo PID para $service_name está vazio."
        rm -f "$pid_file"
        return
    fi

    # Verifica se o processo existe
    if ps -p "$pid" > /dev/null; then
        progress "Parando $service_name (PID: $pid)..."
        # Tenta parar de forma graciosa primeiro (SIGTERM)
        kill -15 "$pid"
        sleep 3

        # Se ainda estiver rodando, força a parada (SIGKILL)
        if ps -p "$pid" > /dev/null; then
            warn "$service_name não parou de forma graciosa. Forçando..."
            kill -9 "$pid"
            sleep 1
        fi
        success "$service_name parado."
    else
        info "$service_name (PID: $pid) já estava parado."
    fi

    rm -f "$pid_file"
}

# Inicia o cluster
start_cluster() {
    section "Iniciando Cluster AI"
    mkdir -p "${PROJECT_ROOT}/run" "${PROJECT_ROOT}/logs"

    # Verifica configuração
    if ! file_exists "$CONFIG_FILE"; then
        error "Arquivo de configuração não encontrado: $CONFIG_FILE"
        info "Execute ./install.sh primeiro"
        return 1
    fi

    # Inicia o Cluster Dask usando o script Python unificado
    # Este script gerencia o scheduler e os workers locais em um único processo.
    local dask_cmd="python3 \"${PROJECT_ROOT}/scripts/dask/start_dask_cluster.py\" \"$PROJECT_ROOT\""
    local dask_pid_file="${PROJECT_ROOT}/run/dask_cluster.pid"
    start_process "Dask Cluster" "$dask_pid_file" "$dask_cmd" "${PROJECT_ROOT}/logs/dask_cluster.log"

    # Inicia Ollama (como serviço systemd)
    progress "Verificando serviço Ollama..."
    if command_exists systemctl && sudo systemctl is-active --quiet ollama; then
        success "Ollama já está ativo."
    elif command_exists systemctl; then
        progress "Iniciando serviço Ollama..."
        sudo systemctl start ollama 2>/dev/null || warn "Falha ao iniciar serviço Ollama. Pode não estar instalado."
    fi

    # Inicia OpenWebUI (container Docker)
    progress "Verificando container OpenWebUI..."
    if command_exists docker; then
        if sudo docker ps --format '{{.Names}}' | grep -q "^open-webui$"; then
            success "Container OpenWebUI já está em execução."
        elif sudo docker ps -a --format '{{.Names}}' | grep -q "^open-webui$"; then
            progress "Iniciando container OpenWebUI parado..."
            sudo docker start open-webui
            success "Container OpenWebUI iniciado."
        else
            warn "Container OpenWebUI não encontrado. Execute 'setup_openwebui.sh' para criá-lo."
        fi
    else
        warn "Docker não encontrado. Pulando verificação do OpenWebUI."
    fi

    # Inicia Nginx
    progress "Verificando serviço Nginx..."
    if command_exists nginx && command_exists systemctl; then
        if sudo systemctl is-active --quiet nginx; then
            success "Nginx já está ativo."
        else
            progress "Iniciando Nginx..."
            sudo systemctl start nginx 2>/dev/null || true
        fi
    fi

    echo
    success "Comandos de inicialização do cluster enviados."
    echo
    show_status
}

# Para o cluster
stop_cluster() {
    section "Parando Cluster AI"

    info "Parando todos os serviços gerenciados..."

    # Para o Cluster Dask unificado
    stop_process_by_pid "Dask Cluster" "${PROJECT_ROOT}/run/dask_cluster.pid"

    # Para Ollama (serviço systemd)
    if command_exists systemctl && sudo systemctl is-active --quiet ollama; then
        progress "Parando serviço Ollama..."
        sudo systemctl stop ollama
        success "Serviço Ollama parado."
    fi

    # Para OpenWebUI (container Docker)
    if command_exists docker && sudo docker ps --format '{{.Names}}' | grep -q "^open-webui$"; then
        progress "Parando container OpenWebUI..."
        sudo docker stop open-webui
        success "Container OpenWebUI parado."
    fi

    # Para Nginx
    if command_exists nginx && pgrep nginx >/dev/null; then
        progress "Parando Nginx..."
        sudo systemctl stop nginx 2>/dev/null || true
        success "Nginx parado"
    fi

    echo
    success "Cluster parado com sucesso!"
    echo
    show_status
}

# Reinicia o cluster
restart_cluster() {
    section "Reiniciando Cluster AI"

    stop_cluster
    sleep 2
    start_cluster
}

# Inicialização rápida (Quick Start)
quick_start_cluster() {
    section "🚀 Inicialização Rápida do Cluster AI"

    local ACTIVATE_SCRIPT="${PROJECT_ROOT}/scripts/deployment/activate_server.sh"
    local NETWORK_SCRIPT="${PROJECT_ROOT}/scripts/management/network_discovery.sh"
    local SETUP_MONITOR_SCRIPT="${PROJECT_ROOT}/scripts/deployment/setup_monitor_service.sh"

    # Passo 1: Ativar servidor
    subsection "Passo 1: Ativando Servidor"
    if [ -f "$ACTIVATE_SCRIPT" ]; then
        progress "Executando ativação do servidor..."
        bash "$ACTIVATE_SCRIPT"
    else
        error "Script de ativação não encontrado: $ACTIVATE_SCRIPT"
        return 1
    fi

    echo
    sleep 2

    # Passo 2: Descobrir nós
    subsection "Passo 2: Descobrindo Nós na Rede"
    if [ -f "$NETWORK_SCRIPT" ]; then
        progress "Executando descoberta de rede..."
        bash "$NETWORK_SCRIPT" auto
    else
        error "Script de descoberta não encontrado: $NETWORK_SCRIPT"
        return 1
    fi

    echo
    sleep 2

    # Passo 3: Configurar monitoramento
    subsection "Passo 3: Configurando Monitoramento Contínuo"
    if [ -f "$SETUP_MONITOR_SCRIPT" ]; then
        progress "Configurando serviço de monitoramento em background..."
        info "Será solicitada a senha de superusuário (sudo) para instalar o serviço."
        sudo bash "$SETUP_MONITOR_SCRIPT"
    fi
}

# Mostra status detalhado
show_detailed_status() {
    display_cluster_status "detailed"
}

# Executa testes
run_tests() {
    section "Executando Testes"

    if ! file_exists "scripts/validation/run_tests.sh"; then
        error "Script de testes não encontrado: scripts/validation/run_tests.sh"
        return 1
    fi

    progress "Executando suíte de testes..."
    bash scripts/validation/run_tests.sh
}

# Mostra diagnóstico
show_diagnostics() {
    section "Diagnóstico do Sistema"

    subsection "Verificações Básicas"

    # Python
    if command_exists python3; then
        success "Python 3: $(python3 --version)"
    else
        error "Python 3: Não encontrado"
    fi

    # Pip
    if command_exists pip; then
        success "Pip: $(pip --version | cut -d' ' -f1-2)"
    else
        error "Pip: Não encontrado"
    fi

    # Docker
    if command_exists docker; then
        success "Docker: $(docker --version)"
    else
        error "Docker: Não encontrado"
    fi

    # Ambiente virtual
    if dir_exists ".venv"; then
        success "Ambiente Virtual: OK"
    else
        warn "Ambiente Virtual: Não encontrado"
    fi

    # Configuração
    if file_exists "$CONFIG_FILE"; then
        success "Configuração: OK"
    else
        error "Configuração: Não encontrada"
    fi

    echo
    subsection "Recomendações"

    if ! dir_exists ".venv"; then
        info "• Execute ./install.sh para configurar o ambiente"
    fi

    if ! file_exists "$CONFIG_FILE"; then
        info "• Execute ./install.sh para criar a configuração"
    fi

    if ! command_exists docker; then
        info "• Instale Docker para funcionalidades completas"
    fi
}

# Mostra ajuda
show_help() {
    section "Ajuda do Gerenciador"

    echo "Uso: ./manager.sh [comando]"
    echo
    echo "Comandos disponíveis:"
    echo "  start      - Inicia todos os serviços do cluster"
    echo "  stop       - Para todos os serviços do cluster"
    echo "  restart    - Reinicia todos os serviços do cluster"
    echo "  status     - Mostra status detalhado do cluster"
    echo "  test       - Executa testes do sistema"
    echo "  quick-start - Ativa servidor, descobre nós e configura monitoramento"
    echo "  diag       - Mostra diagnóstico do sistema"
    echo "  logs       - Visualiza logs do sistema"
    echo "  monitor    - Sistema de monitoramento central"
    echo "  optimize   - Otimizador de performance"
    echo "  vscode     - Gerenciador VSCode"
    echo "  update     - Atualização automática"
    echo "  security   - Ferramentas de segurança"
    echo "  help       - Mostra esta ajuda"
    echo
    echo "Exemplos:"
    echo "  ./manager.sh start"
    echo "  ./manager.sh monitor dashboard"
    echo "  ./manager.sh optimize"
    echo "  ./manager.sh vscode status"
    echo
}

# Sistema de monitoramento central
start_monitor() {
    section "Sistema de Monitoramento Central"

    local monitor_script="${SCRIPT_DIR}/scripts/monitoring/central_monitor.sh"

    if ! file_exists "$monitor_script"; then
        error "Script de monitoramento não encontrado: $monitor_script"
        return 1
    fi

    info "Iniciando sistema de monitoramento..."
    bash "$monitor_script" "$@"
}

# Otimizador de performance
run_optimizer() {
    section "Otimizador de Performance"

    local optimizer_script="${SCRIPT_DIR}/scripts/optimization/performance_optimizer.sh"

    if ! file_exists "$optimizer_script"; then
        error "Script otimizador não encontrado: $optimizer_script"
        return 1
    fi

    info "Executando otimizações de performance..."
    bash "$optimizer_script"
}

# Gerenciador VSCode
manage_vscode() {
    section "Gerenciador VSCode"

    local vscode_script="${SCRIPT_DIR}/scripts/maintenance/vscode_manager.sh"

    if ! file_exists "$vscode_script"; then
        error "Script VSCode não encontrado: $vscode_script"
        return 1
    fi

    info "Iniciando gerenciador VSCode..."
    bash "$vscode_script" "$@"
}

# Atualização automática
run_updater() {
    section "Atualização Automática"

    local updater_script="${SCRIPT_DIR}/scripts/maintenance/auto_updater.sh"

    if ! file_exists "$updater_script"; then
        error "Script de atualização não encontrado: $updater_script"
        return 1
    fi

    info "Iniciando atualização automática..."
    bash "$updater_script"
}

# Ferramentas de segurança
manage_security() {
    section "Ferramentas de Segurança"

    echo "Ferramentas de Segurança Disponíveis:"
    echo "1) Gerenciador de Autenticação"
    echo "2) Gerenciador de Firewall"
    echo "3) Logger de Segurança"
    echo "0) Voltar"
    echo

    read -p "Digite sua opção: " option

    case $option in
        1)
            local auth_script="${SCRIPT_DIR}/scripts/security/auth_manager.sh"
            if file_exists "$auth_script"; then
                bash "$auth_script" "$@"
            else
                error "Script de autenticação não encontrado"
            fi
            ;;
        2)
            local firewall_script="${SCRIPT_DIR}/scripts/security/firewall_manager.sh"
            if file_exists "$firewall_script"; then
                bash "$firewall_script" "$@"
            else
                error "Script de firewall não encontrado"
            fi
            ;;
        3)
            local logger_script="${SCRIPT_DIR}/scripts/security/security_logger.sh"
            if file_exists "$logger_script"; then
                bash "$logger_script" "$@"
            else
                error "Script de logger não encontrado"
            fi
            ;;
        0)
            return
            ;;
        *)
            error "Opção inválida"
            ;;
    esac
}

# Executa o linter de qualidade de código
run_linter() {
    section "🔎 Verificador de Qualidade de Código (Linter)"

    local linter_script="${SCRIPT_DIR}/scripts/maintenance/run_linter.sh"

    if ! file_exists "$linter_script"; then
        error "Script do linter não encontrado: $linter_script"
        return 1
    fi

    info "Executando o linter para Shell e Python..."
    bash "$linter_script"
}

# Gerencia backups e restaurações
manage_backup_restore() {
    section "💾 Gerenciador de Backup e Restauração"
    local verify_script="${SCRIPT_DIR}/scripts/maintenance/verify_backup.sh"
    local backup_script="${SCRIPT_DIR}/scripts/maintenance/backup_manager.sh"
    local restore_script="${SCRIPT_DIR}/scripts/maintenance/restore_manager.sh"

    if ! file_exists "$backup_script" || ! file_exists "$restore_script"; then
        error "Scripts de backup/restauração não encontrados."
        info "Verifique em 'scripts/maintenance/'"
        return 1
    fi

    while true; do
        subsection "Menu de Backup e Restauração"
        echo "1) Realizar um novo Backup"
        echo "2) Restaurar de um Backup"
        echo "3) Listar Backups existentes"
        echo "4) Limpar Backups antigos"
        echo "5) Verificar Integridade de um Backup"
        echo "0) Voltar ao menu principal"
        echo

        read -p "Digite sua opção: " choice

        case $choice in
            1)
                subsection "Tipo de Backup"
                echo "1) Backup Completo (config, modelos, docker)"
                echo "2) Apenas Configurações"
                echo "3) Apenas Modelos Ollama"
                echo "4) Apenas Dados Docker"
                echo "0) Cancelar"
                read -p "Escolha o tipo de backup: " backup_type_choice
                local backup_type=""
                case $backup_type_choice in
                    1) backup_type="full" ;;
                    2) backup_type="config" ;;
                    3) backup_type="models" ;;
                    4) backup_type="docker-data" ;;
                    0) continue ;;
                    *) error "Opção inválida."; continue ;;
                esac
                bash "$backup_script" "$backup_type"

                local encrypt_arg=""
                if confirm_operation "Deseja criptografar este backup com uma senha?"; then
                    encrypt_arg="--encrypt"
                fi
                bash "$backup_script" "$backup_type" "$encrypt_arg"
                ;;
            2)
                bash "$restore_script"
                ;;
            3)
                bash "$backup_script" list
                ;;
            4)
                bash "$backup_script" cleanup
                ;;
            5)
                bash "$verify_script"
                ;;
            0) return ;;
            *) error "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}
# =============================================================================
# FUNÇÕES DE PROCESSAMENTO DO MENU
# =============================================================================

# Processa a escolha do usuário no menu interativo
process_menu_choice() {
    local choice="$1"

    case $choice in
        1) start_cluster ;;
        2) stop_cluster ;;
        3) restart_cluster ;; # Corrigido para chamar a função correta
        "⚡") quick_start_cluster ;;
        4) show_detailed_status ;;
        5) run_cleanup ;; # Limpeza geral
        6) archive_logs ;;
        7) clear_all_logs ;;
        8) check_all_workers_status ;;
        9) view_system_logs ;;
        10) run_tests ;;
        11) run_linter ;;
        12) show_system_info_submenu ;;
        13) install_dependencies ;;
        14) manage_backup_restore ;;
        15) setup_cron_job ;;
        16) run_updater ;;
        17) configure_cluster ;;
        18) run_optimizer ;;
        19) manage_vscode ;;
        20) manage_security ;;
        21) start_monitor ;;
        22) warn "Documentação - Em desenvolvimento" ;;
        0)
            info "Gerenciador encerrado"
            return 1 # Sinaliza para sair do loop
            ;;
    esac
    return 0 # Sinaliza para continuar no loop
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Análise de argumentos para modos especiais como --quiet
    if [[ "${1:-}" == "--quiet" || "${1:-}" == "-q" ]]; then
        # Redefine as funções de log para suprimir a saída, exceto erros.
        # A função 'error' de common.sh continuará a funcionar pois não é sobrescrita.
        info() { :; }
        log() { :; }
        success() { :; }
        warn() { :; }
        progress() { :; }
        section() { :; }
        subsection() { :; }
        show_banner() { :; }

        # Remove a flag para que o resto do script não a processe
        shift
    fi

    # Processa argumentos da linha de comando
    case "${1:-}" in
        start)
            start_cluster
            exit 0
            ;;
        stop)
            stop_cluster
            exit 0
            ;;
        restart)
            restart_cluster
            exit 0
            ;;
        quick-start|quickstart)
            quick_start_cluster
            exit 0
            ;;
        status|--status)
            show_detailed_status
            exit 0
            ;;
        check-workers|workers-status)
            check_all_workers_status
            exit 0
            ;;
        test)
            run_tests
            exit 0
            ;;
        diag)
            show_diagnostics
            exit 0
            ;;
        monitor)
            shift
            start_monitor "$@"
            exit 0
            ;;
        optimize)
            run_optimizer
            exit 0
            ;;
        vscode)
            shift
            manage_vscode "$@"
            exit 0
            ;;
        update)
            run_updater
            exit 0
            ;;
        lint|linter)
            run_linter
            exit 0
            ;;
        security)
            manage_security
            exit 0
            ;;
        cleanup)
            shift # remove 'cleanup'
            run_cleanup
            exit 0
            ;;
        cleanup-logs)
            clear_all_logs
            exit 0
            ;;
        archive-logs)
            shift # remove 'archive-logs'
            archive_logs "$@"
            exit 0
            ;;
        setup-cron)
            # Renamed to manage_cron_jobs internally
            setup_cron_job
            exit 0
            ;;
        backup)
            manage_backup_restore
            exit 0
            ;;
        logs)
            view_system_logs
            exit 0
            ;;
        help|--help|-h)
            show_help
            exit 0
            ;;
    esac

    # Menu interativo
    while true; do
        show_banner
        display_cluster_status "simple"
        show_menu

        read -p "Digite sua opção (0-22): " choice

        # Validação da entrada: deve ser um número ou '⚡'
        if [[ ! "$choice" =~ ^([0-9]|1[0-9]|2[0-2]|⚡)$ ]]; then
            error "Opção inválida. Por favor, digite um número de 0 a 22 ou '⚡'."
            sleep 2
        else
            # Processa a escolha e verifica se deve sair
            if ! process_menu_choice "$choice"; then
                exit 0
            fi
        fi

        # Pausa para o usuário ver a saída, a menos que a opção seja sair
        if [[ "$choice" != "0" ]]; then
            echo
            read -p "Pressione Enter para continuar..."
        fi

        # Limpa a tela para a próxima iteração, exceto ao sair
        if [[ "$choice" != "0" ]]; then
            clear
        fi
    done
}

# Instala dependências essenciais como openssl e pv
install_dependencies() {
    section "🧩 Verificador e Instalador de Dependências"

    local deps_to_check=("openssl" "pv")
    local missing_deps=()

    subsection "Verificando dependências..."
    for dep in "${deps_to_check[@]}"; do
        if ! command_exists "$dep"; then
            warn "Dependência não encontrada: $dep"
            missing_deps+=("$dep")
        else
            success "Dependência encontrada: $dep"
        fi
    done

    if [ ${#missing_deps[@]} -eq 0 ]; then
        success "Todas as dependências essenciais já estão instaladas."
        return 0
    fi

    info "As seguintes dependências estão faltando: ${missing_deps[*]}"
    if ! confirm_operation "Deseja tentar instalá-las agora?"; then
        warn "Instalação cancelada."
        return 1
    fi

    local pm; pm=$(detect_package_manager)
    if [ -z "$pm" ]; then
        error "Não foi possível detectar o gerenciador de pacotes do seu sistema."
        info "Por favor, instale as dependências manualmente: sudo <pm> install ${missing_deps[*]}"
        return 1
    fi

    log "Usando '$pm' para instalar..."
    if sudo "$pm" install -y "${missing_deps[@]}"; then
        success "Dependências instaladas com sucesso!"
    else
        error "Falha ao instalar uma ou mais dependências."
        info "Tente instalar manualmente: sudo $pm install -y ${missing_deps[*]}"
        return 1
    fi
}

# Limpa um arquivo de log específico
clear_specific_log() {
    subsection "Limpar Log Específico"
    echo "Qual log você deseja limpar (esvaziar)?"
    echo "1) Log de Ativação do Servidor (server_activation.log)"
    echo "2) Log do Cluster Dask (dask_cluster.log)"
    echo "3) Log de Limpeza Automática (cron_cleanup.log)"
    echo "0) Cancelar"
    echo

    read -p "Digite sua opção: " clear_choice

    local log_to_clear=""
    case $clear_choice in
        1) log_to_clear="${PROJECT_ROOT}/logs/server_activation.log" ;;
        2) log_to_clear="${PROJECT_ROOT}/logs/dask_cluster.log" ;;
        3) log_to_clear="${PROJECT_ROOT}/logs/cron_cleanup.log" ;;
        0) return ;;
        *) error "Opção inválida."; return 1 ;;
    esac

    if [ ! -f "$log_to_clear" ]; then
        error "Arquivo de log não encontrado: $log_to_clear"
        return 1
    fi

    warn "Esta ação irá esvaziar o conteúdo de '$(basename "$log_to_clear")'."
    warn "O arquivo não será removido, apenas seu conteúdo."
    if confirm_operation "Você tem certeza?"; then
        > "$log_to_clear"
        success "Log '$(basename "$log_to_clear")' foi limpo com sucesso."
    else
        info "Operação de limpeza cancelada."
    fi
}

# Agenda a limpeza automática de logs usando cron
# Agora é um menu para gerenciar todas as tarefas agendadas
setup_cron_job() {
    if ! command_exists crontab; then
        error "Comando 'crontab' não encontrado. Não é possível agendar tarefas."
        info "Instale o cliente cron do seu sistema (ex: sudo apt install cron)."
        return 1
    fi

    while true; do
        section "🗓️ Gerenciador de Tarefas Agendadas (Cron)"
        echo "1) Agendar Arquivamento Semanal de Logs (Recomendado)"
        echo "2) Agendar Limpeza Semanal de Logs"
        echo "3) Remover Tarefa Agendada"
        echo "4) Ver Tarefas Agendadas do Cluster AI"
        echo "0) Voltar"
        echo
        read -p "Digite sua opção: " choice

        case $choice in
            1)
                local archive_cmd="cd \"${PROJECT_ROOT}\" && ./manager.sh archive-logs --force >> \"${PROJECT_ROOT}/logs/cron_cleanup.log\" 2>&1"
                local archive_schedule="0 3 * * 0" # Domingo às 3h
                add_cron_job "Arquivamento Semanal de Logs" "$archive_cmd" "$archive_schedule"
                ;;
            2)
                local cleanup_cmd="cd \"${PROJECT_ROOT}\" && ./manager.sh cleanup-logs --force >> \"${PROJECT_ROOT}/logs/cron_cleanup.log\" 2>&1"
                local cleanup_schedule="0 4 * * 0" # Domingo às 4h
                add_cron_job "Limpeza Semanal de Logs" "$cleanup_cmd" "$cleanup_schedule"
                ;;
            3)
                remove_cron_job
                ;;
            4)
                view_cron_jobs
                ;;
            0) return ;;
            *) error "Opção inválida." ;;
        esac
        read -p "Pressione Enter para continuar..."
    done
}

# Função auxiliar para adicionar uma tarefa ao cron
add_cron_job() {
    local job_name="$1"
    local cron_command="$2"
    local cron_schedule="$3"
    local cron_job="${cron_schedule} ${cron_command}"

    subsection "Agendando: $job_name"

    if crontab -l 2>/dev/null | grep -qF -- "$cron_command"; then
        success "A tarefa '$job_name' já está agendada."
        return
    fi

    if ! confirm_operation "Deseja adicionar a tarefa '$job_name' ao seu agendador?"; then
        info "Agendamento cancelado."
        return
    fi

    (crontab -l 2>/dev/null; echo "# Tarefa do Cluster AI: $job_name"; echo "$cron_job") | crontab -

    if crontab -l | grep -qF -- "$cron_command"; then
        success "🎉 Tarefa '$job_name' agendada com sucesso!"
    else
        error "Falha ao agendar a tarefa '$job_name'."
    fi
}

# Função auxiliar para remover uma tarefa do cron
remove_cron_job() {
    subsection "Removendo Tarefa Agendada"
    local cron_jobs
    mapfile -t cron_jobs < <(crontab -l 2>/dev/null | grep 'Cluster AI')

    if [ ${#cron_jobs[@]} -eq 0 ]; then
        warn "Nenhuma tarefa do Cluster AI encontrada para remover."
        return
    fi

    info "Selecione a tarefa para remover:"
    select job in "${cron_jobs[@]}" "Cancelar"; do
        if [[ "$job" == "Cancelar" ]]; then
            info "Remoção cancelada."
            break
        elif [ -n "$job" ]; then
            (crontab -l | grep -vF "$job") | crontab -
            success "Tarefa removida com sucesso."
            break
        else
            error "Seleção inválida."
        fi
    done
}

# Função para visualizar tarefas agendadas
view_cron_jobs() {
    subsection "Tarefas Agendadas do Cluster AI"
    if ! crontab -l 2>/dev/null | grep -q 'Cluster AI'; then
        warn "Nenhuma tarefa do Cluster AI agendada."
    else
        crontab -l | grep --color=always -E 'Cluster AI|$'
    fi
}

# Limpa todos os arquivos de log
clear_all_logs() {
    local force_mode=false
    if [[ "$1" == "--force" ]]; then
        force_mode=true
    fi

    section "🧽 Limpeza de Todos os Logs"
    local log_dir="${PROJECT_ROOT}/logs"

    if [ ! -d "$log_dir" ]; then
        warn "Diretório de logs não encontrado em '$log_dir'."
        return 1
    fi

    # Usar find para ser mais robusto com nomes de arquivos
    local log_files
    mapfile -t log_files < <(find "$log_dir" -maxdepth 1 -type f -name "*.log")

    if [ ${#log_files[@]} -eq 0 ]; then
        success "Nenhum arquivo .log para limpar em '$log_dir'."
        return 0
    fi

    info "Os seguintes arquivos de log serão ESVAZIADOS (não removidos):"
    for file in "${log_files[@]}"; do
        echo "  - $(basename "$file") ($(du -h "$file" | cut -f1))"
    done
    echo

    if [[ "$force_mode" == true ]] || confirm_operation "Você tem certeza que deseja limpar todos esses logs?"; then
        progress "Limpando logs..."
        for file in "${log_files[@]}"; do
            > "$file"
        done
        success "Todos os arquivos de log foram limpos."
    else
        info "Operação de limpeza cancelada."
    fi
}

# Arquiva e limpa todos os arquivos de log
archive_logs() {
    local force_mode=false
    if [[ "$1" == "--force" ]]; then
        force_mode=true
    fi

    section "🗄️ Arquivamento de Logs"
    local log_dir="${PROJECT_ROOT}/logs"
    local backup_dir="${PROJECT_ROOT}/backups"
    mkdir -p "$backup_dir"

    if [ ! -d "$log_dir" ]; then
        warn "Diretório de logs não encontrado em '$log_dir'."
        return 1
    fi

    local log_files
    mapfile -t log_files < <(find "$log_dir" -maxdepth 1 -type f -name "*.log")

    if [ ${#log_files[@]} -eq 0 ]; then
        success "Nenhum arquivo .log para arquivar em '$log_dir'."
        return 0
    fi

    local archive_name="logs_archive_$(date +%Y-%m-%d_%H%M%S).tar.gz"
    local archive_path="${backup_dir}/${archive_name}"

    info "Os seguintes arquivos de log serão arquivados e depois limpos:"
    for file in "${log_files[@]}"; do
        echo "  - $(basename "$file") ($(du -h "$file" | cut -f1))"
    done
    echo
    info "O arquivo de arquivamento será salvo em: ${backup_dir}/${archive_name}"

    if [[ "$force_mode" == true ]] || confirm_operation "Você tem certeza que deseja arquivar e limpar esses logs?"; then
        progress "Criando arquivo de arquivamento..."
        if tar -czf "$archive_path" -C "$log_dir" $(for file in "${log_files[@]}"; do echo "$(basename "$file")"; done); then
            success "Arquivo de arquivamento criado com sucesso: $archive_path"
            progress "Limpando arquivos de log originais..."
            for file in "${log_files[@]}"; do > "$file"; done
            success "Arquivos de log originais foram limpos."
        else
            error "Falha ao criar o arquivo de arquivamento. Os logs não foram limpos."
        fi
    else
        info "Operação de arquivamento cancelada."
    fi
}

# Visualiza logs do sistema
view_system_logs() {
    section "📋 Visualizador de Logs do Sistema"

    while true; do
        subsection "Selecione o log que deseja visualizar"
        echo "1) Log de Ativação do Servidor (server_activation.log)"
        echo "2) 🚀 Log Principal do Cluster Dask (dask_cluster.log)"
        echo "3) Log do Ollama (via journalctl ou docker)"
        echo "4) Log do OpenWebUI (via docker)"
        echo "5) Log de Limpeza Automática (cron_cleanup.log)"
        echo "6) Logs do Nginx (access.log e error.log)"
        echo "7) 🛡️  Log de Auditoria (audit.log)"
        echo
        echo "8) 🧽 Limpar um log específico"
        echo "0) Voltar ao menu principal"
        echo

        read -p "Digite sua opção: " choice

        local log_file=""
        local log_cmd=""

        case $choice in
            1) log_file="${PROJECT_ROOT}/logs/server_activation.log" ;;
            2) log_file="${PROJECT_ROOT}/logs/dask_cluster.log" ;; # Log principal do Dask
            3)
                if command_exists journalctl && sudo journalctl -u ollama -n 1 >/dev/null 2>&1; then
                    log_cmd="sudo journalctl -u ollama -f -n 200"
                elif command_exists docker && docker ps -q --filter "name=ollama" | grep -q .; then
                    log_cmd="docker logs -f ollama"
                else
                    error "Não foi possível encontrar os logs do Ollama (nem via journalctl, nem via Docker)."
                fi
                ;;
            4)
                if command_exists docker && docker ps -q --filter "name=open-webui" | grep -q .; then
                    log_cmd="docker logs -f open-webui"
                else
                    error "Container Docker 'open-webui' não encontrado ou não está em execução."
                fi
                ;;
            5) log_file="${PROJECT_ROOT}/logs/cron_cleanup.log" ;;
            6)
                info "O Nginx possui dois logs principais. Qual deseja ver?"
                echo "1) access.log (requisições)"
                echo "2) error.log (erros)"
                read -p "Escolha [1-2]: " nginx_choice
                if [[ "$nginx_choice" == "1" ]]; then
                    log_file="/var/log/nginx/access.log"
                elif [[ "$nginx_choice" == "2" ]]; then
                    log_file="/var/log/nginx/error.log"
                fi
                log_cmd="sudo tail -f -n 200 $log_file"
                ;;
            7)
                log_file="${PROJECT_ROOT}/logs/audit.log"
                # Usar 'less' para logs de auditoria, pois permite navegar facilmente
                log_cmd="less -R $log_file"
                ;;
            8) clear_specific_log; continue ;;
            0) return ;;
            *) error "Opção inválida."; continue ;;
        esac

        if [ -n "$log_file" ] && [ ! -f "$log_file" ]; then
            error "Arquivo de log não encontrado: $log_file"
        elif [ -n "$log_file" ] && [ -z "$log_cmd" ]; then
            log_cmd="tail -f -n 200 $log_file"
        fi

        if [ -n "$log_cmd" ]; then
            if [[ "$log_cmd" == tail* ]]; then
                info "Pressione CTRL+C para parar de visualizar o log."
            else
                info "Pressione 'q' para sair do visualizador de log."
            fi
            sleep 2
            (set -x; $log_cmd)
        fi
        read -p "Pressione Enter para continuar..."
    done
}

# Testa a conexão com um worker de forma interativa e amigável
test_worker_connection_interactive() {
    local name="$1"
    local ip="$2"
    local user="$3"
    local port="$4"
    local config_file="$5"

    subsection "Testando Conexão com: $name ($user@$ip:$port)"

    local all_ok=true

    # 1. Teste de Ping
    progress "1/3 - Verificando conectividade de rede (ping)..."
    if ping -c 1 -W 3 "$ip" >/dev/null 2>&1; then
        success "      └─ Ping para $ip bem-sucedido."
    else
        warn "      └─ Ping para $ip falhou. O host pode estar offline ou bloqueando pings (ICMP)."
        # Não consideramos falha de ping como crítica, pois pode ser bloqueado por firewall
    fi
    sleep 1

    # 2. Teste de Porta
    progress "2/3 - Verificando se a porta SSH ($port) está aberta..."
    if timeout 5 bash -c "echo >/dev/tcp/$ip/$port" 2>/dev/null; then
        success "      └─ Porta $port está aberta e acessível."
    else
        error "      └─ Porta $port está fechada ou bloqueada por firewall."
        warn "         Verifique se o serviço SSH está rodando no worker."
        all_ok=false
    fi
    sleep 1

    # 3. Teste de Autenticação SSH
    if [[ "$all_ok" == true ]]; then
        progress "3/3 - Tentando autenticação SSH..."
        # Adiciona a chave do host ao known_hosts para evitar prompts
        ssh-keyscan -p "$port" -H "$ip" >> ~/.ssh/known_hosts 2>/dev/null

        local ssh_output
        ssh_output=$(ssh -o BatchMode=yes -o ConnectTimeout=10 -p "$port" "$user@$ip" "echo 'Conexão bem-sucedida'" 2>&1)
        local ssh_exit_code=$?

        if [ $ssh_exit_code -eq 0 ]; then
            success "      └─ Autenticação SSH bem-sucedida!"
            info "         Resposta do worker: $ssh_output"
        else
            error "      └─ Falha na autenticação SSH (código: $ssh_exit_code)."
            warn "         Verifique se a chave SSH foi copiada corretamente ou se o usuário/senha está correto."
            info "         Saída do erro: $ssh_output"
            all_ok=false
        fi
    else
        warn "Pulando teste de autenticação SSH devido a falha na verificação da porta."
    fi

    # Atualiza o status no arquivo de configuração
    if [[ "$all_ok" == true ]]; then
        sed -i "s/^\($name $ip $user $port\).*/\1 active/" "$config_file"
        success "\n✅ Worker '$name' está ATIVO e pronto para uso."
    else
        sed -i "s/^\($name $ip $user $port\).*/\1 inactive/" "$config_file"
        error "\n❌ Worker '$name' está INATIVO. Verifique os erros acima."
    fi
}
# =============================================================================
# FUNÇÃO PARA GERENCIAR WORKERS REMOTOS (SSH)
# =============================================================================

manage_remote_workers() {
    section "Gerenciamento de Workers Remotos (SSH)"

    local config_file="$HOME/.cluster_config/nodes_list.conf"

    # Criar arquivo de configuração se não existir
    if [ ! -f "$config_file" ]; then
        mkdir -p "$HOME/.cluster_config"

cat > "$config_file" <<EOF
# =============================================================================
# Configuração de Workers Remotos para Cluster AI
# Formato: hostname IP user port status
# Exemplo: android-worker 192.168.1.100 u0_a249 8022 active

# Adicione seus workers remotos aqui:
EOF
        success "Arquivo de configuração criado: $config_file"
    fi

    while true; do
        echo
        echo "Workers Remotos - Menu:"
        echo "1) Listar Workers Configurados"
        echo "2) Adicionar Novo Worker"
        echo "3) Testar Conexão com Worker"
        echo "4) Remover Worker"
        echo "5) Atualizar Status dos Workers"
        echo "0) Voltar"
        echo

        read -p "Digite sua opção: " option

        case $option in
            1)
                # Listar workers
                section "Workers Configurados"
                if [ -s "$config_file" ] && grep -v '^#' "$config_file" | grep -q .; then
                    echo "Workers encontrados:"
                    echo
                    awk 'NR>1 && !/^#/ {print NR-1 ") " $1 " - " $2 ":" $4 " (" $3 ") - " ($5 ? $5 : "unknown")}' "$config_file"
                else
                    warn "Nenhum worker configurado ainda."
                    info "Use a opção 2 para adicionar um worker."
                fi
                ;;
            2)
                # Adicionar worker
                section "Adicionando Novo Worker"
                echo "Digite as informações do worker:"
                read -p "Nome do worker (ex: android-worker): " worker_name
                read -p "IP do worker: " worker_ip
                read -p "Usuário SSH: " worker_user

                local default_port=22
                if [[ "$worker_name" == "android-worker" ]]; then
                    default_port=8022
                    info "Detectado worker Android, porta padrão sugerida: 8022"
                fi
                read -p "Porta SSH (padrão $default_port): " worker_port

                # Valores padrão
                worker_port=${worker_port:-$default_port}
                worker_user=${worker_user:-$USER}

                # Opção para configurar chave SSH
                echo
                if command_exists ssh-copy-id && confirm_operation "Deseja copiar sua chave SSH pública para o worker para acesso sem senha?"; then
                    info "Tentando copiar a chave SSH para $worker_user@$worker_ip na porta $worker_port..."
                    info "Você precisará digitar a senha de '$worker_user' uma única vez."
                    if ssh-copy-id -p "$worker_port" "$worker_user@$worker_ip"; then
                        success "Chave SSH copiada com sucesso!"
                    else
                        error "Falha ao copiar a chave SSH."
                        warn "Você precisará configurar a autenticação manualmente ou tentar novamente."
                    fi
                fi

                # Adicionar ao arquivo
                echo "$worker_name $worker_ip $worker_user $worker_port active" >> "$config_file"
                success "Worker '$worker_name' adicionado à configuração"
                ;;
            2)
                # ... (código anterior) ...
                success "Worker '$worker_name' adicionado à configuração."
                test_worker_connection_interactive "$worker_name" "$worker_ip" "$worker_user" "$worker_port" "$config_file"
                ;;
            3)
                # Testar conexão
                section "Testando Conexão"
                if [ -s "$config_file" ] && grep -v '^#' "$config_file" | grep -q .; then
                    echo "Workers disponíveis:"
                    awk 'NR>1 && !/^#/ {print NR-1 ") " $1 " - " $2 ":" $4 " (" $3 ")"}' "$config_file"
                    echo
                    read -p "Digite o número do worker para testar: " worker_num

                    local worker_info=$(awk "NR==$((worker_num+1)) && !/^#/ {print \$1,\$2,\$3,\$4}" "$config_file")
                    if [ -n "$worker_info" ]; then
                        local name ip user port
                        read -r name ip user port <<< "$worker_info"
                        test_worker_connection_interactive "$name" "$ip" "$user" "$port" "$config_file"
                    else
                        error "Worker não encontrado"
                    fi
                else
                    warn "Nenhum worker configurado."
                fi
                ;;
            4)
                # Remover worker
                section "Removendo Worker"
                if [ -s "$config_file" ] && grep -v '^#' "$config_file" | grep -q .; then
                    echo "Workers disponíveis:"
                    awk 'NR>1 && !/^#/ {print NR-1 ") " $1 " - " $2 ":" $4 " (" $3 ")"}' "$config_file"
                    echo
                    read -p "Digite o número do worker para remover: " worker_num

                    local line_num=$((worker_num+1))
                    if [ $line_num -gt 1 ] && sed -n "${line_num}p" "$config_file" | grep -q .; then
                        local worker_name=$(sed -n "${line_num}p" "$config_file" | awk '{print $1}')
                        sed -i "${line_num}d" "$config_file"
                        success "Worker '$worker_name' removido"
                    else
                        error "Worker não encontrado"
                    fi
                else
                    warn "Nenhum worker configurado."
                fi
                ;;
            5)
                # Atualizar status
                section "Atualizando Status dos Workers"
                if [ -s "$config_file" ] && grep -v '^#' "$config_file" | grep -q .; then
                    log "Verificando status de todos os workers..."
                    local updated=0

                    while IFS= read -r line; do
                        if [[ $line =~ ^# ]] || [ -z "$line" ]; then
                            continue
                        fi

                        local name ip user port status
                        read name ip user port status <<< "$line"

                        # Adiciona a chave do host ao known_hosts para segurança
                        ssh-keyscan -p "$port" -H "$ip" >> ~/.ssh/known_hosts 2>/dev/null
                        if ssh -o StrictHostKeyChecking=no \
                               -o UserKnownHostsFile=/dev/null \
                               -o ConnectTimeout=10 \
                               -o BatchMode=yes \
                               -p "$port" \
                               "$user@$ip" \
                               "echo 'OK'" >/dev/null 2>&1; then
                            sed -i "s/^$name $ip $user $port .*/$name $ip $user $port active/" "$config_file"
                            ((updated++))
                        else
                            sed -i "s/^$name $ip $user $port .*/$name $ip $user $port inactive/" "$config_file"
                        fi
                    done < "$config_file"

                    success "Status atualizado para $updated workers"
                else
                    warn "Nenhum worker configurado."
                fi
                ;;
            0)
                return
                ;;
            *)
                error "Opção inválida"
                ;;
        esac

        echo
        read -p "Pressione Enter para continuar..."
    done
}

# =============================================================================
# FUNÇÃO PARA INSTRUÇÕES DO WORKER ANDROID
# =============================================================================

show_android_setup_instructions() {
    section "Instruções para Configurar Worker Android (Termux)"

    info "Este processo automatiza a configuração do seu dispositivo Android como um worker."
    echo
    echo "PASSO 1: No seu dispositivo Android, abra o aplicativo Termux."
    echo
    echo "PASSO 2: Copie e cole o comando abaixo no Termux e pressione Enter."
    echo "         Este comando fará o download e executará o script de configuração automática."
    echo
    echo -e "${YELLOW}--------------------------------------------------------------------------------${NC}"
    echo -e "${YELLOW}curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker.sh | bash${NC}"
    echo -e "${YELLOW}--------------------------------------------------------------------------------${NC}"
    echo
    echo "PASSO 3: Siga as instruções no Termux."
    echo "         Ao final, o script exibirá a ${GREEN}chave SSH pública${NC} e o ${GREEN}IP${NC} do seu dispositivo."
    echo
    echo "PASSO 4: Volte para este menu e use a opção 'Gerenciar Workers Remotos (SSH)' para"
    echo "         adicionar o novo worker usando as informações fornecidas pelo script."
    echo
    success "Após esses passos, seu worker Android estará pronto para ser usado!"
}

# =============================================================================
# FUNÇÃO PARA GERENCIAR WORKERS REGISTRADOS AUTOMATICAMENTE
# =============================================================================

manage_auto_registered_workers() {
    section "Gerenciamento de Workers Registrados Automaticamente"

    local config_dir="$HOME/.cluster_config"
    local workers_config="$config_dir/workers.conf"
    local authorized_keys_dir="$config_dir/authorized_keys"

    # Criar diretórios se não existirem
    mkdir -p "$config_dir" "$authorized_keys_dir"

    # Criar arquivo de configuração se não existir
    if [ ! -f "$workers_config" ]; then
        cat > "$workers_config" <<EOF
# Workers registrados automaticamente
# Formato: worker_name worker_ip worker_user worker_port status timestamp
# Status: active, inactive, pending
EOF
        success "Arquivo de configuração criado: $workers_config"
    fi

    while true; do
        echo
        echo "Workers Registrados - Menu:"
        echo "1) Listar Workers Registrados"
        echo "2) Verificar Status dos Workers"
        echo "3) Conectar a Worker Específico"
        echo "4) Remover Worker Registrado"
        echo "5) Limpar Workers Inativos"
        echo "6) Exportar Configuração"
        echo "0) Voltar"
        echo

        read -p "Digite sua opção: " option

        case $option in
            1)
                # Listar workers registrados
                section "Workers Registrados Automaticamente"
                if [ -s "$workers_config" ] && grep -v '^#' "$workers_config" | grep -q .; then
                    echo "Workers registrados:"
                    echo
                    local count=1
                    while IFS= read -r line; do
                        if [[ $line =~ ^# ]] || [ -z "$line" ]; then
                            continue
                        fi
                        local name ip user port status timestamp
                        read -r name ip user port status timestamp <<< "$line"

                        case $status in
                            active)
                                echo -e "$count) $name ($ip:$port) - ${GREEN}ATIVO${NC} - Usuário: $user"
                                ;;
                            inactive)
                                echo -e "$count) $name ($ip:$port) - ${RED}INATIVO${NC} - Usuário: $user"
                                ;;
                            pending)
                                echo -e "$count) $name ($ip:$port) - ${YELLOW}PENDENTE${NC} - Usuário: $user"
                                ;;
                            *)
                                echo -e "$count) $name ($ip:$port) - ${BLUE}DESCONHECIDO${NC} - Usuário: $user"
                                ;;
                        esac

                        if [ -n "$timestamp" ]; then
                            echo "   Registrado em: $(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$timestamp")"
                        fi

                        # Verificar se chave existe
                        if [ -f "$authorized_keys_dir/${name}.pub" ]; then
                            echo -e "   ${GREEN}✓${NC} Chave SSH armazenada"
                        else
                            echo -e "   ${RED}✗${NC} Chave SSH não encontrada"
                        fi
                        echo
                        ((count++))
                    done < "$workers_config"
                else
                    warn "Nenhum worker registrado automaticamente."
                    info "Os workers serão registrados automaticamente quando se conectarem."
                fi
                ;;
            2)
                # Verificar status dos workers
                section "Verificando Status dos Workers"
                if [ -s "$workers_config" ] && grep -v '^#' "$workers_config" | grep -q .; then
                    log "Verificando conectividade de todos os workers..."
                    local checked=0
                    local active=0
                    local inactive=0

                    while IFS= read -r line; do
                        if [[ $line =~ ^# ]] || [ -z "$line" ]; then
                            continue
                        fi

                        local name ip user port status timestamp
                        read -r name ip user port status timestamp <<< "$line"

                        subsection "Verificando: $name ($ip:$port)"

                        # Testar conectividade
                        if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p "$port" "$user@$ip" "echo 'OK'" >/dev/null 2>&1; then
                            success "  ✅ Worker ativo"
                            sed -i "s/^$name $ip $user $port .*/$name $ip $user $port active $(date +%s)/" "$workers_config"
                            ((active++))
                        else
                            warn "  ❌ Worker inativo"
                            sed -i "s/^$name $ip $user $port .*/$name $ip $user $port inactive $(date +%s)/" "$workers_config"
                            ((inactive++))
                        fi

                        ((checked++))
                        echo
                    done < "$workers_config"

                    section "Resumo da Verificação"
                    success "Workers verificados: $checked"
                    success "Workers ativos: $active"
                    if [ $inactive -gt 0 ]; then
                        warn "Workers inativos: $inactive"
                    fi
                else
                    warn "Nenhum worker registrado para verificar."
                fi
                ;;
            3)
                # Conectar a worker específico
                section "Conectar a Worker Específico"
                if [ -s "$workers_config" ] && grep -v '^#' "$workers_config" | grep -q .; then
                    echo "Workers disponíveis:"
                    local count=1
                    while IFS= read -r line; do
                        if [[ $line =~ ^# ]] || [ -z "$line" ]; then
                            continue
                        fi
                        local name ip user port status
                        read -r name ip user port status <<< "$line"
                        echo "$count) $name ($ip:$port) - Status: $status"
                        ((count++))
                    done < "$workers_config"
                    echo

                    read -p "Digite o número do worker para conectar: " worker_num

                    local line_num=$((worker_num))
                    local worker_info=$(sed -n "${line_num}p" "$workers_config" | grep -v '^#')
                    if [ -n "$worker_info" ]; then
                        local name ip user port status
                        read -r name ip user port status <<< "$worker_info"

                        info "Conectando ao worker: $name ($user@$ip:$port)"
                        info "Pressione Ctrl+D para sair da sessão SSH"
                        echo

                        ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
                    else
                        error "Worker não encontrado"
                    fi
                else
                    warn "Nenhum worker registrado."
                fi
                ;;
            4)
                # Remover worker registrado
                section "Remover Worker Registrado"
                if [ -s "$workers_config" ] && grep -v '^#' "$workers_config" | grep -q .; then
                    echo "Workers registrados:"
                    local count=1
                    while IFS= read -r line; do
                        if [[ $line =~ ^# ]] || [ -z "$line" ]; then
                            continue
                        fi
                        local name ip user port status
                        read -r name ip user port status <<< "$line"
                        echo "$count) $name ($ip:$port)"
                        ((count++))
                    done < "$workers_config"
                    echo

                    read -p "Digite o número do worker para remover: " worker_num

                    local line_num=$((worker_num))
                    local worker_info=$(sed -n "${line_num}p" "$workers_config" | grep -v '^#')
                    if [ -n "$worker_info" ]; then
                        local name ip user port status
                        read -r name ip user port status <<< "$worker_info"

                        if confirm_operation "Remover worker '$name' ($ip:$port)?"; then
                            # Remover linha do arquivo
                            sed -i "${line_num}d" "$workers_config"

                            # Remover chave SSH se existir
                            if [ -f "$authorized_keys_dir/${name}.pub" ]; then
                                rm "$authorized_keys_dir/${name}.pub"
                                info "Chave SSH removida"
                            fi

                            # Remover do authorized_keys do usuário
                            if [ -f "$HOME/.ssh/authorized_keys" ] && grep -q "$name" "$HOME/.ssh/authorized_keys"; then
                                sed -i "/$name/d" "$HOME/.ssh/authorized_keys"
                                info "Worker removido do authorized_keys"
                            fi

                            success "Worker '$name' removido com sucesso"
                        fi
                    else
                        error "Worker não encontrado"
                    fi
                else
                    warn "Nenhum worker registrado."
                fi
                ;;
            5)
                # Limpar workers inativos
                section "Limpar Workers Inativos"
                if [ -s "$workers_config" ] && grep -v '^#' "$workers_config" | grep -q .; then
                    local inactive_count=0
                    local to_remove=()

                    while IFS= read -r line; do
                        if [[ $line =~ ^# ]] || [ -z "$line" ]; then
                            continue
                        fi

                        local name ip user port status
                        read -r name ip user port status <<< "$line"

                        if [ "$status" = "inactive" ]; then
                            to_remove+=("$name $ip $user $port")
                            ((inactive_count++))
                        fi
                    done < "$workers_config"

                    if [ $inactive_count -gt 0 ]; then
                        info "Encontrados $inactive_count workers inativos"
                        if confirm_operation "Remover todos os workers inativos?"; then
                            for worker_info in "${to_remove[@]}"; do
                                local name ip user port
                                read -r name ip user port <<< "$worker_info"

                                # Remover linha
                                sed -i "/^$name $ip $user $port/d" "$workers_config"

                                # Remover chave SSH
                                if [ -f "$authorized_keys_dir/${name}.pub" ]; then
                                    rm "$authorized_keys_dir/${name}.pub"
                                fi

                                info "Removido: $name ($ip:$port)"
                            done

                            success "Workers inativos removidos: $inactive_count"
                        fi
                    else
                        success "Nenhum worker inativo encontrado"
                    fi
                else
                    warn "Nenhum worker registrado."
                fi
                ;;
            6)
                # Exportar configuração
                section "Exportar Configuração"
                local export_file="$HOME/cluster_workers_export_$(date +%Y%m%d_%H%M%S).tar.gz"

                if [ -d "$config_dir" ]; then
                    info "Exportando configuração para: $export_file"
                    if tar -czf "$export_file" -C "$HOME" ".cluster_config"; then
                        success "Configuração exportada com sucesso"
                        info "Arquivo: $export_file"
                    else
                        error "Falha ao exportar configuração"
                    fi
                else
                    warn "Nenhuma configuração para exportar"
                fi
                ;;
            0)
                return
                ;;
            *)
                error "Opção inválida"
                ;;
        esac

        echo
        read -p "Pressione Enter para continuar..."
    done
}

# =============================================================================
# FUNÇÃO PARA CONFIGURAR CLUSTER (IMPLEMENTAÇÃO DA OPÇÃO 7)
# =============================================================================

configure_cluster() {
    section "Configuração do Cluster"

    echo "Opções de Configuração:"
    echo "1) Gerenciar Workers Remotos (SSH)"
    echo "2) Configurar Worker Android (Termux)"
    echo "3) Gerenciar Workers Registrados Automaticamente"
    echo "0) Voltar ao Menu Principal"
    echo

    read -p "Digite sua opção: " option

    case $option in
        1)
            manage_remote_workers
            ;;
        2)
            show_android_setup_instructions
            ;;
        3)
            manage_auto_registered_workers
            ;;
        0)
            return
            ;;
        *)
            error "Opção inválida."
            ;;
    esac

    echo
    read -p "Pressione Enter para continuar..."
    clear
}
# EXECUÇÃO
# =============================================================================

main "$@"
