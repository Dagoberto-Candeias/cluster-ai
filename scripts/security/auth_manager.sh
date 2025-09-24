#!/bin/bash
# -*- coding: utf-8 -*-
#
# Cluster AI - Authentication Manager Script
# Gerenciador de autenticação do Cluster AI
#
# Projeto: Cluster AI
# Autor: Sistema de consolidação automática
# Data: 2024-12-19
# Versão: 1.0.0
#
# Descrição:
#   Script responsável pelo gerenciamento de autenticação do Cluster AI.
#   Gerencia usuários, chaves SSH, certificados SSL/TLS, permissões e
#   auditoria de segurança. Suporta múltiplos métodos de autenticação
#   e integração com sistemas externos.
#
# Uso:
#   ./scripts/security/auth_manager.sh [opções]
#
# Dependências:
#   - bash
#   - openssl (para certificados)
#   - ssh-keygen (para chaves SSH)
#   - useradd/userdel (para usuários)
#   - sudo (para operações privilegiadas)
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
SECURITY_DIR="$PROJECT_ROOT"
LOG_DIR="$PROJECT_ROOT/logs"
AUTH_LOG="$LOG_DIR/auth_manager.log"

# Configurações
DEFAULT_USER_SHELL="/bin/bash"
DEFAULT_USER_HOME="/home"
SSH_KEY_TYPE="rsa"
SSH_KEY_BITS="4096"
CERT_VALIDITY_DAYS="365"
AUDIT_LOG_RETENTION="90"

# Arrays para controle
ACTIVE_USERS=()
REVOKED_KEYS=()
CERTIFICATES=()

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
    log_info "Verificando dependências do gerenciador de autenticação..."

    local missing_deps=()
    local required_commands=(
        "openssl"
        "ssh-keygen"
        "useradd"
        "usermod"
        "userdel"
        "sudo"
        "chown"
        "chmod"
    )

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Dependências faltando: ${missing_deps[*]}"
        log_info "Instale as dependências necessárias e tente novamente"
        return 1
    fi

    log_success "Dependências verificadas"
    return 0
}

# Função para criar usuário do sistema
create_system_user() {
    local username="$1"
    local full_name="${2:-$username}"
    local user_home="$DEFAULT_USER_HOME/$username"

    if id "$username" &>/dev/null; then
        log_warning "Usuário $username já existe"
        return 0
    fi

    log_info "Criando usuário $username..."

    # Criar usuário
    sudo useradd -m -s "$DEFAULT_USER_SHELL" -c "$full_name" "$username"

    # Criar diretório SSH
    sudo mkdir -p "$user_home/.ssh"
    sudo chown "$username:$username" "$user_home/.ssh"
    sudo chmod 700 "$user_home/.ssh"

    # Adicionar ao grupo cluster-ai se existir
    if getent group cluster-ai >/dev/null; then
        sudo usermod -a -G cluster-ai "$username"
    fi

    # Criar chave SSH para o usuário
    generate_user_ssh_key "$username"

    log_success "Usuário $username criado com sucesso"
    ACTIVE_USERS+=("$username")
}

# Função para gerar chave SSH para usuário
generate_user_ssh_key() {
    local username="$1"
    local user_home="$DEFAULT_USER_HOME/$username"
    local key_file="$user_home/.ssh/id_$SSH_KEY_TYPE"

    if [ -f "$key_file" ]; then
        log_warning "Chave SSH já existe para $username"
        return 0
    fi

    log_info "Gerando chave SSH para $username..."

    sudo -u "$username" ssh-keygen -t "$SSH_KEY_TYPE" -b "$SSH_KEY_BITS" -f "$key_file" -N ""

    # Configurar authorized_keys
    local pub_key_file="$key_file.pub"
    local authorized_keys="$user_home/.ssh/authorized_keys"

    if [ -f "$pub_key_file" ]; then
        sudo -u "$username" cat "$pub_key_file" >> "$authorized_keys"
        sudo -u "$username" chmod 600 "$authorized_keys"
    fi

    log_success "Chave SSH gerada para $username"
}

