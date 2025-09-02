# Guia de Uso e Manutenção do Auto Start do Cluster AI

Este documento descreve o processo de uso e manutenção do script de inicialização automática do Cluster AI, que permite iniciar o servidor e os workers automaticamente na mesma rede.

---

## 1. Visão Geral

O script `scripts/management/auto_start_cluster.sh` automatiza as seguintes etapas:

- Inicialização do servidor principal (scheduler Dask, Ollama, OpenWebUI, Docker).
- Descoberta automática dos nós (workers) na rede local.
- Inicialização remota dos workers conectando ao scheduler via IP ou hostname.

---

## 2. Pré-requisitos

- Rede local configurada com IPs na faixa `192.168.0.0/24` (pode ser ajustado no script).
- Autenticação SSH sem senha configurada entre o servidor e os workers.
- O projeto `cluster-ai` deve estar no mesmo caminho nos nós remotos (`~/Projetos/cluster-ai` por padrão).
- Docker e serviços necessários instalados e configurados no servidor.

---

## 3. Como usar

### Executar o script de auto start

```bash
bash scripts/management/auto_start_cluster.sh
```

Este comando:

- Inicia o servidor e serviços principais.
- Descobre automaticamente os nós na rede local.
- Inicia os workers remotamente conectando ao scheduler.

### Logs e monitoramento

- Verifique os logs dos serviços para garantir que todos os componentes estejam ativos.
- Use o dashboard do Dask em `http://<IP_DO_SERVIDOR>:8787` para monitorar os workers.

---

## 4. Manutenção

### Adicionar novos workers

- Registre o worker usando o script `scripts/deployment/register_worker_node.sh`.
- Certifique-se que a chave SSH pública do worker está autorizada no servidor.
- Execute novamente o script de auto start para detectar e iniciar o novo worker.

### Atualizar scripts

- Mantenha os scripts atualizados conforme novas versões do projeto.
- Teste as atualizações em ambiente controlado antes de aplicar em produção.

### Monitoramento contínuo

- Considere configurar jobs cron ou systemd para executar o script de auto start periodicamente.
- Implemente alertas para falhas nos serviços e indisponibilidade dos workers.

---

## 5. Solução de problemas

- **Falha na descoberta dos nós:** Verifique a faixa de IP configurada e a conectividade SSH.
- **Workers não iniciam:** Confirme o caminho do projeto e permissões SSH.
- **Serviços do servidor não iniciam:** Verifique logs do Docker e serviços relacionados.

---

## 6. Contato e suporte

Para dúvidas e suporte, consulte a documentação principal do projeto ou entre em contato com a equipe de desenvolvimento.

---

Este guia será atualizado conforme o projeto evoluir.
