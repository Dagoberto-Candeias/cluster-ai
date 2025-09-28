# Correções Aplicadas para Congelamentos do VSCode

## Problemas Identificados e Resolvidos

### 1. Script demo_complete_system.sh
- **Problema**: Cálculo incorreto do PROJECT_ROOT causando falha ao localizar common.sh
- **Solução**: Simplificado o cálculo para usar `PROJECT_ROOT="$(pwd)"`
- **Status**: ✅ RESOLVIDO - Script agora executa corretamente

### 2. Congelamentos do VSCode no Debian
- **Problema**: VSCode congelando ao executar comandos do sistema
- **Causas Possíveis**:
  - Uso excessivo de recursos pelos workers
  - Configurações inadequadas do terminal integrado
  - Falta de limites de recursos para processos
  - Cache acumulado do VSCode

## Correções Aplicadas

### ✅ Configurações do VSCode Otimizadas
- Desabilitado minimap e renderização desnecessária
- Configurado terminal integrado para performance
- Desabilitado auto-update de extensões
- Otimizado file watcher exclude patterns

### ✅ Limites de Sistema Ajustados
- Arquivo `/etc/security/limits.d/99-vscode.conf` criado
- Limites de arquivos abertos: 4096 soft, 8192 hard
- Configurações aplicadas ao usuário vscode

### ✅ Configurações do Kernel Otimizadas
- Arquivo `/etc/sysctl.d/99-vscode.conf` criado
- Swappiness reduzido para 10
- Dirty ratio otimizado para melhor performance
- Granularidade de scheduler ajustada

### ✅ Scripts de Manutenção Criados
- `scripts/vscode/clean_vscode_cache.sh`: Limpa cache do VSCode
- `scripts/vscode/monitor_resources.sh`: Monitora uso de recursos
- `scripts/vscode/terminal_wrapper.sh`: Wrapper para comandos do terminal

### ✅ .bashrc Otimizado
- Limites de processos e arquivos abertos
- Alias para monitoramento: `vscode-monitor`, `vscode-clean`
- Configurações de histórico otimizadas

## Próximos Passos Recomendados

### Imediatos (Executar Agora)
1. **Fechar VSCode completamente**
2. **Executar limpeza de cache**:
   ```bash
   vscode-clean
   ```
3. **Reiniciar VSCode**
4. **Testar execução de comandos**

### Monitoramento Contínuo
- Usar `vscode-monitor` para verificar recursos se houver problemas
- Monitorar logs do sistema: `journalctl -f`
- Verificar uso de CPU/memória com `htop`

### Se Problemas Persistirem
1. **Atualizar VSCode**:
   ```bash
   sudo apt update && sudo apt install code
   ```

2. **Verificar extensões**:
   - Desabilitar extensões desnecessárias
   - Atualizar extensões críticas

3. **Verificar sistema**:
   ```bash
   sudo apt update && sudo apt upgrade
   free -h  # Verificar memória disponível
   ```

## Comandos Úteis Criados

```bash
# Limpar cache do VSCode
vscode-clean

# Monitorar recursos do sistema
vscode-monitor

# Executar comandos com wrapper (reduz uso de recursos)
bash scripts/vscode/terminal_wrapper.sh <comando>
```

## Arquivos Modificados/Criados

### Modificados
- `demo_complete_system.sh`: Correção do PROJECT_ROOT
- `~/.bashrc`: Otimizações adicionadas
- `~/.config/Code/User/settings.json`: Configurações otimizadas

### Criados
- `scripts/vscode/fix_vscode_freeze.sh`: Script principal de correção
- `scripts/vscode/clean_vscode_cache.sh`: Limpeza de cache
- `scripts/vscode/monitor_resources.sh`: Monitoramento
- `scripts/vscode/terminal_wrapper.sh`: Wrapper de comandos
- `/etc/security/limits.d/99-vscode.conf`: Limites do sistema
- `/etc/sysctl.d/99-vscode.conf`: Configurações do kernel
- `~/.vscode/argv.json`: Configurações adicionais do VSCode

## Status Final
- ✅ Script demo_complete_system.sh funcionando
- ✅ Correções do VSCode aplicadas
- ✅ Scripts de manutenção criados
- ✅ Configurações otimizadas

**Resultado Esperado**: VSCode deve parar de congelar e ter melhor performance geral no Debian.
