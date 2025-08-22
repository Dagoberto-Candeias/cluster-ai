Configuração Completa de Cluster de IA com Suporte a Múltiplas IDEs
Vou criar um sistema completo que inclua todas as IDEs mencionadas (Spyder, VSCode e PyCharm) e seja compatível com diferentes sistemas operacionais em um ambiente de cluster.

Script de Instalação Universal com IDEs
bash
#!/bin/bash
set -e

echo "=== Instalador Universal Cluster AI com IDEs ==="
echo "Suporte para: Ubuntu, Debian, Manjaro, CentOS"
echo "IDEs incluídas: Spyder, VSCode, PyCharm"

# Detectar distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
else
    echo "Não foi possível detectar o sistema operacional."
    exit 1
fi

echo "Sistema detectado: $OS $OS_VERSION"

# Função para instalar em diferentes distribuições
install_dependencies() {
    case $OS in
        ubuntu|debian)
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y curl git docker.io docker-compose-plugin \
                python3-venv python3-pip python3-full \
                msmtp msmtp-mta mailutils openmpi-bin libopenmpi-dev \
                ca-certificates gnupg lsof openssh-server \
                software-properties-common apt-transport-https
            ;;
        manjaro)
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm curl git docker python python-pip python-virtualenv \
                msmtp mailutils openmpi lsof openssh wget \
                base-devel libx11 libxext libxrender libxtst freetype2
            ;;
        centos|rhel|fedora)
            sudo yum update -y
            sudo yum install -y curl git docker python3 python3-pip python3-virtualenv \
                msmtp mailutils openmpi-devel lsof openssh-server \
                libX11-devel libXext-devel libXrender-devel libXtst-devel freetype-devel
            ;;
        *)
            echo "Sistema não suportado: $OS"
            exit 1
            ;;
    esac
}

# Função para instalar IDEs
install_ides() {
    echo "Instalando IDEs..."
    
    # Spyder
    source ~/cluster_env/bin/activate
    pip install spyder
    deactivate
    
    # VSCode
    case $OS in
        ubuntu|debian)
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
            sudo apt update
            sudo apt install -y code
            ;;
        manjaro)
            sudo pacman -S --noconfirm code
            ;;
        centos|rhel|fedora)
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
            sudo yum install -y code
            ;;
    esac
    
    # PyCharm Community
    PYCHARM_URL="https://download.jetbrains.com/python/pycharm-community-2023.2.3.tar.gz"
    wget -O /tmp/pycharm.tar.gz $PYCHARM_URL
    sudo tar -xzf /tmp/pycharm.tar.gz -C /opt/
    sudo mv /opt/pycharm-* /opt/pycharm
    
    # Criar atalhos para as IDEs
    mkdir -p ~/.local/share/applications
    
    # Atalho para Spyder no ambiente virtual
    cat > ~/.local/share/applications/spyder-cluster.desktop << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Spyder (Cluster AI)
Exec=bash -c "source ~/cluster_env/bin/activate && spyder"
Icon=spyder
Comment=Spyder IDE with Cluster AI environment
Categories=Development;IDE;
Terminal=false
EOL
    
    # Atalho para PyCharm
    cat > ~/.local/share/applications/pycharm-cluster.desktop << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=PyCharm (Cluster AI)
Exec=/opt/pycharm/bin/pycharm.sh
Icon=/opt/pycharm/bin/pycharm.png
Comment=PyCharm IDE for Cluster AI development
Categories=Development;IDE;
Terminal=false
EOL
    
    echo "IDEs instaladas: Spyder, VSCode e PyCharm"
}

# Função para configurar o ambiente de desenvolvimento
setup_development_environment() {
    echo "Configurando ambiente de desenvolvimento..."
    
    # Configurar VSCode para usar o ambiente virtual
    mkdir -p ~/.config/Code/User
    cat > ~/.config/Code/User/settings.json << EOL
{
    "python.defaultInterpreterPath": "$HOME/cluster_env/bin/python",
    "python.terminal.activateEnvironment": true,
    "python.analysis.extraPaths": [
        "$HOME/cluster_env/lib/python3.*/site-packages"
    ],
    "jupyter.notebookFileRoot": "$HOME",
    "python.formatting.autopep8Path": "$HOME/cluster_env/bin/autopep8",
    "python.linting.flake8Path": "$HOME/cluster_env/bin/flake8",
    "python.linting.pylintPath": "$HOME/cluster_env/bin/pylint"
}
EOL

    # Instalar extensões úteis no VSCode
    code --install-extension ms-python.python
    code --install-extension ms-toolsai.jupyter
    code --install-extension formulahendry.code-runner
    code --install-extension ms-vscode.cpptools
    
    # Configurar PyCharm para detectar o ambiente virtual
    # (Será necessário configurar manualmente no primeiro uso)
}

