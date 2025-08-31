# 💾 Manual de Backup e Restauração - Cluster AI

## 🎯 Visão Geral

Este manual descreve o sistema de backup e restauração do Cluster AI, gerenciado através do `manager.sh`. O sistema foi projetado para ser robusto, cobrindo tanto o servidor principal quanto os workers remotos.

## 🚀 Gerenciamento de Backups via `manager.sh`

Todas as operações de backup e restauração são centralizadas no painel de controle.

```bash
# Inicie o painel de controle
./manager.sh
```

### Itens Incluídos no Backup
- ✅ Modelos Ollama (`~/.ollama`)
- ✅ Configurações do cluster (`~/.cluster_role`)
- ✅ Dados do OpenWebUI (`~/open-webui`)
- ✅ Scripts de gerenciamento (`~/cluster_scripts`)
- ✅ Configurações SSH (`~/.ssh`)
- ✅ Ambiente Python (`~/cluster_env`)
- ✅ Configurações de email (`~/.msmtprc`, `~/.gmail_pass.gpg`)

## 📁 Estrutura de Backups

### Localização Padrão
```bash
# Diretório padrão de backups
~/cluster_backups/

# Estrutura de arquivos
cluster_backups/
├── cluster_backup_20241215_143022.tar.gz
├── ollama_models_20241215_143045.tar.gz
├── cluster_config_20241215_143102.tar.gz
└── openwebui_data_20241215_143115.tar.gz
```

### Formatos de Backup
- **Completo**: Todos os componentes do cluster
- **Modelos**: Apenas modelos Ollama
- **Configuração**: Apenas configurações
- **OpenWebUI**: Apenas dados da interface web

## 🔧 Backup Manual

### Backup Completo
```bash
# Usando o script principal
./scripts/installation/main.sh --backup

# Ou manualmente com tar
tar -czf cluster_backup_$(date +%Y%m%d_%H%M%S).tar.gz \
  ~/.ollama \
  ~/.cluster_role \
  ~/open-webui \
  ~/cluster_scripts \
  ~/.ssh \
  ~/cluster_env \
  ~/.msmtprc \
  ~/.gmail_pass.gpg
```

### Backup de Modelos Ollama
```bash
# Backup apenas dos modelos
tar -czf ollama_models_$(date +%Y%m%d_%H%M%S).tar.gz -C ~ .ollama
```

### Backup de Configurações
```bash
# Backup das configurações do cluster
tar -czf cluster_config_$(date +%Y%m%d_%H%M%S).tar.gz \
  ~/.cluster_role \
  ~/cluster_scripts \
  ~/.ssh \
  ~/.msmtprc \
  ~/.gmail_pass.gpg
```

## 🔄 Restauração

### Restauração Interativa
```bash
# Listar backups disponíveis
ls -la ~/cluster_backups/

# Restaurar backup interativo
./install_cluster.sh --restore
```

### Restauração Manual
```bash
# Extrair backup completo
tar -xzf cluster_backup_20241215_143022.tar.gz -C ~

# Ou extrair componentes específicos
tar -xzf ollama_models_20241215_143045.tar.gz -C ~
tar -xzf cluster_config_20241215_143102.tar.gz -C ~
```

### Pós-Restauração
Após restaurar um backup, reinicie os serviços:

```bash
# Reiniciar serviços
./install_cluster.sh --restart

# Ou manualmente
pkill -f "dask-scheduler"
pkill -f "dask-worker" 
pkill -f "ollama"
sudo systemctl restart ollama
./scripts/installation/main.sh
```

## ⏰ Agendamento Automático

### Agendamento com Cron
```bash
# Agendar backup diário às 2:00 AM
./install_cluster.sh --schedule

# Ou manualmente no crontab
crontab -e
```

### Exemplos de Agendamento
```bash
# Diário às 2:00 AM
0 2 * * * /caminho/para/install_cluster.sh --backup --auto

# Semanal aos domingos às 2:00 AM  
0 2 * * 0 /caminho/para/install_cluster.sh --backup --auto

# Mensal no primeiro dia às 2:00 AM
0 2 1 * * /caminho/para/install_cluster.sh --backup --auto
```

