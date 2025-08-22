# 📘 Manual de Instalação e Uso - Open WebUI + Ollama + Cluster Dask

Este manual reúne todas as etapas necessárias para instalar, configurar e executar o **Open WebUI com Ollama**,
incluindo a configuração de um ambiente de **cluster distribuído com Dask**.

---

## 🔹 1. Preparação do Ambiente

### Atualizar o sistema
```bash
sudo apt update && sudo apt upgrade -y
```

### Instalar dependências principais
```bash
sudo apt install -y git curl wget unzip software-properties-common
```

---

## 🔹 2. Instalação do Docker

```bash
sudo apt install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $USER
```

Depois, saia e entre novamente na sessão para aplicar o grupo.

---

## 🔹 3. Instalação do Open WebUI com Ollama

```bash
sudo docker run -d --name open-webui -p 8080:8080   -v $HOME/open-webui:/app/data   ghcr.io/open-webui/open-webui:main
```

Acesse no navegador:  
👉 `http://localhost:8080`

---

## 🔹 4. Configuração do Ambiente Python para Cluster

### Instalar ferramentas necessárias
```bash
sudo apt install python3.13-venv python3-pip python3.13-full -y
```

### Criar ambiente virtual
```bash
mkdir ~/cluster_env
python3 -m venv ~/cluster_env
source ~/cluster_env/bin/activate
```

### Instalar dependências
```bash
pip install dask[complete] distributed numpy pandas scipy
python -c "import dask; print('Dask version:', dask.__version__)"
```

### Configurar ativação automática (opcional)
Adicionar ao final do arquivo `~/.bashrc`:
```bash
# Ativar ambiente do cluster automaticamente
if [ -f ~/cluster_env/bin/activate ]; then
    source ~/cluster_env/bin/activate
fi
```

### Instalar MPI (opcional, para uso distribuído avançado)
```bash
pip install mpi4py
sudo apt install openmpi-bin libopenmpi-dev -y
```

---

## 🔹 5. Configuração Multi-Dispositivo (Exemplo no Manjaro)

```bash
sudo pacman -Syu python python-pip openmpi
python -m venv ~/cluster_env
source ~/cluster_env/bin/activate
pip install dask[complete] distributed mpi4py
```

---

## 🔹 6. Execução do Script Automatizado

Você pode rodar o script unificado que automatiza tudo:

👉 [open_webui_cluster_setup.sh](open_webui_cluster_setup.sh)

### Passos:
```bash
chmod +x open_webui_cluster_setup.sh
./open_webui_cluster_setup.sh
```

---

## 🔹 7. Conclusão

Após seguir estes passos, você terá:

✅ Open WebUI com Ollama rodando via Docker  
✅ Ambiente Python configurado para Dask e MPI  
✅ Possibilidade de rodar clusters distribuídos  
✅ Setup automatizado via script `.sh`  

---
