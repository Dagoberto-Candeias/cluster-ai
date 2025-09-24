# 🚀 Catálogo de Prompts para DevOps - Cluster-AI

## 🎯 Guia Rápido de Utilização

### Configurações Recomendadas
- **Temperatura Baixa (0.1-0.3)**: Para IaC, scripts, configuração
- **Temperatura Média (0.4-0.6)**: Para pipelines, automação
- **Temperatura Alta (0.7-0.9)**: Para otimização, inovação

### Modelos por Categoria
- **LLM Geral**: Llama 3, Mixtral, Mistral
- **Codificação**: CodeLlama, Qwen2.5-Coder, DeepSeek-Coder

---

## 📁 CATEGORIA: INFRAESTRUTURA COMO CÓDIGO

### 1. Terraform para Cluster-AI
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de DevOps especializado em Terraform]

Crie configuração Terraform para deploy do Cluster-AI na AWS:

**Requisitos:**
- VPC com subnets públicas/privadas
- EC2 Auto Scaling Group
- Application Load Balancer
- RDS PostgreSQL
- CloudWatch monitoring

**Variáveis necessárias:** [LISTE VARIÁVEIS]

**Solicito:**
1. main.tf com recursos principais
2. variables.tf parametrizado
3. outputs.tf com informações importantes
4. Módulos reutilizáveis
5. Documentação de uso
```

### 2. Docker Compose para Desenvolvimento
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de containers]

Crie docker-compose.yml otimizado para desenvolvimento do Cluster-AI:

**Serviços necessários:**
- Cluster-AI manager
- Workers (Python/Node.js)
- Redis para cache
- PostgreSQL para dados
- Nginx como proxy reverso

**Requisitos:** [desenvolvimento/produção]

**Solicito:**
1. docker-compose.yml completo
2. Dockerfile otimizado para cada serviço
3. docker-compose.override.yml para desenvolvimento
4. Scripts de inicialização
5. Configurações de rede e volumes
```

### 3. Kubernetes Manifests
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de Kubernetes]

Gere manifests Kubernetes para Cluster-AI:

**Componentes:**
- Deployment do manager
- StatefulSet para workers
- ConfigMaps para configuração
- Secrets para credenciais
- Services e Ingress

**Requisitos:** [HA, auto-scaling, security]

**Solicito:**
1. Deployment.yaml completo
2. Service.yaml e Ingress.yaml
3. ConfigMap.yaml e Secret.yaml
4. HPA (Horizontal Pod Autoscaler)
5. Network policies para segurança
```

---

## 📁 CATEGORIA: CI/CD PIPELINES

### 4. GitHub Actions Pipeline
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em GitHub Actions]

Crie pipeline CI/CD completo para Cluster-AI:

**Workflows necessários:**
- CI: build, test, lint, security scan
- CD: deploy para staging e produção
- Release: automated releases

**Tecnologias:** [Docker, Python, Node.js]

**Solicito:**
1. .github/workflows/ci.yml
2. .github/workflows/cd.yml
3. Estratégia de deploy (blue-green)
4. Security scanning integrado
5. Notifications e alertas
```

### 5. Jenkins Pipeline Declarativo
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de Jenkins]

Desenvolva pipeline Jenkins para Cluster-AI:

**Estágios:**
- Checkout e setup
- Build e testes
- Security scanning
- Deploy para ambientes
- Validation e rollback

**Ferramentas:** [Docker, Kubernetes, SonarQube]

**Solicito:**
1. Jenkinsfile declarativo
2. Configuração de agentes
3. Estratégia de deploy
4. Integração com ferramentas
5. Pipeline de rollback
```

### 6. GitLab CI/CD Pipeline
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em GitLab CI]

Crie pipeline GitLab CI para Cluster-AI:

**Stages:**
- build: compilação e testes
- test: testes automatizados
- security: scanning de segurança
- deploy: deploy para ambientes
- cleanup: limpeza de recursos

**Features:** [auto-scaling, caching, artifacts]

**Solicito:**
1. .gitlab-ci.yml completo
2. Configuração de runners
3. Estratégia de environments
4. Caching inteligente
5. Deploy reviews e approvals
```

---

## 📁 CATEGORIA: MONITORAMENTO E OBSERVABILIDADE

### 7. Prometheus + Grafana Stack
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um SRE especializado em observabilidade]

Configure stack de monitoramento Prometheus + Grafana:

**Métricas do Cluster-AI:**
- Performance dos workers
- Latência de resposta
- Utilização de recursos
- Health checks

**Dashboards:** [sistema, aplicação, negócio]

