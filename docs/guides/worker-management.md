# 🚀 Gerenciamento de Workers - Cluster AI

Este guia detalha como configurar, gerenciar e otimizar workers no Cluster AI, com foco em configuração plug-and-play para máxima facilidade de uso.

## 🏗️ Arquitetura de Workers

### Tipos de Workers Suportados

#### 🐧 Workers Linux Nativos
- **Plataformas**: Ubuntu, Debian, Fedora, Arch Linux.
- **Requisitos**: Python 3.8+, SSH, conectividade de rede.
- **Casos de Uso**: Servidores dedicados, desktops, VMs.

#### 📱 Workers Android/Termux
- **Plataformas**: Android 7.0+ com Termux.
- **Requisitos**: Termux instalado, acesso root opcional.
- **Casos de Uso**: Dispositivos móveis, tablets, smartphones.

#### ☁️ Workers Cloud
- **Plataformas**: AWS EC2, GCP, Azure VMs.
- **Requisitos**: SSH configurado, Python instalado.
- **Casos de Uso**: Escalabilidade elástica, processamento sob demanda.

### Arquitetura de Comunicação
```
Scheduler (localhost:8786)
    ├── Worker Linux 1 (TCP/SSH)
    ├── Worker Linux 2 (TCP/SSH)
    ├── Worker Android 1 (SSH Tunnel)
    └── Worker Android 2 (SSH Tunnel)
```

## ⚡ Instalação Plug-and-Play

### Para Android/Termux (Mais Fácil)

#### Método One-Click
```bash
# Execute diretamente no Termux
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/termux_worker_setup.sh | bash
```

#### Método Manual
```bash
# 1. Baixar script
wget https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/termux_worker_setup.sh

# 2. Tornar executável
chmod +x termux_worker_setup.sh

# 3. Executar
./termux_worker_setup.sh
```

#### O que o Script Faz Automaticamente
- ✅ Instala Python 3.8+ e pip
- ✅ Configura SSH com chaves
- ✅ Instala dependências (dask, distributed)
- ✅ Detecta IP do scheduler automaticamente
- ✅ Configura worker com nome único
- ✅ Inicia worker em background
- ✅ Configura auto-restart

### Para Linux Nativo

#### Instalação Inteligente
```bash
# Instalador unificado (detecta sistema)
bash install_unified.sh --component workers

# Ou instalar tudo
bash install_unified.sh --auto-role worker
```

#### Configuração Manual
```bash
# 1. Instalar dependências
sudo apt update
sudo apt install -y python3 python3-pip openssh-server

# 2. Instalar Dask
pip3 install dask[distributed] --user

# 3. Configurar SSH (sem senha)
ssh-keygen -t rsa -b 4096
ssh-copy-id user@scheduler_ip

# 4. Testar conexão
ssh user@scheduler_ip "echo 'SSH funcionando'"

# 5. Iniciar worker
dask-worker tcp://scheduler_ip:8786 --name worker-$(hostname) --nthreads 4
```

## 📊 Gerenciamento de Workers

### Comandos Básicos
```bash
# Listar workers ativos
./scripts/management/worker_manager.sh list

# Ver status detalhado
./scripts/management/worker_manager.sh status worker-001

# Reiniciar worker
./scripts/management/worker_manager.sh restart worker-001

# Parar worker
./scripts/management/worker_manager.sh stop worker-001

# Remover worker
./scripts/management/worker_manager.sh remove worker-001
```

### Monitoramento em Tempo Real
```bash
# Dashboard de workers
./scripts/monitoring/worker_monitor.sh live

# Dashboard avançado
./scripts/monitoring/advanced_dashboard.sh live

# Métricas específicas
./scripts/monitoring/worker_monitor.sh --worker worker-001 --metrics cpu,memory,disk
```

### Auto-Scaling
```bash
# Configurar auto-scaling
./scripts/deployment/auto_scaling.sh enable --min 2 --max 10

# Verificar status
./scripts/deployment/auto_scaling.sh status

# Desabilitar
./scripts/deployment/auto_scaling.sh disable
```

## ⚙️ Configuração Avançada

### Arquivo de Configuração
Edite `config/cluster.conf`:
```ini
[workers]
default_threads = 4
default_memory = 2GB
auto_discovery = true
health_check_interval = 30
max_restart_attempts = 3
```

### Otimização de Recursos

#### Para CPU
```bash
# Worker otimizado para CPU
dask-worker tcp://localhost:8786 \
  --name cpu-worker \
  --nthreads 8 \
  --memory-limit 8GB \
  --no-dashboard
```

#### Para GPU
```bash
# Worker com GPU
dask-worker tcp://localhost:8786 \
  --name gpu-worker \
  --nthreads 2 \
  --memory-limit 16GB \
  --resources "GPU=1"
```

