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

### 2. Configurar Autenticação com GitHub (para repositórios privados)
```bash
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_github_auth.sh | bash
```
Siga as instruções do script para configurar SSH ou Token.

### 3. Instalar Dependências
```bash
pkg update -y
pkg install -y openssh python git curl
```

### 4. Baixar o Projeto (método automático)
```bash
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker_robust.sh | bash
```
Se falhar, tente o método simples:
```bash
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker_simple.sh | bash
```

### 5. Copiar Chave SSH
O script exibirá sua chave pública.  
Copie tudo e adicione em [GitHub SSH Keys](https://github.com/settings/keys).

### 6. Registrar Worker no Servidor Principal
No servidor principal:
```bash
cd /caminho/para/cluster-ai
./manager.sh
```
Escolha "Gerenciar Workers Remotos (SSH)", cole a chave SSH, informe IP e porta (8022).

### 7. Testar Conexão
No servidor principal:
```bash
ssh usuario@ip_do_android -p 8022
ssh usuario@ip_do_android -p 8022 "echo 'Worker Android conectado!'"
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

---

## 📦 Instalação Offline (Último Recurso)

1. Baixe o ZIP do projeto no computador.
2. Transfira para o Android.
3. Extraia e execute:
   ```bash
   cd cluster-ai
   bash scripts/android/setup_android_worker_simple.sh
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
   pkg install -y openssh python git curl
   ```

3. **Configurar autenticação GitHub:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_github_auth.sh | bash
   ```

4. **Instalar o worker Android (automático):**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker_robust.sh | bash
   ```

5. **Se falhar, tente o método simples:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker_simple.sh | bash
   ```

6. **Copie a chave SSH exibida e registre no GitHub.**

7. **No servidor principal, registre o worker e teste a conexão:**
   ```bash
   ./manager.sh
   ssh usuario@ip_do_android -p 8022
   ```

---

Pronto!  
Seu Android estará integrado ao Cluster AI como worker.  
Se encontrar problemas, siga as dicas de solução ou entre em contato
