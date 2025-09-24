# 🚀 Técnicas Avançadas de Otimização - Cluster AI

## 🎯 Visão Geral

Este guia cobre técnicas avançadas de otimização para maximizar a performance do Cluster AI em diferentes cenários e configurações de hardware.

## 📊 Otimização de Hardware

### Configuração de CPU

#### Ajuste de Governadores
```bash
# Performance máximo (consumo maior)
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Balanceado (recomendado)
echo ondemand | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Economia de energia
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

#### Ajuste de Frequência
```bash
# Verificar frequências disponíveis
cpufreq-info

# Definir frequência mínima/máxima
sudo cpufreq-set -c 0 -g performance -d 2.0GHz -u 4.0GHz

# Para todos os cores
for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
    echo 4000000 | sudo tee $cpu/scaling_max_freq
done
```

### Otimização de Memória

#### Swappiness para SSDs
```bash
# Valor baixo para SSDs (10-30)
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

# Valor médio para HDDs (30-60)
echo "vm.swappiness=30" | sudo tee -a /etc/sysctl.conf

# Cache pressure para SSDs
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf

# Aplicar configurações
sudo sysctl -p
```

#### Transparent Huge Pages
```bash
# Verificar status
cat /sys/kernel/mm/transparent_hugepage/enabled

# Desativar (pode melhorar performance em alguns casos)
echo never | sudo tee /sys/kernel/mm/transparent_hugepage/enabled

# Ativar
echo always | sudo tee /sys/kernel/mm/transparent_hugepage/enabled
```

### Otimização de Disco

#### Mount Options para SSDs
```bash
# Editar fstab
sudo nano /etc/fstab

# Adicionar opções para SSDs
UUID=xxxx-xxxx / ext4 defaults,noatime,nodiratime,discard 0 1

# Para HDDs
UUID=xxxx-xxxx / ext4 defaults,noatime,nodiratime 0 1
```

#### I/O Scheduler
```bash
# Verificar scheduler atual
cat /sys/block/sda/queue/scheduler

# Para SSDs (usar none ou mq-deadline)
echo none | sudo tee /sys/block/sda/queue/scheduler

# Para HDDs (usar mq-deadline ou bfq)
echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler
```

## 🤖 Otimização do Ollama

### Configuração de GPU

#### Camadas GPU por Modelo
```bash
# Configuração por modelo
cat > ~/.ollama/models/config/llama3 << EOL
{
    "gpu_layers": 35,
    "num_gpu": 1,
    "main_gpu": 0,
    "tensor_split": "1"
}
EOL

# Para GPU com pouca VRAM
cat > ~/.ollama/models/config/small-model << EOL
{
    "gpu_layers": 15,
    "num_thread": 8,
    "batch_size": 512
}
EOL
```

#### Otimização de VRAM
```bash
# Monitorar uso de VRAM
nvidia-smi -l 1

# Configurar split entre GPU/CPU
export OLLAMA_GPU_LAYERS=20
export OLLAMA_NUM_THREAD=12

# Limitar VRAM por processo
export CUDA_VISIBLE_DEVICES=0
export CUDA_MPS_ACTIVE_THREAD_PERCENTAGE=50
```

### Otimização de Modelos

#### Quantização
```bash
# Baixar versões quantizadas
ollama pull llama3:8b-q4_0
ollama pull codellama:7b-q2_k

# Comparar performance vs precisão
# q4_0 - Boa performance, boa precisão
# q2_k - Máxima performance, menor precisão
# f16 - Máxima precisão, menor performance
```

#### Batch Size e Contexto
```bash
# Ajustar batch size para seu hardware
export OLLAMA_MAX_BATCH_SIZE=512
export OLLAMA_MAX_CTX_SIZE=4096

# Para GPUs potentes
export OLLAMA_MAX_BATCH_SIZE=1024
export OLLAMA_MAX_CTX_SIZE=8192
```

## ⚡ Otimização do Dask Cluster

### Configuração de Workers

#### Balanceamento por Hardware
```bash
# Baseado em núcleos de CPU
NUM_CORES=$(nproc)
NUM_WORKERS=$((NUM_CORES / 2))  # 50% dos cores
NUM_THREADS=$((NUM_CORES / NUM_WORKERS))

dask-worker --nworkers $NUM_WORKERS --nthreads $NUM_THREADS
```

#### Memory Management
```bash
# Calcular limite de memória por worker
TOTAL_MEM=$(free -g | awk '/Mem:/{print $2}')
MEM_PER_WORKER=$((TOTAL_MEM / NUM_WORKERS))

