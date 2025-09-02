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

### ❌ SSH não conecta
```bash
# No Termux, verifique se SSH está rodando
sshd

# Teste local
ssh localhost -p 8022
```

### ❌ "Permission denied"
```bash
# Execute novamente a configuração de storage
termux-setup-storage
```

### ❌ Sem internet no Termux
- Verifique se o Wi-Fi está conectado
- Teste: `ping 8.8.8.8`
- Se não funcionar, reinicie o Termux

## 📊 Verificar se Funcionou

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
4. **Abra uma issue no GitHub** com os logs de erro

---

**🎉 Parabéns!** Seu Android agora é parte do Cluster AI! 🚀
