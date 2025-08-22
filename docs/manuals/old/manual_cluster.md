# Manual de Instalação e Uso do Cluster + OpenWebUI + Ollama

## 1. Instalação
Baixe e rode o script:

```bash
wget -O install_cluster.sh https://example.com/install_cluster.sh
chmod +x install_cluster.sh
./install_cluster.sh
```

## 2. Ambiente Virtual
Ativar manualmente quando necessário:

```bash
source ~/cluster_env/bin/activate
```

Pacotes instalados:
- dask[complete]
- distributed
- numpy
- pandas
- scipy
- mpi4py

## 3. OpenWebUI
- Instalado em container Docker.
- Porta: `8080`
- Acesse em: [http://localhost:8080](http://localhost:8080)

Se já existir container com o mesmo nome, o script remove antes de recriar.

## 4. Ollama
- Instalado automaticamente.
- Porta padrão: `11434`
- Se já estiver em uso, o script encerra o processo antigo antes de iniciar.

Rodar manualmente:

```bash
ollama serve
```

## 5. E-mail com Gmail
O script gera `~/.msmtprc`. Exemplo:

```ini
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
```

### Configurando senha criptografada
```bash
echo "SUA_SENHA_DO_GMAIL" | gpg --symmetric --cipher-algo AES256 -o ~/.gmail_pass.gpg
```

### Testar envio
```bash
echo "Teste OK" | mail -s "Alerta Cluster" SEU_EMAIL@gmail.com
```

## 6. Uso Multi-dispositivo
No Manjaro:

```bash
sudo pacman -Syu python python-pip openmpi
python -m venv ~/cluster_env
source ~/cluster_env/bin/activate
pip install dask[complete] distributed mpi4py
```

---

## 7. Atalhos Importantes
- Ativar ambiente: `source ~/cluster_env/bin/activate`
- Subir OpenWebUI: `sudo docker start -ai open-webui`
- Verificar Ollama: `ps aux | grep ollama`