### Verificar Agendamentos
```bash
# Listar agendamentos ativos
crontab -l

# Verificar logs de execução
tail -f /var/log/syslog | grep backup
```

## 💾 Estratégias de Backup

### Backup Local
```bash
# Para disco externo
rsync -av ~/cluster_backups/ /media/external-drive/backups/

# Para outro diretório
cp ~/cluster_backups/* /mnt/backup-server/
```

### Backup Remoto (SSH/SCP)
```bash
# Copiar para servidor remoto
scp ~/cluster_backups/* user@backup-server:/backups/cluster-ai/

# Usando rsync sobre SSH
rsync -av -e ssh ~/cluster_backups/ user@backup-server:/backups/cluster-ai/
```

### Backup em Nuvem
```bash
# AWS S3 (instalar aws-cli primeiro)
aws s3 sync ~/cluster_backups/ s3://meu-bucket/cluster-backups/

# Google Cloud Storage
gsutil cp ~/cluster_backups/* gs://meu-bucket/cluster-backups/

# Azure Blob Storage
az storage blob upload-batch --source ~/cluster_backups/ --destination container-name
```

## 🛡️ Políticas de Retenção

### Exemplo de Política
```bash
# Manter backups dos últimos 7 dias
find ~/cluster_backups/ -name "*.tar.gz" -mtime +7 -delete

# Manter backups semanais por 1 mês
find ~/cluster_backups/ -name "*.tar.gz" -mtime +30 -delete

# Manter backups mensais por 1 ano
find ~/cluster_backups/ -name "*.tar.gz" -mtime +365 -delete
```

### Script de Limpeza Automática
```bash
#!/bin/bash
# cleanup_old_backups.sh

BACKUP_DIR=~/cluster_backups

# Manter últimos 7 dias
find "$BACKUP_DIR" -name "cluster_backup_*.tar.gz" -mtime +7 -delete

# Manter últimos 30 dias para modelos
find "$BACKUP_DIR" -name "ollama_models_*.tar.gz" -mtime +30 -delete

# Manter últimos 90 dias para configurações
find "$BACKUP_DIR" -name "cluster_config_*.tar.gz" -mtime +90 -delete
```

## 🚨 Recuperação de Desastres

### Cenário: Perda Completa do Sistema
1. **Instalar sistema operacional**
2. **Instalar Cluster AI**: `./install_cluster.sh`
3. **Restaurar backup mais recente**
4. **Reconfigurar serviços**

### Script de Recuperação
```bash
#!/bin/bash
# disaster_recovery.sh

echo "=== RECUPERAÇÃO DE DESASTRES CLUSTER AI ==="

# Verificar se há backups
if [ ! -d ~/cluster_backups ]; then
    echo "❌ Nenhum backup encontrado!"
    exit 1
fi

# Encontrar backup mais recente
LATEST_BACKUP=$(ls -t ~/cluster_backups/cluster_backup_*.tar.gz | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "❌ Nenhum backup completo encontrado!"
    exit 1
fi

echo "📦 Restaurando backup: $LATEST_BACKUP"

# Extrair backup
tar -xzf "$LATEST_BACKUP" -C ~

echo "✅ Backup restaurado!"
echo "🔄 Reiniciando serviços..."

# Reiniciar serviços
pkill -f "dask-scheduler" || true
pkill -f "dask-worker" || true
pkill -f "ollama" || true

sleep 2

# Iniciar serviços baseado na configuração
if [ -f ~/.cluster_role ]; then
    source ~/.cluster_role
    ./scripts/installation/main.sh --role "$ROLE"
else
    ./scripts/installation/main.sh
fi

echo "🎉 Recuperação concluída!"
```

## 📊 Monitoramento de Backups

### Verificação de Integridade
```bash
# Verificar checksum dos backups
md5sum ~/cluster_backups/*.tar.gz > backup_checksums.txt

# Verificar integridade
tar -tzf backup_file.tar.gz > /dev/null && echo "✅ Backup íntegro" || echo "❌ Backup corrompido"
```

### Logs de Backup
```bash
# Verificar logs do sistema
journalctl -u cron | grep backup

# Logs específicos do script
tail -f ~/cluster_backups/backup.log
```

