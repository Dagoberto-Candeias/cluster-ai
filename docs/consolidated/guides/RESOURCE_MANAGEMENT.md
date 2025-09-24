# 📊 Sistema de Gerenciamento de Recursos - Cluster AI

Guia completo do sistema de gerenciamento de recursos auto-expansível que utiliza SSD como memória auxiliar para evitar falta de memória.

## 🎯 Visão Geral

O sistema de gerenciamento de recursos do Cluster AI foi projetado para:
- **Prevenir falta de memória** através de swap auto-expansível em SSD
- **Otimizar automaticamente** as configurações baseadas nos recursos disponíveis
- **Monitorar continuamente** o uso de CPU, memória e disco
- **Ajustar dinamicamente** a carga de trabalho para evitar travamentos

## 🏗️ Arquitetura do Sistema

### Componentes Principais

1. **Memory Manager** (`memory_manager.sh`)
   - Sistema de swap auto-expansível
   - Expansão/contração automática baseada no uso
   - Otimização de configurações do kernel

2. **Resource Optimizer** (`resource_optimizer.sh`)
   - Ajuste automático de configurações Dask/Ollama
   - Monitoramento contínuo de recursos
   - Medidas emergenciais para evitar travamentos

3. **Resource Checker** (`resource_checker.sh`)
   - Verificação pré-instalação de requisitos
   - Recomendações de configuração baseadas em hardware
   - Score de performance do sistema

## 🚀 Como Usar

### Iniciação Automática
O sistema é iniciado automaticamente durante a instalação do Cluster AI através do script principal.

### Comandos Manuais

#### Gerenciamento de Memória
```bash
# Iniciar monitoramento
bash ~/scripts/utils/memory_manager.sh start

# Ver status
bash ~/scripts/utils/memory_manager.sh status

# Expandir manualmente
bash ~/scripts/utils/memory_manager.sh expand

# Limpar configuração
bash ~/scripts/utils/memory_manager.sh clean
```

#### Otimização de Recursos
```bash
# Otimizar configurações
bash ~/scripts/utils/resource_optimizer.sh optimize

# Monitorar recursos
bash ~/scripts/utils/resource_optimizer.sh monitor

# Liberar memória imediatamente
bash ~/scripts/utils/resource_optimizer.sh free-memory
```

#### Verificação de Recursos
```bash
# Verificação completa
bash ~/scripts/utils/resource_checker.sh full

# Verificação rápida
bash ~/scripts/utils/resource_checker.sh quick
```

## ⚙️ Configurações

### Arquivo de Configuração do Memory Manager
Localizado em: `~/.cluster_optimization/`

Configurações padrão:
```bash
SWAP_DIR="$HOME/cluster_swap"          # Diretório do swap
MIN_SWAP_SIZE="2G"                     # Tamanho mínimo inicial
MAX_SWAP_SIZE="16G"                    # Tamanho máximo
SWAP_INCREMENT="1G"                    # Incremento de expansão
MEMORY_THRESHOLD=80                    # % de uso para expandir
CHECK_INTERVAL=30                      # Verificação a cada 30s
```

### Configurações do Resource Optimizer
O otimizador ajusta automaticamente:
- **Workers Dask**: Baseado em núcleos de CPU
- **Threads por Worker**: Baseado em capacidade
- **Limite de Memória**: 80% da RAM dividido pelos workers
- **Camadas GPU Ollama**: Baseado em memória disponível
- **Modelos Simultâneos**: Baseado em recursos totais

## 📊 Monitoramento

### Logs do Sistema
- **Memory Manager**: `~/.cluster_optimization/optimization.log`
- **Uso de Swap**: Monitorado em tempo real
- **Estatísticas**: Logadas a cada verificação

### Métricas Monitoradas
```bash
# Uso de CPU (%)
top -bn1 | grep "Cpu(s)" | awk '{print $2}'

# Uso de Memória (%)
free | awk '/Mem:/{printf("%.0f"), $3/$2 * 100}'

# Uso de Disco (%)
df -h / | awk 'NR==2{print $5}' | cut -d'%' -f1

# Uso de Swap (MB)
free -m | awk '/^Swap:/{print $3}'
```

## 🚨 Medidas Emergenciais

### Alta Utilização de CPU (>90%)
- Redução automática de workers Dask
- Priorização de processos críticos

### Alta Utilização de Memória (>85%)
- Expansão imediata do swap
- Liberação de cache do sistema
- Limpeza de cache do Ollama