dask-worker --memory-limit ${MEM_PER_WORKER}GB
```

### Otimização de Task Graphs

#### Chunk Size Optimization
```python
import dask.array as da
import dask.dataframe as dd

# Para arrays grandes (ajustar baseado em RAM)
optimal_chunk_size = "256MB"  # ou "512MB", "1GB"

# Criar array com chunks otimizados
array = da.random.random((100000, 1000), chunks=(1000, 100))

# Para dataframes
df = dd.read_parquet("data.parquet", chunksize="256MB")
```

#### Persistência Estratégica
```python
# Persistir dados reutilizados frequentemente
data = data.persist()

# Persistir com memória limitada
from dask.distributed import Client
client = Client(memory_limit='4GB')

data = client.persist(data)
```

## 🌐 Otimização de Rede

### Configuração de TCP
```bash
# Otimizar buffer TCP
echo "net.core.rmem_max=16777216" | sudo tee -a /etc/sysctl.conf
echo "net.core.wmem_max=16777216" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_rmem=4096 87380 16777216" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_wmem=4096 65536 16777216" | sudo tee -a /etc/sysctl.conf

# Aumentar conexões máximas
echo "net.core.somaxconn=65535" | sudo tee -a /etc/sysctl.conf

# Aplicar configurações
sudo sysctl -p
```

### Otimização para Clusters

#### Latência entre Nós
```bash
# Testar latência
ping -c 10 worker-node

# Usar IPs estáticos ou DNS local
echo "192.168.1.100 worker1" | sudo tee -a /etc/hosts

# Configurar MTU otimizado
sudo ip link set eth0 mtu 9000  # Jumbo frames se suportado
```

#### Throughput Optimization
```bash
# Verificar throughput
iperf3 -c worker-node

# Ajustar window scaling
echo "net.ipv4.tcp_window_scaling=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_timestamps=1" | sudo tee -a /etc/sysctl.conf
```

## 💾 Otimização de Disco para Dados

### Filesystem Tuning
```bash
# Ext4 otimizado para SSDs
sudo mkfs.ext4 -O ^has_journal -E lazy_itable_init=0,lazy_journal_init=0 /dev/sdX

# XFS para alta performance
sudo mkfs.xfs -f /dev/sdX

# Mount options otimizadas
UUID=xxxx-xxxx /data xfs defaults,noatime,nodiratime 0 2
```

### Caching Strategies
```bash
# Usar ramdisk para cache temporário
sudo mkdir /ramcache
sudo mount -t tmpfs -o size=2G tmpfs /ramcache

# Configurar Ollama para usar ramdisk
export OLLAMA_TMPDIR=/ramcache
```

## 🔧 Tuning Fino por Caso de Uso

### Para Inferência de IA
```bash
# Maximizar throughput de inferência
export OLLAMA_NUM_PARALLEL=1
export OLLAMA_MAX_LOADED_MODELS=1
export CUDA_LAUNCH_BLOCKING=0

# Priorizar processos de inferência
sudo nice -n -10 ollama serve
```

### Para Treinamento de Modelos
```bash
# Maximizar uso de GPU para treino
export CUDA_VISIBLE_DEVICES=0
export TF_FORCE_GPU_ALLOW_GROWTH=true
export NVIDIA_TF32_OVERRIDE=1

# Otimizar memória para treino
export XLA_PYTHON_CLIENT_MEM_FRACTION=0.8
```

### Para Processamento de Dados
```bash
# Otimizar Dask para ETL
export DASK_DISTRIBUTED__WORKER__MEMORY__TARGET=0.8
export DASK_DISTRIBUTED__WORKER__MEMORY__SPILL=0.9
export DASK_DISTRIBUTED__WORKER__MEMORY__PAUSE=0.95

# Usar compressed serialization
export DASK_DISTRIBUTED__COMM__COMPRESSION="lz4"
```

## 📈 Monitoring e Ajuste Contínuo

### Script de Auto-Otimização
```bash
#!/bin/bash
# auto_optimizer.sh

# Monitorar recursos e ajustar dinamicamente
while true; do
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    MEM_USAGE=$(free | awk '/Mem:/{printf("%.0f"), $3/$2 * 100}')
    
    if [ $CPU_USAGE -gt 85 ]; then
        echo "CPU alta ($CPU_USAGE%) - reduzindo workers"
        pkill -f "dask-worker" && sleep 2
        dask-worker --nworkers 2 --nthreads 1 &
    fi
    
    if [ $MEM_USAGE -gt 90 ]; then
        echo "Memória alta ($MEM_USAGE%) - expandindo swap"
        ~/scripts/utils/memory_manager.sh expand
    fi
    
    sleep 30
