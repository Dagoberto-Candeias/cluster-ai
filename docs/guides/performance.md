# 🚀 Guia de Otimização de Performance - Cluster AI

## 📋 Visão Geral

Este guia apresenta técnicas avançadas para otimizar o desempenho do Cluster AI, incluindo configurações do sistema, otimização de scripts e melhores práticas para processamento distribuído.

## 🛠️ Ferramentas de Otimização

### Otimizador de Performance

O script principal de otimização é `scripts/optimization/performance_optimizer.sh`. Ele automatiza várias otimizações para melhorar o desempenho geral do sistema.

### Funcionalidades do Otimizador

- **Otimização de Scripts Bash**: Paralelização de downloads, timeouts, tratamento de erros
- **Cache de Pacotes**: Configuração otimizada para diferentes distribuições Linux
- **Configurações do Sistema**: Limites de arquivos, configurações de kernel
- **Otimização Docker**: Configurações de logging, storage driver, ulimits
- **Otimização Python/Pip**: Cache, timeouts, mirrors
- **Benchmark**: Medição de performance dos scripts principais

## 🚀 Como Usar o Otimizador

### Execução Básica

```bash
# Executar todas as otimizações
./scripts/optimization/performance_optimizer.sh

# Verificar melhorias
./scripts/utils/health_check.sh
```

### O que o Otimizador Faz

1. **Scripts Bash**
   - Adiciona paralelização para downloads
   - Configura timeouts para comandos lentos
   - Otimiza loops e condições
   - Melhora tratamento de erros

2. **Cache de Pacotes**
   - Limpa cache antigo
   - Configura repositórios otimizados
   - Suporte para Ubuntu/Debian, Arch/Manjaro, Fedora/CentOS

3. **Sistema Operacional**
   - Aumenta limites de arquivos abertos (65536)
   - Otimiza configurações de kernel
   - Reduz swappiness para 10
   - Aumenta somaxconn para 65535

4. **Docker**
   - Configura storage driver overlay2
   - Otimiza logging (100MB max, 3 arquivos)
   - Aumenta ulimits para arquivos

5. **Python/Pip**
   - Configura cache pip
   - Adiciona timeouts e retries
   - Configura mirrors (PyPI, NGC, PyTorch)

## 📊 Benchmark de Performance

O otimizador inclui um sistema de benchmark que mede o tempo de execução dos scripts principais:

```json
{
  "timestamp": "2024-01-15T10:30:00+00:00",
  "benchmarks": {
    "install_universal.sh": 2.345,
    "scripts/utils/health_check.sh": 0.123,
    "scripts/utils/check_models.sh": 1.567
  }
}
```

## ⚡ Otimizações Manuais Avançadas

### Configurações de Kernel

```bash
# Arquivo /etc/sysctl.conf
vm.swappiness=10
vm.vfs_cache_pressure=50
net.core.somaxconn=65535
net.ipv4.tcp_max_syn_backlog=65535
```

### Limites do Sistema

```bash
# Arquivo /etc/security/limits.conf
* soft nofile 65536
* hard nofile 131072
* soft nproc 65536
* hard nproc 131072
```

### Docker Otimizado

```json
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "storage-opts": [
        "overlay2.override_kernel_check=true"
    ],
    "default-ulimits": {
        "nofile": {
            "Name": "nofile",
            "Hard": 65536,
            "Soft": 65536
        }
    }
}
```

## 🎯 Otimizações por Componente

### Dask Cluster

```python
# Configurações otimizadas para Dask
import dask
from dask.distributed import Client, LocalCluster

# Configurações de performance
dask.config.set({
    'distributed.worker.memory.target': 0.6,  # 60% da memória
    'distributed.worker.memory.spill': 0.7,   # Spill em 70%
    'distributed.worker.memory.pause': 0.8,   # Pause em 80%
    'distributed.worker.memory.terminate': 0.95,  # Terminate em 95%
    'distributed.comm.timeouts.connect': '10s',
    'distributed.comm.timeouts.tcp': '30s'
})

# Cluster local otimizado
cluster = LocalCluster(
    n_workers=4,
    threads_per_worker=2,
    memory_limit='2GB',
    processes=True,
    silence_logs=False
)
client = Client(cluster)
```

