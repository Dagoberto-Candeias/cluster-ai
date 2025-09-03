# 🐳 Catálogo de Prompts: Docker & Containers - Cluster-AI

## 🎯 Guia Rápido de Utilização

### Configurações Recomendadas
- **Temperatura Baixa (0.1-0.3)**: Para Dockerfiles, configurações
- **Temperatura Média (0.4-0.6)**: Para otimização e troubleshooting
- **Temperatura Alta (0.7-0.9)**: Para arquitetura avançada

### Modelos por Categoria
- **Docker**: CodeLlama, Qwen2.5-Coder
- **Otimização**: DeepSeek-Coder
- **Arquitetura**: Mixtral, Llama 3

---

## 📁 CATEGORIA: DOCKERFILES OTIMIZADOS

### 1. Dockerfile Otimizado para Python
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em containerização Python]

Crie um Dockerfile otimizado para aplicação Python no Cluster-AI:

**Requisitos da Aplicação:**
- Framework: [FastAPI/Flask/Django]
- Dependências: [requirements.txt com principais libs]
- Porta: [8000]
- Health check endpoint: [/health]

**Otimização Necessária:**
- Multi-stage build
- Layer caching inteligente
- Imagem final mínima
- Security hardening

**Solicito:**
1. Dockerfile completo com multi-stage
2. .dockerignore otimizado
3. Build script com argumentos
4. Security scan recommendations
5. Performance benchmarks
```

### 2. Dockerfile para Node.js Application
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de containers Node.js]

Desenvolva Dockerfile otimizado para aplicação Node.js no Cluster-AI:

**Stack Tecnológico:**
- Runtime: [Node.js 18/20 LTS]
- Package manager: [npm/yarn/pnpm]
- Build tool: [Webpack/Vite/Next.js]
- Tipo: [API/Web App/Microserviço]

**Otimização de Build:**
- Dependency caching
- Source code copying strategy
- Production-ready image
- Multi-environment support

**Solicito:**
1. Dockerfile com build otimizado
2. Multi-stage para development/production
3. Package.json optimization tips
4. Security best practices
5. CI/CD integration
```

### 3. Dockerfile Multi-stage Avançado
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um especialista em otimização de containers]

Crie Dockerfile multi-stage avançado para build complexo no Cluster-AI:

**Build Complexo:**
- Linguagens múltiplas (Python + Node.js)
- Build tools pesados (GCC, Make)
- Assets estáticos (CSS/JS minification)
- Testing integrado no build

**Otimização Alvo:**
- Imagem final < 100MB
- Build time < 5 minutos
- Security vulnerabilities zero
- Cache layers inteligente

**Solicito:**
1. Dockerfile multi-stage completo
2. Build arguments para customização
3. Layer optimization strategy
4. Security scanning integrado
5. Performance metrics
```

---

## 📁 CATEGORIA: DOCKER COMPOSE

### 4. Docker Compose para Desenvolvimento
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um DevOps engineer especializado em desenvolvimento local]

Crie docker-compose.yml completo para desenvolvimento do Cluster-AI:

**Serviços Necessários:**
- Manager API (Python/FastAPI)
- Workers (Python com Dask)
- Redis para cache e filas
- PostgreSQL para dados
- Nginx como reverse proxy
- Monitoring stack (Prometheus/Grafana)

**Recursos de Desenvolvimento:**
- Hot reload habilitado
- Debug ports expostos
- Volume mounts para código
- Environment variables
- Health checks

**Solicito:**
1. docker-compose.yml principal
2. docker-compose.override.yml para dev
3. Dockerfile para cada serviço
4. .env template
5. Setup script automatizado
```

### 5. Docker Compose para Produção
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um SRE especializado em produção]

Configure docker-compose.yml para produção do Cluster-AI:

**Requisitos de Produção:**
- High availability
- Resource limits
- Health checks robustos
- Logging centralizado
- Security hardening

**Serviços Críticos:**
- Load balancer (HAProxy/Nginx)
- Application servers (3+ réplicas)
- Database com backup
- Monitoring e alerting
- Security services

**Solicito:**
1. docker-compose.prod.yml
2. Resource constraints
3. Health check configuration
4. Logging drivers
5. Security policies
6. Backup strategy integrada
```

### 6. Docker Compose com Redes Avançadas
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um network engineer para containers]

Implemente docker-compose com configuração de rede avançada:

**Topologia de Rede:**
- Frontend network (público)
- Backend network (privado)
- Database network (isolado)
- Monitoring network (admin)

**Recursos de Rede:**
- Custom networks com subnets
- Service discovery
- Load balancing interno
- Security policies por rede
- VPN integration

**Solicito:**
1. Networks configuration completa
2. Service connectivity matrix
3. Security groups por rede
4. DNS resolution interna
5. Network troubleshooting tools
```

---

## 📁 CATEGORIA: OTIMIZAÇÃO E PERFORMANCE

