📋 Como Usar Este Script
1. Download do Script
bash
# Baixar o script diretamente
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/install_cluster_ai.sh -o install_cluster_ai.sh
2. Tornar Executável
bash
chmod +x install_cluster_ai.sh
3. Executar
bash
./install_cluster_ai.sh
4. Seguir o Menu Interativo
O script oferece um menu interativo com opções para:

Instalar dependências

Configurar ambiente Python

Configurar SSH

Definir papel da máquina

Fazer backup e restauração

Ver status do sistema

🚀 Funcionalidades Principais
Instalação Automática: Detecta sua distribuição Linux e instala todas as dependências necessárias

Configuração de GPU: Detecta automaticamente GPUs NVIDIA ou AMD e configura o Ollama para melhor desempenho

Sistema de Backup: Backup completo ou parcial com agendamento automático

Múltiplos Papéis: Configura a máquina como servidor, workstation ou worker

Monitoramento: Verifica o status de todos os serviços e componentes

📝 Notas Importantes
O script requer privilégios de sudo para instalar pacotes do sistema

A primeira execução pode levar de 15-30 minutos dependendo da sua conexão com a internet

Os modelos de IA podem ocupar vários GB de espaço em disco

Configure um IP estático para o servidor principal em ambientes de produção

Este script é a maneira mais fácil e completa de instalar e configurar o Cluster AI em qualquer máquina Linux.
