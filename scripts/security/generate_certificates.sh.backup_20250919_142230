#!/bin/bash
#
# Script para gerar certificados TLS para Dask
# Gera certificado auto-assinado para desenvolvimento/teste
#

set -euo pipefail

# Carregar funções comuns
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${PROJECT_ROOT}/scripts/lib/common.sh"

# Configurações do certificado
CERT_DIR="${PROJECT_ROOT}/certs"
CERT_FILE="${CERT_DIR}/dask_cert.pem"
KEY_FILE="${CERT_DIR}/dask_key.pem"
DAYS_VALID=365
KEY_SIZE=4096

# Informações do certificado
COUNTRY="BR"
STATE="SP"
CITY="Sao Paulo"
ORGANIZATION="Cluster AI"
UNIT="Development"
COMMON_NAME="localhost"
EMAIL="admin@cluster-ai.local"

main() {
    section "🔐 Gerando Certificados TLS para Dask"

    # Criar diretório de certificados se não existir
    if [ ! -d "$CERT_DIR" ]; then
        mkdir -p "$CERT_DIR"
        info "Diretório de certificados criado: $CERT_DIR"
    fi

    # Verificar se já existem certificados
    if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
        warn "Certificados já existem:"
        warn "  Certificado: $CERT_FILE"
        warn "  Chave: $KEY_FILE"
        read -p "Deseja sobrescrever? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Operação cancelada pelo usuário."
            exit 0
        fi
    fi

    subsection "Gerando chave privada RSA ($KEY_SIZE bits)"
    openssl genrsa -out "$KEY_FILE" $KEY_SIZE

    subsection "Gerando certificado auto-assinado"
    openssl req -new -x509 -key "$KEY_FILE" -out "$CERT_FILE" -days $DAYS_VALID \
        -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$UNIT/CN=$COMMON_NAME/emailAddress=$EMAIL"

    subsection "Ajustando permissões"
    chmod 600 "$KEY_FILE"
    chmod 644 "$CERT_FILE"

    subsection "Verificando certificados gerados"
    openssl x509 -in "$CERT_FILE" -text -noout | head -10

    success "✅ Certificados TLS gerados com sucesso!"
    info "Certificado: $CERT_FILE"
    info "Chave privada: $KEY_FILE"
    info "Validade: $DAYS_VALID dias"

    subsection "Testando configuração TLS"
    if openssl s_client -connect localhost:8786 -cert "$CERT_FILE" -key "$KEY_FILE" -CAfile "$CERT_FILE" </dev/null 2>/dev/null | openssl x509 -noout -dates 2>/dev/null; then
        success "✅ Configuração TLS válida"
    else
        warn "⚠️  Não foi possível testar TLS (servidor pode não estar rodando)"
    fi

    info ""
    info "📋 Para usar os certificados no Dask:"
    info "   1. Configure security no cluster:"
    info "      security = Security(tls_ca_file='$CERT_FILE',"
    info "                        tls_cert='$CERT_FILE',"
    info "                        tls_key='$KEY_FILE')"
    info ""
    info "   2. Ou use variáveis de ambiente:"
    info "      export DASK_DISTRIBUTED__COMM__TLS__CA_FILE=$CERT_FILE"
    info "      export DASK_DISTRIBUTED__COMM__TLS__CERT=$CERT_FILE"
    info "      export DASK_DISTRIBUTED__COMM__TLS__KEY=$KEY_FILE"
}

main "$@"
