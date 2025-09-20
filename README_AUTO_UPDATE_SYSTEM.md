# 🚀 Sistema de Auto Atualização - Cluster AI

## 📋 Visão Geral

O Sistema de Auto Atualização é uma solução completa e robusta para manter o Cluster AI sempre atualizado de forma automática e segura. O sistema verifica continuamente por atualizações disponíveis e permite ao usuário aprovar ou rejeitar as atualizações antes de aplicá-las.

## ✨ Funcionalidades

- **Verificação Automática**: Verifica atualizações de Git, Docker, Sistema Operacional e Modelos de IA
- **Interface Interativa**: Interface amigável para aprovar/rejeitar atualizações
- **Backups Automáticos**: Cria backups antes de aplicar atualizações
- **Rollback Seguro**: Reverte automaticamente em caso de falha
- **Monitoramento Contínuo**: Monitora em background por novas atualizações
- **Agendamento Flexível**: Configuração via cron para verificações periódicas
- **Logs Detalhados**: Registro completo de todas as operações
- **Configuração Personalizável**: Ajuste fino via arquivo de configuração

## 📁 Arquivos do Sistema

### Scripts Principais
- `scripts/update_checker.sh` - Verifica atualizações disponíveis
- `scripts/update_notifier.sh` - Interface interativa para gerenciar atualizações
- `scripts/backup_manager.sh` - Gerencia backups automáticos
- `scripts/maintenance/auto_updater.sh` - Aplica atualizações de forma segura
- `scripts/monitor_worker_updates.sh` - Monitora continuamente por atualizações
- `scripts/maintenance/update_scheduler.sh` - Gerencia agendamento via cron

### Arquivos de Configuração
- `config/update.conf` - Configurações principais do sistema
- `logs/update_status.json` - Status atual das atualizações
- `logs/update_checker.log` - Logs da verificação de atualizações
- `logs/auto_updater.log` - Logs das aplicações de atualização

## 🚀 Como Usar

### 1. Configuração Inicial

```bash
# Configurar o sistema de agendamento
./scripts/maintenance/update_scheduler.sh setup

# Verificar status do sistema
./scripts/maintenance/update_scheduler.sh status
```

### 2. Verificar Atualizações

```bash
# Verificar se há atualizações disponíveis
./scripts/update_checker.sh

# Ver atualizações disponíveis com interface interativa
./scripts/update_notifier.sh
```

### 3. Monitoramento Contínuo

```bash
# Iniciar monitoramento em background
./scripts/monitor_worker_updates.sh start

# Verificar status do monitoramento
./scripts/monitor_worker_updates.sh status

# Parar monitoramento
./scripts/monitor_worker_updates.sh stop
```

### 4. Gerenciamento de Backups

```bash
# Criar backup manual
./scripts/backup_manager.sh create

# Listar backups disponíveis
./scripts/backup_manager.sh list

# Limpar backups antigos
./scripts/backup_manager.sh cleanup
```

### 5. Aplicar Atualizações Manualmente

```bash
# Aplicar atualizações específicas
./scripts/maintenance/auto_updater.sh git docker:open-webui system
```

## ⚙️ Configuração

### Arquivo de Configuração Principal

O arquivo `config/update.conf` contém todas as configurações do sistema:

```ini
[GENERAL]
# Frequência de verificação (em minutos)
CHECK_INTERVAL=60

# Habilitar notificações automáticas
AUTO_NOTIFY=true

# Habilitar backups automáticos
AUTO_BACKUP=true

# Diretório para backups
BACKUP_DIR=${PROJECT_ROOT}/backups/auto_update

[REPOSITORY]
# Política de atualização do Git
GIT_UPDATE_POLICY=ask

[DOCKER]
# Containers a verificar
DOCKER_CONTAINERS=open-webui,nginx,ollama

# Política de atualização Docker
DOCKER_UPDATE_POLICY=ask

[SYSTEM]
# Política de atualização do sistema
SYSTEM_UPDATE_POLICY=ask

[MODELS]
# Política de atualização de modelos
MODELS_UPDATE_POLICY=ask
```

### Políticas de Atualização

- `auto`: Atualizar automaticamente sem perguntar
- `ask`: Perguntar antes de atualizar (recomendado)
- `never`: Nunca atualizar automaticamente

## 📊 Monitoramento e Logs

### Logs do Sistema

```bash
# Ver logs de verificação
tail -f logs/update_checker.log

# Ver logs de atualização
tail -f logs/auto_updater.log

# Ver logs de monitoramento
tail -f logs/monitor_updates.log

# Ver logs de backup
tail -f logs/backup_manager.log
```

### Status das Atualizações

