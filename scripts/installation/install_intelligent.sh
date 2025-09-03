#!/bin/bash

# 🎯 INSTALAÇÃO INTELIGENTE - Cluster AI
# Sistema avançado de instalação com detecção automática e opções inteligentes

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
DOCKER_COMPOSE_FILE="$PROJECT_ROOT/configs/docker/compose-basic.yml"

# --- Cores para output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Funções auxiliares ---
show_banner() {
    echo
    echo -e "${CYAN}================================================================================${NC}"
    echo -e "${CYAN}                    🚀 INSTALAÇÃO INTELIGENTE - CLUSTER AI 🚀${NC}"
    echo -e "${CYAN}================================================================================${NC}"
    echo
}

detect_installation_type() {
    local install_type="unknown"

    # Detectar se é servidor ou worker
    if [ -f "$CONFIG_FILE" ]; then
        if grep -q "role.*server" "$CONFIG_FILE" 2>/dev/null; then
            install_type="server"
        elif grep -q "role.*worker" "$CONFIG_FILE" 2>/dev/null; then
            install_type="worker"
        fi
    fi

    # Verificar se estamos no Termux (Android)
    if [ -d "/data/data/com.termux" ]; then
        install_type="android_worker"
    fi

    echo "$install_type"
}

check_existing_installation() {
    local install_type=$(detect_installation_type)
    local is_installed=false
    local components=()

    subsection "🔍 Analisando Instalação Existente"

    # Verificar componentes básicos
    if [ -d "$VENV_DIR" ]; then
        is_installed=true
        components+=("Ambiente Virtual Python")
    fi

    if [ -f "$CONFIG_FILE" ]; then
        is_installed=true
        components+=("Arquivo de Configuração")
    fi

    # Verificar Docker
    if command_exists docker && docker ps -a --format '{{.Names}}' | grep -q 'cluster-ai\|open-webui'; then
        is_installed=true
        components+=("Containers Docker")
    fi

    # Verificar Ollama
    if [ -d "$OLLAMA_DIR" ] && [ "$(ls -A $OLLAMA_DIR 2>/dev/null)" ]; then
        is_installed=true
        components+=("Ollama e Modelos")
    fi

    # Verificar OpenWebUI
    if [ -d "$OPENWEBUI_DIR" ] || docker ps -a --format '{{.Names}}' | grep -q 'open-webui'; then
        is_installed=true
        components+=("OpenWebUI")
    fi

    # Verificar serviços em execução
    if pgrep -f "dask\|ollama\|open-webui" >/dev/null 2>&1; then
        is_installed=true
        components+=("Serviços em Execução")
    fi

    if [ "$is_installed" = true ]; then
        echo -e "${YELLOW}⚠️  INSTALAÇÃO DETECTADA${NC}"
        echo
        echo "Tipo de instalação: $(echo $install_type | tr '[:lower:]' '[:upper:]')"
        echo "Componentes encontrados:"
        for component in "${components[@]}"; do
            echo -e "  ✅ $component"
        done
        echo
        return 0
    else
        echo -e "${GREEN}ℹ️  NENHUMA INSTALAÇÃO DETECTADA${NC}"
        echo "Sistema pronto para instalação inicial."
        echo
        return 1
    fi
}

show_installation_options() {
    echo "Opções disponíveis:"
    echo
    echo "1) 🆕 Instalar do Zero (Fresh Install)"
    echo "2) 🔄 Reinstalar (Remove e Instala Novamente)"
    echo "3) 🛠️  Reparar Instalação (Fix Issues)"
    echo "4) 📦 Instalar Componentes Específicos"
    echo "5) 🗑️  Desinstalar (Remove Tudo)"
    echo "6) 📊 Verificar Status da Instalação"
    echo
    echo "0) ❌ Cancelar"
    echo
}

