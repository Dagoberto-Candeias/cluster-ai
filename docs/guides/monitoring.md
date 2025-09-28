# 📊 Guia de Monitoramento - Cluster AI

## 📋 Visão Geral

Este guia descreve as ferramentas e práticas para monitorar o Cluster AI, garantindo alta disponibilidade, desempenho e segurança do sistema.

## 🛠️ Ferramentas de Monitoramento

### Sistema Central de Monitoramento

O script principal de monitoramento é `scripts/monitoring/central_monitor.sh`. Ele coleta métricas do sistema, cluster e workers Android, gera alertas e exibe dashboards em tempo real.

### Métricas Coletadas

- **CPU**: Uso, temperatura, load average
- **Memória**: Total, usada, livre, disponível, percentual de uso
- **Disco**: Uso percentual, total, usado e disponível em GB
- **Rede**: Dados recebidos e enviados em MB
- **Cluster**: Status dos processos Ollama, Dask, OpenWebUI, número de workers, tarefas concluídas e falhadas, memória usada pelo Dask
- **Workers Android**: Número de workers ativos, nível médio de bateria, uso médio de CPU e memória, latência de rede

### Alertas

O sistema gera alertas para:

- Uso alto de CPU, memória e disco
- Bateria baixa em workers Android

Os alertas são registrados em logs e exibidos no terminal com níveis de severidade (CRITICAL, WARNING).

## 🚦 Uso do Script de Monitoramento

### Comandos Disponíveis

```bash
./scripts/monitoring/central_monitor.sh monitor
./scripts/monitoring/central_monitor.sh dashboard
./scripts/monitoring/central_monitor.sh alerts
./scripts/monitoring/central_monitor.sh report
./scripts/monitoring/central_monitor.sh rotate
```

- `monitor`: Inicia monitoramento contínuo com coleta de métricas e alertas
- `dashboard`: Exibe dashboard em tempo real no terminal
- `alerts`: Mostra histórico dos últimos alertas
- `report`: Gera relatório JSON com métricas atuais
- `rotate`: Rotaciona logs antigos para manutenção

### Exemplo de Uso

```bash
# Iniciar monitoramento contínuo
./scripts/monitoring/central_monitor.sh monitor

# Visualizar dashboard em tempo real
./scripts/monitoring/central_monitor.sh dashboard

# Ver alertas recentes
./scripts/monitoring/central_monitor.sh alerts

# Gerar relatório de métricas
./scripts/monitoring/central_monitor.sh report

# Rotacionar logs antigos
./scripts/monitoring/central_monitor.sh rotate
```

## 📈 Interpretação dos Dados

- **Uso de CPU/Memória/Disco**: Valores acima dos thresholds configurados indicam necessidade de ação
- **Status do Cluster**: Indica se os serviços principais estão rodando corretamente
- **Alertas**: Priorize alertas críticos para evitar falhas no sistema

## 🔧 Configuração

Os thresholds e intervalos podem ser configurados nos arquivos:

- `config/monitor.conf`
- `config/alerts.conf`

## 📚 Referências

- [Dask Monitoring](https://distributed.dask.org/en/latest/monitor.html)
- [Linux System Monitoring Tools](https://linux.die.net/man/1/top)
- [Docker Monitoring](https://docs.docker.com/config/containers/resource_constraints/)

---

**Última atualização:** $(date +%Y-%m-%d)  
**Mantenedor:** Equipe Cluster AI