### Ollama

```bash
# Configurações para GPU
export OLLAMA_GPU_LAYERS=35
export OLLAMA_MAX_LOADED_MODELS=2
export OLLAMA_NUM_THREAD=8

# Otimização de memória
export OLLAMA_MAX_MODEL_SIZE=8GB
```

### OpenWebUI

```bash
# Configurações Docker otimizadas
docker run -d \
  --name open-webui \
  --restart unless-stopped \
  -p 8080:8080 \
  -v open-webui:/app/data \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
  --memory=2g \
  --cpus=2 \
  ghcr.io/open-webui/open-webui:main
```

## 📈 Monitoramento de Performance

### Métricas Principais

- **CPU**: Uso médio, picos, temperatura
- **Memória**: Uso total, swap, cache
- **Disco**: IOPS, latência, espaço livre
- **Rede**: Throughput, latência, conexões
- **Dask**: Tarefas por segundo, tempo médio, falhas
- **Ollama**: Tempo de inferência, uso de GPU
- **Docker**: Uso de recursos por container

### Ferramentas de Monitoramento

```bash
# Monitoramento em tempo real
htop
iotop
nvidia-smi
docker stats

# Scripts do Cluster AI
./scripts/monitoring/central_monitor.sh dashboard
./scripts/utils/health_check.sh
```

## 🔧 Troubleshooting de Performance

### Problemas Comuns

1. **CPU Alta**
   ```bash
   # Verificar processos
   ps aux --sort=-%cpu | head -10

   # Verificar load average
   uptime

   # Otimizar processos Python
   export OMP_NUM_THREADS=4
   export MKL_NUM_THREADS=4
   ```

2. **Memória Insuficiente**
   ```bash
   # Verificar uso de memória
   free -h
   vmstat 1

   # Configurar swap
   sudo fallocate -l 4G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

3. **Disco Lento**
   ```bash
   # Verificar I/O
   iostat -x 1

   # Otimizar para SSD
   sudo systemctl enable fstrim.timer
   ```

4. **Rede Lenta**
   ```bash
   # Verificar conectividade
   ping -c 4 8.8.8.8
   traceroute google.com

   # Otimizar TCP
   sudo sysctl -w net.ipv4.tcp_congestion_control=bbr
   ```

## 📚 Recomendações por Cenário

### Para Desenvolvimento
- Use SSD para melhor I/O
- Configure 16GB+ RAM
- Use GPU dedicada se disponível
- Otimize VSCode com extensions mínimas

### Para Produção
- Use RAID 1 ou 10 para dados
- Configure 32GB+ RAM
- Use GPU com 8GB+ VRAM
- Configure backup automático
- Use monitoramento 24/7

### Para Clusters Grandes
- Use rede 10GbE
- Configure storage distribuído
- Use load balancer
- Configure auto-scaling
- Use monitoramento centralizado

## 🎯 Benchmarks de Referência

### Tempos Esperados

- **Instalação**: 5-15 minutos
- **Download de modelo (7B)**: 2-5 minutos
- **Inferência (100 tokens)**: 1-3 segundos
- **Processamento Dask**: 10-50% mais rápido que single-thread

### Configurações de Referência

```yaml
# cluster.conf otimizado
[system]
memory_target = 0.6
cpu_threads = 8
gpu_layers = 35

[dask]
workers = 4
threads_per_worker = 2
memory_limit = 2GB

[ollama]
max_loaded_models = 2
gpu_layers = 35
num_thread = 8
```

## 📞 Suporte e Recursos

### Documentação Relacionada
- [Guia de Monitoramento](monitoring.md)
- [Troubleshooting](TROUBLESHOOTING.md)
- [Configuração Avançada](OPTIMIZATION.md)

### Ferramentas Externas
- [Dask Performance](https://docs.dask.org/en/latest/best-practices.html)
- [Ollama Performance](https://github.com/ollama/ollama/blob/main/docs/performance.md)
- [Docker Performance](https://docs.docker.com/config/containers/resource_constraints/)

---

**Última atualização:** $(date +%Y-%m-%d)  
**Mantenedor:** Equipe Cluster AI
