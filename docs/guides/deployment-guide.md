# 🚀 Guia Completo de Deploy do Cluster AI

## Visão Geral do Deploy

Este guia apresenta todas as opções de deploy disponíveis para o Cluster AI, desde configurações simples até ambientes de produção completos.

## 📋 Pré-requisitos

### Requisitos Mínimos
- **Sistema Operacional**: Linux (Ubuntu 20.04+, Debian 10+, Fedora 30+)
- **CPU**: 2 cores (4+ recomendado)
- **RAM**: 4GB (16GB+ recomendado)
- **Armazenamento**: 20GB SSD (100GB+ recomendado)
- **Rede**: Conexão internet para downloads

### Verificação de Recursos
```bash
# Verificar recursos do sistema
python3 -c "
import psutil
import shutil

print('=== RECURSOS DO SISTEMA ===')
print(f'CPUs Físicos: {psutil.cpu_count()}')
print(f'CPUs Lógicos: {psutil.cpu_count(logical=True)}')

mem = psutil.virtual_memory()
print(f'Memória Total: {mem.total / (1024**3):.1f}GB')
print(f'Memória Disponível: {mem.available / (1024**3):.1f}GB')

disk = shutil.disk_usage('/')
print(f'Disco Total: {disk.total / (1024**3):.1f}GB')
print(f'Disco Disponível: {disk.free / (1024**3):.1f}GB')
"
```

## 🎯 Opções de Deploy

### 1. Deploy Rápido (Recomendado para Iniciantes)

#### Passo 1: Instalação Automática
```bash
# Clone o repositório
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
cd cluster-ai

# Instalação inteligente (detecta hardware automaticamente)
bash install.sh --auto-role
```

#### Passo 2: Primeiro Uso
```bash
# Iniciar serviços
./manager.sh
# Selecionar: 1. Iniciar Todos os Serviços

# Acessar interfaces:
# - OpenWebUI: http://localhost:3000
# - Dask Dashboard: http://localhost:8787
# - Web Dashboard: http://localhost:3000
```

### 2. Deploy com Docker (Stack Completo)

#### Configuração Básica
```bash
# 1. Configurar variáveis de ambiente
cp .env.example .env
# Editar .env com suas configurações

# 2. Iniciar stack completo
docker-compose up -d

# 3. Verificar status
docker-compose ps

# 4. Verificar saúde dos serviços
curl -f http://localhost:8000/health
curl -f http://localhost:3000/health
```

#### Configuração Avançada
```bash
# Iniciar apenas serviços específicos
docker-compose up -d backend redis prometheus grafana

# Verificar logs em tempo real
docker-compose logs -f backend

# Escalar serviços
docker-compose up -d --scale worker=3
```

### 3. Deploy de Produção

#### Configuração com SSL/TLS
```bash
# 1. Gerar certificados
./scripts/security/generate_ssl.sh

# 2. Configurar produção
cp docker-compose.prod.yml docker-compose.override.yml
docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d

# 3. Configurar reverse proxy (nginx)
./scripts/installation/setup_nginx.sh
```

#### Configuração Multi-Node
```bash
# 1. Configurar cluster distribuído
./scripts/deployment/setup_multi_node.sh

# 2. Configurar load balancer
./scripts/deployment/setup_load_balancer.sh

# 3. Configurar monitoramento cross-node
./scripts/monitoring/setup_cluster_monitoring.sh
```

## 📊 Dashboards e Interfaces

### Dashboard Principal (React + FastAPI)
- **URL**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **Funcionalidades**:
  - Monitoramento em tempo real
  - Gerenciamento de workers
  - Métricas de sistema
  - Alertas e notificações

### Dask Dashboard
- **URL**: http://localhost:8787
- **Funcionalidades**:
  - Visualização de tarefas distribuídas
  - Monitoramento de workers
  - Análise de performance
  - Debug de aplicações

### Grafana Dashboard
- **URL**: http://localhost:3001
- **Credenciais**: admin/admin (alterar no primeiro acesso)
- **Funcionalidades**:
  - Visualização avançada de métricas
  - Dashboards customizáveis
  - Alertas configuráveis
  - Integração com Prometheus

### Prometheus
- **URL**: http://localhost:9090
- **Funcionalidades**:
  - Coleta de métricas
  - Consultas avançadas
  - Configuração de alertas
  - Integração com Grafana

### Kibana (ELK Stack)
- **URL**: http://localhost:5601
- **Funcionalidades**:
  - Análise de logs
  - Visualização de dados
  - Dashboards interativos
  - Busca avançada

## 🔧 Configuração de Workers

### Workers Linux
```bash
# Configuração automática
./scripts/deployment/auto_discover_workers.sh

# Configuração manual
./manager.sh
# Selecionar: 2. Gerenciar Workers
# Selecionar: 2. Adicionar Worker
```

### Workers Android (Termux)
```bash
# No dispositivo Android:
# 1. Instalar Termux
# 2. Executar configuração
bash setup_android_worker.sh

# No servidor principal:
./manager.sh
# Selecionar: 7. Configuração Guiada Android
```