show_repair_options() {
    local install_type=$(detect_installation_type)

    echo "Selecione os componentes para reparar:"
    echo
    echo "🔧 COMPONENTES BÁSICOS:"
    echo "1) Ambiente Virtual Python"
    echo "2) Arquivo de Configuração"
    echo "3) Dependências do Sistema"
    echo

    if [ "$install_type" = "server" ]; then
        echo "🖥️  COMPONENTES DO SERVIDOR:"
        echo "4) Docker e Containers"
        echo "5) Dask Scheduler"
        echo "6) Nginx"
        echo "7) OpenWebUI"
        echo "8) Ollama"
        echo "9) Modelos de IA"
        echo "10) Ollama + Modelos (Completo)"
        echo
    fi

    echo "11) 🔄 Reparar Tudo"
    echo "0) ↩️  Voltar"
    echo
}

show_uninstall_options() {
    local install_type=$(detect_installation_type)

    echo "Selecione os componentes para desinstalar:"
    echo
    echo "🗑️  COMPONENTES PARA REMOVER:"
    echo "1) Ambiente Virtual Python"
    echo "2) Arquivo de Configuração"
    echo "3) Arquivos Temporários"
    echo

    if [ "$install_type" = "server" ]; then
        echo "🖥️  COMPONENTES DO SERVIDOR:"
        echo "4) Parar e Remover Containers Docker"
        echo "5) OpenWebUI"
        echo "6) Ollama e Modelos"
        echo "7) Ollama + Modelos (Completo)"
        echo "8) Configurações do Sistema"
        echo
    fi

    echo "9) 🧹 Limpeza Completa (Remove Tudo)"
    echo "0) ↩️  Voltar"
    echo
}

# --- Funções de Instalação ---
install_fresh() {
    section "🆕 Instalação do Zero"

    warn "Esta opção irá instalar o Cluster AI completamente."
    if confirm_operation "Continuar com a instalação do zero?"; then

        # Instalar dependências básicas
        if [ -f "scripts/installation/setup_dependencies.sh" ]; then
            log "Instalando dependências básicas..."
            bash scripts/installation/setup_dependencies.sh
        fi

        # Configurar Python
        if [ -f "scripts/installation/setup_python_env.sh" ]; then
            log "Configurando ambiente Python..."
            bash scripts/installation/setup_python_env.sh
        fi

        # Instalar Docker se for servidor
        local install_type=$(detect_installation_type)
        if [ "$install_type" = "server" ] && [ -f "scripts/installation/setup_docker.sh" ]; then
            log "Instalando Docker..."
            bash scripts/installation/setup_docker.sh
        fi

        # Instalar Nginx se for servidor
        if [ "$install_type" = "server" ] && [ -f "scripts/installation/setup_nginx.sh" ]; then
            log "Instalando Nginx..."
            bash scripts/installation/setup_nginx.sh
        fi

        success "✅ Instalação do zero concluída!"
    fi
}

reinstall_system() {
    section "🔄 Reinstalação Completa"

    warn "Esta opção irá REMOVER tudo e instalar novamente."
    warn "Todos os dados e configurações serão perdidos!"
    echo

    if confirm_operation "Você tem certeza que deseja fazer uma reinstalação completa?"; then
        # Fazer backup primeiro
        if [ -f "scripts/maintenance/backup_scripts.sh" ]; then
            log "Fazendo backup dos dados importantes..."
            bash scripts/maintenance/backup_scripts.sh
        fi

        # Desinstalar tudo
        if [ -f "scripts/maintenance/uninstall_master.sh" ]; then
            log "Removendo instalação atual..."
            bash scripts/maintenance/uninstall_master.sh --all --force
        fi

        # Instalar do zero
        install_fresh
    fi
}

repair_installation() {
    section "🛠️ Reparo de Instalação"

    while true; do
        show_repair_options

        local choice
        read -p "Digite sua opção: " choice

        case $choice in
            1) repair_python_env ;;
            2) repair_config ;;
            3) repair_dependencies ;;
            4) repair_docker ;;
            5) repair_dask ;;
            6) repair_nginx ;;
            7) repair_openwebui ;;
            8) repair_ollama ;;
            9) repair_models ;;
            10) repair_ollama_full ;;
            11) repair_all ;;
            0) return ;;
            *) error "Opção inválida" ;;
        esac

        echo
        read -p "Pressione Enter para continuar..."
    done
}