**Solicito:**
1. prometheus.yml configuration
2. Service discovery para workers
3. Custom metrics do Cluster-AI
4. Grafana dashboards JSON
5. Alerting rules
```

### 8. ELK Stack para Logs
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de observabilidade]

Configure ELK Stack para análise de logs do Cluster-AI:

**Fontes de logs:**
- Aplicação Python
- Workers distribuídos
- Nginx access/error logs
- System logs

**Requisitos:** [busca rápida, dashboards, alertas]

**Solicito:**
1. Filebeat configuration
2. Logstash pipelines
3. Elasticsearch index templates
4. Kibana dashboards
5. Alerting configuration
```

### 9. Jaeger para Distributed Tracing
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de observabilidade]

Implemente distributed tracing com Jaeger no Cluster-AI:

**Serviços a rastrear:**
- Manager API
- Worker execution
- Database queries
- External API calls

**Linguagens:** [Python, Node.js]

**Solicito:**
1. Configuração do Jaeger
2. Instrumentation do código
3. Custom spans e tags
4. Sampling strategies
5. Dashboards de tracing
```

---

## 📁 CATEGORIA: SEGURANÇA E COMPLIANCE

### 10. DevSecOps Pipeline
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um security engineer]

Integre segurança no pipeline CI/CD do Cluster-AI:

**Ferramentas de segurança:**
- SAST (Static Application Security Testing)
- DAST (Dynamic Application Security Testing)
- SCA (Software Composition Analysis)
- Container scanning

**Compliance:** [OWASP, NIST, etc.]

**Solicito:**
1. Integração de ferramentas de segurança
2. Gating de qualidade de segurança
3. Relatórios de vulnerabilidades
4. Remediação automatizada
5. Compliance as code
```

### 11. Gestão de Secrets
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em security]

Implemente gestão segura de secrets para Cluster-AI:

**Secrets a gerenciar:**
- Database credentials
- API keys
- TLS certificates
- Service account keys

**Ferramentas:** [Vault, AWS Secrets Manager, etc.]

**Solicito:**
1. Estratégia de gestão de secrets
2. Integração com aplicações
3. Rotação automática
4. Audit logging
5. Backup e recovery
```

### 12. Network Security Policies
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um network security engineer]

Implemente políticas de segurança de rede para Cluster-AI:

**Segmentação:**
- DMZ para serviços públicos
- Internal network para workers
- Database isolation
- Management network

**Ferramentas:** [Kubernetes Network Policies, AWS Security Groups]

**Solicito:**
1. Network policies YAML
2. Security groups configuration
3. Firewall rules
4. Service mesh configuration
5. Zero trust architecture
```

---

## 📁 CATEGORIA: AUTOMAÇÃO E ORQUESTRAÇÃO

### 13. Ansible Playbooks
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de automação]

Crie Ansible playbooks para gerenciamento do Cluster-AI:

**Tarefas de automação:**
- Instalação e configuração
- Deploy de updates
- Backup e recovery
- Health checks
- Troubleshooting

**Inventário:** [dinâmico/estático]

**Solicito:**
1. Playbooks principais
2. Roles organizados
3. Inventário dinâmico
4. Vault para secrets
5. Molecule para testes
```

### 14. GitOps com ArgoCD
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em GitOps]

Implemente GitOps com ArgoCD para Cluster-AI:

**Aplicações a gerenciar:**
- Cluster-AI core services
- Monitoring stack
- Ingress controllers
- Custom resources

**Estratégia:** [single repo/multi repo]

**Solicito:**
1. Application manifests
2. ArgoCD configuration
3. Sync policies
4. Health checks
5. Rollback procedures
```

### 15. Service Mesh com Istio
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de service mesh]

Configure Istio service mesh para Cluster-AI:

**Funcionalidades:**
- Traffic management
- Security (mTLS)
- Observability
- Fault injection

**Serviços:** [manager, workers, APIs]

**Solicito:**
1. Istio configuration
2. Virtual services
3. Destination rules
4. Peer authentication
5. Authorization policies
```

---

## 📁 CATEGORIA: PERFORMANCE E OTIMIZAÇÃO

### 16. Otimização de Containers
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um engenheiro de performance]

Otimize containers Docker para Cluster-AI:

**Problemas identificados:**
- Imagens grandes
- Build lento
- Runtime performance
- Security vulnerabilities

**Dockerfiles atuais:** [COLE DOCKERFILES]

**Solicito:**
1. Dockerfile otimizado
2. Multi-stage builds
3. Layer caching strategy
4. Security hardening
5. Performance benchmarks
```

### 17. Auto-scaling Configuration
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de escalabilidade]

