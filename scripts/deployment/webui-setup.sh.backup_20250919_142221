#!/bin/bash
# ================================================
# Script Unificado - Open WebUI + Cluster Dask/MPI
# Autor: Dagoberto Candeias de Moraes
# ================================================

echo "=== Open WebUI + Cluster Dask/MPI Installer ==="

# ==============================
# 1. Solicitar senha de App do Gmail
# ==============================
read -s -p "Digite sua senha de app do Gmail para betoallnet@gmail.com: " GMAIL_PASS
echo

# ==============================
# 2. Atualizar pacotes e instalar dependências
# ==============================
echo "[1/6] Instalando dependências..."
sudo apt update
sudo apt install -y docker.io docker-compose curl msmtp msmtp-mta mailutils ca-certificates \
    python3.13-venv python3.13-full python3-pip

# ==============================
# 3. Configurar msmtp para Gmail
# ==============================
echo "[2/6] Configurando envio de email (msmtp)..."
cat <<EOF > ~/.msmtprc
# Configuração do msmtp para Gmail
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile ~/.msmtp.log

account gmail
host smtp.gmail.com
port 587
from betoallnet@gmail.com
user betoallnet@gmail.com
password $GMAIL_PASS

account default : gmail
EOF

chmod 600 ~/.msmtprc

# Testar envio
echo "Teste de configuração de email via Gmail (msmtp)." | msmtp -a gmail betoallnet@gmail.com

# ==============================
# 4. Criar ambiente virtual cluster (Dask/MPI)
# ==============================
echo "[3/6] Criando ambiente cluster_env..."
mkdir -p ~/cluster_env
python3 -m venv ~/cluster_env

# Ativar e instalar pacotes
source ~/cluster_env/bin/activate
pip install --upgrade pip
pip install dask[complete] distributed numpy pandas scipy mpi4py

# Instalar dependências MPI no sistema
sudo apt install -y openmpi-bin libopenmpi-dev

# Verificar instalação Dask
python -c "import dask; print('Dask version:', dask.__version__)"

deactivate

# ==============================
# 5. Configurar ativação automática no .bashrc
# ==============================
echo "[4/6] Atualizando ~/.bashrc..."
if ! grep -q "Configuração Cluster Dask/MPI" ~/.bashrc; then
cat <<'EOF' >> ~/.bashrc

# >>> Configuração Cluster Dask/MPI >>>
if [ -f ~/cluster_env/bin/activate ]; then
    source ~/cluster_env/bin/activate
    echo "[INFO] Ambiente cluster_env ativado automaticamente."
fi
# <<< Configuração Cluster Dask/MPI <<<
EOF
fi

# ==============================
# 6. Instalar e iniciar Open WebUI (Docker)
# ==============================
echo "[5/6] Instalando Open WebUI (Docker)..."
sudo docker stop open-webui 2>/dev/null || true
sudo docker rm open-webui 2>/dev/null || true

sudo docker run -d --name open-webui -p 8080:8080 \
  -v ~/open-webui-data:/app/backend/data \
  ghcr.io/open-webui/open-webui:main

# ==============================
# Finalização
# ==============================
echo "[6/6] Instalação concluída!"
echo " - Open WebUI rodando em: http://localhost:8080"
echo " - Alertas configurados via Gmail (msmtp)"
echo " - Ambiente Dask/MPI em: ~/cluster_env (ativação automática habilitada)"
