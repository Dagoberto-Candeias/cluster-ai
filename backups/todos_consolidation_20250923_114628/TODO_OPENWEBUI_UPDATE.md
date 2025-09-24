# 📋 TODO - Atualização OpenWebUI v0.6.30

## ✅ PLANO DE ATUALIZAÇÃO APROVADO

### **FASE 1: Backup dos Dados Atuais**
- [x] Fazer backup do volume de dados do OpenWebUI
- [x] Exportar configurações e personas personalizadas
- [x] Salvar logs de configuração atual

### **FASE 2: Análise de Mudanças na Nova Versão**
- [x] Verificar changelog da v0.6.30
- [x] Identificar breaking changes
- [x] Verificar compatibilidade com Ollama

### **FASE 3: Atualização dos Arquivos de Configuração**
- [x] `configs/docker/compose-basic.yml` - Atualizar imagem para v0.6.30
- [x] `config/cluster.conf.example` - Atualizar referência da imagem
- [x] `scripts/installation/setup_openwebui.sh` - Revisar script de instalação

### **FASE 4: Testes de Compatibilidade**
- [ ] Testar integração com Ollama
- [ ] Verificar funcionamento das personas
- [ ] Testar funcionalidades principais

### **FASE 5: Rollback Plan**
- [ ] Preparar script de rollback
- [ ] Documentar processo de reversão

## 📁 BACKUPS CRIADOS
- Data: $(date)
- Local: ${PROJECT_ROOT}/backups/openwebui_backup_$(date +%Y%m%d_%H%M%S).tar.gz

## 🔧 ARQUIVOS A SEREM MODIFICADOS
1. `configs/docker/compose-basic.yml`
2. `config/cluster.conf.example`
3. `scripts/installation/setup_openwebui.sh`

## ⚠️ PONTOS DE ATENÇÃO
- Verificar se há containers rodando antes da atualização
- Testar conectividade com Ollama após atualização
- Verificar se as personas personalizadas ainda funcionam
