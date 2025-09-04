#!/bin/bash
# Script de Deploy para Cluster AI
# Suporte a múltiplos ambientes e estratégias de deploy

set -euo pipefail

# =============================================================================
# CONFIGURAÇÃO
# =============================================================================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_DIR="${PROJECT_ROOT}/scripts/deployment"
ENVIRONMENT="${1:-development}"
DEPLOY_STRATEGY="${2:-rolling}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configurações por ambiente
declare -A ENV_CONFIGS=(
    ["development,host"]="localhost"
    ["development,user"]="dev"
    ["development,path"]="/opt/cluster-ai-dev"
    ["staging,host"]="staging.cluster.ai"
    ["staging,user"]="deploy"
    ["staging,path"]="/opt/cluster-ai-staging"
    ["production,host"]="cluster.ai"
    ["production,user"]="deploy"
    ["production,path"]="/opt/cluster-ai"
)

# =============================================================================
# FUNÇÕES UTILITÁRIAS
# =============================================================================

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

section() {
    echo
    echo -e "${PURPLE}================================================================================${NC}"
    echo -e "${PURPLE}  $1${NC}"
    echo -e "${PURPLE}================================================================================${NC}"
    echo
}

# =============================================================================
# VALIDAÇÃO
# =============================================================================

validate_environment() {
    section "VALIDAÇÃO DO AMBIENTE"

    # Verificar se o ambiente é suportado
    if [[ ! "${ENV_CONFIGS[${ENVIRONMENT},host]+_}" ]]; then
        error "Ambiente '${ENVIRONMENT}' não é suportado. Ambientes disponíveis: development, staging, production"
    fi

    # Verificar dependências
    local deps=("rsync" "ssh" "git")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "Dependência '$dep' não encontrada. Instale-a antes de continuar."
        fi
    done

    # Verificar se estamos em um repositório git limpo
    if [[ -n $(git status --porcelain) ]]; then
        warning "Repositório git não está limpo. Mudanças não commitadas serão ignoradas."
        read -p "Continuar mesmo assim? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    success "Validação do ambiente concluída"
}

# =============================================================================
# PREPARAÇÃO DO DEPLOY
# =============================================================================

prepare_deploy() {
    section "PREPARAÇÃO DO DEPLOY"

    # Criar diretório temporário para o deploy
    DEPLOY_TMP_DIR=$(mktemp -d)
    log "Diretório temporário criado: $DEPLOY_TMP_DIR"

    # Fazer checkout limpo do código
    log "Preparando código para deploy..."
    git archive --format=tar --output="${DEPLOY_TMP_DIR}/cluster-ai.tar" HEAD
    cd "$DEPLOY_TMP_DIR"
    tar -xf cluster-ai.tar
    rm cluster-ai.tar

    # Instalar dependências Python
    if [ -f "requirements.txt" ]; then
        log "Instalando dependências Python..."
        python3 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip
        pip install -r requirements.txt
        deactivate
    fi

    # Configurar permissões
    find . -name "*.sh" -exec chmod +x {} \;

    success "Preparação do deploy concluída"
}

# =============================================================================
# ESTRATÉGIAS DE DEPLOY
# =============================================================================

deploy_rolling() {
    section "DEPLOY ROLLING UPDATE"

    local host="${ENV_CONFIGS[${ENVIRONMENT},host]}"
    local user="${ENV_CONFIGS[${ENVIRONMENT},user]}"
    local path="${ENV_CONFIGS[${ENVIRONMENT},path]}"

    log "Iniciando deploy rolling para ${ENVIRONMENT}..."

    # Criar backup
    log "Criando backup da versão atual..."
    ssh "${user}@${host}" "cd '${path}' && tar -czf backup_$(date +%Y%m%d_%H%M%S).tar.gz ."

    # Sincronizar arquivos
    log "Sincronizando arquivos..."
    rsync -avz --delete --exclude='.git' --exclude='__pycache__' \
        --exclude='*.pyc' --exclude='.pytest_cache' \
        "${DEPLOY_TMP_DIR}/" "${user}@${host}:${path}/"

    # Executar migrações se necessário
    if ssh "${user}@${host}" "[ -f '${path}/scripts/migration.sh' ]"; then
        log "Executando migrações..."
        ssh "${user}@${host}" "cd '${path}' && bash scripts/migration.sh"
    fi

    # Reiniciar serviços
    log "Reiniciando serviços..."
    ssh "${user}@${host}" "cd '${path}' && bash scripts/restart_services.sh"

    success "Deploy rolling concluído"
}

deploy_blue_green() {
    section "DEPLOY BLUE-GREEN"

    local host="${ENV_CONFIGS[${ENVIRONMENT},host]}"
    local user="${ENV_CONFIGS[${ENVIRONMENT},user]}"
    local path="${ENV_CONFIGS[${ENVIRONMENT},path]}"

    log "Iniciando deploy blue-green para ${ENVIRONMENT}..."

    # Determinar qual versão está ativa
    local active_version
    active_version=$(ssh "${user}@${host}" "readlink '${path}/current'" | xargs basename)

    local new_version="blue"
    if [ "$active_version" = "blue" ]; then
        new_version="green"
    fi

    local new_path="${path}/${new_version}"

    # Deploy para nova versão
    log "Deploying para versão ${new_version}..."
    ssh "${user}@${host}" "mkdir -p '${new_path}'"
    rsync -avz --delete --exclude='.git' --exclude='__pycache__' \
        --exclude='*.pyc' --exclude='.pytest_cache' \
        "${DEPLOY_TMP_DIR}/" "${user}@${host}:${new_path}/"

    # Executar testes na nova versão
    log "Executando testes na nova versão..."
    ssh "${user}@${host}" "cd '${new_path}' && bash scripts/run_tests.sh"

    # Executar migrações se necessário
    if ssh "${user}@${host}" "[ -f '${new_path}/scripts/migration.sh' ]"; then
        log "Executando migrações..."
        ssh "${user}@${host}" "cd '${new_path}' && bash scripts/migration.sh"
    fi

    # Testar nova versão
    log "Testando nova versão..."
    if ssh "${user}@${host}" "cd '${new_path}' && bash scripts/health_check.sh"; then
        # Switch para nova versão
        log "Alternando para nova versão..."
        ssh "${user}@${host}" "cd '${path}' && ln -sfn '${new_version}' current"

        # Reiniciar serviços
        ssh "${user}@${host}" "cd '${path}/current' && bash scripts/restart_services.sh"

        success "Deploy blue-green concluído - versão ${new_version} ativada"
    else
        error "Testes falharam na nova versão. Deploy abortado."
    fi
}

