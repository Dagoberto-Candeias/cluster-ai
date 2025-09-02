# 🚀 Guia Rápido - Worker Android (Fácil)

## Sumário
- [Pré-requisitos](#pré-requisitos)
- [Instalação Passo a Passo](#instalação-passo-a-passo)
- [Solução de Problemas](#solução-de-problemas)
- [Instalação Offline](#instalação-offline-último-recurso)
- [Checklist Final](#checklist-final)
- [Contato/Suporte](#contato-suporte)

---

## 📋 Pré-requisitos

- Dispositivo Android com Termux instalado ([F-Droid](https://f-droid.org/packages/com.termux/) ou Google Play)
- Conexão Wi-Fi estável
- Pelo menos 20% de bateria
- Acesso ao seu repositório privado no GitHub (via SSH ou Token)

---

## 🛠️ Instalação Passo a Passo

### 1. Preparar o Termux
```bash
termux-setup-storage
```
Conceda as permissões solicitadas.

### 2. Instalar Dependências
```bash
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

---

Pronto!  
Seu Android estará integrado ao Cluster AI como worker.  
Se encontrar problemas, siga as dicas de solução ou entre em contato
