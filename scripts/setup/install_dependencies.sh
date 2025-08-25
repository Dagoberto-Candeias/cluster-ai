#!/bin/bash
# Script para instalar dependências do sistema para o Cluster AI

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Verificar se é root
if [ "$EUID" -eq 0 ]; then
    error "Não execute este script como root. Use seu usuário normal."
    exit 1
fi

echo -e "${BLUE}=== INSTALANDO DEPENDÊNCIAS DO CLUSTER AI ===${NC}"
echo ""

# 1. Atualizar sistema
log "Atualizando lista de pacotes..."
sudo apt update

# 2. Instalar dependências básicas
log "Instalando dependências básicas..."
sudo apt install -y \
    curl \
    git \
    python3 \
    python3-pip \
    python3-venv \
    net-tools \
    software-properties-common

# 3. Instalar Docker
log "Instalando Docker..."
sudo apt install -y docker.io docker-compose-plugin

# 4. Adicionar usuário ao grupo docker
log "Adicionando usuário ao grupo docker..."
sudo usermod -aG docker $USER

# 5. Instalar dependências de rede
log "Instalando ferramentas de rede..."
sudo apt install -y \
    net-tools \
    iproute2 \
    dnsutils

# 6. Verificar instalações
echo ""
echo -e "${BLUE}=== VERIFICANDO INSTALAÇÕES ===${NC}"

check_install() {
    if command -v "$1" >/dev/null 2>&1; then
        success "$1 instalado corretamente"
        return 0
    else
        error "$1 não foi instalado corretamente"
        return 1
    fi
}

check_install docker
check_install curl
check_install python3
check_install pip3
check_install git

# 7. Configurações pós-instalação
echo ""
echo -e "${BLUE}=== CONFIGURAÇÕES FINAIS ===${NC}"

log "Reiniciando serviço Docker..."
sudo systemctl enable docker
sudo systemctl restart docker

log "Configurando ambiente..."
# Criar alguns diretórios necessários
mkdir -p ~/cluster_scripts
mkdir -p ~/cluster_backups

echo ""
echo -e "${GREEN}=== INSTALAÇÃO CONCLUÍDA ===${NC}"
echo ""
echo -e "${BLUE}📋 PRÓXIMOS PASSOS:${NC}"
echo "1. Faça logout e login novamente para aplicar grupo docker"
echo "2. Execute a instalação do Cluster AI: ./install_cluster.sh"
echo "3. Siga o menu interativo para configurar sua máquina"
echo "4. Instale os modelos: ./scripts/utils/check_models.sh"
echo "5. Valide a instalação: ./scripts/validation/validate_installation.sh"
echo ""
echo -e "${BLUE}📚 DOCUMENTAÇÃO:${NC}"
echo "- Guia rápido: docs/guides/QUICK_START.md"
echo "- Troubleshooting: docs/guides/TROUBLESHOOTING.md"
echo "- Manual completo: docs/README_PRINCIPAL.md"

# Verificar se precisa de reboot
if ! groups | grep -q docker; then
    echo ""
    echo -e "${YELLOW}⚠️  NECESSÁRIO LOGOUT/LOGIN:${NC}"
    echo "Faça logout e login novamente para que as permissões do Docker sejam aplicadas."
fi
