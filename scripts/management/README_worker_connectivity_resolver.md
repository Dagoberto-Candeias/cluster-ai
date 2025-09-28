# 🔗 Resolvedor de Conectividade de Workers - Cluster AI

## 📋 Visão Geral

O **Resolvedor de Conectividade de Workers** é uma ferramenta avançada para diagnosticar e resolver problemas de conectividade entre o nó manager do Cluster AI e seus workers remotos. Esta ferramenta automatiza o processo de identificação de problemas de rede, configuração SSH e status dos serviços do cluster.

## 🎯 Funcionalidades Principais

### 🔍 **Diagnóstico Completo**
- **Teste de conectividade básica**: Ping para verificar se o worker está na rede
- **Verificação de tabela ARP**: Identifica problemas de resolução de endereços MAC
- **Teste de portas do cluster**: Verifica se as portas necessárias estão abertas (Dask, Ollama, etc.)
- **Autenticação SSH**: Testa se a conexão SSH está funcionando corretamente

### 🔧 **Resolução Automática**
- **Descoberta de workers na rede**: Usa ferramentas como `nmap` e `arp` para encontrar dispositivos
- **Configuração automática de SSH**: Copia chaves públicas para workers
- **Atualização de configurações**: Mantém os arquivos de configuração sincronizados
- **Relatórios detalhados**: Gera relatórios completos sobre o status dos workers

### 📊 **Relatórios e Monitoramento**
- **Relatório completo**: Visão geral de todos os workers e seus status
- **Diagnóstico individual**: Análise detalhada de um worker específico
- **Listagem de workers**: Mostra todos os workers configurados
- **Logs de auditoria**: Registra todas as ações realizadas

## 🚀 Como Usar

### Método 1: Via Manager do Cluster
```bash
./manager.sh
# Escolha a opção 8) 🔗 Resolvedor de Conectividade de Workers
```

### Método 2: Execução Direta
```bash
./scripts/management/worker_connectivity_resolver.sh
```

### Método 3: Modo Não-Interativo (para automação)
```bash
# Diagnosticar um worker específico chamado 'worker-01'
./scripts/management/worker_connectivity_resolver.sh diagnose worker-01

# Tentar resolver problemas de todos os workers automaticamente
./scripts/management/worker_connectivity_resolver.sh auto-resolve

# Descobrir novos workers na rede
./scripts/management/worker_connectivity_resolver.sh discover
```

## 📖 Menu de Opções

### 🔍 **Diagnóstico**
1. **Diagnosticar conectividade de worker específico**
   - Permite escolher um worker específico para análise detalhada
   - Mostra problemas encontrados e recomendações de solução

2. **Diagnosticar todos os workers**
   - Executa diagnóstico completo em todos os workers configurados
   - Útil para verificações rápidas de status geral

### 🔧 **Resolução**
3. **Resolver problemas automaticamente**
   - Tenta corrigir automaticamente problemas identificados
   - Inclui configuração SSH, descoberta de IP e atualização de configurações

4. **Descobrir workers na rede**
   - Usa ferramentas de descoberta de rede para encontrar workers
   - Suporta descoberta via ARP, mDNS e nmap

5. **Atualizar configuração de worker**
   - Permite modificar configurações de workers existentes
   - Atualiza IP, usuário, porta ou status

### ⚙️ **Utilitários**
6. **Listar workers configurados**
   - Mostra todos os workers registrados no sistema
   - Exibe status atual de cada worker

7. **Gerar relatório completo**
   - Cria relatório detalhado sobre todos os workers
   - Inclui diagnósticos, recomendações e estatísticas

## 🔧 Configuração de Workers

### Arquivo de Configuração
O resolvedor usa o arquivo `~/.cluster_config/nodes_list.conf`:

```bash
# Formato: hostname alias IP user port status
android-device android 192.168.0.13 u0_a249 8022 active
manjaro-pc manjaro 192.168.0.4 dcm 22 active
```

### Campos da Configuração
- **hostname**: Nome do host do worker
- **alias**: Apelido amigável para identificação
- **IP**: Endereço IP do worker
- **user**: Usuário SSH para conexão
- **port**: Porta SSH (22 para Linux, 8022 para Android/Termux)
- **status**: Status atual (active/inactive)

## 🛠️ Solução de Problemas Comuns

### ❌ Worker Mostrando como "OFFLINE"