Configure auto-scaling para Cluster-AI:

**Métricas de scaling:**
- CPU utilization
- Memory usage
- Queue length
- Response time

**Plataformas:** [Kubernetes/AWS ECS]

**Solicito:**
1. HPA configuration
2. Custom metrics
3. Scaling policies
4. Cooldown periods
5. Cost optimization
```

### 18. Database Performance Tuning
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um DBA especializado em performance]

Otimize performance do banco de dados do Cluster-AI:

**Problemas:**
- Queries lentas
- Connection pooling
- Index utilization
- Memory configuration

**Database:** [PostgreSQL/MySQL]

**Solicito:**
1. Query optimization
2. Index strategy
3. Connection pooling config
4. Memory tuning
5. Monitoring queries
```

---

## 📋 TABELA DE USO POR CENÁRIO

| Cenário | Modelo Recomendado | Temperature | Prompt Exemplo |
|---------|-------------------|-------------|----------------|
| **IaC** | CodeLlama | 0.2 | Terraform |
| **CI/CD** | CodeLlama | 0.2 | GitHub Actions |
| **Monitoramento** | CodeLlama | 0.3 | Prometheus |
| **Segurança** | Mixtral | 0.3 | DevSecOps |
| **Automação** | CodeLlama | 0.2 | Ansible |
| **Performance** | DeepSeek-Coder | 0.3 | Containers |

---

## 🎯 CONFIGURAÇÕES PARA OPENWEBUI

### Template de Persona DevOps Cluster-AI:
```yaml
name: "DevOps Cluster-AI"
description: "Assistente para práticas DevOps no Cluster-AI"
instruction: |
  Você é um engenheiro DevOps experiente especializado em Cluster-AI.
  Foque em automação, infraestrutura como código, CI/CD e observabilidade.
  Priorize soluções escaláveis, seguras e automatizáveis.
```

### Template de Configuração para DevOps:
```yaml
model: "codellama"
temperature: 0.2
max_tokens: 2000
system: |
  Você é um engenheiro DevOps sênior especializado em automação e infraestrutura.
  Forneça soluções práticas, código IaC funcional e melhores práticas DevOps.
  Considere escalabilidade, segurança e eficiência operacional.
```

---

## 💡 DICAS PARA DEVOPS

### Infrastructure as Code
Sempre version control sua infraestrutura

### Automação Primeiro
Automatize tudo que for repetitivo

### Monitoramento Proativo
Configure observabilidade antes de problemas

### Segurança Integrada
Incorpore segurança em todos os pipelines

### Teste Tudo
Teste infraestrutura, aplicações e processos

---

## 🤖 CATEGORIA: DESENVOLVIMENTO DE IA & PROJETOS TECNOLÓGICOS

### 19. Design de Modelo de Machine Learning
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um ML engineer sênior]

Projete uma arquitetura de modelo de machine learning para o Cluster-AI:

**Objetivo:** [previsão de demanda/detecção de anomalias/classificação/etc.]
**Dados disponíveis:** [DESCREVA OS DADOS]
**Restrições:** [latência, recursos computacionais, precisão]

**Solicito:**
1. Análise dos requisitos do problema
2. Seleção de algoritmo apropriado
3. Arquitetura do modelo proposta
4. Estratégia de treinamento
5. Métricas de avaliação
```

### 20. Explicação de Papers de IA
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um pesquisador de IA]

Explique de forma prática o paper 'Attention Is All You Need' para desenvolvedores:

**Contexto:** [experiência do desenvolvedor - iniciante/intermediário/avançado]
**Aplicação:** [como aplicar no Cluster-AI]
**Foco:** [conceitos-chave/transformer architecture/aplicações]

**Solicito:**
1. Conceitos fundamentais explicados
2. Como funciona o mecanismo de atenção
3. Aplicações práticas no Cluster-AI
4. Implementação simplificada
5. Recursos para aprofundamento
```

### 21. Pipeline de Dados em Python
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um data engineer]

Crie um pipeline de ingestão de dados para o Cluster-AI:

**Fonte de dados:** [APIs/databases/files/etc.]
**Destino:** [PostgreSQL/MongoDB/S3/etc.]
**Processamento:** [ETL/ELT/streaming]

**Solicito:**
1. Arquitetura do pipeline
2. Código Python completo
3. Tratamento de erros
4. Monitoramento e logging
5. Otimização de performance
```

### 22. Fine-tuning de Modelos LLaMA
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um ML engineer especializado em LLMs]

Como implementar fine-tuning em um modelo LLaMA para o Cluster-AI:

**Objetivo:** [classificação/geração/embedding/etc.]
**Dataset:** [tamanho, qualidade, formato]
**Recursos:** [GPU disponível, tempo de treinamento]

**Solicito:**
1. Preparação do dataset
2. Configuração do fine-tuning
3. Código de implementação
4. Estratégias de otimização
5. Avaliação e deployment
```

