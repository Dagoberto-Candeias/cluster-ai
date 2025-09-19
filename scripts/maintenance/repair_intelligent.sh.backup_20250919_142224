#!/bin/bash

# 🛠️ REPARO INTELIGENTE - Cluster AI
# Sistema avançado de diagnóstico e reparo automático

set -e

# --- Carregar Funções Comuns ---
PROJECT_ROOT=$(pwd)
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Definição de Caminhos ---
CONFIG_FILE="$PROJECT_ROOT/cluster.conf"
VENV_DIR="$PROJECT_ROOT/.venv"
OLLAMA_DIR="$HOME/.ollama"
OPENWEBUI_DIR="$HOME/.open-webui"
LOG_DIR="$PROJECT_ROOT/logs"

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Funções de Diagnóstico ---
show_banner() {
    echo
    echo -e "${CYAN}================================================================================${NC}"
    echo -e "${CYAN}                    🛠️ REPARO INTELIGENTE - CLUSTER AI 🛠️${NC}"
    echo -e "${CYAN}================================================================================${NC}"
    echo
}

analyze_system() {
    section "🔍 Análise Completa do Sistema"

    local issues_found=0
    local recommendations=()

    subsection "Verificações Básicas"

    # 1. Ambiente Python
    if [ ! -d "$VENV_DIR" ]; then
        echo -e "${RED}❌ Ambiente Virtual Python: FALTANDO${NC}"
        ((issues_found++))
        recommendations+=("Criar ambiente virtual Python")
    else
        echo -e "${GREEN}✅ Ambiente Virtual Python: OK${NC}"
    fi

    # 2. Configuração
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}❌ Arquivo de Configuração: FALTANDO${NC}"
        ((issues_found++))
        recommendations+=("Criar arquivo de configuração")
    else
        echo -e "${GREEN}✅ Arquivo de Configuração: OK${NC}"
    fi

    # 3. Dependências Python
    if [ -d "$VENV_DIR" ]; then
        if ! "$VENV_DIR/bin/python" -c "import dask, distributed" 2>/dev/null; then
            echo -e "${RED}❌ Dependências Python: FALTANDO${NC}"
            ((issues_found++))
            recommendations+=("Instalar dependências Python")
        else
            echo -e "${GREEN}✅ Dependências Python: OK${NC}"
        fi
    fi

    subsection "Verificações de Serviços"

    # 4. Docker
    if command_exists docker; then
        if docker info >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Docker: OK${NC}"
        else
            echo -e "${RED}❌ Docker: NÃO ACESSÍVEL${NC}"
            ((issues_found++))
            recommendations+=("Verificar serviço Docker")
        fi
    else
        echo -e "${YELLOW}⚠️  Docker: NÃO INSTALADO${NC}"
        recommendations+=("Instalar Docker")
    fi

    # 5. Containers
    if command_exists docker && docker info >/dev/null 2>&1; then
        local container_count=$(docker ps -a --filter "name=cluster-ai\|open-webui" --format "{{.Names}}" | wc -l)
        if [ "$container_count" -gt 0 ]; then
            echo -e "${GREEN}✅ Containers Cluster AI: $container_count ENCONTRADOS${NC}"
        else
            echo -e "${YELLOW}⚠️  Containers Cluster AI: NENHUM${NC}"
            recommendations+=("Criar containers necessários")
        fi
    fi

    # 6. Ollama
    if is_port_open 11434; then
        echo -e "${GREEN}✅ Ollama: EM EXECUÇÃO${NC}"
    else
        echo -e "${RED}❌ Ollama: PARADO${NC}"
        ((issues_found++))
        recommendations+=("Iniciar serviço Ollama")
    fi

    # 7. OpenWebUI
    if is_port_open 3000; then
        echo -e "${GREEN}✅ OpenWebUI: EM EXECUÇÃO${NC}"
    else
        echo -e "${YELLOW}⚠️  OpenWebUI: PARADO${NC}"
        recommendations+=("Iniciar OpenWebUI")
    fi

    # 8. Dask
    if is_port_open 8786; then
        echo -e "${GREEN}✅ Dask Scheduler: EM EXECUÇÃO${NC}"
    else
        echo -e "${RED}❌ Dask Scheduler: PARADO${NC}"
        ((issues_found++))
        recommendations+=("Iniciar Dask Scheduler")
    fi

    subsection "Verificações de Recursos"

    # 9. Espaço em disco
    local disk_usage=$(df "$PROJECT_ROOT" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
        echo -e "${RED}❌ Espaço em Disco: CRÍTICO ($disk_usage%)${NC}"
        ((issues_found++))
        recommendations+=("Liberar espaço em disco")
    elif [ "$disk_usage" -gt 80 ]; then
        echo -e "${YELLOW}⚠️  Espaço em Disco: BAIXO ($disk_usage%)${NC}"
        recommendations+=("Considerar limpeza de disco")
    else
        echo -e "${GREEN}✅ Espaço em Disco: OK ($disk_usage%)${NC}"
    fi

    # 10. Memória RAM
    local mem_usage=$(free | awk 'NR==2{printf "%.0f", $3*100/$2}')
    if [ "$mem_usage" -gt 90 ]; then
        echo -e "${RED}❌ Memória RAM: CRÍTICA ($mem_usage%)${NC}"
        ((issues_found++))
        recommendations+=("Liberar memória RAM")
    elif [ "$mem_usage" -gt 80 ]; then
        echo -e "${YELLOW}⚠️  Memória RAM: ALTA ($mem_usage%)${NC}"
        recommendations+=("Monitorar uso de memória")
    else
        echo -e "${GREEN}✅ Memória RAM: OK ($mem_usage%)${NC}"
    fi

    subsection "Verificações de Arquivos"

    # 11. Logs
    if [ -d "$LOG_DIR" ]; then
        local log_count=$(find "$LOG_DIR" -name "*.log" -mtime +7 2>/dev/null | wc -l)
        if [ "$log_count" -gt 0 ]; then
            echo -e "${YELLOW}⚠️  Logs Antigos: $log_count arquivos${NC}"
            recommendations+=("Limpar logs antigos")
        else
            echo -e "${GREEN}✅ Logs: OK${NC}"
        fi
    fi

    # 12. Arquivos temporários
    local temp_count=$(find "$PROJECT_ROOT" -name "__pycache__" -o -name "*.pyc" -o -name ".pytest_cache" 2>/dev/null | wc -l)
    if [ "$temp_count" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Arquivos Temporários: $temp_count encontrados${NC}"
        recommendations+=("Limpar arquivos temporários")
    else
        echo -e "${GREEN}✅ Arquivos Temporários: OK${NC}"
    fi

    # Resultado da análise
    echo
    echo -e "${BLUE}📊 RESULTADO DA ANÁLISE:${NC}"
    if [ "$issues_found" -eq 0 ]; then
        echo -e "${GREEN}🎉 Sistema saudável! Nenhum problema crítico encontrado.${NC}"
    else
        echo -e "${RED}⚠️  $issues_found problemas encontrados${NC}"
    fi

    if [ ${#recommendations[@]} -gt 0 ]; then
        echo
        echo -e "${YELLOW}💡 RECOMENDAÇÕES:${NC}"
        for i in "${!recommendations[@]}"; do
            echo -e "  $((i+1)). ${recommendations[$i]}"
        done
    fi

    return $issues_found
}

show_repair_options() {
    echo "Opções de Reparo:"
    echo
    echo "🔧 REPAROS INDIVIDUAIS:"
    echo "1) Ambiente Virtual Python"
    echo "2) Dependências Python"
    echo "3) Arquivo de Configuração"
    echo "4) Serviço Docker"
    echo "5) Containers Docker"
    echo "6) Serviço Ollama"
    echo "7) OpenWebUI"
    echo "8) Dask Scheduler"
    echo "9) Nginx"
    echo
    echo "🧹 LIMPEZA:"
    echo "10) Limpar Logs Antigos"
    echo "11) Limpar Arquivos Temporários"
    echo "12) Liberar Espaço em Disco"
    echo
    echo "🔄 REPAROS COMPLETOS:"
    echo "13) Reparo Rápido (Problemas Críticos)"
    echo "14) Reparo Completo (Todos os Componentes)"
    echo "15) Diagnóstico Detalhado"
    echo
    echo "0) ❌ Cancelar"
    echo
}

# --- Funções de Reparo ---
repair_python_env() {
    subsection "🔧 Reparando Ambiente Python"

    if [ -d "$VENV_DIR" ]; then
        warn "Removendo ambiente virtual existente..."
        rm -rf "$VENV_DIR"
    fi

    log "Criando novo ambiente virtual..."
    python3 -m venv "$VENV_DIR"

    log "Ativando ambiente virtual..."
    source "$VENV_DIR/bin/activate"

    log "Instalando dependências..."
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
    else
        pip install dask distributed bokeh
    fi

    success "✅ Ambiente Python reparado!"
}

repair_python_deps() {
    subsection "🔧 Reparando Dependências Python"

    if [ ! -d "$VENV_DIR" ]; then
        error "Ambiente virtual não encontrado. Execute o reparo do ambiente Python primeiro."
        return 1
    fi

    source "$VENV_DIR/bin/activate"

    log "Atualizando pip..."
    pip install --upgrade pip

    log "Reinstalando dependências..."
    if [ -f "requirements.txt" ]; then
        pip install --force-reinstall -r requirements.txt
    else
        pip install --force-reinstall dask distributed bokeh
    fi

    success "✅ Dependências Python reparadas!"
}

repair_config() {
    subsection "🔧 Reparando Configuração"

    if [ -f "$CONFIG_FILE" ]; then
        warn "Fazendo backup da configuração atual..."
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    log "Criando nova configuração..."
    cat > "$CONFIG_FILE" << EOF
# Configuração do Cluster AI - Reparada em $(date)
role=server
project_root=$PROJECT_ROOT
venv_dir=$VENV_DIR

# Portas
dask_scheduler_port=8786
dask_dashboard_port=8787
ollama_port=11434
openwebui_port=3000
nginx_port=80

# Configurações
allow_remote_access=false
enable_ssl=false
auto_start_services=true
EOF

    success "✅ Configuração reparada!"
}

repair_docker_service() {
    subsection "🔧 Reparando Serviço Docker"

    if ! command_exists docker; then
        error "Docker não está instalado."
        return 1
    fi

    log "Reiniciando serviço Docker..."
    if command_exists systemctl; then
        sudo systemctl restart docker
    elif command_exists service; then
        sudo service docker restart
    else
        error "Não foi possível reiniciar o serviço Docker."
        return 1
    fi

    # Aguardar Docker ficar disponível
    local count=0
    while [ $count -lt 10 ]; do
        if docker info >/dev/null 2>&1; then
            success "✅ Serviço Docker reparado!"
            return 0
        fi
        sleep 2
        ((count++))
    done

    error "Falha ao reparar serviço Docker."
    return 1
}

repair_containers() {
    subsection "🔧 Reparando Containers Docker"

    if ! docker info >/dev/null 2>&1; then
        error "Docker não está acessível."
        return 1
    fi

    log "Parando containers existentes..."
    docker stop $(docker ps -q) 2>/dev/null || true

    log "Removendo containers parados..."
    docker rm $(docker ps -a -q) 2>/dev/null || true

    log "Limpando imagens não utilizadas..."
    docker image prune -f >/dev/null 2>&1 || true

    success "✅ Containers Docker reparados!"
}

repair_ollama() {
    subsection "🔧 Reparando Ollama"

    log "Parando processos Ollama existentes..."
    pkill -f ollama 2>/dev/null || true

    sleep 2

    log "Iniciando Ollama..."
    if command_exists ollama; then
        nohup ollama serve > /dev/null 2>&1 &
        sleep 3

        if is_port_open 11434; then
            success "✅ Ollama reparado!"
        else
            error "Falha ao iniciar Ollama."
            return 1
        fi
    else
        error "Ollama não está instalado."
        return 1
    fi
}

repair_openwebui() {
    subsection "🔧 Reparando OpenWebUI"

    if ! docker info >/dev/null 2>&1; then
        error "Docker não está acessível."
        return 1
    fi

    log "Parando container OpenWebUI existente..."
    docker stop open-webui 2>/dev/null || true
    docker rm open-webui 2>/dev/null || true

    log "Iniciando novo container OpenWebUI..."
    docker run -d \
        --name open-webui \
        -p 3000:8080 \
        --restart unless-stopped \
        ghcr.io/open-webui/open-webui:latest

    sleep 5

    if is_port_open 3000; then
        success "✅ OpenWebUI reparado!"
    else
        error "Falha ao iniciar OpenWebUI."
        return 1
    fi
}

repair_dask() {
    subsection "🔧 Reparando Dask Scheduler"

    log "Parando processos Dask existentes..."
    pkill -f "dask-scheduler" 2>/dev/null || true
    pkill -f "dask-worker" 2>/dev/null || true

    sleep 2

    if [ -d "$VENV_DIR" ]; then
        source "$VENV_DIR/bin/activate"

        log "Iniciando Dask Scheduler..."
        nohup dask-scheduler --port 8786 > /dev/null 2>&1 &
        sleep 3

        if is_port_open 8786; then
            success "✅ Dask Scheduler reparado!"
        else
            error "Falha ao iniciar Dask Scheduler."
            return 1
        fi
    else
        error "Ambiente virtual não encontrado."
        return 1
    fi
}

repair_nginx() {
    subsection "🔧 Reparando Nginx"

    if ! command_exists nginx; then
        error "Nginx não está instalado."
        return 1
    fi

    log "Testando configuração Nginx..."
    if sudo nginx -t 2>/dev/null; then
        log "Reiniciando Nginx..."
        sudo systemctl restart nginx 2>/dev/null || sudo service nginx restart 2>/dev/null || true

        if sudo systemctl is-active nginx >/dev/null 2>&1; then
            success "✅ Nginx reparado!"
        else
            error "Falha ao reiniciar Nginx."
            return 1
        fi
    else
        error "Configuração do Nginx inválida."
        return 1
    fi
}

# --- Funções de Limpeza ---
clean_old_logs() {
    subsection "🧹 Limpando Logs Antigos"

    if [ -d "$LOG_DIR" ]; then
        local old_logs=$(find "$LOG_DIR" -name "*.log" -mtime +7 2>/dev/null)
        if [ -n "$old_logs" ]; then
            echo "$old_logs" | xargs rm -f
            local count=$(echo "$old_logs" | wc -l)
            success "✅ $count logs antigos removidos!"
        else
            success "✅ Nenhum log antigo encontrado!"
        fi
    else
        success "✅ Diretório de logs não existe!"
    fi
}

clean_temp_files() {
    subsection "🧹 Limpando Arquivos Temporários"

    local temp_files=(
        "$PROJECT_ROOT/__pycache__"
        "$PROJECT_ROOT/.pytest_cache"
        "$PROJECT_ROOT/*.pyc"
        "$PROJECT_ROOT/.coverage"
        "$PROJECT_ROOT/coverage.xml"
        "$PROJECT_ROOT/.DS_Store"
        "$PROJECT_ROOT/Thumbs.db"
    )

    local cleaned=0
    for temp in "${temp_files[@]}"; do
        if [ -e "$temp" ]; then
            rm -rf "$temp" 2>/dev/null && ((cleaned++))
        fi
    done

    # Limpar pycache recursivamente
    find "$PROJECT_ROOT" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

    success "✅ $cleaned tipos de arquivos temporários limpos!"
}

free_disk_space() {
    subsection "🧹 Liberando Espaço em Disco"

    log "Executando limpeza do sistema..."

    # Docker cleanup
    if command_exists docker; then
        log "Limpando Docker..."
        docker system prune -f >/dev/null 2>&1 || true
        docker volume prune -f >/dev/null 2>&1 || true
    fi

    # Package managers
    if command_exists apt; then
        log "Limpando apt..."
        sudo apt autoremove -y >/dev/null 2>&1 || true
        sudo apt autoclean -y >/dev/null 2>&1 || true
    elif command_exists yum; then
        log "Limpando yum..."
        sudo yum clean all >/dev/null 2>&1 || true
    fi

    # System cleanup
    if command_exists journalctl; then
        log "Limpando logs do sistema (últimos 7 dias)..."
        sudo journalctl --vacuum-time=7d >/dev/null 2>&1 || true
    fi

    success "✅ Espaço em disco liberado!"
}

# --- Funções de Reparo Completo ---
quick_repair() {
    section "🔄 Reparo Rápido"

    warn "Esta opção irá reparar apenas os problemas críticos detectados."
    if confirm_operation "Continuar com o reparo rápido?"; then

        # Reparar componentes críticos
        if [ ! -d "$VENV_DIR" ]; then
            repair_python_env
        fi

        if [ ! -f "$CONFIG_FILE" ]; then
            repair_config
        fi

        if ! is_port_open 11434; then
            repair_ollama
        fi

        if ! is_port_open 8786; then
            repair_dask
        fi

        if ! is_port_open 3000; then
            repair_openwebui
        fi

        success "✅ Reparo rápido concluído!"
    fi
}

full_repair() {
    section "🔄 Reparo Completo"

    warn "Esta opção irá reparar TODOS os componentes do sistema."
    if confirm_operation "Continuar com o reparo completo?"; then

        log "Executando reparo completo..."

        # Reparos em ordem de dependência
        repair_python_env
        echo
        repair_python_deps
        echo
        repair_config
        echo
        repair_docker_service
        echo
        repair_containers
        echo
        repair_ollama
        echo
        repair_openwebui
        echo
        repair_dask
        echo
        repair_nginx
        echo
        clean_old_logs
        echo
        clean_temp_files
        echo
        free_disk_space

        success "✅ Reparo completo concluído!"
    fi
}

detailed_diagnostic() {
    section "🔍 Diagnóstico Detalhado"

    subsection "Informações do Sistema"
    echo "Sistema Operacional: $(detect_os)"
    echo "Distribuição: $(detect_linux_distro)"
    echo "Kernel: $(uname -r)"
    echo "Arquitetura: $(uname -m)"
    echo "Hostname: $(hostname)"
    echo "Usuário: $(whoami)"
    echo

    subsection "Recursos do Sistema"
    echo "CPU: $(nproc) cores"
    echo "Memória Total: $(free -h | awk 'NR==2{print $2}')"
    echo "Memória Usada: $(free -h | awk 'NR==2{print $3}')"
    echo "Disco Total: $(df -h . | awk 'NR==2{print $2}')"
    echo "Disco Usado: $(df -h . | awk 'NR==2{print $3}')"
    echo "Disco Livre: $(df -h . | awk 'NR==2{print $4}')"
    echo

    subsection "Processos Relacionados"
    echo "Processos Python: $(pgrep -f python | wc -l)"
    echo "Processos Dask: $(pgrep -f dask | wc -l)"
    echo "Processos Ollama: $(pgrep -f ollama | wc -l)"
    echo "Containers Docker: $(docker ps 2>/dev/null | wc -l)"
    echo

    subsection "Portas em Uso"
    if command_exists netstat; then
        netstat -tln | grep -E ':(8786|8787|11434|3000|80)' || echo "Nenhuma porta relevante em uso"
    elif command_exists ss; then
        ss -tln | grep -E ':(8786|8787|11434|3000|80)' || echo "Nenhuma porta relevante em uso"
    fi
    echo

    subsection "Configurações Atuais"
    if [ -f "$CONFIG_FILE" ]; then
        echo "Arquivo de configuração encontrado:"
        grep -v '^#' "$CONFIG_FILE" | grep -v '^$' | head -10
    else
        echo "Arquivo de configuração não encontrado"
    fi
}

# --- Script Principal ---
main() {
    show_banner

    # Executar análise inicial
    local issues_found=0
    analyze_system
    issues_found=$?

    echo
    if [ "$issues_found" -gt 0 ]; then
        warn "Problemas detectados. Iniciando modo de reparo..."
    else
        success "Sistema saudável! Você pode executar diagnósticos detalhados se desejar."
    fi

    echo
    while true; do
        show_repair_options

        local choice
        read -p "Digite sua opção (0-15): " choice

        case $choice in
            1) repair_python_env ;;
            2) repair_python_deps ;;
            3) repair_config ;;
            4) repair_docker_service ;;
            5) repair_containers ;;
            6) repair_ollama ;;
            7) repair_openwebui ;;
            8) repair_dask ;;
            9) repair_nginx ;;
            10) clean_old_logs ;;
            11) clean_temp_files ;;
            12) free_disk_space ;;
            13) quick_repair ;;
            14) full_repair ;;
            15) detailed_diagnostic ;;
            0)
                info "Reparo cancelado."
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
        show_banner
    done
}

# Executa o script principal
main
