# 🔒 Catálogo de Prompts para Segurança - Cluster-AI

## 🎯 Guia Rápido de Utilização

### Configurações Recomendadas
- **Temperatura Baixa (0.1-0.3)**: Para políticas, configuração, compliance
- **Temperatura Média (0.4-0.6)**: Para análise de riscos, auditoria
- **Temperatura Alta (0.7-0.9)**: Para resposta a incidentes, inovação

### Modelos por Categoria
- **LLM Geral**: Llama 3, Mixtral, Mistral
- **Codificação**: CodeLlama, Qwen2.5-Coder, DeepSeek-Coder

---

## 📁 CATEGORIA: ANÁLISE DE SEGURANÇA

### 1. Threat Modeling do Cluster-AI
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um threat modeler experiente]

Realize threat modeling completo do Cluster-AI:

**Componentes do sistema:**
- Manager API
- Workers distribuídos
- Comunicação inter-nós
- Armazenamento de dados
- Interfaces de usuário

**Atores de ameaça:** [internos/externos, motivados/não motivados]

**Solicito:**
1. Diagrama de arquitetura com zonas de confiança
2. Identificação de ativos críticos
3. Mapeamento de ameaças por componente
4. Avaliação de riscos (likelihood/impact)
5. Controles de segurança recomendados
```

### 2. Análise de Vulnerabilidades
**Modelo**: Mixtral/CodeLlama

```
[Instrução: Atue como um analista de vulnerabilidades]

Analise vulnerabilidades de segurança no Cluster-AI:

**Componentes analisados:**
- Código fonte Python
- Dependências (requirements.txt)
- Configurações de sistema
- Imagens Docker
- Infraestrutura cloud

**Ferramentas:** [SAST, SCA, container scanning]

**Solicito:**
1. Vulnerabilidades críticas identificadas
2. Análise de impacto e exploitabilidade
3. Priorização por CVSS score
4. Plano de remediação
5. Métricas de melhoria de segurança
```

### 3. Análise de Superfície de Ataque
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um penetration tester]

Analise a superfície de ataque do Cluster-AI:

**Pontos de entrada:**
- APIs públicas
- Interfaces web
- Workers expostos
- Comunicação entre nós
- Dependências externas

**Cenário:** [internet facing/internal network]

**Solicito:**
1. Mapeamento completo da superfície de ataque
2. Vetores de ataque identificados
3. Controles de segurança existentes
4. Lacunas de segurança
5. Recomendações de hardening
```

---

## 📁 CATEGORIA: IMPLEMENTAÇÃO DE CONTROLES

### 4. Configuração de Autenticação e Autorização
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um identity and access management engineer]

Implemente sistema robusto de autenticação e autorização:

**Requisitos:**
- Multi-factor authentication (MFA)
- Role-based access control (RBAC)
- Single sign-on (SSO)
- Session management seguro

**Usuários:** [admin, developer, user, service accounts]

**Solicito:**
1. Estratégia de autenticação
2. Configuração de RBAC
3. Implementação de MFA
4. Gestão de sessões
5. Auditoria de acesso
```

### 5. Criptografia de Dados
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um criptógrafo aplicado]

Implemente criptografia completa para dados do Cluster-AI:

**Dados a proteger:**
- Dados em trânsito (TLS 1.3)
- Dados em repouso (encryption at rest)
- Credenciais e secrets
- Comunicação inter-nós
- Backups

**Algoritmos:** [AES-256, RSA-4096, etc.]

**Solicito:**
1. Estratégia de criptografia end-to-end
2. Configuração de TLS/SSL
3. Encryption de dados em banco
4. Gestão de chaves (KMS)
5. Rotação de chaves automática
```

### 6. Implementação de WAF (Web Application Firewall)
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um security engineer especializado em WAF]

Configure WAF para proteger APIs do Cluster-AI:

**Proteções necessárias:**
- OWASP Top 10
- DDoS protection
- Rate limiting
- SQL injection prevention
- XSS protection

**WAF:** [Cloudflare, AWS WAF, ModSecurity]

**Solicito:**
1. Regras de WAF customizadas
2. Configuração de rate limiting
3. Proteção contra ataques comuns
4. Logging e monitoramento
5. False positive management
```

---

## 📁 CATEGORIA: MONITORAMENTO DE SEGURANÇA

### 7. SIEM Configuration
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um SIEM engineer]

Configure SIEM para monitoramento de segurança do Cluster-AI:

**Fontes de logs:**
- Application logs
- System logs
- Network logs
- Authentication logs
- API access logs

**SIEM:** [Splunk, ELK Stack, Azure Sentinel]

**Solicito:**
1. Configuração de coleta de logs
2. Parsing e normalização
3. Regras de correlação
4. Dashboards de segurança
5. Alerting e response automation
```