### 23. Checklist de AI Safety
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um AI safety researcher]

Crie um checklist de auditoria ética para modelos de IA no Cluster-AI:

**Tipo de modelo:** [classificação/regressão/geração/etc.]
**Aplicação:** [crédito/rh/saúde/etc.]
**Regulamentações:** [LGPD/ética IA/transparência]

**Solicito:**
1. Verificações de viés e fairness
2. Transparência e explicabilidade
3. Segurança e robustez
4. Compliance regulatório
5. Monitoramento contínuo
```

### 24. Implementação de RAG
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de IA aplicado]

Implemente Retrieval-Augmented Generation (RAG) no Cluster-AI:

**Base de conhecimento:** [documentos, FAQs, manuais]
**Modelo base:** [Llama 3, Mixtral, etc.]
**Integração:** [API, chatbot, aplicação]

**Solicito:**
1. Arquitetura RAG proposta
2. Configuração do vector database
3. Implementação do retrieval
4. Integração com LLM
5. Otimização de performance
```

### 25. Agente Autônomo com Ollama
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um AI engineer]

Crie um agente autônomo simples usando Ollama + LangChain:

**Objetivo:** [automação de tarefas, chatbot inteligente, etc.]
**Ferramentas:** [APIs disponíveis, funções customizadas]
**Modelo:** [Llama 3, CodeLlama, etc.]

**Solicito:**
1. Design da arquitetura do agente
2. Configuração do LangChain
3. Implementação das ferramentas
4. Lógica de decisão
5. Testes e validação
```

### 26. Avaliação de Modelos em Produção
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um MLOps engineer]

Monte um guia de boas práticas para avaliação de modelos de IA em produção:

**Métricas:** [accuracy, precision, recall, latency, etc.]
**Monitoramento:** [performance, drift, qualidade]
**Ferramentas:** [MLflow, Prometheus, custom metrics]

**Solicito:**
1. Framework de avaliação
2. Métricas automatizadas
3. Detecção de drift
4. A/B testing
5. Rollback procedures
```

### 27. Tutorial de Embeddings com Ollama
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em NLP]

Crie um exemplo de código usando embeddings (nomic-embed-text) para busca semântica:

**Aplicação:** [FAQ, busca em documentos, recomendação]
**Modelo:** [nomic-embed-text, bge-m3, etc.]
**Framework:** [LangChain, LlamaIndex, custom]

**Solicito:**
1. Configuração do modelo de embedding
2. Indexação de documentos
3. Implementação da busca semântica
4. Otimização de performance
5. Casos de uso no Cluster-AI
```

### 28. Análise de Commits e Evolução do Projeto
**Modelo**: Mixtral/CodeLlama

```
[Instrução: Atue como um engenheiro de DevOps e analista de qualidade de código]

Analise o histórico de commits do Cluster-AI e forneça insights sobre:

1. Padrões de Desenvolvimento:
   - Frequência e consistência dos commits
   - Padrão de mensagens de commit (conventional commits?)
   - Horários predominantes de commits

2. Análise de Colaboração:
   - Principais contribuidores e seus padrões
   - Possíveis gargalos no desenvolvimento
   - Arquivos com maior número de modificações

3. Indicadores de Qualidade:
   - Razão entre commits de feature/bugfix/refatoração
   - Arquivos com maior churn (muitas alterações)
   - Possíveis áreas de instabilidade

4. Recomendações para Melhoria do Processo:

Histórico de commits (últimos 30 dias):
[COLE A SAÍDA DE `git log --oneline --since="30 days" --pretty=format:"%h|%an|%ad|%s" --date=short`]
```

### 29. Refatoração de Sistema Legado
**Modelo**: DeepSeek-Coder/CodeLlama

```
[Instrução: Atue como um especialista em modernização de sistemas legados]

Estou trabalhando em um sistema legado no Cluster-AI e preciso de um plano de refatoração em fases.

Contexto do Sistema:
- Componente legado: [manager/worker/database/etc.]
- Principais desafios: [acoplamento alto, testes frágeis, documentação inexistente]
- Objetivos de negócio: [permitir novas funcionalidades, melhorar performance]

Solicito:
1. Análise de Risco: Quais são os riscos mais críticos nesta refatoração?
2. Estratégia de Refatoração:
   - Fase 1: Estabilização (1-2 semanas)
   - Fase 2: Refatoração arquitetural (3-4 semanas)
   - Fase 3: Modernização (2-3 semanas)