### Alta Utilização de Disco (>90%)
- Limpeza de logs antigos
- Purge de cache do pip/Docker
- Remoção de arquivos temporários

## 🎯 Recomendações por Hardware

### Sistema Básico (2-4 cores, 4-8GB RAM)
```bash
# Configurações recomendadas
DASK_WORKERS=2
DASK_THREADS=1
MEMORY_LIMIT="1.5GB"
OLLAMA_LAYERS=10
OLLAMA_MODELS=1
```

### Sistema Intermediário (4-8 cores, 8-16GB RAM)
```bash
# Configurações recomendadas
DASK_WORKERS=4
DASK_THREADS=2
MEMORY_LIMIT="3GB"
OLLAMA_LAYERS=20
OLLAMA_MODELS=2
```

### Sistema Avançado (8+ cores, 16+GB RAM)
```bash
# Configurações recomendadas
DASK_WORKERS=6
DASK_THREADS=2
MEMORY_LIMIT="4GB"
OLLAMA_LAYERS=35
OLLAMA_MODELS=3
```

## 🔧 Solução de Problemas

### Problemas Comuns

#### Swap Não Expande
```bash
# Verificar permissões
ls -la ~/cluster_swap/

# Verificar espaço em disco
df -h /

# Reiniciar memory manager
bash ~/scripts/utils/memory_manager.sh stop
bash ~/scripts/utils/memory_manager.sh start
```

#### Uso Alto de CPU Persistente
```bash
# Verificar processos
top -bn1 | head -20

# Reduzir manualmente workers
sed -i 's/--nworkers [0-9]\+/--nworkers 2/' ~/cluster_scripts/start_worker.sh
```

#### Memória Insuficiente
```bash
# Liberar memória manualmente
bash ~/scripts/utils/resource_optimizer.sh free-memory

# Verificar modelos Ollama em uso
ollama ps

# Limpar modelos não usados
ollama ps | grep -v "NAME" | awk '{print $1}' | xargs -I {} ollama rm {}
```

### Comandos de Diagnóstico
```bash
# Status completo
bash ~/scripts/utils/resource_optimizer.sh status

# Verificar recursos
bash ~/scripts/utils/resource_checker.sh full

# Logs do sistema
tail -f ~/.cluster_optimization/optimization.log
```

## 📈 Performance Tips

### Para SSDs
```bash
# Ajustar swappiness para SSDs
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf

# Ajustar cache pressure
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf

# Aplicar configurações
sudo sysctl -p
```

### Para HDDs
```bash
# Configurações conservadoras para HDDs
echo "vm.swappiness=30" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=100" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Otimizações Específicas
```bash
# Para processamento intensivo
export OMP_NUM_THREADS=$(nproc)
export MKL_NUM_THREADS=$(nproc)

# Para modelos grandes de IA
export OLLAMA_NUM_PARALLEL=1
export OLLAMA_MAX_LOADED_MODELS=1
```

## 🔄 Integração com Script Principal

O sistema é integrado automaticamente ao:
1. **Pré-instalação**: Verificação de recursos
2. **Instalação**: Configuração automática
3. **Pós-instalação**: Monitoramento contínuo

### Fluxo de Integração
```
Script Principal → Resource Checker → Memory Manager → Resource Optimizer
      ↓                ↓                   ↓                ↓
   Instalação     Verificação        Swap Auto-Exp      Otimização
                   Prévia            Config Contínua    Dinâmica
```

## 📋 Checklist de Implantação

- [ ] Verificar recursos do sistema (`resource_checker.sh full`)
- [ ] Configurar swap auto-expansível (`memory_manager.sh start`)
- [ ] Otimizar configurações (`resource_optimizer.sh optimize`)
- [ ] Monitorar performance (`resource_optimizer.sh monitor`)
- [ ] Ajustar conforme necessidades específicas

## 🆘 Suporte

Para problemas específicos do sistema de gerenciamento de recursos:
1. Verifique os logs em `~/.cluster_optimization/optimization.log`
2. Execute `bash ~/scripts/utils/resource_optimizer.sh status`
3. Consulte este guia para configurações manuais
4. Reporte issues no repositório do projeto

---

**📖 Próximos Passos**: Consulte [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) para soluções de problemas específicos ou [OPTIMIZATION.md](../OPTIMIZATION.md) para técnicas avançadas de otimização.