```bash
# Ver status atual
cat logs/update_status.json | jq '.'
```

## 🔧 Comandos Avançados

### Agendamento

```bash
# Configurar agendamento otimizado
./scripts/maintenance/update_scheduler.sh setup

# Verificar integridade do agendamento
./scripts/maintenance/update_scheduler.sh verify

# Mostrar cron jobs atuais
./scripts/maintenance/update_scheduler.sh show

# Remover todos os cron jobs
./scripts/maintenance/update_scheduler.sh remove
```

### Modo Silencioso

```bash
# Verificar atualizações sem interface interativa
./scripts/update_notifier.sh --silent
```

### Verificação Manual

```bash
# Verificar apenas conectividade
./scripts/update_checker.sh --connectivity

# Verificar apenas atualizações Git
./scripts/update_checker.sh --git-only
```

## 🛡️ Segurança e Rollback

### Funcionalidades de Segurança

- ✅ Verificação de conectividade antes das atualizações
- ✅ Verificação de espaço em disco disponível
- ✅ Verificação de containers críticos rodando
- ✅ Backup automático antes de atualizações
- ✅ Rollback automático em caso de falha
- ✅ Verificação de integridade após atualizações

### Processo de Rollback

1. **Detecção de Falha**: Sistema detecta falha na atualização
2. **Parada Automática**: Interrompe o processo de atualização
3. **Restauração de Backup**: Restaura backup pré-atualização
4. **Notificação**: Informa sobre o rollback
5. **Log Detalhado**: Registra todos os passos do rollback

## 📈 Exemplo de Uso Diário

### Configuração Inicial (uma vez)

```bash
# 1. Configurar agendamento
./scripts/maintenance/update_scheduler.sh setup

# 2. Iniciar monitoramento
./scripts/monitor_worker_updates.sh start

# 3. Verificar status
./scripts/maintenance/update_scheduler.sh status
```

### Uso Diário

```bash
# 1. Verificar se há atualizações
./scripts/update_checker.sh

# 2. Se houver atualizações, usar interface interativa
./scripts/update_notifier.sh

# 3. Ver logs se necessário
tail -f logs/update_checker.log
```

### Manutenção Semanal

```bash
# 1. Verificar integridade do sistema
./scripts/maintenance/update_scheduler.sh verify

# 2. Limpar backups antigos
./scripts/backup_manager.sh cleanup

# 3. Ver status geral
./scripts/maintenance/update_scheduler.sh status
```

## 🚨 Solução de Problemas

### Problema: Sistema não está verificando atualizações

```bash
# 1. Verificar se cron está rodando
./scripts/maintenance/update_scheduler.sh status

# 2. Verificar logs
tail -f logs/update_checker.log

# 3. Reiniciar agendamento
./scripts/maintenance/update_scheduler.sh restart
```

### Problema: Falha na atualização

```bash
# 1. Verificar logs detalhados
tail -f logs/auto_updater.log

# 2. Verificar conectividade
./scripts/update_checker.sh --connectivity

# 3. Tentar novamente com modo verboso
./scripts/maintenance/auto_updater.sh git --verbose
```

### Problema: Rollback não funcionou

```bash
# 1. Verificar se backup existe
./scripts/backup_manager.sh list

# 2. Restaurar backup manualmente
./scripts/backup_manager.sh restore <nome_do_backup>

# 3. Verificar logs de backup
tail -f logs/backup_manager.log
```

## 📝 Logs e Depuração

### Níveis de Log

- **DEBUG**: Informações detalhadas para depuração
- **INFO**: Informações gerais sobre operações
- **WARN**: Avisos sobre possíveis problemas
- **ERROR**: Erros que impedem o funcionamento

### Arquivos de Log Importantes

```bash
logs/update_checker.log     # Verificação de atualizações
logs/auto_updater.log       # Aplicação de atualizações
logs/monitor_updates.log    # Monitoramento contínuo
logs/backup_manager.log     # Operações de backup
logs/update_notifications.log # Notificações enviadas
```

## 🔄 Integração com Scripts Existentes

O sistema está preparado para integração com scripts existentes:

- `scripts/auto_init_project.sh` - Pode verificar atualizações no startup
- `scripts/lib/common.sh` - Pode usar funções do sistema de atualização
- Scripts de instalação podem usar o sistema de backup

## 📞 Suporte

Para problemas ou dúvidas:

1. Verifique os logs em `logs/`
2. Execute verificação de integridade: `./scripts/maintenance/update_scheduler.sh verify`
3. Consulte este README para comandos específicos
4. Verifique se todas as dependências estão instaladas

---

**Desenvolvido pela equipe Cluster AI** 🚀
**Versão: 1.0.0**
**Data: 2025-01-20**