3. Plano de Testes: Como garantir que não haverá regressões?
4. Métricas de Sucesso: Como medir o progresso?

Código exemplar do sistema atual:
```python
[COLE 2-3 EXCERTOS REPRESENTATIVOS DO CÓDIGO LEGADO]
```
```

### 30. Design de Sistema Distribuído
**Modelo**: Mixtral/Llama 3 70B

```
[Instrução: Atue como um engenheiro de sistemas distribuídos]

Preciso projetar um sistema distribuído para o Cluster-AI:

**Requisitos Não-Funcionais:**
- Carga esperada: [X requests/segundo]
- Latência máxima: [Y ms]
- Disponibilidade: [Z% uptime]
- Consistência vs. Disponibilidade: [CAP theorem tradeoffs]

Solicito:
1. Diagrama Arquitetural: Componentes e suas interações
2. Estratégia de Escalabilidade: Horizontal vs vertical
3. Gestão de Estado: Stateless vs stateful
4. Comunicação entre Serviços: Synchronous vs asynchronous
5. Considerações de Banco de Dados: SQL vs NoSQL, sharding, replication
6. Pontos de Falha Potenciais: e mitigações
```

### 31. Otimização de Consultas de Banco de Dados
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um DBA especializado em performance]

Otimize a seguinte consulta SQL do Cluster-AI:

Consulta atual:
```sql
[COLE A CONSULTA SQL AQUI]
```

Esquema da Tabela:
```sql
[COLE O SCHEMA DAS TABELAS ENVOLVIDAS]
```

Contexto:
- SGBD: [PostgreSQL/MySQL]
- Volume de dados: [XXX GB]
- Padrão de acesso: [ex: 70% reads, 30% writes]

Solicito:
1. Análise do Plano de Execução: Identifique problemas
2. Otimizações de Índices: Quais índices criar/remover
3. Rewriting da Query: Versão otimizada
4. Modificações de Esquema: Se necessário
5. Métricas Esperadas: Melhoria estimada em performance
```

### 32. Hardening de Configuração e Deployment
**Modelo**: Mixtral/CodeLlama

```
[Instrução: Atue como um DevSecOps engineer]

Analise a seguinte configuração de deployment do Cluster-AI e forneça recomendações de hardening:

Arquivos de Configuração:
```yaml
[COLE DOCKERCOMPOSE, KUBERNETES DEPLOYMENT, OU SERVER CONFIG]
```

Contexto:
- Ambiente: [Kubernetes/AWS/Azure/On-premise]
- Sensibilidade dos dados: [dados pessoais, financeiros]
- Requisitos regulatórios: [GDPR, HIPAA, etc.]

Solicito:
1. Riscos Identificados: Configurações inseguras
2. Recomendações de Hardening: Por categoria (network, secrets, permissions)
3. Configurações Seguras Exemplares: Arquivos corrigidos
4. Ferramentas de Scanning: Recomendações para validar segurança
```

### 33. Checklist de Pré-Deploy
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um engenheiro de DevOps sênior]

Baseado no contexto do Cluster-AI, crie um checklist completo de pré-deploy:

Contexto do Projeto:
- Tipo de aplicação: [Web App/API/Microserviço]
- Ambiente de destino: [AWS/Azure/GCP/On-premise]
- Tecnologias: [Python + PostgreSQL/Node.js + MongoDB/etc.]
- Equipe: [X desenvolvedores, Y ambientes]

Solicito:
1. Checklist de Segurança (10 itens críticos)
2. Checklist de Performance (5 métricas essenciais)
3. Checklist de Configuração (variáveis de ambiente, secrets)
4. Checklist de Banco de Dados (migrations, backups)
5. Plano de Rollback (condições e procedimentos)

Forneça em formato de tabela markdown com colunas: [Item, Descrição, Criticidade, Responsável]
```

### 34. Análise de Configuração para Produção
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um SRE especializado em ambientes de produção]

Analise a seguinte configuração de deployment do Cluster-AI e identifique problemas potenciais:

Arquivos de Configuração:
```yaml
[COLE AQUI O docker-compose.yml OU Kubernetes deployment]
```

Variáveis de Ambiente:
```bash
[COLE AQUI AS VARIÁVEIS DE AMBIENTE]
```

Solicito:
1. Problemas Imediatos (críticos para produção)
2. Recomendações de Otimização (recursos, limites)
3. Configurações de Segurança missing
4. Versionamento e tags inadequadas
5. Configuração revisada com as correções
```

