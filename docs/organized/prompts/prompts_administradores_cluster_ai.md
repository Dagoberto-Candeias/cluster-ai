# 🛠️ Catálogo de Prompts para Administradores - Cluster-AI

## 🎯 Guia Rápido de Utilização

### Configurações Recomendadas
- **Temperatura Baixa (0.1-0.3)**: Para configuração, troubleshooting
- **Temperatura Média (0.4-0.6)**: Para análise, planejamento
- **Temperatura Alta (0.7-0.9)**: Para automação, otimização

### Modelos por Categoria
- **LLM Geral**: Llama 3, Mixtral, Mistral
- **Codificação**: CodeLlama, Qwen2.5-Coder, DeepSeek-Coder

---

## 📁 CATEGORIA: INSTALAÇÃO E CONFIGURAÇÃO

### 1. Checklist de Pré-Instalação
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um administrador de sistemas experiente]

Crie um checklist completo de pré-instalação para o Cluster-AI:

**Ambiente:** [servidor dedicado/cloud/on-premise]
**Sistema Operacional:** [Ubuntu 22.04/Debian 11/etc.]
**Recursos:** [CPU, RAM, Disco, Rede]

**Solicito:**
1. Verificações de compatibilidade de hardware
2. Requisitos de sistema operacional
3. Dependências e pré-requisitos
4. Configurações de rede necessárias
5. Plano de rollback se necessário
```

### 2. Configuração de Produção Otimizada
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um arquiteto de infraestrutura]

Configure o Cluster-AI para ambiente de produção:

**Requisitos:**
- Alta disponibilidade
- Escalabilidade automática
- Segurança enterprise
- Monitoramento completo

**Infraestrutura:** [DESCREVA A INFRAESTRUTURA]

**Solicito:**
1. Arquitetura de produção recomendada
2. Configurações de cluster.conf otimizadas
3. Estratégia de backup e recuperação
4. Plano de monitoramento e alertas
5. Procedimentos de manutenção
```

### 3. Migração de Ambiente
**Modelo**: Mixtral/CodeLlama

```
[Instrução: Atue como um especialista em migração de sistemas]

Planeje a migração do Cluster-AI para novo ambiente:

**Origem:** [ambiente atual]
**Destino:** [novo ambiente - AWS/Azure/GCP]
**Restrições:** [downtime máximo, orçamento, etc.]

**Dados atuais:** [DESCREVA OS DADOS E CONFIGURAÇÕES]

**Solicito:**
1. Análise de compatibilidade
2. Estratégia de migração (big bang/phased)
3. Plano de contingência
4. Validação pós-migração
5. Rollback procedures
```

---

## 📁 CATEGORIA: GERENCIAMENTO DE INFRAESTRUTURA

### 4. Otimização de Recursos de Sistema
**Modelo**: DeepSeek-Coder/CodeLlama

```
[Instrução: Atue como um engenheiro de performance de sistemas]

Otimize os recursos do sistema para o Cluster-AI:

**Recursos atuais:**
- CPU: [número de cores, utilização média]
- Memória: [total, utilização média]
- Disco: [tipo, IOPS, espaço livre]
- Rede: [bandwidth, latência]

**Workloads:** [tipos de tarefas executadas]

**Solicito:**
1. Análise de utilização atual
2. Identificação de gargalos
3. Recomendações de otimização
4. Configurações de sistema otimizadas
5. Métricas de monitoramento
```

### 5. Configuração de Rede e Firewall
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um engenheiro de rede]

Configure rede e firewall para Cluster-AI seguro:

**Topologia:** [DESCREVA A TOPOLOGIA DE REDE]
**Requisitos de segurança:** [níveis de acesso, compliance]
**Serviços externos:** [APIs, bancos de dados externos]

**Solicito:**
1. Configuração de firewall (iptables/ufw)
2. Regras de rede para comunicação cluster
3. Configuração de VPN se necessário
4. Monitoramento de tráfego
5. Plano de resposta a incidentes
```

### 6. Gerenciamento de Certificados SSL/TLS
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em PKI e certificados]

Implemente gerenciamento de certificados para Cluster-AI:

**Cenário:** [HTTPS interno/externo, mTLS, etc.]
**CA:** [Let's Encrypt/interna/terceira]
**Domínios:** [LISTE OS DOMÍNIOS]

**Solicito:**
1. Estratégia de certificados
2. Script de geração/renovação
3. Configuração no Nginx
4. Automação de renovação
5. Monitoramento de expiração
```

---

## 📁 CATEGORIA: MONITORAMENTO E ALERTAS

### 7. Sistema de Monitoramento Completo
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um SRE especializado em observabilidade]

Implemente sistema de monitoramento para Cluster-AI:

