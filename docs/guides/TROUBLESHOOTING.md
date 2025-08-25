# 🛠️ Guia de Solução de Problemas - Cluster AI

## 🎯 Visão Geral

Este guia cobre os problemas mais comuns encontrados durante a instalação, configuração e uso do Cluster AI, com soluções passo a passo.

## 📋 Índice Rápido

- [🔧 Problemas de Instalação](#-problemas-de-instalação)
- [🤖 Problemas com Ollama](#-problemas-com-ollama)
- [🌐 Problemas com OpenWebUI](#-problemas-com-openwebui)
- [⚡ Problemas com Dask Cluster](#-problemas-com-dask-cluster)
- [🔌 Problemas de Rede](#-problemas-de-rede)
- [💾 Problemas de Performance](#-problemas-de-performance)
- [🚨 Problemas Críticos](#-problemas-críticos)

## 🔧 Problemas de Instalação

### ❌ Script de Instalação Falha

**Sintomas**: Erro durante execução do `install_cluster.sh`

**Soluções**:
```bash
# 1. Verificar permissões
chmod +x install_cluster.sh
chmod +x scripts/installation/main.sh

# 2. Executar com debug
bash -x install_cluster.sh

# 3. Verificar dependências
sudo apt update
sudo apt install -y curl git docker.io

# 4. Executar script principal diretamente
./scripts/installation/main.sh
```

### ❌ Docker Não Instala

**Soluções**:
```bash
# Remover instalações antigas
sudo apt remove docker docker-engine docker.io containerd runc

# Instalar Docker oficial
sudo apt update
sudo apt install -y docker.io docker-compose-plugin

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER
newgrp docker

# Verificar instalação
docker --version
```

### ❌ Erro de Permissão

**Soluções**:
```bash
# Corrigir permissões de diretórios
sudo chown -R $USER:$USER ~/.ollama
sudo chown -R $USER:$USER ~/cluster_scripts
sudo chown -R $USER:$USER ~/open-webui

# Corrigir permissões do Docker
sudo chmod 666 /var/run/docker.sock
```

## 🤖 Problemas com Ollama

### ❌ Ollama Não Inicia

**Sintomas**: `ollama serve` falha ou não responde

**Soluções**:
```bash
# 1. Verificar se está instalado
which ollama

# 2. Reiniciar serviço
sudo systemctl restart ollama

# 3. Verificar logs
journalctl -u ollama -f

# 4. Executar manualmente
ollama serve &

# 5. Verificar porta
netstat -tlnp | grep 11434
```

### ❌ Modelos Não Carregam

**Soluções**:
```bash
# 1. Verificar modelos instalados
ollama list

# 2. Baixar modelo específico
ollama pull llama3

# 3. Verificar espaço em disco
df -h ~/.ollama

# 4. Limpar cache
ollama rm $(ollama list | awk '{print $1}' | tail -n +2)
```

### ❌ Erro de GPU/CUDA

**Soluções**:
```bash
# 1. Verificar GPU
nvidia-smi

# 2. Instalar drivers NVIDIA
sudo apt install -y nvidia-driver-535 nvidia-container-toolkit

# 3. Configurar Ollama para GPU
cat > ~/.ollama/config.json << EOL
{
    "runners": {
        "nvidia": {
            "url": "https://github.com/ollama/ollama/blob/main/gpu/nvidia/runner.cu"
        }
    }
}
EOL

# 4. Reiniciar Ollama
sudo systemctl restart ollama
```

## 🌐 Problemas com OpenWebUI

### ❌ OpenWebUI Não Acessível

**Soluções**:
```bash
# 1. Verificar se container está rodando
docker ps | grep open-webui

# 2. Verificar logs
docker logs open-webui

# 3. Reiniciar container
docker restart open-webui

# 4. Verificar porta
netstat -tlnp | grep 8080

# 5. Testar conexão
curl http://localhost:8080/api/health
```

### ❌ Erro de Conexão com Ollama

**Soluções**:
```bash
# 1. Verificar se Ollama está acessível
curl http://localhost:11434/api/tags

# 2. Configurar variável de ambiente
export OLLAMA_BASE_URL=http://host.docker.internal:11434

# 3. Reiniciar OpenWebUI com configuração correta
docker run -e OLLAMA_BASE_URL=http://host.docker.internal:11434 ...
```

### ❌ Erro de Autenticação

**Soluções**:
```bash
# 1. Redefinir admin (deletar container e volume)
docker stop open-webui
docker rm open-webui
docker volume rm open-webui-data

# 2. Recriar com novo admin
docker run -e FIRST_ADMIN_USER=admin -e FIRST_ADMIN_PASSWORD=senha ...
```

## ⚡ Problemas com Dask Cluster

### ❌ Scheduler Não Inicia

**Soluções**:
```bash
# 1. Verificar processo
pgrep -f "dask-scheduler"

# 2. Matar processo existente
pkill -f "dask-scheduler"

# 3. Iniciar manualmente
source ~/cluster_env/bin/activate
dask-scheduler --host 0.0.0.0 --port 8786 &

# 4. Verificar porta
netstat -tlnp | grep 8786
```

### ❌ Workers Não Conectam

**Soluções**:
```bash
# 1. Verificar conexão com scheduler
nc -zv scheduler-ip 8786

# 2. Verificar firewall
sudo ufw allow 8786/tcp
sudo ufw allow 8787/tcp

# 3. Verificar configuração do worker
cat ~/.cluster_role

# 4. Reiniciar worker
pkill -f "dask-worker"
~/cluster_scripts/start_worker.sh
```

### ❌ Dashboard Não Acessível

**Soluções**:
```bash
# 1. Verificar se dashboard está rodando
pgrep -f "dask-scheduler"

# 2. Verificar porta do dashboard
netstat -tlnp | grep 8787

# 3. Acessar via IP correto
curl http://$(hostname -I | awk '{print $1}'):8787

# 4. Reiniciar scheduler com dashboard
dask-scheduler --dashboard --dashboard-address 0.0.0.0:8787
```

## 🔌 Problemas de Rede

### ❌ Conexão entre Máquinas

**Soluções**:
```bash
# 1. Verificar conectividade
ping outra-maquina

# 2. Verificar portas abertas
nc -zv outra-maquina 8786

# 3. Configurar SSH sem senha
ssh-copy-id usuario@outra-maquina

# 4. Verificar firewall
sudo ufw status
sudo ufw allow 8786/tcp
```

### ❌ IP Dinâmico

**Soluções**:
```bash
# 1. Usar nome de host no lugar de IP
echo "192.168.1.100 meu-servidor" | sudo tee -a /etc/hosts

# 2. Configurar DNS local
# 3. Usar serviço de DNS dinâmico
# 4. Script de reconexão automática
```

### ❌ Problemas de DNS

**Soluções**:
```bash
# 1. Verificar DNS
nslookup google.com

# 2. Configurar DNS alternativo
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# 3. Reiniciar networking
sudo systemctl restart systemd-networkd
```

## 💾 Problemas de Performance

### ❌ Uso Alto de CPU/Memória

**Soluções**:
```bash
# 1. Monitorar recursos
htop
glances

# 2. Limitar recursos por container
docker run --cpus=2 --memory=4g ...

# 3. Otimizar configuração Ollama
cat > ~/.ollama/config.json << EOL
{
    "environment": {
        "OLLAMA_MAX_LOADED_MODELS": "2",
        "OLLAMA_NUM_GPU_LAYERS": "20"
    }
}
EOL

# 4. Reduzir número de workers
dask-worker --nworkers 2 --nthreads 1
```

### ❌ Lentidão no Processamento

**Soluções**:
```bash
# 1. Verificar latência de rede
ping scheduler-ip

# 2. Otimizar tamanho dos chunks
import dask.array as da
x = da.random.random((10000, 10000), chunks=(1000, 1000))

# 3. Usar persist() para dados reutilizados
data = data.persist()

# 4. Verificar uso de disco
df -h
iotop
```

### ❌ Aquecimento Excessivo

**Soluções**:
```bash
# 1. Monitorar temperatura
sensors

# 2. Limitar uso de CPU
taskset -c 0-3 dask-worker  # Usar apenas cores 0-3

# 3. Configurar governador de CPU
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# 4. Melhorar ventilação/refrigeração
```

## 🚨 Problemas Críticos

### ❌ Sistema Não Inicia

**Procedimento de Emergência**:
```bash
# 1. Backup manual dos dados importantes
tar -czf emergency_backup.tar.gz ~/.ollama ~/.cluster_role

# 2. Verificar logs do sistema
journalctl -xe

# 3. Reiniciar serviços críticos
sudo systemctl restart docker ollama

# 4. Restaurar from backup se necessário
```

### ❊ Perda de Dados

**Recuperação**:
```bash
# 1. Verificar backups existentes
ls -la ~/cluster_backups/

# 2. Restaurar backup mais recente
./install_cluster.sh --restore

# 3. Restauração manual se necessário
tar -xzf backup_file.tar.gz -C ~

# 4. Reconfigurar serviços
./install_cluster.sh --role server
```

### ❌ Corrupção de Dados

**Soluções**:
```bash
# 1. Verificar integridade do disco
sudo fsck /dev/sda1

# 2. Restaurar from backup
# 3. Recriar estruturas corrompidas
rm -rf ~/.ollama/models/corrupted-model
ollama pull llama3

# 4. Verificar logs de erro
journalctl -u ollama --since "1 hour ago"
```

## 📊 Ferramentas de Diagnóstico

### Comandos Úteis
```bash
# Verificar serviços
systemctl status docker ollama

# Verificar recursos
htop, atop, glances

# Verificar rede
netstat -tlnp, ss -tlnp, ip addr

# Verificar disco
df -h, du -sh, iotop

# Verificar logs
journalctl -xe, docker logs, tail -f
```

### Scripts de Diagnóstico
```bash
#!/bin/bash
# cluster_diagnostics.sh

echo "=== DIAGNÓSTICO DO CLUSTER AI ==="

# Serviços
echo "📦 Serviços:"
systemctl status docker | grep Active
systemctl status ollama | grep Active

# Rede
echo "🌐 Rede:"
netstat -tlnp | grep -E '(8786|8787|8080|11434)'

# Processos
echo "⚡ Processos:"
pgrep -f "dask-|ollama" | xargs ps -o pid,comm,args -p

# Recursos
echo "💾 Recursos:"
free -h
df -h ~/

echo "✅ Diagnóstico concluído!"
```

## 🔄 Procedimentos de Recuperação

### Recuperação Rápida
```bash
# Parar tudo e recomeçar
pkill -f "dask-"
pkill -f "ollama"
sudo systemctl restart docker
./install_cluster.sh --role server
```

### Reset Completo
```bash
# Remover tudo e reinstalar
rm -rf ~/.ollama ~/cluster_scripts ~/open-webui ~/.cluster_role
./install_cluster.sh
```

## 📞 Suporte e Logs

### Coletar Logs para Suporte
```bash
# Script de coleta de logs
#!/bin/bash
echo "=== COLETA DE LOGS PARA SUPORTE ==="

# Informações do sistema
uname -a > cluster_support.txt
lsb_release -a >> cluster_support.txt

# Serviços
systemctl status docker >> cluster_support.txt
systemctl status ollama >> cluster_support.txt

# Processos
ps aux | grep -E '(dask|ollama)' >> cluster_support.txt

# Rede
netstat -tlnp >> cluster_support.txt

# Logs
journalctl -u docker --since "1 day ago" >> cluster_support.txt
journalctl -u ollama --since "1 day ago" >> cluster_support.txt

echo "📋 Logs salvos em cluster_support.txt"
```

### Canais de Suporte
1. **Documentação Oficial**: Consulte os manuais
2. **GitHub Issues**: Reporte bugs e problemas
3. **Comunidade**: Discord e fóruns especializados
4. **Logs**: Forneça logs detalhados para suporte

## 🎯 Checklist de Troubleshooting

### Antes de Pedir Ajuda
- [ ] Verificar logs (`journalctl -xe`)
- [ ] Testar conectividade de rede
- [ ] Verificar espaço em disco
- [ ] Confirmar serviços em execução
- [ ] Testar com configuração mínima

### Informações para Suporte
- [ ] Versão do sistema operacional
- [ ] Logs relevantes
- [ ] Configuração do cluster
- [ ] Passos para reproduzir o problema
- [ ] Screenshots ou mensagens de erro

---

**💡 Dica**: Muitos problemas podem ser resolvidos reiniciando os serviços ou verificando os logs. Sempre comece pelo diagnóstico básico.

**🚨 Emergência**: Em caso de perda de dados, NÃO reinstale imediatamente. Primeiro faça backup dos dados remanescentes e só então proceda com a recuperação.

**📚 Recursos**: Consulte a documentação oficial de cada componente para problemas específicos:
- [Dask Documentation](https://docs.dask.org/)
- [Ollama Documentation](https://ollama.ai/)
- [OpenWebUI Documentation](https://docs.openwebui.com/)