### 35. Estratégia de Deploy
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um arquiteto de cloud]

Recomende a melhor estratégia de deploy para o Cluster-AI:

Contexto:
- Aplicação: [Monolítico/Microserviços]
- Tráfego: [X usuários simultâneos, pico às Y horas]
- Requisitos de Disponibilidade: [Z% uptime]
- Tolerância a Downtime: [Nenhuma/Mínima/Moderada]
- Equipe: [Tamanho e experiência]

Solicito:
1. Análise Comparativa de estratégias: Blue-Green vs Canary vs Rolling vs Recreate
2. Recomendação justificada
3. Diagrama da estratégia escolhida
4. Pré-requisitos para implementação
5. Riscos e mitigações
```

### 36. Configuração de Blue-Green Deployment
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de AWS/Azure/GCP]

Crie um script completo para implementar Blue-Green deployment no Cluster-AI:

Stack Requerida:
- Cloud: [AWS ELB + Auto Scaling/Azure Load Balancer/GCP Cloud Load Balancing]
- Aplicação: [Docker containers/VM-based]
- Database: [PostgreSQL/MySQL/MongoDB]

Solicito:
1. Script de Implantação (bash/powershell)
2. Script de Troca (switch between environments)
3. Script de Rollback
4. Monitoramento durante a transição
5. Validação pós-deploy
```

### 37. Deploy no Kubernetes
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de Kubernetes certificado]

Gere os manifestos YAML completos para deploy do Cluster-AI:

Aplicação:
- Nome: [cluster-ai]
- Port: [8000]
- Recursos: [2CPU, 4GB RAM]
- Replicas: [3]
- Health checks: [Liveness, Readiness]

Requisitos:
- ConfigMaps para configuração
- Secrets management
- Auto-scaling (HPA)
- Resource limits
- Service e Ingress
- Probes configuradas

Solicito:
1. Deployment.yaml completo
2. Service.yaml
3. Ingress.yaml (com SSL)
4. HPA.yaml
5. ConfigMap.yaml
6. Instructions para aplicação
```

### 38. Deploy no Azure DevOps
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em Azure DevOps pipelines]

Crie um pipeline completo no Azure DevOps para o Cluster-AI:

Processo:
- Build: [Docker image/Python package]
- Test: [Unit tests/Integration tests]
- Scan: [Security scanning]
- Deploy: [Para dev/staging/prod]

Solicito:
1. azure-pipelines.yml completo
2. Variáveis de Grupo recomendadas
3. Approval gates entre ambientes
4. Integração com monitoramento
5. Rollback automation
```

### 39. Diagnóstico de Falha no Deploy
**Modelo**: Mixtral/CodeLlama

```
[Instrução: Atue como um engenheiro de SRE]

Analise os logs de deploy abaixo e diagnostique a causa raiz do problema:

Logs de Deploy:
```
[COLE OS LOGS DE ERRO AQUI]
```

Contexto:
- Plataforma: [Kubernetes/AWS ECS/Heroku]
- Última mudança: [O que foi alterado?]

Solicito:
1. Diagnóstico da causa raiz
2. Passos para Resolução imediata
3. Prevenção para o futuro
4. Script de correção (se aplicável)
```

### 40. Rollback Automatizado
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um engenheiro de confiabilidade (SRE)]

Desenvolva um script de rollback automatizado para o Cluster-AI:

Contexto:
- Plataforma: [Kubernetes/AWS/Azure]
- Método de deploy: [Blue-Green/Canary]
- Indicadores de falha: [Latência > Xms, Error rate > Y%]

Solicito:
1. Script de Monitoramento contínuo
2. Condições para trigger de rollback
3. Script de Rollback automático
4. Notificações (Slack/Email)
5. Documentação pós-rollback
```

### 41. Deploy e Migração de Database
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um DBA especializado em migrações]

Planeje a estratégia de deploy para mudanças no banco de dados do Cluster-AI:

Contexto:
- Database: [PostgreSQL 12 -> 14/MySQL 5.7 -> 8.0]
- Tamanho: [XXX GB]
- Downtime permitido: [Nenhum/Mínimo/Z horas]

Mudanças:
```sql
[COLE AS ALTERAÇÕES SCHEMA AQUI]
```

Solicito:
1. Estratégia de Migração (com downtime/zero-downtime)
2. Scripts de Migração passo a passo
3. Plano de Rollback para database
4. Teste de Validação pós-migração
5. Monitoramento durante a migração
```

### 42. Criando Runbooks de Deploy
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um engenheiro de confiabilidade (SRE)]

Crie um runbook completo para deploy em produção do Cluster-AI:

Estrutura Solicita:
- Pré-requisitos e verificações
- Comandos passo a passo
- Verificações pós-deploy
- Procedimento de Rollback
- Lista de Contatos em caso de emergência

Contexto Específico:
- Aplicação: [Cluster-AI v2.1]
- Equipe: [Plantão e responsáveis]
- SLA: [Tempo máximo de recuperação]

Forneça em formato de tabela com timestamps e responsabilidades.
```

### 43. Documentação de Procedimentos de Emergência
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um engenheiro de incident response]

Crie documentação para lidar com emergências durante deploy do Cluster-AI:

Cenários:
- Deploy falha e aplicação não sobe
- Deploy completo mas performance degradada
- Deploy causa errors em cadeia
- Data corruption durante deploy

Solicito:
1. Procedimentos passo a passo para cada cenário
2. Comunicação (o que dizer, para quem)
3. Decisão de rollback vs fix forward
4. Documentação pós-incidente
```

### 44. Deploy com Docker Compose no Cluster-AI
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de containers especializado em Docker]

Crie um docker-compose.yml completo para desenvolvimento do Cluster-AI:

**Serviços necessários:**
- Manager do Cluster-AI (porta 8000)
- Workers Python (porta 8001-8003)
- Redis para cache de tarefas
- PostgreSQL para metadados
- Nginx como load balancer

**Requisitos específicos:**
- Rede isolada para comunicação interna
- Volumes para persistência de dados
- Variáveis de ambiente para configuração
- Health checks para todos os serviços
- Logs centralizados

Solicito:
1. docker-compose.yml completo com todos os serviços
2. Dockerfile otimizado para cada componente
3. docker-compose.override.yml para desenvolvimento
4. Scripts de inicialização e configuração
5. Configuração de rede e volumes persistentes
```

### 45. Pipeline CI/CD com GitHub Actions
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em GitHub Actions]

Crie um pipeline completo de CI/CD para o Cluster-AI:

**Workflows necessários:**
- CI: lint, testes unitários, testes de integração
- Build: criação de imagens Docker otimizadas
- Security: scanning de vulnerabilidades
- Deploy: para staging e produção
- Rollback: automatizado em caso de falha

**Tecnologias:** [Python, Docker, Kubernetes]

Solicito:
1. .github/workflows/ci.yml com testes e build
2. .github/workflows/deploy.yml com estratégia blue-green
3. Configuração de secrets e variáveis
4. Integração com ferramentas de segurança
5. Notificações e alertas automatizados
```

### 46. Deploy no Kubernetes com Helm
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de Kubernetes com experiência em Helm]

Crie um Helm Chart completo para deploy do Cluster-AI:

**Componentes do Chart:**
- Manager deployment e service
- Worker deployments com auto-scaling
- ConfigMaps para configuração centralizada
- Secrets para credenciais
- Ingress com TLS
- Network policies para isolamento

**Requisitos:**
- Suporte a múltiplos ambientes (dev/staging/prod)
- Configuração parametrizável via values.yaml
- Health checks e probes configurados
- Resource limits e requests
- Service mesh integration

Solicito:
1. Estrutura completa do Helm Chart
2. values.yaml com configurações padrão
3. Templates para todos os recursos K8s
4. Helpers para reutilização de código
5. Documentação de instalação e uso
```

### 47. Deploy na AWS com Terraform
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de DevOps especializado em AWS e Terraform]

Crie infraestrutura como código para deploy do Cluster-AI na AWS:

**Stack completo:**
- VPC com subnets públicas/privadas
- EKS cluster para Kubernetes
- RDS PostgreSQL com alta disponibilidade
- ElastiCache Redis para cache
- Application Load Balancer
- CloudWatch para monitoramento
- Route 53 para DNS

**Requisitos de segurança:**
- Security groups configurados
- IAM roles com princípio do menor privilégio
- Encryption em trânsito e repouso
- Backup automatizado

Solicito:
1. main.tf com todos os recursos
2. variables.tf parametrizado
3. outputs.tf com informações importantes
4. Módulos organizados por componente
5. Documentação de deploy e destroy
```

### 48. Configuração de Monitoramento com Prometheus
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um SRE especializado em observabilidade]

Configure monitoramento completo para o Cluster-AI com Prometheus:

**Métricas essenciais:**
- Performance dos workers (CPU, memória, throughput)
- Latência de processamento de tarefas
- Taxa de erro por componente
- Utilização de recursos do cluster
- Health checks de conectividade

**Dashboards no Grafana:**
- Visão geral do cluster
- Performance por worker
- Alertas e notificações
- Tendências históricas

