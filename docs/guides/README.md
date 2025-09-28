# 📚 Guias e Tutoriais - Cluster-AI

## 🎯 Sobre Esta Seção

Esta pasta contém guias especializados e catálogos de prompts adaptados especificamente para o projeto Cluster-AI. Todos os materiais foram criados com base em templates externos, mas totalmente adaptados para o contexto específico do projeto.

## 📁 Organização dos Arquivos

### Catálogos de Prompts por Perfil Profissional

#### 👨‍💻 Para Desenvolvedores
- **`prompts_desenvolvedores_cluster_ai.md`** (16 prompts)
  - Desenvolvimento de código e aplicações
  - Debugging e troubleshooting
  - Otimização de performance
  - Arquitetura e design patterns

- **`prompts_devops_cluster_ai.md`** (27 prompts)
  - Infrastructure as Code (IaC)
  - CI/CD pipelines
  - Containers e orquestração
  - Automação e DevOps

#### 🛠️ Para Administradores de Sistema
- **`prompts_administradores_cluster_ai.md`** (27 prompts)
  - Instalação e configuração
  - Gerenciamento de infraestrutura
  - Monitoramento de sistema
  - Manutenção e troubleshooting

#### 🔒 Para Profissionais de Segurança
- **`prompts_seguranca_cluster_ai.md`** (27 prompts)
  - Análise de ameaças e vulnerabilidades
  - Controles de segurança
  - Compliance e governança
  - Resposta a incidentes

#### 📊 Para Profissionais de Monitoramento
- **`prompts_monitoramento_cluster_ai.md`** (18 prompts)
  - Métricas e dashboards
  - Logging e análise
  - Distributed tracing
  - Alerting e notificações

#### 🎓 Para Estudantes e Aprendizes
- **`prompts_estudantes_cluster_ai.md`** (27 prompts)
  - Catálogo completo combinando aprendizado específico do Cluster-AI com técnicas gerais de estudo

#### 🎨 Para Multimodal e RAG
- **`prompts_multimodais_rag_cluster_ai.md`** (18 prompts)
  - Análise de imagens e diagramas
  - Geração de conteúdo visual
  - Sistemas RAG e busca semântica
  - Integração multimodal avançada

### 🚀 Novos Catálogos Especializados (2024)

#### 📦 Catálogos Técnicos Especializados
- **`specialized/prompts_deploy_fundamental_cluster_ai.md`** (10 prompts)
  - Estratégias de deploy e rollback
  - Ambientes de desenvolvimento/staging/produção
  - Gestão de mudanças e RTO/RPO

- **`specialized/prompts_containers_docker_cluster_ai.md`** (10 prompts)
  - Dockerfiles otimizados
  - Docker Compose para desenvolvimento/produção
  - Otimização e segurança de containers

- **`specialized/prompts_cicd_automation_cluster_ai.md`** (10 prompts)
  - GitHub Actions, Jenkins, GitLab CI
  - Pipelines automatizados
  - Scripts de automação Bash/Python

- **`specialized/prompts_kubernetes_cluster_ai.md`** (10 prompts)
  - Manifests K8s completos
  - Helm charts avançados
  - Service Mesh (Istio/Linkerd)
  - Troubleshooting e operators

- **`specialized/prompts_cloud_deploy_cluster_ai.md`** (10 prompts)
  - AWS, Azure, GCP Infrastructure as Code
  - Estratégias multi-cloud
  - Otimização de custos
  - Migração para cloud

#### 📋 Sistema de Indexação
- **`index/prompts_index_cluster_ai.md`** - Índice completo com mapeamento detalhado
- **`index/prompts_quick_reference.md`** - Referência rápida para uso imediato

#### 🔗 Integração OpenWebUI
- **`openwebui_integration.md`** - Guia completo de integração com OpenWebUI
  - 5 personas especializadas configuradas
  - Templates de configuração otimizados
  - Fluxos de trabalho integrados
  - Métricas e acompanhamento
- **`openwebui_personas.json`** - Arquivo JSON para importação direta no OpenWebUI
  - Todas as personas prontas para importação
  - Configurações otimizadas por categoria
  - Workflows integrados incluídos

#### 📚 Arquivos Gerais
- **`prompts_cluster_ai.md`** - Catálogo original (legado)
- **`README.md`** - Este arquivo

## 🚀 Como Usar os Prompts

### 1. Identifique seu Perfil
Escolha o catálogo que melhor se adapta ao seu perfil profissional ou objetivo de aprendizagem.

### 2. Selecione o Prompt Adequado
Cada catálogo contém prompts específicos para diferentes cenários e necessidades.

### 3. Configure o Modelo Correto
Cada prompt indica o modelo Ollama recomendado e a temperatura ideal:
- **Baixa (0.1-0.3)**: Para código, configuração, precisão
- **Média (0.4-0.6)**: Para análise, planejamento
- **Alta (0.7-0.9)**: Para criatividade, otimização