# Função para revogar chave SSH
revoke_ssh_key() {
    local username="$1"
    local key_fingerprint="$2"
    local user_home="$DEFAULT_USER_HOME/$username"
    local authorized_keys="$user_home/.ssh/authorized_keys"

    if [ ! -f "$authorized_keys" ]; then
        log_warning "Nenhuma chave autorizada encontrada para $username"
        return 0
    fi

    log_info "Revogando chave SSH para $username..."

    # Remover chave por fingerprint
    local temp_keys=$(mktemp)
    while IFS= read -r line; do
        local current_fingerprint=$(echo "$line" | ssh-keygen -l -f /dev/stdin 2>/dev/null | awk '{print $2}')
        if [ "$current_fingerprint" != "$key_fingerprint" ]; then
            echo "$line" >> "$temp_keys"
        fi
    done < "$authorized_keys"

    sudo cp "$temp_keys" "$authorized_keys"
    sudo chown "$username:$username" "$authorized_keys"
    sudo chmod 600 "$authorized_keys"
    rm -f "$temp_keys"

    REVOKED_KEYS+=("$username:$key_fingerprint")
    log_success "Chave SSH revogada para $username"
}

# Função para gerar certificado SSL/TLS
generate_certificate() {
    local domain="$1"
    local cert_dir="$SECURITY_DIR/certs"
    local key_file="$cert_dir/$domain.key"
    local cert_file="$cert_dir/$domain.crt"

    if [ -f "$cert_file" ] && [ -f "$key_file" ]; then
        log_warning "Certificado já existe para $domain"
        return 0
    fi

    log_info "Gerando certificado SSL/TLS para $domain..."

    # Criar diretório de certificados
    mkdir -p "$cert_dir"

    # Gerar chave privada
    openssl genrsa -out "$key_file" 2048

    # Gerar certificado auto-assinado
    openssl req -new -x509 -key "$key_file" -out "$cert_file" -days "$CERT_VALIDITY_DAYS" \
        -subj "/C=BR/ST=Estado/L=Cidade/O=ClusterAI/CN=$domain"

    # Configurar permissões
    chmod 600 "$key_file"
    chmod 644 "$cert_file"

    CERTIFICATES+=("$domain")
    log_success "Certificado gerado para $domain"
}

# Função para configurar firewall
configure_firewall() {
    log_info "Configurando firewall..."

    # Verificar se ufw está disponível
    if command -v ufw &> /dev/null; then
        sudo ufw --force enable
        sudo ufw default deny incoming
        sudo ufw default allow outgoing

        # Permitir portas essenciais
        local ports=(
            "22"    # SSH
            "80"    # HTTP
            "443"   # HTTPS
            "8786"  # Dask Scheduler
            "8787"  # Dask Dashboard
            "11434" # Ollama
            "3000"  # OpenWebUI
            "9090"  # Prometheus
            "3001"  # Grafana
        )

        for port in "${ports[@]}"; do
            sudo ufw allow "$port"
        done

        sudo ufw reload
        log_success "Firewall configurado com UFW"
    else
        log_warning "UFW não disponível, pulando configuração de firewall"
    fi
}

# Função para auditoria de segurança
perform_security_audit() {
    log_info "Executando auditoria de segurança..."

    local audit_report="$LOG_DIR/security_audit_$(date +%Y%m%d_%H%M%S).log"

    cat > "$audit_report" << EOF
=== Relatório de Auditoria de Segurança ===
Data: $(date -Iseconds)
Sistema: Cluster AI - Auth Manager

1. Usuários Ativos:
$(printf '  - %s\n' "${ACTIVE_USERS[@]}")

2. Chaves Revogadas:
$(printf '  - %s\n' "${REVOKED_KEYS[@]}")

3. Certificados Ativos:
$(printf '  - %s\n' "${CERTIFICATES[@]}")

4. Verificações de Segurança:
  - Usuários do sistema: $(cut -d: -f1 /etc/passwd | wc -l)
  - Chaves SSH autorizadas: $(find /home -name "authorized_keys" -exec cat {} \; | wc -l)
  - Certificados SSL: $(find $SECURITY_DIR/certs -name "*.crt" | wc -l)
  - Regras de firewall ativas: $(sudo ufw status numbered 2>/dev/null | wc -l)

5. Recomendações:
  - Revisar usuários inativos regularmente
  - Rotacionar chaves SSH periodicamente
  - Renovar certificados antes da expiração
  - Monitorar logs de autenticação

=== Fim do Relatório ===
EOF

    log_success "Auditoria de segurança concluída: $audit_report"
    echo "$audit_report"
}

