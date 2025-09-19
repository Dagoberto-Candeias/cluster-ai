#!/bin/bash
# Test Worker Provisioning Script
# Testa o provisionamento automático de workers

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Verificar se estamos no diretório correto
if [[ ! -f "manager.sh" ]] || [[ ! -f "requirements.txt" ]]; then
    log_error "Este script deve ser executado no diretório raiz do projeto Cluster AI"
    exit 1
fi

# Ativar ambiente virtual
if [[ -d "venv" ]]; then
    source venv/bin/activate
    log_success "Ambiente virtual ativado"
else
    log_error "Ambiente virtual não encontrado. Execute ./scripts/auto_init_project.sh primeiro"
    exit 1
fi

echo
echo "🧪 TESTE DE PROVISIONAMENTO DE WORKERS"
echo "====================================="
echo

# Testar provisionamento de todos os workers
log_info "Testando provisionamento automático de todos os workers..."
if python3 scripts/utils/auto_worker_provisioning.py provision; then
    log_success "Provisionamento automático executado"
else
    log_warning "Provisionamento automático encontrou alguns problemas"
fi

echo

# Verificar status dos workers
log_info "Verificando status dos workers provisionados..."
if python3 scripts/utils/auto_worker_provisioning.py status; then
    log_success "Verificação de status concluída"
else
    log_warning "Falha ao verificar status dos workers"
fi

echo
log_info "Para provisionar um worker específico, use:"
echo "  python3 scripts/utils/auto_worker_provisioning.py provision --worker <hostname> --ip <ip> --port <port> --user <user>"
echo
log_info "Para verificar o status de um worker:"
echo "  python3 scripts/utils/auto_worker_provisioning.py status"
echo
