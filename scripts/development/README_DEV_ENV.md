# 🧰 Ambiente de Desenvolvimento Universal - Cluster AI

Script de configuração automatizada para ambiente de desenvolvimento compatível com qualquer desktop (KDE, GNOME, XFCE, etc.) e otimizado para desenvolvimento com Python, Dask, Ollama e IA.

## 📦 O que é instalado

### 🐍 Python e Ferramentas
- Python 3.11+ com pip e venv
- Ambiente virtual em `~/venv`
- FastAPI, Uvicorn, pytest
- JupyterLab e Notebooks
- NumPy, Pandas, Matplotlib, Scipy

### 🐳 Docker e Containers
- Docker Engine
- Docker Compose
- Usuário adicionado ao grupo docker

### 🖥️ Visual Studio Code
- VS Code oficial da Microsoft
- 80+ extensões pré-configuradas
- Suporte a Python, IA, Docker, Git

### 🛠️ Ferramentas de Desenvolvimento
- Git, curl, wget, unzip
- Build-essential e compiladores
- SSH server, net-tools
- Htop, tree, tmux, ncdu

### 🎨 Extensões VS Code Incluídas

#### 🤖 IA e Assistants
- GitHub Copilot e Copilot Chat
- Continue, CodeGPT, BLACKBOX
- AskCodi, Google Gemini, Cody AI

#### 🐍 Python e Data Science
- Python Extension Pack
- Pylance, Pylint, Debugpy
- Jupyter, Autopep8, YAPF
- AutoDocString, Python Snippets

#### 🐳 Docker e Containers
- Docker Extension
- Remote Containers
- MySQL Client

#### 🌐 Web Development
- Prettier, ESLint
- Auto Close Tag, Auto Rename Tag
- Tailwind CSS, Live Server

#### 📝 Documentação
- Markdown All in One
- PDF Viewer
- Spell Checker (PT-BR e EN)

#### ⚙️ Utilitários
- GitLens, Git History
- Bookmarks, Better Comments
- Rainbow CSV, Polacode
- Material Icon Theme

## 🚀 Como usar

### Instalação Rápida
```bash
# Dar permissão de execução
chmod +x scripts/development/setup_dev_environment.sh

# Executar instalação
./scripts/development/setup_dev_environment.sh
```

### Instalação pelo Menu Principal
```bash
# Pelo script principal do Cluster AI
./install_cluster.sh

# Escolher opção de ambiente de desenvolvimento quando disponível
```

### Comandos Após Instalação

```bash
# Recarregar configurações do terminal
source ~/.bashrc

# Ver informações do ambiente
dev-env

# Ativar ambiente virtual
venv-activate

# Abrir VS Code no diretório atual
code-proj
```

## 🎯 Compatibilidade

### ✅ Sistemas Suportados
- **Ubuntu** 20.04, 22.04, 24.04
- **Debian** 11, 12
- **Distribuições baseadas em Debian/Ubuntu**

### ✅ Ambientes Desktop
- **KDE Plasma** ✓
- **GNOME** ✓  
- **XFCE** ✓
- **LXDE** ✓
- **MATE** ✓
- **Qualquer outro desktop** ✓

### ❌ Sistemas Não Suportados
- Windows (use WSL2)
- macOS (script específico necessário)
- Distribuições não baseadas em Debian

## ⚙️ Personalização

### Adicionar Extensões
Edite o array `vscode_extensions` no script para adicionar mais extensões.

### Configurar Aliases
Os aliases são adicionados ao `~/.bashrc`:
- `dev-env`: Mostra informações do ambiente
- `venv-activate`: Ativa o ambiente virtual
- `code-proj`: Abre VS Code no diretório atual

### Ambiente Virtual
O ambiente virtual é criado em `~/venv` e pode ser ativado com:
```bash
source ~/venv/bin/activate
```

## 🔧 Solução de Problemas

### Extensões não instalam
Algumas extensões podem falhar na instalação automática. Instale manualmente:
```bash
code --install-extension NOME_DA_EXTENSAO
```

### Docker sem permissão
Se tiver problemas com Docker, execute:
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### VS Code não encontrado
Se o comando `code` não funcionar, reinicie o terminal ou execute:
```bash
source ~/.bashrc
```

## 📊 Verificação da Instalação

### Testar Componentes
```bash
# Verificar Python
python3 --version
pip --version

# Verificar Docker
docker --version
docker-compose --version

# Verificar VS Code
code --version

# Verificar extensões instaladas
code --list-extensions
```

### Testar Ambiente Virtual
```bash
source ~/venv/bin/activate
python -c "import numpy, pandas, fastapi; print('✅ Todas as bibliotecas funcionando')"
deactivate
```

## 🎉 Pronto para Desenvolver!

Com este ambiente você pode:

1. **Desenvolver aplicações Python** com todas as ferramentas
2. **Trabalhar com Dask e processamento distribuído**
3. **Integrar com Ollama e modelos de IA**
4. **Usar Docker para containers e desenvolvimento**
5. **Ter todas as extensões VS Code necessárias**

## 🔄 Integração com Cluster AI

Para desenvolvimento específico do Cluster AI, instale também:
```bash
./install_cluster.sh --role workstation
```

Isso adicionará:
- Dask cluster configuration
- Ollama integration  
- OpenWebUI setup
- Ferramentas específicas de IA

---

**📞 Suporte**: Consulte a documentação principal do Cluster AI para mais informações.

**🐛 Problemas**: Abra uma issue no repositório do projeto.
