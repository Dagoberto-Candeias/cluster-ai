# 🔧 CORREÇÃO MANUAL DO VS CODE - GUIA PASSO A PASSO

## ❌ PROBLEMA IDENTIFICADO
O VSCode está fechando inesperadamente quando scripts tentam iniciá-lo automaticamente. Isso indica um problema mais profundo no ambiente ou instalação do VSCode.

## 🛠️ SOLUÇÕES MANUAIS (NÃO AUTOMÁTICAS)

### SOLUÇÃO 1: LIMPEZA MANUAL COMPLETA

#### Passo 1: Fazer Backup (IMPORTANTE!)
```bash
# Criar backup das configurações atuais
mkdir -p ~/vscode_backup_manual
cp -r ~/.config/Code/User/settings.json ~/vscode_backup_manual/ 2>/dev/null || true
cp -r ~/.vscode/extensions ~/vscode_backup_manual/ 2>/dev/null || true
echo "Backup criado em: ~/vscode_backup_manual"
```

#### Passo 2: Parar VSCode Completamente
```bash
# Forçar parada de todos os processos
pkill -9 -f "code" 2>/dev/null || true
pkill -9 -f "vscode" 2>/dev/null || true
pkill -9 -f "electron" 2>/dev/null || true
sleep 5
```

#### Passo 3: Limpar Estado Corrompido
```bash
# Limpar diretórios de estado
rm -rf ~/.config/Code/User/workspaceStorage/*
rm -rf ~/.config/Code/User/globalStorage/*
rm -rf ~/.config/Code/Backups/*
rm -rf ~/.config/Code/Local\ Storage/*
rm -rf ~/.config/Code/logs/*
rm -rf ~/.config/Code/Crashpad/*
rm -rf ~/.vscode/extensions/*
rm -rf /tmp/vscode-*
rm -rf /tmp/Crashpad*
```

#### Passo 4: Recriar Configurações Seguras
```bash
# Criar configurações básicas
mkdir -p ~/.config/Code/User

cat > ~/.config/Code/User/settings.json << 'EOF'
{
    "telemetry.telemetryLevel": "off",
    "extensions.autoUpdate": false,
    "update.mode": "none",
    "workbench.enableExperiments": false,
    "files.watcherExclude": {
        "**/.git/objects/**": true,
        "**/.git/subtree-cache/**": true,
        "**/node_modules/**": true,
        "**/venv/**": true,
        "**/cluster_env/**": true,
        "**/.vscode/**": true,
        "**/backups/**": true
    },
    "search.exclude": {
        "**/node_modules": true,
        "**/venv": true,
        "**/cluster_env": true,
        "**/.vscode": true,
        "**/backups": true
    },
    "editor.largeFileOptimizations": true,
    "files.maxMemoryForLargeFilesMB": 512,
    "editor.codeLens": false,
    "editor.minimap.enabled": false,
    "workbench.editor.empty.hint": "hidden",
    "workbench.startupEditor": "none",
    "workbench.editor.limit.enabled": true,
    "workbench.editor.limit.value": 3,
    "window.restoreWindows": "none",
    "window.newWindowDimensions": "default",
    "typescript.tsserver.maxTsServerMemory": 512,
    "javascript.suggest.enabled": false,
    "typescript.suggest.enabled": false,
    "python.terminal.activateEnvironment": true,
    "terminal.integrated.scrollback": 300,
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 60000
}
EOF
```

#### Passo 5: Teste de Inicialização Manual
```bash
# Teste BÁSICO (execute no terminal)
code --version

# Se funcionar, teste com configurações mínimas
code --disable-extensions --no-sandbox

# Se ainda funcionar, teste completo
code --disable-extensions --disable-gpu --no-sandbox --disable-web-security
```

### SOLUÇÃO 2: REINSTALAÇÃO COMPLETA DO VSCODE

#### Passo 1: Remover VSCode Completamente
```bash
# Ubuntu/Debian
sudo apt remove --purge code code-insiders
sudo apt autoremove
sudo apt autoclean

# Remover configurações
rm -rf ~/.config/Code
rm -rf ~/.vscode
rm -rf ~/.cache/code*
```

#### Passo 2: Limpar Cache do Sistema
```bash
# Limpar caches
rm -rf /tmp/code*
rm -rf /tmp/vscode*
rm -rf ~/.cache/code*
```

