#!/bin/bash
# -*- coding: utf-8 -*-
#
# Cluster AI - Certificate Generator Script
# Gerador de certificados SSL/TLS do Cluster AI
#
# Projeto: Cluster AI
# Autor: Sistema de consolidação automática
# Data: 2024-12-19
# Versão: 1.0.0
#
# Descrição:
#   Script responsável pela geração e gerenciamento de certificados
#   SSL/TLS para o Cluster AI. Suporta certificados auto-assinados,
#   certificados Let's Encrypt e configuração automática de HTTPS.
#   Inclui validação de certificados e renovação automática.
#
# Uso:
#   ./scripts/security/generate_certificates.sh [opções]
#
# Dependências:
#   - bash
#   - openssl
#   - certbot (para Let's Encrypt)
#   - curl (para verificação)
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
CERT_DIR="$PROJECT_ROOT/certs"
LOG_DIR="$PROJECT_ROOT/logs"
CERT_LOG="$LOG_DIR/certificate_generator.log"

# Configurações
CERT_VALIDITY_DAYS="365"
KEY_SIZE="2048"
COUNTRY="BR"
STATE="Estado"
CITY="Cidade"
ORGANIZATION="Cluster AI"
ORGANIZATIONAL_UNIT="IT"
EMAIL="admin@cluster-ai.local"
LETS_ENCRYPT_ENABLED="false"
AUTO_RENEW_ENABLED="true"

# Arrays para controle
GENERATED_CERTS=()
EXPIRED_CERTS=()

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
    log_info "Verificando dependências do gerador de certificados..."

    local missing_deps=()
    local required_commands=(
        "openssl"
        "curl"
    )

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ "$LETS_ENCRYPT_ENABLED" = "true" ]; then
        if ! command -v "certbot" &> /dev/null; then
            missing_deps+=("certbot")
        fi
    fi

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Dependências faltando: ${missing_deps[*]}"
        log_info "Instale as dependências necessárias e tente novamente"
        return 1
    fi

    log_success "Dependências verificadas"
    return 0
}

# Função para gerar certificado auto-assinado
generate_self_signed_cert() {
    local domain="$1"
    local cert_file="$CERT_DIR/$domain.crt"
    local key_file="$CERT_DIR/$domain.key"
    local csr_file="$CERT_DIR/$domain.csr"

    if [ -f "$cert_file" ] && [ -f "$key_file" ]; then
        log_warning "Certificado já existe para $domain"
        return 0
    fi

    log_info "Gerando certificado auto-assinado para $domain..."

    # Criar diretório de certificados
    mkdir -p "$CERT_DIR"

    # Gerar chave privada
    openssl genrsa -out "$key_file" "$KEY_SIZE"

    # Gerar CSR (Certificate Signing Request)
    openssl req -new -key "$key_file" -out "$csr_file" -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$domain/emailAddress=$EMAIL"

    # Gerar certificado auto-assinado
    openssl x509 -req -days "$CERT_VALIDITY_DAYS" -in "$csr_file" -signkey "$key_file" -out "$cert_file"

    # Configurar permissões
    chmod 600 "$key_file"
    chmod 644 "$cert_file"

    GENERATED_CERTS+=("$domain:self-signed")
    log_success "Certificado auto-assinado gerado para $domain"
}

# Função para gerar certificado Let's Encrypt
generate_lets_encrypt_cert() {
    local domain="$1"

    if [ "$LETS_ENCRYPT_ENABLED" != "true" ]; then
        log_warning "Let's Encrypt não está habilitado"
        return 1
    fi

    if ! command -v "certbot" &> /dev/null; then
        log_error "Certbot não está instalado"
        return 1
    fi

    log_info "Gerando certificado Let's Encrypt para $domain..."

    # Executar certbot
    sudo certbot certonly --standalone -d "$domain" --email "$EMAIL" --agree-tos --non-interactive

    # Copiar certificados para o diretório do projeto
    local le_cert="/etc/letsencrypt/live/$domain/fullchain.pem"
    local le_key="/etc/letsencrypt/live/$domain/privkey.pem"

    if [ -f "$le_cert" ] && [ -f "$le_key" ]; then
        cp "$le_cert" "$CERT_DIR/$domain.crt"
        cp "$le_key" "$CERT_DIR/$domain.key"
        GENERATED_CERTS+=("$domain:lets-encrypt")
        log_success "Certificado Let's Encrypt gerado para $domain"
    else
        log_error "Falha ao obter certificado Let's Encrypt"
        return 1
    fi
}