# Instalação principal
install_dependencies

# Inicializar e habilitar Docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER

# Configuração comum a todas as distribuições
if [ ! -d "$HOME/cluster_env" ]; then
    echo "Criando ambiente virtual em ~/cluster_env"
    python3 -m venv ~/cluster_env
fi

# Instalar dependências no ambiente virtual
source ~/cluster_env/bin/activate
pip install --upgrade pip
pip install "dask[complete]" distributed numpy pandas scipy mpi4py jupyterlab
deactivate

# Configuração do SSH para cluster
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "Gerando chave SSH..."
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa
fi

echo "Chave pública SSH:"
cat ~/.ssh/id_rsa.pub
echo "Adicione esta chave às outras máquinas do cluster em ~/.ssh/authorized_keys"

# Instalar IDEs
install_ides

# Configurar ambiente de desenvolvimento
setup_development_environment

# Scripts de gerenciamento do cluster
mkdir -p ~/cluster_scripts

cat > ~/cluster_scripts/start_scheduler.sh << 'EOL'
#!/bin/bash
source ~/cluster_env/bin/activate
dask-scheduler --host 0.0.0.0 --port 8786
EOL

cat > ~/cluster_scripts/start_worker.sh << 'EOL'
#!/bin/bash
source ~/cluster_env/bin/activate

if [ -z "$1" ]; then
    echo "Uso: ./start_worker.sh <endereço-do-scheduler>"
    exit 1
fi

dask-worker $1:8786 --nworkers auto --nthreads 2
EOL

