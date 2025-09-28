# 🚀 Novas Funcionalidades de Deployment - Cluster AI

## 📋 Visão Geral

Este guia documenta as novas funcionalidades de deployment implementadas no Cluster AI, incluindo descoberta automática de workers, instalação unificada via web e ferramentas avançadas de configuração.

## 🔍 Descoberta Automática de Workers

### Funcionalidade
O sistema de descoberta automática permite identificar e configurar workers Dask em um cluster Kubernetes de forma automática, sem intervenção manual.

### Como Usar

#### Via Script
```bash
# Executar descoberta automática
./scripts/deployment/auto_discover_workers.sh

# Ou via Python
python scripts/deployment/auto_discover_workers.py
```

#### Via Manager
```bash
./manager.sh
# Selecionar: 7. Configurar Worker Android
# Selecionar: 5. Descobrir Workers Automaticamente
```

### O que o Sistema Faz
1. **Varredura Automática**: Busca por pods Dask worker no cluster
2. **Verificação de Status**: Confirma se os workers estão saudáveis
3. **Registro Automático**: Adiciona workers válidos à configuração
4. **Relatório Detalhado**: Mostra informações de todos os workers encontrados

### Exemplo de Saída
```
🔍 Descobrindo workers automaticamente...
NAME                    READY   STATUS    RESTARTS   AGE   IP           NODE
dask-worker-1           1/1     Running   0          5m    10.0.1.10    node-1
dask-worker-2           1/1     Running   0          5m    10.0.1.11    node-2
dask-worker-3           1/1     Running   0          3m    10.0.1.12    node-3
```

## 🌐 Instalador Unificado Web

### Funcionalidade
O instalador web unificado permite configurar todo o ambiente Cluster AI (Open WebUI + Dask) através de uma interface web intuitiva, com configuração de alertas por email.

### Pré-requisitos
- Sistema Linux (Ubuntu/Debian/Fedora)
- Acesso root/sudo
- Conexão com internet
- Conta Gmail com senha de app

### Como Usar

#### Instalação Básica
```bash
# Executar instalador unificado
./scripts/deployment/webui-installer.sh
```

#### Processo de Instalação
1. **Configuração de Email**: Insira credenciais Gmail para alertas
2. **Instalação de Dependências**: Python, MPI, Docker
3. **Criação de Ambiente Virtual**: Ambiente isolado para Dask
4. **Configuração Automática**: Ativação automática no ~/.bashrc
5. **Instalação Docker**: Se não estiver presente
6. **Deploy Open WebUI**: Container Docker configurado
7. **Sistema de Alertas**: Configuração de notificações por email

### Funcionalidades Incluídas

#### Ambiente Python Otimizado
```bash
# Ambiente virtual criado automaticamente
source ~/cluster_env/bin/activate

# Pacotes instalados
pip list | grep -E "(dask|distributed|numpy|pandas|scipy|mpi4py)"
```

#### Open WebUI com Persistência
```bash
# Container com volume persistente
docker run -d --name open-webui \
  -p 8080:8080 \
  -v $HOME/open-webui:/app/data \
  ghcr.io/open-webui/open-webui:main
```

#### Sistema de Alertas
```python
# Script de envio de alertas criado
python ~/send_alert.py
```

### Verificação Pós-Instalação
```bash
# Verificar serviços
docker ps | grep open-webui
curl http://localhost:8080

# Testar ambiente Python
source ~/cluster_env/bin/activate
python -c "import dask; print('Dask OK')"

# Testar alertas
python ~/send_alert.py
```

## ⚙️ Configuração Avançada

### Personalização do Ambiente
```bash
# Editar ~/.bashrc para personalizar
nano ~/.bashrc

# Adicionar variáveis customizadas
export DASK_SCHEDULER_PORT=8786
export OPENWEBUI_PORT=8080
```

### Configuração de Rede
```bash
# Abrir portas necessárias
sudo ufw allow 8080/tcp  # Open WebUI
sudo ufw allow 8786/tcp  # Dask Scheduler
sudo ufw allow 8787/tcp  # Dask Dashboard
```

### Backup e Restauração
```bash
# Backup da configuração
tar -czf webui_backup.tar.gz ~/open-webui ~/cluster_env

# Restauração
tar -xzf webui_backup.tar.gz -C ~/
```

## 🔧 Solução de Problemas

### Erro de Conexão Docker
```bash
# Verificar status do Docker
sudo systemctl status docker

# Reiniciar serviço
sudo systemctl restart docker

# Verificar permissões
sudo usermod -aG docker $USER
newgrp docker
```