# Função para verificar validade do certificado
check_certificate_validity() {
    local cert_file="$1"

    if [ ! -f "$cert_file" ]; then
        echo "INVALID"
        return 1
    fi

    local expiry_date=$(openssl x509 -in "$cert_file" -noout -enddate 2>/dev/null | cut -d= -f2)
    if [ -z "$expiry_date" ]; then
        echo "INVALID"
        return 1
    fi

    local expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null)
    local current_timestamp=$(date +%s)
    local days_left=$(( (expiry_timestamp - current_timestamp) / 86400 ))

    if [ "$days_left" -lt 0 ]; then
        echo "EXPIRED"
        return 1
    elif [ "$days_left" -le 30 ]; then
        echo "EXPIRING_SOON:$days_left"
        return 0
    else
        echo "VALID:$days_left"
        return 0
    fi
}

# Função para renovar certificado
renew_certificate() {
    local domain="$1"
    local cert_type="${2:-self-signed}"

    log_info "Renovando certificado para $domain..."

    case "$cert_type" in
        "self-signed")
            generate_self_signed_cert "$domain"
            ;;
        "lets-encrypt")
            if [ "$LETS_ENCRYPT_ENABLED" = "true" ]; then
                sudo certbot renew --cert-name "$domain"
                # Recopiar certificados
                local le_cert="/etc/letsencrypt/live/$domain/fullchain.pem"
                local le_key="/etc/letsencrypt/live/$domain/privkey.pem"
                if [ -f "$le_cert" ] && [ -f "$le_key" ]; then
                    cp "$le_cert" "$CERT_DIR/$domain.crt"
                    cp "$le_key" "$CERT_DIR/$domain.key"
                fi
            fi
            ;;
    esac

    log_success "Certificado renovado para $domain"
}