uninstall_components() {
    section "🗑️ Desinstalação Seletiva"

    while true; do
        show_uninstall_options

        local choice
        read -p "Digite sua opção: " choice

        case $choice in
            1) uninstall_python_env ;;
            2) uninstall_config ;;
            3) uninstall_temp ;;
            4) uninstall_docker ;;
            5) uninstall_openwebui ;;
            6) uninstall_ollama ;;
            7) uninstall_ollama_full ;;
            8) uninstall_system_config ;;
            9) uninstall_complete ;;
            0) return ;;
            *) error "Opção inválida" ;;
        esac

        echo
        read -p "Pressione Enter para continuar..."
    done
}

# --- Funções de Reparo ---
repair_python_env() {
    subsection "Reparando Ambiente Python"
    if [ -d "$VENV_DIR" ]; then
        rm -rf "$VENV_DIR"
    fi
    bash scripts/installation/setup_python_env.sh
}

repair_config() {
    subsection "Reparando Configuração"
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    # Recriar configuração básica
    create_basic_config
}

repair_dependencies() {
    subsection "Reparando Dependências"
    bash scripts/installation/setup_dependencies.sh
}

repair_docker() {
    subsection "Reparando Docker"
    # Parar containers existentes
    docker stop $(docker ps -q) 2>/dev/null || true
    docker rm $(docker ps -a -q) 2>/dev/null || true
    # Reinstalar
    bash scripts/installation/setup_docker.sh
}

repair_dask() {
    subsection "Reparando Dask"
    pkill -f dask 2>/dev/null || true
    # Reiniciar serviços Dask
    log "Dask será reiniciado na próxima inicialização do cluster"
}

repair_nginx() {
    subsection "Reparando Nginx"
    sudo systemctl stop nginx 2>/dev/null || true
    bash scripts/installation/setup_nginx.sh
}

repair_openwebui() {
    subsection "Reparando OpenWebUI"
    # Parar container existente
    docker stop open-webui 2>/dev/null || true
    docker rm open-webui 2>/dev/null || true
    # Reiniciar
    if [ -f "$DOCKER_COMPOSE_FILE" ]; then
        docker-compose -f "$DOCKER_COMPOSE_FILE" up -d open-webui
    fi
}

repair_ollama() {
    subsection "Reparando Ollama"
    pkill -f ollama 2>/dev/null || true
    # Ollama será reiniciado automaticamente se configurado como serviço
}

repair_models() {
    subsection "Reparando Modelos de IA"
    if [ -f "scripts/ollama/install_additional_models.sh" ]; then
        bash scripts/ollama/install_additional_models.sh
    fi
}

repair_ollama_full() {
    subsection "Reparando Ollama + Modelos (Completo)"
    repair_ollama
    repair_models
}

repair_all() {
    subsection "Reparando Tudo"
    warn "Esta opção irá reparar todos os componentes."
    if confirm_operation "Continuar?"; then
        repair_python_env
        repair_config
        repair_dependencies
        repair_docker
        repair_dask
        repair_nginx
        repair_openwebui
        repair_ollama_full
        success "✅ Todos os componentes reparados!"
    fi
}

# --- Funções de Desinstalação ---
uninstall_python_env() {
    subsection "Removendo Ambiente Python"
    if [ -d "$VENV_DIR" ]; then
        rm -rf "$VENV_DIR"
        success "Ambiente Python removido"
    fi
}

uninstall_config() {
    subsection "Removendo Configuração"
    if [ -f "$CONFIG_FILE" ]; then
        rm -f "$CONFIG_FILE"
        success "Configuração removida"
    fi
}

uninstall_temp() {
    subsection "Removendo Arquivos Temporários"
    rm -rf "$PROJECT_ROOT/__pycache__" 2>/dev/null || true
    rm -rf "$PROJECT_ROOT/.pytest_cache" 2>/dev/null || true
    rm -rf "$PROJECT_ROOT/*.pyc" 2>/dev/null || true
    find "$PROJECT_ROOT" -name "*.log" -mtime +7 -delete 2>/dev/null || true
    success "Arquivos temporários removidos"
}

uninstall_docker() {
    subsection "Removendo Containers Docker"
    docker stop $(docker ps -q) 2>/dev/null || true
    docker rm $(docker ps -a -q) 2>/dev/null || true
    success "Containers Docker removidos"
}