#### Para Android (Recursos Limitados)
```bash
# Worker leve para mobile
dask-worker tcp://scheduler_ip:8786 \
  --name android-worker \
  --nthreads 2 \
  --memory-limit 1GB \
  --no-dashboard \
  --death-timeout 60
```

### Segurança
- **SSH Keys**: Sempre use chaves SSH em vez de senhas.
- **Firewalls**: Configure regras para portas 8786-8787.
- **VPN**: Para workers remotos, considere VPN.
- **Monitoramento**: Logs de acesso em `logs/worker_access.log`.

## 🔧 Solução de Problemas

### Problemas Comuns

#### Worker Não Conecta
```bash
# Verificar conectividade de rede
ping scheduler_ip

# Testar SSH
ssh -T user@scheduler_ip

# Verificar portas abertas
telnet scheduler_ip 8786

# Logs do worker
tail -f ~/.dask-worker.log
```

#### Performance Baixa
```bash
# Verificar recursos
./scripts/optimization/worker_optimizer.sh --worker worker-001

# Ajustar threads
./scripts/management/worker_manager.sh config worker-001 --threads 6

# Monitorar uso
./scripts/monitoring/worker_monitor.sh --worker worker-001 --live
```

#### Worker Cai Frequentemente
```bash
# Verificar saúde
./scripts/health_check.sh worker worker-001

# Aumentar timeout
dask-worker tcp://scheduler_ip:8786 --death-timeout 120

# Configurar auto-restart
./scripts/management/worker_manager.sh config worker-001 --auto-restart true
```

#### Memória Insuficiente
```bash
# Reduzir limite de memória
./scripts/management/worker_manager.sh config worker-001 --memory 512MB

# Habilitar spill-to-disk
dask-worker tcp://scheduler_ip:8786 --memory-limit 1GB --memory-target-fraction 0.6
```

### Logs e Debugging
```bash
# Logs do scheduler
tail -f logs/dask_scheduler.log

# Logs do worker
tail -f logs/worker_monitor.log

# Debug detalhado
DASK_LOG_LEVEL=debug dask-worker tcp://scheduler_ip:8786 --name debug-worker
```

## 📈 Otimização de Performance

### Estratégias de Otimização
1. **Balanceamento de Carga**: Distribua tarefas uniformemente.
2. **Afinidade de CPU**: Fixe workers em CPUs específicas.
3. **Compressão de Dados**: Reduza tráfego de rede.
4. **Cache Inteligente**: Reuse resultados computacionais.

### Benchmarks
- **CPU Workers**: Até 8x speedup com 4 workers.
- **GPU Workers**: Até 50x speedup para ML workloads.
- **Android Workers**: Ideal para tarefas leves (< 1GB RAM).

### Monitoramento de Performance
```bash
# Relatório de performance
./scripts/monitoring/performance_report.sh --workers

# Alertas de performance
./scripts/monitoring/alert_manager.sh --enable worker_performance
```

## 🛡️ Segurança e Conformidade

### Melhores Práticas
- **Isolamento**: Use containers ou VMs para workers.
- **Autenticação**: SSH keys obrigatórias.
- **Monitoramento**: Logs de acesso e atividades.
- **Atualizações**: Mantenha workers atualizados.

### Configuração Segura
```bash
# SSH hardening
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Firewall
sudo ufw allow 8786/tcp
sudo ufw allow 8787/tcp
sudo ufw --force enable
```

## 📚 Casos de Uso Avançados

### Cluster Híbrido (Linux + Android)
```bash
# Scheduler em Linux
dask-scheduler --host 0.0.0.0 --port 8786

# Workers Linux
dask-worker tcp://scheduler_ip:8786 --name linux-01 --nthreads 8

# Workers Android
# Usar script termux_worker_setup.sh
```

### Auto-Scaling na Nuvem
```bash
# AWS Auto Scaling
./scripts/deployment/aws_autoscaling.sh setup --min 2 --max 20

# GCP Auto Scaling
./scripts/deployment/gcp_autoscaling.sh setup --min 1 --max 15
```

### Workers Especializados
```bash
# Worker para ML
dask-worker tcp://scheduler_ip:8786 --name ml-worker --resources "GPU=1,ML=1"

# Worker para análise de dados
dask-worker tcp://scheduler_ip:8786 --name data-worker --memory-limit 32GB
```

## 🚀 Roadmap

- **v1.1**: Suporte a Kubernetes pods como workers.
- **v1.2**: Auto-discovery via mDNS.
- **v2.0**: Workers serverless na nuvem.

Para suporte adicional, consulte [Dask Documentation](https://docs.dask.org/).

*Última atualização: 2025-01-28*
