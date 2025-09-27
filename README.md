# 🚀 Cluster AI - Sistema Universal de IA Distribuída

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.8+](https://img.shields.io/badge/Python-3.8%2B-blue.svg)](https://www.python.org/)
[![Docker](https://img.shields.io/badge/Docker-Supported-blue.svg)](https://www.docker.com/)
[![Linux](https://img.shields.io/badge/Linux-Supported-green.svg)](https://www.linux.org/)
[![Android](https://img.shields.io/badge/Android-Termux-green.svg)](https://termux.dev/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

> Plataforma integrada de IA distribuída com processamento paralelo (Dask), modelos locais (Ollama), interface web (OpenWebUI) e suporte multi-plataforma (Linux/Android). Fácil de usar, escalável e segura.

## 📖 Visão Geral

O **Cluster AI** é um sistema completo para computação distribuída de IA, combinando:

- **🚀 Processamento Distribuído**: Dask para tarefas paralelas em larga escala.
- **🧠 Modelos de IA**: Ollama com suporte a múltiplos modelos (Llama3, Mistral, etc.).
- **🌐 Interface Web**: OpenWebUI para interação conversacional e dashboards.
- **📱 Workers Multi-Plataforma**: Suporte nativo a Linux e Android (via Termux/SSH).
- **🔒 Segurança**: TLS/SSL, auditoria de logs e validação de integridade.
- **📊 Monitoramento**: Prometheus, Grafana, Kibana para métricas em tempo real.
- **🛡️ Automação**: Inicialização plug-and-play, auto-recuperação e atualizações automáticas.

**Status do Projeto**: Versão 2.0.0 (85% concluído). Melhorias recentes incluem scripts de rollback, gestão segura de modelos e otimizações de performance.

### ✨ Características Principais

- **🤖 Universal**: Funciona em qualquer distribuição Linux e Android via Termux
- **⚡ Performance**: Otimizado para GPU NVIDIA/AMD/Apple Silicon/ARM64
- **🔧 Pronto**: Scripts automatizados e documentação completa
- **🚀 Produtivo**: VSCode com 25 extensões essenciais
- **📊 Escalável**: Processamento distribuído com Dask
- **🛡️ Seguro**: Validações, auditoria e rollback automático
- **🔄 Auto-Recuperação**: Sistema de recuperação automática de falhas

### 🆕 Melhorias Recentes (Janeiro 2025)

#### 🔴 Segurança e Estabilidade
- ✅ **Scripts Completos**: `model_manager.sh`, `install_additional_models.sh`, `cleanup_manager_secure.sh`, `rollback.sh`
- ✅ **Validações Robustas**: Funções de validação de entrada em `common.sh`
- ✅ **Confirmações Críticas**: Níveis de risco para operações perigosas
- ✅ **Auditoria Completa**: Logs de auditoria para operações críticas
- ✅ **Rollback Automático**: Recuperação de emergência via Docker

#### 🟡 Funcionalidade
- ✅ **Modelos Categorizados**: Instalação por categoria (coding, creative, multilingual, science, compact)
- ✅ **Gestão Inteligente**: Listar, limpar, otimizar e estatísticas de modelos
- ✅ **Workers Plug-and-Play**: Auto-descoberta e configuração automática

#### 🟢 Otimização
- ✅ **VSCode Otimizado**: Telemetria desabilitada, exclusões de arquivos pesados
- ✅ **Performance**: Configurações de spill-to-disk e balanceamento automático

## 🏗️ Arquitetura

### Diagrama Principal
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

### Componentes Chave
- **Dask**: Computação paralela escalável.
- **Ollama**: Execução local de LLMs com suporte a GPU.
- **FastAPI Backend**: APIs para gerenciamento (web-dashboard/backend).
- **Docker Compose**: Orquestração de serviços (postgres, redis, prometheus, etc.).
- **Scripts de Gerenciamento**: Em `/scripts/` para automação.

## 📚 Documentação Completa

### 🎯 Guias Principais
- **[📖 Manual de Instalação](docs/manuals/INSTALACAO.md)** - Guia detalhado passo a passo
- **[🤖 Manual do Ollama](docs/manuals/OLLAMA.md)** - Modelos e configuração
- **[⚡ Guia Rápido](docs/guides/QUICK_START.md)** - Comece em 5 minutos
- **[🛠️ Troubleshooting](docs/guides/TROUBLESHOOTING.md)** - Solução de problemas
- **[🚀 Guia Prático](GUIA_PRATICO_CLUSTER_AI.md)** - Comandos e exemplos

### 🔧 Scripts Principais
| Script | Descrição | Uso |
|--------|-----------|-----|
| `install_unified.sh` | Instalador universal | `sudo ./install_unified.sh` |
| `install_cluster.sh` | Menu interativo | `./install_cluster.sh` |
| `health_check.sh` | Verificação do sistema | `./scripts/utils/health_check.sh` |
| `check_models.sh` | Gerenciar modelos | `./scripts/utils/check_models.sh` |
| `model_manager.sh` | Gestão completa de modelos | `./scripts/ollama/model_manager.sh` |
| `worker_manager.sh` | Gerenciar workers | `./scripts/management/worker_manager.sh` |

## 📋 Requisitos do Sistema

### Mínimos
- **SO**: Linux (Ubuntu 20.04+, Debian 10+, Fedora 30+, Arch Linux).
- **RAM**: 4GB (8GB recomendado para modelos).
- **Armazenamento**: 20GB SSD (100GB+ para modelos).
- **CPU**: 2 cores (4+ com AVX2 recomendado).
- **Rede**: Conexão à internet para downloads iniciais.
- **Python**: 3.8+.
- **Docker**: Versão 20+ com Compose v2.

### Recomendados
- **RAM**: 16GB+.
- **GPU**: NVIDIA (CUDA 11.8+) ou AMD (ROCm 5.4+).
- **Armazenamento**: 500GB+ SSD para datasets e modelos.

### Suportados
- ✅ GPUs NVIDIA/AMD/Apple Silicon/ARM64 (Raspberry Pi 4+).
- ✅ Android via Termux (workers leves).

**Dependências Principais** (requirements.txt):
- dask[complete]>=2024.12.0
- fastapi>=0.115.0
- ollama>=0.3.0
- torch>=2.4.0
- psutil>=6.0.0
- (Ver requirements.txt e requirements-dev.txt para completo).

**Permissões Necessárias**:
- Scripts principais: `chmod +x scripts/*.sh`.
- Docker: Usuário no grupo `docker` (sem sudo).
- Workers: SSH keys para conexões remotas (sem senha).

## 🚀 Início Rápido

### 1. Instalação de Dependências
Crie um ambiente virtual (recomendado para evitar conflitos):
```bash
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# ou venv\Scripts\activate  # Windows
pip install -r requirements.txt
pip install -r requirements-dev.txt  # Para testes
```

Instale Docker Compose v2 se necessário:
```bash
sudo apt update && sudo apt install docker-compose-v2  # Ubuntu/Debian
```

### 2. Instalação Automática (Recomendada)
```bash
# Clone o repositório
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
cd cluster-ai

# Instalação unificada com menu interativo
bash install_unified.sh

# Ou instalação inteligente (detecta hardware)
bash install_unified.sh --auto-role
```

### 3. Inicialização do Cluster
```bash
# Menu principal
./manager.sh

# Ou inicie diretamente
bash scripts/start_cluster_complete_fixed.sh

# Para produção (Docker)
docker compose up -d
```

### 4. Primeiro Uso
- **Dashboard Principal**: http://localhost:3000 (login: admin/admin123).
- **Dask Dashboard**: http://localhost:8787.
- **Ollama API**: http://localhost:11434.
- **Grafana**: http://localhost:3001.
- **Prometheus**: http://localhost:9090.
- **Kibana (Logs)**: http://localhost:5601.

Teste básico:
```bash
# Baixe um modelo
ollama pull llama3:8b

# Teste o modelo
ollama run llama3:8b "Olá! Explique machine learning."
```

## 🧪 Testes
Após setup:
```bash
pytest tests/ -v  # Todos os testes
SECRET_KEY=test-secret-key pytest tests/test_backend.py -v  # Backend específico
```

Cobertura: 90%+ em unitários, integração, performance e segurança.

## 🔧 Configuração de Workers (Plug-and-Play)

### Linux Nativo
```bash
# Via menu
./manager.sh  # Opção: Gerenciar Workers > Adicionar Worker

# Automático
bash scripts/deployment/auto_discover_workers.sh --ip <worker_ip> --user <username>
```

### Android/Termux
```bash
# One-liner
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/termux_worker_setup.sh | bash

# Manual
wget https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/termux_worker_setup.sh
chmod +x termux_worker_setup.sh
./termux_worker_setup.sh
```

**Gerenciamento**:
```bash
./scripts/management/worker_manager.sh list  # Listar
./scripts/management/worker_manager.sh status worker-001  # Status
./scripts/management/worker_manager.sh restart worker-001  # Reiniciar
```

## 🧠 Workers Ollama e Modelos

### Categorias de Modelos Recomendados

#### 📝 **Coding** (Programação)
- `codellama:7b` - Geração e análise de código
- `deepseek-coder:6.7b` - Desenvolvimento avançado
- `llama3:8b` - Chat geral com capacidades de código
- `starcoder:7b` - Modelos de código especializados

#### 🎨 **Creative** (Criativo)
- `llama3:8b` - Conteúdo criativo geral
- `mistral:7b` - Análise técnica e criativa
- `nous-hermes:13b` - Raciocínio avançado

#### 🌍 **Multilingual** (Multilíngue)
- `llama3:8b` - Suporte multilíngue nativo
- `mistral:7b` - Forte em idiomas europeus
- `gemma:7b` - Otimizado para multilíngue

#### 🔬 **Science** (Científico)
- `llama3:8b` - Análise científica geral
- `mixtral:8x7b` - Raciocínio matemático avançado
- `nous-hermes:13b` - Pesquisa e análise

#### 📦 **Compact** (Leves)
- `phi3:3.8b` - Tarefas leves eficientes
- `gemma:2b` - Modelo compacto otimizado
- `llama3:1b` - Versão ultra-leve

#### 👁️ **Vision** (Visão Computacional)
- `llava:7b` - Análise de imagens
- `bakllava:7b` - Multimodal avançado
- `moondream:1.8b` - Leve para imagens

### Gestão Inteligente de Modelos

#### Instalação Automatizada
```bash
# Por categoria específica
./scripts/ollama/install_additional_models.sh coding    # Modelos de programação
./scripts/ollama/install_additional_models.sh creative  # Modelos criativos
./scripts/ollama/install_additional_models.sh compact   # Modelos leves

# Todas as categorias
./scripts/ollama/install_additional_models.sh all

# Verificar instalação
ollama list
```

#### Gerenciamento Completo
```bash
# Listar todos os modelos
./scripts/ollama/model_manager.sh list

# Estatísticas detalhadas
./scripts/ollama/model_manager.sh stats

# Otimizar armazenamento (remover duplicatas)
./scripts/ollama/model_manager.sh optimize

# Limpeza de modelos não utilizados (30+ dias)
./scripts/ollama/model_manager.sh cleanup 30

# Atualizar modelo específico
./scripts/ollama/model_manager.sh update llama3:8b

# Rollback para versão anterior
./scripts/ollama/model_manager.sh rollback llama3
```

#### Validação e Segurança
- ✅ **Hash Checks**: Validação de integridade em todos os downloads
- ✅ **Rollback Automático**: Recuperação de falhas de atualização
- ✅ **Auditoria**: Logs completos de todas as operações
- ✅ **Confirmações**: Validações para operações críticas

Documentação detalhada: [docs/manuals/OLLAMA.md](docs/manuals/OLLAMA.md).

## 🛠️ Scripts e Ferramentas

### Manifest de Scripts (Funções e Permissões)
| Script | Função Principal | Permissões | Dependências |
|--------|------------------|------------|--------------|
| `manager.sh` | Menu interativo principal | +x | bash, whiptail |
| `install_unified.sh` | Instalação unificada | +x, sudo | python3, docker |
| `start_cluster_complete_fixed.sh` | Inicialização completa | +x | docker, ollama |
| `web_server_fixed.sh` | Servidor web | +x | python3 |
| `worker_manager.sh` | Gerenciar workers | +x | ssh, dask |
| `model_manager.sh` | Modelos Ollama | +x | ollama |
| `health_checker.sh` | Verificação saúde | +x | curl, psutil |
| `rollback.sh` | Recuperação emergência | +x, sudo | docker |

**Padronização**: Todos seguem PEP 8 (Python), Shell Best Practices (Bash), com shebang `#!/bin/bash`, headers e comentários.

### Comandos Rápidos
```bash
./manager.sh start  # Iniciar cluster
./manager.sh stop   # Parar
./manager.sh status # Status
./scripts/ollama/model_manager.sh list  # Modelos
./scripts/management/cleanup_manager_secure.sh all  # Limpeza segura
```

## 🛡️ Segurança e Melhores Práticas

- **Auditoria**: Logs em `/logs/` com rotação; auditoria para ops críticas (ex: rm, sudo).
- **Credenciais**: Use variáveis de ambiente; nunca hardcode senhas.
- **Validação**: Entradas validadas (IPs, portas); confirmações para ações perigosas.
- **Permissões**: Scripts com `chmod +x`; workers via SSH keys (sem senha).
- **Integridade Modelos**: Hash checks em downloads; rollback automático.
- **Exposição Dados**: Sem dados sensíveis em logs; TLS para produção.

**Auditoria Recente**: Implementado em janeiro 2025; todos comandos perigosos (rm -rf, sudo) auditados e validados.

## ⚡ Desempenho e Otimização

- **Workers**: Balanceamento automático; spill-to-disk para memória.
- **Docker**: Healthchecks e restarts automáticos.
- **VSCode**: Configs otimizadas (.vscode/settings.json): telemetria off, exclusões de arquivos pesados.
- **Auto-Escalabilidade**: Workers dinâmicos; monitoramento com alertas.

## 🐛 Troubleshooting e Recuperação Automática

### Problemas Comuns
- **"docker-compose não encontrado"**: Instale `docker-compose-v2`.
- **Workers não conectam**: Verifique SSH: `ssh -T user@worker_ip`.
- **Modelos não carregam**: Cheque espaço: `df -h`; reinicie: `systemctl restart ollama`.
- **Performance baixa**: Otimize: `./scripts/optimization/worker_optimizer.sh`.

### Recuperação Automática
- **Auto-Restart**: Configurado em manager.sh e Docker (depends_on com healthcheck).
- **Rollback**: `./scripts/deployment/rollback.sh` para emergências.
- **Logs Detalhados**: `tail -f logs/cluster_start.log`; notificações para falhas críticas via email/Slack (configurável).

**Procedimentos**:
1. Rode `./manager.sh diag` para diagnóstico.
2. Use `./manager.sh restart` para auto-recuperação.
3. Para falhas críticas: `./scripts/emergency_fix.sh`.

Documentação completa: [docs/guides/troubleshooting.md](docs/guides/troubleshooting.md).

## 🧪 Testes e CI/CD

- **Cobertura**: Unitários (pytest), integração, E2E, performance, segurança.
- **Executar**: `pytest tests/ -v --cov`.
- **CI**: GitLab CI (.gitlab-ci.yml) com linting (flake8, ShellCheck), testes e relatórios de cobertura.

Adicione testes para falhas: Cenários de recuperação, permissões e validação de comandos.

## 🤝 Contribuição

1. Fork o projeto.
2. Leia [CONTRIBUTING.md](CONTRIBUTING.md).
3. Crie branch para sua feature.
4. Teste: `pytest tests/`.
5. Envie PR.

**Padrões**: PEP 8 (Python), Shell Best Practices (Bash). Use `scripts/lint.sh` para verificação.

## 📊 Status e Roadmap

### Implementado (v2.0.0)
- [x] Instalação universal e auto-detecção hardware.
- [x] Workers Android via Termux.
- [x] Interface OpenWebUI integrada.
- [x] Dask cluster funcional.
- [x] Modelos Ollama com gestão inteligente.
- [x] Segurança: TLS, auditoria, validações.
- [x] Monitoramento: Dashboards avançados.
- [x] Auto-atualização e rollback.
- [x] Correções de sintaxe e otimizações.

### Roadmap
- **v2.1.0**: Integração GPT/Claude; testes multi-distro.
- **v2.2.0**: Cache distribuído; segurança avançada.
- **v3.0.0**: Suporte iOS/Desktop/Cloud; MLOps.

## 📞 Suporte e Comunidade

- **Issues**: GitHub para bugs/features.
- **Discussões**: GitHub Discussions.
- **Documentação**: [docs/](docs/).
- **Email**: Para suporte técnico específico.

## 📄 Licença

MIT License - veja [LICENSE](LICENSE).

## 🙏 Agradecimentos

- **Tecnologias**: Dask, Ollama, FastAPI, OpenWebUI.
- **Contribuidores**: Dagoberto Candeias (principal); comunidade open-source.

**⭐ Dê uma estrela no GitHub se útil!**

*Última Atualização: 2025-01-27 | Versão: 2.0.0*
