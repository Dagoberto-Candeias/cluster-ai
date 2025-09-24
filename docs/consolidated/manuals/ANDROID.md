# 📱 Guia Completo de Configuração - Worker Android

## 🎯 Visão Geral

Este guia explica como configurar um dispositivo Android (smartphone ou tablet) para atuar como um worker no seu Cluster AI. Isso permite que você aproveite o poder de processamento de dispositivos móveis para tarefas de CPU, expandindo significativamente a capacidade computacional do seu cluster.

## 📋 Pré-requisitos

### Requisitos Mínimos
- **Dispositivo Android**: Versão 7.0 ou superior
- **Armazenamento**: Pelo menos 2GB de espaço livre
- **Memória RAM**: Mínimo 2GB (recomendado 4GB+)
- **Bateria**: Boa condição (recomendado acima de 50%)
- **Conectividade**: Wi-Fi estável na mesma rede do servidor principal

### Software Necessário
- **Termux**: Aplicativo de terminal Linux para Android
  - Download: [F-Droid](https://f-droid.org/packages/com.termux/) (recomendado) ou [Google Play Store](https://play.google.com/store/apps/details?id=com.termux)
  - Versão: 0.118+ (mais recente possível)

### Verificações Pré-Instalação
- ✅ Acesso root: **NÃO** necessário (na verdade, é recomendado NÃO ter root)
- ✅ Google Play Services: Opcional, mas recomendado para melhor compatibilidade
- ✅ Permissões: Acesso a armazenamento e localização (para configuração de rede)

## 🚀 Passo a Passo da Configuração

### Parte 1: Preparação do Dispositivo Android

#### 1. Instalação do Termux
![Instalação do Termux](https://via.placeholder.com/300x200?text=Termux+Installation)

1. Baixe e instale o Termux da F-Droid ou Play Store
2. Abra o aplicativo Termux
3. Execute o comando de configuração inicial:
   ```bash
   termux-setup-storage
   ```
   Isso concede permissões de armazenamento ao Termux

#### 2. Configuração Automática do Worker
![Execução do script de configuração](https://via.placeholder.com/300x200?text=Script+Execution)

Execute o script de configuração automática:
```bash
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker.sh | bash
```

**O que o script faz:**
- ✅ Atualiza os pacotes do Termux
- ✅ Instala dependências: OpenSSH, Python, Git, ncurses-utils
- ✅ Gera chave SSH RSA de 4096 bits
- ✅ Exibe informações de conexão (IP, usuário, porta)

#### 3. Copiando a Chave SSH
![Cópia da chave SSH](https://via.placeholder.com/300x200?text=SSH+Key+Copy)

O script irá pausar e mostrar sua chave pública SSH. **IMPORTANTE:**
- Copie toda a linha que começa com `ssh-rsa`
- Guarde em local seguro (bloco de notas, etc.)
- Não compartilhe esta chave com ninguém

### Parte 2: Registro no Servidor Principal

#### 1. Acesso ao Painel de Controle
![Painel de Controle Manager.sh](https://via.placeholder.com/300x200?text=Manager+Dashboard)

No seu servidor principal:
```bash
cd /caminho/para/cluster-ai
./scripts/management/manager.sh
```

#### 2. Navegação no Menu
1. Selecione: **"Gerenciar Workers Remotos (SSH)"**
2. Escolha: **"Configurar um worker Android (Termux)"**

#### 3. Processo de Registro
![Registro do Worker](https://via.placeholder.com/300x200?text=Worker+Registration)

Siga as instruções na tela:
- **Cole a chave SSH pública** copiada do Termux
- **Nome de usuário**: Geralmente `u0_aXXX` (exibido pelo script)
- **IP/Hostname**: Endereço IP do dispositivo Android
- **Porta**: `8022` (padrão do Termux)

## 🔧 Verificação e Monitoramento

### Verificando Status do Worker
Após o registro, verifique através do manager.sh:

```bash
# Opção: Mostrar status geral
# Resultado esperado: Worker Android na lista de nós remotos
```

### Health Check Detalhado
```bash
# Opção: Executar verificação de saúde (Health Check)
```

**Informações exibidas:**
- 📊 **Nível da bateria**: Percentual atual
- 🖥️ **Uso de CPU**: Porcentagem de utilização
- 🧠 **Memória RAM**: Uso atual e disponível
- 📶 **Conectividade**: Status da rede Wi-Fi
- 🔋 **Temperatura**: Do dispositivo (se disponível)

### Monitoramento Contínuo
O sistema monitora automaticamente:
- Conexão SSH com o worker
- Status da bateria (alerta se abaixo de 20%)
- Uso de recursos do dispositivo
- Disponibilidade do worker

## 📚 Exemplos Práticos de Uso

### Exemplo 1: Processamento de Imagens
```python
# Código executado no worker Android
from PIL import Image
import numpy as np

def processar_imagem(caminho_imagem):
    img = Image.open(caminho_imagem)
    # Processamento distribuído
    return np.array(img).mean()
```

### Exemplo 2: Análise de Dados
```python
# Worker Android processando dados
import pandas as pd

def analisar_dataset(df_chunk):
    # Análise em paralelo
    return df_chunk.describe()
```

### Exemplo 3: Treinamento de Modelo
```python
# Treinamento distribuído
import torch
import torch.nn as nn

def treinar_modelo(dados_treinamento):
    modelo = nn.Linear(10, 1)
    # Treinamento no worker Android
    return modelo
```

## ❓ Perguntas Frequentes (FAQ)

### 🔌 Problemas de Conectividade
**Q: O worker não conecta via SSH**
- Verifique se ambos dispositivos estão na mesma rede Wi-Fi
- Confirme se a porta 8022 não está bloqueada pelo firewall
- Teste: `ssh user@ip -p 8022` do servidor principal

**Q: "Connection refused" ao tentar conectar**
- Certifique-se de que o SSH está rodando no Termux: `sshd`
- Verifique o IP do dispositivo Android
- Confirme que a chave SSH foi adicionada corretamente

### 🔋 Problemas de Bateria
**Q: Worker desconecta quando bateria está baixa**
- Configure limite mínimo de bateria no manager.sh
- Mantenha dispositivo carregando durante uso intensivo
- Use modo de economia de energia do Android

**Q: Sobreaquecimento do dispositivo**
- Monitore temperatura através do health check
- Reduza carga de trabalho se temperatura > 40°C
- Use cooler ou superfície fresca

### 📱 Problemas Específicos do Android
**Q: Termux para de funcionar em background**
- Configure "Don't kill app" nas configurações do Android
- Use aplicativo "Termux:Boot" para iniciar automaticamente
- Evite fechar o Termux manualmente

**Q: Permissões negadas**
- Execute `termux-setup-storage` novamente
- Conceda permissões manuais no Android Settings > Apps > Termux
- Reinicie o dispositivo se necessário

### 🔧 Problemas Gerais
**Q: Worker aparece offline no cluster**
- Execute health check manual: `./manager.sh > Health Check`
- Verifique logs: `tail -f logs/cluster.log`
- Teste conectividade: `ping <android_ip>`

**Q: Lentidão no processamento**
- Verifique uso de CPU/memória no health check
- Feche outros aplicativos no Android
- Considere adicionar mais workers Android

## 🗑️ Removendo/Desregistrando um Worker Android

### Método 1: Via Manager.sh (Recomendado)
1. Execute `./scripts/management/manager.sh`
2. Selecione "Gerenciar Workers Remotos (SSH)"
3. Escolha "Remover worker"
4. Selecione o worker Android da lista
5. Confirme a remoção

### Método 2: Remoção Manual
1. No servidor principal, edite `~/.cluster_config/nodes_list.conf`
2. Remova a linha correspondente ao worker Android
3. Remova a chave SSH do `~/.ssh/authorized_keys`
4. Reinicie o cluster se necessário

### Limpeza no Dispositivo Android
```bash
# No Termux do dispositivo Android
# Parar serviços
pkill sshd
pkill python

# Remover arquivos do projeto (opcional)
rm -rf ~/Projetos/cluster-ai

# Remover chave SSH (opcional, para segurança)
rm -f ~/.ssh/id_rsa*
```

## 📊 Limitações Conhecidas

### Hardware
- **CPU**: Limitado ao processador do dispositivo móvel
- **GPU**: Geralmente indisponível para processamento geral
- **Memória**: Limitada pela RAM do dispositivo
- **Armazenamento**: Restrito ao espaço interno do Android

### Software
- **Termux**: Dependente de atualizações do aplicativo
- **Compatibilidade**: Algumas bibliotecas podem não funcionar perfeitamente
- **Background**: Limitações do Android em execução em background

### Rede
- **Wi-Fi**: Dependente da qualidade da conexão local
- **Mobilidade**: Worker deve permanecer na mesma rede
- **Latência**: Pode ser maior que workers locais

## 🔧 Troubleshooting Avançado

### Logs e Diagnóstico
```bash
# Ver logs do cluster
tail -f logs/cluster.log

# Ver logs específicos do Android worker
grep "android" logs/cluster.log

# Teste de conectividade detalhado
ssh -v user@android_ip -p 8022
```

### Configurações Avançadas
```bash
# Arquivo de configuração do worker
~/.cluster_config/worker_android.conf

# Configurações de monitoramento
battery_threshold=20
cpu_limit=80
memory_limit=90
```

### Suporte e Ajuda
- 📧 **Issues**: [GitHub Issues](https://github.com/Dagoberto-Candeias/cluster-ai/issues)
- 📖 **Documentação**: [Documentação Completa](../README.md)
- 💬 **Discussões**: [GitHub Discussions](https://github.com/Dagoberto-Candeias/cluster-ai/discussions)

---

**💡 Dica**: Para melhor performance, use dispositivos Android com pelo menos 4GB RAM e mantenha-os carregando durante o uso como workers do cluster.