done
```

### Metrics Collection
```bash
# Coletar métricas para análise
#!/bin/bash
collect_metrics() {
    echo "$(date),$(top -bn1 | grep "Cpu(s)" | awk '{print $2}'),$(free | awk '/Mem:/{printf("%.0f"), $3/$2 * 100}'),$(df -h / | awk 'NR==2{print $5}' | cut -d'%' -f1)" >> metrics.csv
}

# Coletar a cada minuto
while true; do
    collect_metrics
    sleep 60
done
```

## 🎯 Best Practices

### Para Produção
1. **Monitoramento Contínuo**: Implementar alertas para recursos críticos
2. **Backup Automático**: Backup diário de configurações e modelos
3. **Scaling Horizontal**: Adicionar workers conforme necessidade
4. **Health Checks**: Verificações automáticas de saúde dos serviços

### Para Desenvolvimento
1. **Isolamento**: Usar containers ou VMs para desenvolvimento
2. **Versionamento**: Versionar todas as configurações
3. **Documentação**: Manter documentação atualizada das otimizações
4. **Testing**: Testar otimizações em ambiente staging antes de produção

### Para High Performance
1. **SSD NVMe**: Usar storage de alta velocidade
2. **GPU dedicada**: Preferir GPUs dedicadas para inferência
3. **Rede 10Gbps**: Para clusters distribuídos
4. **RAM abundante**: Mínimo 16GB, ideal 32GB+

## 🔄 Workflows de Otimização

### Otimização Iterativa
```
1. Baseline → Medir performance atual
2. Identificar → Encontrar gargalos
3. Ajustar → Aplicar otimizações
4. Medir → Verificar melhoria
5. Repetir → Até atingir objetivos
```

### Ferramentas de Análise
```bash
# Performance analysis
perf stat -d python script.py
py-spy record -o profile.svg -- python script.py

# Memory analysis
mprof run python script.py
fil-profile run script.py

# GPU analysis
nvidia-smi dmon
nvprof python script.py
```

## 📊 Tabelas de Referência

### Configurações Recomendadas por Hardware

| Hardware | Workers | Threads | Memória/Worker | GPU Layers |
|----------|---------|---------|----------------|------------|
| 4C/8GB   | 2       | 2       | 2GB            | 10         |
| 8C/16GB  | 4       | 2       | 3GB            | 20         |
| 16C/32GB | 8       | 2       | 4GB            | 35         |
| 32C/64GB | 16      | 2       | 4GB            | 40         |

### Tipos de Quantização Ollama

| Tipo     | Tamanho | Performance | Precisão | Uso Recomendado |
|----------|---------|-------------|----------|-----------------|
| q2_k     | 2-bit   | ⭐⭐⭐⭐⭐     | ⭐⭐      | Prototipagem    |
| q4_0     | 4-bit   | ⭐⭐⭐⭐      | ⭐⭐⭐     | Produção        |
| q6_k     | 6-bit   | ⭐⭐⭐       | ⭐⭐⭐⭐   | Alta precisão   |
| q8_0     | 8-bit   | ⭐⭐        | ⭐⭐⭐⭐⭐  | Máxima precisão |
| f16      | 16-bit  | ⭐          | ⭐⭐⭐⭐⭐  | Treinamento     |

## 🆘 Troubleshooting de Otimização

### Problemas Comuns
```bash
# Oversubscription de CPU
# Sintoma: Lentidão geral do sistema
# Solução: Reduzir número de workers/threads

# Memory thrashing
# Sintoma: Swap constante, performance ruim
# Solução: Aumentar RAM ou reduzir carga

# GPU memory overflow
# Sintoma: Erros CUDA out of memory
# Solução: Reduzir batch size ou GPU layers
```

### Ferramentas de Diagnóstico
```bash
# Verificar oversubscription
mpstat -P ALL 1

# Verificar memory pressure
vmstat 1

# Verificar I/O wait
iostat -x 1

# Verificar GPU utilization
nvidia-smi -l 1
```

---

**📚 Próximos Passos**: 
- Consulte [RESOURCE_MANAGEMENT.md](RESOURCE_MANAGEMENT.md) para gerenciamento automático de recursos
- Consulte [TROUBLESHOOTING.md](TROUBLESHOOTING.md) para solução de problemas
- Experimente diferentes configurações e meça os resultados
- Documente as otimizações que funcionam melhor para seu caso de uso

**💡 Dica**: Sempre teste otimizações em ambiente controlado antes de aplicar em produção. Performance pode variar significativamente dependendo do hardware e carga de trabalho específicos.
