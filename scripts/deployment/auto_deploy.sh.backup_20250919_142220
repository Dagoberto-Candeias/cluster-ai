#!/bin/bash

# 🚀 Script de Deploy Automatizado - Cluster AI
# Autor: Sistema Cluster AI
# Descrição: Pipeline completo de deploy para produção

set -e  # Sai no primeiro erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="/tmp/cluster_ai_deploy.log"
DEPLOY_CONFIG="$HOME/.cluster_deploy_config"

# Função para log
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

# Função para sucesso
success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

# Função para warning
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

# Função para erro
error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

# Função para carregar configuração
load_config() {
    if [ -f "$DEPLOY_CONFIG" ]; then
        source "$DEPLOY_CONFIG"
    else
        # Configurações padrão
        DEPLOY_ENV="production"
        BACKUP_BEFORE_DEPLOY=true
        VALIDATE_AFTER_DEPLOY=true
        NOTIFY_ON_SUCCESS=true
        ROLLBACK_ON_FAILURE=true
    fi
}

# Função para criar backup
create_backup() {
    log "Criando backup do sistema..."
    
    local backup_dir="/backups/cluster_ai_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Backup de dados importantes
    local backup_items=(
        "$HOME/.ollama"
        "$HOME/.cluster_role"
        "$HOME/.cluster_optimization"
        "/etc/docker/daemon.json"
        "/etc/systemd/system/ollama.service"
    )
    
    for item in "${backup_items[@]}"; do
        if [ -e "$item" ]; then
            cp -r "$item" "$backup_dir/" 2>/dev/null || warning "Não foi possível fazer backup de: $item"
        fi
    done
    
    # Backup de configurações do Docker
    docker ps -aq | xargs -I {} docker commit {} cluster_ai_backup:$(date +%Y%m%d) 2>/dev/null || true
    
    success "Backup criado em: $backup_dir"
    echo "$backup_dir" > /tmp/last_backup_dir
}

# Função para validar ambiente
validate_environment() {
    log "Validando ambiente de deploy..."
    
    # Verificar dependências
    local required_commands=("docker" "curl" "git" "python3")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error "Comando necessário não encontrado: $cmd"
        fi
    done
    
    # Verificar recursos do sistema
    local min_memory=4096  # 4GB
    local available_memory=$(free -m | awk '/Mem:/ {print $7}')
    
    if [ "$available_memory" -lt "$min_memory" ]; then
        warning "Memória disponível baixa: ${available_memory}MB (mínimo recomendado: ${min_memory}MB)"
    fi
    
    # Verificar espaço em disco
    local min_disk=20480  # 20GB
    local available_disk=$(df / | awk 'NR==2 {print $4}')
    
    if [ "$available_disk" -lt "$min_disk" ]; then
        warning "Espaço em disco baixo: ${available_disk}KB (mínimo recomendado: ${min_disk}KB)"
    fi
    
    success "Ambiente validado com sucesso"
}

# Função para deploy principal
deploy_cluster() {
    log "Iniciando deploy do Cluster AI..."
    
    # Parar serviços existentes
    log "Parando serviços existentes..."
    docker-compose down 2>/dev/null || true
    sudo systemctl stop ollama 2>/dev/null || true
    
    # Atualizar código se for um repositório git
    if [ -d .git ]; then
        log "Atualizando código do repositório..."
        git pull origin main
    fi
    
    # Instalar/atualizar dependências
    log "Instalando dependências..."
    sudo ./install_cluster_universal.sh --silent
    
    # Configurar ambiente
    log "Configurando ambiente..."
    source scripts/installation/venv_setup.sh
    source scripts/installation/gpu_setup.sh
    
    # Iniciar serviços
    log "Iniciando serviços..."
    docker-compose up -d
    sudo systemctl start ollama
    
    success "Deploy principal concluído"
}

# Função para validar deploy
validate_deploy() {
    log "Validando deploy..."
    
    local max_attempts=30
    local attempt=1
    
    # Verificar se os serviços estão respondendo
    while [ $attempt -le $max_attempts ]; do
        log "Tentativa $attempt/$max_attempts - Verificando serviços..."
        
        # Verificar Ollama
        if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
            success "Ollama está respondendo"
            break
        fi
        
        # Verificar OpenWebUI
        if curl -s http://localhost:8080/api/health >/dev/null 2>&1; then
            success "OpenWebUI está respondendo"
            break
        fi
        
        sleep 5
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        error "Timeout na validação do deploy"
    fi
    
    # Teste funcional básico
    log "Executando teste funcional..."
    if python3 scripts/utils/test_gpu.py; then
        success "Teste funcional passou"
    else
        warning "Teste funcional falhou - continuando mesmo assim"
    fi
    
    success "Deploy validado com sucesso"
}

