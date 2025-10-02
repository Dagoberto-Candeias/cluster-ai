#!/bin/bash
# =============================================================================
# Cluster AI - Auto Start Services
# =============================================================================
# Inicialização automática de serviços do Cluster AI com retry e logging
#
# Projeto: Cluster AI - Sistema Universal de IA Distribuída
# URL: https://github.com/your-org/cluster-ai
#
# Autor: Cluster AI Team
# Data: 2025-01-27
# Versão: 1.0.0
# Arquivo: auto_start_services.sh
# Licença: MIT
# =============================================================================

# Configurações de segurança e robustez
set -euo pipefail  # Exit on error, undefined vars, pipe failures
umask 027         # Secure file permissions
IFS=$'\n\t'       # Safe IFS for word splitting

# Carregar biblioteca comum se disponível
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Carregar common.sh se disponível
if [[ -r "${PROJECT_ROOT}/scripts/lib/common.sh" ]]; then
    # shellcheck disable=SC1091
    source "${PROJECT_ROOT}/scripts/lib/common.sh"
fi

# Fallback para funções essenciais se common.sh não estiver disponível
if ! command -v log >/dev/null 2>&1; then
    log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [LOG] $*"; }
fi
if ! command -v error >/dev/null 2>&1; then
    error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $*" >&2; }
fi
if ! command -v success >/dev/null 2>&1; then
    success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS] $*"; }
fi

# Configurações globais
readonly LOG_DIR="${PROJECT_ROOT}/logs"
readonly BACKUP_DIR="${PROJECT_ROOT}/backups"
readonly CONFIG_FILE="${PROJECT_ROOT}/cluster.yaml"
readonly SERVICES_LOG="${LOG_DIR}/services_startup.log"
readonly MAX_RETRIES=5
readonly RETRY_DELAY=5  # segundos

# Criar diretórios necessários
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

# Logging setup
readonly LOG_FILE="${LOG_DIR}/$(basename "${BASH_SOURCE[0]}" .sh).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Trap para cleanup
cleanup() {
    local exit_code=$?
    # Cleanup code here if needed
    exit $exit_code
}
trap cleanup EXIT INT TERM

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly GRAY='\033[0;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Fallback para command_exists se não estiver disponível
if ! command -v command_exists >/dev/null 2>&1; then
    command_exists() { command -v "$1" >/dev/null 2>&1; }
fi

# Garantir permissões seguras no diretório de logs
chmod 750 "$LOG_DIR" 2>/dev/null || true

# =============================================================================
# FUNÇÕES AUXILIARES
# =============================================================================

# Exibir uso do script
usage() {
    cat << EOF
Uso: $0 [OPÇÕES]

Inicializa automaticamente os serviços do Cluster AI com retry e logging.

OPÇÕES:
    -h, --help          Exibir esta ajuda
    -v, --verbose       Modo verboso
    -d, --dry-run       Executar sem fazer alterações
    --version           Exibir versão

EXEMPLOS:
    $0                    # Inicialização normal
    $0 --verbose         # Modo verboso
    $0 --dry-run         # Teste sem iniciar serviços

Para mais informações, consulte: https://github.com/your-org/cluster-ai
EOF
}

# Processar argumentos da linha de comando
parse_args() {
    VERBOSE=false
    DRY_RUN=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            --version)
                echo "$(basename "$0") v1.0.0"
                exit 0
                ;;
            *)
                error "Opção desconhecida: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Verificar dependências
check_dependencies() {
    local deps=("docker" "curl")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Dependências faltando: ${missing[*]}"
        exit 1
    fi
}

# Função para log detalhado (apenas para arquivo)
log_service() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" >> "$SERVICES_LOG"
}

# Função para verificar se serviço está rodando
is_service_running() {
    local check_command="$1"
    eval "$check_command" >/dev/null 2>&1
}

# Função para iniciar serviço com retry
start_service() {
    local service_name="$1"
    local start_command="$2"
    local check_command="$3"
    local attempt=1

    printf "  %-25s" "$service_name"

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}⚠ Modo dry-run - não iniciado${NC}"
        log_service "$service_name: DRY_RUN - not started"
        return 0
    fi

    while [[ $attempt -le $MAX_RETRIES ]]; do
        if [[ "$VERBOSE" == true ]]; then
            log "Tentativa $attempt/$MAX_RETRIES para iniciar $service_name"
        fi

        eval "$start_command" >/dev/null 2>&1
        sleep 3

        if is_service_running "$check_command"; then
            echo -e "${GREEN}✓ Iniciado${NC}"
            log_service "$service_name: STARTED on attempt $attempt"
            return 0
        else
            log_service "$service_name: FAILED_TO_VERIFY on attempt $attempt"
        fi

        if [[ $attempt -lt $MAX_RETRIES ]]; then
            echo -e "${YELLOW}Falhou. Tentando novamente em ${RETRY_DELAY}s... (${attempt}/${MAX_RETRIES})${NC}"
            sleep "$RETRY_DELAY"
        fi
        ((attempt++))
    done

    echo -e "${RED}✗ Falha após $MAX_RETRIES tentativas${NC}"
    log_service "$service_name: FAILED after $MAX_RETRIES attempts"
    return 1
}

# =============================================================================
# SERVIÇOS A SEREM GERENCIADOS
# =============================================================================

