#!/bin/bash
set -e

echo "=== Open WebUI Auto Alert Installer ==="

# Configurações de e-mail
EMAIL_USER="betoallnet@gmail.com"
echo -n "Digite sua senha de app do Gmail para $EMAIL_USER: "
read -s EMAIL_PASS
echo ""

# Detecta versão do Ubuntu
UBUNTU_VERSION=$(lsb_release -rs | cut -d. -f1)

echo "[1/6] Instalando dependências..."
sudo apt-get update -y

# Instala Docker corretamente conforme versão
if [ "$UBUNTU_VERSION" -ge 20 ]; then
    sudo apt-get install -y docker.io docker-compose-plugin msmtp msmtp-mta mailutils
else
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io msmtp msmtp-mta mailutils
fi

# Habilitar Docker no boot
sudo systemctl enable --now docker

echo "[2/6] Criando configuração do msmtp..."
sudo tee /etc/msmtprc > /dev/null <<EOL
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           $EMAIL_USER
user           $EMAIL_USER
password       $EMAIL_PASS

account default : gmail
EOL

sudo chmod 600 /etc/msmtprc
sudo touch /var/log/msmtp.log
sudo chmod 666 /var/log/msmtp.log

echo "[3/6] Testando envio de e-mail..."
echo "Alerta de teste do Open WebUI - instalação concluída com sucesso!" | mail -s "Teste Open WebUI" $EMAIL_USER

echo "[4/6] Criando diretório de configuração..."
mkdir -p ~/open-webui-data

echo "[5/6] Subindo container Open WebUI..."
sudo docker run -d --name open-webui   -p 8080:8080   -v ~/open-webui-data:/app/backend/data   ghcr.io/open-webui/open-webui:main

echo "[6/6] Criando cron job para monitorar container..."

CRON_CMD="* * * * * /usr/bin/docker ps | grep open-webui >/dev/null || echo 'O container Open WebUI parou!' | mail -s '⚠️ Open WebUI caiu' $EMAIL_USER"
(crontab -l 2>/dev/null; echo "$CRON_CMD") | crontab -

echo "✅ Instalação concluída!"
echo "Abra no navegador: http://localhost:8080"
