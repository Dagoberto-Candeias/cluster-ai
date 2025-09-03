# 🔄 Catálogo de Prompts: CI/CD & Automação - Cluster-AI

## 🎯 Guia Rápido de Utilização

### Configurações Recomendadas
- **Temperatura Baixa (0.1-0.3)**: Para pipelines YAML, scripts
- **Temperatura Média (0.4-0.6)**: Para arquitetura e otimização
- **Temperatura Alta (0.7-0.9)**: Para inovação em automação

### Modelos por Categoria
- **Pipelines**: CodeLlama, Qwen2.5-Coder
- **Automação**: CodeLlama, DeepSeek-Coder
- **Arquitetura**: Mixtral, Llama 3

---

## 📁 CATEGORIA: GITHUB ACTIONS

### 1. Pipeline Completo GitHub Actions
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em GitHub Actions]

Crie um pipeline completo de CI/CD para o Cluster-AI usando GitHub Actions:

**Workflows Necessários:**
- CI: build, test, lint, security scan
- CD: deploy para staging e produção
- Release: automated releases e changelogs
- Security: vulnerability scanning contínuo

**Tecnologias:**
- Linguagem: [Python/Node.js/Multi-lang]
- Deploy: [Docker/Kubernetes/Cloud]
- Testing: [Unit/Integration/E2E]

**Solicito:**
1. .github/workflows/ci.yml completo
2. .github/workflows/cd.yml com deploy
3. .github/workflows/release.yml
4. Reusable workflows para eficiência
5. Security scanning integrado
6. Notifications e alertas
```

### 2. GitHub Actions para Microserviços
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de CI/CD para microserviços]

Desenvolva pipeline GitHub Actions otimizado para arquitetura de microserviços do Cluster-AI:

**Microserviços:**
- Manager API (Python)
- Worker services (Python/Node.js)
- Auth service (Node.js)
- Notification service (Go)

**Estratégias de Deploy:**
- Independent deployment por serviço
- Shared pipeline components
- Parallel builds e tests
- Service mesh integration

**Solicito:**
1. Monorepo vs multi-repo strategy
2. Shared workflows para reutilização
3. Service-specific workflows
4. Dependency management
5. Cross-service testing
6. Rollback automation
```

### 3. GitHub Actions com Matrix Builds
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em matrix builds]

Implemente matrix builds no GitHub Actions para o Cluster-AI:

**Matrizes de Build:**
- Python versions: [3.8, 3.9, 3.10, 3.11]
- Operating systems: [ubuntu-latest, windows-latest]
- Databases: [PostgreSQL, MySQL, SQLite]
- Node.js versions: [16, 18, 20]

**Otimização:**
- Build caching inteligente
- Parallel execution
- Fail-fast strategy
- Result aggregation

**Solicito:**
1. Matrix configuration otimizada
2. Build caching strategy
3. Test parallelization
4. Result reporting
5. Performance optimization
```

---

## 📁 CATEGORIA: JENKINS PIPELINES

### 4. Jenkins Pipeline Declarativo
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em Jenkins]

Crie um pipeline Jenkins declarativo completo para o Cluster-AI:

**Estágios do Pipeline:**
- Checkout: código e dependências
- Build: compilação e packaging
- Test: unitários, integração, e2e
- Security: scanning e compliance
- Deploy: staging e produção
- Cleanup: recursos e artifacts

**Ferramentas Integradas:**
- Docker para containerização
- SonarQube para qualidade
- Nexus para artifact repository
- Kubernetes para deploy

**Solicito:**
1. Jenkinsfile declarativo completo
2. Configuração de agentes
3. Pipeline library reutilizável
4. Error handling e retry logic
5. Notifications e reporting
```

### 5. Jenkins com Blue Ocean
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um DevOps engineer especializado em Jenkins]

Configure pipeline Jenkins com Blue Ocean para melhor experiência visual:

**Recursos do Blue Ocean:**
- Pipeline visualization
- Branch navigation
- Stage view intuitivo
- Real-time status
- Interactive input steps

**Integrações:**
- GitHub para triggers
- Docker para builds
- Kubernetes para deploy
- Slack para notifications

**Solicito:**
1. Jenkinsfile otimizado para Blue Ocean
2. Branch-based pipelines
3. Visual pipeline design
4. Interactive approval steps
5. Real-time monitoring
```

### 6. Jenkins Shared Libraries
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um arquiteto de Jenkins]

Desenvolva shared libraries para Jenkins no Cluster-AI:

**Bibliotecas Necessárias:**
- buildUtils: funções comuns de build
- deployUtils: estratégias de deploy
- testUtils: execução de testes
- notificationUtils: comunicação
- securityUtils: scanning e compliance

**Estrutura:**
- vars/ para global functions
- src/ para classes Groovy
- resources/ para templates
- test/ para unit tests

**Solicito:**
1. Estrutura completa da library
2. Funções utilitárias essenciais
3. Pipeline templates
4. Documentation e examples
5. Testing framework
```

---

## 📁 CATEGORIA: GITLAB CI/CD

### 7. GitLab CI Pipeline Avançado
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em GitLab CI]

Crie um pipeline GitLab CI avançado para o Cluster-AI:

**Recursos Avançados:**
- Parent-child pipelines
- Dynamic environments
- Auto DevOps integration
- Compliance frameworks
- Security orchestration

**Stages Complexos:**
- build: multi-stage Docker builds
- test: parallel test execution
- security: comprehensive scanning
- deploy: canary deployments
- cleanup: resource management

**Solicito:**
1. .gitlab-ci.yml com advanced features
2. Parent-child pipeline structure
3. Dynamic environment creation
4. Security scanning integrado
5. Compliance pipeline
6. Performance optimization
```

### 8. GitLab Auto DevOps
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um engenheiro de DevOps GitLab]

Configure Auto DevOps para o Cluster-AI no GitLab:

**Auto DevOps Features:**
- Automatic pipeline generation
- Security scanning integrado
- Performance testing
- License compliance
- Container registry integration

**Customizações:**
- Custom buildpacks
- Environment-specific configs
- Custom test stages
- Deploy strategies
- Monitoring integration

**Solicito:**
1. Auto DevOps configuration
2. Custom buildpack development
3. Environment overrides
4. Custom job templates
5. Integration com monitoring
6. Performance tuning
```

---

## 📁 CATEGORIA: AUTOMATION SCRIPTS

### 9. Bash Scripts de Automação
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em automação Bash]

Crie scripts Bash robustos para automação do Cluster-AI:

**Scripts Necessários:**
- setup.sh: instalação inicial
- deploy.sh: deploy automatizado
- backup.sh: backup de dados
- health-check.sh: verificação de saúde
- rollback.sh: rollback procedures

**Recursos dos Scripts:**
- Error handling robusto
- Logging estruturado
- Configuration management
- Dry-run mode
- Interactive prompts

**Solicito:**
1. Scripts modulares e reutilizáveis
2. Configuration file templates
3. Error handling e recovery
4. Logging e monitoring
5. Testing framework para scripts
6. Documentation completa
```

### 10. Python Automation Scripts
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de automação Python]

Desenvolva scripts Python para automação avançada do Cluster-AI:

**Módulos de Automação:**
- cluster_manager.py: gestão do cluster
- deploy_orchestrator.py: orquestração de deploys
- monitoring_automation.py: automação de monitoring
- backup_scheduler.py: agendamento de backups

**Recursos Avançados:**
- Async/await para performance
- Configuration management (YAML/TOML)
- REST API integration
- Database automation
- Cloud provider APIs

**Solicito:**
1. Scripts Python assíncronos
2. Configuration management
3. Error handling e retry logic
4. Logging estruturado
5. Unit tests para scripts
6. CLI interface (Click/Typer)
7. Docker integration
```

---

## 📋 TABELA DE USO POR CENÁRIO

| Cenário | Modelo Recomendado | Temperature | Prompt Exemplo |
|---------|-------------------|-------------|----------------|
| **GitHub Actions** | CodeLlama | 0.2 | Pipeline Completo |
| **Jenkins** | CodeLlama | 0.2 | Declarativo |
| **GitLab** | CodeLlama | 0.2 | Auto DevOps |
| **Bash Scripts** | CodeLlama | 0.2 | Automação |
| **Python Scripts** | Qwen2.5-Coder | 0.3 | Avançado |

---

## 🎯 CONFIGURAÇÕES PARA OPENWEBUI

### Template de Persona CI/CD Cluster-AI:
```yaml
name: "Especialista CI/CD Cluster-AI"
description: "Assistente para pipelines e automação"
instruction: |
  Você é um especialista em CI/CD e automação para sistemas distribuídos.
  Foque em pipelines eficientes, automação robusta e DevOps practices.
  Considere escalabilidade, reliability e velocidade de entrega.
```

### Template de Configuração para CI/CD:
```yaml
model: "codellama"
temperature: 0.2
max_tokens: 2500
system: |
  Você é um engenheiro de CI/CD sênior especializado em automação.
  Forneça pipelines funcionais, scripts robustos e melhores práticas.
  Priorize reusabilidade, segurança e performance.
```

---

## 💡 DICAS PARA CI/CD EFETIVO

### Pipeline as Code
Mantenha pipelines versionados no repositório

### Testes em Todos os Estágios
Implemente testes progressivos (unit → integration → e2e)

### Segurança Integrada
Incorpore security scanning em todos os pipelines

### Monitoramento Contínuo
Configure observabilidade para pipelines e deploys

### Automação Primeiro
Automatize tudo que for repetitivo

---

## 📊 MODELOS DE OLLAMA RECOMENDADOS

### Para Pipelines:
- **CodeLlama 34B**: YAML e configuração
- **Qwen2.5-Coder 14B**: Scripts complexos

### Para Automação:
- **CodeLlama 34B**: Bash e Python scripts
- **DeepSeek-Coder 14B**: Otimização e debugging

### Para Arquitetura:
- **Mixtral 8x7B**: Design e estratégia
- **Llama 3 70B**: Análise complexa

---

Este catálogo oferece **10 prompts especializados** para CI/CD e automação no Cluster-AI, cobrindo GitHub Actions, Jenkins, GitLab e scripts de automação.

**Última atualização**: Outubro 2024
**Total de prompts**: 10
**Foco**: Pipelines automatizados e DevOps
