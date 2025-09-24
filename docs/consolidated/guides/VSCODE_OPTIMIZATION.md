# Guia de Otimização do VSCode - Cluster AI

## Visão Geral

Este guia apresenta o sistema completo de otimização de performance do VSCode desenvolvido para o projeto Cluster AI. O sistema resolve problemas comuns como travamentos, lentidão e consumo excessivo de recursos.

## Problemas Resolvidos

- ✅ Travamentos frequentes
- ✅ Consumo excessivo de memória
- ✅ Interface não responsiva
- ✅ Muitos arquivos abertos
- ✅ Perda de trabalho por crashes
- ✅ Dificuldade de recuperação

## Componentes do Sistema

### 1. VSCode Manager (Principal)
**Arquivo:** `scripts/maintenance/vscode_manager.sh`

Interface unificada que controla todos os componentes de otimização.

```bash
# Verificar status
./scripts/maintenance/vscode_manager.sh status

# Otimização completa
./scripts/maintenance/vscode_manager.sh optimize

# Iniciar VSCode otimizado
./scripts/maintenance/vscode_manager.sh start
```

### 2. Otimizador de Performance
**Arquivo:** `scripts/maintenance/vscode_optimizer.sh`

Configura o VSCode para melhor performance:
- Limpa cache automaticamente
- Otimiza configurações
- Cria workspace otimizado
- Gerencia uso de memória

### 3. Monitor de Performance
**Arquivo:** `scripts/maintenance/vscode_performance_monitor.sh`

Monitora em tempo real:
- Uso de memória e CPU
- Número de arquivos abertos
- Responsividade da interface
- Detecta problemas automaticamente

### 4. Sistema de Auto-Recuperação
**Arquivo:** `scripts/maintenance/vscode_auto_recovery.sh`

Recuperação automática:
- Reinicia VSCode quando necessário
- Aplica correções preventivas
- Mantém monitoramento contínuo
- Evita perda de trabalho

### 5. Inicializador Otimizado
**Arquivo:** `scripts/maintenance/start_vscode_optimized.sh`

Inicialização inteligente:
- Limpa estado corrompido
- Aplica configurações otimizadas
- Verifica integridade antes de iniciar
- Retry automático em caso de falha

## Instalação e Configuração

### Instalação Automática

```bash
# Executar otimização completa
./scripts/maintenance/vscode_manager.sh optimize

# Iniciar auto-recuperação
./scripts/maintenance/vscode_manager.sh recovery start

# Verificar status
./scripts/maintenance/vscode_manager.sh status
```

### Configuração Manual

1. **Executar otimização inicial:**
```bash
./scripts/maintenance/vscode_optimizer.sh full
```

2. **Criar workspace otimizado:**
```bash
./scripts/maintenance/vscode_optimizer.sh workspace
```

3. **Iniciar monitoramento:**
```bash
./scripts/maintenance/vscode_performance_monitor.sh monitor &
```

4. **Ativar auto-recuperação:**
```bash
./scripts/maintenance/vscode_auto_recovery.sh start
```

## Uso Diário

### Verificar Status
```bash
./scripts/maintenance/vscode_manager.sh status
```

### Iniciar VSCode Otimizado
```bash
./scripts/maintenance/vscode_manager.sh start
```

### Monitorar Performance
```bash
./scripts/maintenance/vscode_manager.sh monitor check
```

### Manutenção Semanal
```bash
./scripts/maintenance/vscode_manager.sh optimize
```

## Configurações Otimizadas

### Settings.json Otimizado
```json
{
    "workbench.enableExperiments": false,
    "workbench.enablePreviewFeatures": false,
    "workbench.editor.enablePreview": false,
    "workbench.editor.limit.enabled": true,
    "workbench.editor.limit.value": 15,
    "files.maxMemoryForLargeFilesMB": 1024,
    "editor.minimap.enabled": false,
    "editor.renderWhitespace": "boundary",
    "editor.wordWrap": "off",
    "editor.cursorBlinking": "solid",
    "editor.smoothScrolling": true,
    "editor.cursorSmoothCaretAnimation": "off"
}
```

