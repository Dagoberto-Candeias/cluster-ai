# Guia de Configuração do Cluster AI: Servidor e Worker

## Visão Geral
Este guia detalha o passo a passo para configurar um cluster distribuído com um computador servidor (Debian) e um computador worker (Manjaro). O objetivo é facilitar a instalação, configuração e conexão dos nós para processamento distribuído.

---

## 1. Descobrir Informações de Rede

### No Servidor (Debian)
```bash
hostname
ip addr show | grep -E "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d'/' -f1
ip route | grep default | awk '{print $3}'
```

### No Worker (Manjaro)
```bash
hostname
ip addr show | grep -E "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d'/' -f1
ip route | grep default | awk '{print $3}'
```

---

## 2. Preparar o Servidor

### 2.1 Instalar Cluster AI
```bash
cd ~/Projetos/cluster-ai
./install.sh
# Escolha a opção 1 para instalação completa
```

### 2.2 Configurar SSH sem senha (opcional)
```bash
ssh-keygen -t rsa -b 4096 -C "cluster-server"
cat ~/.ssh/id_rsa.pub
# Copie a saída para usar no worker
```

### 2.3 Iniciar serviços do servidor
```bash
./manager.sh
# Escolha a opção 1 para iniciar todos os serviços
```

---

## 3. Preparar o Worker (Manjaro)

### 3.1 Instalar dependências básicas
```bash
sudo pacman -Syu
sudo pacman -S openssh python python-pip git
sudo systemctl enable sshd
sudo systemctl start sshd
```

### 3.2 Configurar SSH sem senha
```bash
mkdir -p ~/.ssh
nano ~/.ssh/authorized_keys
# Cole a chave pública do servidor
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

### 3.3 Instalar Cluster AI
```bash
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
cd cluster-ai
./install.sh
# Escolha a opção 2 para instalação personalizada
# Selecione Python e Docker (se disponível)
```

---

## 4. Conectar Worker ao Servidor

### 4.1 Descobrir e registrar o worker no servidor
```bash
./scripts/management/discover_nodes.sh
# Informe a faixa de IP da rede local (ex: 192.168.1.0/24)
# Adicione o worker quando solicitado
```

### 4.2 Verificar conectividade SSH
```bash
ssh usuario_worker@ip_do_worker
```

---

## 5. Configurar e Testar o Cluster

### 5.1 Iniciar gerenciamento remoto
```bash
./manager.sh
# Escolha a opção 5 para gerenciar workers remotos
# Escolha a opção 1 para iniciar workers em todos os nós remotos
```

### 5.2 Verificar status do cluster
```bash
# No manager, escolha a opção 6 para mostrar status geral
```

### 5.3 Testar processamento distribuído
```bash
python demo_cluster.py
# Ou acessar dashboard Dask em http://localhost:8787
```

---

## 6. Verificação e Troubleshooting

### 6.1 Executar health check
```bash
./scripts/utils/health_check.sh
```

### 6.2 Diagnóstico comum
```bash
# Ver logs do Dask
tail -f logs/dask_scheduler.log

# Ver status dos serviços
systemctl status ollama
systemctl status docker

# Ver processos Dask no worker
ps aux | grep dask
```

### 6.3 Problemas comuns
- Firewall bloqueando portas (liberar 22, 8786, 8787)
- SSH pedindo senha (configurar chave SSH)
- Serviços não iniciam (ver logs e status systemd)

---

## 7. Monitoramento Contínuo

### 7.1 Configurar serviço de monitoramento no servidor
```bash
sudo ./scripts/deployment/setup_monitor_service.sh
```

### 7.2 Acessar interfaces web
- OpenWebUI: http://localhost:3000
- Dask Dashboard: http://localhost:8787
- Monitor do cluster: Ctrl+Alt+F8 (no servidor)

---

## Conclusão
Este guia facilita a configuração e operação do Cluster AI em ambiente distribuído. Para dúvidas ou problemas, consulte a documentação oficial ou solicite suporte.
