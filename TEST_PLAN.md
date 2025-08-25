# 🧪 Plano de Teste Completo - Cluster AI

## 🎯 Objetivo
Testar todas as funcionalidades do Cluster AI de forma abrangente, desde a instalação até o uso avançado.

## 📋 Fases de Teste

### Fase 1: Teste de Instalação Básica
- [ ] Instalar dependências do sistema
- [ ] Executar script principal de instalação
- [ ] Verificar criação de ambiente virtual
- [ ] Validar instalação do Docker
- [ ] Testar instalação do Ollama

### Fase 2: Teste de Configuração do Cluster
- [ ] Configurar máquina como servidor principal
- [ ] Configurar máquina como estação de trabalho  
- [ ] Configurar máquina apenas como worker
- [ ] Testar conversão entre papéis
- [ ] Validar configuração de firewall

### Fase 3: Teste de Modelos Ollama
- [ ] Verificar sistema de detecção de modelos
- [ ] Instalar modelos recomendados
- [ ] Testar modelos personalizados
- [ ] Validar integração Ollama + OpenWebUI
- [ ] Testar API do Ollama

### Fase 4: Teste do OpenWebUI
- [ ] Instalar e configurar OpenWebUI
- [ ] Testar interface web
- [ ] Validar autenticação e usuários
- [ ] Testar chat com modelos
- [ ] Verificar monitoramento

### Fase 5: Teste do Cluster Dask
- [ ] Iniciar scheduler Dask
- [ ] Conectar workers ao cluster
- [ ] Testar processamento distribuído
- [ ] Validar dashboard de monitoramento
- [ ] Testar resiliência do cluster

### Fase 6: Teste de Backup e Restauração
- [ ] Executar backup completo
- [ ] Testar backup incremental
- [ ] Validar restauração de backup
- [ ] Testar agendamento automático
- [ ] Verificar integridade dos backups

### Fase 7: Teste de Produção (TLS)
- [ ] Configurar TLS/SSL
- [ ] Testar certificados Let's Encrypt
- [ ] Validar configuração Nginx
- [ ] Testar acesso HTTPS
- [ ] Verificar segurança

### Fase 8: Teste de Performance
- [ ] Testar com múltiplos workers
- [ ] Validar uso de GPU (se disponível)
- [ ] Medir tempo de resposta
- [ ] Testar com modelos grandes
- [ ] Verificar consumo de recursos

### Fase 9: Teste de Recuperação de Erros
- [ ] Simular falhas de serviços
- [ ] Testar reinicialização automática
- [ ] Validar mensagens de erro
- [ ] Testar recuperação de dados
- [ ] Verificar logs de diagnóstico

### Fase 10: Teste de Documentação
- [ ] Validar todos os manuais
- [ ] Testar exemplos de código
- [ ] Verificar links e referências
- [ ] Testar guias de troubleshooting
- [ ] Validar procedimentos de emergência

## 🔧 Ferramentas de Teste

### Scripts de Validação
```bash
# Validação básica
./scripts/validation/validate_installation.sh

# Verificação de modelos
./scripts/utils/check_models.sh

# Teste de conectividade
./scripts/deployment/cluster-nodes.sh
```

### Comandos Manuais
```bash
# Testar Ollama
curl http://localhost:11434/api/tags

# Testar Dask
python -c "from dask.distributed import Client; c = Client('localhost:8786'); print(c)"

# Testar OpenWebUI
curl http://localhost:8080/api/health

# Testar rede
ping entre-máquinas
nc -zv IP porta
```

### Monitoramento
```bash
# Recursos do sistema
htop, glances, atop

# Logs de serviços
journalctl -u ollama -f
docker logs open-webui -f

# Rede
netstat -tlnp
ss -tlnp
```

## 🚀 Procedimento de Teste Passo a Passo

### Passo 1: Preparação do Ambiente
```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências básicas
sudo apt install -y curl net-tools python3-pip
```

### Passo 2: Instalação Principal
```bash
# Executar instalação completa
./install_cluster.sh

# Ou executar script principal diretamente  
./scripts/installation/main.sh
```

### Passo 3: Configuração do Papel
```bash
# Configurar como servidor principal
# (Seguir menu interativo)

# Ou configurar papel específico
./scripts/installation/main.sh --role server
```

### Passo 4: Instalação de Modelos
```bash
# Verificar e instalar modelos
./scripts/utils/check_models.sh

# Instalar modelo específico
ollama pull llama3
```

