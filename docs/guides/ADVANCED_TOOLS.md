# 🛠️ Ferramentas Avançadas - Cluster AI

Este documento descreve as ferramentas avançadas disponíveis no Cluster AI que não estão documentadas na documentação principal.

## 📊 Sistema de Monitoramento Central

### Localização
`scripts/monitoring/central_monitor.sh`

### Funcionalidades
- **Dashboard em tempo real** com métricas de sistema
- **Coleta automática** de CPU, memória, disco, rede
- **Monitoramento de cluster Dask** com métricas avançadas
- **Sistema de alertas inteligente** com thresholds configuráveis
- **Relatórios automáticos** de performance
- **Monitoramento de workers Android** (simulado)

### Como usar

```bash
# Via manager
./manager.sh monitor dashboard    # Dashboard interativo
./manager.sh monitor monitor      # Monitoramento contínuo
./manager.sh monitor alerts       # Ver alertas
./manager.sh monitor report       # Gerar relatório

# Diretamente
./scripts/monitoring/central_monitor.sh dashboard
```

### Métricas Coletadas
- **Sistema**: CPU, memória, disco, rede
- **Cluster**: Status Ollama, Dask, WebUI, workers
- **Android**: Bateria, CPU, memória, latência

## ⚡ Otimizador de Performance

### Localização
`scripts/optimization/performance_optimizer.sh`

### Funcionalidades
- **Otimização de scripts bash** com paralelização
- **Configuração de cache** de pacotes do sistema
- **Otimização de configurações** do kernel Linux
- **Configuração Docker** para melhor performance
- **Otimização Python/pip** com mirrors
- **Benchmark de performance** automatizado
- **Relatórios detalhados** de otimização

### Como usar

```bash
# Via manager
./manager.sh optimize

# Diretamente
./scripts/optimization/performance_optimizer.sh
```

### Otimizações Aplicadas
- **Scripts**: Timeout, paralelização, tratamento de erros
- **Sistema**: Limites de arquivos, swappiness, sysctl
- **Docker**: Logging, storage driver, ulimits
- **Python**: Cache, mirrors, retries

## 💻 Gerenciador VSCode

### Localização
`scripts/maintenance/vscode_manager.sh`

### Funcionalidades
- **Gerenciamento completo** de performance do VSCode
- **Auto-recuperação automática** com monitoramento
- **Otimização de configurações** e cache
- **Monitoramento de recursos** em tempo real
- **Sistema de backup** e recuperação
- **Interface unificada** para todas as funções VSCode

### Como usar

```bash
# Via manager
./manager.sh vscode status      # Status completo
./manager.sh vscode optimize    # Otimização completa
./manager.sh vscode start       # Iniciar otimizado
./manager.sh vscode recovery start  # Auto-recuperação
./manager.sh vscode monitor check   # Verificar performance

# Diretamente
./scripts/maintenance/vscode_manager.sh status
```

### Recursos Gerenciados
- **Performance**: CPU, memória, arquivos abertos
- **Auto-recuperação**: PID monitoring, restart automático
- **Otimização**: Cache, configurações, extensions
- **Monitoramento**: Métricas em tempo real

## 🔄 Sistema de Atualização Automática

### Localização
`scripts/maintenance/auto_updater.sh`

### Funcionalidades
- **Atualização automática** do projeto via Git
- **Backup automático** de alterações locais (stash)
- **Reinstalação automática** de dependências Python
- **Verificação de conflitos** e resolução
- **Rollback automático** em caso de problemas
- **Avisos de atualização** para scripts importantes

### Como usar

```bash
# Via manager
./manager.sh update

# Diretamente
./scripts/maintenance/auto_updater.sh
```

### Processo de Atualização
1. **Verificação**: Git status e conflitos
2. **Backup**: Stash de alterações locais
3. **Download**: Git pull com rebase
4. **Instalação**: Dependências Python se necessário
5. **Restauração**: Pop do stash
6. **Verificação**: Funcionamento correto

## 🔒 Ferramentas de Segurança

### Localização
`scripts/security/`

### Scripts Disponíveis

#### 1. Gerenciador de Autenticação
`scripts/security/auth_manager.sh`
- Gerenciamento de usuários e permissões
- Configuração SSH
- Autenticação de dois fatores

#### 2. Gerenciador de Firewall
`scripts/security/firewall_manager.sh`
- Regras de firewall UFW/iptables
- Configuração de portas
- Bloqueio de IPs suspeitos

#### 3. Logger de Segurança
`scripts/security/security_logger.sh`
- Log de acessos e tentativas
- Monitoramento de segurança
- Alertas de intrusão

### Como usar

```bash
# Via manager
./manager.sh security

# Diretamente
./scripts/security/auth_manager.sh
./scripts/security/firewall_manager.sh
./scripts/security/security_logger.sh
```