### Problemas com Ambiente Virtual
```bash
# Recriar ambiente se corrompido
rm -rf ~/cluster_env
python3 -m venv ~/cluster_env
source ~/cluster_env/bin/activate
pip install dask[complete] distributed numpy pandas scipy mpi4py
```

### Falha no Envio de Email
```bash
# Verificar credenciais Gmail
# Criar senha de app em: https://myaccount.google.com/apppasswords

# Testar conectividade SMTP
telnet smtp.gmail.com 465
```

## 📊 Monitoramento e Logs

### Logs do Sistema
```bash
# Logs do Docker
docker logs open-webui

# Logs do Dask (se executando)
tail -f ~/.dask-worker.log

# Logs de instalação
tail -f ~/cluster_install.log
```

### Monitoramento de Recursos
```bash
# Uso de CPU/Memória
htop

# Containers ativos
docker stats

# Processos Python
ps aux | grep python
```

## 🚀 Casos de Uso Avançados

### Cluster Multi-Nó
```bash
# Configurar scheduler em máquina principal
dask-scheduler --host 0.0.0.0 --port 8786

# Conectar workers de outras máquinas
dask-worker scheduler-ip:8786
```

### Integração com Kubernetes
```yaml
# Exemplo de deployment Kubernetes
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dask-worker
spec:
  replicas: 3
  selector:
    matchLabels:
      app: dask
      component: worker
  template:
    spec:
      containers:
      - name: dask-worker
        image: daskdev/dask:latest
        command: ["dask-worker", "dask-scheduler:8786"]
```

### Automação com Scripts
```bash
#!/bin/bash
# deploy_cluster.sh

# Instalar via web installer
./scripts/deployment/webui-installer.sh

# Descobrir workers automaticamente
./scripts/deployment/auto_discover_workers.sh

# Configurar monitoramento
./scripts/monitoring/setup_monitor_service.sh

echo "Cluster implantado com sucesso!"
```

## 📈 Benefícios das Novas Funcionalidades

### Para Administradores
- ✅ **Setup Automatizado**: Instalação completa em minutos
- ✅ **Descoberta Inteligente**: Workers encontrados automaticamente
- ✅ **Monitoramento Integrado**: Alertas e notificações automáticas
- ✅ **Configuração Web**: Interface intuitiva para setup

### Para Desenvolvedores
- ✅ **Ambiente Pronto**: Python + Dask configurado automaticamente
- ✅ **Integração Fácil**: Conexão transparente com Kubernetes
- ✅ **Debugging Avançado**: Logs detalhados e monitoramento
- ✅ **Escalabilidade**: Adição dinâmica de workers

### Para Usuários Finais
- ✅ **Instalação Simples**: Processo guiado passo a passo
- ✅ **Interface Web**: Acesso via navegador
- ✅ **Alertas Automáticos**: Notificações por email
- ✅ **Suporte Completo**: Documentação e troubleshooting integrados

## 🔗 Próximos Passos

### Expansão Planejada
- [ ] **Interface Web Avançada**: Dashboard completo para gerenciamento
- [ ] **Auto-scaling**: Escalabilidade automática baseada em carga
- [ ] **Multi-cloud**: Suporte a múltiplos provedores de nuvem
- [ ] **Integração CI/CD**: Pipelines automatizados de deployment

### Melhorias em Desenvolvimento
- [ ] **Backup Automático**: Estratégias de backup inteligentes
- [ ] **Monitoramento Avançado**: Métricas e alertas customizáveis
- [ ] **Segurança Aprimorada**: Autenticação e autorização robustas
- [ ] **Documentação Expandida**: Guias para casos de uso específicos

## 📞 Suporte

### Canais de Suporte
- **Documentação**: Este guia e documentação relacionada
- **GitHub Issues**: Para bugs e solicitações de features
- **Comunidade**: Discussões e compartilhamento de experiências

### Recursos Adicionais
- **[Guia de Troubleshooting](../guides/troubleshooting.md)**: Solução de problemas comuns
- **[Monitoramento](../guides/monitoring.md)**: Ferramentas de observabilidade
- **[Segurança](../security/)**: Medidas de segurança implementadas

---

**🎯 Status**: Funcionalidades implementadas e documentadas
**📅 Última Atualização**: $(date +%Y-%m-%d)
**👥 Mantenedor**: Equipe de Desenvolvimento Cluster AI
