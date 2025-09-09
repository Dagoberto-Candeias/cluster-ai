# 💾 Guia de Gerenciamento de Recursos do Sistema - Cluster AI

## 📋 Visão Geral

Este guia aborda o gerenciamento inteligente de recursos do sistema no Cluster AI, incluindo memória, CPU, disco e rede, com foco em otimização e eficiência.

## 🛠️ Componentes de Gerenciamento

### Sistema de Gerenciamento de Recursos

O Cluster AI inclui vários scripts para gerenciamento inteligente de recursos:

- `scripts/utils/memory_manager.sh`: Gerenciamento automático de memória e swap
- `scripts/utils/resource_checker.sh`: Verificação de recursos do sistema
- `scripts/utils/resource_optimizer.sh`: Otimização automática de configurações
- `scripts/monitoring/central_monitor.sh`: Monitoramento em tempo real

## 🚀 Gerenciamento de Memória

### Memory Manager

O script `scripts/utils/memory_manager.sh` gerencia automaticamente a memória do sistema:

```bash
# Verificar status da memória
./scripts/utils/memory_manager.sh status

# Expandir swap automaticamente
./scripts/utils/memory_manager.sh expand

# Limpar cache de memória
./scripts/utils/memory_manager.sh clean

# Otimizar uso de memória
./scripts/utils/memory_manager.sh optimize
```

### Funcionalidades

- **Swap Dinâmico**: Expande automaticamente quando necessário
- **Limpeza de Cache**: Remove caches desnecessários
- **Monitoramento**: Acompanha uso de memória em tempo real
- **Otimização**: Ajusta configurações para melhor uso

### Configurações Recomendadas

```bash
# /etc/sysctl.conf
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=10
vm.dirty_background_ratio=5
```

## ⚡ Gerenciamento de CPU

### Otimização de CPU

```bash
# Verificar uso de CPU
./scripts/utils/resource_checker.sh cpu

# Otimizar configurações de CPU
./scripts/utils/resource_optimizer.sh cpu

# Monitorar em tempo real
./scripts/monitoring/central_monitor.sh dashboard
```

### Técnicas de Otimização

1. **Governor de CPU**
   ```bash
   # Para performance máxima
   echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

   # Para balanceamento (recomendado)
   echo ondemand | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
   ```

2. **Afinidade de Processo**
   ```bash
   # Executar processo em CPUs específicas
   taskset -c 0-3 python meu_script.py

   # Para Dask workers
   export DASK_DISTRIBUTED__WORKER__RESOURCES__CPU=2
   ```

3. **Limites de Recursos**
   ```bash
   # Para containers Docker
   docker run --cpus=2 --cpuset-cpus=0-1 minha_imagem

   # Para processos do sistema
   cpulimit -l 50 python meu_script.py
   ```

## 💽 Gerenciamento de Disco

### Otimização de I/O

```bash
# Verificar uso de disco
./scripts/utils/resource_checker.sh disk

# Otimizar configurações de disco
./scripts/utils/resource_optimizer.sh disk

# Limpar espaço em disco
./scripts/utils/resource_optimizer.sh cleanup
```

### Técnicas de Otimização

1. **Sistema de Arquivos**
   ```bash
   # Para SSD (ext4 otimizado)
   sudo tune2fs -o journal_data_writeback /dev/sda1
   sudo tune2fs -O ^has_journal /dev/sda1

   # Para HDD (ext4 padrão)
   sudo tune2fs -o journal_data_ordered /dev/sda1
   ```

2. **Agendamento de I/O**
   ```bash
   # Para SSD
   echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler

   # Para HDD
   echo bfq | sudo tee /sys/block/sda/queue/scheduler
   ```

3. **Cache de Disco**
   ```bash
   # Aumentar cache de leitura
   sudo blockdev --setra 1024 /dev/sda

   # Configurar readahead
   sudo blockdev --setra 256 /dev/sda
   ```

