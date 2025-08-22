# 🚀 Biblioteca de Prompts para Desenvolvimento - Cluster AI

## 📋 Guia de Utilização para Ollama & OpenWebUI

### Configurações Recomendadas:
- **Modelos**: CodeLlama, Mistral, Mixtral para código; Llama2 para documentação
- **Temperatura**: 0.1-0.3 (código preciso), 0.5-0.7 (estratégias)
- **Personas**: Configure personas específicas no OpenWebUI

---

## 🔍 CATEGORIA: ANÁLISE E REVISÃO DO CLUSTER AI

### 1. Análise da Arquitetura do Cluster
**Prompt:**
```
[Instrução: Atue como um arquiteto de sistemas distribuídos com expertise em clusters de IA]

Analise a estrutura atual do Cluster AI e forneça recomendações para:

1. **Escalabilidade**: Como melhorar a escalabilidade horizontal do cluster Dask?
2. **Resiliência**: Estratégias para tornar o sistema mais tolerante a falhas
3. **Performance**: Otimizações para processamento distribuído de modelos de IA
4. **Monitoramento**: Melhorias no sistema de observabilidade

Estrutura atual:
[Forneça a saída de `tree` do projeto ou descreva a arquitetura]
```

### 2. Code Review Específico para Dask
**Prompt:**
```
[Instrução: Atue como um engenheiro especializado em processamento distribuído com Dask]

Revise o seguinte código de processamento distribuído:

```python
[Cole aqui o código Dask do Cluster AI]
```

Foque em:
- Uso eficiente de operações distribuídas
- Gerenciamento de memória em workers
- Tratamento de exceções em ambiente distribuído
- Otimização de comunicação entre scheduler e workers
```

---

## 🛠️ CATEGORIA: OTIMIZAÇÃO DO CLUSTER

### 3. Otimização de Workers Dask
**Prompt:**
```
[Instrução: Atue como um especialista em otimização de clusters Dask]

Otimize a configuração de workers para o seguinte cenário:
- Hardware: [Especificar CPU, RAM, GPU disponível]
- Carga de trabalho: Processamento de modelos Ollama + tarefas Dask
- Modelos: [Listar modelos Ollama em uso]

Solicito:
1. Configuração ideal de recursos por worker
2. Estratégia de escalabilidade automática
3. Otimizações específicas para GPU
4. Monitoramento de performance
```

### 4. Integração Ollama + Dask
**Prompt:**
```
[Instrução: Atue como um especialista em integração de modelos de IA com processamento distribuído]

Melhore a integração entre Ollama e Dask no Cluster AI:

```python
[Cole o código de integração atual]
```

Sugira:
1. Padrões de design para chamadas assíncronas
2. Gerenciamento de sessões de modelo
3. Balanceamento de carga entre workers
4. Tratamento de timeouts e retries
```

---

## 🌐 CATEGORIA: DEPLOY E INFRAESTRUTURA

### 5. Deploy em Produção com TLS
**Prompt:**
```
[Instrução: Atue como um engenheiro de DevOps especializado em deploy seguro]

Otimize o deploy em produção do Cluster AI com TLS:

Arquivos atuais:
```yaml
[Cole o docker-compose-tls.yml]
```
```nginx
[Cole o nginx-tls.conf]
```

Solicito:
1. Hardening de configurações Nginx
2. Otimização de certificados SSL
3. Configurações de segurança
4. Monitoramento de performance HTTPS
```

### 6. Auto-scaling para Cluster AI
**Prompt:**
```
[Instrução: Atue como um especialista em auto-scaling de clusters]

Implemente auto-scaling para o Cluster AI baseado em:

Métricas:
- Uso de CPU dos workers
- Fila de tarefas no scheduler
- Uso de memória
- Tempo de resposta dos modelos Ollama

Plataforma: [Kubernetes/AWS/Docker Swarm]

Forneça:
1. Configurações de scaling
2. Scripts de implementação
3. Métricas de monitoramento
4. Estratégia de cool-down
```

---

## 📊 CATEGORIA: MONITORAMENTO E OBSERVABILIDADE

### 7. Dashboard de Monitoramento
**Prompt:**
```
[Instrução: Atue como um engenheiro de observabilidade]

Crie um dashboard completo de monitoramento para o Cluster AI incluindo:

Métricas a monitorar:
- Performance Dask (tasks completadas, tempo de fila)
- Uso de recursos (CPU, RAM, GPU)
- Health check dos serviços
- Latência dos modelos Ollama
- Logs de erro e warnings

Ferramentas: [Grafana, Prometheus, ELK]

Forneça:
1. Configurações de coleta de métricas
2. Queries para dashboard
3. Alertas recomendados
4. Configuração de logging estruturado
```

### 8. Análise de Performance
**Prompt:**
```
[Instrução: Atue como um performance engineer]

Analise e otimize a performance do Cluster AI:

Problemas atuais:
[Descreva problemas de performance específicos]

Métricas disponíveis:
[Listar métricas coletadas]

Solicito:
1. Identificação de gargalos
2. Recomendações de otimização
3. Configurações específicas
4. Scripts de benchmark
```

---

## 🔒 CATEGORIA: SEGURANÇA

### 9. Hardening de Segurança
**Prompt:**
```
[Instrução: Atue como um especialista em segurança de aplicações]

Realize hardening de segurança completo no Cluster AI:

Áreas de foco:
- Configurações Docker e containers
- API do Ollama (11434)
- OpenWebUI (8080/3000)
- Comunicação entre serviços
- Gestão de secrets

Forneça:
1. Checklist de segurança
2. Configurações específicas
3. Ferramentas de scanning
4. Monitoramento de segurança
```

