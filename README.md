# 🚀 Cluster AI - Sistema Universal de IA Distribuída

[![License: MIT](https://img.shields.io/github/license/Dagoberto-Candeias/cluster-ai)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
![Status](https://img.shields.io/badge/status-ativo-success)

Sistema integrado para implantação de clusters de IA com processamento distribuído usando **Dask**, **Ollama** e **OpenWebUI**. O projeto é gerenciado por um painel de controle centralizado (`manager.sh`) que simplifica todas as operações.

## 📋 Índice

- ✨ Funcionalidades
- 🚀 Instalação
- 🛠️ Uso (Painel de Controle)
- 🏗️ Arquitetura
- 📚 Documentação Completa
- 🤝 Contribuição
- 📄 Licença

## ✨ Funcionalidades

-   **🤖 Processamento Distribuído**: Cluster Dask para computação paralela e escalável.
-   **🧠 Modelos de IA Locais**: Ollama integrado para executar LLMs localmente, com otimização para GPU (NVIDIA/AMD).
-   **🌐 Interface Web**: OpenWebUI para interagir com os modelos de forma intuitiva.
-   **🛠️ Painel de Controle Centralizado**: Script `manager.sh` para gerenciar todos os serviços, backups, otimizações e configurações.
-   **📦 Instalação Automatizada**: Detecção de hardware para sugerir o papel do nó (Servidor, Worker) e instalação não interativa.
-   **🩺 Diagnóstico e Manutenção**: Ferramentas de health check, otimização de recursos e relatórios de performance.
-   **💾 Backup e Restauração**: Sistema completo para backup e restauração de configurações, modelos e dados de containers.
-   **☁️ Gerenciamento Remoto**: Controle workers remotos via SSH, execute comandos, inicie e pare serviços.

## 🚀 Instalação

A instalação é projetada para ser simples e flexível.

1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
    cd cluster-ai
    ```

2.  **Execute o instalador principal:**
    ```bash
    bash install.sh
    ```

O instalador irá:
-   Verificar os pré-requisitos do sistema.
-   Detectar seu hardware e sugerir um papel para o nó (Servidor Principal, Worker GPU, etc.).
-   Guiá-lo através de um menu interativo para uma instalação completa ou customizada.

Para **instalação automatizada** (sem prompts), use a flag `--auto-role`:
```bash
bash install.sh --auto-role
```

## 🛠️ Uso (Painel de Controle)

O coração do projeto é o `manager.sh`. Ele oferece um menu interativo para controlar todos os aspectos do cluster.

**Para iniciar o painel de controle:**
```bash
./manager.sh
```

**Principais funcionalidades do painel:**
-   **Ações em Massa**: Iniciar, parar e reiniciar todos os serviços de uma vez.
-   **Gerenciamento Individual**: Controle fino sobre Ollama, Dask e OpenWebUI.
-   **Workers Remotos**: Adicione, configure, inicie, pare e execute comandos em nós remotos.
-   **Diagnóstico**: Execute health checks, gere relatórios de performance e verifique a qualidade do código.
-   **Manutenção**: Gerencie backups, restaure o sistema, atualize o projeto via Git e rotacione logs.
-   **Otimização**: Otimize os recursos do nó local e dos workers remotos com base no hardware detectado.

## 🏗️ Arquitetura

O sistema é modular, permitindo que diferentes máquinas assumam papéis específicos.

-   **Servidor Principal**: Hospeda o Dask Scheduler, a API do Ollama e a interface OpenWebUI. Centraliza o gerenciamento.
-   **Worker (GPU/CPU)**: Executa os processos `dask-worker` para realizar as tarefas de computação. Pode ou não ter uma GPU.
-   **Estação de Trabalho**: Um worker que também possui ferramentas de desenvolvimento (IDEs) instaladas.

| Serviço        | Porta   | Protocolo | Descrição                  |
| -------------- | ------- | --------- | -------------------------- |
| Dask Scheduler | 8786    | TCP       | Coordenação do cluster     |
| Dask Dashboard | 8787    | TCP       | Monitoramento web do Dask  |
| OpenWebUI      | 3000    | TCP       | Interface web para modelos |
| Ollama API     | 11434   | TCP       | API dos modelos de IA      |
| SSH            | 22      | TCP       | Acesso remoto para workers |

## 📚 Documentação Completa

A documentação detalhada está no diretório `docs/`.

-   **Índice da Documentação**: Ponto de partida para todos os guias.
-   **Guia de Início Rápido**: Comece a usar o cluster em minutos.
-   **Biblioteca de Prompts**: Prompts avançados para desenvolvedores.
-   **Guia de Troubleshooting**: Soluções para problemas comuns.

## 🤝 Contribuição

Contribuições são bem-vindas! Por favor, leia o nosso **Guia de Contribuição** para saber como participar.

## 📄 Licença

Este projeto está licenciado sob a Licença MIT. Veja o arquivo LICENSE.txt para mais detalhes.