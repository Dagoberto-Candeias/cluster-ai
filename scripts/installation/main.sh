#!/bin/bash
# -*- coding: utf-8 -*-
#
# Cluster AI - Main Installation Orchestrator
# Orquestrador principal de instalação do Cluster AI
#
# Projeto: Cluster AI
# Autor: Sistema de consolidação automática
# Data: 2024-12-19
# Versão: 1.0.0
#
# Descrição:
#   Script orquestrador que coordena a instalação de todos os componentes
#   do Cluster AI. Gerencia dependências, ordem de instalação e
#   configurações específicas para diferentes ambientes.
#
# Uso:
#   ./scripts/installation/main.sh [opções]
#
# Dependências:
#   - bash
#   - python3
#   - curl, wget
#   - sudo
#
# Changelog:
#   v1.0.0 - 2024-12-19: Criação inicial com funcionalidades completas
#
# ============================================================================

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretório base
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$PROJECT_ROOT/logs"
MAIN_LOG="$LOG_DIR/main_install.log"

# Configurações
INSTALLATION_ORDER=(
    "pre_install_check"
    "setup_dependencies"
    "setup_python_env"
    "setup_docker"
    "setup_ollama"
    "setup_openwebui"
    "setup_dask"
    "setup_monitoring"
    "setup_security"
    "setup_nginx"
    "setup_firewall"
)

# Arrays para controle
COMPLETED_STEPS=()
FAILED_STEPS=()

# Funções utilitárias
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Função para verificar se script existe e é executável
check_script() {
    local script=$1

    if [ -f "$script" ] && [ -x "$script" ]; then
        return 0
    fi

    return 1
}

# Função para executar passo de instalação
execute_step() {
    local step=$1
    local script_path="scripts/installation/${step}.sh"

    log_info "Executando passo: $step"

    if check_script "$script_path"; then
        bash "$script_path" >> "$MAIN_LOG" 2>&1
        if [ $? -eq 0 ]; then
            COMPLETED_STEPS+=("$step")
            log_success "Passo $step concluído"
            return 0
        fi
    else
        log_warning "Script $script_path não encontrado ou não executável"
    fi

    log_error "Falha no passo $step"
    FAILED_STEPS+=("$step")
    return 1
}

