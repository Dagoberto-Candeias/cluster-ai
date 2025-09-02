# 🚀 Guia Rápido - Worker Android (Fácil)

## 📱 Instalação em 5 Minutos

### Passo 1: Instalar Termux
1. Baixe o **Termux** da F-Droid ou Google Play
2. Abra o aplicativo
3. Execute: `termux-setup-storage`
4. Conceda as permissões solicitadas

### Passo 2: Escolher Método de Instalação

#### 📡 Método Automático (recomendado):
```bash
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker.sh | bash
```

#### 📱 Método Manual (se automático falhar):
```bash
# Copie e cole este script completo no Termux:
```

```bash
#!/data/data/com.termux/files/usr/bin/bash
# Instalação Manual do Worker Android - Cluster AI

set -euo pipefail

# --- Cores para output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Funções auxiliares ---
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        error "Este script deve ser executado no Termux!"
        exit 1
    fi
    success "Termux detectado"
}

main() {
    echo; echo "🤖 INSTALAÇÃO MANUAL - WORKER ANDROID"; echo "====================================="; echo
    check_termux

    log "Configurando armazenamento..."
    if [ ! -d "$HOME/storage" ]; then termux-setup-storage; sleep 3; fi
    success "Armazenamento OK"

    log "Atualizando pacotes..."
    pkg update -y >/dev/null 2>&1; pkg upgrade -y >/dev/null 2>&1
    success "Pacotes atualizados"

    log "Instalando dependências..."
    pkg install -y openssh python git ncurses-utils curl >/dev/null 2>&1
    success "Dependências OK"

    log "Configurando SSH..."
    mkdir -p "$HOME/.ssh"
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        ssh-keygen -t rsa -b 2048 -N "" -f "$HOME/.ssh/id_rsa" >/dev/null 2>&1
    fi
    sshd >/dev/null 2>&1
    success "SSH OK"

    log "Baixando projeto..."
    if [ ! -d "$HOME/Projetos/cluster-ai" ]; then
        mkdir -p "$HOME/Projetos"
        if git clone git@github.com:Dagoberto-Candeias/cluster-ai.git "$HOME/Projetos/cluster-ai" >/dev/null 2>&1; then
            success "Projeto clonado via SSH"
        elif git clone https://github.com/Dagoberto-Candeias/cluster-ai.git "$HOME/Projetos/cluster-ai" >/dev/null 2>&1; then
            success "Projeto clonado via HTTPS"
        else
            warn "Clone falhou - configure autenticação posteriormente"
        fi
    else
        success "Projeto já existe"
    fi

    echo; echo "=================================================="
    echo "🎉 INSTALAÇÃO CONCLUÍDA!"
    echo "=================================================="; echo
    echo "🔑 CHAVE SSH (copie para o servidor principal):"
    echo "--------------------------------------------------"
    cat "$HOME/.ssh/id_rsa.pub"
    echo "--------------------------------------------------"; echo
    echo "🌐 CONEXÃO: $(whoami)@$(ip route get 1 | awk '{print $7}' | head -1 || echo 'Verifique Wi-Fi'):8022"
    echo; echo "📋 No servidor principal: ./manager.sh > Gerenciar Workers"
}

main
```

**O que acontece:**
- ✅ Atualiza pacotes automaticamente
- ✅ Instala SSH, Python e Git
- ✅ Configura servidor SSH
- ✅ Baixa o projeto Cluster AI (com fallback)
- ✅ Mostra informações de conexão

### Passo 3: Copiar Chave SSH
O script mostrará uma **chave SSH** como esta:
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... usuario@dispositivo
```

**Copie TUDO** (da palavra `ssh-rsa` até o final)

### Passo 4: Registrar no Servidor Principal
No seu servidor principal, execute:
```bash
cd /caminho/para/cluster-ai
./manager.sh
```

Escolha as opções:
1. **"Gerenciar Workers Remotos (SSH)"**
2. **"Configurar um worker Android (Termux)"**
3. **Cole a chave SSH** quando solicitado
4. **Digite o IP** do seu celular Android
5. **Porta: 8022**

## 🔧 Solução de Problemas

### ❌ Erro 400 ou falha no download (Repositório Privado)
```bash
# SOLUÇÃO 1: Baixar via Git (recomendado para repositórios privados)
pkg install -y git
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git ~/cluster-ai-temp
cd ~/cluster-ai-temp
bash scripts/android/setup_android_worker.sh