### 10. Backup e Disaster Recovery
**Prompt:**
```
[Instrução: Atue como um especialista em backup e recuperação de desastres]

Implemente uma estratégia robusta de backup para o Cluster AI:

Dados críticos:
- Modelos Ollama
- Configurações do cluster
- Dados de treinamento
- Logs e métricas

Solicito:
1. Estratégia de backup
2. Scripts de backup/restore
3. Testes de recuperação
4. Monitoramento de backups
```

---

## 🤖 CATEGORIA: MODELOS DE IA E OLLAMA

### 11. Otimização de Modelos Ollama
**Prompt:**
```
[Instrução: Atue como um especialista em otimização de modelos de LLM]

Otimize o uso de modelos Ollama no cluster:

Modelos em uso: [Listar modelos]
Hardware disponível: [Especificar GPU/RAM]

Solicito:
1. Configurações ótimas por modelo
2. Estratégia de loading/unloading
3. Otimização de memória GPU
4. Benchmarks de performance
```

### 12. Pipeline de Processamento com IA
**Prompt:**
```
[Instrução: Atue como um engenheiro de ML pipelines]

Crie pipelines otimizados para processamento distribuído com IA:

Cenários:
- Processamento em lote de documentos
- Análise de sentimentos em tempo real
- Geração de conteúdo distribuída
- Fine-tuning distribuído

Forneça:
1. Arquitetura dos pipelines
2. Código de implementação
3. Otimizações específicas
4. Monitoramento
```

---

## 📚 CATEGORIA: DOCUMENTAÇÃO

### 13. Documentação Técnica do Cluster
**Prompt:**
```
[Instrução: Atue como um escritor técnico especializado em documentação de software]

Melhore a documentação técnica do Cluster AI:

Documentação atual:
[Fornecer links ou conteúdo da doc existente]

Solicito:
1. Estrutura organizada por tópicos
2. Exemplos práticos de uso
3. Guias de troubleshooting
4. Documentação de API
```

### 14. Tutorial de Implementação
**Prompt:**
```
[Instrução: Atue como um instrutor técnico]

Crie um tutorial passo a passo para:

Tópico: [Implementação específica, ex: Deploy em Kubernetes]
Nível: [Iniciante/Intermediário/Avançado]

Forneça:
1. Passos detalhados
2. Comandos executáveis
3. Screenshots/exemplos
4. Solução de problemas comuns
```

---

## 🧪 CATEGORIA: TESTES

### 15. Testes de Carga para o Cluster
**Prompt:**
```
[Instrução: Atue como um engenheiro de performance testing]

Implemente testes de carga para o Cluster AI:

Cenários a testar:
- Carga máxima de usuários no OpenWebUI
- Processamento simultâneo de múltiplos modelos
- Stress test do scheduler Dask
- Teste de recuperação de falhas

Ferramentas: [Locust, k6, JMeter]

Forneça:
1. Scripts de teste
2. Configurações
3. Métricas a coletar
4. Análise de resultados
```

### 16. Testes de Integração
**Prompt:**
```
[Instrução: Atue como um QA engineer especializado em testes de integração]

Crie testes de integração para os componentes do Cluster AI:

Componentes:
- Dask Scheduler ↔ Workers
- OpenWebUI ↔ Ollama API
- Nginx ↔ Aplicações
- Sistema de backup

Solicito:
1. Casos de teste
2. Scripts de automação
3. Cobertura de teste
4. Relatórios
```

---

## 🔄 FLUXOS DE TRABALHO RECOMENDADOS

### Para Novas Features:
1. **Análise**: Use prompts de arquitetura (1-2)
2. **Implementação**: Use prompts de otimização (3-4)
3. **Testes**: Use prompts de testing (15-16)
4. **Deploy**: Use prompts de infraestrutura (5-6)
5. **Monitoramento**: Use prompts de observabilidade (7-8)

### Para Troubleshooting:
1. **Diagnóstico**: Use prompts de análise (1-2)
2. **Otimização**: Use prompts específicos da área
3. **Validação**: Use prompts de testing
4. **Documentação**: Use prompts de documentação (13-14)

---

## 🎯 CONFIGURAÇÕES ESPECÍFICAS PARA OPENWEBUI

### Personas Recomendadas:
```yaml
# Persona: Arquiteto de Cluster AI
Instrução: Você é um arquiteto especializado em clusters de IA distribuídos. Forneça recomendações técnicas detalhadas com exemplos práticos.

# Persona: DevOps para IA
Instrução: Você é um engenheiro de DevOps focado em infraestrutura para IA. Forneça scripts e configurações prontas para produção.

# Persona: Especialista em Performance
Instrução: Você é um performance engineer especializado em otimização de sistemas distribuídos. Foque em métricas e melhorias mensuráveis.
```

### Templates de Configuração:
```bash
# Para análise técnica (temperatura baixa)
ollama run codellama:34b --temperature 0.2 --prompt "file:cluster-analysis.txt"

# Para brainstorming (temperatura média)
ollama run mixtral:8x7b --temperature 0.6 --prompt "file:cluster-design.txt"

# Para geração de código (temperatura muito baixa)
ollama run codellama:13b --temperature 0.1 --prompt "file:optimization-code.txt"
```

---

## 📊 METR
