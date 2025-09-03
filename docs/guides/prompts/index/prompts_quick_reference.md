# 🚀 Referência Rápida de Prompts - Cluster-AI

## 📋 BUSCA RÁPIDA POR NECESSIDADE

### ❓ O QUE VOCÊ PRECISA FAZER?

| Necessidade | Prompt Recomendado | Localização | Modelo |
|-------------|-------------------|-------------|---------|
| **Criar Dockerfile** | 2.1 Dockerfile Python | `specialized/docker/2.1` | CodeLlama |
| **Deploy no K8s** | 4.1 Deployment Manifest | `specialized/kubernetes/4.1` | CodeLlama |
| **Pipeline CI/CD** | 3.1 GitHub Actions | `specialized/cicd/3.1` | CodeLlama |
| **Infraestrutura AWS** | 5.1 AWS IaC | `specialized/cloud/5.1` | CodeLlama |
| **Docker Compose** | 2.4 Compose Dev | `specialized/docker/2.4` | CodeLlama |
| **Helm Chart** | 4.4 Helm Básico | `specialized/kubernetes/4.4` | CodeLlama |
| **Monitoring** | 7.1 Prometheus | `core/monitoring/7.1` | CodeLlama |
| **Segurança** | 8.1 DevSecOps | `core/security/8.1` | Mixtral |

---

## 🏷️ BUSCA POR TECNOLOGIA

### 🐳 Docker
```
2.1 → Dockerfile Python
2.2 → Dockerfile Node.js
2.3 → Multi-stage avançado
2.4 → Compose desenvolvimento
2.5 → Compose produção
2.6 → Compose redes avançadas
2.7 → Otimização imagens
2.8 → Resource management
2.9 → Security hardening
2.10 → Debug containers
```

### ☸️ Kubernetes
```
4.1 → Deployment completo
4.2 → StatefulSet database
4.3 → Ingress avançado
4.4 → Helm chart básico
4.5 → Helm dependências
4.6 → Helm hooks
4.7 → Istio service mesh
4.8 → Linkerd service mesh
4.9 → Troubleshooting K8s
4.10 → Custom operators
```

### ☁️ Cloud
```
5.1 → AWS IaC completo
5.2 → AWS EKS otimizado
5.3 → AWS serverless
5.4 → Azure IaC
5.5 → Azure AKS
5.6 → GCP IaC
5.7 → GCP GKE
5.8 → Multi-cloud architecture
5.9 → Cloud migration
5.10 → Cost optimization
```

### 🔄 CI/CD
```
3.1 → GitHub Actions completo
3.2 → GitHub microserviços
3.3 → GitHub matrix builds
3.4 → Jenkins declarativo
3.5 → Jenkins Blue Ocean
3.6 → Jenkins shared libraries
3.7 → GitLab avançado
3.8 → GitLab Auto DevOps
3.9 → Bash automation
3.10 → Python automation
```

### 🚀 Deploy
```
1.1 → Análise estratégia
1.2 → Zero-downtime planning
1.3 → Versionamento
1.4 → Deploy desenvolvimento
1.5 → Deploy staging
1.6 → Deploy produção
1.7 → Rollback automatizado
1.8 → Database rollback
1.9 → RTO optimization
1.10 → Change management
```

---

## 🎯 BUSCA POR NÍVEL DE COMPLEXIDADE

### 🟢 INICIANTE (Comece aqui)
| Tarefa | Prompt | Por que? |
|--------|--------|----------|
| Primeiro Dockerfile | 2.1 | Simples e completo |
| Primeiro K8s deploy | 4.1 | Manifest básico |
| Primeiro pipeline | 3.1 | GitHub Actions |
| Primeiro cloud deploy | 5.1 | AWS IaC |

### 🟡 INTERMEDIÁRIO (Padrão)
| Tarefa | Prompt | Por que? |
|--------|--------|----------|
| Otimização Docker | 2.7 | Performance |
| Helm avançado | 4.5 | Dependências |
| Multi-stage builds | 2.3 | Avançado |
| Service mesh | 4.7 | Istio |