uninstall_openwebui() {
    subsection "Removendo OpenWebUI"
    docker stop open-webui 2>/dev/null || true
    docker rm open-webui 2>/dev/null || true
    rm -rf "$OPENWEBUI_DIR" 2>/dev/null || true
    success "OpenWebUI removido"
}

uninstall_ollama() {
    subsection "Removendo Ollama"
    pkill -f ollama 2>/dev/null || true
    success "Ollama parado"
}

uninstall_ollama_full() {
    subsection "Removendo Ollama + Modelos (Completo)"
    uninstall_ollama
    rm -rf "$OLLAMA_DIR" 2>/dev/null || true
    success "Ollama e modelos removidos"
}

uninstall_system_config() {
    subsection "Removendo Configurações do Sistema"
    # Remover integrações IDE
    rm -rf "$HOME/.vscode/extensions/cluster-ai" 2>/dev/null || true
    rm -rf "$HOME/.config/JetBrains/PyCharm*/options/cluster_ai.xml" 2>/dev/null || true
    success "Configurações do sistema removidas"
}

uninstall_complete() {
    subsection "Limpeza Completa"
    warn "Esta opção irá remover TODOS os componentes!"
    if confirm_operation "Você tem certeza?"; then
        uninstall_python_env
        uninstall_config
        uninstall_temp
        uninstall_docker
        uninstall_openwebui
        uninstall_ollama_full
        uninstall_system_config
        success "✅ Limpeza completa realizada!"
    fi
}

# --- Função para criar configuração básica ---
create_basic_config() {
    subsection "Criando Configuração Básica"

    cat > "$CONFIG_FILE" << EOF
# Configuração Básica do Cluster AI
# Gerado automaticamente em $(date)

# Tipo de instalação
role=$(detect_installation_type)

# Configurações básicas
project_root=$PROJECT_ROOT
venv_dir=$VENV_DIR

# Portas padrão
dask_scheduler_port=8786
dask_dashboard_port=8787
ollama_port=11434
openwebui_port=3000
nginx_port=80

# Configurações de segurança
allow_remote_access=false
enable_ssl=false

EOF

    success "Configuração básica criada: $CONFIG_FILE"
}

# --- Função para verificar status ---
check_installation_status() {
    section "📊 Status da Instalação"

    local install_type=$(detect_installation_type)
    echo "Tipo de instalação: $(echo $install_type | tr '[:lower:]' '[:upper:]')"
    echo

    # Verificar componentes
    subsection "Componentes"

    # Python
    if [ -d "$VENV_DIR" ]; then
        success "Ambiente Virtual Python: OK"
    else
        error "Ambiente Virtual Python: Faltando"
    fi

    # Configuração
    if [ -f "$CONFIG_FILE" ]; then
        success "Arquivo de Configuração: OK"
    else
        error "Arquivo de Configuração: Faltando"
    fi

    # Docker
    if command_exists docker && docker info >/dev/null 2>&1; then
        success "Docker: OK"
    else
        warn "Docker: Não disponível"
    fi

    # Ollama
    if is_port_open 11434; then
        success "Ollama: Em execução"
    else
        warn "Ollama: Parado"
    fi

    # OpenWebUI
    if is_port_open 3000; then
        success "OpenWebUI: Em execução"
    else
        warn "OpenWebUI: Parado"
    fi

    # Dask
    if is_port_open 8786; then
        success "Dask Scheduler: Em execução"
    else
        warn "Dask Scheduler: Parado"
    fi
}

# --- Script Principal ---
main() {
    show_banner

    # Detectar instalação existente
    if check_existing_installation; then
        # Instalação existente detectada
        while true; do
            show_installation_options

            local choice
            read -p "Digite sua opção (0-6): " choice

            case $choice in
                1) install_fresh ;;
                2) reinstall_system ;;
                3) repair_installation ;;
                4) warn "Instalação de componentes específicos - Em desenvolvimento" ;;
                5) uninstall_components ;;
                6) check_installation_status ;;
                0)
                    info "Instalação cancelada."
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
    else
        # Nenhuma instalação detectada - instalar do zero
        info "Nenhuma instalação detectada. Iniciando instalação do zero..."
        echo
        install_fresh
    fi
}

# Executa o script principal
main
