# ⚙️ Guia de Configuração Avançada - Cluster AI

## 🎯 Visão Geral

Este guia fornece instruções sobre como configurar o Cluster AI para atender a necessidades específicas e otimizar seu desempenho em diferentes ambientes.

## 📋 Pré-requisitos

Antes de começar, certifique-se de que você já instalou o Cluster AI seguindo o [Guia de Instalação](INSTALACAO.md).

## 🚀 Configurações Comuns

### 1. Configuração de Rede

Para ambientes de produção, é recomendável configurar um IP estático para o servidor principal. Isso garante que o servidor sempre tenha o mesmo endereço IP, facilitando a conexão de outros nós.

#### Exemplo de Configuração de IP Estático (Ubuntu)
```bash
# Editar o arquivo de configuração de rede
sudo nano /etc/netplan/01-netcfg.yaml

# Adicionar as seguintes linhas
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 8.8.4.4
```

### 2. Configuração de TLS

Para garantir a segurança da comunicação entre os serviços, é importante configurar TLS. Consulte o guia de [Deploy Production](deployments/production/README.md) para instruções detalhadas.

### 3. Configurações do Ollama

Ollama pode ser configurado para usar diferentes modelos e ajustar o uso de GPU. Edite o arquivo de configuração localizado em `~/.ollama/config.json` para personalizar as opções.

#### Exemplo de Configuração
```json
{
    "runners": {
        "nvidia": {
            "url": "https://github.com/ollama/ollama/blob/main/gpu/nvidia/runner.cu"
        }
    },
    "models": {
        "llama3": {
            "gpu_layers": 20,
            "num_gpu": 1
        }
    }
}
```

### 4. Configurações do Dask

Para otimizar o desempenho do Dask, você pode ajustar o número de workers e threads. Isso pode ser feito no script de inicialização ou diretamente no código.

#### Exemplo de Configuração
```python
from dask.distributed import Client

# Conectar ao cluster
client = Client(n_workers=4, threads_per_worker=2)
```

## 🔄 Ajustes de Performance

### 1. Ajuste de Swappiness

Para sistemas com SSD, é recomendável ajustar o valor de swappiness para evitar o uso excessivo de swap.

```bash
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 2. Configurações de I/O

Ajuste as opções de montagem para otimizar o desempenho de leitura e gravação em SSDs.

```bash
# Editar fstab
sudo nano /etc/fstab

# Adicionar opções para SSDs
UUID=xxxx-xxxx / ext4 defaults,noatime,nodiratime,discard 0 1
```

## 📈 Monitoramento e Logs

### 1. Logs do Sistema

Os logs do sistema podem ser encontrados em `~/.cluster_optimization/optimization.log`. Verifique este arquivo para monitorar o desempenho e identificar problemas.

### 2. Monitoramento de Recursos

Use ferramentas como `htop`, `glances` e `nvidia-smi` para monitorar o uso de CPU, memória e GPU em tempo real.

## 🚨 Solução de Problemas

Se você encontrar problemas durante a configuração, consulte o [Guia de Solução de Problemas](TROUBLESHOOTING.md) para obter assistência.

---

**🎉 Parabéns!** Você configurou com sucesso o Cluster AI. Agora você pode começar a explorar suas funcionalidades avançadas!

**💡 Dica**: Mantenha a documentação atualizada conforme você faz alterações nas configurações.
