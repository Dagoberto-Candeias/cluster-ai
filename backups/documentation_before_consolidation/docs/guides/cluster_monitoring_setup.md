# Guia para Configuração de Monitoramento Contínuo do Cluster AI

Este documento descreve como configurar monitoramento contínuo para garantir a saúde e desempenho do Cluster AI.

---

## 1. Objetivo

Implementar monitoramento automatizado para:

- Verificar status dos serviços principais (Docker, Dask Scheduler, Ollama, OpenWebUI).
- Monitorar conectividade e status dos workers.
- Detectar falhas e reiniciar serviços automaticamente.
- Gerar alertas em caso de problemas críticos.

---

## 2. Ferramentas Utilizadas

- **scripts/management/health_check.sh**: Script para checagem de saúde do cluster.
- **scripts/management/monitor_node.sh**: Monitoramento de nós individuais.
- **scripts/monitoring/central_monitor.sh**: Monitoramento centralizado do cluster.
- **systemd** ou **cron**: Para agendamento e execução periódica dos scripts.

---

## 3. Configuração Básica

### 3.1. Agendamento com Cron

Exemplo de entrada no crontab para executar o health check a cada 5 minutos:

```bash
*/5 * * * * /bin/bash /caminho/para/scripts/management/health_check.sh >> /var/log/cluster_health.log 2>&1
```

### 3.2. Configuração com systemd

Criar um serviço systemd para monitoramento contínuo:

```ini
[Unit]
Description=Monitoramento do Cluster AI
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /caminho/para/scripts/management/central_monitor.sh
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
```

Habilitar e iniciar o serviço:

```bash
sudo systemctl enable cluster-monitor.service
sudo systemctl start cluster-monitor.service
```

---

## 4. Alertas e Logs

- Configure logs para armazenar saídas dos scripts em local acessível.
- Integre com sistemas de alerta (email, Slack, etc.) conforme necessidade.
- Revise periodicamente os logs para identificar padrões ou falhas recorrentes.

---

## 5. Manutenção

- Atualize os scripts de monitoramento conforme novas versões do cluster.
- Teste o monitoramento após atualizações para garantir funcionamento correto.
- Documente quaisquer alterações na configuração de monitoramento.

---

## 6. Suporte

Para dúvidas ou suporte, consulte a documentação principal do projeto ou contate a equipe de desenvolvimento.

---

Este guia será atualizado conforme o projeto evoluir.
