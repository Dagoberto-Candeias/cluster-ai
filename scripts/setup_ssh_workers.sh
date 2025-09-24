#!/bin/bash
# -*- coding: utf-8 -*-
#
# Cluster AI - SSH Workers Setup Script
# Configuração automática de autenticação SSH para workers
#
# Projeto: Cluster AI
# Autor: Sistema de consolidação automática
# Data: 2024-12-19
# Versão: 1.0.0
#
# Descrição:
#   Script para configurar automaticamente a autenticação SSH sem senha
#   para os workers listados no Cluster AI. Gera chaves SSH, distribui
#   chaves públicas e configura known_hosts para comunicação segura.
#
# Uso:
#   ./scripts/setup_ssh_workers.sh [opções]
#
# Dependências:
#   - bash
#   - ssh-keygen
#   - ssh-copy-id
#   - ssh-keyscan
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
SSH_LOG="$LOG_DIR/ssh_setup.log"

# Configurações
SSH_KEY_FILE="$HOME/.ssh/cluster_ai_key"
WORKERS_LIST_FILE="$PROJECT_ROOT/config/workers.conf"
KNOWN_HOSTS_FILE="$HOME/.ssh/known_hosts"

# Arrays para controle
CONFIGURED_WORKERS=()
FAILED_WORKERS=()

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

# Função para verificar dependências
check_dependencies() {
    log_info "Verificando dependências SSH..."

    local missing_deps=()
    local required_commands=(
        "ssh-keygen"
        "ssh-copy-id"
        "ssh-keyscan"
    )

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Dependências SSH faltando: ${missing_deps[*]}"
        log_info "Instale o pacote openssh-client e tente novamente"
        return 1
    fi

    log_success "Dependências SSH verificadas"
    return 0
}

# Função para gerar chaves SSH
generate_ssh_keys() {
    log_info "Gerando chaves SSH..."

    # Criar diretório .ssh se não existir
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # Gerar chave se não existir
    if [ ! -f "$SSH_KEY_FILE" ]; then
        ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_FILE" -N "" -C "Cluster AI Key"
        log_success "Chave SSH gerada: $SSH_KEY_FILE"
    else
        log_info "Chave SSH já existe: $SSH_KEY_FILE"
    fi

    # Configurar permissões
    chmod 600 "$SSH_KEY_FILE"
    chmod 644 "$SSH_KEY_FILE.pub"

    log_success "Chaves SSH configuradas"
}