deploy_canary() {
    section "DEPLOY CANARY"

    local host="${ENV_CONFIGS[${ENVIRONMENT},host]}"
    local user="${ENV_CONFIGS[${ENVIRONMENT},user]}"
    local path="${ENV_CONFIGS[${ENVIRONMENT},path]}"

    log "Iniciando deploy canary para ${ENVIRONMENT}..."

    # Deploy para subconjunto de servidores
    local canary_servers=("server1" "server2")  # Configurar conforme necessário

    for server in "${canary_servers[@]}"; do
        log "Deploying para servidor canary: ${server}..."

        # Sincronizar para servidor canary
        rsync -avz --delete --exclude='.git' --exclude='__pycache__' \
            --exclude='*.pyc' --exclude='.pytest_cache' \
            "${DEPLOY_TMP_DIR}/" "${user}@${server}:${path}/"

        # Executar testes no servidor canary
        if ssh "${user}@${server}" "cd '${path}' && bash scripts/health_check.sh"; then
            success "Servidor canary ${server} aprovado"
        else
            error "Servidor canary ${server} falhou nos testes"
        fi
    done

    # Se todos os servidores canary passarem, continuar com deploy completo
    log "Todos os servidores canary aprovados. Continuando com deploy completo..."
    deploy_rolling

    success "Deploy canary concluído"
}

# =============================================================================
# PÓS-DEPLOY
# =============================================================================

post_deploy() {
    section "PÓS-DEPLOY"

    local host="${ENV_CONFIGS[${ENVIRONMENT},host]}"
    local user="${ENV_CONFIGS[${ENVIRONMENT},user]}"
    local path="${ENV_CONFIGS[${ENVIRONMENT},path]}"

    # Executar verificações finais
    log "Executando verificações finais..."
    if ssh "${user}@${host}" "cd '${path}' && bash scripts/health_check.sh"; then
        success "Verificações de saúde passaram"
    else
        warning "Algumas verificações de saúde falharam"
    fi

    # Limpar backups antigos (manter apenas os últimos 5)
    log "Limpando backups antigos..."
    ssh "${user}@${host}" "cd '${path}' && ls -t backup_*.tar.gz | tail -n +6 | xargs -r rm"

    # Enviar notificações
    log "Enviando notificações..."
    # Adicionar lógica de notificação aqui

    success "Pós-deploy concluído"
}

# =============================================================================
# ROLLBACK
# =============================================================================

rollback() {
    section "ROLLBACK"

    local host="${ENV_CONFIGS[${ENVIRONMENT},host]}"
    local user="${ENV_CONFIGS[${ENVIRONMENT},user]}"
    local path="${ENV_CONFIGS[${ENVIRONMENT},path]}"

    log "Iniciando rollback para ${ENVIRONMENT}..."

    # Encontrar último backup
    local latest_backup
    latest_backup=$(ssh "${user}@${host}" "cd '${path}' && ls -t backup_*.tar.gz | head -1")

    if [ -z "$latest_backup" ]; then
        error "Nenhum backup encontrado para rollback"
    fi

    log "Restaurando backup: ${latest_backup}"

    # Restaurar backup
    ssh "${user}@${host}" "cd '${path}' && tar -xzf '${latest_backup}'"

    # Reiniciar serviços
    ssh "${user}@${host}" "cd '${path}' && bash scripts/restart_services.sh"

    success "Rollback concluído"
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================

main() {
    log "Iniciando deploy para ambiente: ${ENVIRONMENT}"
    log "Estratégia: ${DEPLOY_STRATEGY}"

    # Validar entrada
    if [ $# -lt 1 ] || [ $# -gt 2 ]; then
        echo "Uso: $0 <environment> [strategy]"
        echo ""
        echo "Ambientes: development, staging, production"
        echo "Estratégias: rolling (padrão), blue-green, canary"
        echo ""
        echo "Exemplos:"
        echo "  $0 development"
        echo "  $0 staging blue-green"
        echo "  $0 production canary"
        exit 1
    fi

    # Executar validações
    validate_environment

    # Preparar deploy
    prepare_deploy

    # Executar deploy baseado na estratégia
    case "$DEPLOY_STRATEGY" in
        "rolling")
            deploy_rolling
            ;;
        "blue-green")
            deploy_blue_green
            ;;
        "canary")
            deploy_canary
            ;;
        *)
            error "Estratégia '${DEPLOY_STRATEGY}' não suportada"
            ;;
    esac

    # Pós-deploy
    post_deploy

    # Limpeza
    log "Limpando arquivos temporários..."
    rm -rf "$DEPLOY_TMP_DIR"

    success "Deploy concluído com sucesso!"
    info "Ambiente: ${ENVIRONMENT}"
    info "Estratégia: ${DEPLOY_STRATEGY}"
    info "Data/Hora: $(date)"
}

# Executar
main "$@"
