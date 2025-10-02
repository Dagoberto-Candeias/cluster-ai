# Cluster AI

**Sistema Universal de IA Distribuída**

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.8+-blue.svg)](https://www.python.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)

Este projeto é uma plataforma completa para **gerenciamento e orquestração de modelos de inteligência artificial em cluster distribuído**. O foco é exclusivamente em processamento de IA, aprendizado de máquina e computação distribuída.

## 🚫 ESCOPO DO PROJETO

**IMPORTANTE:** Este projeto **NÃO** contém nenhuma funcionalidade relacionada a:
- Mineração de criptomoedas
- Blockchain ou criptografia financeira
- Qualquer tipo de atividade financeira ou monetária

O projeto é dedicado exclusivamente ao processamento distribuído de inteligência artificial, utilizando tecnologias como:
- Ollama para execução de modelos de IA
- Dask para computação distribuída
- OpenWebUI para interfaces de chat
- Docker para containerização
- Monitoramento e métricas com Prometheus/Grafana

## 📋 COMPONENTES PRINCIPAIS

- **Model Registry**: Gerenciamento de modelos de IA
- **Distributed Workers**: Processamento paralelo de tarefas de IA
- **Web Dashboard**: Interface web para monitoramento e controle
- **API Backend**: REST API para integração com sistemas externos
- **Monitoring Stack**: Prometheus, Grafana e alertas
- **Security Layer**: Autenticação, autorização e auditoria

## 🏗️ ARQUITETURA

### Componentes Técnicos
- **Dask Scheduler**: Coordenação de tarefas distribuídas (porta 8786)
- **Dask Workers**: Execução paralela em múltiplos nós
- **Ollama API**: Servidor de modelos IA locais (porta 11434)
- **OpenWebUI**: Interface web conversacional (porta 3000)
- **Backend FastAPI**: APIs de gerenciamento (porta 8000)
- **Frontend React**: Dashboard web responsivo
- **PostgreSQL/Redis**: Persistência e cache
- **Prometheus/Grafana**: Monitoramento e métricas

### Fluxo de Dados
```
Usuário → OpenWebUI → Ollama API → Modelo IA → Resposta
                    ↓
            Backend API → Dask Scheduler → Workers
                    ↓
            PostgreSQL/Redis ← Monitoramento
```

## 🚀 INSTALAÇÃO RÁPIDA

### Pré-requisitos
- **Sistema Operacional**: Linux (Ubuntu/Debian/CentOS/Fedora/Arch)
- **Python**: 3.8 ou superior
- **Docker**: 20.10 ou superior
- **Git**: Para controle de versão

### Instalação Automática (Recomendado)

```bash
# Clone o repositório
git clone https://github.com/your-org/cluster-ai.git
cd cluster-ai

# Execute o instalador unificado
./install_unified.sh
```

### Instalação Manual

```bash
# 1. Instalar dependências do sistema
sudo apt update && sudo apt install -y python3 python3-pip docker.io docker-compose git

# 2. Clonar repositório
git clone https://github.com/your-org/cluster-ai.git
cd cluster-ai

# 3. Instalar dependências Python
./install_dependencies.sh

# 4. Configurar ambiente
source cluster-ai-env/bin/activate

# 5. Inicializar serviços
bash scripts/auto_init_project.sh
```

## 🐍 AMBIENTE VIRTUAL PYTHON

**REGRA IMPORTANTE:** Este projeto utiliza exclusivamente o ambiente virtual `cluster-ai-env` para todas as operações Python. **NÃO** utilize outros ambientes virtuais como `venv`, `venv_cluster_ai`, ou `.venv`.

### Configuração do Ambiente Virtual

1. **Instalação automática de dependências:**
   ```bash
   ./install_dependencies.sh
   ```

2. **Ativação manual:**
   ```bash
   source cluster-ai-env/bin/activate
   ```

3. **Verificação:**
   ```bash
   python -c "import flask, fastapi, dask, torch; print('✅ Ambiente OK')"
   ```

### Dependências Principais

- **FastAPI**: Framework web assíncrono
- **Flask**: Framework web para dashboards
- **Dask**: Computação distribuída
- **PyTorch**: Framework de IA
- **Ollama**: Execução de modelos de IA
- **Prometheus/Grafana**: Monitoramento

**IMPORTANTE:** Sempre ative o ambiente virtual `cluster-ai-env` antes de executar qualquer comando Python no projeto.

## 🔧 USO BÁSICO

### Inicialização dos Serviços

Para iniciar os serviços essenciais do projeto, utilize o script de inicialização automática:

```bash
bash scripts/auto_init_project.sh
```

Este script garante que os serviços principais estejam rodando, incluindo o Dashboard Model Registry, o Web Dashboard Frontend e a Backend API.

### Scripts de Inicialização

- **`scripts/auto_init_project.sh`**: Script principal que verifica o status do sistema e chama o script de inicialização de serviços.
- **`scripts/auto_start_services.sh`**: Script dedicado à inicialização automática dos serviços essenciais:
  - **Dashboard Model Registry**: Executa `python ai-ml/model-registry/dashboard/app.py` na porta 5000
  - **Web Dashboard Frontend**: Executa `docker compose up -d frontend`
  - **Backend API**: Executa `docker compose up -d backend`

### Funcionalidades dos Scripts

- **Caminhos Absolutos**: Os scripts utilizam caminhos absolutos baseados em `$PROJECT_ROOT` para garantir funcionamento independente do diretório de execução.
- **Verificações de Status**: Antes de iniciar serviços, os scripts verificam se eles já estão rodando para evitar conflitos.
- **Logs Detalhados**: Todos os eventos são registrados em `logs/auto_init_project.log` e `logs/services_startup.log`.
- **Tratamento de Erros**: Em caso de falha, são exibidas mensagens claras com instruções para correção.
- **Retries Automáticos**: Até 3 tentativas de inicialização com delays configuráveis.

## 🌐 INTERFACES WEB

Após a inicialização, as seguintes interfaces estarão disponíveis:

- **OpenWebUI (Chat IA)**: http://localhost:3000
- **Grafana (Monitoramento)**: http://localhost:3001
- **Prometheus**: http://localhost:9090
- **Kibana (Logs)**: http://localhost:5601
- **Model Registry**: http://localhost:5000
- **Backend API**: http://localhost:8000
- **VSCode Server (AWS)**: http://localhost:8081
- **Android Worker Interface**: http://localhost:8082
- **Jupyter Lab**: http://localhost:8888

## 📊 APIs E ENDPOINTS

### Backend FastAPI (/api)
- `GET /health` - Status do sistema
- `POST /workers` - Gerenciar workers
- `GET /models` - Listar modelos Ollama
- `POST /models/{model}/pull` - Baixar modelo
- `DELETE /models/{model}` - Remover modelo

### Dask
- Dashboard: http://localhost:8787
- API: http://localhost:8786

### Ollama
- API: http://localhost:11434
- Modelos: Lista via `ollama list`

## 🛠️ GERENCIAMENTO DE WORKERS

### Adicionar Worker
```bash
./scripts/management/worker_manager.sh add
```

### Monitorar Workers
```bash
./scripts/management/worker_manager.sh monitor worker-01
```

### Health Check
```bash
./scripts/management/worker_manager.sh health-check all
```

### Auto-scaling
```bash
./scripts/management/worker_manager.sh auto-scale
```

## 🤖 GERENCIAMENTO DE MODELOS

### Listar Modelos Disponíveis
```bash
ollama list
```

### Baixar Modelo
```bash
ollama pull llama2:7b
```

### Executar Modelo
```bash
ollama run llama2:7b
```

## 🧪 TESTES

### Executar Todos os Testes
```bash
./scripts/validation/run_all_tests.sh
```

### Testes Unitários Python
```bash
source cluster-ai-env/bin/activate
pytest tests/ -v --cov
```

### Testes de Integração
```bash
pytest tests/integration/ -v
```

## 🔒 SEGURANÇA

### Validações Implementadas
- Entradas sanitizadas em todos os scripts
- Confirmações para operações críticas
- Logs de auditoria para ações perigosas
- Rollback automático para falhas

### Autenticação
- JWT para APIs web
- SSH keys para workers (sem senha)
- TLS/SSL para comunicações

## 📊 MONITORAMENTO

### Métricas
- CPU/Memória por worker
- Latência de modelos IA
- Uso de rede
- Status de saúde

### Alertas
- Prometheus rules
- Notificações por email/Slack
- Auto-escalabilidade

## 🚀 DEPLOYMENT

### Desenvolvimento
```bash
docker compose up -d
```

### Produção
```bash
docker compose -f docker-compose.prod.yml up -d
```

### Configurar TLS/SSL
```bash
./scripts/security/generate_certificates.sh
```

## 🔄 ATUALIZAÇÕES

### Sistema Automático
- Verificação periódica via cron
- Backup antes de updates
- Rollback em falha
- Notificações de disponibilidade

### Manual
```bash
./scripts/maintenance/auto_updater.sh
```

## 📞 SUPORTE E TROUBLESHOOTING

### Logs do Sistema
- Logs principais: `logs/`
- Diagnóstico: `./manager.sh diag`
- Recuperação: `./scripts/deployment/rollback.sh`

### Problemas Comuns

#### Dashboard Model Registry não inicia
- Verifique se a porta 5000 está livre: `lsof -i :5000`
- Libere a porta se necessário
- Consulte logs: `logs/services_startup.log`

#### Workers não conectam
- Verifique conectividade SSH: `ssh -T user@host`
- Valide chaves SSH: `./scripts/management/worker_manager.sh validate-ssh host user port`
- Consulte logs de worker

#### Modelos IA não carregam
- Verifique instalação Ollama: `ollama --version`
- Liste modelos: `ollama list`
- Baixe modelo: `ollama pull model_name`

### Suporte
- **Documentação**: Este README e docs/
- **Comunidade**: Issues e discussões no GitHub
- **Emergência**: Procedimentos em docs/guides/TROUBLESHOOTING.md

## 📚 DOCUMENTAÇÃO ADICIONAL

- [Instalação Detalhada](docs/manuals/INSTALACAO.md)
- [Ollama e Modelos](docs/manuals/OLLAMA.md)
- [OpenWebUI](docs/manuals/OPENWEBUI.md)
- [Backup e Recuperação](docs/manuals/BACKUP.md)
- [Quick Start](docs/guides/QUICK_START.md)
- [Troubleshooting](docs/guides/TROUBLESHOOTING.md)
- [Otimização](docs/guides/OPTIMIZATION.md)
- [Gerenciamento de Recursos](docs/guides/RESOURCE_MANAGEMENT.md)

## 🤝 CONTRIBUIÇÃO

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

### Padrões de Código
- **Python**: PEP 8, flake8, black, isort
- **Bash**: ShellCheck, comentários detalhados
- **YAML**: yamllint
- **Markdown**: Prettier

### Pre-commit Hooks
```bash
pip install pre-commit
pre-commit install
```

## 📄 LICENÇA

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🙏 AGRADECIMENTOS

- [Ollama](https://ollama.ai/) - Execução local de modelos IA
- [Dask](https://dask.org/) - Computação distribuída
- [FastAPI](https://fastapi.tiangolo.com/) - Framework web moderno
- [Docker](https://www.docker.com/) - Containerização
- [Prometheus](https://prometheus.io/) - Monitoramento

---

**Cluster AI v2.0.0** - Sistema Universal de IA Distribuída