### 8. Intrusion Detection System
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um IDS/IPS engineer]

Implemente IDS/IPS para Cluster-AI:

**Proteções:**
- Network-based IDS (NIDS)
- Host-based IDS (HIDS)
- Anomaly detection
- Signature-based detection

**Ferramentas:** [Snort, Suricata, OSSEC]

**Solicito:**
1. Configuração do IDS/IPS
2. Regras de detecção customizadas
3. Integração com SIEM
4. Response automation
5. Tuning para reduzir falsos positivos
```

### 9. File Integrity Monitoring
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um security operations engineer]

Configure monitoramento de integridade de arquivos:

**Arquivos críticos:**
- Binários do sistema
- Configurações do Cluster-AI
- Scripts de automação
- Certificados e chaves

**Ferramentas:** [OSSEC, Tripwire, AIDE]

**Solicito:**
1. Baseline de integridade
2. Configuração de monitoramento
3. Alertas de alteração
4. Exclusões apropriadas
5. Relatórios de conformidade
```

---

## 📁 CATEGORIA: RESPONSE E RECOVERY

### 10. Plano de Resposta a Incidentes
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um incident response coordinator]

Crie plano de resposta a incidentes para Cluster-AI:

**Tipos de incidentes:**
- Breach de segurança
- Ransomware
- DDoS attack
- Data exfiltration
- Service disruption

**Equipe:** [tamanho, especializações, comunicação]

**Solicito:**
1. Processo de detecção e análise
2. Contenção e erradicação
3. Recuperação e lições aprendidas
4. Comunicação interna/externa
5. Documentação e melhoria contínua
```

### 11. Estratégia de Backup Seguro
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um backup security specialist]

Implemente estratégia de backup com foco em segurança:

**Requisitos de segurança:**
- Encryption de backups
- Imutabilidade de backups
- Air-gapping quando apropriado
- Testes de recuperação seguros

**RTO/RPO:** [Recovery Time/Objective]

**Solicito:**
1. Estratégia de backup segura
2. Encryption e proteção de backups
3. Testes de recuperação isolados
4. Chain of custody
5. Compliance com regulamentações
```

### 12. Disaster Recovery Planning
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um disaster recovery planner]

Desenvolva plano de disaster recovery para Cluster-AI:

**Cenários de desastre:**
- Data center failure
- Ransomware attack
- Natural disaster
- Cyber attack massivo

**RTO/RPO por serviço:** [crítico, importante, não crítico]

**Solicito:**
1. Análise de impacto de negócio
2. Estratégias de recuperação
3. Plano de comunicação
4. Testes e manutenção do plano
5. Melhoria contínua baseada em lições
```

---

## 📁 CATEGORIA: COMPLIANCE E GOVERNANÇA

### 13. Framework de Compliance
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um compliance officer]

Implemente framework de compliance para Cluster-AI:

**Regulamentações aplicáveis:**
- GDPR (dados pessoais)
- LGPD (Brasil)
- SOX (financial data)
- HIPAA (health data)

**Auditorias:** [internas, externas, certificações]

**Solicito:**
1. Mapeamento de controles por regulamentação
2. Implementação de controles técnicos
3. Processos de auditoria
4. Relatórios de conformidade
5. Plano de melhoria contínua
```

### 14. Gestão de Riscos de Segurança
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um risk management specialist]

Desenvolva programa de gestão de riscos de segurança:

**Metodologia:** [NIST RMF, ISO 27005, etc.]
**Escopo:** [tecnologia, processo, pessoas]

**Riscos identificados:** [LISTE RISCOS PRINCIPAIS]

**Solicito:**
1. Identificação e avaliação de riscos
2. Estratégias de mitigação
3. Plano de tratamento de riscos
4. Monitoramento contínuo
5. Relatórios para stakeholders
```

### 15. Auditoria de Segurança Técnica
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um auditor técnico de segurança]

Realize auditoria técnica de segurança do Cluster-AI:

**Áreas de auditoria:**
- Configuração de segurança
- Controles de acesso
- Proteção de dados
- Monitoramento e logging
- Incident response

**Ferramentas:** [automated scanners, manual testing]

**Solicito:**
1. Checklist de auditoria técnica
2. Execução da auditoria
3. Identificação de não-conformidades
4. Plano de remediação
5. Relatório executivo e técnico
```

---

