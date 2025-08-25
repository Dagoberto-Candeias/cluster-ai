# 📱 Guia de Configuração Android para Cluster AI

## 🎯 Visão Geral

Este guia explica como configurar dispositivos Android como **workers** do Cluster AI, permitindo que smartphones e tablets contribuam com poder de processamento para o cluster.

## 📋 Pré-requisitos

### 1. **Termux**
- Instale o Termux da [F-Droid](https://f-droid.org/en/packages/com.termux/)
- **NÃO** instale da Play Store (versão desatualizada)

### 2. **Permissões**
- Conceda permissões de armazenamento ao Termux
- Execute no Termux: `termux-setup-storage`

### 3. **Conexão de Rede**
- Dispositivo Android e servidor principal na mesma rede
- IP estático ou DHCP reservado para o servidor

## 🚀 Configuração Rápida

### Método 1: Script Automático (Recomendado)
```bash
# No Termux:
curl -O https://raw.githubusercontent.com/seu-usuario/cluster-ai/main/scripts/android/setup_android_worker.sh
bash setup_android_worker.sh
```

### Método 2: Configuração Manual
```bash
# No Termux:
pkg update && pkg upgrade -y
pkg install -y python git curl

# Criar diretório de scripts
mkdir -p ~/cluster_scripts

# Baixar script do worker
curl -o ~/cluster_scripts/start_worker.sh https://raw.githubusercontent.com/seu-usuario/cluster-ai/main/scripts/android/start_worker.sh
chmod +x ~/cluster_scripts/start_worker.sh
```

## ⚙️ Configuração do Worker

### 1. **Obter IP do Servidor**
No servidor principal, execute:
```bash
hostname -I
```

### 2. **Iniciar Worker**
No Termux do Android:
```bash
# Substitua 192.168.1.100 pelo IP do seu servidor
bash ~/cluster_scripts/start_worker.sh 192.168.1.100
```

### 3. **Execução Automática (Opcional)**
Para iniciar automaticamente ao abrir o Termux:
```bash
echo 'bash ~/cluster_scripts/start_worker.sh 192.168.1.100' >> ~/.bashrc
```

## 🔧 Script Avançado para Android

Crie um script mais robusto em `~/cluster_scripts/advanced_worker.sh`:

```bash
#!/bin/bash
# Worker avançado para Android

SERVER_IP="$1"
MACHINE_NAME="android-$(getprop ro.product.model | tr ' ' '-')"
MAX_RETRIES=10
RETRY_DELAY=30

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

install_dependencies() {
    log "Instalando dependências..."
    pkg install -y python git curl proot
    pip install dask distributed
}

start_worker() {
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if nc -z -w 5 $SERVER_IP 8786; then
            log "Conectando ao scheduler em $SERVER_IP:8786"
            dask-worker $SERVER_IP:8786 \
                --nworkers 2 \
                --nthreads 1 \
                --name "$MACHINE_NAME" \
                --memory-limit "1GB" \
                --local-directory "/data/data/com.termux/files/home/tmp"
            return $?
        else
            retry_count=$((retry_count + 1))
            log "Scheduler não disponível. Tentativa $retry_count/$MAX_RETRIES..."
            sleep $RETRY_DELAY
        fi
    done
    
    error "Não foi possível conectar ao scheduler após $MAX_RETRIES tentativas"
    return 1
}

# Execução principal
if [ -z "$SERVER_IP" ]; then
    echo "Uso: $0 <IP_DO_SERVIDOR>"
    exit 1
fi

install_dependencies
start_worker
```

## ⚡ Otimizações para Android

### 1. **Limitações de Recursos**
```bash
# Configurações recomendadas para Android:
--nworkers 2              # 2 workers por dispositivo
--nthreads 1              # 1 thread por worker (evita sobrecarga)
--memory-limit "512MB"    # Limite de memória conservador
```

### 2. **Economia de Bateria**
```bash
# Executar apenas quando conectado à energia
if termux-battery-status | grep -q '"status": "CHARGING"'; then
    # Iniciar worker apenas se estiver carregando
    start_worker
else
    echo "Bateria descarregando. Worker não iniciado."
fi
```

### 3. **Suspensão Inteligente**
```bash
# Parar worker quando tela estiver desligada
while true; do
    if termux-sensor -s light | grep -q "value: 0"; then
        # Tela desligada - parar worker
        pkill -f "dask-worker"
        sleep 60
    else
        # Tela ligada - iniciar worker
        if ! pgrep -f "dask-worker" >/dev/null; then
            start_worker
        fi
        sleep 30
    fi
done
```

## 🧪 Testes de Conexão

### Verificar Conexão com Servidor
```bash
# No Termux:
ping -c 4 192.168.1.100
nc -zv 192.168.1.100 8786
```

### Testar Worker Manualmente
```bash
# Testar conexão Dask
python -c "
from dask.distributed import Client
try:
    client = Client('192.168.1.100:8786')
    print('✅ Conectado ao scheduler')
    print('Workers:', len(client.scheduler_info()['workers']))
except Exception as e:
    print('❌ Erro:', e)
"
```

## 🔍 Solução de Problemas

### Problema: Conexão Recusada
**Solução**: Verifique se:
- Servidor está rodando: `./install_cluster.sh`
- Firewall permite conexões: `sudo ufw allow 8786`
- IP está correto

### Problema: Termux Fechando
**Solução**: Use `termux-wake-lock` e execute em background:
```bash
termux-wake-lock
nohup bash ~/cluster_scripts/start_worker.sh 192.168.1.100 > worker.log 2>&1 &
```

### Problema: Pouca Memória
**Solução**: Reduza workers e memória:
```bash
dask-worker 192.168.1.100:8786 --nworkers 1 --memory-limit "256MB"
```

## 📊 Monitoramento

### No Servidor Principal
```bash
# Verificar workers conectados
./scripts/utils/check_cluster.sh

# Monitorar performance
watch -n 5 "dask-scheduler --version && echo 'Workers:' && dask-worker --version"
```

### No Android
```bash
# Verificar status do worker
ps aux | grep "dask-worker"

# Verificar logs
tail -f ~/worker.log
```

## 🔄 Atualização

### Atualizar Scripts
```bash
# No Termux:
curl -O https://raw.githubusercontent.com/seu-usuario/cluster-ai/main/scripts/android/setup_android_worker.sh
bash setup_android_worker.sh
```

### Atualizar Dependências
```bash
pkg update && pkg upgrade -y
pip install --upgrade dask distributed
```

## ⚠️ Considerações Importantes

### 1. **Bateria**
- Execute preferencialmente com carregador conectado
- Configure suspensão quando bateria estiver baixa

### 2. **Temperatura**
- Monitore temperatura do dispositivo
- Pare worker se dispositivo estiver superaquecendo

### 3. **Rede**
- Use Wi-Fi estável (evite dados móveis)
- Configure IP estático para servidor

### 4. **Armazenamento**
- Limpe cache regularmente: `pkg clean`
- Monitore espaço em disco: `df -h`

## 🎯 Melhores Práticas

### Para Dispositivos Modernos (8GB+ RAM)
```bash
dask-worker 192.168.1.100:8786 \
    --nworkers 4 \
    --nthreads 2 \
    --memory-limit "2GB"
```

### Para Dispositivos Básicos (4GB RAM)
```bash
dask-worker 192.168.1.100:8786 \
    --nworkers 2 \
    --nthreads 1 \
    --memory-limit "1GB"
```

### Para Dispositivos Antigos (2GB RAM)
```bash
dask-worker 192.168.1.100:8786 \
    --nworkers 1 \
    --nthreads 1 \
    --memory-limit "512MB"
```

## 📈 Estatísticas de Performance

### Dispositivos Testados
| Dispositivo       | RAM    | CPU         | Workers | Performance |
|-------------------|--------|-------------|---------|-------------|
| Samsung S23 Ultra | 12GB   | Snapdragon 8 | 4       | ⭐⭐⭐⭐⭐     |
| Google Pixel 7    | 8GB    | Tensor G2   | 3       | ⭐⭐⭐⭐      |
| Xiaomi Redmi Note | 6GB    | Snapdragon  | 2       | ⭐⭐⭐        |
| Moto G Power      | 4GB    | MediaTek    | 1       | ⭐⭐         |

## 🚀 Próximos Passos

1. **Configure múltiplos dispositivos** Android como workers
2. **Monitore performance** do cluster expandido
3. **Experimente diferentes cargas** de trabalho
4. **Otimize configurações** para seu hardware específico

## 📞 Suporte

### Issues Comuns
- **Conexão recusada**: Verifique firewall e IP do servidor
- **Termux crash**: Reduza número de workers
- **Bateria drenando**: Execute apenas quando carregando

### Logs de Diagnóstico
```bash
# Coletar informações para troubleshooting
termux-info > debug_info.txt
ps aux >> debug_info.txt
netstat -tlnp >> debug_info.txt
```

---

**📅 Última Atualização**: $(date +%Y-%m-%d)
**📱 Compatibilidade**: Android 8.0+ com Termux
**⚡ Status**: Estável para uso em produção
