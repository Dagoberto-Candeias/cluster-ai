# Manual Completo - Open WebUI com Cluster e Alertas

Este documento descreve o processo automatizado de instalação e configuração
do ambiente de execução para o **Open WebUI com Ollama**, incluindo suporte a:
- Cluster com Dask e MPI
- Ambientes virtuais Python (`venv`)
- Configuração de envio de alertas por email (Gmail via msmtp)
- Deploy automático do Open WebUI com Docker

---

## 1. Instalar ferramentas necessárias

```bash
sudo apt update
sudo apt install -y     python3.13-venv python3-pip python3.13-full     docker.io msmtp msmtp-mta mailutils
```

---

## 2. Criar ambiente virtual para o cluster

```bash
# Criar diretório para o ambiente virtual
mkdir -p ~/cluster_env
python3 -m venv ~/cluster_env

# Ativar o ambiente
source ~/cluster_env/bin/activate
```

---

## 3. Instalar as dependências no ambiente virtual

```bash
pip install --upgrade pip
pip install dask[complete] distributed numpy pandas scipy
```

Verificar instalação:

```bash
python -c "import dask; print('Dask version:', dask.__version__)"
```

---

## 4. Configurar ativação automática (opcional)

Adicionar ao final do seu `~/.bashrc`:

```bash
# Ativar ambiente do cluster automaticamente
if [ -f ~/cluster_env/bin/activate ]; then
    source ~/cluster_env/bin/activate
fi
```

---

## 5. Instalar suporte a MPI

```bash
# No ambiente virtual ativado
pip install mpi4py

# Dependências do sistema
sudo apt install -y openmpi-bin libopenmpi-dev
```

---

## 6. Configuração Multi-Dispositivo (Manjaro)

```bash
sudo pacman -Syu python python-pip openmpi

python -m venv ~/cluster_env
source ~/cluster_env/bin/activate
pip install dask[complete] distributed mpi4py
```

---

## 7. Configuração do msmtp (envio de alertas Gmail)

Criar `~/.msmtprc`:

```ini
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
password <SENHA_DE_APP_DO_GMAIL>
auth plain
tls_starttls on

account default : gmail
```

Dar permissão correta:

```bash
chmod 600 ~/.msmtprc
```

Testar envio:

```bash
echo "Teste de alerta OpenWebUI" | mail -s "Teste OK" betoallnet@gmail.com
```

---

## 8. Deploy do Open WebUI com Docker

O script já verifica se existe um container chamado `open-webui`.
Se existir, ele será removido automaticamente antes de criar outro.

```bash
# Verificação e execução
if sudo docker ps -a --format '{{.Names}}' | grep -Eq '^open-webui$'; then
    echo "Container 'open-webui' já existe. Removendo..."
    sudo docker stop open-webui
    sudo docker rm open-webui
fi

sudo docker run -d --name open-webui -p 8080:8080   -v $HOME/open-webui:/app/data   ghcr.io/open-webui/open-webui:main
```

---

## 9. Arquivo unificado (instalador automático)

Use o script `open_webui_cluster_installer.sh` para automatizar todo o processo.

```bash
chmod +x open_webui_cluster_installer.sh
./open_webui_cluster_installer.sh
```

---

## 10. Acesso ao sistema

Abra no navegador:

```
http://localhost:8080
```

E faça login no Open WebUI.

---

## Conclusão

Agora você possui:
- Ambiente Python isolado para cluster Dask + MPI
- Open WebUI rodando em Docker
- Alertas automáticos por Gmail via `msmtp`
- Verificação para evitar conflitos de containers duplicados