# Função para verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."

    local missing_prereqs=()

    # Verificar se estamos em um diretório válido
    if [ ! -f "README.md" ]; then
        missing_prereqs+=("README.md não encontrado - diretório inválido")
    fi

    # Verificar permissões
    if [ ! -w "." ]; then
        missing_prereqs+=("Sem permissão de escrita no diretório atual")
    fi

    # Verificar conexão de internet
    if ! curl -s --connect-timeout 5 "https://www.google.com" > /dev/null 2>&1; then
        log_warning "Sem conexão com a internet - alguns downloads podem falhar"
    fi

    if [ ${#missing_prereqs[@]} -gt 0 ]; then
        log_error "Pré-requisitos não atendidos:"
        printf '  - %s\n' "${missing_prereqs[@]}"
        return 1
    fi

    log_success "Pré-requisitos verificados"
    return 0
}

# Função para configurar ambiente
setup_environment() {
    log_info "Configurando ambiente de instalação..."

    # Criar diretórios necessários
    mkdir -p "$LOG_DIR"
    mkdir -p "$PROJECT_ROOT/models"
    mkdir -p "$PROJECT_ROOT/configs"
    mkdir -p "$PROJECT_ROOT/backups"
    mkdir -p "$PROJECT_ROOT/data"

    # Configurar variáveis de ambiente
    export CLUSTER_AI_ROOT="$PROJECT_ROOT"
    export PATH="$PROJECT_ROOT/scripts:$PATH"

    # Criar arquivo de configuração básico
    if [ ! -f "cluster.conf" ]; then
        cat > "cluster.conf" << 'EOF'
# Cluster AI Configuration
CLUSTER_NAME="cluster-ai"
DASK_SCHEDULER_HOST="localhost"
DASK_SCHEDULER_PORT="8786"
OLLAMA_HOST="localhost"
OLLAMA_PORT="11434"
WEBUI_HOST="localhost"
WEBUI_PORT="3000"
LOG_LEVEL="INFO"
EOF
        log_success "Arquivo de configuração básico criado"
    fi

    log_success "Ambiente configurado"
}

# Função para validar instalação
validate_installation() {
    log_info "Validando instalação..."

    local validation_issues=()

    # Verificar se serviços estão rodando
    if curl -s "http://localhost:3000" > /dev/null 2>&1; then
        log_success "OpenWebUI está acessível"
    else
        validation_issues+=("OpenWebUI não está acessível")
    fi

    if curl -s "http://localhost:8787" > /dev/null 2>&1; then
        log_success "Dask Dashboard está acessível"
    else
        validation_issues+=("Dask Dashboard não está acessível")
    fi

    if curl -s "http://localhost:11434/api/tags" > /dev/null 2>&1; then
        log_success "Ollama API está acessível"
    else
        validation_issues+=("Ollama API não está acessível")
    fi

    if [ ${#validation_issues[@]} -gt 0 ]; then
        log_warning "Problemas de validação detectados:"
        printf '  - %s\n' "${validation_issues[@]}"
        return 1
    fi

    log_success "Instalação validada com sucesso"
    return 0
}

# Função para mostrar status final
show_final_status() {
    log_info "=== STATUS FINAL DA INSTALAÇÃO ==="

    echo "✅ Passos Concluídos:"
    if [ ${#COMPLETED_STEPS[@]} -gt 0 ]; then
        printf '  - %s\n' "${COMPLETED_STEPS[@]}"
    else
        echo "  Nenhum"
    fi

    echo "❌ Passos com Falha:"
    if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
        printf '  - %s\n' "${FAILED_STEPS[@]}"
    else
        echo "  Nenhum"
    fi

    echo "🌐 URLs de Acesso:"
    echo "  - OpenWebUI: http://localhost:3000"
    echo "  - Dask Dashboard: http://localhost:8787"
    echo "  - Ollama API: http://localhost:11434"

    echo "📝 Logs:"
    echo "  - Principal: $MAIN_LOG"
    echo "  - Detalhado: $LOG_DIR/"

    echo "🚀 Próximos Passos:"
    echo "  1. Execute: ./scripts/start_cluster_complete.sh start"
    echo "  2. Acesse: http://localhost:3000"
    echo "  3. Configure modelos: ollama pull llama3:8b"
    echo "  4. Verifique logs: tail -f $LOG_DIR/*.log"
}

# Função para instalar componente específico
install_component() {
    local component=$1

    log_info "Instalando componente específico: $component"

    case $component in
        "dask")
            execute_step "setup_dask"
            ;;
        "ollama")
            execute_step "setup_ollama"
            ;;
        "openwebui")
            execute_step "setup_openwebui"
            ;;
        "monitoring")
            execute_step "setup_monitoring"
            ;;
        "security")
            execute_step "setup_security"
            ;;
        "nginx")
            execute_step "setup_nginx"
            ;;
        "firewall")
            execute_step "setup_firewall"
            ;;
        *)
            log_error "Componente desconhecido: $component"
            return 1
            ;;
    esac
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    # Criar diretório de logs
    mkdir -p "$LOG_DIR"
    touch "$MAIN_LOG"

    local mode="${1:-full}"

    case "$mode" in
        "full")
            log_info "🚀 Iniciando instalação completa do Cluster AI..."

            # Verificações iniciais
            check_prerequisites || exit 1
            setup_environment

            # Executar passos de instalação
            for step in "${INSTALLATION_ORDER[@]}"; do
                execute_step "$step"
            done

            # Validar instalação
            validate_installation

            # Status final
            show_final_status
            ;;
        "component")
            local component="${2:-}"
            if [ -z "$component" ]; then
                log_error "Especifique um componente para instalar"
                echo "Componentes disponíveis: dask, ollama, openwebui, monitoring, security, nginx, firewall"
                exit 1
            fi
            install_component "$component"
            ;;
        "validate")
            validate_installation
            ;;
        "help"|*)
            echo "Cluster AI - Main Installation Orchestrator"
            echo ""
            echo "Uso: $0 [modo] [componente]"
            echo ""
            echo "Modos:"
            echo "  full          - Instalação completa (padrão)"
            echo "  component     - Instalar componente específico"
            echo "  validate      - Validar instalação existente"
            echo "  help          - Mostra esta mensagem"
            echo ""
            echo "Componentes (para modo 'component'):"
            echo "  dask          - Instalar Dask"
            echo "  ollama        - Instalar Ollama"
            echo "  openwebui     - Instalar OpenWebUI"
            echo "  monitoring    - Instalar monitoramento"
            echo "  security      - Instalar configurações de segurança"
            echo "  nginx         - Instalar Nginx"
            echo "  firewall      - Configurar firewall"
            echo ""
            echo "Exemplos:"
            echo "  $0 full"
            echo "  $0 component ollama"
            echo "  $0 validate"
            ;;
    esac
}

# Executar função principal
main "$@"