**Métricas críticas:**
- Performance do cluster
- Saúde dos workers
- Utilização de recursos
- Latência de resposta

**Ferramentas disponíveis:** [Prometheus/Grafana/Zabbix/etc.]

**Solicito:**
1. Dashboard de monitoramento principal
2. Métricas essenciais a coletar
3. Alertas críticos e warning
4. Estratégia de retenção de dados
5. Relatórios automatizados
```

### 8. Estratégia de Alertas Inteligente
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um especialista em alert management]

Crie estratégia de alertas para reduzir noise e aumentar eficiência:

**Problemas atuais:** [muitos falsos positivos, alertas ignorados]
**Equipe:** [tamanho, horários de cobertura]
**SLA:** [tempos de resposta por severidade]

**Solicito:**
1. Classificação de alertas por severidade
2. Regras de escalação automática
3. Janelas de manutenção
4. Supressão inteligente de alertas
5. Relatórios de eficiência de alertas
```

### 9. Análise de Logs Centralizada
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um engenheiro de observabilidade]

Configure análise centralizada de logs para Cluster-AI:

**Fontes de logs:**
- Aplicação Cluster-AI
- Sistema operacional
- Nginx proxy
- Workers distribuídos

**Requisitos:** [busca rápida, retenção, análise]

**Solicito:**
1. Arquitetura de centralização
2. Configuração de coleta (Filebeat/rsyslog)
3. Estratégia de indexação e busca
4. Dashboards de análise
5. Políticas de retenção
```

---

## 📁 CATEGORIA: AUTOMAÇÃO E ORQUESTRAÇÃO

### 10. Automação de Deploy
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de DevOps]

Crie pipeline de deploy automatizado para Cluster-AI:

**Ambiente:** [desenvolvimento/staging/produção]
**Estratégia:** [blue-green/canary/rolling]
**Ferramentas:** [GitHub Actions/Jenkins/GitLab CI]

**Solicito:**
1. Pipeline completo (CI/CD)
2. Estratégia de deploy
3. Rollback automático
4. Testes automatizados
5. Aprovações manuais quando necessário
```

### 11. Gerenciamento de Configuração
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em configuration management]

Implemente gerenciamento de configuração para Cluster-AI:

**Configurações gerenciadas:**
- cluster.conf
- Configurações de workers
- Variáveis de ambiente
- Secrets e credenciais

**Ferramentas:** [Ansible/Chef/Puppet]

**Solicito:**
1. Estrutura de configuração
2. Templates parametrizados
3. Gestão de secrets
4. Validação de configuração
5. Versionamento de mudanças
```

### 12. Backup Automatizado
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um especialista em backup e recuperação]

Implemente estratégia de backup automatizado:

**Dados a proteger:**
- Configurações do cluster
- Dados de usuários
- Logs importantes
- Certificados e chaves

**Requisitos RTO/RPO:** [Recovery Time/Objective]

**Solicito:**
1. Estratégia de backup (completo/incremental)
2. Automação de backup
3. Testes de recuperação
4. Rotações de backup
5. Monitoramento de backups
```

---

## 📁 CATEGORIA: SEGURANÇA E CONFORMIDADE

### 13. Hardening de Segurança
**Modelo**: Mixtral/CodeLlama

```
[Instrução: Atue como um security engineer]

Aplique hardening de segurança no Cluster-AI:

**Vulnerabilidades identificadas:** [LISTE VULNERABILIDADES]
**Requisitos de compliance:** [GDPR/SOC2/ISO27001]
**Ambiente:** [produção/desenvolvimento]

**Solicito:**
1. Configurações de segurança do SO
2. Hardening do Docker/Kubernetes
3. Configurações de rede seguras
4. Gestão de acesso privilegiado
5. Monitoramento de segurança
```

### 14. Auditoria e Conformidade
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um auditor de segurança]

Implemente controles de auditoria para Cluster-AI:

**Requisitos de auditoria:**
- Acessos ao sistema
- Mudanças de configuração
- Operações críticas
- Incidentes de segurança

**Ferramentas:** [SIEM, log aggregation]

**Solicito:**
1. Estratégia de auditoria
2. Configuração de logs de auditoria
3. Relatórios de conformidade
4. Alertas de segurança
5. Procedimentos de resposta a incidentes
```

---

## 📁 CATEGORIA: TROUBLESHOOTING AVANÇADO

### 15. Diagnóstico de Problemas de Sistema
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um troubleshooter de sistemas]

Diagnostique problema complexo no Cluster-AI:

**Sintomas:** [DESCREVA OS SINTOMAS]
**Quando ocorre:** [condições específicas]
**Impacto:** [afetados usuários/sistema]

**Informações coletadas:**
- Logs do sistema
- Métricas de performance
- Configurações atuais

**Solicito:**
1. Análise sistemática do problema
2. Comandos de diagnóstico
3. Identificação da causa raiz
4. Solução recomendada
5. Prevenção de recorrência
```