## 📁 CATEGORIA: SEGURANÇA AVANÇADA

### 16. Zero Trust Architecture
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um zero trust architect]

Implemente arquitetura zero trust para Cluster-AI:

**Princípios zero trust:**
- Never trust, always verify
- Least privilege access
- Micro-segmentation
- Continuous monitoring

**Componentes:** [users, devices, applications, data]

**Solicito:**
1. Design da arquitetura zero trust
2. Controles de identidade e acesso
3. Micro-segmentação de rede
4. Monitoramento contínuo
5. Estratégia de implementação gradual
```

### 17. Security Information and Event Management
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um SIEM specialist]

Configure SIEM avançado para Cluster-AI:

**Recursos avançados:**
- Machine learning para detecção
- Behavioral analytics
- Threat intelligence integration
- Automated response

**Integrações:** [threat feeds, SOAR, etc.]

**Solicito:**
1. Configuração avançada do SIEM
2. Regras de correlação complexas
3. Integração com threat intelligence
4. Automated response playbooks
5. Advanced analytics e reporting
```

### 18. Container Security
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um container security specialist]

Implemente segurança abrangente para containers do Cluster-AI:

**Áreas de foco:**
- Imagens seguras
- Runtime security
- Orchestration security
- Supply chain security

**Ferramentas:** [Trivy, Falco, OPA, etc.]

**Solicito:**
1. Security scanning de imagens
2. Runtime protection
3. Network policies
4. Secret management
5. Compliance checking
```

---

## 📋 TABELA DE USO POR CENÁRIO

| Cenário | Modelo Recomendado | Temperature | Prompt Exemplo |
|---------|-------------------|-------------|----------------|
| **Análise** | Mixtral | 0.4 | Threat Modeling |
| **Controles** | CodeLlama | 0.2 | Autenticação |
| **Monitoramento** | CodeLlama | 0.3 | SIEM |
| **Response** | Mixtral | 0.4 | Incident Response |
| **Compliance** | Llama 3 | 0.4 | Framework |
| **Avançado** | CodeLlama | 0.3 | Zero Trust |

---

## 🎯 CONFIGURAÇÕES PARA OPENWEBUI

### Template de Persona Security Cluster-AI:
```yaml
name: "Security Engineer Cluster-AI"
description: "Assistente para segurança e compliance do Cluster-AI"
instruction: |
  Você é um security engineer experiente especializado em sistemas distribuídos.
  Foque em defesa em profundidade, compliance e resposta a incidentes.
  Priorize soluções que reduzam riscos e aumentem a resiliência.
```

### Template de Configuração para Segurança:
```yaml
model: "codellama"
temperature: 0.2
max_tokens: 2000
system: |
  Você é um security engineer sênior especializado em segurança de sistemas.
  Forneça soluções práticas, configurações seguras e melhores práticas de segurança.
  Considere defesa em profundidade, compliance e operational security.
```

---

## 💡 DICAS PARA PROFISSIONAIS DE SEGURANÇA

### Defense in Depth
Implemente múltiplas camadas de segurança

### Zero Trust Mindset
Nunca confie, sempre verifique

### Continuous Monitoring
Monitore tudo, sempre

### Incident Response Ready
Prepare-se para incidentes antes que ocorram

### Compliance as Code
Automatize verificações de conformidade

---

## 🔍 CATEGORIA: AUDITORIA INTERNA & COMPLIANCE

### 19. Checklist de Auditoria Interna
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um auditor interno especializado em tecnologia]

Crie um checklist de auditoria interna para verificar se o Cluster-AI está em conformidade:

**Regulamentações aplicáveis:** [LGPD/SOC2/ISO27001/etc.]
**Escopo da auditoria:** [sistema completo/componentes específicos]
**Período:** [anual/trimestral/mensal]

**Solicito:**
1. Verificações de conformidade regulatória
2. Controles de segurança implementados
3. Procedimentos de auditoria técnica
4. Evidências documentais necessárias
5. Plano de ação corretiva
```

### 20. Análise de Riscos Operacionais
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um analista de riscos corporativos]

Analise o seguinte processo interno do Cluster-AI e identifique riscos de fraude:

**Processo:** [DESCREVA O PROCESSO - ex: pagamentos, acessos, dados]
**Controles atuais:** [LISTE CONTROLES EXISTENTES]
**Dados históricos:** [incidentes anteriores, vulnerabilidades]

