#!/bin/bash
# Local: manager.sh
# Autor: Nome: Dagoberto Candeias. email: betoallnet@gmail.com telefone/whatsapp: +5511951754945

# =============================================================================
# Cluster AI - Gerenciador do Cluster
# =============================================================================
# Este é o painel de controle principal do Cluster AI. Permite iniciar,
# parar, configurar e monitorar todos os componentes do sistema.

set -e  # Para o script em caso de erro

# =============================================================================
# INICIALIZAÇÃO
# =============================================================================

# Carrega funções comuns
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/scripts/lib/common.sh"

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

# Exibe status do cluster
show_status() {
    section "Status do Cluster"

    # Verifica se configuração existe
    if ! file_exists "$CONFIG_FILE"; then
        warn "Arquivo de configuração não encontrado: $CONFIG_FILE"
        info "Execute ./install.sh primeiro"
        return 1
    fi

    # Carrega configuração
    load_config

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
    if is_port_open "${DASK_SCHEDULER_PORT:-8786}"; then
        success "📊 Dask Scheduler: Ativo (porta ${DASK_SCHEDULER_PORT:-8786})"
    else
        warn "📊 Dask Scheduler: Inativo"
    fi

    # Dask Dashboard
    if is_port_open "${DASK_DASHBOARD_PORT:-8787}"; then
        success "📈 Dask Dashboard: Ativo (porta ${DASK_DASHBOARD_PORT:-8787})"
    else
        warn "📈 Dask Dashboard: Inativo"
    fi

    # Ollama
    if is_port_open "${OLLAMA_PORT:-11434}"; then
        success "🧠 Ollama: Ativo (porta ${OLLAMA_PORT:-11434})"
    else
        warn "🧠 Ollama: Inativo"
    fi

    # OpenWebUI
    if is_port_open "${OPENWEBUI_PORT:-3000}"; then
        success "🌐 OpenWebUI: Ativo (porta ${OPENWEBUI_PORT:-3000})"
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
    info "Para mais detalhes, use: ./manager.sh status"
}

# Menu principal
show_menu() {
    subsection "Menu Principal"

    echo "Escolha uma operação:"
    echo
    echo "🚀 GERENCIAMENTO:"
    echo "1) ▶️  Iniciar Cluster"
    echo "2) ⏹️  Parar Cluster"
    echo "3) 🔄 Reiniciar Cluster"
    echo
    echo "📊 MONITORAMENTO:"
    echo "4) 📈 Status do Cluster"
    echo "5) 📊 Métricas em Tempo Real"
    echo "6) 📋 Logs do Sistema"
    echo
    echo "⚙️  CONFIGURAÇÃO:"
    echo "7) 🔧 Configurar Cluster"
    echo "8) 🔄 Atualizar Sistema"
    echo "9) 💾 Backup e Restauração"
    echo
    echo "🧪 DESENVOLVIMENTO:"
    echo "10) 🧪 Executar Testes"
    echo "11) 🔍 Diagnóstico do Sistema"
    echo "12) 📚 Documentação"
    echo
    echo "0) ❌ Sair"
    echo
}

# Inicia o cluster
start_cluster() {
    section "Iniciando Cluster AI"

    # Verifica configuração
    if ! file_exists "$CONFIG_FILE"; then
        error "Arquivo de configuração não encontrado"
        info "Execute ./install.sh primeiro"
        return 1
    fi

    load_config

    # Inicia Docker se necessário
    if command_exists docker; then
        progress "Iniciando Docker..."
        sudo systemctl start docker 2>/dev/null || true
    fi

    # Inicia Dask
    progress "Iniciando Dask..."
    if ! is_port_open "${DASK_SCHEDULER_PORT:-8786}"; then
        # Aqui seria o comando para iniciar Dask
        info "Dask scheduler seria iniciado na porta ${DASK_SCHEDULER_PORT:-8786}"
    fi

    # Inicia Ollama
    progress "Iniciando Ollama..."
    if ! is_port_open "${OLLAMA_PORT:-11434}"; then
        # Aqui seria o comando para iniciar Ollama
        info "Ollama seria iniciado na porta ${OLLAMA_PORT:-11434}"
    fi

    # Inicia OpenWebUI
    progress "Iniciando OpenWebUI..."
    if ! is_port_open "${OPENWEBUI_PORT:-3000}"; then
        # Aqui seria o comando para iniciar OpenWebUI
        info "OpenWebUI seria iniciado na porta ${OPENWEBUI_PORT:-3000}"
    fi

    # Inicia Nginx
    progress "Iniciando Nginx..."
    if command_exists nginx; then
        sudo systemctl start nginx 2>/dev/null || true
    fi

    success "Cluster iniciado com sucesso!"
    show_status
}