### Alertas e Notificações
```bash
# Enviar email em caso de falha
if [ $? -ne 0 ]; then
    echo "Backup falhou!" | mail -s "ALERTA: Backup Cluster AI Falhou" admin@example.com
fi

# Notificação via Slack/Telegram (usando curl)
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Backup do Cluster AI concluído com sucesso!"}' \
  https://hooks.slack.com/services/TOKEN
```

## 🔄 Migração entre Máquinas

### Migração Completa
1. **Backup na máquina origem**
2. **Transferir arquivos de backup**
3. **Restaurar na máquina destino**
4. **Reconfigurar endereços IP**

### Script de Migração
```bash
#!/bin/bash
# migrate_cluster.sh

SOURCE_HOST="maquina-origem"
DEST_HOST="maquina-destino"
BACKUP_FILE="cluster_backup_$(date +%Y%m%d_%H%M%S).tar.gz"

echo "=== MIGRAÇÃO DE CLUSTER AI ==="

# Backup na origem
echo "📦 Criando backup na origem..."
ssh "$SOURCE_HOST" "./install_cluster.sh --backup --auto"

# Transferir backup
echo "📤 Transferindo backup..."
scp "$SOURCE_HOST:~/cluster_backups/latest.tar.gz" "$BACKUP_FILE"

# Restaurar no destino
echo "📥 Restaurando no destino..."
scp "$BACKUP_FILE" "$DEST_HOST:~/"
ssh "$DEST_HOST" "tar -xzf $BACKUP_FILE -C ~ && ./install_cluster.sh --restart"

echo "✅ Migração concluída!"
```

## 🛠️ Solução de Problemas

### Problemas Comuns

#### ❌ Erro de Permissão
```bash
# Corrigir permissões
sudo chown -R $USER:$USER ~/cluster_backups/
sudo chmod -R 755 ~/cluster_backups/
```

#### ❌ Espaço em Disco Insuficiente
```bash
# Verificar espaço livre
df -h ~/

# Limpar backups antigos
find ~/cluster_backups/ -name "*.tar.gz" -mtime +30 -delete
```

#### ❌ Backup Muito Lento
```bash
# Excluir cache desnecessário
tar --exclude='.ollama/models/*/tmp' --exclude='.ollama/models/*/cache' \
  -czf backup.tar.gz ~/.ollama
```

#### ❌ Restauração Falha
```bash
# Verificar integridade do backup
tar -tzf backup_file.tar.gz > /dev/null || echo "Backup corrompido"

# Tentar extrair parcialmente
tar -xzf backup_file.tar.gz ~/.cluster_role ~/cluster_scripts
```

### Logs de Depuração
```bash
# Executar com debug
bash -x ./scripts/installation/main.sh --backup

# Log detalhado
./install_cluster.sh --backup 2>&1 | tee backup.log
```

## 📈 Melhores Práticas

### 1. Backup Regular
- ✅ Diário para configurações
- ✅ Semanal para modelos
- ✅ Mensal completo

### 2. Verificação de Integridade
- ✅ Checksum dos arquivos
- ✅ Teste de restauração periódico
- ✅ Monitoramento de logs

### 3. Armazenamento Seguro
- ✅ Local + Remoto (3-2-1 rule)
- ✅ Criptografia para dados sensíveis
- ✅ Acesso restrito

### 4. Documentação
- ✅ Procedimentos documentados
- ✅ Contatos de emergência
- ✅ Roteiro de recuperação

### 5. Testes Regulares
- ✅ Teste de restauração trimestral
- ✅ Simulação de desastre
- ✅ Atualização de procedimentos

## 🎯 Checklist de Backup

### Pré-Backup
- [ ] Verificar espaço em disco
- [ ] Confirmar serviços em execução
- [ ] Fechar aplicações críticas

### Durante Backup
- [ ] Monitorar progresso
- [ ] Verificar logs
- [ ] Confirmar checksum

### Pós-Backup
- [ ] Verificar integridade
- [ ] Copiar para local remoto
- [ ] Atualizar documentação
- [ ] Limpar backups antigos

---

**💡 Dica Importante**: Execute backups regularmente e teste periodicamente o processo de restauração para garantir que seus dados estarão seguros em caso de necessidade.

**🚨 Lembrete**: Backups só são úteis se forem testados regularmente. Agende testes de restauração a cada 3 meses.