### Workspace Otimizado
- Exclusão automática de arquivos desnecessários
- Configurações específicas do projeto
- Extensões recomendadas
- Configurações de debug otimizadas

## Limites de Performance

| Recurso | Limite | Ação |
|---------|--------|------|
| Memória | 85% | Reinício automático |
| CPU | 75% | Correção aplicada |
| Arquivos Abertos | 100 | Alerta gerado |
| Tempo sem resposta | 5s | Reinício forçado |

## Troubleshooting

### VSCode não abre
```bash
# Limpar estado corrompido
./scripts/maintenance/vscode_manager.sh clean

# Tentar novamente
./scripts/maintenance/vscode_manager.sh start
```

### Performance degradada
```bash
# Otimização completa
./scripts/maintenance/vscode_manager.sh optimize

# Verificar problemas
./scripts/maintenance/vscode_manager.sh monitor check
```

### Auto-recuperação não funciona
```bash
# Reiniciar auto-recuperação
./scripts/maintenance/vscode_manager.sh recovery stop
./scripts/maintenance/vscode_manager.sh recovery start
```

## Logs e Monitoramento

### Arquivos de Log
- `/tmp/vscode_manager.log` - Log principal
- `/tmp/vscode_optimizer.log` - Otimizações
- `/tmp/vscode_performance_monitor.log` - Performance
- `/tmp/vscode_auto_recovery.log` - Recuperação

### Comandos de Debug
```bash
# Ver log completo
tail -f /tmp/vscode_manager.log

# Verificar processos
ps aux | grep code

# Verificar uso de recursos
top -p $(pgrep -f code | head -1)
```

## Dicas de Performance

### Durante o Desenvolvimento
1. **Mantenha menos de 15 abas abertas**
2. **Feche arquivos não utilizados**
3. **Use Ctrl+Shift+P > 'Developer: Reload Window' se travar**
4. **Evite abrir arquivos muito grandes simultaneamente**

### Manutenção Preventiva
1. **Execute otimização semanalmente**
2. **Mantenha auto-recuperação ativa**
3. **Monitore logs regularmente**
4. **Atualize VSCode regularmente**

### Configurações do Sistema
1. **Mantenha pelo menos 4GB RAM livre**
2. **Use SSD para melhor performance**
3. **Mantenha espaço em disco (>10GB livre)**
4. **Atualize drivers de vídeo**

## Integração com Cluster AI

O sistema de otimização está integrado com o Cluster AI:

- **Monitoramento centralizado** com outros serviços
- **Alertas automáticos** via sistema de notificações
- **Backup automático** de configurações
- **Recuperação integrada** com outros componentes

## Suporte e Manutenção

### Verificar Saúde do Sistema
```bash
./scripts/maintenance/vscode_manager.sh status
```

### Relatar Problemas
1. Execute diagnóstico completo:
```bash
./scripts/maintenance/vscode_manager.sh monitor check
```

2. Colete logs relevantes:
```bash
cat /tmp/vscode_*.log
```

3. Descreva o problema com contexto

### Atualização do Sistema
```bash
# Parar serviços
./scripts/maintenance/vscode_manager.sh recovery stop

# Atualizar scripts
git pull

# Reaplicar otimizações
./scripts/maintenance/vscode_manager.sh optimize

# Reiniciar serviços
./scripts/maintenance/vscode_manager.sh recovery start
```

## Conclusão

Este sistema de otimização transforma o VSCode de uma ferramenta problemática em um ambiente de desenvolvimento confiável e de alta performance. Com monitoramento automático e recuperação inteligente, você pode focar no desenvolvimento sem se preocupar com travamentos ou perda de produtividade.

Para suporte adicional, consulte a documentação completa do Cluster AI ou abra uma issue no repositório do projeto.