## 🤖 Scripts Android Avançados

### Localização
`scripts/android/`

### Scripts Importantes

#### 1. Worker Avançado
`scripts/android/advanced_worker.sh`
- Funcionalidades avançadas para workers Android
- Gerenciamento de bateria inteligente
- Otimização de performance móvel

#### 2. Configuração de Servidor
`scripts/android/configure_android_worker_server.sh`
- Configuração avançada de servidor para workers
- Balanceamento de carga
- Gerenciamento de conexões

#### 3. Testes Específicos
`scripts/android/test_android_worker.sh`
- Testes específicos para Android
- Validação de conectividade
- Performance móvel

#### 4. Autenticação GitHub
`scripts/android/setup_github_auth.sh`
- Configuração de autenticação GitHub
- SSH keys para Android
- Integração com repositório

### Como usar

```bash
# Workers avançados
./scripts/android/advanced_worker.sh

# Configuração servidor
./scripts/android/configure_android_worker_server.sh

# Testes
./scripts/android/test_android_worker.sh

# GitHub auth
./scripts/android/setup_github_auth.sh
```

## 📈 Scripts de Desenvolvimento

### Localização
`scripts/development/`

### Funcionalidades
- **Setup de ambientes** de desenvolvimento
- **Configuração PyCharm**, Spyder, VSCode
- **Lista de extensões** recomendadas
- **Templates de projeto** Python

### Scripts Disponíveis
- `setup_dev_environment.sh` - Ambiente completo
- `setup_pycharm.sh` - Configuração PyCharm
- `setup_spyder.sh` - Configuração Spyder
- `setup_vscode.sh` - Configuração VSCode
- `vscode_extensions.list` - Lista de extensões

## 🔧 Scripts de Manutenção

### Localização
`scripts/maintenance/`

### Scripts Importantes

#### 1. Auto Updater
`scripts/maintenance/auto_updater.sh`
- Atualização automática (já descrito acima)

#### 2. VSCode Manager
`scripts/maintenance/vscode_manager.sh`
- Gerenciamento VSCode (já descrito acima)

#### 3. Backup Manager
`scripts/maintenance/backup_manager.sh`
- Sistema de backup automático
- Restauração de configurações
- Backup de dados importantes

#### 4. Consolidate TODOs
`scripts/maintenance/consolidate_todos.sh`
- Organização automática de TODOs
- Priorização de tarefas
- Relatórios de progresso

## 📊 Scripts de Monitoramento

### Localização
`scripts/monitoring/`

### Scripts Disponíveis

#### 1. Central Monitor
`scripts/monitoring/central_monitor.sh`
- Monitoramento central (já descrito acima)

#### 2. Dashboard
`scripts/monitoring/dashboard.sh`
- Dashboard web simples
- Visualização de métricas
- Interface gráfica

#### 3. Log Analyzer
`scripts/monitoring/log_analyzer.sh`
- Análise automática de logs
- Detecção de padrões
- Relatórios de anomalias

#### 4. OpenWebUI Monitor
`scripts/monitoring/openwebui_monitor.sh`
- Monitoramento específico do OpenWebUI
- Métricas de uso
- Performance da interface

## 🎯 Recomendações de Uso

### Para Usuários Iniciantes
1. Use o **manager principal** (`./manager.sh`)
2. Comece com **monitoramento básico**
3. Explore **otimizações** quando necessário

### Para Usuários Avançados
1. **Integre scripts** no seu workflow
2. **Automatize** tarefas recorrentes
3. **Monitore** performance continuamente
4. **Use ferramentas de segurança** regularmente

### Para Desenvolvedores
1. **Contribua** com melhorias nos scripts
2. **Documente** novas funcionalidades
3. **Teste** thoroughly antes de commitar
4. **Siga padrões** de código estabelecidos

## 🔗 Integração com Manager

Todas essas ferramentas estão **integradas no manager principal**:

```bash
./manager.sh monitor    # Sistema de monitoramento
./manager.sh optimize   # Otimizador de performance
./manager.sh vscode     # Gerenciador VSCode
./manager.sh update     # Atualização automática
./manager.sh security   # Ferramentas de segurança
```

## 📝 Logs e Relatórios

### Localização de Logs
- `/tmp/cluster_ai_*.log` - Logs de execução
- `logs/monitor.log` - Logs de monitoramento
- `logs/cluster_ai.log` - Log geral do sistema

### Relatórios
- `/tmp/cluster_ai_optimization_report.md` - Relatório de otimização
- `metrics/cluster_metrics.json` - Métricas do cluster
- `alerts/alerts.log` - Log de alertas

---

**Nota**: Esta documentação cobre funcionalidades avançadas não documentadas na documentação principal. Para funcionalidades básicas, consulte `README.md` e `docs/guides/`.
