#!/bin/bash
# Script para configurar dispositivos Android como workers do Cluster AI

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

# Verificar se o Termux está instalado
if ! command -v termux-setup-storage >/dev/null 2>&1; then
    error "Termux não está instalado. Instale o Termux primeiro."
    exit 1
fi

log "Configurando dispositivo Android como worker do Cluster AI..."

# Instalar dependências no Termux
pkg update && pkg upgrade -y
pkg install -y python git curl

# Criar diretório para scripts
mkdir -p ~/cluster_scripts

# Criar script para iniciar worker
cat > ~/cluster_scripts/start_worker.sh << EOL
#!/bin/bash
# Script para iniciar o worker do Cluster AI

# Conectar ao servidor principal
SERVER_IP="\$1"

# Iniciar worker
while true; do
    if nc -z -w 5 \$SERVER_IP 8786; then
        echo "Conectando ao scheduler em \$SERVER_IP:8786"
        dask-worker \$SERVER_IP:8786 --nworkers auto --nthreads 2 --name "\$(hostname)"
        break
    else
        echo "Scheduler não disponível. Tentando novamente em 10 segundos..."
        sleep 10
    fi
done
EOL

chmod +x ~/cluster_scripts/start_worker.sh

log "Script de worker criado em ~/cluster_scripts/start_worker.sh"

# Instruções para o usuário
echo -e "${YELLOW}=== INSTRUÇÕES ===${NC}"
echo "Para iniciar o worker, execute o seguinte comando no Termux:"
echo "bash ~/cluster_scripts/start_worker.sh <IP_DO_SERVIDOR_PRINCIPAL>"
echo "Substitua <IP_DO_SERVIDOR_PRINCIPAL> pelo IP do servidor onde o Cluster AI está rodando."

log "Configuração concluída. O dispositivo Android agora pode atuar como um worker."
