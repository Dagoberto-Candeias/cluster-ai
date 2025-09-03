# ☸️ Catálogo de Prompts: Kubernetes & Orquestração - Cluster-AI

## 🎯 Guia Rápido de Utilização

### Configurações Recomendadas
- **Temperatura Baixa (0.1-0.3)**: Para manifests YAML, Helm charts
- **Temperatura Média (0.4-0.6)**: Para arquitetura e troubleshooting
- **Temperatura Alta (0.7-0.9)**: Para otimização avançada

### Modelos por Categoria
- **Manifests**: CodeLlama, Qwen2.5-Coder
- **Helm**: CodeLlama, DeepSeek-Coder
- **Arquitetura**: Mixtral, Llama 3

---

## 📁 CATEGORIA: KUBERNETES MANIFESTS

### 1. Deployment Manifest Completo
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de Kubernetes certificado]

Crie um Deployment manifest completo para o Cluster-AI:

**Aplicação:**
- Nome: [cluster-ai-manager]
- Imagem: [registry/cluster-ai:v1.0.0]
- Réplicas: [3]
- Porta: [8000]
- Recursos: [CPU: 500m, Memory: 1Gi]

**Configurações Avançadas:**
- Health checks (readiness/liveness)
- Resource limits e requests
- Rolling update strategy
- Pod security context
- Affinity/anti-affinity rules

**Solicito:**
1. Deployment.yaml completo
2. Service.yaml para exposição
3. ConfigMap para configuração
4. Secret para credenciais
5. NetworkPolicy para isolamento
6. HPA (HorizontalPodAutoscaler)
```

### 2. StatefulSet para Banco de Dados
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um DBA especializado em Kubernetes]

Desenvolva StatefulSet para PostgreSQL no Cluster-AI:

**Requisitos de Dados:**
- Persistência garantida
- High availability (3 réplicas)
- Backup automatizado
- Connection pooling
- Monitoring integrado

**Configurações:**
- StorageClass para PVs
- Init containers para setup
- Sidecar containers para backup
- Service headless para discovery
- Pod disruption budget

**Solicito:**
1. StatefulSet.yaml completo
2. PersistentVolumeClaim templates
3. Service headless
4. ConfigMap para postgresql.conf
5. Backup cronjob
6. Monitoring service monitor
```

### 3. Ingress Controller Avançado
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um network engineer Kubernetes]

Configure Ingress controller avançado para o Cluster-AI:

**Recursos de Ingress:**
- SSL/TLS termination
- Load balancing inteligente
- Rate limiting
- Authentication middleware
- Custom error pages

**Segurança:**
- HTTPS obrigatório
- HSTS headers
- CORS configuration
- IP whitelisting
- DDoS protection

**Solicito:**
1. Ingress.yaml com annotations avançadas
2. Certificate management (cert-manager)
3. Middleware configuration
4. Rate limiting rules
5. Authentication setup
6. Monitoring e logging
```

---

## 📁 CATEGORIA: HELM CHARTS

### 4. Helm Chart para Cluster-AI
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em Helm]

Crie um Helm chart completo para deploy do Cluster-AI:

**Estrutura do Chart:**
- templates/ com manifests
- values.yaml parametrizável
- Chart.yaml com metadados
- helpers.tpl para reutilização
- tests/ para validation

**Componentes:**
- Manager deployment
- Worker deployments
- Database statefulset
- Redis deployment
- Ingress configuration

**Solicito:**
1. Estrutura completa do chart
2. values.yaml com todas as opções
3. Templates modulares
4. Helper functions
5. Test files
6. CI/CD integration
7. Documentation
```

### 5. Helm Chart com Dependências
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um arquiteto de Helm]

Desenvolva Helm chart com dependências para stack completa do Cluster-AI:

**Dependências:**
- PostgreSQL (bitnami/postgresql)
- Redis (bitnami/redis)
- Nginx Ingress (ingress-nginx)
- Cert Manager (cert-manager)
- Prometheus Stack (prometheus-community)

**Gestão de Dependências:**
- Version pinning
- Conditional installation
- Namespace isolation
- Resource management
- Upgrade strategies

**Solicito:**
1. Chart.yaml com dependencies
2. requirements.yaml ou Chart.lock
3. Dependency management
4. Namespace configuration
5. Resource quotas
6. Upgrade procedures
```

### 6. Helm Chart com Hooks
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em Helm hooks]

Implemente Helm hooks para lifecycle management do Cluster-AI:

**Hooks Necessários:**
- pre-install: database setup
- post-install: application initialization
- pre-upgrade: backup creation
- post-upgrade: migration execution
- pre-delete: cleanup procedures

**Casos de Uso:**
- Database migrations
- Cache warming
- Service registration
- Configuration updates
- Resource cleanup

**Solicito:**
1. Hook definitions completas
2. Job templates para hooks
3. Error handling em hooks
4. Hook weight management
5. Testing de hooks
6. Rollback procedures
```

---

## 📁 CATEGORIA: SERVICE MESH

### 7. Istio Service Mesh Configuration
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um especialista em service mesh]

