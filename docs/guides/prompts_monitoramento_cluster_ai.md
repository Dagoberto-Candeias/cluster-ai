# 📊 Catálogo de Prompts para Monitoramento - Cluster-AI

## 🎯 Guia Rápido de Utilização

### Configurações Recomendadas
- **Temperatura Baixa (0.1-0.3)**: Para configuração, dashboards, alertas
- **Temperatura Média (0.4-0.6)**: Para análise, troubleshooting
- **Temperatura Alta (0.7-0.9)**: Para otimização, inovação

### Modelos por Categoria
- **LLM Geral**: Llama 3, Mixtral, Mistral
- **Codificação**: CodeLlama, Qwen2.5-Coder, DeepSeek-Coder

---

## 📁 CATEGORIA: MÉTRICAS E MONITORAMENTO

### 1. Sistema de Métricas Completo
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de observabilidade]

Configure sistema completo de métricas para Cluster-AI:

**Métricas essenciais:**
- Performance dos workers
- Latência de resposta da API
- Utilização de recursos (CPU, memória, disco)
- Throughput de tarefas
- Health checks

**Ferramentas:** [Prometheus, Grafana, custom metrics]

**Solicito:**
1. Configuração do Prometheus
2. Métricas customizadas do Cluster-AI
3. Service discovery automático
4. Estratégia de retenção
5. High availability setup
```

### 2. Dashboards de Monitoramento
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em dashboards]

Crie dashboards abrangentes para Cluster-AI:

**Dashboards necessários:**
- Visão geral do sistema
- Performance dos workers
- API endpoints
- Recursos de infraestrutura
- Alertas ativos

**Ferramenta:** [Grafana/Kibana]

**Solicito:**
1. Dashboard principal (system overview)
2. Dashboard de performance
3. Dashboard de infraestrutura
4. Dashboard de negócio (SLIs/SLOs)
5. Templates reutilizáveis
```

### 3. Service Level Indicators (SLIs) e Objectives (SLOs)
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um SRE especializado em SLOs]

Defina SLIs e SLOs para Cluster-AI:

**Serviços críticos:**
- API de submissão de tarefas
- Processamento de workers
- Comunicação inter-nós
- Armazenamento de resultados

**Objetivos de negócio:** [disponibilidade, performance, etc.]

**Solicito:**
1. Identificação de SLIs relevantes
2. Definição de SLOs realistas
3. Estratégia de medição
4. Error budgets
5. Plano de melhoria contínua
```

---

## 📁 CATEGORIA: LOGGING E ANÁLISE

### 4. Estratégia de Logging Centralizado
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de logging]

Implemente logging centralizado para Cluster-AI:

**Fontes de logs:**
- Aplicação Python (manager/workers)
- Nginx access/error logs
- System logs (journald/syslog)
- Container logs (Docker/Kubernetes)

**Stack:** [ELK, Loki+Promtail, Fluentd]

**Solicito:**
1. Configuração de coleta de logs
2. Estrutura de indexação
3. Políticas de retenção
4. Busca e análise eficientes
5. Integração com métricas
```

### 5. Análise de Logs Estruturados
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um log analyst]

Configure análise avançada de logs para Cluster-AI:

**Tipos de análise:**
- Busca e filtragem
- Agregação e estatísticas
- Detecção de anomalias
- Correlação de eventos
- Alerting baseado em logs

**Ferramentas:** [Elasticsearch, Loki, Splunk]

**Solicito:**
1. Parsing e estruturação de logs
2. Queries de análise comuns
3. Dashboards de análise
4. Alertas baseados em padrões
5. Relatórios automatizados
```

### 6. Log Aggregation e Correlation
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em log aggregation]

Implemente correlação avançada de logs no Cluster-AI:

**Cenários de correlação:**
- Request tracing (request ID)
- Error correlation
- Performance degradation
- Security events
- Business metrics

**Ferramentas:** [Fluentd, Logstash, Vector]

**Solicito:**
1. Estratégia de correlação
2. Configuração de agregação
3. Enriquecimento de logs
4. Visualização de fluxos
5. Alertas de correlação
```

---

## 📁 CATEGORIA: DISTRIBUTED TRACING

### 7. Implementação de Distributed Tracing
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um tracing engineer]