## 📈 Monitoramento e Observabilidade

### Configuração Básica
```bash
# Iniciar monitoramento central
./scripts/monitoring/central_monitor.sh start

# Dashboard em tempo real
./scripts/monitoring/advanced_dashboard.sh live

# Monitoramento contínuo
./scripts/monitoring/advanced_dashboard.sh continuous 30
```

### Alertas e Notificações
```bash
# Configurar alertas
./scripts/monitoring/setup_alerts.sh

# Testar sistema de alertas
./scripts/monitoring/test_alerts.sh
```

### Métricas e Logs
```bash
# Coletar métricas
./scripts/monitoring/collect_metrics.sh

# Analisar logs
./scripts/monitoring/analyze_logs.sh

# Gerar relatórios
./scripts/monitoring/generate_report.sh
```

## 🔒 Segurança

### Configuração Básica
```bash
# Configurar firewall
./scripts/security/setup_firewall.sh

# Gerar certificados SSL
./scripts/security/generate_ssl.sh

# Configurar autenticação
./scripts/security/setup_auth.sh
```

### Configuração Avançada
```bash
# Configurar SELinux/AppArmor
./scripts/security/setup_selinux.sh

# Configurar auditoria
./scripts/security/setup_audit.sh

# Configurar backup seguro
./scripts/security/setup_secure_backup.sh
```

## 🔄 Backup e Recuperação

### Estratégias de Backup
```bash
# Backup completo
./scripts/backup/full_backup.sh

# Backup incremental
./scripts/backup/incremental_backup.sh

# Backup de configuração
./scripts/backup/config_backup.sh
```

### Recuperação
```bash
# Restaurar do backup
./scripts/backup/restore.sh

# Verificar integridade
./scripts/backup/verify_backup.sh
```

## 🧪 Testes e Validação

### Testes Automatizados
```bash
# Executar todos os testes
./run_tests.sh

# Testes específicos
python -m pytest tests/test_cluster.py -v
python -m pytest tests/test_workers.py -v
```

### Validação Manual
```bash
# Verificar saúde do sistema
./scripts/health_check.sh

# Testar conectividade
./scripts/test_connectivity.sh

# Validar configuração
./scripts/validate_config.sh
```

## 🚨 Solução de Problemas

### Problemas Comuns

#### Serviços não iniciam
```bash
# Verificar logs
docker-compose logs

# Verificar portas ocupadas
netstat -tlnp | grep :3000

# Reiniciar serviços
docker-compose restart
```

#### Workers não conectam
```bash
# Testar conectividade SSH
ssh -T worker@192.168.1.100

# Verificar configuração
cat cluster.yaml

# Reiniciar workers
./scripts/workers/restart_workers.sh
```

#### Performance degradada
```bash
# Verificar recursos
./scripts/monitoring/check_resources.sh

# Otimizar configuração
./scripts/optimization/optimize_config.sh

# Limpar cache
./scripts/maintenance/clean_cache.sh
```

## 📊 Monitoramento de Produção

### Métricas Principais
- **CPU Usage**: < 80%
- **Memory Usage**: < 85%
- **Disk I/O**: < 90%
- **Network Latency**: < 100ms
- **Active Workers**: Conforme capacidade

### Alertas Recomendados
```yaml
# Exemplo de configuração de alertas
alerts:
  - name: High CPU Usage
    condition: cpu_usage > 90
    duration: 5m
    severity: critical

  - name: Memory Pressure
    condition: memory_usage > 85
    duration: 10m
    severity: warning

  - name: Worker Disconnection
    condition: active_workers < min_workers
    duration: 2m
    severity: error
```

## 🔄 Atualização e Manutenção

### Atualização do Sistema
```bash
# Atualizar código
git pull origin main

# Atualizar dependências
pip install -r requirements.txt --upgrade

# Migrar banco de dados (se aplicável)
./scripts/migration/migrate_db.sh

# Reiniciar serviços
docker-compose restart
```

### Manutenção Regular
```bash
# Limpeza semanal
./scripts/maintenance/weekly_cleanup.sh

# Otimização mensal
./scripts/optimization/monthly_optimization.sh

# Backup diário
./scripts/backup/daily_backup.sh
```

## 📞 Suporte

### Recursos de Suporte
- **Documentação**: [docs/](../)
- **Issues**: [GitHub Issues](../../issues)
- **Discussões**: [GitHub Discussions](../../discussions)
- **Logs**: `logs/` directory

### Diagnóstico Rápido
```bash
# Coletar informações do sistema
./scripts/diagnostics/collect_info.sh

# Gerar relatório de diagnóstico
./scripts/diagnostics/generate_report.sh

# Enviar para suporte
./scripts/diagnostics/send_report.sh
```

---

**Última atualização**: Dezembro 2024
**Versão**: 1.0.1
**Autor**: Equipe Cluster AI
