# 🚀 Guia Rápido - Worker Android

## Sumário
- [Pré-requisitos](#pré-requisitos)
- [Método 1: Instalação Automática (Recomendado)](#método-1-instalação-automática-recomendado)
- [Método 2: Descoberta Automática pelo Servidor](#método-2-descoberta-automática-pelo-servidor)
- [Método 3: Instalação Manual (Avançado)](#método-3-instalação-manual-avançado)
- [Desinstalação](#desinstalação)
- [Solução de Problemas](#solução-de-problemas)
- [Checklist Final](#checklist-final)
- [Contato/Suporte](#contato-suporte)

---

## 📋 Pré-requisitos

- Dispositivo Android com **Termux** instalado (recomendado via [F-Droid](https://f-droid.org/packages/com.termux/)).
- Conexão Wi-Fi estável (o Android e o servidor devem estar na mesma rede).
- Pelo menos 20% de bateria

---

## 🚀 Método 1: Instalação Automática (Recomendado)

Este método configura o worker Android com um único comando.

1.  **No seu dispositivo Android, abra o Termux e execute:**
    ```bash
    curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker.sh | bash
    ```

    > **Nota de Segurança**: O comando `curl | bash` é conveniente, mas executa um script diretamente da internet. Para maior segurança, você pode clonar o repositório primeiro e executar o script localmente:
    > ```bash
    > git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
    > bash cluster-ai/scripts/android/setup_android_worker.sh
    > ```

2.  O script irá:
    - Instalar todas as dependências necessárias (Git, Python, OpenSSH).
    - Gerar uma chave SSH para comunicação com o servidor.
    - Clonar o repositório do `cluster-ai`.
    - Iniciar o serviço SSH na porta 8022.
    - Exibir as informações necessárias para registrar o worker no servidor.

3.  **No servidor principal, siga as instruções exibidas no Termux**: Use o `manager.sh` para adicionar o worker, informando o IP e a chave pública que o script forneceu.

---

## 🔍 Método 2: Descoberta Automática pelo Servidor

Se o seu dispositivo Android já possui o Termux e o OpenSSH instalados, você pode usar a descoberta automática do servidor.

1.  **No Termux, instale e inicie o `sshd`:**
    ```bash
    pkg install openssh
    sshd
    ```

2.  **No servidor principal, execute o `manager.sh`:**
    ```bash
    ./manager.sh
    ```
    - Escolha a opção "Gerenciar Workers Remotos (SSH)".
    - Selecione "Executar Descoberta Automática".
    - O sistema irá escanear a rede, encontrar seu dispositivo Android e guiar você na configuração.

---

## 🛠️ Método 3: Instalação Manual (Avançado)

Use este método apenas se a instalação automática falhar.

### 1. Preparar o Termux e Dependências
```bash
termux-setup-storage
pkg update -y
pkg install -y openssh python git curl unzip
```

### 3. Configurar Autenticação com GitHub (para repositórios privados)

#### Opção 1: SSH (Recomendado)
```bash
ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub
```
Copie a chave pública e adicione em [GitHub > Settings > SSH keys](https://github.com/settings/keys).

#### Opção 2: Token de Acesso Pessoal
- Gere um token em [GitHub Tokens](https://github.com/settings/tokens) com permissão "repo".
- Use para clonar:
  ```bash
  git clone https://TOKEN@github.com/Dagoberto-Candeias/cluster-ai.git
  ```

### 4. Baixar o Projeto

#### Método Git (recomendado)
```bash
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
cd cluster-ai
```
Se for privado, use o SSH após configurar a chave.

#### Método ZIP (offline/manual)
```bash
curl -L -o cluster-ai.zip https://github.com/Dagoberto-Candeias/cluster-ai/archive/main.zip
unzip cluster-ai.zip
mv cluster-ai-main cluster-ai
rm cluster-ai.zip
cd cluster-ai
```

### 5. Iniciar o SSHD no Termux
```bash
sshd
```
- Porta padrão: **8022**
- Descubra seu IP local:
  ```bash
  ip addr show wlan0
  ```

### 6. Registrar Worker no Servidor Principal
No servidor principal (Linux/VS Code):
```bash
cd /caminho/para/cluster-ai
./manager.sh
```
Escolha "Gerenciar Workers Remotos (SSH)", cole a chave SSH, informe IP e porta (8022).

### 7. Testar Conexão
No servidor principal:
```bash
ssh <usuario>@<ip_do_android> -p 8022
ssh <usuario>@<ip_do_android> -p 8022 "echo 'Worker Android conectado!'"
```
No Termux, o usuário padrão é o nome exibido no prompt (ex: `u0_a249`).

---

## 🗑️ Desinstalação

### Desinstalação Completa (Recomendado)
```bash
# No Termux do dispositivo Android
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/uninstall_android_worker.sh | bash
```

### Desinstalação Manual
```bash
# Parar serviços
pkill sshd
pkill python

# Remover projeto
rm -rf ~/Projetos/cluster-ai

# Remover chaves SSH (opcional)
rm -rf ~/.ssh

# Limpar cache e dados
rm -rf ~/.cache/cluster-ai
rm -rf ~/.local/share/cluster-ai
```

### Remover do Servidor Principal
```bash
# No servidor principal
./manager.sh
# Escolha: "Gerenciar Workers Remotos (SSH)"
# Escolha: "Remover worker"
# Selecione o worker Android
```

### Desinstalação via Menu Unificado
```bash
# No servidor principal (para todos os tipos)
./scripts/maintenance/uninstall_master.sh
# Escolha: "📱 Desinstalar Worker Android (Termux)"
```

---

## 🆘 Solução de Problemas

- Execute novamente `termux-setup-storage` se houver erro de permissão.
- Configure SSH ou Token se o clone do repositório falhar.
- Teste SSH local:  
  ```bash
  ssh localhost -p 8022
  ```
- Verifique conexão Wi-Fi:  
  ```bash
  ping 8.8.8.8
  ```
- Se não conseguir clonar, baixe o ZIP e extraia manualmente.

---

## 📦 Instalação Offline (Último Recurso)

1. Baixe o ZIP do projeto no computador.
2. Transfira para o Android.
3. Extraia e execute:
   ```bash
   unzip cluster-ai.zip
   mv cluster-ai-main cluster-ai
   cd cluster-ai
   ```

---

## ✅ Checklist Final

- [ ] Termux instalado e com permissões de armazenamento
- [ ] Dependências instaladas
- [ ] Projeto baixado com sucesso
- [ ] Chave SSH copiada e registrada no GitHub
- [ ] Worker aparece no painel do servidor principal
- [ ] Teste SSH funciona

---

## 📧 Contato/Suporte

Dúvidas?  
Abra uma issue em [github.com/Dagoberto-Candeias/cluster-ai/issues](https://github.com/Dagoberto-Candeias/cluster-ai/issues)  
ou envie e-mail para: betoallnet@gmail.com

---

# Resumo Prático dos Comandos

## Instalação

1. **Configurar armazenamento:**
   ```bash
   termux-setup-storage
   ```

2. **Instalar dependências:**
   ```bash
   pkg update -y
   pkg install -y openssh python git curl unzip
   ```

3. **Gerar chave SSH (se necessário):**
   ```bash
   ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/id_rsa
   cat ~/.ssh/id_rsa.pub
   ```

4. **Clonar o repositório:**
   ```bash
   git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
   cd cluster-ai
   ```

5. **Iniciar SSHD:**
   ```bash
   sshd
   ```

6. **Descobrir IP local:**
   ```bash
   ip addr show wlan0
   ```

7. **No servidor principal, registrar e testar o worker:**
   ```bash
   ./manager.sh
   ssh <usuario>@<ip_do_android> -p 8022
   ```

## Desinstalação

8. **Desinstalação completa:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/uninstall_android_worker.sh | bash
   ```

9. **Remover do servidor principal:**
   ```bash
   ./manager.sh
   # Menu: Gerenciar Workers Remotos (SSH) > Remover worker
   ```

---

Pronto!  
Seu Android estará integrado ao Cluster AI como worker.  
Se encontrar problemas, siga as dicas de solução ou entre em contato
