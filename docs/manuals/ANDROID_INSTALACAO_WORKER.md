# Instalação do Worker no Android

Este guia fornece uma lista sequencial de comandos para instalar um worker no Android usando o Termux.

## Pré-requisitos

- Dispositivo Android com Termux instalado
- Conexão com a internet

## Lista Sequencial de Comandos

**Importante:** Copie e cole cada bloco de código separadamente no Termux. Não copie múltiplos blocos de uma vez, pois pode causar erros de sintaxe.

Execute os comandos abaixo em sequência no Termux:

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
