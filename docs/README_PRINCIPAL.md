# 🚀 Cluster AI - Sistema Completo de Processamento Distribuído de IA

![GitHub](https://img.shields.io/github/license/Dagoberto-Candeias/cluster-ai)
![GitHub issues](https://img.shields.io/github/issues/Dagoberto-Candeias/cluster-ai)
![GitHub release](https://img.shields.io/github/v/release/Dagoberto-Candeias/cluster-ai)

Sistema integrado para implantação de clusters de IA com processamento distribuído usando **Dask**, **Ollama** e **OpenWebUI**.

## 📋 Índice Rápido

- [✨ Funcionalidades](#-funcionalidades)
- [🚀 Instalação Rápida](#-instalação-rápida)
- [🏗️ Arquitetura do Sistema](#️-arquitetura-do-sistema)
- [📚 Documentação Completa](#-documentação-completa)
- [⚙️ Configuração](#️-configuração)
- [🔧 Scripts e Ferramentas](#-scripts-e-ferramentas)
- [🎯 Exemplos de Uso](#-exemplos-de-uso)
- [🛡️ Segurança](#️-segurança)
- [❓ FAQ](#-faq)
- [📞 Suporte](#-suporte)

## ✨ Funcionalidades

### 🤖 Processamento Distribuído
- **Dask Cluster**: Computação paralela distribuída
- **Escalabilidade Horizontal**: Adicione workers conforme necessário
- **Dashboard Integrado**: Monitoramento em tempo real

### 🧠 Modelos de IA Locais
- **Ollama Integrado**: Execute modelos de linguagem localmente
- **Multi-modelos**: Suporte a diversos modelos (LLaMA, Mistral, DeepSeek, etc.)
- **Otimização GPU**: Configuração automática para NVIDIA e AMD

### 🌐 Interface Web
- **OpenWebUI**: Interface moderna para interagir com modelos
- **TLS/SSL**: Configuração segura para produção
- **Multi-usuário**: Suporte a autenticação e sessões

### 💻 Ferramentas de Desenvolvimento
- **IDEs Integradas**: Spyder, VSCode, PyCharm
- **Ambientes Virtuais**: Isolamento completo por projeto
- **Backup Automático**: Sistema robusto de backup e restore

## 🚀 Instalação Rápida

### Instalação via Repositório (Recomendado)
```bash
# Clone o repositório
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
cd cluster-ai

# Execute o instalador universal
./install_universal.sh
```

**💡 Nota**: O script `install_universal.sh` é o ponto de entrada principal e guiará você por todas as opções de instalação, seja para uma máquina local ou para configurar os nós de um cluster.

### Instalação em Múltiplas Máquinas (Cluster)
```bash
# Em cada máquina do cluster, execute o instalador universal
./install_universal.sh

# Siga o menu interativo para definir o papel de cada máquina
```

**💡 Nota**: O projeto agora inclui um script wrapper `install_cluster.sh` no diretório raiz para facilitar o acesso. Consulte [INSTALACAO_LOCAL.md](../INSTALACAO_LOCAL.md) para mais detalhes.

## 🛠️ Painel de Controle (`manager.sh`)

O script `manager.sh` na raiz do projeto é a principal ferramenta para gerenciar seu cluster. Ele oferece um menu interativo para controlar todos os serviços.

**Uso:**
```bash
# A partir do diretório raiz do projeto
./manager.sh
```

**Funcionalidades do Gerenciador:**
- Iniciar, parar e reiniciar todos os serviços de uma só vez.
- Gerenciar cada serviço (Ollama, Dask, OpenWebUI) individualmente.
- Visualizar o status geral do cluster.
- Acessar scripts de diagnóstico (Health Check) e otimização.

## 🏗️ Arquitetura do Sistema

### Diagrama de Arquitetura
```
[Servidor Principal]
├── Dask Scheduler (Porta 8786)
├── Dask Dashboard (Porta 8787)
├── OpenWebUI (Porta 8080)
├── Ollama API (Porta 11434)
└── Dask Worker (Processamento)

[Estações de Trabalho]
├── Dask Worker (Conecta ao Scheduler)
├── Spyder IDE
├── VSCode IDE
└── PyCharm IDE

[Workers Dedicados]
└── Dask Worker (Apenas processamento)
```

### Portas Utilizadas
| Serviço | Porta | Protocolo | Descrição |
|---------|-------|-----------|-----------|
| Dask Scheduler | 8786 | TCP | Coordenação do cluster |
| Dask Dashboard | 8787 | TCP | Monitoramento web |
| OpenWebUI | 8080 | TCP | Interface web |
| Ollama API | 11434 | TCP | API de modelos de IA |
| SSH | 22 | TCP | Acesso remoto |

## 📚 Documentação Completa

### Manuais Detalhados
- **[Guia de Instalação](docs/manuals/INSTALACAO.md)** - Instalação passo a passo
- **[Guia de Configuração](docs/manuals/CONFIGURACAO.md)** - Configuração avançada
- **[Manual do Ollama](docs/manuals/OLLAMA.md)** - Modelos e uso de IA
- **[Guia OpenWebUI](docs/manuals/OPENWEBUI.md)** - Interface web
- **[Backup e Restauração](docs/manuals/BACKUP.md)** - Sistema de backup

### Guias Rápidos
- **[Quick Start](docs/guides/QUICK_START.md)** - Comece em 5 minutos
- **[Exemplos Práticos](examples/)** - Códigos de exemplo
- **[Solução de Problemas](docs/guides/TROUBLESHOOTING.md)** - FAQ e soluções

## ⚙️ Configuração

### Papéis das Máquinas
Durante a instalação, escolha o papel:

1. **Servidor Principal**: Coordenação + Serviços + Worker
2. **Estação de Trabalho**: Worker + IDEs de desenvolvimento  
3. **Apenas Worker**: Dedicação total ao processamento
4. **Converter para Servidor**: Promover estação para servidor

### Variáveis de Configuração
```bash
# Arquivo: ~/.cluster_role
ROLE=server
SERVER_IP=localhost
MACHINE_NAME=meu-servidor
BACKUP_DIR=/caminho/backups
```

## 🔧 Scripts e Ferramentas

### Scripts Principais
| Script | Localização | Descrição |
|--------|-------------|-----------|
| `install_cluster.sh` | `scripts/installation/` | Instalação principal |
| `deploy_cluster.sh` | `scripts/deployment/` | Deploy em produção |
| `backup_manager.sh` | `scripts/backup/` | Gerenciamento de backup |
| `update_models.sh` | `scripts/maintenance/` | Atualização de modelos |

### Comandos Úteis
```bash
# Verificar status do cluster
./install_cluster.sh --status

# Fazer backup
./install_cluster.sh --backup

# Restaurar backup  
./install_cluster.sh --restore

# Agendar backups
./install_cluster.sh --schedule
```

## 🎯 Exemplos de Uso

### Processamento Distribuído
```python
from dask.distributed import Client

# Conectar ao cluster
client = Client('servidor:8786')

# Processamento distribuído
import dask.array as da
x = da.random.random((10000, 10000), chunks=(1000, 1000))
result = (x + x.T).mean().compute()
```

### Integração com Ollama
```python
import requests

def ask_ai(prompt, model="llama3"):
    response = requests.post(
        'http://localhost:11434/api/generate',
        json={'model': model, 'prompt': prompt, 'stream': False}
    )
    return response.json()['response']

resposta = ask_ai("Explique machine learning")
```

### Análise de Sentimento Distribuída
```python
from dask.distributed import Client
import dask.bag as db

def analyze_sentiment(text):
    # Integração com Ollama para análise
    return ask_ai(f"Analise sentimento: {text}. Responda com POSITIVO/NEGATIVO/NEUTRO")

# Processamento paralelo
texts = ["Texto 1", "Texto 2", "Texto 3"]
results = db.from_sequence(texts).map(analyze_sentiment).compute()
```

## 🛡️ Segurança

### 🔒 Segurança de Scripts e Prevenção de Corrupção
O Cluster AI inclui proteções avançadas contra operações acidentais:

#### ✅ Funções de Segurança Implementadas
- **Validação de Caminhos**: Bloqueia operações em diretórios críticos do sistema (`/`, `/usr`, `/bin`, `/etc`)
- **Confirmação do Usuário**: Requer aprovação explícita para operações destrutivas
- **Prevenção de Execução como Root**: Scripts falham se executados como usuário root
- **Validação de Valores**: Verifica todos os inputs numéricos antes do uso

#### 📋 Scripts Seguros Disponíveis
```bash
# Gerenciador de Memória Seguro
./scripts/utils/memory_manager_secure.sh start

# Health Check Seguro  
./scripts/utils/health_check_secure.sh

# Otimizador de Recursos com Validação
./scripts/utils/resource_optimizer.sh optimize
```

#### 🛡️ Proteções Ativas
- ✅ Bloqueio de operações em diretórios críticos do sistema
- ✅ Validação de caminhos vazios e inválidos
- ✅ Confirmação obrigatória para limpeza de logs e arquivos temporários
- ✅ Verificação de privilégios sudo antes de operações privilegiadas

Consulte [SECURITY_IMPROVEMENTS_SUMMARY.md](../SECURITY_IMPROVEMENTS_SUMMARY.md) para detalhes completos.

### 🔐 Segurança de Rede

#### Configuração de Firewall
```bash
# Configuração recomendada
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 8786/tcp  # Dask Scheduler
sudo ufw allow 8787/tcp  # Dask Dashboard  
sudo ufw allow 8080/tcp  # OpenWebUI
sudo ufw allow 11434/tcp # Ollama API
sudo ufw enable
```

#### TLS/SSL para Produção
Consulte [Deploy com TLS](deployments/production/README.md) para configuração segura com:
- Certificados Let's Encrypt
- Nginx como reverse proxy
- Configuração HTTPS

## ❓ FAQ

### ❓ Posso usar com IPs dinâmicos?
✅ Sim, o sistema inclui mecanismos de reconexão automática.

### ❓ Como adicionar mais workers?
✅ Instale o script em nova máquina e configure como "Apenas Worker".

### ❓ Suporte a GPU?
✅ Detecta automaticamente GPUs NVIDIA/AMD e configura otimização.

### ❓ Funciona offline?
✅ O processamento Dask funciona offline, mas download de modelos requer internet.

### ❓ Como fazer backup dos modelos?
✅ Os backups incluem modelos Ollama automaticamente.

## 📞 Suporte

### Documentação Oficial
- **[Dask](https://docs.dask.org/)** - Documentação do Dask
- **[Ollama](https://ollama.ai/)** - Modelos de IA local
- **[OpenWebUI](https://docs.openwebui.com/)** - Interface web

### Comunidade e Issues
- **[GitHub Issues](https://github.com/Dagoberto-Candeias/cluster-ai/issues)** - Reportar problemas
- **[Discussions](https://github.com/Dagoberto-Candeias/cluster-ai/discussions)** - Discussões da comunidade

### Contribuição
Consulte [CONTRIBUTING.md](CONTRIBUTING.md) para guidelines de contribuição.

---

## 📄 Licença

Este projeto está licenciado sob a MIT License - veja [LICENSE.txt](LICENSE.txt) para detalhes.

## 🏆 Créditos

Desenvolvido por [Dagoberto Candeias](https://github.com/Dagoberto-Candeias) com contribuições da comunidade.

---

**✨ Dica**: Comece com o [Guia Rápido](docs/guides/QUICK_START.md) para ter seu cluster funcionando em minutos!