Configure Istio service mesh para o Cluster-AI:

**Funcionalidades do Istio:**
- Traffic management (routing, load balancing)
- Security (mTLS, authorization)
- Observability (tracing, metrics)
- Resilience (retries, circuit breakers)

**Configurações:**
- Gateway configuration
- Virtual services
- Destination rules
- Peer authentication
- Authorization policies

**Solicito:**
1. Istio installation (istioctl/Helm)
2. Gateway configuration
3. Traffic policies
4. Security policies
5. Observability setup
6. Integration com aplicações
```

### 8. Linkerd Service Mesh
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de Linkerd]

Implemente Linkerd service mesh no Cluster-AI:

**Vantagens do Linkerd:**
- Lightweight (Go vs Java)
- Automatic mTLS
- Built-in observability
- Easy installation
- Low resource overhead

**Configurações:**
- Data plane injection
- Traffic splitting
- Service profiles
- Authorization policies
- Extensions

**Solicito:**
1. Linkerd installation
2. Service mesh injection
3. Traffic management
4. Security policies
5. Observability dashboard
6. Performance monitoring
```

---

## 📁 CATEGORIA: OPERATIONS E TROUBLESHOOTING

### 9. K8s Troubleshooting Avançado
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um SRE especializado em Kubernetes]

Desenvolva guia de troubleshooting avançado para Cluster-AI no Kubernetes:

**Cenários Comuns:**
- Pod não inicia (ImagePullBackOff, CrashLoopBackOff)
- Service não responde (DNS, networking)
- Resource exhaustion (CPU, memory)
- Storage issues (PVC, PV)

**Ferramentas de Debug:**
- kubectl commands avançados
- Container runtime debugging
- Network policies troubleshooting
- RBAC issues resolution

**Solicito:**
1. Systematic troubleshooting framework
2. Debug commands collection
3. Log analysis methodology
4. Network debugging tools
5. Performance profiling
6. Automated diagnostic scripts
```

### 10. K8s Operators Customizados
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um desenvolvedor de Kubernetes Operators]

Crie um Operator customizado para o Cluster-AI:

**Funcionalidades do Operator:**
- Automated cluster scaling
- Configuration management
- Backup orchestration
- Health monitoring
- Disaster recovery

**Componentes:**
- Custom Resource Definitions (CRDs)
- Controller logic (Go)
- Webhooks para validation
- RBAC permissions
- Documentation

**Solicito:**
1. CRD definitions
2. Controller implementation
3. Webhook configurations
4. RBAC setup
5. Testing framework
6. Documentation completa
7. CI/CD pipeline
```

---

## 📋 TABELA DE USO POR CENÁRIO

| Cenário | Modelo Recomendado | Temperature | Prompt Exemplo |
|---------|-------------------|-------------|----------------|
| **Manifests** | CodeLlama | 0.2 | Deployment Completo |
| **Helm** | CodeLlama | 0.2 | Chart com Dependências |
| **Service Mesh** | CodeLlama | 0.3 | Istio Configuration |
| **Operations** | DeepSeek-Coder | 0.3 | Troubleshooting |
| **Custom** | Qwen2.5-Coder | 0.3 | Operators |

---

## 🎯 CONFIGURAÇÕES PARA OPENWEBUI

### Template de Persona Kubernetes Cluster-AI:
```yaml
name: "Especialista K8s Cluster-AI"
description: "Assistente para orquestração Kubernetes"
instruction: |
  Você é um especialista em Kubernetes e orquestração de containers.
  Foque em manifests eficientes, Helm charts e service mesh.
  Considere escalabilidade, reliability e operações.
```

### Template de Configuração para Kubernetes:
```yaml
model: "codellama"
temperature: 0.2
max_tokens: 2500
system: |
  Você é um engenheiro de Kubernetes sênior especializado em orquestração.
  Forneça manifests funcionais, Helm charts e melhores práticas.
  Priorize segurança, observabilidade e automação.
```

---

## 💡 DICAS PARA KUBERNETES EFETIVO

### Declarative Configuration
Use abordagem declarativa sempre que possível

### Resource Limits
Sempre defina requests e limits para recursos

### Health Checks
Implemente readiness e liveness probes

### Security Context
Configure security contexts apropriados

### Observability
Integre monitoring e logging desde o início

---

## 📊 MODELOS DE OLLAMA RECOMENDADOS

### Para Manifests:
- **CodeLlama 34B**: YAML e configuração
- **Qwen2.5-Coder 14B**: Templates complexos

### Para Troubleshooting:
- **DeepSeek-Coder 14B**: Debug e análise
- **Mixtral 8x7B**: Problemas complexos

### Para Arquitetura:
- **Llama 3 70B**: Design avançado
- **Mixtral 8x7B**: Estratégia e planejamento

---

Este catálogo oferece **10 prompts especializados** para Kubernetes e orquestração no Cluster-AI, cobrindo manifests, Helm, service mesh e operações.

**Última atualização**: Outubro 2024
**Total de prompts**: 10
**Foco**: Orquestração e gerenciamento de containers
