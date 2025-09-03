# Instalação do Worker no Android

Este guia fornece instruções para instalar um worker no Android usando o Termux.

## Pré-requisitos

- Dispositivo Android com Termux instalado
- Conexão com a internet

## Método 1: Script Automático (Recomendado)

Para facilitar a instalação, use o script automático:

### Opção A: Baixar e executar o script (se disponível)
```bash
# Baixar o script
curl -L -o install_worker.sh https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/install_worker.sh

# Tornar executável
chmod +x install_worker.sh

# Executar
./install_worker.sh
```

### Opção B: Criar o script manualmente
Se o download falhar, copie o conteúdo abaixo e salve em um arquivo `install_worker.sh`:

```bash
#!/data/data/com.termux/files/usr/bin/bash
# Script de instalação do Worker Android para Cluster AI
# Execute este script no Termux

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funções auxiliares
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# Verificar Termux
check_termux() {
    if [ ! -d "/data/data/com.termux" ]; then
        error "Este script deve ser executado no Termux!"
        exit 1
    fi
    success "Termux detectado"
}

# Configurar armazenamento
setup_storage() {
    log "Configurando armazenamento..."
    if [ ! -d "$HOME/storage" ]; then
        termux-setup-storage
        sleep 3
    fi
    success "Armazenamento configurado"
}

# Corrigir dpkg
fix_dpkg() {
    log "Corrigindo dpkg..."
    dpkg --configure -a 2>/dev/null || true
    success "dpkg corrigido"
}

# Atualizar pacotes
update_packages() {
    log "Atualizando pacotes..."
    pkg update -y
    success "Pacotes atualizados"
}

# Instalar dependências
install_deps() {
    log "Instalando dependências..."
    pkg install -y openssh python git ncurses-utils curl
    success "Dependências instaladas"
}

# Configurar SSH
setup_ssh() {
    log "Configurando SSH..."
    mkdir -p "$HOME/.ssh"
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        ssh-keygen -t rsa -b 2048 -N "" -f "$HOME/.ssh/id_rsa" -C "$(whoami)@termux"
    fi
    sshd >/dev/null 2>&1
    success "SSH configurado"
}

# Baixar projeto
download_project() {
    log "Baixando projeto Cluster AI..."
    mkdir -p "$HOME/Projetos"
    cd "$HOME/Projetos"
    if git clone https://github.com/Dagoberto-Candeias/cluster-ai.git cluster-ai 2>/dev/null; then
        success "Projeto baixado via HTTPS"
    else
        warn "HTTPS falhou - tentando método alternativo"
        if curl -L -o cluster-ai.zip https://github.com/Dagoberto-Candeias/cluster-ai/archive/main.zip && [ -s cluster-ai.zip ]; then
            unzip cluster-ai.zip
            mv cluster-ai-main cluster-ai
            rm cluster-ai.zip
            success "Projeto baixado via ZIP"
        else
            warn "Download falhou. Você pode baixar manualmente de:"
            echo "  https://github.com/Dagoberto-Candeias/cluster-ai"
            echo "  Ou configure autenticação SSH primeiro."
            success "Pule o download - configure manualmente se necessário"
        fi
    fi
}

# Exibir informações
show_info() {
    echo
    echo "=================================================="
    echo "🎉 INSTALAÇÃO CONCLUÍDA COM SUCESSO!"
    echo "=================================================="
    echo
    echo "🔑 CHAVE SSH PÚBLICA (copie tudo abaixo):"
    echo "--------------------------------------------------"
    cat "$HOME/.ssh/id_rsa.pub"
    echo "--------------------------------------------------"
    echo
    echo "🌐 INFORMAÇÕES DE CONEXÃO:"
    echo "   Usuário: $(whoami)"
    echo "   IP: $(ip route get 1 | awk '{print $7}' | head -1)"
    echo "   Porta SSH: 8022"
    echo
    echo "📋 PRÓXIMOS PASSOS:"
    echo "1. Copie a chave SSH acima"
    echo "2. No servidor principal, execute: ./manager.sh"
    echo "3. Escolha: Gerenciar Workers Remotos (SSH)"
    echo "4. Cole a chave SSH quando solicitado"
    echo "5. Digite o IP do seu Android"
    echo "6. Porta: 8022"
    echo
    echo "🧪 TESTE DE CONEXÃO:"
    echo "ssh $(whoami)@$(ip route get 1 | awk '{print $7}' | head -1) -p 8022"
}

# Função principal
main() {
    echo
    echo "🤖 CLUSTER AI - INSTALAÇÃO DO WORKER ANDROID"
    echo "==========================================="
    echo
    warn "Este script instala tudo automaticamente"
    echo

    check_termux
    setup_storage
    fix_dpkg
    update_packages
    install_deps
    setup_ssh
    download_project
    show_info

    echo "🎊 Pronto! Seu Android é um worker do Cluster AI!"
    echo
}

# Executar
main
```

Depois de salvar o arquivo, execute:
```bash
chmod +x install_worker.sh
./install_worker.sh
```

Este script executa todos os passos automaticamente e exibe as informações necessárias ao final.

## Método 2: Instalação Manual (Passo a Passo)

Se preferir executar manualmente, siga os comandos abaixo. **Importante:** Copie e cole cada bloco de código separadamente no Termux.

### 1. Verificar se está no Termux
```bash
if [ ! -d "/data/data/com.termux" ]; then
    echo "❌ Este script deve ser executado no Termux!"
    exit 1
fi
echo "✅ Termux detectado"
```

### 2. Configurar armazenamento
```bash
if [ ! -d "$HOME/storage" ]; then
    termux-setup-storage
    sleep 3
fi
echo "✅ Armazenamento OK"
```

### 3. Corrigir dpkg
```bash
dpkg --configure -a 2>/dev/null || true
```

### 4. Atualizar pacotes
```bash
pkg update -y
```

### 5. Instalar dependências
```bash
pkg install -y openssh python git ncurses-utils curl
```

### 6. Configurar SSH
```bash
mkdir -p "$HOME/.ssh"
if [ ! -f "$HOME/.ssh/id_rsa" ]; then
    ssh-keygen -t rsa -b 2048 -N "" -f "$HOME/.ssh/id_rsa" -C "$(whoami)@termux"
fi
sshd >/dev/null 2>&1
```

### 7. Baixar o projeto
```bash
mkdir -p "$HOME/Projetos"
cd "$HOME/Projetos"
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git cluster-ai
```

### 8. Exibir informações de conexão
```bash
echo "🔑 CHAVE SSH PÚBLICA:"
cat "$HOME/.ssh/id_rsa.pub"
echo ""
echo "🌐 INFORMAÇÕES:"
echo "Usuário: $(whoami)"
echo "IP: $(ip route get 1 | awk '{print $7}' | head -1)"
echo "Porta: 8022"
```

## Próximos Passos

Após executar estes comandos:

1. Copie a chave SSH pública exibida
2. No servidor principal, execute: `./manager.sh`
3. Escolha: Gerenciar Workers Remotos (SSH)
4. Cole a chave SSH quando solicitado
5. Digite o IP do seu Android
6. Porta: 8022

## Teste de Conexão

Para testar a conexão:
```bash
ssh $(whoami)@$(ip route get 1 | awk '{print $7}' | head -1) -p 8022
```

## Notas

- Certifique-se de que o Termux tem permissões de armazenamento concedidas
- Se o download via Git falhar, configure autenticação SSH ou use token do GitHub
