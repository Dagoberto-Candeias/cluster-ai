# Documentação Detalhada dos Dashboards e Interfaces de Monitoramento do Cluster AI

Este documento apresenta uma explicação detalhada em português sobre cada dashboard e interface de monitoramento presentes no projeto Cluster AI, seus propósitos e cenários de uso.

---

## 1. Dashboard Web Principal (React + Material-UI)

### Propósito
Interface gráfica principal para monitoramento em tempo real do cluster distribuído de IA. Permite visualizar métricas do sistema, status dos workers, alertas e configurações.

### Componentes Principais
- **Dashboard.tsx**: Página principal com gráficos de uso de CPU, memória, disco e rede.
- **Workers.tsx**: Lista detalhada dos workers ativos, com status e uso de recursos.
- **Alerts.tsx**: Histórico e notificações de alertas críticos, avisos e informações.
- **Settings.tsx**: Configurações do dashboard e preferências do usuário.

### Cenários de Uso
- Operadores monitoram a saúde do cluster em tempo real.
- Administradores verificam alertas e tomam ações corretivas.
- Engenheiros ajustam configurações para otimização do sistema.

---

## 2. API Backend (FastAPI)

### Propósito
Fornecer dados e serviços para o frontend e outras integrações via endpoints REST e WebSocket.

### Endpoints Relevantes
- `/api/v1/metrics/system`: Retorna métricas históricas do sistema.
- `/api/v1/metrics/system/current`: Métricas atuais em tempo real.
- `/api/v1/workers`: Informações dos workers ativos.
- `/api/v1/alerts`: Dados de alertas gerados pelo sistema.
- `/ws/connections`: Status das conexões WebSocket ativas.

### Cenários de Uso
- Frontend consome dados para exibir dashboards.
- Serviços externos podem integrar-se para automação.
- Monitoramento e alertas em tempo real via WebSocket.

---

## 3. Dashboards de Monitoramento via Grafana

### Propósito
Visualização avançada e customizável das métricas coletadas pelo Prometheus.

### Arquivos e Configurações
- Dashboards JSON localizados em `monitoring/grafana/dashboards/`.
- Provisionamento automático via arquivos em `monitoring/grafana/provisioning/`.

### Cenários de Uso
- Engenheiros de DevOps analisam métricas detalhadas.
- Visualização histórica e alertas configuráveis.
- Integração com Prometheus para coleta eficiente.

---

## 4. Prometheus

### Propósito
Coletar, armazenar e disponibilizar métricas do sistema e serviços.

### Configuração
- Arquivo principal: `monitoring/prometheus/prometheus.yml`.
- Configurado para coletar métricas do backend, workers e serviços auxiliares.

### Cenários de Uso
- Coleta contínua de métricas para análise.
- Base para alertas e dashboards Grafana.

---

## 5. Kibana + Elasticsearch + Logstash (ELK Stack)

### Propósito
Gerenciamento e visualização dos logs do sistema para auditoria e troubleshooting.

### Configuração
- Elasticsearch armazena os logs.
- Logstash processa e envia logs para Elasticsearch.
- Kibana oferece interface para consulta e visualização.

### Cenários de Uso
- Análise de logs para identificar falhas.
- Auditoria de operações sensíveis.
- Monitoramento de segurança.

---

## 6. Dashboards via Terminal (Scripts Bash)

### Propósito
Monitoramento rápido e direto via terminal para administradores que preferem linha de comando.

### Scripts Principais
- `scripts/monitoring/dashboard.sh`: Exibe métricas em tempo real no terminal.
- `scripts/monitoring/central_monitor.sh`: Monitoramento centralizado com logs.

### Cenários de Uso
- Acesso rápido sem interface gráfica.
- Diagnóstico em ambientes restritos.

---

## Considerações Finais

O sistema de monitoramento do Cluster AI é robusto e flexível, combinando interfaces gráficas modernas, APIs REST/WebSocket, dashboards avançados e ferramentas tradicionais de linha de comando para atender diferentes perfis de usuários e necessidades operacionais.

Para dúvidas ou sugestões, consulte a documentação técnica ou entre em contato com a equipe de desenvolvimento.

---

**Data:** Setembro 2025  
**Versão:** 1.0  
**Autor:** Equipe Cluster AI