### Passo 5: Teste de Serviços
```bash
# Verificar se todos os serviços estão rodando
./scripts/validation/validate_installation.sh

# Testar conectividade individual
curl http://localhost:11434/api/tags       # Ollama
curl http://localhost:8787/status          # Dask Dashboard
curl http://localhost:8080/api/health      # OpenWebUI
```

### Passo 6: Teste de Integração
```bash
# Testar exemplo de integração
python examples/integration/ollama_integration.py

# Testar processamento distribuído
python examples/basic/basic_usage.py
```

### Passo 7: Teste de Backup
```bash
# Executar backup completo
./install_cluster.sh --backup

# Verificar backups criados
ls -la ~/cluster_backups/

# Testar restauração
./install_cluster.sh --restore
```

### Passo 8: Teste de Produção
```bash
# Configurar TLS
cd configs/tls/
./issue-certs-robust.sh exemplo.com email@exemplo.com

# Configurar Nginx com TLS
cd ../nginx/
# Configurar nginx-tls.conf

# Testar HTTPS
curl -k https://localhost:443
```

## 📊 Critérios de Aceitação

### ✅ Instalação
- [ ] Script executa sem erros
- [ ] Todas as dependências instaladas
- [ ] Ambiente virtual criado
- [ ] Serviços configurados corretamente

### ✅ Funcionalidade
- [ ] Ollama responde na porta 11434
- [ ] Dask scheduler roda na porta 8786
- [ ] Dashboard acessível na porta 8787
- [ ] OpenWebUI funciona na porta 8080
- [ ] Modelos podem ser instalados e usados

### ✅ Integração
- [ ] Workers conectam ao scheduler
- [ ] OpenWebUI conversa com Ollama
- [ ] Exemplos de código funcionam
- [ ] Processamento distribuído opera

### ✅ Backup
- [ ] Backups são criados corretamente
- [ ] Restauração funciona sem perda de dados
- [ ] Agendamento automático opera
- [ ] Integridade dos backups verificada

### ✅ Segurança
- [ ] Firewall configurado corretamente
- [ ] TLS/SSL funciona em produção
- [ ] Acesso restrito apropriadamente
- [ ] Logs de segurança gerados

### ✅ Performance
- [ ] Sistema responde em tempo aceitável
- [ ] Recursos utilizados adequadamente
- [ ] Escala com múltiplos workers
- [ ] Suporta carga esperada

## 🐛 Procedimento de Bug Reporting

### Template de Bug Report
```
## Descrição do Problema

## Passos para Reproduzir
1. 
2. 
3. 

## Comportamento Esperado

## Comportamento Atual

## Logs Relevantes
```

### Coleta de Logs
```bash
# Script de coleta automática
#!/bin/bash
echo "=== LOGS PARA BUG REPORT ===" > bug_report.txt
uname -a >> bug_report.txt
./scripts/validation/validate_installation.sh >> bug_report.txt
docker logs open-webui 2>&1 | tail -50 >> bug_report.txt
journalctl -u ollama --since "1 hour ago" >> bug_report.txt
```

## 📈 Métricas de Sucesso

### Taxa de Sucesso da Instalação
- ✅ 95% das instalações devem completar sem erro
- ✅ 100% das dependências críticas instaladas
- ✅ Configuração automática funcional

### Tempo de Instalação
- ⏱️ Instalação completa em < 30 minutos
- ⏱️ Primeiro modelo funcionando em < 45 minutos
- ⏱️ Cluster operacional em < 1 hora

### Disponibilidade de Serviços
- 📊 Ollama: 99.9% uptime
- 📊 Dask: 99.9% uptime  
- 📊 OpenWebUI: 99.9% uptime
- 📊 Backup: 100% confiabilidade

## 🚨 Cenários de Teste de Estresse

### Carga Pesada
```bash
# Testar com múltiplos workers simultâneos
for i in {1..10}; do
  ./scripts/installation/main.sh --role worker &
done

# Testar com modelos grandes
ollama pull llama3:70b
```

### Falhas Simuladas
```bash
# Simular falha de rede
sudo iptables -A INPUT -p tcp --dport 8786 -j DROP

# Simular falha de serviço
sudo systemctl stop ollama

# Simular falta de disco
dd if=/dev/zero of=/tmp/fill.disk bs=1M count=10240
```

### Recuperação
```bash
# Testar reinicialização automática
pkill -f "dask-scheduler"
# Verificar se reinicia automaticamente

# Testar restauração de backup após falha
rm -rf ~/.ollama
./install_cluster.sh --restore
```

---

**📅 Início dos Testes**: $(date +%Y-%m-%d)
**👥 Responsável**: Equipe de QA
**📊 Método**: Teste manual e automatizado
**🎯 Objetivo**: Certificação para produção