### 🔴 AVANÇADO (Especialistas)
| Tarefa | Prompt | Por que? |
|--------|--------|----------|
| Custom operators | 4.10 | K8s avançado |
| Multi-cloud | 5.8 | Arquitetura |
| Cost optimization | 5.10 | FinOps |
| Troubleshooting | 4.9 | Debug avançado |

---

## 📊 BUSCA POR CENÁRIO PRÁTICO

### Desenvolvimento Local
```
🐳 Docker Compose dev → 2.4
🔄 Hot reload → 2.4 (override)
📊 Local monitoring → 2.4 (services)
🗄️ Local database → 2.4 (PostgreSQL)
```

### Produção
```
☸️ K8s deployment → 4.1
🔒 Security hardening → 4.1 (securityContext)
📊 Monitoring → 4.1 (annotations)
⚖️ Auto-scaling → 4.1 (HPA)
```

### CI/CD Pipeline
```
🔄 GitHub Actions → 3.1
🐳 Docker build → 3.1 (build job)
🧪 Tests → 3.1 (test job)
🚀 Deploy → 3.1 (deploy job)
```

### Cloud Migration
```
☁️ Assessment → 5.9
🏗️ Infrastructure → 5.1 (AWS) / 5.4 (Azure) / 5.6 (GCP)
🔄 Migration plan → 5.9
💰 Cost optimization → 5.10
```

---

## ⚡ COMANDOS DE CONFIGURAÇÃO RÁPIDA

### Modelos por Tarefa
```bash
# Para código/script
model: codellama, temperature: 0.2

# Para análise/planejamento
model: mixtral, temperature: 0.4

# Para otimização/debug
model: deepseek-coder, temperature: 0.3

# Para arquitetura/estratégia
model: llama3, temperature: 0.5
```

### Personas Rápidas
```yaml
# DevOps geral
"Engenheiro DevOps sênior especializado em automação"

# Cloud específico
"Arquiteto cloud com experiência em multi-cloud"

# Kubernetes
"Especialista K8s com certificação CKA"

# Segurança
"Engenheiro de segurança focado em DevSecOps"
```

---

## 🔍 MAPA DE LOCALIZAÇÃO RÁPIDA

```
docs/guides/prompts/
├── core/                          # Catálogos principais
│   ├── prompts_devops_cluster_ai.md
│   ├── prompts_desenvolvedores_cluster_ai.md
│   ├── prompts_seguranca_cluster_ai.md
│   ├── prompts_monitoramento_cluster_ai.md
│   └── ...
├── specialized/                   # Catálogos especializados
│   ├── prompts_deploy_fundamental_cluster_ai.md
│   ├── prompts_containers_docker_cluster_ai.md
│   ├── prompts_cicd_automation_cluster_ai.md
│   ├── prompts_kubernetes_cluster_ai.md
│   └── prompts_cloud_deploy_cluster_ai.md
└── index/                        # Referências
    ├── prompts_index_cluster_ai.md
    └── prompts_quick_reference.md
```

---

## 🚨 EMERGÊNCIA - PROBLEMAS COMUNS

| Problema | Solução Rápida | Prompt |
|----------|----------------|--------|
| Container não sobe | Debug Docker | 2.10 |
| K8s pod crash | Troubleshooting K8s | 4.9 |
| Deploy falha | Rollback strategy | 1.7 |
| Performance ruim | Otimização | 2.7 |
| Segurança | Hardening | 2.9 |

---

## 📈 EVOLUÇÃO DO SISTEMA

### Adicionado Recentemente
- ✅ 5 catálogos especializados (50 prompts)
- ✅ Sistema de indexação completo
- ✅ Referência rápida
- ✅ Mapeamento por tecnologia

### Próximas Expansões
- 🔄 Machine Learning Ops
- 🔄 Edge Computing
- 🔄 Industry-specific templates
- 🔄 Advanced automation

---

**💡 DICA**: Use este arquivo como ponto de partida. Para detalhes completos, consulte o índice principal em `prompts_index_cluster_ai.md`.

**📞 Suporte**: Para novos prompts ou sugestões, abra uma issue no repositório.

**Última atualização**: Outubro 2024