## 🌐 Gerenciamento de Rede

### Otimização de Rede

```bash
# Verificar conectividade
./scripts/utils/resource_checker.sh network

# Otimizar configurações de rede
./scripts/utils/resource_optimizer.sh network

# Testar performance de rede
./scripts/utils/resource_checker.sh network --benchmark
```

### Configurações de Rede

```bash
# /etc/sysctl.conf
net.core.somaxconn=65535
net.core.netdev_max_backlog=5000
net.ipv4.tcp_max_syn_backlog=65535
net.ipv4.tcp_tw_reuse=1
net.ipv4.ip_local_port_range=1024 65535
```

### Ferramentas de Diagnóstico

```bash
# Testar velocidade de conexão
speedtest-cli

# Verificar latência
ping -c 10 google.com

# Analisar conexões
ss -tlnp
netstat -tlnp

# Monitorar tráfego
iftop
iptraf
```

## 🔧 Resource Checker

### Verificações Disponíveis

```bash
# Verificação completa
./scripts/utils/resource_checker.sh full

# Verificação rápida
./scripts/utils/resource_checker.sh quick

# Verificações específicas
./scripts/utils/resource_checker.sh cpu
./scripts/utils/resource_checker.sh memory
./scripts/utils/resource_checker.sh disk
./scripts/utils/resource_checker.sh network
```

### Saídas de Exemplo

```
🔍 VERIFICAÇÃO DE RECURSOS - Cluster AI
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 CPU
   Cores físicos: 4
   Cores lógicos: 8
   Uso atual: 45%
   Temperatura: 65°C
   Status: ✅ OK

🧠 MEMÓRIA
   Total: 16GB
   Usada: 8GB
   Livre: 8GB
   Swap: 4GB usado de 8GB
   Status: ✅ OK

💾 DISCO
   Total: 500GB
   Usado: 200GB
   Livre: 300GB
   Sistema: ext4
   Status: ✅ OK

🌐 REDE
   Interface: eth0
   IP: 192.168.1.100
   Gateway: 192.168.1.1
   DNS: 8.8.8.8
   Status: ✅ OK

⚡ AVALIAÇÃO GERAL
   Pontuação: 85/100
   Status: ✅ SISTEMA SAUDÁVEL
```

## 🎯 Resource Optimizer

### Otimizações Disponíveis

```bash
# Otimização completa
./scripts/utils/resource_optimizer.sh optimize

# Otimizações específicas
./scripts/utils/resource_optimizer.sh cpu
./scripts/utils/resource_optimizer.sh memory
./scripts/utils/resource_optimizer.sh disk
./scripts/utils/resource_optimizer.sh network

# Modo debug
./scripts/utils/resource_optimizer.sh optimize --debug
```

### Otimizações Aplicadas

1. **CPU**
   - Ajusta governor para performance
   - Configura afinidade de processos
   - Otimiza scheduling

2. **Memória**
   - Ajusta swappiness
   - Configura cache pressure
   - Otimiza dirty ratios

3. **Disco**
   - Ajusta scheduler de I/O
   - Configura readahead
   - Otimiza sistema de arquivos

4. **Rede**
   - Ajusta buffers TCP
   - Configura congestion control
   - Otimiza timeouts

## 📊 Monitoramento em Tempo Real

### Dashboard do Sistema

```bash
# Iniciar dashboard
./scripts/monitoring/central_monitor.sh dashboard

# Monitoramento contínuo
./scripts/monitoring/central_monitor.sh monitor

# Ver alertas
./scripts/monitoring/central_monitor.sh alerts
```

### Métricas Monitoradas

- **Sistema**: CPU, memória, disco, rede
- **Aplicações**: Dask, Ollama, OpenWebUI
- **Containers**: Docker stats
- **Workers**: Android workers (simulado)

## 🚨 Sistema de Alertas

### Thresholds Configuráveis

