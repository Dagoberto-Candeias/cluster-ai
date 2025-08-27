# Cluster AI - Ambiente Universal de Desenvolvimento e Processamento Distribuído

![GitHub](https://img.shields.io/github/license/Dagoberto-Candeias/cluster-ai)
![GitHub issues](https://img.shields.io/github/issues/Dagoberto-Candeias/cluster-ai)
![GitHub release](https://img.shields.io/github/v/release/Dagoberto-Candeias/cluster-ai)
![Platform](https://img.shields.io/badge/platform-linux%20universal-blue)

Sistema completo para desenvolvimento e implantação de clusters de IA com processamento distribuído usando Dask, Ollama, OpenWebUI e ambiente de desenvolvimento universal.

## 🎯 NOVAS FUNCIONALIDADES

### 🚀 Instalador Universal
- **Suporte a múltiplas distribuições**: Ubuntu, Debian, Manjaro, Arch, CentOS, RHEL, Fedora
- **Detecção automática**: Identifica a distribuição e instala pacotes apropriados
- **Modo texto/gráfico**: Funciona com ou sem interface gráfica

### 💻 Ambiente de Desenvolvimento Completo
- **VS Code Otimizado**: 25 extensões essenciais pré-configuradas
- **Spyder e PyCharm**: IDEs Python completas
- **Configurações otimizadas**: Settings pré-ajustados para Python/IA

### ⚡ Performance e Usabilidade
- **Instalação enxuta**: Apenas o necessário, sem bloat
- **Boot rápido**: Ambiente pronto em minutos
- **Fácil manutenção**: Scripts modulares e documentados

## 🚀 INSTALAÇÃO RÁPIDA

### Método Universal (Recomendado)
```bash
# Clone o repositório
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
cd cluster-ai

# Instalação universal
./install_universal.sh
```

### Método Automático (Single Machine)
```bash
# Instalação automática em uma única máquina
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/install_cluster.sh)"
```

## 🛠️ OPÇÕES DE INSTALAÇÃO

O instalador universal oferece múltiplas opções:

1. **Instalação Completa** (Recomendado) - Tudo em um só comando
2. **Apenas Dependências** - Sistema operacional e bibliotecas base
3. **Apenas Python** - Ambiente virtual com todas as bibliotecas
4. **Apenas IDEs** - Ferramentas de desenvolvimento
5. **Configurar Cluster** - Definir papel da máquina no cluster

## 📦 EXTENSÕES ESSENCIAIS DO VS CODE

### 🐍 Python Development (6)
- `ms-python.python` - Suporte essencial Python
- `ms-python.vscode-pylance` - Language server rápido  
- `ms-python.debugpy` - Debugging avançado
- `ms-python.pylint` - Linting e análise
- `ms-python.autopep8` - Formatação automática
- `kevinrose.vsc-python-indent` - Indentação inteligente

### 🤖 IA Assistants (4)
- `github.copilot` - GitHub Copilot
- `github.copilot-chat` - Chat com Copilot
- `blackboxapp.blackbox` - BLACKBOX AI
- `sourcegraph.cody-ai` - Cody AI assistant

### 🔧 Development Tools (8)
- `eamodio.gitlens` - Git superpoderes
- `ms-azuretools.vscode-docker` - Gerenciamento Docker
- `ms-vscode-remote.remote-containers` - Dev Containers
- `streetsidesoftware.code-spell-checker` - Spell checker
- `usernamehw.errorlens` - Erros em tempo real
- `yzhang.markdown-all-in-one` - Tudo para Markdown
- `dracula-theme.theme-dracula` - Tema Dracula
- `pkief.material-icon-theme` - Ícones Material

### 📊 Jupyter (1)
- `ms-toolsai.jupyter` - Suporte a Jupyter Notebooks

**Total: 25 extensões** (vs 80+ anterior) - 70% menos, muito mais foco!

## ⚡ SISTEMA DE GERENCIAMENTO DE RECURSOS

### Recursos Avançados
- **✅ Memória Auxiliar Auto-Expansível**: Swap dinâmico SSD (2G-16G)
- **✅ Otimização Automática**: Configurações baseadas no hardware
- **✅ Monitoramento Contínuo**: Previne travamentos e falta de memória
- **✅ Verificação Pré-Instalação**: Garante recursos mínimos
- **✅ Suporte Multi-Interface**: Wi-Fi + Ethernet simultâneas

### Scripts de Gerenciamento
- `scripts/utils/resource_checker.sh` - Verificação completa de recursos
- `scripts/utils/memory_manager.sh` - Gerenciamento de memória e swap
- `scripts/utils/resource_optimizer.sh` - Otimização automática
- `scripts/utils/memory_stress_test.sh` - Testes de estresse

## 🎮 COMO USAR

### Ambiente de Desenvolvimento
```bash
# Ativar ambiente Python
source ~/cluster_env/bin/activate

# Abrir projeto no VS Code
code .

# Executar demonstrações
python demo_cluster.py
python simple_demo.py

# Testar instalação
python test_installation.py
```

### Cluster Management
```bash
# Configurar papel da máquina
./scripts/installation/main.sh

# Acessar dashboards
http://localhost:8787    # Dask Dashboard
http://localhost:8080    # OpenWebUI
http://localhost:11434   # Ollama API
```

## 🔧 ESTRUTURA DO PROJETO

```
cluster-ai/
├── 📁 scripts/           # Scripts de gerenciamento
│   ├── 📁 installation/  # Instalação universal
│   ├── 📁 utils/         # Utilitários do sistema
│   └── 📁 validation/    # Testes e validação
├── 📁 docs/             # Documentação completa
├── 📁 configs/          # Configurações do sistema
├── 📁 deployments/      # Configurações de deploy
├── 📁 examples/         # Exemplos de código
├── 📄 install_universal.sh  # Instalador universal
├── 📄 requirements.txt  # Dependências Python
└── 📄 .gitignore       # Arquivos ignorados pelo Git
```

## 📚 DOCUMENTAÇÃO

- [ESTRUTURA_PROJETO.md](ESTRUTURA_PROJETO.md) - Estrutura detalhada
- [DEMO_README.md](DEMO_README.md) - Guia de demonstrações
- [EXTENSOES_ESSENCIAIS_VSCODE.md](EXTENSOES_ESSENCIAIS_VSCODE.md) - Lista de extensões
- [PLANO_MELHORIAS_DEV_ENV.md](PLANO_MELHORIAS_DEV_ENV.md) - Plano de melhorias

## 🐛 SUPORTE

Para problemas ou dúvidas:
1. Consulte a documentação acima
2. Execute `python test_installation.py` para diagnóstico
3. Verifique os logs em `~/scheduler.log` e `~/worker.log`

## 📄 LICENÇA

Este projeto está licenciado sob a MIT License - veja [LICENSE.txt](LICENSE.txt) para detalhes.

---

**🎉 PRONTO PARA DESENVOLVIMENTO!** Seu ambiente universal de IA está configurado!
