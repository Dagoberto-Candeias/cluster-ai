# ☁️ Catálogo de Prompts: Cloud Deploy - Cluster-AI

## 🎯 Guia Rápido de Utilização

### Configurações Recomendadas
- **Temperatura Baixa (0.1-0.3)**: Para IaC, configurações
- **Temperatura Média (0.4-0.6)**: Para arquitetura e otimização
- **Temperatura Alta (0.7-0.9)**: Para estratégias avançadas

### Modelos por Categoria
- **IaC**: CodeLlama, Qwen2.5-Coder
- **Arquitetura**: Mixtral, Llama 3
- **Otimização**: DeepSeek-Coder

---

## 📁 CATEGORIA: AMAZON WEB SERVICES (AWS)

### 1. AWS Infrastructure as Code
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um arquiteto de AWS especializado em DevOps]

Crie infraestrutura completa na AWS para o Cluster-AI usando Terraform:

**Stack AWS:**
- VPC com subnets públicas/privadas
- EKS cluster para Kubernetes
- RDS PostgreSQL com Multi-AZ
- ElastiCache Redis cluster
- Application Load Balancer
- CloudFront CDN
- Route 53 DNS

**Recursos de Segurança:**
- Security Groups otimizados
- IAM roles com least privilege
- KMS encryption
- AWS Config rules
- CloudTrail logging

**Solicito:**
1. main.tf com todos os recursos
2. variables.tf parametrizável
3. outputs.tf com informações
4. Módulos organizados
5. Remote state configuration
6. Cost optimization tags
```

### 2. AWS EKS Cluster Otimizado
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em Amazon EKS]

Configure cluster EKS otimizado para o Cluster-AI:

**Configurações EKS:**
- Managed node groups
- Fargate profiles para serverless
- Cluster autoscaling
- Network policies
- IAM integration

**Otimizações:**
- Spot instances para workers
- Graviton instances para cost savings
- Cluster upgrades automatizados
- Monitoring com CloudWatch
- Cost allocation tags

**Solicito:**
1. EKS cluster configuration
2. Node group strategies
3. Networking setup (VPC CNI)
4. Security groups e IAM
5. Monitoring e logging
6. Cost optimization
7. Backup strategy
```

### 3. AWS Serverless Architecture
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um arquiteto serverless AWS]

Desenvolva arquitetura serverless na AWS para componentes do Cluster-AI:

**Serviços Serverless:**
- Lambda functions para workers
- API Gateway para endpoints
- DynamoDB para metadados
- S3 para storage
- CloudFront para CDN
- SNS/SQS para messaging

**Benefícios:**
- Zero server management
- Auto-scaling automático
- Pay-per-use pricing
- High availability
- Global distribution

**Solicito:**
1. Lambda function templates
2. API Gateway configuration
3. DynamoDB table design
4. S3 bucket policies
5. CloudFormation templates
6. Monitoring com CloudWatch
7. Cost optimization
```

---

## 📁 CATEGORIA: MICROSOFT AZURE

### 4. Azure Infrastructure as Code
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um arquiteto de Azure especializado em DevOps]

Crie infraestrutura Azure completa para o Cluster-AI usando Bicep/Terraform:

**Stack Azure:**
- Virtual Network com subnets
- AKS cluster para Kubernetes
- Azure Database for PostgreSQL
- Azure Cache for Redis
- Application Gateway
- Front Door CDN
- Azure DNS

**Recursos de Segurança:**
- Network Security Groups
- Azure AD integration
- Key Vault para secrets
- Azure Policy
- Azure Monitor

**Solicito:**
1. main.bicep ou main.tf
2. Parameter files
3. Module structure
4. RBAC configuration
5. Cost management
6. Monitoring setup
```

### 5. Azure AKS Optimization
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em Azure AKS]

Otimize cluster AKS para o Cluster-AI:

**Configurações AKS:**
- System e user node pools
- Auto-scaling configuration
- Azure CNI networking
- Azure AD integration
- Azure Policy enforcement

**Otimizações:**
- Spot instances para workloads
- Azure Container Instances
- Cluster upgrades
- Cost optimization
- Performance monitoring

**Solicito:**
1. AKS cluster configuration
2. Node pool strategies
3. Networking setup
4. Security configuration
5. Monitoring integration
6. Cost optimization
7. Backup procedures
```

---

## 📁 CATEGORIA: GOOGLE CLOUD PLATFORM (GCP)

### 6. GCP Infrastructure as Code
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um arquiteto de GCP especializado em DevOps]

Desenvolva infraestrutura GCP completa para o Cluster-AI:

**Stack GCP:**
- VPC network com subnets
- GKE cluster para Kubernetes
- Cloud SQL PostgreSQL
- Memorystore Redis
- Cloud Load Balancing
- Cloud CDN
- Cloud DNS

**Recursos de Segurança:**
- VPC Service Controls
- IAM permissions
- Cloud KMS encryption
- Security Command Center
- Cloud Logging

**Solicito:**
1. main.tf com Deployment Manager
2. Variables e outputs
3. Module organization
4. IAM setup
5. Cost controls
6. Monitoring configuration
```

### 7. GCP GKE Advanced Configuration
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um especialista em Google GKE]