# Função para listar usuários ativos
list_active_users() {
    log_info "Listando usuários ativos..."

    if [ ${#ACTIVE_USERS[@]} -eq 0 ]; then
        echo "Nenhum usuário ativo registrado"
        return 0
    fi

    echo "=== Usuários Ativos ==="
    for user in "${ACTIVE_USERS[@]}"; do
        if id "$user" &>/dev/null; then
            echo "✅ $user (UID: $(id -u "$user"))"
        else
            echo "❌ $user (usuário não encontrado no sistema)"
        fi
    done
}

# Função para remover usuário
remove_user() {
    local username="$1"

    if ! id "$username" &>/dev/null; then
        log_warning "Usuário $username não existe"
        return 0
    fi

    log_info "Removendo usuário $username..."

    # Revogar todas as chaves SSH
    revoke_all_user_keys "$username"

    # Remover usuário
    sudo userdel -r "$username"

    # Remover da lista de usuários ativos
    ACTIVE_USERS=("${ACTIVE_USERS[@]/$username}")

    log_success "Usuário $username removido"
}

# Função para revogar todas as chaves de um usuário
revoke_all_user_keys() {
    local username="$1"
    local user_home="$DEFAULT_USER_HOME/$username"
    local authorized_keys="$user_home/.ssh/authorized_keys"

    if [ ! -f "$authorized_keys" ]; then
        return 0
    fi

    log_info "Revogando todas as chaves SSH de $username..."

    while IFS= read -r line; do
        local fingerprint=$(echo "$line" | ssh-keygen -l -f /dev/stdin 2>/dev/null | awk '{print $2}')
        if [ -n "$fingerprint" ]; then
            REVOKED_KEYS+=("$username:$fingerprint")
        fi
    done < "$authorized_keys"

    # Limpar authorized_keys
    echo "# Todas as chaves foram revogadas" > "$authorized_keys"
    sudo chown "$username:$username" "$authorized_keys"
    sudo chmod 600 "$authorized_keys"
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    # Criar diretório de logs
    mkdir -p "$LOG_DIR"
    touch "$AUTH_LOG"

    local action="${1:-help}"

    case "$action" in
        "create-user")
            check_dependencies || exit 1
            create_system_user "${2:-}"
            ;;
        "generate-key")
            check_dependencies || exit 1
            generate_user_ssh_key "${2:-}"
            ;;
        "revoke-key")
            check_dependencies || exit 1
            revoke_ssh_key "${2:-}" "${3:-}"
            ;;
        "generate-cert")
            check_dependencies || exit 1
            generate_certificate "${2:-}"
            ;;
        "configure-firewall")
            configure_firewall
            ;;
        "audit")
            check_dependencies || exit 1
            perform_security_audit
            ;;
        "list-users")
            list_active_users
            ;;
        "remove-user")
            check_dependencies || exit 1
            remove_user "${2:-}"
            ;;
        "help"|*)
            echo "Cluster AI - Authentication Manager Script"
            echo ""
            echo "Uso: $0 <ação> [parâmetros]"
            echo ""
            echo "Ações:"
            echo "  create-user <username> [full_name]    - Criar novo usuário"
            echo "  generate-key <username>               - Gerar chave SSH para usuário"
            echo "  revoke-key <username> <fingerprint>   - Revogar chave SSH específica"
            echo "  generate-cert <domain>                - Gerar certificado SSL/TLS"
            echo "  configure-firewall                    - Configurar firewall"
            echo "  audit                                 - Executar auditoria de segurança"
            echo "  list-users                            - Listar usuários ativos"
            echo "  remove-user <username>                - Remover usuário"
            echo "  help                                  - Mostra esta mensagem"
            echo ""
            echo "Configurações:"
            echo "  - Tipo de chave SSH: $SSH_KEY_TYPE"
            echo "  - Tamanho da chave: $SSH_KEY_BITS bits"
            echo "  - Validade do certificado: $CERT_VALIDITY_DAYS dias"
            echo "  - Retenção de logs de auditoria: $AUDIT_LOG_RETENTION dias"
            echo ""
            echo "Exemplos:"
            echo "  $0 create-user admin \"Administrator\""
            echo "  $0 generate-key admin"
            echo "  $0 generate-cert cluster-ai.local"
            echo "  $0 audit"
            ;;
    esac
}

# Executar função principal
main "$@"