### 4. Adapte para seu Contexto
Personalize os prompts com informações específicas do seu ambiente:
- Nomes de arquivos do projeto
- Configurações atuais
- Requisitos específicos
- Contexto técnico

## 🎯 Modelos Ollama Recomendados

### Para Desenvolvimento e Código
- **CodeLlama 34B**: Geração de código, debugging
- **Qwen2.5-Coder 14B**: Desenvolvimento web, APIs
- **DeepSeek-Coder 14B**: Análise e otimização

### Para Análise e Planejamento
- **Llama 3 70B**: Planejamento arquitetural, análise complexa
- **Mixtral 8x7B**: Troubleshooting, configuração
- **Mistral 7B**: Tutoriais, explicações

## 💡 Dicas Gerais de Uso

### Contexto é Fundamental
Quanto mais contexto você fornecer, melhores serão as respostas:
- ✅ "Explique o arquivo manager.sh linha por linha"
- ❌ "Explique o código"

### Seja Específico
Inclua detalhes técnicos relevantes:
- ✅ "Otimize este Dockerfile Python para reduzir tamanho em 50%"
- ❌ "Melhore este Dockerfile"

### Itere Progressivamente
Use respostas anteriores para refinar suas solicitações:
1. Comece com visão geral
2. Aprofunde em aspectos específicos
3. Refine implementações

### Valide Sempre
Teste as soluções em ambiente de desenvolvimento antes de produção.

## 🔧 Configurações para OpenWebUI

### Persona Base para Cluster-AI
```yaml
name: "Especialista Cluster-AI"
description: "Assistente especializado no projeto Cluster-AI"
instruction: |
  Você é um especialista experiente no projeto Cluster-AI.
  Conhece profundamente a arquitetura, componentes e melhores práticas.
  Fornece soluções práticas e contextualizadas para o projeto específico.
```

### Configuração Técnica Geral
```yaml
model: "codellama"
temperature: 0.2
max_tokens: 2000
system: |
  Você é um especialista técnico no projeto Cluster-AI.
  Conhece a arquitetura, componentes e padrões do projeto.
  Fornece soluções práticas, código funcional e melhores práticas.
```

## 📊 Estatísticas dos Catálogos

| Categoria | Arquivo | Número de Prompts | Foco Principal |
|-----------|---------|-------------------|----------------|
| **Catálogos Core** | | | |
| Desenvolvedores | `prompts_desenvolvedores_cluster_ai.md` | 16 | Desenvolvimento e arquitetura |
| DevOps | `prompts_devops_cluster_ai.md` | 27 | Automação e infraestrutura |
| Administradores | `prompts_administradores_cluster_ai.md` | 27 | Sistema e infraestrutura |
| Segurança | `prompts_seguranca_cluster_ai.md` | 27 | Segurança e compliance |
| Monitoramento | `prompts_monitoramento_cluster_ai.md` | 18 | Observabilidade |
| Estudantes | `prompts_estudantes_cluster_ai.md` | 27 | Aprendizado |
| Multimodal/RAG | `prompts_multimodais_rag_cluster_ai.md` | 18 | Multimodal e RAG |
| **Subtotal Core** | - | **160 prompts** | - |
| **Catálogos Especializados** | | | |
| Deploy Fundamental | `specialized/prompts_deploy_fundamental_cluster_ai.md` | 10 | Estratégias de deploy |
| Docker Containers | `specialized/prompts_containers_docker_cluster_ai.md` | 10 | Containerização |
| CI/CD Automation | `specialized/prompts_cicd_automation_cluster_ai.md` | 10 | Pipelines automatizados |
| Kubernetes | `specialized/prompts_kubernetes_cluster_ai.md` | 10 | Orquestração K8s |
| Cloud Deploy | `specialized/prompts_cloud_deploy_cluster_ai.md` | 10 | Infraestrutura cloud |
| **Subtotal Especializados** | - | **50 prompts** | - |
| **Total Geral** | - | **210 prompts** | - |

## 🎓 Para Iniciantes

Se você é novo no projeto Cluster-AI:

1. **Comece pelo básico**: Leia o README principal do projeto
2. **Use os prompts de estudantes**: `prompts_estudantes_cluster_ai.md`
3. **Explore o código**: Use prompts de análise de código
4. **Contribua**: Siga os prompts de contribuição

## 🔄 Atualizações

Estes catálogos são atualizados regularmente com:
- Novos padrões e melhores práticas
- Funcionalidades adicionadas ao projeto
- Feedback da comunidade
- Melhorias baseadas em uso real

**Última atualização**: Outubro 2024
**Total de catálogos**: 7 core + 5 especializados + 1 integração
**Total de prompts**: 210
**Personas OpenWebUI**: 5 configuradas

---

## 📞 Suporte

- **Documentação Principal**: Consulte o `docs/INDEX.md` para navegação completa
- **GitHub Issues**: Para sugestões de novos prompts ou melhorias
- **Comunidade**: Discuta usos avançados nos fóruns da comunidade

---

*Este README é mantido atualizado junto com os catálogos de prompts.*