# Array de serviços com suas configurações
declare -a SERVICES=(
    "Dashboard Model Registry:${PROJECT_ROOT}/.dashboard_model_registry.pid:5002"
    "Web Dashboard Frontend::0"
    "Backend API::0"
    "Prometheus::0"
    "OpenWebUI::0"
)

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    # Processar argumentos
    parse_args "$@"

    # Verificações iniciais
    check_dependencies

    # Log de início
    log "Iniciando $(basename "$0")"
    if [[ "$DRY_RUN" == true ]]; then
        log "MODO DRY-RUN: Nenhuma alteração será feita"
    fi

    echo -e "\n${BOLD}${CYAN}🚀 INICIANDO SERVIÇOS AUTOMÁTICOS - CLUSTER AI${NC}\n"

    # Inicializar log de serviços
    log_service "=== INICIANDO INICIALIZAÇÃO DE SERVIÇOS ==="

    # 1. Dashboard Model Registry
    start_dashboard_service

    # 2. Web Dashboard Frontend
    start_docker_service "Web Dashboard Frontend" "frontend"

    # 3. Backend API
    start_docker_service "Backend API" "backend"

    # 4. Prometheus
    if command_exists docker && docker info >/dev/null 2>&1; then
        start_docker_service "Prometheus" "prometheus"
    fi

    # 5. OpenWebUI
    if command_exists docker && docker info >/dev/null 2>&1; then
        start_docker_service "OpenWebUI" "open-webui"
    fi

    # 6. Ollama
    start_ollama_service

    # Verificar status de outros serviços
    check_additional_services

    # Log de conclusão
    success "$(basename "$0") concluído com sucesso"
    echo -e "\n${BOLD}${GREEN}✅ INICIALIZAÇÃO AUTOMÁTICA CONCLUÍDA${NC}"
    echo -e "${GRAY}Log detalhado: $SERVICES_LOG${NC}"

    log_service "=== SERVIÇOS INICIADOS COM SUCESSO ==="
}

# Função para iniciar Dashboard Model Registry
start_dashboard_service() {
    local service_name="Dashboard Model Registry"
    local pid_file="${PROJECT_ROOT}/.dashboard_model_registry.pid"
    local port=5002

    # Finaliza instâncias anteriores na mesma porta
    pkill -f "python app.py" || true

    # Inicia o serviço e salva o PID
    local start_cmd="cd '${PROJECT_ROOT}' && source cluster-ai-env/bin/activate && cd ai-ml/model-registry/dashboard && nohup python app.py > dashboard.log 2>&1 & echo \$! > '${pid_file}'"
    local check_cmd="sleep 5 && curl -fsS --max-time 5 http://127.0.0.1:${port}/health >/dev/null"

    if ! is_service_running "$check_cmd"; then
        start_service "$service_name" "$start_cmd" "$check_cmd"
    else
        printf "  %-25s" "$service_name"
        echo -e "${GREEN}✓ Já rodando${NC}"
    fi
}

# Função genérica para iniciar serviços Docker
start_docker_service() {
    local service_name="$1"
    local container_name="$2"

    local start_cmd="cd '${PROJECT_ROOT}' && docker compose up -d ${container_name}"
    local check_cmd="docker ps | grep -q ${container_name}"

    if ! is_service_running "$check_cmd"; then
        start_service "$service_name" "$start_cmd" "$check_cmd"
    else
        printf "  %-25s" "$service_name"
        echo -e "${GREEN}✓ Já rodando${NC}"
    fi
}

# Função para iniciar Ollama
start_ollama_service() {
    if command_exists ollama; then
        if ! pgrep -f "ollama" >/dev/null 2>&1; then
            printf "  %-25s" "Ollama"
            if [[ "$DRY_RUN" == true ]]; then
                echo -e "${YELLOW}⚠ Modo dry-run - não iniciado${NC}"
                log_service "Ollama: DRY_RUN - not started"
                return 0
            fi

            nohup ollama serve > "${LOG_DIR}/ollama.log" 2>&1 &
            sleep 5
            if pgrep -f "ollama" >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Iniciado${NC}"
                log_service "Ollama: STARTED"
            else
                echo -e "${RED}✗ Falha${NC}"
                log_service "Ollama: FAILED_TO_START"
            fi
        else
            printf "  %-25s" "Ollama"
            echo -e "${GREEN}✓ Já rodando${NC}"
        fi
    else
        printf "  %-25s" "Ollama"
        echo -e "${YELLOW}⚠️ Não instalado${NC}"
    fi
}

# Verificar status de serviços adicionais
check_additional_services() {
    echo -e "\n${BOLD}${BLUE}STATUS DE OUTROS SERVIÇOS${NC}"

    # Redis
    if docker ps | grep -q redis; then
        printf "  %-25s" "Redis"
        echo -e "${GREEN}✓ Rodando${NC}"
    else
        printf "  %-25s" "Redis"
        echo -e "${YELLOW}⚠️ Não rodando${NC}"
    fi

    # PostgreSQL
    if docker ps | grep -q postgres; then
        printf "  %-25s" "PostgreSQL"
        echo -e "${GREEN}✓ Rodando${NC}"
    else
        printf "  %-25s" "PostgreSQL"
        echo -e "${YELLOW}⚠️ Não rodando${NC}"
    fi

    # Ollama (verificação adicional)
    if pgrep -f "ollama" >/dev/null 2>&1; then
        printf "  %-25s" "Ollama"
        echo -e "${GREEN}✓ Rodando${NC}"
    else
        printf "  %-25s" "Ollama"
        echo -e "${YELLOW}⚠️ Não rodando${NC}"
    fi
}

# =============================================================================
# EXECUÇÃO
# =============================================================================

# Executar função principal se script for chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi

# =============================================================================
# FIM DO SCRIPT
# =============================================================================