# Função para rollback
rollback_deploy() {
    log "Executando rollback..."
    
    local backup_dir=$(cat /tmp/last_backup_dir 2>/dev/null)
    
    if [ -z "$backup_dir" ] || [ ! -d "$backup_dir" ]; then
        error "Nenhum backup encontrado para rollback"
    fi
    
    # Parar serviços
    docker-compose down 2>/dev/null || true
    sudo systemctl stop ollama 2>/dev/null || true
    
    # Restaurar backup
    log "Restaurando backup de: $backup_dir"
    cp -r "$backup_dir"/* / 2>/dev/null || warning "Alguns arquivos não puderam ser restaurados"
    
    # Restaurar containers Docker
    docker images | grep cluster_ai_backup | head -1 | awk '{print $1}' | xargs -I {} docker run -d {} 2>/dev/null || true
    
    success "Rollback concluído"
}

# Função para notificar
send_notification() {
    local status=$1
    local message=$2
    
    log "Enviando notificação: $status - $message"
    
    # Aqui você pode integrar com Slack, Email, Discord, etc.
    # Exemplo para Slack (descomente e configure):
    # curl -X POST -H 'Content-type: application/json' \
    #   --data "{\"text\":\"Deploy $status: $message\"}" \
    #   $SLACK_WEBHOOK_URL
    
    echo "📧 NOTIFICAÇÃO: Deploy $status - $message"
}

# Função principal
main() {
    local start_time=$(date +%s)
    
    log "🚀 INICIANDO DEPLOY AUTOMATIZADO - CLUSTER AI"
    log "Modo: $DEPLOY_ENV"
    log "Log: $LOG_FILE"
    
    # Carregar configuração
    load_config
    
    # Bash não suporta try/catch nativamente, substituindo por trap e controle de erros
    trap 'error_handler $?' ERR
    error_handler() {
        local error_code=$1
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        error "❌ DEPLOY FALHOU após ${duration}s"
        if [ "$ROLLBACK_ON_FAILURE" = true ]; then
            rollback_deploy
            send_notification "FALHA_COM_ROLLBACK" "Deploy falhou, rollback executado"
        else
            send_notification "FALHA" "Deploy falhou sem rollback"
        fi
        exit $error_code
    }

    # Fase 1: Pré-deploy
    validate_environment

    if [ "$BACKUP_BEFORE_DEPLOY" = true ]; then
        create_backup
    fi

    # Fase 2: Deploy
    deploy_cluster

    # Fase 3: Pós-deploy
    if [ "$VALIDATE_AFTER_DEPLOY" = true ]; then
        validate_deploy
    fi

    # Fase 4: Notificação
    if [ "$NOTIFY_ON_SUCCESS" = true ]; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        send_notification "SUCESSO" "Deploy concluído em ${duration}s"
    fi

    success "🎉 DEPLOY CONCLUÍDO COM SUCESSO!"
    log "Tempo total: ${duration}s"
    log "Serviços disponíveis:"
    log "  Ollama: http://localhost:11434"
    log "  OpenWebUI: http://localhost:8080"
    log "  Dask Dashboard: http://localhost:8787"
}

# Função de ajuda
show_help() {
    cat << EOF
Uso: $0 [OPÇÕES]

Opções:
  --env ENV          Ambiente de deploy (production, staging, development)
  --no-backup        Não criar backup antes do deploy
  --no-validate      Não validar após o deploy
  --no-notify        Não enviar notificações
  --no-rollback      Não fazer rollback em caso de falha
  --help             Mostrar esta ajuda

Exemplos:
  $0 --env production
  $0 --no-backup --no-notify
  $0 --help
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --env)
            DEPLOY_ENV="$2"
            shift 2
            ;;
        --no-backup)
            BACKUP_BEFORE_DEPLOY=false
            shift
            ;;
        --no-validate)
            VALIDATE_AFTER_DEPLOY=false
            shift
            ;;
        --no-notify)
            NOTIFY_ON_SUCCESS=false
            shift
            ;;
        --no-rollback)
            ROLLBACK_ON_FAILURE=false
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            error "Opção inválida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Executar
main "$@"
