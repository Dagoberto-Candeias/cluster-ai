# 🚀 Guia Rápido - Worker Android (Fácil)

## 📱 Instalação em 5 Minutos

### Passo 1: Instalar Termux
1. Baixe o **Termux** da F-Droid ou Google Play
2. Abra o aplicativo
3. Execute: `termux-setup-storage`
4. Conceda as permissões solicitadas

### Passo 2: Executar Instalação Automática
```bash
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker_simple.sh | bash
```

**O que acontece:**
- ✅ Atualiza pacotes automaticamente
- ✅ Instala SSH, Python e Git
- ✅ Configura servidor SSH
- ✅ Baixa o projeto Cluster AI
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

### ❌ Erro 400 ou falha no download
```bash
# Tente baixar o script primeiro
curl -O https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker_simple.sh

# Depois execute
bash setup_android_worker_simple.sh
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