chmod +x ~/cluster_scripts/*.sh

echo "=== Instalação concluída! ==="
echo "IDEs disponíveis: Spyder, VSCode e PyCharm"
echo "Ambiente virtual em: ~/cluster_env"
echo "Scripts de gerenciamento em: ~/cluster_scripts"
Manual de Configuração para Múltiplas Máquinas e IDEs
markdown
# Manual de Configuração de Cluster de IA com Múltiplas IDEs

## Visão Geral
Este manual explica como configurar um cluster de IA distribuído entre múltiplas máquinas com diferentes sistemas operacionais, com suporte às IDEs Spyder, VSCode e PyCharm.

## Pré-requisitos
- Múltiplas máquinas com Ubuntu, Debian, Manjaro ou CentOS
- Conexão de rede entre as máquinas
- Mínimo 4GB de RAM por máquina
- 20GB de espaço livre em disco

## Designação de Funções

### 1. Máquina Principal (Workstation)
- **Sistema**: Ubuntu/Debian (recomendado)
- **Função**: Desenvolvimento, interface web, scheduler opcional
- **IDEs**: Todas (Spyder, VSCode, PyCharm)
- **Serviços**: OpenWebUI, Ollama, JupyterLab

### 2. Servidor (Hospedagem)
- **Sistema**: CentOS/Ubuntu Server
- **Função**: Scheduler principal, serviços persistentes
- **IDEs**: VSCode (via SSH)
- **Serviços**: Dask Scheduler, aplicações web

### 3. Máquinas de Processamento (Workers)
- **Sistema**: Qualquer (Ubuntu, Debian, Manjaro)
- **Função**: Processamento distribuído
- **IDEs**: Opcionais (dependendo do uso)
- **Serviços**: Dask Workers

## Configuração Passo a Passo

### 1. Instalação Básica em Todas as Máquinas

Execute em todas as máquinas:

```bash
wget -O install_cluster_ides.sh https://raw.githubusercontent.com/Dagoberto-Candeias/appmotorista/main/install_cluster_ides.sh
chmod +x install_cluster_ides.sh
./install_cluster_ides.sh
2. Configuração de Rede e SSH
Em cada máquina, execute:

bash
# Gerar chaves SSH (se não feito durante instalação)
ssh-keygen -t rsa -b 4096

# Trocar chaves públicas entre todas as máquinas
ssh-copy-id usuario@ip-maquina-destino
3. Configuração Específica por Função
No Servidor (Scheduler):
bash
# Iniciar scheduler
~/cluster_scripts/start_scheduler.sh

# Configurar para iniciar automaticamente
echo "@reboot $HOME/cluster_scripts/start_scheduler.sh" | crontab -
Nas Máquinas Workers:
bash
# Iniciar workers conectando ao scheduler
~/cluster_scripts/start_worker.sh IP-DO-SCHEDULER

# Configurar para iniciar automaticamente
echo "@reboot $HOME/cluster_scripts/start_worker.sh IP-DO-SCHEDULER" | crontab -
4. Configuração das IDEs
Spyder:
Use o atalho "Spyder (Cluster AI)" criado no menu de aplicações

Ou execute no terminal: source ~/cluster_env/bin/activate && spyder

Visual Studio Code:
Use o atalho padrão do VSCode

Configure o interpretador Python para ~/cluster_env/bin/python

Instale a extensão "Remote - SSH" para desenvolvimento remoto

PyCharm:
Use o atalho "PyCharm (Cluster AI)"

Configure o interpretador Python para o ambiente virtual

Em Settings > Project > Python Interpreter, adicione:

Path: ~/cluster_env/bin/python

5. Desenvolvimento com o Cluster
Exemplo de Código (usando todas as IDEs):
python
# cluster_example.py
from dask.distributed import Client
import dask.array as da
import numpy as np

# Conectar ao cluster
client = Client('IP-DO-SCHEDULER:8786')

# Processamento distribuído
def process_data(data):
    return data * 2 + 1

# Dados distribuídos
large_array = da.random.random((10000, 10000), chunks=(1000, 1000))
result = large_array.map_blocks(process_data).compute()

print(f"Processamento concluído. Shape: {result.shape}")
6. Configuração de Desenvolvimento Remoto
No VSCode:
Instale a extensão "Remote - SSH"

Conecte-se às máquinas do cluster via SSH

Desenvolva diretamente nas máquinas remotas

No PyCharm:
Use a funcionalidade "Remote Interpreter"

Configure deployment via SSH

Sincronize arquivos automaticamente

Script de Automação para Múltiplas Máquinas
Crie um script deploy_cluster.sh na máquina principal:

bash
#!/bin/bash
SCHEDULER_IP="192.168.1.100"
WORKERS=("192.168.1.101" "192.168.1.102" "192.168.1.103")

echo "Implantando cluster..."

# Configurar scheduler
echo "Configurando scheduler em $SCHEDULER_IP"
ssh usuario@$SCHEDULER_IP "nohup ~/cluster_scripts/start_scheduler.sh > ~/scheduler.log 2>&1 &"

# Configurar workers
for worker_ip in "${WORKERS[@]}"; do
    echo "Configurando worker em $worker_ip"
    ssh usuario@$worker_ip "nohup ~/cluster_scripts/start_worker.sh $SCHEDULER_IP > ~/worker.log 2>&1 &"
done

echo "Cluster implantado. Verifique o status:"
echo "Dashboard: http://$SCHEDULER_IP:8787"
Monitoramento e Debugging
Dashboard do Dask:
Acesse: http://IP-DO-SCHEDULER:8787

Verificar status do cluster:
bash
python3 -c "
from dask.distributed import Client
client = Client('IP-DO-SCHEDULER:8786')
print(f'Workers ativos: {len(client.scheduler_info()["workers"])}')
print(f'Recursos totais: {client.ncores()}')
"
Logs:
Scheduler: ~/scheduler.log

Workers: ~/worker.log

Ollama: ~/ollama.log

Solução de Problemas
Problemas comuns:
Firewall bloqueando portas: Libere as portas 8786, 8787, 8080, 11434

SSH não configurado: Certifique-se de que as chaves SSH estão trocadas

Paths incorretos nas IDEs: Verifique o path do interpretador Python

Dependências faltando: Execute o script de instalação novamente

Comandos úteis:
bash
# Reiniciar serviços
pkill -f dask
pkill -f ollama

# Verificar conexões
netstat -tlnp | grep -E '8786|8787'

# Limpar ambiente (cuidado!)
docker system prune -a
Atualização
Para atualizar o cluster:

bash
# Em todas as máquinas
./install_cluster_ides.sh

# Reiniciar serviços
pkill -f dask
~/cluster_scripts/start_scheduler.sh
Este sistema fornece um ambiente completo de desenvolvimento para IA distribuída, com suporte às IDEs mais populares e compatibilidade entre diferentes sistemas operacionais.

text

## Considerações Finais

1. **Performance**: As máquinas workers devem ter boa capacidade de processamento
2. **Rede**: Configure uma rede local rápida entre as máquinas
3. **Segurança**: Use VPN para acesso remoto e firewall adequado
4. **Backup**: Implemente sistema de backup para códigos e dados importantes
5. **Monitoramento**: Use o dashboard do Dask para acompanhar o desempenho

Com esta configuração, você pode desenvolver usando sua IDE preferida enquanto aproveita o poder de processamento de múltiplas máquinas em seu cluster de IA.