Configure GKE avançado para o Cluster-AI:

**Configurações GKE:**
- Autopilot vs Standard mode
- Multi-cluster setup
- Anthos Service Mesh
- Binary Authorization
- GKE Enterprise features

**Otimizações:**
- Preemptible VMs
- Custom machine types
- Auto-scaling avançado
- Cost optimization
- Performance monitoring

**Solicito:**
1. GKE cluster configuration
2. Node pool strategies
3. Networking setup
4. Security policies
5. Monitoring integration
6. Cost optimization
7. Multi-cluster management
```

---

## 📁 CATEGORIA: MULTI-CLOUD STRATEGIES

### 8. Multi-Cloud Architecture
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um arquiteto multi-cloud]

Desenvolva estratégia multi-cloud para o Cluster-AI:

**Provedores:**
- AWS como primário
- GCP como secundário
- Azure como terciário

**Arquitetura:**
- Global load balancer (Cloudflare)
- Cross-cloud database replication
- Multi-region CDN
- Disaster recovery
- Cost optimization

**Solicito:**
1. Multi-cloud architecture diagram
2. Traffic distribution strategy
3. Data replication setup
4. Disaster recovery plan
5. Cost optimization approach
6. Monitoring cross-cloud
7. Compliance considerations
```

### 9. Cloud Migration Strategy
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um consultor de cloud migration]

Crie plano de migração para cloud do Cluster-AI:

**Fases de Migração:**
- Assessment e planning
- Pilot migration
- Data migration
- Application migration
- Optimization e go-live

**Estratégias:**
- Lift and shift
- Refactor para cloud-native
- Hybrid approach
- Incremental migration

**Solicito:**
1. Migration roadmap detalhado
2. Risk assessment
3. Resource requirements
4. Timeline e milestones
5. Rollback procedures
6. Cost analysis
7. Success metrics
```

### 10. Cloud Cost Optimization
**Modelo**: Mixtral/DeepSeek-Coder

```
[Instrução: Atue como um especialista em cloud cost optimization]

Desenvolva estratégia de otimização de custos para o Cluster-AI na cloud:

**Áreas de Otimização:**
- Compute resources (EC2, VMs)
- Storage (EBS, disks, buckets)
- Database (RDS, Cloud SQL)
- Networking (data transfer)
- Monitoring e logging

**Ferramentas:**
- AWS Cost Explorer
- Azure Cost Management
- GCP Cost Calculator
- Third-party tools (CloudHealth, Cloudability)

**Solicito:**
1. Current cost analysis
2. Optimization recommendations
3. Reserved instances strategy
4. Storage tier optimization
5. Right-sizing recommendations
6. Monitoring e alerting setup
7. Automated cost controls
8. ROI calculation
```

---

## 📋 TABELA DE USO POR CENÁRIO

| Cenário | Modelo Recomendado | Temperature | Prompt Exemplo |
|---------|-------------------|-------------|----------------|
| **AWS** | CodeLlama | 0.2 | EKS Otimizado |
| **Azure** | CodeLlama | 0.2 | AKS Configuration |
| **GCP** | CodeLlama | 0.2 | GKE Advanced |
| **Multi-Cloud** | Mixtral | 0.4 | Architecture |
| **Cost** | DeepSeek-Coder | 0.3 | Optimization |

---

## 🎯 CONFIGURAÇÕES PARA OPENWEBUI

### Template de Persona Cloud Cluster-AI:
```yaml
name: "Especialista Cloud Cluster-AI"
description: "Assistente para deploy e arquitetura cloud"
instruction: |
  Você é um especialista em cloud computing para sistemas distribuídos.
  Foque em IaC, otimização de custos e arquitetura escalável.
  Considere multi-cloud, security e compliance.
```

### Template de Configuração para Cloud:
```yaml
model: "codellama"
temperature: 0.2
max_tokens: 2500
system: |
  Você é um arquiteto de cloud sênior especializado em infraestrutura.
  Forneça IaC funcional, arquitetura otimizada e melhores práticas.
  Priorize segurança, escalabilidade e eficiência de custos.
```

---

## 💡 DICAS PARA CLOUD DEPLOY EFETIVO

### Infrastructure as Code
Version control toda sua infraestrutura

### Cost Monitoring
Configure alertas de custo desde o início

### Security First
Implemente security groups e IAM corretamente

### Auto-scaling
Configure auto-scaling para otimizar custos

### Multi-region
Considere multi-region para alta disponibilidade

---

## 📊 MODELOS DE OLLAMA RECOMENDADOS

### Para IaC:
- **CodeLlama 34B**: Terraform e CloudFormation
- **Qwen2.5-Coder 14B**: Scripts complexos

### Para Arquitetura:
- **Mixtral 8x7B**: Design e estratégia
- **Llama 3 70B**: Análise complexa

### Para Otimização:
- **DeepSeek-Coder 14B**: Performance e custos
- **Mixtral 8x7B**: Otimização avançada

---

Este catálogo oferece **10 prompts especializados** para cloud deploy no Cluster-AI, cobrindo AWS, Azure, GCP e estratégias multi-cloud.

**Última atualização**: Outubro 2024
**Total de prompts**: 10
**Foco**: Infraestrutura cloud e arquitetura