### 7. Otimização de Imagens Docker
**Modelo**: DeepSeek-Coder/CodeLlama

```
[Instrução: Atue como um performance engineer para containers]

Otimize imagens Docker para performance no Cluster-AI:

**Problemas Identificados:**
- Imagens muito grandes (>1GB)
- Build lento (>10 minutos)
- Runtime performance ruim
- Security vulnerabilities

**Métricas Alvo:**
- Tamanho: <200MB
- Build time: <3 minutos
- Startup time: <10 segundos
- Vulnerabilities: 0 críticas

**Solicito:**
1. Análise da imagem atual
2. Dockerfile otimizado
3. Build cache strategy
4. Runtime optimization
5. Security hardening
6. Performance benchmarks
```

### 8. Container Resource Management
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um SRE especializado em resource optimization]

Configure gerenciamento de recursos para containers do Cluster-AI:

**Workloads do Cluster:**
- CPU intensive workers
- Memory intensive APIs
- I/O intensive databases
- Network intensive services

**Resource Constraints:**
- CPU limits e requests
- Memory limits e reservations
- Disk I/O throttling
- Network bandwidth control

**Solicito:**
1. Resource quotas por serviço
2. Auto-scaling baseado em métricas
3. Resource monitoring
4. Cost optimization
5. Performance tuning
```

### 9. Container Security Hardening
**Modelo**: Mixtral/CodeLlama

```
[Instrução: Atue como um security engineer para containers]

Implemente hardening de segurança para containers do Cluster-AI:

**Vulnerabilidades Comuns:**
- Running as root
- No resource limits
- Exposed secrets
- Outdated base images

**Security Best Practices:**
- Non-root user
- Minimal attack surface
- Secret management
- Image scanning
- Runtime security

**Solicito:**
1. Dockerfile security hardening
2. docker-compose security config
3. Secret management strategy
4. Image scanning pipeline
5. Runtime security monitoring
6. Compliance checklist
```

---

## 📁 CATEGORIA: TROUBLESHOOTING E DEBUG

### 10. Debug de Containers
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um container debugging expert]

Debug problemas em containers do Cluster-AI:

**Sintomas do Problema:**
- Container não inicia
- Aplicação crasha dentro do container
- Performance degradada
- Network connectivity issues

**Debug Tools Disponíveis:**
- docker logs, docker exec
- docker stats, docker inspect
- strace, tcpdump dentro do container
- Application profiling

**Solicito:**
1. Systematic debugging approach
2. Container inspection commands
3. Log analysis methodology
4. Network debugging tools
5. Performance profiling
6. Root cause analysis
7. Fix implementation
```

---

## 📋 TABELA DE USO POR CENÁRIO

| Cenário | Modelo Recomendado | Temperature | Prompt Exemplo |
|---------|-------------------|-------------|----------------|
| **Dockerfile** | CodeLlama | 0.2 | Multi-stage Build |
| **Compose** | CodeLlama | 0.2 | Development Stack |
| **Otimização** | DeepSeek-Coder | 0.3 | Performance |
| **Segurança** | Mixtral | 0.3 | Hardening |
| **Debug** | CodeLlama | 0.3 | Troubleshooting |

---

## 🎯 CONFIGURAÇÕES PARA OPENWEBUI

### Template de Persona Docker Cluster-AI:
```yaml
name: "Especialista Docker Cluster-AI"
description: "Assistente para containerização e orquestração"
instruction: |
  Você é um especialista em Docker e containerização para sistemas distribuídos.
  Foque em otimização, segurança e performance de containers.
  Considere multi-stage builds, resource management e troubleshooting.
```

### Template de Configuração para Docker:
```yaml
model: "codellama"
temperature: 0.2
max_tokens: 2000
system: |
  Você é um engenheiro de containers sênior especializado em Docker.
  Forneça Dockerfiles otimizados, docker-compose funcionais e melhores práticas.
  Priorize segurança, performance e manutenibilidade.
```

---

## 💡 DICAS PARA DOCKER EFETIVO

### Multi-stage Builds
Sempre use multi-stage para reduzir tamanho das imagens

### Layer Caching
Ordene comandos para maximizar cache de layers

### Security First
Nunca rode containers como root em produção

### Resource Limits
Sempre defina CPU e memory limits

### Health Checks
Implemente health checks robustos

---

## 📊 MODELOS DE OLLAMA RECOMENDADOS

### Para Desenvolvimento:
- **CodeLlama 34B**: Dockerfiles e scripts
- **Qwen2.5-Coder 14B**: Configurações complexas

### Para Otimização:
- **DeepSeek-Coder 14B**: Performance e debugging
- **Mixtral 8x7B**: Análise e arquitetura

---

Este catálogo oferece **10 prompts especializados** para Docker e containers no Cluster-AI, cobrindo Dockerfiles, Docker Compose, otimização e segurança.

**Última atualização**: Outubro 2024
**Total de prompts**: 10
**Foco**: Containerização e orquestração
