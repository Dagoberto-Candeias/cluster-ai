# Guia de Solução de Problemas - Cluster AI

## Visão Geral

Este guia ajuda a diagnosticar e resolver problemas comuns no Cluster AI. Siga os passos em ordem para identificar e corrigir issues.

## Diagnóstico Inicial

### 1. Verificar Status dos Serviços
```bash
# Verificar serviços principais
./manager.sh status

# Ou verificar manualmente
ps aux | grep -E "(dask|ollama|open-webui)"
```

**Serviços esperados:**
- `dask-scheduler` (porta 8786)
- `ollama serve` (porta 11434)
- `open-webui` (porta 3000)

### 2. Verificar Logs de Erro
```bash
# Logs principais
tail -50 logs/audit.log
tail -50 logs/security_events.log

# Logs de sistema
tail -20 logs/system/$(ls logs/system/ | tail -1)
```

### 3. Verificar Recursos do Sistema
```bash
# Uso de CPU/Memória
htop  # ou top

# Espaço em disco
df -h

# Conectividade de rede
ping -c 3 google.com
```

## Problemas Comuns e Soluções

### 🔴 Sistema Não Inicia

#### Sintomas
- Comando `./start_cluster.sh` falha
- Serviços não sobem
- Erro de permissões

#### Soluções

1. **Verificar permissões dos scripts:**
```bash
find scripts/ -name "*.sh" -exec ls -la {} \;
# Corrigir permissões se necessário
chmod +x scripts/**/*.sh
```

2. **Verificar dependências:**
```bash
python3 -c "import dask, numpy, pandas"
echo "Python dependencies: OK"
```

3. **Limpar processos antigos:**
```bash
pkill -f dask
pkill -f ollama
pkill -f open-webui
```

4. **Verificar portas ocupadas:**
```bash
netstat -tlnp | grep -E "(8786|11434|3000)"
# Liberar portas se necessário
```

### 🟡 Workers Não Conectam

#### Sintomas
- Workers aparecem como "inactive"
- Erro de conexão no dashboard
- Dask scheduler não reconhece workers

#### Soluções

1. **Verificar conectividade:**
```bash
# No worker
telnet localhost 8786  # Dask scheduler

# Verificar firewall
sudo ufw status
sudo ufw allow 8786
```

2. **Reiniciar workers:**
```bash
# Parar workers existentes
pkill -f "dask-worker"

# Reiniciar via manager
./manager.sh
# Selecionar: 2. Gerenciar Workers → 3. Reiniciar Workers
```

3. **Verificar configuração:**
```bash
cat config/cluster.conf
# Verificar scheduler_address
```

### 🟠 Modelos IA Não Carregam

#### Sintomas
- Ollama não responde
- Modelos não listam
- Erro ao fazer chat

#### Soluções

1. **Verificar serviço Ollama:**
```bash
ps aux | grep ollama
# Se não estiver rodando
ollama serve &
```

2. **Listar modelos disponíveis:**
```bash
ollama list
# Se vazio, baixar modelo
ollama pull llama3:8b
```

3. **Verificar espaço em disco:**
```bash
df -h ~/.ollama
# Modelos precisam de ~4-8GB cada
```

4. **Reiniciar OpenWebUI:**
```bash
pkill -f open-webui
# Reiniciar via manager ou diretamente
```

### 🔵 Performance Lenta

#### Sintomas
- Respostas lentas
- Alto uso de CPU/Memória
- Workers sobrecarregados

#### Soluções

1. **Verificar recursos:**
```bash
# CPU
htop

# Memória
free -h

# Disco I/O
iotop
```

2. **Otimizar workers:**
```bash
# Ajustar threads por worker
# Editar config/cluster.conf
nthreads: 2  # Reduzir se CPU alta
```

3. **Limpar cache:**
```bash
# Limpar cache do sistema
sync; echo 3 > /proc/sys/vm/drop_caches

# Limpar cache do Ollama
ollama list
# Remover modelos não usados
```

4. **Verificar rede:**
```bash
# Latência
ping -c 5 localhost

# Bandwidth
iperf3 -c localhost
```

### 🟢 Problemas de Autenticação

#### Sintomas
- Não consegue fazer login
- Token expira rapidamente
- Erro 401 Unauthorized

#### Soluções

1. **Verificar credenciais:**
```bash
# Credenciais padrão
Username: admin
Password: admin123
```

2. **Verificar token JWT:**
```bash
# Decodificar token (usar jwt.io)
# Verificar expiração
```

3. **Reiniciar API:**
```bash
pkill -f "uvicorn main"
cd web-dashboard/backend
python main_fixed.py &
```

### 🟣 Problemas de Android Workers

#### Sintomas
- Workers Android não conectam
- Erro de SSH
- Termux não responde

#### Soluções

1. **Verificar Termux:**
```bash
# No Android/Termux
pkg update && pkg upgrade
pkg install openssh python
```

2. **Configurar SSH:**
```bash
# Gerar chave SSH
ssh-keygen -t rsa -b 4096

# Copiar chave para servidor
ssh-copy-id user@server-ip
```

3. **Executar worker:**
```bash
# No Termux
bash scripts/android/setup_android_worker.sh
```

4. **Verificar conectividade:**
```bash
# Testar SSH
ssh user@server-ip

# Verificar portas
telnet server-ip 8786
```

## Ferramentas de Diagnóstico

### Health Check Avançado
```bash
./scripts/health_check_enhanced_fixed.sh
```

### Análise de Logs
```bash
./scripts/log_analyzer.sh alerts
./scripts/log_analyzer.sh performance
./scripts/log_analyzer.sh errors
```

### Monitor em Tempo Real
```bash
./scripts/monitoring/advanced_dashboard.sh live
```

### Teste de Conectividade
```bash
./test_dask_client.py
./test_import_personas.sh
```

## Prevenção de Problemas

### Manutenção Regular
```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade

# Limpar logs antigos
find logs/ -name "*.log" -mtime +30 -delete

# Verificar integridade
./scripts/health_check_enhanced_fixed.sh
```

### Backup Regular
```bash
./scripts/backup_manager.sh create
```

### Monitoramento Contínuo
```bash
# Configurar alertas
./scripts/monitoring/setup_alerts.sh

# Dashboard em tempo real
./scripts/monitoring/advanced_dashboard.sh continuous 10
```

## Contato e Suporte

### Recursos de Ajuda
- **Documentação**: `docs/`
- **Logs Detalhados**: `logs/`
- **Scripts de Diagnóstico**: `scripts/health_check_enhanced_fixed.sh`
- **Comunidade**: GitHub Issues

### Quando Pedir Ajuda
- Problemas persistentes após seguir este guia
- Erros não documentados
- Problemas de segurança
- Issues de performance crítica

### Informações para Suporte
Ao reportar problemas, inclua:
- Saída de `./manager.sh status`
- Logs relevantes: `tail -50 logs/audit.log`
- Sistema: `uname -a`, `lsb_release -a`
- Recursos: `free -h`, `df -h`

## Resolução de Emergência

### Reset Completo do Sistema
⚠️ **Use apenas em último caso**
```bash
# Parar tudo
./stop_cluster.sh

# Limpar processos
pkill -9 -f "dask\|ollama\|open-webui"

# Limpar caches
rm -rf ~/.cache/dask/*
rm -rf ~/.ollama/cache/*

# Reiniciar
./start_cluster.sh
```

### Recovery Mode
```bash
# Modo de recuperação
export RECOVERY_MODE=1
./start_cluster.sh
```

---

**Última atualização:** Janeiro 2025
**Versão:** 1.0.2