# SOLUÇÃO 2: Usar token de acesso pessoal
# 1. Vá para: https://github.com/settings/tokens
# 2. Crie um token com permissões "repo"
# 3. Execute:
curl -H "Authorization: token SEU_TOKEN_AQUI" \
  -H "Accept: application/vnd.github.v3.raw" \
  -o setup_worker.sh \
  https://api.github.com/repos/Dagoberto-Candeias/cluster-ai/contents/scripts/android/setup_android_worker.sh?ref=main

# SOLUÇÃO 3: Download manual
# 1. No seu computador, baixe o arquivo:
#    https://github.com/Dagoberto-Candeias/cluster-ai/blob/main/scripts/android/setup_android_worker.sh
# 2. Transfira para o Android via Bluetooth/USB
# 3. Execute: bash setup_android_worker.sh
```

### ❌ "Repository not found" ou "Permission denied" (Repositório Privado)
```bash
# Solução 1: Configurar chave SSH no GitHub
# 1. Vá para: https://github.com/settings/keys
# 2. Clique em "New SSH key"
# 3. Cole a chave gerada pelo script (mostrada na saída)
# 4. Execute o script novamente

# Solução 2: Usar Personal Access Token
# 1. Vá para: https://github.com/settings/tokens
# 2. Gere um novo token com permissões de "repo"
# 3. Execute manualmente:
git clone https://SEU_TOKEN@github.com/Dagoberto-Candeias/cluster-ai.git ~/Projetos/cluster-ai
```

### ❌ SSH não conecta
```bash
# No Termux, verifique se SSH está rodando
sshd

# Teste local
ssh localhost -p 8022
```

### ❌ "Permission denied" (não relacionado ao Git)
```bash
# Execute novamente a configuração de storage
termux-setup-storage
```

### ❌ Sem internet no Termux
- Verifique se o Wi-Fi está conectado
- Teste: `ping 8.8.8.8`
- Se não funcionar, reinicie o Termux

### ❌ Falha na autenticação Git
```bash
# Verificar configuração Git
git config --global user.name "Seu Nome"
git config --global user.email "seu@email.com"

# Testar conexão SSH
ssh -T git@github.com
```

## 📊 Verificar se Funcionou

### No Android (Termux):
```bash
# Execute o script de teste
bash ~/Projetos/cluster-ai/scripts/android/test_android_worker.sh
```

### No Servidor Principal:
```bash
# Ver status dos workers
./manager.sh
# Procure pelo worker Android na lista
```

### Teste de Conexão:
```bash
# Teste SSH do servidor para o Android
ssh usuario@ip_do_android -p 8022

# Teste execução remota
ssh usuario@ip_do_android -p 8022 "echo 'Worker Android conectado!'"
```

## 💡 Dicas para Melhor Performance

- 🔋 **Bateria**: Mantenha acima de 20%
- 📶 **Wi-Fi**: Use rede estável
- 📱 **Background**: Não feche o Termux
- 🧠 **RAM**: Feche outros apps no Android
- 🌡️ **Temperatura**: Evite uso prolongado se >40°C

## 🎯 O Que Faz o Worker Android

- ⚡ **Processamento CPU**: Executa tarefas distribuídas
- 🤖 **IA Local**: Pode rodar modelos pequenos do Ollama
- 📊 **Análise de Dados**: Processa chunks de dados
- 🔄 **Backup**: Ajuda em tarefas de backup distribuído

## ❓ Ainda com Problemas?

Se nada funcionar:

1. **Reinicie o Android**
2. **Reinstale o Termux**
3. **Execute novamente a configuração**
4. **Configure a autenticação SSH para GitHub:**
   - Execute o script auxiliar:
     ```bash
     bash ~/scripts/android/setup_github_ssh.sh
     ```
   - Siga as instruções para adicionar a chave SSH no GitHub
5. **Abra uma issue no GitHub** com os logs de erro

---

**🎉 Parabéns!** Seu Android agora é parte do Cluster AI! 🚀