Configure distributed tracing completo para Cluster-AI:

**Serviços a rastrear:**
- Manager API endpoints
- Worker task execution
- Database queries
- External API calls
- Async operations

**Ferramentas:** [Jaeger, Zipkin, OpenTelemetry]

**Solicito:**
1. Instrumentation do código
2. Configuração do collector
3. Sampling strategies
4. Custom spans e tags
5. Integração com métricas
```

### 8. Tracing para Performance Analysis
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um performance analyst]

Configure tracing para análise de performance no Cluster-AI:

**Cenários de análise:**
- Latência de requests
- Bottlenecks identification
- Resource consumption
- Error propagation
- Service dependencies

**Ferramentas:** [Jaeger UI, custom dashboards]

**Solicito:**
1. Tracing de performance crítica
2. Análise de bottlenecks
3. Service mesh integration
4. Custom instrumentation
5. Performance dashboards
```

### 9. Tracing para Troubleshooting
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um troubleshooting specialist]

Use tracing para debugging avançado no Cluster-AI:

**Cenários de troubleshooting:**
- Requests lentos
- Errors intermitentes
- Service failures
- Resource exhaustion
- Network issues

**Ferramentas:** [Jaeger, OpenTelemetry]

**Solicito:**
1. Estratégia de troubleshooting com tracing
2. Queries de debugging
3. Root cause analysis
4. Service dependency mapping
5. Automated issue detection
```

---

## 📁 CATEGORIA: ALERTING E NOTIFICAÇÕES

### 10. Sistema de Alertas Inteligente
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um alerting engineer]

Configure sistema de alertas inteligente para Cluster-AI:

**Tipos de alertas:**
- Métricas (CPU, memória, latência)
- Logs (erros, warnings)
- Synthetic monitoring
- Business metrics
- Security events

**Ferramentas:** [Alertmanager, PagerDuty, Slack]

**Solicito:**
1. Regras de alertas hierárquicas
2. Escalação automática
3. Supressão inteligente
4. Integração com ferramentas
5. Runbooks automatizados
```

### 11. Alerting Baseado em SLOs
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um SRE especializado em SLO-based alerting]

Implemente alerting baseado em SLOs para Cluster-AI:

**SLOs definidos:**
- Service availability
- Request latency
- Error rate
- Throughput

**Estratégia:** [error budget, multi-window, etc.]

**Solicito:**
1. Alerting baseado em error budget
2. Multi-window alerting
3. Burn rate alerts
4. Escalação baseada em severidade
5. Relatórios de SLO compliance
```

### 12. On-Call e Incident Response
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um incident manager]

Configure sistema de on-call e resposta a incidentes:

**Equipe:** [tamanho, cobertura horária, especializações]
**Ferramentas:** [PagerDuty, OpsGenie, VictorOps]

**Processos:** [detecção, análise, resposta, resolução]

**Solicito:**
1. Rotação de on-call
2. Escalação de incidentes
3. Runbooks por tipo de incidente
4. Post-mortem process
5. Melhoria contínua baseada em incidentes
```

---

## 📁 CATEGORIA: SYNTHETIC MONITORING

### 13. User Journey Monitoring
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um synthetic monitoring engineer]

Configure monitoramento sintético para Cluster-AI:

**Journeys críticos:**
- Submissão de tarefa simples
- Processamento complexo
- API integration
- Web interface usage
- Mobile app interaction

**Ferramentas:** [Selenium, Playwright, custom scripts]

**Solicito:**
1. Scripts de user journeys
2. Configuração de execução
3. Métricas de sucesso
4. Alertas de falha
5. Relatórios de performance
```

### 14. API Monitoring
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um API monitoring specialist]

Implemente monitoramento abrangente de APIs do Cluster-AI:

**APIs a monitorar:**
- REST APIs do manager
- Worker APIs
- Health check endpoints
- Metrics endpoints

**Aspectos:** [availability, performance, correctness]

**Solicito:**
1. Testes de contrato de API
2. Monitoramento de performance
3. Validação de responses
4. Alertas de API degradation
5. SLA monitoring
```

### 15. Infrastructure Monitoring
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um infrastructure monitoring engineer]

Configure monitoramento de infraestrutura para Cluster-AI:

