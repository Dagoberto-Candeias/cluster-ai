#!/bin/bash
# Setup Nginx para Cluster AI
# Configura proxy reverso e balanceamento de carga

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funções auxiliares
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# Verificar se Nginx já está instalado
check_nginx() {
    if command -v nginx &> /dev/null; then
        log "Nginx já está instalado"
        nginx -v
        return 0
    fi
    return 1
}

# Instalar Nginx
install_nginx() {
    log "Instalando Nginx..."

    # Detectar distribuição
    if command -v apt &> /dev/null; then
        # Ubuntu/Debian
        sudo apt update
        sudo apt install -y nginx
    elif command -v dnf &> /dev/null; then
        # Fedora/RHEL
        sudo dnf install -y nginx
    elif command -v pacman &> /dev/null; then
        # Arch Linux
        sudo pacman -S --noconfirm nginx
    else
        error "Gerenciador de pacotes não suportado"
        exit 1
    fi

    success "Nginx instalado com sucesso"
}

# Configurar Nginx para Cluster AI
configure_nginx() {
    log "Configurando Nginx para Cluster AI..."

    # Criar diretório de configuração se não existir
    sudo mkdir -p /etc/nginx/sites-available
    sudo mkdir -p /etc/nginx/sites-enabled

    # Backup da configuração padrão
    if [ -f "/etc/nginx/sites-enabled/default" ]; then
        sudo cp /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.backup
    fi

    # Criar configuração do Cluster AI
    cat << 'EOF' | sudo tee /etc/nginx/sites-available/cluster-ai
# Configuração Nginx para Cluster AI
server {
    listen 80;
    server_name localhost;

    # Logs
    access_log /var/log/nginx/cluster-ai.access.log;
    error_log /var/log/nginx/cluster-ai.error.log;

    # Proxy para Dask Dashboard
    location /dask/ {
        proxy_pass http://localhost:8787/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Proxy para OpenWebUI
    location /webui/ {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # API do Cluster AI (se existir)
    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Arquivos estáticos
    location /static/ {
        alias /home/dcm/cluster-ai/static/;
        expires 30d;
    }

    # Página de status
    location /status {
        access_log off;
        return 200 "Cluster AI - Online\n";
        add_header Content-Type text/plain;
    }

    # Redirecionar root para dashboard
    location / {
        return 302 /dask/status;
    }
}

# Servidor HTTPS (opcional - requer certificado)
server {
    listen 443 ssl http2;
    server_name localhost;

    # SSL configuration (uncomment and configure when certificates are available)
    # ssl_certificate /etc/ssl/certs/cluster-ai.crt;
    # ssl_certificate_key /etc/ssl/private/cluster-ai.key;

    # Include the same configuration as HTTP
    include /etc/nginx/sites-available/cluster-ai;
}
EOF

    # Habilitar site
    sudo ln -sf /etc/nginx/sites-available/cluster-ai /etc/nginx/sites-enabled/

    # Remover configuração padrão
    sudo rm -f /etc/nginx/sites-enabled/default

    success "Configuração Nginx criada"
}

# Configurar firewall (UFW)
configure_firewall() {
    log "Configurando firewall..."

    if command -v ufw &> /dev/null; then
        sudo ufw allow 'Nginx Full'
        success "Firewall configurado para Nginx"
    elif command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --permanent --add-service=http
        sudo firewall-cmd --permanent --add-service=https
        sudo firewall-cmd --reload
        success "Firewall configurado para Nginx"
    else
        warn "Firewall não detectado ou não suportado"
    fi
}

# Iniciar e habilitar Nginx
start_nginx() {
    log "Iniciando Nginx..."

    sudo systemctl start nginx
    sudo systemctl enable nginx

    success "Nginx iniciado e habilitado"
}

# Verificar configuração
verify_configuration() {
    log "Verificando configuração Nginx..."

    # Testar configuração
    if sudo nginx -t; then
        success "Configuração Nginx válida"
    else
        error "Erro na configuração Nginx"
        exit 1
    fi

    # Verificar status do serviço
    if sudo systemctl is-active --quiet nginx; then
        success "Serviço Nginx está ativo"
    else
        error "Serviço Nginx não está ativo"
        exit 1
    fi

    # Testar conectividade
    if curl -s http://localhost/status &> /dev/null; then
        success "Nginx está respondendo corretamente"
    else
        warn "Nginx pode não estar respondendo corretamente"
    fi
}

# Função principal
main() {
    echo
    echo "🌐 CONFIGURAÇÃO NGINX - CLUSTER AI"
    echo "==================================="
    echo

    # Verificar se já está instalado
    if check_nginx; then
        read -p "Nginx já está instalado. Deseja reconfigurar? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Configuração cancelada pelo usuário"
            exit 0
        fi
    else
        install_nginx
    fi

    # Configurar Nginx
    configure_nginx

    # Configurar firewall
    configure_firewall

    # Iniciar serviço
    start_nginx

    # Verificar
    verify_configuration

    echo
    success "Configuração do Nginx concluída!"
    echo
    echo "📋 URLs DISPONÍVEIS:"
    echo "• Dashboard Dask: http://localhost/dask/"
    echo "• OpenWebUI: http://localhost/webui/"
    echo "• Status: http://localhost/status"
    echo
    echo "🔧 Para gerenciar:"
    echo "• sudo systemctl restart nginx"
    echo "• sudo nginx -t (testar configuração)"
    echo "• sudo tail -f /var/log/nginx/cluster-ai.access.log"
    echo
}

# Executar
main "$@"
