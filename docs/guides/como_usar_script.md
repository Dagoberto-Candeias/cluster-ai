📋 Como Usar Este Script

## 1. Download do Script

### Opção A: Se você já clonou o repositório
```bash
# Executar script local diretamente
./install_cluster.sh
```

### Opção B: Download do GitHub
```bash
# Baixar o script principal
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/installation/main.sh -o install_cluster.sh

# Tornar executável
chmod +x install_cluster.sh

# Executar
./install_cluster.sh
```

## 2. Seguir o Menu Interativo
O script oferece um menu interativo com opções para:

- Instalar dependências do sistema
- Configurar ambiente Python
- Configurar Docker e Ollama
- Definir papel da máquina (servidor, workstation, worker)
- Fazer backup e restauração
- Ver status do sistema
- Agendar backups automáticos

## 🚀 Funcionalidades Principais

- **Instalação Automática**: Detecta sua distribuição Linux e instala todas as dependências necessárias
- **Configuração de GPU**: Detecta automaticamente GPUs NVIDIA ou AMD e configura o Ollama para melhor desempenho
- **Sistema de Backup**: Backup completo ou parcial com agendamento automático
- **Múltiplos Papéis**: Configura a máquina como servidor, workstation ou worker
- **Monitoramento**: Verifica o status de todos os serviços e componentes

## 📝 Notas Importantes

- O script requer privilégios de sudo para instalar pacotes do sistema
- A primeira execução pode levar de 15-30 minutos dependendo da sua conexão com a internet
- Os modelos de IA podem ocupar vários GB de espaço em disco
- Configure um IP estático para o servidor principal em ambientes de produção
- Consulte [INSTALACAO_LOCAL.md](../INSTALACAO_LOCAL.md) para mais detalhes sobre instalação local

Este script é a maneira mais fácil e completa de instalar e configurar o Cluster AI em qualquer máquina Linux.