### 16. Otimização de Performance de Sistema
**Modelo**: DeepSeek-Coder/CodeLlama

```
[Instrução: Atue como um performance engineer]

Otimize performance do sistema Cluster-AI:

**Problemas identificados:**
- Latência alta
- Throughput baixo
- Utilização desigual de recursos
- Bottlenecks identificados

**Métricas atuais:** [COLE MÉTRICAS]

**Solicito:**
1. Análise de performance atual
2. Identificação de gargalos
3. Recomendações de otimização
4. Implementação passo a passo
5. Métricas de validação
```

---

## 📋 TABELA DE USO POR CENÁRIO

| Cenário | Modelo Recomendado | Temperature | Prompt Exemplo |
|---------|-------------------|-------------|----------------|
| **Instalação** | Mixtral | 0.3 | Checklist |
| **Configuração** | Llama 3 | 0.4 | Produção |
| **Monitoramento** | CodeLlama | 0.3 | Sistema |
| **Segurança** | Mixtral | 0.3 | Hardening |
| **Automação** | CodeLlama | 0.2 | Deploy |
| **Troubleshooting** | DeepSeek-Coder | 0.3 | Diagnóstico |

---

## 🎯 CONFIGURAÇÕES PARA OPENWEBUI

### Template de Persona Administrador Cluster-AI:
```yaml
name: "Administrador Cluster-AI"
description: "Assistente para administração e operação do Cluster-AI"
instruction: |
  Você é um administrador de sistemas experiente especializado em Cluster-AI.
  Foque em estabilidade, segurança, performance e automação.
  Priorize soluções que reduzam trabalho manual e aumentem confiabilidade.
```

### Template de Configuração para Administração:
```yaml
model: "codellama"
temperature: 0.2
max_tokens: 2000
system: |
  Você é um administrador de sistemas sênior especializado em infraestrutura.
  Forneça soluções práticas, scripts funcionais e melhores práticas de administração.
  Considere alta disponibilidade, segurança e eficiência operacional.
```

---

## 💡 DICAS PARA ADMINISTRADORES

### Automação Primeiro
Sempre busque automatizar tarefas repetitivas

### Monitoramento Proativo
Configure alertas antes que problemas ocorram

### Documentação
Documente todos os procedimentos e configurações

### Segurança por Design
Incorpore segurança em todas as decisões

### Teste em Ambiente Seguro
Sempre teste mudanças em staging antes de produção

---

## 🔧 CATEGORIA: ADMINISTRAÇÃO DE REDES & INFRAESTRUTURA

### 17. Diagnóstico de Falhas em Logs do Sistema
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um administrador de sistemas experiente no Cluster-AI]

Analise os seguintes logs do sistema e sugira possíveis causas de falhas:

**Logs do sistema:** [COLE OS LOGS AQUI]
**Contexto:** [descrição do problema observado]
**Componentes afetados:** [manager/worker/health-check/etc.]

**Solicito:**
1. Análise das mensagens de erro
2. Possíveis causas raiz
3. Impacto no sistema Cluster-AI
4. Passos para diagnóstico adicional
5. Soluções recomendadas
```

### 18. Hardening de Servidores Cluster-AI
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um especialista em segurança de infraestrutura]

Sugira medidas de segurança para fortalecer a configuração dos servidores do Cluster-AI:

**Ambiente:** [desenvolvimento/produção]
**Sistema operacional:** [Ubuntu/Debian/etc.]
**Serviços rodando:** [Docker/Kubernetes/Ollama/etc.]

**Solicito:**
1. 10 medidas prioritárias de hardening
2. Configurações de firewall específicas
3. Gerenciamento de permissões
4. Estratégias de monitoramento
5. Checklist de conformidade
```

### 19. Automação de Backup para Cluster-AI
**Modelo**: CodeLlama/DeepSeek-Coder

```
[Instrução: Atue como um engenheiro de infraestrutura]

Crie um script de automação para backup dos componentes do Cluster-AI:

**Componentes para backup:** [configurações/modelos/dados/etc.]
**Frequência:** [diária/semanal/mensal]
**Destino:** [local/remoto/cloud]

**Solicito:**
1. Script completo em Bash/Python
2. Estratégia de rotação de backups
3. Verificação de integridade
4. Restauração de emergência
5. Monitoramento e alertas
```

### 20. Monitoramento Proativo de Infraestrutura
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um SRE (Site Reliability Engineer)]