**Componentes:**
- Servidores físicos/VMs
- Containers e orchestration
- Redes e load balancers
- Storage systems
- External dependencies

**Ferramentas:** [Prometheus node exporter, cAdvisor, etc.]

**Solicito:**
1. Configuração de exporters
2. Métricas de infraestrutura
3. Dashboards de capacity planning
4. Alertas de infraestrutura
5. Auto-discovery de recursos
```

---

## 📁 CATEGORIA: ANÁLISE E RELATÓRIOS

### 16. Business Intelligence Integration
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um BI engineer]

Integre dados de monitoramento com BI para Cluster-AI:

**Dados disponíveis:**
- Métricas de performance
- Logs de usuário
- Business events
- Cost data
- SLA compliance

**Ferramentas:** [Tableau, Power BI, custom dashboards]

**Solicito:**
1. Data pipeline para BI
2. Métricas de negócio
3. Dashboards executivos
4. Relatórios automatizados
5. Análise preditiva
```

### 17. Capacity Planning e Forecasting
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um capacity planner]

Implemente capacity planning baseado em dados para Cluster-AI:

**Dados históricos:**
- Utilização de recursos
- Padrões de carga
- Eventos sazonais
- Growth trends

**Horizontes:** [curto prazo, médio prazo, longo prazo]

**Solicito:**
1. Análise de tendências atuais
2. Forecasting de demanda
3. Recomendações de capacity
4. Plano de escalabilidade
5. Alertas de capacity
```

### 18. Relatórios Executivos de Observabilidade
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um observability strategist]

Crie relatórios executivos de observabilidade para Cluster-AI:

**Público-alvo:** [CTO, stakeholders, equipe técnica]
**Frequência:** [diário, semanal, mensal]

**Conteúdo:** [performance, reliability, costs, trends]

**Solicito:**
1. KPIs de observabilidade
2. Relatórios automatizados
3. Dashboards executivos
4. Análise de tendências
5. Recomendações estratégicas
```

---

## 📋 TABELA DE USO POR CENÁRIO

| Cenário | Modelo Recomendado | Temperature | Prompt Exemplo |
|---------|-------------------|-------------|----------------|
| **Métricas** | CodeLlama | 0.2 | Sistema Completo |
| **Logging** | CodeLlama | 0.3 | Estratégia Centralizada |
| **Tracing** | CodeLlama | 0.2 | Distributed Tracing |
| **Alerting** | CodeLlama | 0.3 | Sistema Inteligente |
| **Synthetic** | CodeLlama | 0.2 | User Journey |
| **Análise** | Mixtral | 0.4 | Capacity Planning |

---

## 🎯 CONFIGURAÇÕES PARA OPENWEBUI

### Template de Persona Observability Cluster-AI:
```yaml
name: "Observability Engineer Cluster-AI"
description: "Assistente para monitoramento e observabilidade do Cluster-AI"
instruction: |
  Você é um engenheiro de observabilidade experiente especializado em sistemas distribuídos.
  Foque em métricas, logs, tracing e alertas para garantir reliability e performance.
  Priorize soluções que aumentem a visibilidade e reduzam MTTR.
```

### Template de Configuração para Monitoramento:
```yaml
model: "codellama"
temperature: 0.2
max_tokens: 2000
system: |
  Você é um engenheiro de observabilidade sênior especializado em monitoring.
  Forneça soluções práticas, configurações funcionais e melhores práticas de observabilidade.
  Considere escalabilidade, performance e operational excellence.
```

---

## 💡 DICAS PARA PROFISSIONAIS DE MONITORAMENTO

### Observability First
Implemente observabilidade desde o início

### Use the Three Pillars
Métricas, logs e tracing trabalhando juntos

### Alert on Symptoms
Alerta nos sintomas, não nas causas

### Automate Everything
Automatize coleta, análise e resposta

### Continuous Improvement
Use dados para melhorar continuamente

---

Este catálogo oferece **18 prompts especializados** para profissionais de monitoramento trabalhando com Cluster-AI, cobrindo métricas, logging, tracing, alerting e análise. Cada prompt foi adaptado especificamente para as necessidades de observabilidade do projeto.

**Última atualização**: Outubro 2024
**Total de prompts**: 18
**Foco**: Monitoramento e observabilidade do Cluster-AI
