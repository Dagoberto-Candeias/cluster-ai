# 📋 TODO - Sistema de Auto Atualização

## ✅ PLANO APROVADO

### **FASE 1: Sistema de Verificação de Atualizações**
- [ ] Criar `scripts/update_checker.sh` - Verifica atualizações disponíveis
- [ ] Verificar atualizações do Git (repositório)
- [ ] Verificar atualizações de containers Docker
- [ ] Verificar atualizações do sistema operacional
- [ ] Verificar atualizações de modelos de IA

### **FASE 2: Sistema de Notificação e Interação**
- [ ] Criar `scripts/update_notifier.sh` - Sistema de notificação
- [ ] Interface interativa para aprovar atualizações
- [ ] Logs detalhados de todas as operações
- [ ] Notificações por email (opcional)

### **FASE 3: Sistema de Backup**
- [ ] Criar `scripts/backup_manager.sh` - Gerenciador de backups
- [ ] Backup automático antes de atualizações
- [ ] Sistema de rotação de backups
- [ ] Backup de configurações, dados e estado do sistema

### **FASE 4: Sistema de Atualização Principal**
- [ ] Completar `scripts/maintenance/auto_updater.sh`
- [ ] Suporte a diferentes tipos de atualização
- [ ] Verificação de dependências
- [ ] Rollback automático em caso de falha

### **FASE 5: Sistema de Monitoramento Contínuo**
- [ ] Completar `scripts/monitor_worker_updates.sh`
- [ ] Monitoramento em background
- [ ] Verificação periódica configurável
- [ ] Integração com cron

### **FASE 6: Configuração e Personalização**
- [ ] Criar `config/update.conf` - Configurações do sistema de atualização
- [ ] Opções de frequência de verificação
- [ ] Configurações de backup
- [ ] Lista de componentes a serem atualizados

### **FASE 7: Integração com Scripts Existentes**
- [ ] Integrar com `scripts/auto_init_project.sh`
- [ ] Adicionar verificação de atualizações no status do sistema
- [ ] Integração com scripts de instalação existentes

## 📁 ARQUIVOS A SEREM CRIADOS/MODIFICADOS

### **Novos Arquivos:**
- [ ] `scripts/update_checker.sh`
- [ ] `scripts/update_notifier.sh`
- [ ] `scripts/backup_manager.sh`
- [ ] `config/update.conf`
- [ ] `scripts/maintenance/update_scheduler.sh`

### **Arquivos a Completar:**
- [ ] `scripts/maintenance/auto_updater.sh`
- [ ] `scripts/monitor_worker_updates.sh`

### **Arquivos a Modificar:**
- [ ] `scripts/auto_init_project.sh` (adicionar verificação de atualizações)
- [ ] `scripts/lib/common.sh` (adicionar funções específicas para updates)

## 🔧 DEPENDÊNCIAS
- [ ] Git para atualizações do repositório
- [ ] Docker para containers
- [ ] Ferramentas do sistema (apt, dnf, etc.)
- [ ] Cron para agendamento

## ✅ PROGRESSO ATUAL
- [x] Análise completa do sistema atual
- [x] Plano detalhado criado e aprovado
- [ ] Implementação iniciada