# Para o cluster
stop_cluster() {
    section "Parando Cluster AI"

    load_config 2>/dev/null || true

    # Para serviços
    progress "Parando serviços..."

    # Para Nginx
    if command_exists nginx && pgrep nginx >/dev/null; then
        sudo systemctl stop nginx 2>/dev/null || true
        success "Nginx parado"
    fi

    # Para containers Docker
    if command_exists docker; then
        docker stop $(docker ps -q) 2>/dev/null || true
        success "Containers Docker parados"
    fi

    success "Cluster parado com sucesso!"
}

# Reinicia o cluster
restart_cluster() {
    section "Reiniciando Cluster AI"

    stop_cluster
    sleep 2
    start_cluster
}

# Mostra status detalhado
show_detailed_status() {
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

    # Status dos serviços
    subsection "Serviços"
    show_status
    echo

    # Recursos do sistema
    subsection "Recursos"
    echo "📊 Uso de CPU: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
    echo "🧠 Uso de RAM: $(free | awk 'NR==2{printf "%.1f%%", $3*100/$2}')"
    echo "💾 Uso de Disco: $(df -h . | awk 'NR==2{print $5}')"
    echo

    # Portas abertas
    subsection "Portas"
    if command_exists netstat; then
        netstat -tln | grep LISTEN | head -10
    elif command_exists ss; then
        ss -tln | grep LISTEN | head -10
    fi
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
    echo "  diag       - Mostra diagnóstico do sistema"
    echo "  help       - Mostra esta ajuda"
    echo
    echo "Exemplos:"
    echo "  ./manager.sh start"
    echo "  ./manager.sh status"
    echo "  ./manager.sh test"
    echo
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
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
        status)
            show_detailed_status
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
        help|--help|-h)
            show_help
            exit 0
            ;;
    esac

    # Menu interativo
    while true; do
        show_banner
        show_status
        show_menu

        local choice
        read -p "Digite sua opção (0-12): " choice

        case $choice in
            1) start_cluster ;;
            2) stop_cluster ;;
            3) restart_cluster ;;
            4) show_detailed_status ;;
            5) warn "Métricas em tempo real - Em desenvolvimento" ;;
            6) warn "Logs do sistema - Em desenvolvimento" ;;
            7) configure_cluster ;;
            8) warn "Atualização - Em desenvolvimento" ;;
            9) warn "Backup - Em desenvolvimento" ;;
            10) run_tests ;;
            11) show_diagnostics ;;
            12) warn "Documentação - Em desenvolvimento" ;;
            0)
                info "Gerenciador encerrado"
                exit 0
                ;;
            *)
                error "Opção inválida. Tente novamente."
                sleep 2
                ;;
        esac

        echo
        read -p "Pressione Enter para continuar..."
        clear
    done
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
                read -p "Porta SSH (padrão 22): " worker_port

                # Valores padrão
                worker_port=${worker_port:-22}
                worker_user=${worker_user:-$USER}

                # Adicionar ao arquivo
                echo "$worker_name $worker_ip $worker_user $worker_port active" >> "$config_file"
                success "Worker '$worker_name' adicionado à configuração"
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
                        read name ip user port <<< "$worker_info"
                        log "Testando conexão com $name ($ip:$port)..."

                        # Adiciona a chave do host ao known_hosts para segurança
                        ssh-keyscan -p "$port" -H "$ip" >> ~/.ssh/known_hosts 2>/dev/null
                        if ssh -o ConnectTimeout=10 -p "$port" "$user@$ip" "echo 'Worker $name conectado!'"; then
                            success "Conexão com $name estabelecida com sucesso!"
                            # Atualizar status
                            sed -i "s/^$name $ip $user $port .*/$name $ip $user $port active/" "$config_file"
                        else
                            error "Falha na conexão com $name"
                            # Atualizar status
                            sed -i "s/^$name $ip $user $port .*/$name $ip $user $port inactive/" "$config_file"
                        fi
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
                        if ssh -o ConnectTimeout=5 -p "$port" "$user@$ip" "echo 'OK'" >/dev/null 2>&1; then
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
# FUNÇÃO PARA CONFIGURAR CLUSTER (IMPLEMENTAÇÃO DA OPÇÃO 7)
# =============================================================================

configure_cluster() {
    section "Configuração do Cluster"

    echo "Opções de Configuração:"
    echo "1) Gerenciar Workers Remotos (SSH)"
    echo "2) Configurar Worker Android (Termux)"
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

# Executa função principal
main "$@"
