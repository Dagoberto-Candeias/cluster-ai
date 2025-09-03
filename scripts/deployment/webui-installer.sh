#!/bin/bash
set -e

echo "=== Instalador Unificado: Open WebUI + Cluster Dask ==="

# === CONFIGURAÇÕES DE EMAIL ===
EMAIL_USER="betoallnet@gmail.com"
read -sp "Digite sua senha de app do Gmail para $EMAIL_USER: " EMAIL_PASS
echo

# === [1/6] Instalar dependências principais ===
echo "[1/6] Instalando dependências do sistema..."
sudo apt update
sudo apt install -y     python3.13-venv python3-pip python3.13-full     openmpi-bin libopenmpi-dev     apt-transport-https ca-certificates curl software-properties-common

# === [2/6] Configurar ambiente virtual ===
echo "[2/6] Criando ambiente virtual cluster_env..."
if [ ! -d "$HOME/cluster_env" ]; then
    mkdir -p ~/cluster_env
    python3 -m venv ~/cluster_env
fi
source ~/cluster_env/bin/activate

# === [3/6] Instalar dependências Python ===
echo "[3/6] Instalando pacotes Python no ambiente virtual..."
pip install --upgrade pip
pip install dask[complete] distributed numpy pandas scipy mpi4py

# Verificação
python -c "import dask; print('✅ Dask versão:', dask.__version__)"

# === [4/6] Configurar ativação automática ===
BASHRC="$HOME/.bashrc"
if ! grep -q "cluster_env/bin/activate" "$BASHRC"; then
    echo "[4/6] Configurando ativação automática no ~/.bashrc..."
    cat <<EOF >> "$BASHRC"

# Ativar ambiente do cluster automaticamente
if [ -f ~/cluster_env/bin/activate ]; then
    source ~/cluster_env/bin/activate
fi
EOF
fi

# === [5/6] Instalar e configurar Docker ===
echo "[5/6] Instalando Docker..."
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "⚠️  Saia e entre novamente no sistema para usar o Docker sem sudo."
fi

echo "[5/6] Configurando e iniciando o Open WebUI..."
# Verificar se o container já existe
if [ "$(sudo docker ps -aq -f name=open-webui)" ]; then
    echo "⚠️  O container 'open-webui' já existe. Removendo..."
    sudo docker stop open-webui >/dev/null 2>&1 || true
    sudo docker rm open-webui >/dev/null 2>&1 || true
fi

# Criar diretório de dados
mkdir -p "$HOME/open-webui"

# Rodar o container
sudo docker run -d --name open-webui -p 8080:8080   -v $HOME/open-webui:/app/data   ghcr.io/open-webui/open-webui:main

echo "✅ Open WebUI iniciado em http://localhost:8080"

# === [6/6] Configurar envio de alertas por email ===
echo "[6/6] Configurando envio de alertas por email..."
cat > ~/send_alert.py <<EOF
import smtplib
from email.mime.text import MIMEText

def send_alert(subject, message):
    sender = "$EMAIL_USER"
    password = "$EMAIL_PASS"
    recipient = "$EMAIL_USER"

    msg = MIMEText(message)
    msg["Subject"] = subject
    msg["From"] = sender
    msg["To"] = recipient

    try:
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(sender, password)
            server.sendmail(sender, recipient, msg.as_string())
        print("✅ Alerta enviado com sucesso!")
    except Exception as e:
        print("❌ Erro ao enviar alerta:", e)

if __name__ == "__main__":
    send_alert("Teste de Alerta", "Sistema configurado com sucesso!")
EOF

echo "=== Instalação finalizada! ==="
echo "👉 Open WebUI: http://localhost:8080"
echo "👉 Ambiente cluster_env pronto (Dask + MPI)"
echo "👉 Script de envio de alertas: ~/send_alert.py"
