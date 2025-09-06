# 🚀 Cluster AI - Sistema Universal de IA Distribuída

[![License: MIT](https://img.shields.io/github/license/Dagoberto-Candeias/cluster-ai)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
![Status](https://img.shields.io/badge/status-ativo-success)
[![Python](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/)
[![Docker](https://img.shields.io/badge/docker-required-blue.svg)](https://www.docker.com/)

Sistema integrado para implantação de clusters de IA com processamento distribuído usando **Dask**, **Ollama** e **OpenWebUI**. O projeto é gerenciado por um painel de controle centralizado (`manager.sh`) que simplifica todas as operações.

## ⚡ Início Rápido (3 minutos)

```bash
# 1. Clone e entre no projeto
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
cd cluster-ai

# 2. Execute a instalação unificada
./install_unified.sh

# 3. Inicie o sistema
./manager.sh
# Escolha opção 1: "Iniciar Todos os Serviços"
```

**🎯 Resultado**: Cluster AI totalmente funcional com interface web em `http://localhost:3000`

## 📋 Pré-requisitos do Sistema

| Componente | Mínimo | Recomendado | Observação |
|------------|--------|-------------|------------|
| **CPU** | 2 cores | 4+ cores | Para processamento paralelo |
| **RAM** | 4GB | 8GB+ | Para modelos de IA |
| **Armazenamento** | 20GB | 50GB+ | Para modelos e dados |
| **GPU** | Opcional | NVIDIA/AMD | Aceleração de IA |
| **Sistema** | Linux | Ubuntu 20.04+ | Suporte completo |
| **Docker** | 20.10+ | 24.0+ | Containers necessários |
| **Python** | 3.8+ | 3.10+ | Ambiente virtual |

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
-   **📱 Suporte Android**: Workers Android via Termux para expansão do cluster com configuração guiada.
-   **🔍 Descoberta Automática**: Sistema inteligente de descoberta automática de workers na rede local.
-   **🗑️ Desinstalação Completa**: Scripts unificados para desinstalação limpa de todos os componentes.
-   **🔧 Configuração Interativa**: Menu de configuração completo (opção 7) para setup de workers Android.
-   **🔐 Configuração SSH**: Scripts automatizados para configuração de chaves SSH e autenticação GitHub.
-   **🔒 Segurança**: Autenticação, validação de entrada e medidas de segurança integradas.

## 🚀 Instalação

A instalação é projetada para ser simples e flexível, utilizando um sistema modular e inteligente.

### Pré-requisitos
- Sistema Linux (Ubuntu/Debian, Fedora/RHEL, Arch)
- Pelo menos 4GB RAM e 20GB espaço em disco
- Conexão com internet para downloads

### 🚀 Instalação Unificada (Recomendado - Novo!)

O novo instalador unificado oferece a melhor experiência de instalação:

1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
    cd cluster-ai
    ```

2.  **Execute o instalador unificado:**
    ```bash
    ./install_unified.sh
    ```

**Vantagens do Instalador Unificado:**
- ✅ **Arquitetura Modular**: Scripts independentes para cada componente
- ✅ **Instalação Inteligente**: Detecta automaticamente o sistema e otimiza
- ✅ **Menu Interativo**: Escolha entre instalação completa ou personalizada
- ✅ **Verificação Integrada**: Valida cada componente após instalação
- ✅ **Relatórios Detalhados**: Acompanhe o progresso em tempo real
- ✅ **Tratamento de Erros**: Recuperação automática de falhas

### 📦 Instalação Automática (Legacy)

Para compatibilidade, o instalador automático legado ainda está disponível:

```bash
./auto_setup.sh
```

### 🔧 Instalação Manual (Avançado)

Para controle total do processo de instalação:

```bash
bash install.sh
```

**Recursos do Instalador Manual:**
- Verificação completa de pré-requisitos
- Detecção automática de hardware
- Sugestão de papel do nó (Servidor/Worker)
- Menu interativo com opções customizadas

### ⚙️ Instalação Personalizada

Escolha componentes específicos através do menu interativo:

```bash
./install_unified.sh
# Escolha opção 2 (Instalação Personalizada)
```

### 🔍 Verificação da Instalação

Verifique o status da instalação a qualquer momento:

```bash
./install_unified.sh
# Escolha opção 3 (Verificar Status da Instalação)
```

## 🗑️ Desinstalação

### Desinstalação Unificada (Recomendado)

Para desinstalar qualquer componente do Cluster AI:

```bash
./scripts/maintenance/uninstall_master.sh
```

**Opções disponíveis:**
- 🖥️ Desinstalar do Servidor Principal
- 📱 Desinstalar Worker Android (Termux)
- 💻 Desinstalar Estação de Trabalho
- 🔄 Desinstalar Workers Remotos (SSH)
- 🧹 Limpeza Completa (todos os tipos)
- 📊 Verificar Status de Instalação

### Desinstalação Específica

#### Worker Android
```bash
# No dispositivo Android (Termux)
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/uninstall_android_worker.sh | bash
```

#### Servidor/Estação de Trabalho
```bash
# Scripts específicos disponíveis
./scripts/maintenance/uninstall.sh              # Servidor
./scripts/maintenance/uninstall_workstation.sh  # Estação de trabalho
```

### Verificação de Status
```bash
./scripts/maintenance/uninstall_master.sh
# Escolha opção 6 (Verificar Status de Instalação)
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
-   **🔍 Descoberta Automática**: Sistema inteligente para descobrir workers automaticamente na rede.
-   **Workers Remotos**: Adicione, configure, inicie, pare e execute comandos em nós remotos.
-   **Workers Android**: Gerencie workers Android via Termux com configuração guiada (opção 7).
-   **Configuração Interativa**: Menu completo para configurar workers Android e SSH (opção 7).
-   **Diagnóstico**: Execute health checks, gere relatórios de performance e verifique a qualidade do código.
-   **Manutenção**: Gerencie backups, restaure o sistema, atualize o projeto via Git e rotacione logs.
-   **Otimização**: Otimize os recursos do nó local e dos workers remotos com base no hardware detectado.

## 🔍 Descoberta Automática de Workers

O Cluster AI inclui um sistema avançado de descoberta automática que identifica e configura workers na sua rede local.

### Como Usar a Descoberta Automática

#### Via Manager
```bash
./manager.sh
# Escolha: "Gerenciar Workers Remotos (SSH)"
# Escolha: "Executar Descoberta Automática"
```

#### Via Script Direto
```bash
./scripts/deployment/auto_discover_workers.sh
```

### Funcionalidades da Descoberta Automática

-   **🔍 Escaneamento Inteligente**: Detecta dispositivos na rede local (mesma sub-rede)
-   **🔐 Configuração SSH Automática**: Gera e copia chaves SSH automaticamente
-   **📱 Suporte Android**: Detecta workers Android via Termux (porta 8022)
-   **🖥️ Suporte Linux**: Detecta workers Linux (porta 22)
-   **✅ Verificação de Cluster**: Confirma se dispositivos já têm Cluster AI instalado
-   **📊 Relatórios Detalhados**: Mostra progresso e resultados da descoberta
-   **🔄 Configuração Automática**: Registra workers automaticamente no cluster

### Tipos de Dispositivos Detectados

-   **🎯 Workers Cluster AI**: Dispositivos com Cluster AI já instalado
-   **📱 Dispositivos Android**: Celulares/tablets com Termux
-   **🖥️ Servidores Linux**: Outros servidores Linux na rede
-   **❓ Dispositivos Genéricos**: Outros dispositivos com SSH ativo

### Exemplo de Saída
```
🔍 DESCOBERTA AUTOMÁTICA DE WORKERS
Escaneando rede 192.168.1.0/24 por portas SSH...

✅ Conexão SSH estabelecida com 192.168.1.100:8022
🎯 Worker Cluster AI encontrado: android-worker-1
✅ Chave SSH copiada para android-worker-1

📊 RELATÓRIO DE DESCOBERTA
Workers Cluster AI descobertos: 1
Dispositivos descobertos: 2
Workers configurados: 1
```

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

### 📖 Documentação Organizada

Toda a documentação foi reorganizada para facilitar a navegação. Consulte:

#### 🚀 **Instalação e Setup**
- **[📱 Android Workers](docs/organized/installation/ANDROID_GUIA_RAPIDO.md)** - Guia completo de instalação
- **[🖥️ Instalação Geral](docs/organized/installation/INSTALACAO.md)** - Setup completo do sistema
- **[🔍 Descoberta Automática](docs/organized/installation/)** - Workers na rede

#### 📋 **Uso e Operação**
- **[🤖 Ollama](docs/organized/usage/OLLAMA.md)** - Como usar modelos de IA
- **[🌐 OpenWebUI](docs/organized/usage/OPENWEBUI.md)** - Interface web
- **[📝 Prompts](docs/organized/prompts/README.md)** - Catálogos especializados

#### 🔧 **Manutenção e Configuração**
- **[💾 Backup](docs/organized/maintenance/BACKUP.md)** - Sistema de backup
- **[⚙️ Configuração](docs/organized/maintenance/CONFIGURACAO.md)** - Configurações avançadas
- **[🔒 Segurança](docs/organized/security/SECURITY_MEASURES.md)** - Medidas implementadas

#### 📚 **Guias e Referências**
- **[🚀 Guia Rápido](docs/organized/guides/quick-start.md)** - Início rápido
- **[🔧 Troubleshooting](docs/organized/guides/TROUBLESHOOTING.md)** - Resolução de problemas
- **[⚡ Otimização](docs/organized/guides/OPTIMIZATION.md)** - Performance e recursos

### 🔄 **Guia de Migração**
- **[📋 Migração da Documentação](docs/MIGRATION_GUIDE.md)** - Como navegar na nova estrutura
- **[📖 Índice Principal](docs/organized/README.md)** - Visão geral organizada

### 📖 **Documentação Original (Compatibilidade)**
- **[Índice da Documentação](docs/INDEX.md)**: Ponto de entrada para todos os guias (estrutura antiga).
- **[Manuais Técnicos](docs/manuals/)**: Documentação técnica detalhada.
- **[Guias Gerais](docs/guides/)**: Guias específicos de funcionalidades.
- **[Configurações](configs/)**: Configurações Docker, Nginx e TLS.

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

## 💡 Exemplos Práticos

### 1. Processamento de Dados com Dask
```python
from dask.distributed import Client
import dask.dataframe as dd
import pandas as pd

# Conectar ao cluster
client = Client('tcp://localhost:8786')

# Processar dataset grande
df = dd.read_csv('large_dataset.csv')
result = df.groupby('category').value.sum().compute()
print(result)
```

### 2. Usando Modelos de IA via Ollama
```python
import ollama

# Listar modelos disponíveis
models = ollama.list()
print("Modelos disponíveis:", [m['name'] for m in models['models']])

# Fazer uma pergunta
response = ollama.chat(model='llama3', messages=[
    {'role': 'user', 'content': 'Explique machine learning em 3 frases'}
])
print(response['message']['content'])
```

### 3. Adicionando Worker Android
```bash
# No dispositivo Android (Termux)
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker.sh | bash

# No servidor, registrar worker
./manager.sh
# Escolha: "Gerenciar Workers Remotos (SSH)"
# Escolha: "Executar Descoberta Automática"
```

### 4. Monitoramento em Tempo Real
```bash
# Dashboard Dask
open http://localhost:8787

# Interface OpenWebUI
open http://localhost:3000

# Status do cluster
./manager.sh
# Escolha: "Verificar Status dos Serviços"
```

### 5. Backup e Restauração
```bash
# Fazer backup completo
./manager.sh
# Escolha: "Manutenção" > "Fazer Backup do Sistema"

# Restaurar de backup
./manager.sh
# Escolha: "Manutenção" > "Restaurar Sistema"
```

## 🧪 Testes e Qualidade

### Executar Todos os Testes
```bash
# Testes completos
./scripts/validation/run_all_tests.sh

# Testes específicos
pytest tests/                    # Todos os testes Python
pytest tests/security/          # Testes de segurança
pytest tests/performance/       # Testes de performance
pytest tests/integration/       # Testes de integração
```

### Cobertura de Testes
- **Testes Unitários**: Componentes individuais
- **Testes de Integração**: Interação entre componentes
- **Testes de Segurança**: Validação e autenticação
- **Testes de Performance**: Benchmarks e profiling
- **Testes E2E**: Fluxos completos do usuário

## 🔒 Segurança

### Medidas Implementadas
- **Autenticação SSH**: Chaves RSA de 4096 bits
- **Validação de Entrada**: Sanitização de dados
- **Controle de Acesso**: Baseado em roles
- **Auditoria**: Logs detalhados de segurança
- **Criptografia**: Comunicação segura entre nós

### Verificações de Segurança
```bash
# Executar auditoria de segurança
./scripts/security/security_audit.sh

# Verificar permissões de arquivos
./scripts/security/check_permissions.sh
```

## ⚡ Performance e Otimização

### Métricas de Performance
- **Latência**: < 100ms para operações locais
- **Throughput**: 1000+ operações/segundo
- **Escalabilidade**: Até 100 workers simultâneos
- **Eficiência de Memória**: < 2GB por worker básico

### Otimizações Disponíveis
```bash
# Otimizar recursos do sistema
./scripts/optimization/optimize_system.sh

# Monitor de performance em tempo real
./scripts/monitoring/performance_monitor.sh
```

## 🔧 Troubleshooting

### Problemas Comuns

#### Sistema Não Inicia
```bash
# Verificar status dos serviços
./manager.sh
# Escolha: "Verificar Status dos Serviços"

# Ver logs detalhados
tail -f logs/cluster.log
```

#### Workers Não Conectam
```bash
# Testar conectividade SSH
ssh -T worker@192.168.1.100

# Verificar configuração do worker
./scripts/deployment/verify_worker.sh
```

#### Performance Baixa
```bash
# Executar diagnóstico
./scripts/diagnostic/performance_check.sh

# Otimizar recursos
./scripts/optimization/resource_optimizer.sh
```

### Logs e Debug
```bash
# Logs principais
tail -f ~/.cluster_optimization/optimization.log
tail -f logs/dask_scheduler.log
tail -f logs/ollama.log

# Debug mode
export CLUSTER_DEBUG=1
./manager.sh
```

## 📡 API e Integração

### Endpoints Principais
| Serviço | URL | Descrição |
|---------|-----|-----------|
| **OpenWebUI** | http://localhost:3000 | Interface web para IA |
| **Dask Dashboard** | http://localhost:8787 | Monitoramento do cluster |
| **Ollama API** | http://localhost:11434 | API dos modelos de IA |
| **Manager CLI** | - | Interface de linha de comando |

### Integração Programática
```python
# Exemplo de uso do cluster via Python
from dask.distributed import Client
import ollama

# Conectar ao cluster
client = Client('tcp://localhost:8786')

# Usar modelo de IA
response = ollama.chat(model='llama3', messages=[{'role': 'user', 'content': 'Olá!'}])
```

## ❓ FAQ

### Gerais
**P: O sistema funciona em Windows/Mac?**
R: Atualmente suporta apenas Linux. Suporte para outros SOs está planejado.

**P: Posso usar sem GPU?**
R: Sim, mas com performance reduzida. Recomendamos GPU para modelos maiores.

### Workers
**P: Quantos workers posso adicionar?**
R: Teoricamente ilimitado, limitado apenas pelos recursos de rede.

**P: Workers Android são confiáveis?**
R: Sim, com Termux. Recomendamos dispositivos com boa bateria e conexão WiFi estável.

### Performance
**P: Qual o speedup típico?**
R: 2-5x dependendo da tarefa e número de workers.

**P: Como otimizar para meu hardware?**
R: Execute `./scripts/optimization/hardware_optimizer.sh` para configuração automática.

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