```bash
# Arquivo de configuração
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_DISK=90
ALERT_THRESHOLD_BATTERY=20
```

### Tipos de Alertas

- **CRITICAL**: Ação imediata necessária
- **WARNING**: Atenção necessária
- **INFO**: Informações relevantes

### Exemplo de Alerta

```
🚨 ALERTA CRÍTICO: MEMORY - Uso de memória alto: 90% (threshold: 85%)
📅 2024-01-15 14:30:25
🔧 Ações recomendadas:
   - Verificar processos com alto uso de memória
   - Considerar expansão de swap
   - Reiniciar serviços não essenciais
```

## 📈 Relatórios e Logs

### Geração de Relatórios

```bash
# Relatório completo
./scripts/utils/resource_checker.sh full --report

# Relatório de otimização
./scripts/utils/resource_optimizer.sh optimize --report

# Relatório de monitoramento
./scripts/monitoring/central_monitor.sh report
```

### Estrutura de Logs

```
logs/
├── resource_checker.log
├── resource_optimizer.log
├── memory_manager.log
└── central_monitor.log

metrics/
├── system_metrics.json
├── optimization_metrics.json
└── performance_benchmarks.json
```

## 🔧 Troubleshooting

### Problemas Comuns

1. **Memory Manager não expande swap**
   ```bash
   # Verificar permissões
   ls -la ~/cluster_swap/
   chmod 755 ~/cluster_swap/

   # Verificar espaço em disco
   df -h /

   # Reiniciar manualmente
   ./scripts/utils/memory_manager.sh stop
   ./scripts/utils/memory_manager.sh start
   ```

2. **Resource Checker falha**
   ```bash
   # Verificar dependências
   command -v free || sudo apt install procps
   command -v df || sudo apt install coreutils

   # Executar com debug
   ./scripts/utils/resource_checker.sh full --debug
   ```

3. **Resource Optimizer não aplica mudanças**
   ```bash
   # Verificar permissões sudo
   sudo -l

   # Executar como root
   sudo ./scripts/utils/resource_optimizer.sh optimize

   # Verificar logs
   tail -f ~/.cluster_optimization/optimization.log
   ```

## 📚 Recomendações por Cenário

### Para Desenvolvimento
- **CPU**: 4+ cores
- **Memória**: 8GB+ RAM
- **Disco**: 50GB+ SSD
- **Rede**: 100Mbps+

### Para Produção
- **CPU**: 8+ cores
- **Memória**: 16GB+ RAM
- **Disco**: 200GB+ SSD
- **Rede**: 1Gbps+

### Para Clusters
- **CPU**: 16+ cores por nó
- **Memória**: 32GB+ RAM por nó
- **Disco**: 500GB+ SSD por nó
- **Rede**: 10Gbps+

## 🎯 Melhores Práticas

### Monitoramento Contínuo
1. Configure alertas para thresholds críticos
2. Monitore tendências de uso de recursos
3. Faça backup regular de configurações
4. Atualize sistema regularmente

### Otimização Proativa
1. Execute verificações semanais
2. Aplique otimizações preventivas
3. Monitore impacto das mudanças
4. Documente configurações customizadas

### Manutenção
1. Limpe caches regularmente
2. Monitore saúde do disco
3. Atualize kernels e drivers
4. Faça backup antes de mudanças

## 📞 Suporte

### Recursos de Ajuda
- [Guia de Performance](performance.md)
- [Guia de Monitoramento](monitoring.md)
- [Troubleshooting](TROUBLESHOOTING.md)

### Scripts de Diagnóstico
```bash
# Diagnóstico completo
./scripts/utils/health_check.sh

# Verificação de recursos
./scripts/utils/resource_checker.sh full

# Otimização automática
./scripts/utils/resource_optimizer.sh optimize
```

---

**Última atualização:** $(date +%Y-%m-%d)  
**Mantenedor:** Equipe Cluster AI
