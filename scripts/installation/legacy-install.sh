#!/bin/bash
set -e

echo "[INFO] Iniciando instalação do ambiente de cluster e OpenWebUI..."

# Atualizar pacotes
sudo apt update && sudo apt upgrade -y

# Instalar dependências principais
sudo apt install -y curl git docker.io python3.13-venv python3-pip python3.13-full msmtp msmtp-mta mailutils ca-certificates gnupg

# Criar ambiente virtual
if [ ! -d "$HOME/cluster_env" ]; then
    echo "[INFO] Criando ambiente virtual em ~/cluster_env"
    python3 -m venv ~/cluster_env
else
    echo "[INFO] Ambiente virtual já existe em ~/cluster_env"
fi

# Instalar dependências no ambiente virtual
source ~/cluster_env/bin/activate
pip install --upgrade pip
pip install dask[complete] distributed numpy pandas scipy mpi4py
deactivate

# Instalar OpenMPI
sudo apt install -y openmpi-bin libopenmpi-dev

# Configurar msmtp (exemplo)
if [ ! -f "$HOME/.msmtprc" ]; then
    cat <<EOL > ~/.msmtprc
# Configuração de envio de e-mail via Gmail
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        ~/.msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           SEU_EMAIL@gmail.com
user           SEU_EMAIL@gmail.com
passwordeval   "gpg --quiet --for-your-eyes-only --no-tty -d ~/.gmail_pass.gpg"

account default : gmail
EOL
    chmod 600 ~/.msmtprc
    echo "[INFO] Arquivo ~/.msmtprc criado. Configure seu e-mail e senha criptografada."
else
    echo "[INFO] Arquivo ~/.msmtprc já existe."
fi

# Docker: verificar se o container já existe
if sudo docker ps -a --format '{{.Names}}' | grep -q '^open-webui$'; then
    echo "[INFO] Container open-webui já existe. Removendo..."
    sudo docker stop open-webui || true
    sudo docker rm open-webui || true
fi

# Subir container OpenWebUI
sudo docker run -d --name open-webui -p 8080:8080 -v $HOME/open-webui:/app/data ghcr.io/open-webui/open-webui:main

# Instalar Ollama
if ! command -v ollama &> /dev/null; then
    echo "[INFO] Instalando Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "[INFO] Ollama já instalado."
fi

# Garantir que a porta 11434 não esteja em uso
if lsof -i:11434 -sTCP:LISTEN &>/dev/null; then
    echo "[INFO] Porta 11434 já em uso. Encerrando processo que ocupa a porta..."
    sudo fuser -k 11434/tcp
fi

# Iniciar Ollama
ollama serve &

echo "[INFO] Instalação concluída com sucesso!"
echo "Ative o ambiente com: source ~/cluster_env/bin/activate"
