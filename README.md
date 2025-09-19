# 🤖 Cluster AI - Sistema Inteligente de Computação Distribuída

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.8+-blue.svg)](https://www.python.org/)
[![Docker](https://img.shields.io/badge/Docker-Supported-blue.svg)](https://www.docker.com/)
[![Linux](https://img.shields.io/badge/Linux-Supported-blue.svg)](https://www.linux.org/)

> Sistema completo de IA distribuída com processamento paralelo, modelos de linguagem avançados e interface web intuitiva.

## 🌟 Visão Geral

O **Cluster AI** é uma plataforma integrada que combina:

- 🚀 **Processamento Distribuído**: Dask para computação paralela em larga escala
- 🧠 **Modelos de IA**: Ollama com suporte a múltiplos modelos (Llama, Mistral, etc.)
- 🌐 **Interface Web**: OpenWebUI para interação natural com IA
- 📱 **Workers Android**: Suporte a dispositivos móveis via Termux
- 🔒 **Segurança**: Configurações robustas com TLS/SSL
- 📊 **Monitoramento**: Dashboards e métricas em tempo real

## ✨ Funcionalidades Principais

### 🤖 IA e Machine Learning
- **Modelos Diversos**: Llama 3, Mistral, DeepSeek, CodeLlama, e mais
- **Processamento Paralelo**: Distribua tarefas de ML em múltiplos workers
- **Interface Conversacional**: Chat natural com modelos de linguagem
- **APIs REST**: Integração programática com aplicações

### ⚡ Computação Distribuída
- **Dask Framework**: Processamento paralelo escalável
- **Workers Dinâmicos**: Adicione/remova workers automaticamente
- **Balanceamento de Carga**: Otimização automática de recursos
- **Memória Eficiente**: Spill-to-disk para datasets grandes

### 🌐 Multi-Cloud e Alta Disponibilidade (Fase 14)
- **Multi-Cluster Local**: Simulação de ambientes multi-cloud com Kind
- **Load Balancing**: MetalLB para distribuição de carga cross-cluster
- **Storage Replication**: PVC cross-cluster com sincronização automática
- **Disaster Recovery**: Failover automático e backup cross-cluster
- **Auto-Scaling**: Escalabilidade preditiva baseada em métricas
- **Service Mesh**: Istio para gerenciamento avançado de tráfego
- **PostgreSQL Replication**: Replicação de dados cross-cluster
- **Redis Cluster**: Cache distribuído multi-cluster

### 🛠️ Gerenciamento Inteligente
- **Instalação Automática**: Scripts inteligentes que detectam seu hardware
- **Configuração Guiada**: Menus interativos para todas as operações
- **Backup/Restauração**: Estratégias completas de backup
- **Monitoramento 24/7**: Alertas e dashboards de status

### 📱 Suporte Multi-Plataforma
- **Linux Nativo**: Otimizado para distribuições Linux
- **Android/Termux**: Workers móveis via SSH
- **Docker**: Containerização completa
- **Produção**: Configurações TLS para ambientes corporativos

## 🚀 Início Rápido

### Instalação Automática (Recomendado)
```bash
# Clone o repositório
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
cd cluster-ai

# Instalação inteligente (detecta hardware automaticamente)
bash install.sh --auto-role

# Ou instalação unificada com menu interativo
bash install_unified.sh
```

### Primeiro Uso
```bash
# Acessar o painel de controle principal
./manager.sh
# Selecionar: 1. Iniciar Todos os Serviços

# Acesse as interfaces:
# - 🌐 OpenWebUI (IA Conversacional): http://localhost:3000
# - 📊 Dask Dashboard (Computação Distribuída): http://localhost:8787
# - 🎛️ Web Dashboard Principal (Monitoramento): http://localhost:3000
# - 📈 Grafana (Visualização Avançada): http://localhost:3001
# - 📊 Prometheus (Métricas): http://localhost:9090
# - 🔍 Kibana (Análise de Logs): http://localhost:5601
# - 🤖 Ollama API: http://localhost:11434
```

### Deploy com Docker (Stack Completo)
```bash
# Iniciar todos os serviços de monitoramento
docker-compose up -d

# Verificar status dos containers
docker-compose ps

# Acessar logs em tempo real
docker-compose logs -f
```

### Configuração de Workers
```bash
# Configurar workers automaticamente
./scripts/deployment/auto_discover_workers.sh

# Ou configurar manualmente via interface
./manager.sh
# Selecionar: 2. Gerenciar Workers
```

### Teste Básico
```bash
# Baixe um modelo de teste
ollama pull llama3:8b

# Teste o modelo
ollama run llama3:8b "Olá! Explique machine learning em uma frase."
```

## 📋 Requisitos do Sistema

### Mínimos
- **SO**: Linux (Ubuntu 20.04+, Debian 10+, Fedora 30+, Arch Linux)
- **RAM**: 4GB
- **Armazenamento**: 20GB SSD
- **CPU**: 2 cores
- **Rede**: Conexão internet para downloads

### Recomendados
- **RAM**: 16GB+
- **Armazenamento**: 100GB+ SSD
- **CPU**: 4+ cores com AVX2
- **GPU**: NVIDIA/AMD com drivers atualizados (opcional)

### Suportados
- ✅ **GPUs NVIDIA**: CUDA 11.8+
- ✅ **GPUs AMD**: ROCm 5.4+
- ✅ **Apple Silicon**: Via Rosetta 2
- ✅ **ARM64**: Raspberry Pi 4+, servidores ARM

## 🏗️ Arquitetura

### Arquitetura Principal
```
┌─────────────────┐    ┌─────────────────┐
│   OpenWebUI     │    │   Dask          │
│   (Interface)   │◄──►│   Scheduler     │
│   Port: 3000    │    │   Port: 8786    │
└─────────────────┘    └─────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│   Ollama API    │    │   Dask Workers  │
│   (Modelos IA)  │    │   (Processamento)│
│   Port: 11434   │    │   Ports: 8787+  │
└─────────────────┘    └─────────────────┘
         ▲                       ▲
         │                       │
┌─────────────────┐    ┌─────────────────┐
│  Workers Linux  │    │ Workers Android │
│  (SSH/Native)   │    │   (Termux/SSH)  │
└─────────────────┘    └─────────────────┘
```

### Arquitetura Multi-Cloud (Fase 14)
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AWS Cluster   │    │   GCP Cluster   │    │  Azure Cluster  │
│   (Kind Local)  │◄──►│   (Kind Local)  │◄──►│   (Kind Local)  │
│                 │    │                 │    │                 │
│ • MetalLB       │    │ • MetalLB       │    │ • MetalLB       │
│ • PostgreSQL    │    │ • PostgreSQL    │    │ • PostgreSQL    │
│ • Redis         │    │ • Redis         │    │ • Redis         │
│ • Storage Rep.  │    │ • Storage Rep.  │    │ • Storage Rep.  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Service Mesh  │
                    │     (Istio)     │
                    │                 │
                    │ • Load Balance  │
                    │ • Traffic Mgmt  │
                    │ • mTLS Security │
                    │ • Observability │
                    └─────────────────┘
```

## 📚 Exemplos de Uso

### Processamento Distribuído
```python
from dask.distributed import Client
import dask.array as da

# Conectar ao cluster
client = Client('localhost:8786')

# Criar dados distribuídos
x = da.random.random((10000, 10000), chunks=(1000, 1000))
y = (x + x.T).mean()

# Computar em paralelo
resultado = y.compute()
print(f"Resultado: {resultado}")
```

### Interação com IA
```python
from ollama import Client

client = Client(host='http://localhost:11434')

# Chat com modelo
response = client.chat(
    model='llama3:8b',
    messages=[{'role': 'user', 'content': 'Explique quantum computing'}]
)

print(response['message']['content'])
```

### Análise de Dados
```python
import dask.dataframe as dd

# Processar arquivo grande
df = dd.read_csv('dados_grandes.csv')

# Análise distribuída
estatisticas = df.describe().compute()
correlacao = df.corr().compute()

print("Análise completa de dados grandes!")
```

## 📖 Documentação

### 📚 Guias Principais
- **[📖 Documentação Completa](docs/)** - Índice completo da documentação
- **[🚀 Guia de Início Rápido](docs/guides/quick-start.md)** - Comece em minutos
- **[📋 Manual de Instalação](docs/manuals/INSTALACAO.md)** - Instalação detalhada
- **[🛠️ Guia de Desenvolvimento](docs/guides/development-plan.md)** - Para contribuidores

### 🔧 Configurações
- **[⚙️ Arquitetura do Sistema](docs/guides/architecture.md)** - Design e componentes
- **[🔒 Segurança](docs/security/)** - Medidas de segurança implementadas
- **[📊 Monitoramento](docs/guides/monitoring.md)** - Ferramentas de observabilidade
- **[🐛 Solução de Problemas](docs/guides/troubleshooting.md)** - FAQ e diagnóstico

### 📱 Funcionalidades Específicas
- **[📱 Workers Android](docs/manuals/ANDROID.md)** - Configuração de dispositivos móveis
- **[🚢 Docker](configs/docker/)** - Configurações de containerização
- **[🔐 Produção com TLS](deployments/production/)** - Deploy seguro
- **[💾 Backup](docs/manuals/BACKUP.md)** - Estratégias de backup

## 🛠️ Scripts e Ferramentas

### Gerenciamento Principal
```bash
./manager.sh              # Menu principal interativo
./install_unified.sh      # Instalação unificada
./scripts/health_check.sh # Verificação de saúde
```

### Desenvolvimento
```bash
./run_tests.sh           # Executar suíte de testes
./scripts/lint.sh        # Verificação de código
./scripts/format.sh      # Formatação automática
```

### Operações
```bash
./start_cluster.sh       # Iniciar cluster
./stop_cluster.sh        # Parar cluster
./restart_cluster.sh     # Reiniciar serviços
```

### 🤖 Gestão Inteligente de IA
```bash
./scripts/ollama/model_manager.sh list          # Listar modelos com métricas
./scripts/ollama/model_manager.sh cleanup 30    # Limpar modelos não usados (30 dias)
./scripts/ollama/model_manager.sh optimize      # Otimizar uso de disco
```

### 📊 Monitoramento Avançado
```bash
./scripts/monitoring/advanced_dashboard.sh live           # Dashboard em tempo real
./scripts/monitoring/advanced_dashboard.sh continuous 10  # Monitoramento contínuo (10s)
./scripts/monitoring/advanced_dashboard.sh export csv     # Exportar métricas
```

### 🚀 Gerenciador Inteligente Integrado
```bash
./scripts/integration/smart_manager.sh dashboard    # Dashboard integrado interativo
./scripts/integration/smart_manager.sh health       # Verificar saúde do sistema
./scripts/integration/smart_manager.sh optimize     # Otimização automática
./scripts/integration/smart_manager.sh report       # Gerar relatório inteligente
```

## 🤝 Contribuição

### Como Contribuir
1. 🍴 **Fork** o projeto
2. 📝 **Leia** [CONTRIBUTING.md](CONTRIBUTING.md)
3. 🐛 **Abra uma Issue** para discutir mudanças
4. 💻 **Crie uma branch** para sua feature
5. ✅ **Envie um PR** com testes

### Desenvolvimento Local
```bash
# Configurar ambiente de desenvolvimento
bash scripts/setup_dev_env.sh

# Executar testes
python -m pytest tests/

# Verificar linting
bash scripts/lint.sh

# Formatar código
bash scripts/format.sh
```

### Tipos de Contribuição
- 🐛 **Bug Fixes**: Correções de problemas
- ✨ **Features**: Novas funcionalidades
- 📚 **Documentação**: Melhorias na documentação
- 🧪 **Testes**: Novos testes ou melhorias
- 🔧 **Tools**: Scripts e ferramentas de desenvolvimento

## 📊 Status do Projeto

### ✅ Funcionalidades Implementadas
- [x] **Sistema Inteligente**: Instalação automática e detecção de hardware
- [x] **Workers Android**: Suporte completo via Termux
- [x] **Interface Web**: OpenWebUI integrada
- [x] **Processamento Distribuído**: Dask cluster funcional
- [x] **Modelos IA**: Ollama com múltiplos modelos
- [x] **Segurança**: Configurações TLS/SSL
- [x] **Monitoramento**: Dashboards e métricas
- [x] **Backup**: Estratégias automatizadas

### 🔄 Melhorias Recentes (v1.0.1)
- [x] **Correções Críticas**: Todos os bugs críticos corrigidos (27/27 testes passando)
- [x] **Segurança**: Auditoria completa realizada - sistema seguro
- [x] **Organização**: 90+ arquivos TODO consolidados em estrutura limpa
- [x] **Performance**: Otimizações avançadas implementadas
- [x] **Documentação**: README atualizado com status atual
- [x] **Testes**: Cobertura completa de testes de performance
- [x] **Modelos**: Gestão inteligente implementada (Cache, limpeza automática, métricas)
- [x] **Monitoramento**: Dashboards avançados implementados (Métricas em tempo real, alertas)
- [x] **Integração**: Smart Manager integrado (Gestão unificada de todo o sistema)

### 🎯 Roadmap
- **v1.1.0**: Melhorias de performance e novos modelos
- **v1.2.0**: Suporte a Kubernetes
- **v1.3.0**: Interface web aprimorada
- **v2.0.0**: Suporte a múltiplas nuvens

## 📈 Métricas e Benchmarks

### Performance
- **Processamento**: Até 10x mais rápido com workers distribuídos
- **Memória**: Eficiência otimizada com spill-to-disk
- **GPU**: Suporte completo para aceleração de IA

### Escalabilidade
- **Workers**: Suporte a centenas de workers
- **Dados**: Processamento de terabytes de dados
- **Modelos**: Cache inteligente de modelos

## 🏆 Casos de Uso

### 🤖 Machine Learning
- Treinamento distribuído de modelos
- Processamento de datasets grandes
- Inferência em tempo real
- AutoML automatizado

### 📊 Ciência de Dados
- Análise de big data
- Visualização interativa
- ETL distribuído
- Estatísticas avançadas

### 💻 Desenvolvimento
- Geração de código com IA
- Revisão automática de código
- Testes inteligentes
- Documentação automática

### 🚀 Automação
- Workflows de IA
- Processamento de linguagem natural
- Análise de sentimentos
- Chatbots avançados

## 📞 Suporte e Comunidade

### Canais de Suporte
- 📧 **Email**: Para questões técnicas específicas
- 🐛 **GitHub Issues**: Bugs e solicitações de features
- 💬 **GitHub Discussions**: Perguntas gerais e discussões
- 📖 **Documentação**: Guias completos e tutoriais

### Recursos da Comunidade
- **Wiki**: Tutoriais e exemplos avançados
- **Vídeos**: Guias em vídeo no YouTube
- **Discord**: Chat em tempo real (em breve)
- **Blog**: Artigos técnicos e atualizações

## 📄 Licença

Este projeto está licenciado sob a **MIT License** - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🙏 Agradecimentos

### Tecnologias Utilizadas
- **[Dask](https://dask.org/)**: Computação paralela e distribuída
- **[Ollama](https://ollama.ai/)**: Modelos de IA locais
- **[OpenWebUI](https://openwebui.com/)**: Interface web para IA
- **[FastAPI](https://fastapi.tiangolo.com/)**: APIs web modernas

### Contribuidores
- **Dagoberto Candeias**: Desenvolvedor principal
- **Comunidade Open Source**: Contribuições e feedback

### Inspiração
Este projeto é inspirado em:
- **Ray**: Sistema de computação distribuída
- **Hugging Face**: Ecossistema de modelos de IA
- **Apache Spark**: Processamento de big data
- **Kubernetes**: Orquestração de containers

---

## 🎯 Próximos Passos

1. **🚀 Instalação**: Siga o [guia de início rápido](docs/guides/quick-start.md)
2. **📖 Aprendizado**: Explore a [documentação completa](docs/)
3. **🤝 Contribuição**: Leia [CONTRIBUTING.md](CONTRIBUTING.md)
4. **💬 Comunidade**: Participe das discussões no GitHub

---

**⭐ Se este projeto foi útil, considere dar uma estrela no GitHub!**

*Última atualização: 2025-09-11*
*Versão: 1.0.1*