**Solicito:**
1. Identificação de pontos de risco
2. Avaliação de impacto e probabilidade
3. Controles adicionais recomendados
4. Plano de mitigação de riscos
5. Indicadores de monitoramento
```

### 21. Relatório Executivo de Auditoria
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um auditor sênior]

Gere um relatório executivo de auditoria para o Cluster-AI:

**Objetivo da auditoria:** [conformidade/segurança/operacional]
**Período auditado:** [datas específicas]
**Equipe auditora:** [interna/externa]

**Solicito:**
1. Resumo executivo dos achados
2. Avaliação geral de conformidade
3. Principais riscos identificados
4. Recomendações prioritárias
5. Plano de ação com responsáveis e prazos
```

### 22. Detecção de Anomalias em Transações
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um especialista em detecção de fraudes]

Dado o seguinte conjunto de transações do Cluster-AI, identifique movimentações suspeitas:

**Transações:** [COLE DADOS DAS TRANSAÇÕES]
**Padrões normais:** [DESCREVA COMPORTAMENTO ESPERADO]
**Alertas anteriores:** [fraudes detectadas anteriormente]

**Solicito:**
1. Análise de padrões anômalos
2. Indicadores de risco identificados
3. Recomendações de investigação
4. Controles preventivos sugeridos
5. Relatório de achados
```

### 23. Avaliação de Conformidade Regulatória
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um compliance officer]

Avalie se o Cluster-AI está em conformidade com regulamentações específicas:

**Regulamentação:** [LGPD/GDPR/HIPAA/etc.]
**Componentes auditados:** [dados/processos/sistemas]
**Requisitos específicos:** [LISTE REQUISITOS DA REGULAMENTAÇÃO]

**Solicito:**
1. Mapeamento de conformidade por requisito
2. Gaps identificados
3. Plano de remediação
4. Controles de monitoramento contínuo
5. Documentação de evidências
```

---

## 🔐 CATEGORIA: GESTÃO DE SENHAS E AUTENTICAÇÃO

### 24. Política de Senhas Corporativas
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um especialista em segurança de identidade]

Crie uma política de senhas seguras para o Cluster-AI:

**Ambiente:** [corporativo/desenvolvimento/produção]
**Usuários:** [desenvolvedores/administradores/usuários finais]
**Requisitos de compliance:** [NIST/ISO/etc.]

**Solicito:**
1. Requisitos de complexidade de senha
2. Política de rotação e expiração
3. Controles de reutilização
4. Integração com sistemas existentes
5. Procedimentos de recuperação
```

### 25. Configuração de MFA Avançada
**Modelo**: CodeLlama/Qwen2.5-Coder

```
[Instrução: Atue como um engenheiro de segurança]

Explique os passos para configurar autenticação multifator (MFA) no Cluster-AI:

**Sistema:** [Linux/Windows/Cloud]
**Métodos MFA:** [TOTP/SMS/Hardware tokens]
**Integrações:** [OpenSSH/Docker/Kubernetes]

**Solicito:**
1. Guia passo a passo de implementação
2. Configuração de servidores
3. Integração com aplicações
4. Procedimentos de contingência
5. Monitoramento e auditoria
```

---

## 📊 CATEGORIA: MONITORAMENTO DE SEGURANÇA

### 26. Estratégia de Monitoramento de Segurança
**Modelo**: Mixtral/Llama 3

```
[Instrução: Atue como um security operations center (SOC) analyst]

Desenvolva uma estratégia completa de monitoramento de segurança para o Cluster-AI:

**Infraestrutura:** [servidores/cloud/containers]
**Ameaças principais:** [DDoS/injeção/violação de dados]
**Equipe de resposta:** [tamanho/disponibilidade]

**Solicito:**
1. Ferramentas e tecnologias de monitoramento
2. Métricas de segurança críticas
3. Estratégia de detecção de ameaças
4. Plano de resposta a incidentes
5. Relatórios e dashboards
```

### 27. Análise de Logs de Segurança
**Modelo**: CodeLlama/Mixtral

```
[Instrução: Atue como um analista forense digital]

Analise os seguintes logs de segurança do Cluster-AI:

**Logs:** [COLE LOGS DE SEGURANÇA]
**Tipo de evento:** [tentativa de acesso/violação/anomalia]
**Contexto:** [período/sistema afetado]

**Solicito:**
1. Identificação de eventos suspeitos
2. Análise de padrões de ataque
3. Impacto potencial no sistema
4. Recomendações de contenção
5. Lições aprendidas para prevenção
```

---

Este catálogo oferece **27 prompts especializados** para profissionais de segurança no Cluster-AI, expandindo significativamente as capacidades de auditoria, compliance e monitoramento de segurança do projeto.