# Função para ler lista de workers
read_workers_list() {
    log_info "Lendo lista de workers..."

    if [ ! -f "$WORKERS_LIST_FILE" ]; then
        log_error "Arquivo de workers não encontrado: $WORKERS_LIST_FILE"
        log_info "Crie o arquivo $WORKERS_LIST_FILE com a lista de workers (um por linha)"
        log_info "Formato: usuario@host:porta"
        return 1
    fi

    local workers=()
    while IFS= read -r line; do
        # Ignorar linhas vazias e comentários
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        workers+=("$line")
    done < "$WORKERS_LIST_FILE"

    if [ ${#workers[@]} -eq 0 ]; then
        log_error "Nenhum worker encontrado em $WORKERS_LIST_FILE"
        return 1
    fi

    log_success "Encontrados ${#workers[@]} workers"
    echo "${workers[@]}"
}

# Função para configurar worker
configure_worker() {
    local worker=$1
    log_info "Configurando worker: $worker"

    # Extrair host da string worker
    local host=$(echo "$worker" | cut -d'@' -f2 | cut -d':' -f1)

    # Adicionar host ao known_hosts
    if ! ssh-keyscan -H "$host" >> "$KNOWN_HOSTS_FILE" 2>/dev/null; then
        log_warning "Não foi possível adicionar $host ao known_hosts"
    fi

    # Copiar chave pública para o worker
    if ssh-copy-id -i "$SSH_KEY_FILE.pub" -o StrictHostKeyChecking=no "$worker" >> "$SSH_LOG" 2>&1; then
        CONFIGURED_WORKERS+=("$worker")
        log_success "Worker configurado: $worker"
        return 0
    else
        log_error "Falha ao configurar worker: $worker"
        FAILED_WORKERS+=("$worker")
        return 1
    fi
}

# Função para testar conexão SSH
test_ssh_connection() {
    local worker=$1
    log_info "Testando conexão SSH com $worker..."

    if ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$worker" "echo 'SSH OK'" >> "$SSH_LOG" 2>&1; then
        log_success "Conexão SSH funcionando: $worker"
        return 0
    else
        log_error "Falha na conexão SSH: $worker"
        return 1
    fi
}

# Função para criar arquivo de workers de exemplo
create_sample_workers_file() {
    log_info "Criando arquivo de workers de exemplo..."

    mkdir -p "$PROJECT_ROOT/config"

    cat > "$WORKERS_LIST_FILE" << 'EOF'
# Cluster AI - Lista de Workers
# Formato: usuario@host:porta
# Exemplo:
# worker1@192.168.1.100:22
# worker2@worker2.local:22
# android@192.168.1.101:8022

# Descomente e edite as linhas abaixo para seus workers:
# worker1@localhost:22
# worker2@localhost:22
EOF

    log_success "Arquivo de exemplo criado: $WORKERS_LIST_FILE"
    log_info "Edite o arquivo com seus workers antes de executar novamente"
}

# Função para mostrar status final
show_final_status() {
    log_info "=== STATUS FINAL DA CONFIGURAÇÃO SSH ==="

    echo "✅ Workers Configurados:"
    if [ ${#CONFIGURED_WORKERS[@]} -gt 0 ]; then
        printf '  - %s\n' "${CONFIGURED_WORKERS[@]}"
    else
        echo "  Nenhum"
    fi

    echo "❌ Workers com Falha:"
    if [ ${#FAILED_WORKERS[@]} -gt 0 ]; then
        printf '  - %s\n' "${FAILED_WORKERS[@]}"
    else
        echo "  Nenhum"
    fi

    echo "🔑 Arquivos SSH:"
    echo "  - Chave privada: $SSH_KEY_FILE"
    echo "  - Chave pública: $SSH_KEY_FILE.pub"
    echo "  - Known hosts: $KNOWN_HOSTS_FILE"
    echo "  - Lista de workers: $WORKERS_LIST_FILE"

    echo "📝 Logs:"
    echo "  - SSH Setup: $SSH_LOG"

    echo "🚀 Próximos Passos:"
    echo "  1. Edite $WORKERS_LIST_FILE com seus workers"
    echo "  2. Execute: ./scripts/setup_ssh_workers.sh configure"
    echo "  3. Teste: ./scripts/setup_ssh_workers.sh test"
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    # Criar diretório de logs
    mkdir -p "$LOG_DIR"
    touch "$SSH_LOG"

    local action="${1:-help}"

    case "$action" in
        "configure")
            log_info "🚀 Configurando autenticação SSH para workers..."

            # Verificações iniciais
            check_dependencies || exit 1

            # Gerar chaves
            generate_ssh_keys

            # Ler lista de workers
            local workers
            if ! workers=$(read_workers_list); then
                create_sample_workers_file
                exit 1
            fi

            # Configurar cada worker
            for worker in $workers; do
                configure_worker "$worker"
            done

            # Status final
            show_final_status
            ;;
        "test")
            log_info "🧪 Testando conexões SSH..."

            local workers
            if ! workers=$(read_workers_list); then
                log_error "Lista de workers não encontrada"
                exit 1
            fi

            for worker in $workers; do
                test_ssh_connection "$worker"
            done

            log_success "Testes concluídos"
            ;;
        "generate-keys")
            check_dependencies || exit 1
            generate_ssh_keys
            ;;
        "create-sample")
            create_sample_workers_file
            ;;
        "help"|*)
            echo "Cluster AI - SSH Workers Setup Script"
            echo ""
            echo "Uso: $0 [ação]"
            echo ""
            echo "Ações:"
            echo "  configure      - Configura autenticação SSH para todos os workers"
            echo "  test           - Testa conexões SSH com os workers"
            echo "  generate-keys  - Gera novas chaves SSH"
            echo "  create-sample  - Cria arquivo de workers de exemplo"
            echo "  help           - Mostra esta mensagem"
            echo ""
            echo "Pré-requisitos:"
            echo "  - Arquivo $WORKERS_LIST_FILE com lista de workers"
            echo "  - Conectividade SSH com os workers"
            echo "  - Usuário com sudo nos workers (para instalação)"
            echo ""
            echo "Exemplo de $WORKERS_LIST_FILE:"
            echo "  worker1@192.168.1.100:22"
            echo "  worker2@worker2.local:22"
            echo ""
            echo "Exemplos de uso:"
            echo "  $0 configure"
            echo "  $0 test"
            echo "  $0 create-sample"
            ;;
    esac
}

# Executar função principal
main "$@"