Solicito:
1. prometheus.yml com configuração de scraping
2. Service discovery para workers dinâmicos
3. Custom metrics do Cluster-AI
4. Alerting rules para cenários críticos
5. Dashboards Grafana em JSON
```

### 49. Segurança em Produção com HTTPS e Firewall
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um security engineer especializado em hardening]

Configure segurança completa para produção do Cluster-AI:

**Certificados e Encriptação:**
- HTTPS com Let's Encrypt
- Certificados auto-renováveis
- TLS 1.3 obrigatório
- HSTS headers configurados

**Firewall e Network Security:**
- UFW configurado para portas essenciais
- Fail2ban para proteção contra ataques
- Rate limiting no Nginx
- Network policies no Kubernetes

**Monitoramento de Segurança:**
- Logs de acesso auditados
- Alertas de tentativas suspeitas
- Backup criptografado
- Intrusion detection

Solicito:
1. Configuração completa do Nginx com HTTPS
2. Regras de firewall otimizadas
3. Certbot automation para renovação
4. Scripts de hardening do sistema
5. Checklist de validação de segurança
```

### 50. Estratégia de Backup e Disaster Recovery
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um DBA e especialista em disaster recovery]

Implemente estratégia completa de backup para o Cluster-AI:

**Tipos de Backup:**
- Backup completo semanal do banco
- Backup incremental diário
- Backup de configuração a cada deploy
- Backup de logs para auditoria

**Recuperação de Desastre:**
- RTO (Recovery Time Objective): 4 horas
- RPO (Recovery Point Objective): 1 hora
- Plano de failover para região secundária
- Testes de recuperação mensais

**Automação:**
- Scripts de backup agendados
- Validação automática de integridade
- Notificações de falha
- Restauração one-click

Solicito:
1. Scripts de backup para PostgreSQL
2. Estratégia de armazenamento (S3, NFS)
3. Plano de disaster recovery documentado
4. Testes automatizados de recuperação
5. Monitoramento de integridade dos backups
```

### 51. Deploy Multi-Cloud com Failover
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um arquiteto de soluções multi-cloud]

Projete estratégia de deploy multi-cloud para alta disponibilidade do Cluster-AI:

**Provedores:**
- AWS como primário (us-east-1)
- GCP como secundário (us-central1)
- Azure como terciário (East US 2)

**Arquitetura:**
- Load balancer global (Cloudflare)
- Database replication cross-cloud
- CDN para assets estáticos
- Failover automático baseado em health checks

**Requisitos:**
- Latência < 100ms globalmente
- 99.99% uptime SLA
- Custo otimizado
- Compliance com GDPR

Solicito:
1. Diagrama da arquitetura multi-cloud
2. Estratégia de failover automatizado
3. Configuração de DNS inteligente
4. Monitoramento cross-cloud
5. Plano de custos e otimização
```

### 52. Otimização de Performance em Produção
**Modelo**: DeepSeek-Coder/CodeLlama

```
[Instrução: Atue como um performance engineer]

Otimize performance do Cluster-AI para produção:

**Análise Atual:**
- Latência média de resposta
- Throughput máximo suportado
- Utilização de CPU/Memória
- Bottlenecks identificados

**Otimização de Código:**
- Profiling do código Python
- Otimização de queries SQL
- Cache inteligente (Redis)
- Connection pooling

**Infraestrutura:**
- Auto-scaling baseado em métricas
- Load balancing inteligente
- CDN para assets
- Database optimization

Solicito:
1. Análise de performance atual
2. Plano de otimização priorizado
3. Implementação de melhorias
4. Métricas de monitoramento
5. Testes de carga automatizados
```

### 53. GitOps com ArgoCD para Cluster-AI
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em GitOps]

Implemente GitOps completo com ArgoCD para o Cluster-AI:

**Estrutura do Repositório:**
- apps/ - definições das aplicações
- infrastructure/ - IaC com Terraform
- monitoring/ - configurações de observabilidade
- docs/ - documentação automatizada

**Fluxos de Deploy:**
- Pull request → staging automático
- Merge na main → produção
- Rollback via Git revert
- Emergency deploy via hotfix branch

**Integrações:**
- Image scanning automático
- Policy checks com OPA
- Notifications no Slack
- Audit logging

Solicito:
1. Estrutura completa do repositório GitOps
2. Configuração do ArgoCD
3. Application manifests
4. Sync policies e estratégias
5. CI/CD pipeline integrado
```

---

Este catálogo oferece **53 prompts especializados** para profissionais DevOps no Cluster-AI, expandindo significativamente as capacidades de infraestrutura, automação e desenvolvimento de IA do projeto.
