#!/bin/bash
# Setup Docker para Cluster AI
# Wrapper para instalação do Docker com integração no sistema

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

# Verificar se Docker já está instalado
check_docker() {
    if command -v docker &> /dev/null; then
        log "Docker já está instalado"
        docker --version
        return 0
    fi
    return 1
}

# Instalar Docker usando o script oficial
install_docker() {
    log "Instalando Docker..."

    # Verificar se o script get-docker.sh existe
    if [ ! -f "get-docker.sh" ]; then
        error "Script get-docker.sh não encontrado na raiz do projeto"
        error "Baixe o script oficial: curl -fsSL https://get.docker.com -o get-docker.sh"
        exit 1
    fi

    # Executar instalação
    if bash get-docker.sh; then
        success "Docker instalado com sucesso"
    else
        error "Falha na instalação do Docker"
        exit 1
    fi
}

# Configurar Docker para uso não-root (opcional)
setup_docker_nonroot() {
    log "Configurando Docker para uso não-root..."

    # Adicionar usuário ao grupo docker
    if id -nG "$USER" | grep -qw "docker"; then
        log "Usuário já está no grupo docker"
    else
        sudo usermod -aG docker "$USER"
        warn "Reinicie a sessão ou execute 'newgrp docker' para aplicar as mudanças"
    fi
}

# Verificar instalação
verify_installation() {
    log "Verificando instalação do Docker..."

    # Testar Docker
    if docker run --rm hello-world &> /dev/null; then
        success "Docker está funcionando corretamente"
    else
        error "Docker não está funcionando corretamente"
        exit 1
    fi

    # Verificar versão
    docker --version
    docker compose version 2>/dev/null || log "Docker Compose não instalado"
}

# Iniciar serviço Docker
start_docker_service() {
    log "Iniciando serviço Docker..."

    if sudo systemctl is-active --quiet docker; then
        log "Serviço Docker já está ativo"
    else
        sudo systemctl start docker
        sudo systemctl enable docker
        success "Serviço Docker iniciado e habilitado"
    fi
}

# Função principal
main() {
    echo
    echo "🐳 CONFIGURAÇÃO DOCKER - CLUSTER AI"
    echo "==================================="
    echo

    # Verificar se já está instalado
    if check_docker; then
        read -p "Docker já está instalado. Deseja reinstalar? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Instalação cancelada pelo usuário"
            exit 0
        fi
    fi

    # Instalar Docker
    install_docker

    # Iniciar serviço
    start_docker_service

    # Configurar para uso não-root
    read -p "Configurar Docker para uso não-root? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        setup_docker_nonroot
    fi

    # Verificar instalação
    verify_installation

    echo
    success "Configuração do Docker concluída!"
    echo
    echo "📋 PRÓXIMOS PASSOS:"
    echo "• Se configurou para não-root: reinicie a sessão"
    echo "• Teste: docker run hello-world"
    echo "• Para o Cluster AI: execute ./install.sh"
    echo
}

# Executar
main "$@"