#### Problema: Ping falha
**Sintomas**: "Destination Host Unreachable"
**Possíveis causas**:
- Worker não está ligado
- Worker não está na mesma rede
- Firewall bloqueando ICMP

**Soluções**:
1. Verificar se o worker está ligado
2. Confirmar que estão na mesma rede (mesmo subnet)
3. Verificar configurações de firewall

#### Problema: Porta SSH fechada
**Sintomas**: "Porta está fechada ou bloqueada"
**Possíveis causas**:
- Serviço SSH não está rodando no worker
- Firewall bloqueando a porta SSH
- Porta incorreta na configuração

**Soluções**:
1. Verificar se o SSH está instalado e rodando no worker
2. Abrir a porta no firewall do worker
3. Confirmar a porta correta (22 para Linux, 8022 para Android)

#### Problema: Falha na autenticação SSH
**Sintomas**: "Falha na autenticação SSH"
**Possíveis causas**:
- Chave SSH não foi copiada
- Permissões incorretas nos arquivos SSH
- Usuário incorreto na configuração

**Soluções**:
1. Copiar chave SSH usando `ssh-copy-id`
2. Verificar permissões dos arquivos `~/.ssh/`
3. Confirmar usuário correto no worker

### 🔍 Diagnóstico Passo-a-Passo

1. **Executar diagnóstico completo**:
   ```bash
   printf "2\n" | ./scripts/management/worker_connectivity_resolver.sh
   ```

2. **Verificar problemas específicos**:
   - Leia as mensagens de erro detalhadas
   - Anote os códigos de erro (ping_failed, no_arp_entry, etc.)

3. **Aplicar correções**:
   - Siga as recomendações específicas para cada problema
   - Use a opção de resolução automática quando possível

4. **Verificar correção**:
   - Execute o diagnóstico novamente
   - Confirme que os problemas foram resolvidos

## 📊 Relatórios e Logs

### Localização dos Arquivos
- **Logs do resolvedor**: `logs/worker_connectivity_resolver.log`
- **Relatórios**: Gerados na execução e salvos em `reports/`
- **Configurações**: `~/.cluster_config/nodes_list.conf`

### Interpretação dos Relatórios

#### ✅ Status "ONLINE"
- Worker está totalmente acessível
- Todas as verificações passaram
- Pronto para uso no cluster

#### ❌ Status "OFFLINE"
- Worker não está acessível
- Verificar problemas específicos listados
- Aplicar correções recomendadas

#### ⚠️ Status "PARCIAL"
- Algumas verificações falharam
- Worker pode ter problemas específicos
- Verificar detalhes no relatório

## 🔄 Integração com o Sistema

### Comandos do Manager
```bash
# Status completo do cluster (inclui workers)
./manager.sh status

# Verificar workers específicos
./manager.sh check-workers

# Menu completo do manager
./manager.sh
```

### Scripts Relacionados
- `scripts/setup_ssh_workers.sh`: Configuração inicial de SSH
- `scripts/utils/network_discovery.sh`: Descoberta de rede
- `scripts/management/test_node_connectivity.sh`: Testes básicos de conectividade

## 🆘 Suporte e Troubleshooting

### Logs de Debug
Para obter mais informações durante a execução:
```bash
# Executar com debug
bash -x ./scripts/management/worker_connectivity_resolver.sh
```

### Verificação Manual
```bash
# Testar ping
ping -c 4 192.168.0.13

# Testar porta SSH
nc -zv 192.168.0.13 8022

# Testar SSH
ssh -v u0_a249@192.168.0.13 -p 8022
```

### Limpeza de Configurações
```bash
# Limpar known_hosts (cuidado!)
ssh-keygen -R 192.168.0.13

# Recriar configuração
rm ~/.cluster_config/nodes_list.conf
./manager.sh configure
```

## 📈 Melhorias Futuras

- [ ] Suporte a IPv6
- [ ] Integração com ferramentas de monitoramento (Prometheus)
- [ ] Alertas automáticos por email/telegram
- [ ] Dashboard web para visualização de status
- [ ] Suporte a containers Docker como workers
- [ ] Auto-healing para problemas temporários

---

**Nota**: Esta ferramenta é parte integrante do Cluster AI e está em constante evolução. Para sugestões ou relatórios de bugs, use os canais oficiais do projeto.
