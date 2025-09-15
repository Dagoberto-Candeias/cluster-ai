# 🚀 Cluster AI - Sistema Universal de IA Distribuída

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

## 📖 Visão Geral

O Cluster AI é um sistema completo para implantação de clusters de IA com processamento distribuído usando **Dask**, **Ollama** e **OpenWebUI**.

### ✨ Características Principais

- **🤖 Universal**: Funciona em qualquer distribuição Linux
- **⚡ Performance**: Otimizado para GPU NVIDIA/AMD
- **🔧 Pronto**: Scripts automatizados e documentação completa
- **🚀 Produtivo**: VSCode com 25 extensões essenciais
- **📊 Escalável**: Processamento distribuído com Dask

## 🚀 Comece Agora

### Instalação Rápida (5 minutos)

```bash
# Clone o repositório
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
cd cluster-ai

# Instalação completa
sudo ./install_cluster_universal.sh

# Ou instalação tradicional
./install_cluster.sh
```

### 📦 O que é Instalado

| Componente | Descrição | URL |
|------------|-----------|-----|
| **Dask Cluster** | Processamento distribuído | http://localhost:8787 |
| **Ollama** | Modelos de IA local | http://localhost:11434 |
| **OpenWebUI** | Interface web | http://localhost:8080 |
| **VSCode** | IDE otimizada | - |

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
| `install_cluster_universal.sh` | Instalador universal | `sudo ./install_cluster_universal.sh` |
| `install_cluster.sh` | Menu interativo | `./install_cluster.sh` |
| `health_check.sh` | Verificação do sistema | `./scripts/utils/health_check.sh` |
| `check_models.sh` | Gerenciar modelos | `./scripts/utils/check_models.sh` |

## 🎯 Exemplos Práticos

### Processamento Distribuído

```python
from dask.distributed import Client
client = Client('localhost:8786')
print(f"Workers: {len(client.scheduler_info()['workers'])}")
```

### IA com Ollama

```python
import requests
response = requests.post('http://localhost:11434/api/generate', json={
    'model': 'llama3', 
    'prompt': 'Explique IA'
})
print(response.json()['response'])
```

## 🏗️ Arquitetura

### Camadas do Sistema

1. **🖥️ Sistema (sudo)**: Docker, drivers GPU, IDEs, serviços
2. **🐍 Ambiente (.venv)**: PyTorch, bibliotecas ML, dependências

### Distribuições Suportadas

- ✅ Ubuntu/Debian
- ✅ Arch/Manjaro  
- ✅ Fedora/CentOS/RHEL
- ✅ Outras (modo fallback)

## 📊 Status do Projeto

**✅ Concluído**: 85%**
- Instalador universal funcionando
- Suporte completo a GPU
- Documentação organizada
- Scripts de backup e saúde

**🔜 Em Andamento**: 
- Testes em múltiplas distros
- Otimização final
- CI/CD automation

## 🤝 Contribuindo

Consulte nosso [Guia de Contribuição](CONTRIBUTING.md) para:
- Reportar bugs
- Sugerir features
- Enviar PRs
- Melhorar documentação

## 📞 Suporte

- **📚 Documentação**: Consulte os manuais
- **🐛 Issues**: Reporte problemas no GitHub
- **💬 Comunidade**: Participe das discussões

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja [LICENSE.txt](LICENSE.txt) para detalhes.

---

**✨ Dica**: Use `./install_cluster.sh` para acessar o menu completo!

**🚀 Próximos Passos**:
1. Execute a instalação
2. Consulte o guia prático
3. Explore os exemplos
4. Participe da comunidade!

*Última atualização: $(date +%Y-%m-%d)*
