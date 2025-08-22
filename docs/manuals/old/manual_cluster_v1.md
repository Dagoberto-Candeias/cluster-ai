# Manual de Instalação e Uso - Cluster + OpenWebUI + Ollama

## 1. Instalação
Baixe e rode o script:

```bash
wget -O install_cluster.sh https://example.com/install_cluster.sh
chmod +x install_cluster.sh
./install_cluster.sh
```

## 2. Ambiente Virtual
Ativar manualmente:

```bash
source ~/cluster_env/bin/activate
```

Pacotes inclusos:
- dask[complete]
- distributed
- numpy
- pandas
- scipy
- mpi4py

## 3. OpenWebUI
- Roda em container Docker.
- Porta: `8080`
- Acesse: [http://localhost:8080](http://localhost:8080)

Se já existir container antigo, o script remove antes de recriar.

## 4. Ollama
- Instalado automaticamente.
- Porta padrão: `11434`
- Se estiver em uso, o script encerra o processo antes de iniciar.

Rodar manualmente:

```bash
ollama serve
```

## 5. E-mail com Gmail
O script gera `~/.msmtprc`. Exemplo:

```ini
account        gmail
host           smtp.gmail.com
port           587
from           SEU_EMAIL@gmail.com
user           SEU_EMAIL@gmail.com
passwordeval   "gpg --quiet --for-your-eyes-only --no-tty -d ~/.gmail_pass.gpg"
account default : gmail
```

### Configurar senha
```bash
echo "SUA_SENHA_APP_GMAIL" | gpg --symmetric --cipher-algo AES256 -o ~/.gmail_pass.gpg
```

### Testar envio
```bash
echo "Teste OK" | mail -s "Cluster Alerta" SEU_EMAIL@gmail.com
```

## 6. Atalhos Importantes
- Ativar ambiente: `source ~/cluster_env/bin/activate`
- Subir OpenWebUI: `sudo docker start -ai open-webui`
- Checar Ollama: `ps aux | grep ollama`