# Função para verificar e renovar certificados expirados
check_and_renew_certificates() {
    log_info "Verificando certificados para renovação..."

    for cert_file in "$CERT_DIR"/*.crt; do
        if [ ! -f "$cert_file" ]; then
            continue
        fi

        local domain=$(basename "$cert_file" .crt)
        local validity=$(check_certificate_validity "$cert_file")

        case "$validity" in
            "INVALID")
                log_error "Certificado inválido para $domain"
                EXPIRED_CERTS+=("$domain:invalid")
                ;;
            "EXPIRED")
                log_error "Certificado expirado para $domain"
                EXPIRED_CERTS+=("$domain:expired")
                if [ "$AUTO_RENEW_ENABLED" = "true" ]; then
                    renew_certificate "$domain"
                fi
                ;;
            EXPIRING_SOON:*)
                local days_left=$(echo "$validity" | cut -d: -f2)
                log_warning "Certificado para $domain expira em $days_left dias"
                if [ "$AUTO_RENEW_ENABLED" = "true" ] && [ "$days_left" -le 7 ]; then
                    renew_certificate "$domain"
                fi
                ;;
            VALID:*)
                local days_left=$(echo "$validity" | cut -d: -f2)
                log_info "Certificado para $domain válido por $days_left dias"
                ;;
        esac
    done
}

# Função para configurar HTTPS em serviços
configure_https_services() {
    log_info "Configurando HTTPS para serviços..."

    # Nginx
    if command -v nginx &> /dev/null; then
        local nginx_conf="/etc/nginx/sites-available/cluster-ai"
        if [ -f "$nginx_conf" ]; then
            log_info "Configurando HTTPS no Nginx..."
            # Adicionar configuração SSL se não existir
            if ! grep -q "ssl_certificate" "$nginx_conf"; then
                sudo sed -i "/listen 80 default_server;/a\    listen 443 ssl http2 default_server;\n    ssl_certificate $CERT_DIR/cluster-ai.local.crt;\n    ssl_certificate_key $CERT_DIR/cluster-ai.local.key;" "$nginx_conf"
                sudo nginx -t && sudo systemctl reload nginx
                log_success "HTTPS configurado no Nginx"
            fi
        fi
    fi

    # Outros serviços podem ser adicionados aqui
}

# Função para gerar relatório de certificados
generate_certificate_report() {
    local report_file="$LOG_DIR/certificate_report_$(date +%Y%m%d_%H%M%S).log"

    cat > "$report_file" << EOF
=== Relatório de Certificados - Cluster AI ===
Data: $(date -Iseconds)

1. Certificados Gerados:
$(printf '  - %s\n' "${GENERATED_CERTS[@]}")

2. Certificados Expirados/Problemas:
$(printf '  - %s\n' "${EXPIRED_CERTS[@]}")

3. Status dos Certificados:
$(for cert_file in "$CERT_DIR"/*.crt; do
    if [ -f "$cert_file" ]; then
        domain=$(basename "$cert_file" .crt)
        validity=$(check_certificate_validity "$cert_file")
        echo "  - $domain: $validity"
    fi
done)

4. Configurações:
  - Validade padrão: $CERT_VALIDITY_DAYS dias
  - Tamanho da chave: $KEY_SIZE bits
  - Let's Encrypt: $LETS_ENCRYPT_ENABLED
  - Renovação automática: $AUTO_RENEW_ENABLED

5. Recomendações:
  - Renovar certificados com menos de 30 dias de validade
  - Usar certificados Let's Encrypt para produção
  - Configurar alertas para expiração próxima

=== Fim do Relatório ===
EOF

    log_success "Relatório de certificados gerado: $report_file"
    echo "$report_file"
}

# Função para listar certificados
list_certificates() {
    log_info "Listando certificados..."

    if [ ! -d "$CERT_DIR" ] || [ -z "$(ls -A "$CERT_DIR" 2>/dev/null)" ]; then
        echo "Nenhum certificado encontrado"
        return 0
    fi

    echo "=== Certificados Disponíveis ==="
    for cert_file in "$CERT_DIR"/*.crt; do
        if [ -f "$cert_file" ]; then
            local domain=$(basename "$cert_file" .crt)
            local validity=$(check_certificate_validity "$cert_file")
            echo "  - $domain: $validity"
        fi
    done
}

# Função principal
main() {
    cd "$PROJECT_ROOT"

    # Criar diretórios
    mkdir -p "$CERT_DIR"
    mkdir -p "$LOG_DIR"
    touch "$CERT_LOG"

    local action="${1:-help}"

    case "$action" in
        "generate")
            check_dependencies || exit 1
            generate_self_signed_cert "${2:-cluster-ai.local}"
            ;;
        "lets-encrypt")
            check_dependencies || exit 1
            generate_lets_encrypt_cert "${2:-}"
            ;;
        "check")
            check_dependencies || exit 1
            check_and_renew_certificates
            ;;
        "renew")
            check_dependencies || exit 1
            renew_certificate "${2:-}" "${3:-self-signed}"
            ;;
        "configure-https")
            check_dependencies || exit 1
            configure_https_services
            ;;
        "report")
            check_dependencies || exit 1
            generate_certificate_report
            ;;
        "list")
            list_certificates
            ;;
        "help"|*)
            echo "Cluster AI - Certificate Generator Script"
            echo ""
            echo "Uso: $0 <ação> [parâmetros]"
            echo ""
            echo "Ações:"
            echo "  generate [domain]       - Gerar certificado auto-assinado"
            echo "  lets-encrypt <domain>   - Gerar certificado Let's Encrypt"
            echo "  check                   - Verificar e renovar certificados"
            echo "  renew <domain> [type]   - Renovar certificado específico"
            echo "  configure-https         - Configurar HTTPS nos serviços"
            echo "  report                  - Gerar relatório de certificados"
            echo "  list                    - Listar certificados disponíveis"
            echo "  help                    - Mostra esta mensagem"
            echo ""
            echo "Configurações:"
            echo "  - Validade padrão: $CERT_VALIDITY_DAYS dias"
            echo "  - Tamanho da chave: $KEY_SIZE bits"
            echo "  - Let's Encrypt: $LETS_ENCRYPT_ENABLED"
            echo "  - Renovação automática: $AUTO_RENEW_ENABLED"
            echo ""
            echo "Exemplos:"
            echo "  $0 generate cluster-ai.local"
            echo "  $0 lets-encrypt cluster-ai.com"
            echo "  $0 check"
            echo "  $0 report"
            ;;
    esac
}

# Executar função principal
main "$@"
