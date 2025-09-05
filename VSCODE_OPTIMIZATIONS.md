# 🚀 Otimizações VSCode - Cluster AI

## 📋 Problema Identificado
O VSCode estava travando constantemente devido ao projeto Cluster AI ser muito grande e complexo, com muitos arquivos abertos simultaneamente.

## ✅ Melhorias Implementadas

### 1. **Configurações Otimizadas (.vscode/settings.json)**
- **File Watcher Exclusions**: Excluiu diretórios pesados (backups/, logs/, node_modules/, etc.)
- **Search Exclusions**: Otimizou busca excluindo arquivos temporários e caches
- **Python Analysis**: Configurou análise mais leve para melhor performance
- **Editor Settings**: Minimap desabilitado, limite de editores configurado
- **Extensions**: Desabilitou extensões pesadas (Pylint, autopep8) por padrão

### 2. **Extensões Recomendadas (.vscode/extensions.json)**
- **Essenciais**: Python, Pylance, Docker, GitHub Actions, BlackboxAI
- **Não Recomendadas**: Extensões pesadas como Pylint, ESLint, Prettier
- **Foco**: Apenas extensões necessárias para desenvolvimento

### 3. **Script de Limpeza (scripts/cleanup_vscode.sh)**
- Remove caches Python (`__pycache__/`, `*.pyc`)
- Limpa logs antigos (mais de 7 dias)
- Organiza backups (mantém apenas 5 mais recentes)
- Remove arquivos temporários (`*.tmp`, `*.bak`, `*~`)
- Verifica processos em execução

### 4. **Arquivo .vscodeignore**
- Exclui diretórios grandes da indexação
- Ignora arquivos temporários e caches
- Melhora performance de abertura do projeto

## 📊 Resultados da Limpeza
- **Backups**: 995MB organizados
- **Logs**: 740KB limpos
- **Test Logs**: 12KB limpos
- **Reports**: 80KB limpos

## 🎯 Como Usar

### Limpeza Manual
```bash
./scripts/cleanup_vscode.sh
```

### Otimização Completa
1. Execute o script de limpeza
2. Feche o VSCode completamente
3. Execute: `killall code` (ou `killall code-insiders`)
4. Reabra o VSCode no projeto
5. Aguarde a reindexação inicial

## 💡 Dicas de Performance

### Durante o Desenvolvimento
- **Mantenha menos de 10 abas abertas**
- **Feche arquivos não utilizados**
- **Use Ctrl+Shift+P > "Developer: Reload Window"** se necessário

### Configurações do Workspace
- **Files: Exclude**: Configure exclusões adicionais se necessário
- **Search: Exclude**: Adicione padrões de exclusão personalizados
- **Extensions**: Desative extensões não utilizadas

### Monitoramento
- **Process Monitor**: Use `htop` ou `top` para monitorar recursos
- **VSCode Process**: Procure por processos `code` ou `code-insiders` no monitor

## 🔧 Configurações Avançadas

### Se Ainda Travar
1. **Reduza limite de editores**:
   ```json
   "workbench.editor.limit.value": 5
   ```

2. **Desative mais extensões**:
   - Pylance (use apenas Python básico)
   - GitHub Actions
   - Docker

3. **Aumente memória do VSCode** (se disponível):
   ```bash
   code --max-memory=4096
   ```

## 📈 Melhorias Esperadas
- ✅ Menos travamentos
- ✅ Abertura mais rápida do projeto
- ✅ Busca mais rápida
- ✅ Menor uso de CPU/Memória
- ✅ Indexação mais eficiente

## 🆘 Troubleshooting

### VSCode Ainda Lento
- Execute novamente o script de limpeza
- Reinicie o sistema
- Verifique se há atualizações do VSCode
- Considere usar VSCode Insiders (mais atual)

### Extensões Problemáticas
- Desative extensões uma por uma para identificar culpadas
- Use "Developer: Show Running Extensions" para ver consumo

### Projeto Muito Grande
- Considere dividir em workspaces menores
- Use links simbólicos para diretórios grandes
- Configure exclusões mais agressivas

---
**Última atualização**: $(date)
**Status**: ✅ Otimizado para performance