Quais métricas devo monitorar em tempo real para garantir a estabilidade do Cluster-AI?

**Ambiente:** [desenvolvimento/produção]
**Escala:** [pequena/média/grande]
**Serviços críticos:** [Ollama/Dask/workers/etc.]

**Solicito:**
1. Métricas essenciais de sistema
2. Métricas específicas do Cluster-AI
3. Thresholds de alerta recomendados
4. Ferramentas de monitoramento sugeridas
5. Plano de resposta a incidentes
```

### 21. Checklist de Segurança de Rede
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um consultor de segurança de rede]

Crie um checklist completo de segurança para a rede do Cluster-AI:

**Topologia:** [descrição da arquitetura de rede]
**Acesso externo:** [sim/não - portas abertas]
**Usuários:** [número e tipos de usuários]

**Solicito:**
1. Verificações de configuração de firewall
2. Políticas de acesso e autenticação
3. Monitoramento de tráfego suspeito
4. Procedimentos de resposta a incidentes
5. Auditoria e compliance
```

---

## 💼 CATEGORIA: GESTÃO EMPRESARIAL & ADMINISTRAÇÃO

### 22. Análise SWOT para Cluster-AI
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um consultor estratégico]

Como posso aplicar análise SWOT no projeto Cluster-AI?

**Contexto atual:** [descrição da situação do projeto]
**Objetivos:** [crescimento/escalabilidade/adoção/etc.]
**Concorrência:** [outras soluções similares]

**Solicito:**
1. Forças (Strengths) do Cluster-AI
2. Fraquezas (Weaknesses) identificadas
3. Oportunidades (Opportunities) de mercado
4. Ameaças (Threats) potenciais
5. Plano de ação estratégico
```

### 23. Políticas de Segurança da Informação
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um especialista em governança de TI]

Redija uma política de segurança da informação para o Cluster-AI:

**Escopo:** [desenvolvimento/operacional/usuários]
**Regulamentações:** [LGPD/SOC2/ISO27001/etc.]
**Usuários:** [desenvolvedores/operadores/usuários finais]

**Solicito:**
1. Objetivos da política
2. Regras de acesso e autenticação
3. Proteção de dados sensíveis
4. Procedimentos de incidente
5. Responsabilidades e treinamentos
```

### 24. Planejamento de Expansão e Escalabilidade
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um planejador estratégico de TI]

Estruture um plano de expansão para o Cluster-AI:

**Situação atual:** [usuários/servidores/regiões]
**Objetivos de crescimento:** [quantitativos e qualitativos]
**Prazo:** [curto/médio/longo prazo]

**Solicito:**
1. Análise da capacidade atual
2. Roadmap de expansão técnica
3. Investimentos necessários
4. Timeline realista
5. Métricas de sucesso
```

---

## 💰 CATEGORIA: ANÁLISES FINANCEIRAS & COMERCIAIS

### 25. Análise de Custos Operacionais
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um analista financeiro de TI]

Analise os custos operacionais do Cluster-AI:

**Infraestrutura:** [servidores/cloud/energia/etc.]
**Dados de uso:** [COLE MÉTRICAS DE USO]
**Período:** [mês/atual]

**Solicito:**
1. Breakdown de custos por componente
2. Identificação de ineficiências
3. Projeções de otimização
4. ROI (Retorno sobre Investimento)
5. Recomendações de redução de custos
```

### 26. Projeção de Receitas e Modelo de Negócio
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um analista de negócio]

Projete um modelo de receita sustentável para o Cluster-AI:

**Público-alvo:** [empresas/pesquisadores/desenvolvedores]
**Modelo atual:** [open source/freemium/enterprise]
**Concorrência:** [análise comparativa]

**Solicito:**
1. Cenários de monetização viáveis
2. Projeções de receita realistas
3. Estratégias de precificação
4. Análise de mercado
5. Plano de implementação
```

### 27. Análise de Viabilidade Financeira
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um analista de investimentos]

Avalie a viabilidade financeira de expandir o Cluster-AI:

**Investimento necessário:** [valor estimado]
**Fontes de financiamento:** [disponíveis/planejadas]
**Projeções de retorno:** [curto/médio/longo prazo]

**Solicito:**
1. Análise de payback
2. Riscos financeiros identificados
3. Cenários otimista/pessimista
4. KPIs financeiros recomendados
5. Recomendações estratégicas
```

---

Este catálogo oferece **27 prompts especializados** para administradores do Cluster-AI, expandindo significativamente as capacidades de gestão técnica, estratégica e financeira do projeto.

**Última atualização**: Outubro 2024
**Total de prompts**: 27
**Foco**: Administração completa e gestão estratégica do Cluster-AI
