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
-   **📱 Suporte Android**: Workers Android via Termux para expansão do cluster.
-   **🔐 Configuração SSH**: Scripts automatizados para configuração de chaves SSH e autenticação GitHub.
-   **🔒 Segurança**: Autenticação, validação de entrada e medidas de segurança integradas.

## 🚀 Instalação

A instalação é projetada para ser simples e flexível.

### Pré-requisitos
- Sistema Linux (Ubuntu/Debian, Fedora/RHEL, Arch)
- Pelo menos 4GB RAM e 20GB espaço em disco
- Conexão com internet para downloads

### Instalação Automática (Recomendado)

1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
    cd cluster-ai
    ```

2.  **Execute a configuração automática:**
    ```bash
    ./auto_setup.sh
    ```

    O script irá:
    - Detectar automaticamente se deve configurar como servidor ou worker
    - Instalar todas as dependências necessárias
    - Configurar a rede e conexões entre nós
    - Iniciar todos os serviços automaticamente

### Instalação Manual (Avançado)

Para controle total do processo:

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

### Instalação Automatizada
Para **instalação automatizada** (sem prompts), use a flag `--auto-role`:
```bash
bash install.sh --auto-role
```

### Instalação Personalizada
Para escolher componentes específicos:
```bash
bash install.sh --custom
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
-   **Workers Android**: Gerencie workers Android via Termux.
-   **Diagnóstico**: Execute health checks, gere relatórios de performance e verifique a qualidade do código.
-   **Manutenção**: Gerencie backups, restaure o sistema, atualize o projeto via Git e rotacione logs.
-   **Otimização**: Otimize os recursos do nó local e dos workers remotos com base no hardware detectado.

## 🏗️ Arquitetura

O sistema é modular, permitindo que diferentes máquinas assumam papéis específicos.

-   **Servidor Principal**: Hospeda o Dask Scheduler, a API do Ollama e a interface OpenWebUI. Centraliza o gerenciamento.
-   **Worker (GPU/CPU)**: Executa os processos `dask-worker` para realizar as tarefas de computação. Pode ou não ter uma GPU.
-   **Worker Android**: Expande o cluster usando dispositivos Android via Termux.
-   **Estação de Trabalho**: Um worker que também possui ferramentas de desenvolvimento (IDEs) instaladas.

| Serviço        | Porta   | Protocolo | Descrição                  |
| -------------- | ------- | --------- | -------------------------- |
| Dask Scheduler | 8786    | TCP       | Coordenação do cluster     |
| Dask Dashboard | 8787    | TCP       | Monitoramento web do Dask  |
| OpenWebUI      | 3000    | TCP       | Interface web para modelos |
| Ollama API     | 11434   | TCP       | API dos modelos de IA      |
| SSH            | 22      | TCP       | Acesso remoto para workers |

## 📚 Documentação Completa

A documentação detalhada está organizada no diretório `docs/`.

### 📖 Documentação Principal
-   **[Índice da Documentação](docs/INDEX.md)**: Ponto de entrada para todos os guias.

### 🚀 Guias Práticos
-   **[Guia de Início Rápido](docs/guides/quick-start.md)**: Comece a usar o cluster em minutos.
-   **[Configuração de Cluster: Servidor + Worker](docs/guides/cluster_setup_guide.md)**: Configure cluster distribuído com múltiplas máquinas.
-   **[Instalação Detalhada](docs/manuals/INSTALACAO.md)**: Guia passo-a-passo completo.
-   **[Uso Avançado](docs/guides/usage.md)**: Funcionalidades avançadas e otimização.

### 🛠️ Manuais Técnicos
-   **[Manual do Ollama](docs/manuals/ollama/)**: Modelos de IA e configuração.
-   **[Guia OpenWebUI](docs/manuals/openwebui/)**: Interface web.
-   **[Backup e Restauração](docs/manuals/BACKUP.md)**: Sistema de backup.
-   **[Android Workers](docs/manuals/ANDROID.md)**: Configuração de workers Android.
-   **[Guia Rápido Android](docs/manuals/ANDROID_GUIA_RAPIDO.md)**: Instalação simplificada em 5 minutos (inclui configuração SSH automática).

### 💡 Desenvolvimento
-   **[Biblioteca de Prompts](docs/guides/prompts_desenvolvedores_completo.md)**: Prompts avançados para desenvolvedores.
-   **[Arquitetura do Sistema](docs/guides/architecture.md)**: Detalhes técnicos da arquitetura.
-   **[Solução de Problemas](docs/guides/troubleshooting.md)**: FAQ e soluções para problemas comuns.

### 🔧 Configurações
-   **[Docker Compose](configs/docker/)**: Configurações Docker.
-   **[Nginx](configs/nginx/)**: Configurações de proxy reverso.
-   **[TLS/SSL](configs/tls/)**: Certificados e segurança.

## 🎯 Demonstrações e Testes

### Scripts de Demonstração
Após a instalação, teste o sistema com os scripts incluídos:

#### 1. Demonstração Completa (`demo_cluster.py`)
```bash
source ~/cluster_env/bin/activate
python demo_cluster.py
```
**Funcionalidades:**
- Processamento básico paralelo
- Cálculo de Fibonacci distribuído
- Operações com arrays grandes
- Logging detalhado

#### 2. Demonstração Interativa (`simple_demo.py`)
```bash
source ~/cluster_env/bin/activate
python simple_demo.py
```
**Funcionalidades:**
- Interface interativa
- Escolha de operações
- Comparação de performance
- Dashboard em tempo real

#### 3. Teste de Instalação (`test_installation.py`)
```bash
source ~/cluster_env/bin/activate
python test_installation.py
```
**Testes realizados:**
- ✅ Docker funcionando
- ✅ Pacotes Python instalados
- ✅ Cluster Dask operacional
- ✅ Performance (Speedup médio: 2.3x)
- ✅ Operações de data science

### Performance Demonstrativa
- **Processamento paralelo**: Speedup de 4.8x
- **Cálculo Fibonacci**: Speedup de 1.5x
- **Operações pesadas**: Speedup de 2.3x

## 🤝 Contribuição

Contribuições são bem-vindas! Por favor, leia o nosso **Guia de Contribuição** para saber como participar.

### Como Contribuir
1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está licenciado sob a Licença MIT. Veja o arquivo LICENSE.txt para mais detalhes.

## 🙏 Agradecimentos

-   **Dask**: Framework de computação distribuída
-   **Ollama**: Execução local de modelos de IA
-   **OpenWebUI**: Interface web para modelos
-   **Comunidade Open Source**: Por tornar possível este projeto

---

**📧 Suporte**: Para dúvidas e suporte, abra uma issue no GitHub.
**📚 Documentação**: [docs/INDEX.md](docs/INDEX.md)
**🚀 Início Rápido**: [Guia de Início Rápido](docs/guides/quick-start.md)
