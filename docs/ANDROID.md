# Guia de Configuração para Android (Termux)

## Visão Geral
Este guia explica como configurar workers em dispositivos Android usando Termux para expandir seu cluster AI com recursos móveis.

## Pré-requisitos
- Dispositivo Android com Android 7.0+
- Termux instalado (Google Play Store ou F-Droid)
- Conexão Wi-Fi estável
- Pelo menos 4GB RAM livre

## Instalação Automática (Plug-and-Play)
```bash
# One-command setup:
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/termux_worker_setup.sh | bash
```

Este comando irá:
1. Instalar dependências (Python, SSH, Git)
2. Configurar SSH para conexão segura
3. Baixar e configurar Dask worker
4. Registrar worker no cluster principal

## Instalação Manual
Se preferir controle manual:

### 1. Instalar Termux e Dependências
```bash
# Atualizar pacotes
pkg update && pkg upgrade

# Instalar Python e ferramentas
pkg install python git openssh

# Instalar pip e dependências
pip install --upgrade pip
pip install dask distributed paramiko
```

### 2. Configurar SSH
```bash
# Gerar chave SSH
ssh-keygen -t rsa -b 4096 -C "android-worker"

# Copiar chave pública para servidor principal
# (substitua IP_SERVIDOR pelo IP do seu servidor)
ssh-copy-id -p 22 user@IP_SERVIDOR

# Testar conexão
ssh -T user@IP_SERVIDOR
```

### 3. Configurar Worker Dask
```bash
# Clonar repositório (opcional, para scripts)
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
cd cluster-ai

# Iniciar worker
dask-worker tcp://IP_SERVIDOR:8786 \
  --name android-worker-$(hostname) \
  --nthreads 2 \
  --memory-limit 2GB \
  --no-dashboard
```

## Gerenciamento de Workers
```bash
# Verificar status no servidor principal
./scripts/management/worker_manager.sh list

# Reiniciar worker remotamente
./scripts/management/worker_manager.sh update-all

# Monitorar recursos
./scripts/monitoring/advanced_dashboard.sh live
```

## Otimização para Android
- **Bateria**: Use carregador para evitar throttling
- **Rede**: Wi-Fi 5GHz para melhor performance
- **Armazenamento**: Mantenha pelo menos 2GB livre
- **Temperatura**: Evite uso prolongado para prevenir overheating

## Solução de Problemas
```bash
# Verificar logs do worker
tail -f ~/.dask-worker.log

# Reiniciar serviços
pkill -f dask-worker
# Reinicie o comando do worker

# Verificar conectividade
ping IP_SERVIDOR
ssh -T user@IP_SERVIDOR
```

## Limitações
- Performance limitada por hardware móvel
- Não recomendado para tarefas pesadas de GPU
- Dependente de conectividade de rede estável
- Bateria pode limitar uptime

## Próximos Passos
- Configure múltiplos dispositivos Android
- Teste com tarefas leves de ML
- Monitore performance via dashboard
- Considere workers Linux dedicados para cargas pesadas