#### Passo 3: Reinstalar VSCode
```bash
# Baixar e instalar versão estável
wget -O vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
sudo dpkg -i vscode.deb
sudo apt install -f
rm vscode.deb
```

#### Passo 4: Primeira Inicialização Segura
```bash
# Iniciar sem workspace
code --disable-extensions --no-sandbox
```

### SOLUÇÃO 3: ALTERNATIVAS AO VSCODE

#### Opção A: Usar VSCode Web/Insiders
```bash
# Instalar VSCode Insiders (versão de desenvolvimento)
wget -O vscode-insiders.deb "https://code.visualstudio.com/sha/download?build=insiders&os=linux-deb-x64"
sudo dpkg -i vscode-insiders.deb
sudo apt install -f

# Usar code-insiders em vez de code
code-insiders --disable-extensions --no-sandbox
```

#### Opção B: Usar Editor Alternativo Temporariamente
```bash
# Instalar Sublime Text
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
sudo apt install apt-transport-https
echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
sudo apt update
sudo apt install sublime-text

# Ou instalar Atom (se disponível)
# sudo apt install atom
```

#### Opção C: Usar VSCode no Navegador
```bash
# Se você tem um servidor, pode usar VSCode Web
# Ou usar GitHub Codespaces temporariamente
```

### SOLUÇÃO 4: DIAGNÓSTICO AVANÇADO

#### Verificar Logs do Sistema
```bash
# Verificar logs do sistema
journalctl -u code.service 2>/dev/null || echo "Serviço não encontrado"
dmesg | grep -i "code\|vscode\|electron" | tail -20

# Verificar uso de memória
free -h
ps aux | grep -E "(code|vscode)" | grep -v grep
```

#### Verificar Dependências
```bash
# Verificar bibliotecas necessárias
ldd /usr/bin/code 2>/dev/null || echo "Code não encontrado"
ldd /usr/bin/code-insiders 2>/dev/null || echo "Code-insiders não encontrado"
```

#### Testar com Usuário Diferente
```bash
# Criar usuário de teste
sudo useradd -m vscode-test
sudo su - vscode-test
code --version
```

## 📋 CHECKLIST DE VERIFICAÇÃO

- [ ] VSCode fecha inesperadamente? ✅
- [ ] Scripts automáticos causam fechamento? ✅
- [ ] Backup das configurações feito? ☐
- [ ] Limpeza manual executada? ☐
- [ ] Configurações seguras aplicadas? ☐
- [ ] Teste de inicialização básica passou? ☐
- [ ] Extensões essenciais instaladas? ☐

## 🚨 EM CASO DE PROBLEMA PERSISTENTE

Se nenhuma solução funcionar:

1. **Documente o problema:**
   ```bash
   # Criar relatório de diagnóstico
   echo "=== RELATÓRIO DE DIAGNÓSTICO ===" > ~/vscode_diagnostic.txt
   echo "Data: $(date)" >> ~/vscode_diagnostic.txt
   echo "Sistema: $(uname -a)" >> ~/vscode_diagnostic.txt
   echo "Usuário: $(whoami)" >> ~/vscode_diagnostic.txt
   echo "Display: $DISPLAY" >> ~/vscode_diagnostic.txt
   code --version >> ~/vscode_diagnostic.txt 2>&1
   echo "=== FIM DO RELATÓRIO ===" >> ~/vscode_diagnostic.txt
   ```

2. **Considere usar outro editor temporariamente**

3. **Abra uma issue no repositório do VSCode:**
   - https://github.com/microsoft/vscode/issues

4. **Use VSCode em outro ambiente:**
   - Máquina virtual
   - WSL (se no Windows)
   - Codespaces

## 💡 RECOMENDAÇÕES GERAIS

1. **Evite executar scripts que iniciam VSCode automaticamente**
2. **Sempre faça backup antes de mudanças**
3. **Teste mudanças uma de cada vez**
4. **Monitore logs durante inicialização**
5. **Considere usar versão Insiders para testes**

## 🔄 PRÓXIMOS PASSOS

Após aplicar qualquer solução:

1. Teste a inicialização básica: `code --version`
2. Teste abertura sem workspace: `code --disable-extensions`
3. Abra o projeto: `code ~/Projetos/cluster-ai`
4. Instale apenas extensões essenciais uma por vez
5. Monitore estabilidade por alguns dias

---

**IMPORTANTE:** Execute apenas os comandos que você entender e tenha certeza de que não vão causar problemas no seu sistema. Faça backup de dados importantes antes de qualquer mudança.
