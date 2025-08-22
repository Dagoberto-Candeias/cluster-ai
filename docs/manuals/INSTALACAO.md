# 📖 Manual Completo de Instalação - Cluster AI

Guia detalhado para instalação e configuração do Cluster AI em diferentes ambientes.

## 📋 Índice
- [🏗️ Arquitetura do Sistema](#️-arquitetura-do-sistema)
- [📋 Requisitos do Sistema](#-requisitos-do-sistema)
- [🚀 Instalação Automática](#-instalação-automática)
- [🔧 Instalação Manual](#-instalação-manual)
- [🎭 Definição de Papéis](#-definição-de-papéis)
- [⚙️ Configuração Avançada](#️-configuração-avançada)
- [🧪 Verificação da Instalação](#-verificação-da-instalação)
- [🚨 Solução de Problemas](#-solução-de-problemas)

## 🏗️ Arquitetura do Sistema

### Visão Geral
O Cluster AI é composto por três tipos de máquinas:

1. **Servidor Principal**: Coordenação + Serviços + Worker
2. **Estação de Trabalho**: Worker + Ferramentas de desenvolvimento
3. **Apenas Worker**: Processamento dedicado

### Diagrama de Componentes
```
[Servidor Principal]
├── ⚡ Dask Scheduler (8786) - Coordenação do cluster
├── 📊 Dask Dashboard (8787) - Monitoramento web
├── 🌐 OpenWebUI (8080) - Interface para modelos IA
├── 🧠 Ollama (11434) - Modelos de linguagem
└── ⚙️ Dask Worker - Processamento local

[Estação de Trabalho]
├── ⚙️ Dask Worker - Processamento remoto
├── 🐍 Spyder IDE - Desenvolvimento Python
├── 💻 VSCode IDE - Editor de código
└── 🚀 PyCharm IDE - IDE profissional

[Apenas Worker]
└── ⚙️ Dask Worker - Processamento dedicado
```

### Fluxo de Comunicação
```
Workers → Dask Scheduler (8786) ←→ OpenWebUI (8080)
                ↑                       ↓
           Dashboard (8787)        Ollama (11434)
```

## 📋 Requisitos do Sistema

### Requisitos Mínimos
| Componente | Requisito | Observações |
|------------|-----------|-------------|
| Sistema Operacional | Ubuntu 18.04+, Debian 10+, CentOS 7+, Manjaro | Linux recomendado |
| CPU | 2+ núcleos | 4+ núcleos recomendado |
| RAM | 4 GB | 8+ GB para modelos grandes |
| Armazenamento | 20 GB livre | SSD recomendado |
| Rede | Conexão estável | 1Gbps ideal para cluster |

### Requisitos Recomendados
- **CPU**: 8+ núcleos para processamento intensivo
- **RAM**: 16+ GB para múltiplos modelos Ollama
- **GPU**: NVIDIA com CUDA ou AMD com ROCm
- **Armazenamento**: SSD NVMe para melhor performance
- **Rede**: Rede local 1Gbps+ entre máquinas

### Verificação Pré-instalação
```bash
# Verificar sistema
echo "Sistema: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "CPU: $(nproc) núcleos"
echo "RAM: $(free -h | awk '/^Mem:/{print $2}')"
echo "Disco: $(df -h / | awk 'NR==2{print $4}') livre"

# Verificar dependências básicas
command -v python3 && echo "Python3: ✅" || echo "Python3: ❌"
command -v curl && echo "curl: ✅" || echo "curl: ❌"
command -v docker && echo "Docker: ✅" || echo "Docker: ❌"
```

## 🚀 Instalação Automática

### Instalação em Uma Máquina
```bash
# Download do script principal
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/installation/install_cluster.sh -o install_cluster.sh

# Permissões de execução
chmod +x install_cluster.sh

# Executar instalação interativa
./install_cluster.sh
```

### Instalação em Múltiplas Máquinas
```bash
# Em cada máquina do cluster
./install_cluster.sh

# Seguir o menu para definir papéis:
# 1. Servidor Principal (apenas na primeira máquina)
# 2. Estação de Trabalho (máquinas de desenvolvimento)
# 3. Apenas Worker (máquinas dedicadas a processamento)
```

### Opções de Linha de Comando
```bash
# Instalação silenciosa (server)
./install_cluster.sh --role server --silent

# Instalação silenciosa (worker)
./install_cluster.sh --role worker --server-ip 192.168.1.100 --silent

# Apenas verificar status
./install_cluster.sh --status

# Forçar reinstalação
./install_cluster.sh --force
```

## 🔧 Instalação Manual

### 1. Instalar Dependências do Sistema
```bash
# Ubuntu/Debian
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git docker.io docker-compose-plugin \
    python3-venv python3-pip python3-full \
    msmtp msmtp-mta mailutils openmpi-bin libopenmpi-dev \
    ca-certificates gnupg lsof openssh-server \
    software-properties-common apt-transport-https net-tools

# CentOS/RHEL
sudo yum update -y
sudo yum install -y curl git docker python3 python3-pip python3-virtualenv \
    msmtp mailutils openmpi-devel lsof openssh-server \
    libX11-devel libXext-devel libXrender-devel libXtst-devel freetype-devel net-tools

# Manjaro
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm curl git docker python python-pip python-virtualenv \
    msmtp mailutils openmpi lsof openssh wget \
    base-devel libx11 libxext libxrender libxtst freetype2 net-tools
```

### 2. Configurar Docker
```bash
# Iniciar e habilitar Docker
sudo systemctl enable docker
sudo systemctl start docker

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# Verificar instalação
docker --version
docker-compose --version
```

### 3. Instalar Ollama
```bash
# Instalar Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Configurar serviço
sudo systemctl enable ollama
sudo systemctl start ollama

# Configurar para todas as interfaces
sudo mkdir -p /etc/systemd/system/ollama.service.d/
sudo tee /etc/systemd/system/ollama.service.d/environment.conf > /dev/null << EOL
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_NUM_GPU_LAYERS=35"
EOL

sudo systemctl daemon-reload
sudo systemctl restart ollama
```

### 4. Configurar Ambiente Python
```bash
# Criar ambiente virtual
python3 -m venv ~/cluster_env

# Ativar ambiente
source ~/cluster_env/bin/activate

# Instalar dependências Python
pip install --upgrade pip
pip install "dask[complete]" distributed numpy pandas scipy mpi4py \
    jupyterlab requests dask-ml scikit-learn torch torchvision \
    torchaudio transformers

# Desativar ambiente
deactivate
```

### 5. Configurar SSH para Cluster
```bash
# Criar diretório .ssh
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Gerar chave SSH se não existir
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
fi

# Mostrar chave pública
echo "=== CHAVE PÚBLICA SSH ==="
cat ~/.ssh/id_rsa.pub
echo "========================="
```

## 🎭 Definição de Papéis

### Servidor Principal
```bash
# Configurar como servidor
echo "ROLE=server" > ~/.cluster_role
echo "SERVER_IP=localhost" >> ~/.cluster_role
echo "MACHINE_NAME=$(hostname)" >> ~/.cluster_role
echo "BACKUP_DIR=$HOME/cluster_backups" >> ~/.cluster_role

# Iniciar serviços
~/cluster_scripts/start_scheduler.sh
~/cluster_scripts/start_worker.sh
```

### Estação de Trabalho
```bash
# Configurar como estação
echo "ROLE=workstation" > ~/.cluster_role
echo "SERVER_IP=192.168.1.100" >> ~/.cluster_role  # IP do servidor
echo "MACHINE_NAME=$(hostname)" >> ~/.cluster_role

# Instalar IDEs
source ~/cluster_env/bin/activate
pip install spyder
deactivate

# Instalar VSCode (Ubuntu/Debian)
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install -y code

# Iniciar worker
~/cluster_scripts/start_worker.sh
```

### Apenas Worker
```bash
# Configurar como worker
echo "ROLE=worker" > ~/.cluster_role
echo "SERVER_IP=192.168.1.100" >> ~/.cluster_role  # IP do servidor
echo "MACHINE_NAME=$(hostname)" >> ~/.cluster_role

# Iniciar worker
~/cluster_scripts/start_worker.sh
```

## ⚙️ Configuração Avançada

### Otimização de GPU
```bash
# Configurar Ollama para GPU
mkdir -p ~/.ollama

# NVIDIA CUDA
cat > ~/.ollama/config.json << EOL
{
    "runners": {
        "nvidia": {
            "url": "https://github.com/ollama/ollama/blob/main/gpu/nvidia/runner.cu"
        }
    },
    "environment": {
        "OLLAMA_NUM_GPU_LAYERS": "35",
        "OLLAMA_MAX_LOADED_MODELS": "3",
        "OLLAMA_KEEP_ALIVE": "24h"
    }
}
EOL

# Reiniciar Ollama
sudo systemctl restart ollama
```

### Configuração de Firewall
```bash
# Configurar UFW
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 8786/tcp  # Dask Scheduler
sudo ufw allow 8787/tcp  # Dask Dashboard
sudo ufw allow 8080/tcp  # OpenWebUI
sudo ufw allow 11434/tcp # Ollama API
sudo ufw --force enable
```

### Configuração de Rede
```bash
# IP estático (Ubuntu/Debian)
# Editar /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses: [192.168.1.100/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

## 🧪 Verificação da Instalação

### Testar Serviços
```bash
# Verificar Dask Scheduler
curl -s http://localhost:8786/health | jq .

# Verificar Dask Dashboard
curl -s http://localhost:8787/health | jq .

# Verificar Ollama
curl -s http://localhost:11434/api/tags | jq .

# Verificar OpenWebUI
curl -s http://localhost:8080/api/health | jq .
```

### Testar Funcionalidades
```python
# Testar conexão Dask
from dask.distributed import Client
client = Client('localhost:8786')
print(f"Workers: {len(client.scheduler_info()['workers'])}")
client.close()

# Testar Ollama
import requests
response = requests.post('http://localhost:11434/api/generate', 
    json={'model': 'llama3', 'prompt': 'Hello', 'stream': False})
print(response.json()['response'])
```

### Verificar Logs
```bash
# Logs do Scheduler
tail -f ~/scheduler.log

# Logs do Worker
tail -f ~/worker.log

# Logs do Ollama
journalctl -u ollama -f

# Logs do OpenWebUI
docker logs open-webui
```

## 🚨 Solução de Problemas

### Problemas Comuns

#### Portas Ocupadas
```bash
# Encontrar processo usando porta
sudo lsof -i :8786  # Dask Scheduler
sudo lsof -i :8787  # Dask Dashboard
sudo lsof -i :8080  # OpenWebUI
sudo lsof -i :11434 # Ollama

# Encerrar processo
sudo kill -9 <PID>
```

#### Ollama Não Responde
```bash
# Reiniciar serviço
sudo systemctl restart ollama

# Verificar status
systemctl status ollama

# Verificar logs
journalctl -u ollama -f
```

#### Problemas de Permissão Docker
```bash
# Verificar grupo docker
groups $USER

# Adicionar ao grupo docker
sudo usermod -aG docker $USER

# Reiniciar sessão (logout/login)
```

#### IP do Servidor Mudou
```bash
# Atualizar configuração
sed -i 's/SERVER_IP=.*/SERVER_IP=novo_ip/' ~/.cluster_role

# Reiniciar worker
pkill -f "dask-worker"
~/cluster_scripts/start_worker.sh
```

### Comandos de Diagnóstico
```bash
# Verificar status completo
./install_cluster.sh --status

# Verificar conectividade
ping -c 4 $SERVER_IP
nc -zv $SERVER_IP 8786

# Verificar recursos
top -b -n 1 | head -20
free -h
df -h /
```

### Logs de Depuração
```bash
# Modo verbose para debugging
./install_cluster.sh --verbose

# Log detalhado para arquivo
./install_cluster.sh 2>&1 | tee install.log

# Debug específico do Ollama
OLLAMA_DEBUG=1 ollama serve
```

---

**📞 Suporte**: Consulte a documentação completa ou abra uma issue no GitHub para problemas específicos.

**🔧 Próximos Passos**: Após instalação, configure [Backup e Restauração](../manuals/BACKUP.md) e [Deploy em Produção](../../deployments/production/README.md).
