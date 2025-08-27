# 🚀 Cluster AI - Sistema Universal de Instalação

Sistema completo de cluster de IA com suporte universal para qualquer distribuição Linux, otimizado para performance e facilidade de uso.

## 📋 Características Principais

### ✅ Universalidade
- **Suporte a múltiplas distribuições**: Ubuntu, Debian, Arch, Manjaro, Fedora, CentOS, RHEL
- **Detecção automática**: O sistema identifica sua distribuição e instala os pacotes apropriados
- **Fallback inteligente**: Funciona mesmo em distribuições não totalmente suportadas

### 🎯 Performance Otimizada
- **GPU Automática**: Detecção e configuração automática de NVIDIA CUDA e AMD ROCm
- **PyTorch Otimizado**: Instalação com suporte apropriado para sua GPU
- **VSCode Leve**: Apenas 25 extensões essenciais (em vez de 80+)

### 🔧 Separação Clara de Camadas
- **Sistema (sudo)**: Drivers, Docker, IDEs, serviços
- **Ambiente Virtual (user)**: PyTorch, bibliotecas ML, dependências do projeto

## 🛠️ Scripts Principais

### 1. `install_cluster_universal.sh` (Recomendado)
Instalação completa do sistema com suporte universal.

```bash
sudo ./install_cluster_universal.sh
```

### 2. `install_cluster.sh` (Tradicional)
Menu interativo com todas as opções.

```bash
./install_cluster.sh
```

### 3. Scripts Específicos
- `scripts/installation/universal_install.sh` - Instalador universal do sistema
- `scripts/installation/venv_setup.sh` - Configuração do ambiente Python
- `scripts/installation/vscode_optimized.sh` - VSCode com 25 extensões
- `scripts/utils/health_check.sh` - Verificação de saúde do sistema

## 📦 Componentes Instalados

### 🖥️ Camada do Sistema (requer sudo)
- **Docker** e Docker Compose para containerização
- **Drivers GPU**: Suporte automático para NVIDIA CUDA e AMD ROCm
- **VSCode** com 25 extensões essenciais otimizadas
- **Ferramentas essenciais**: git, curl, wget, Python 3
- **Serviços**: Ollama (modelos LLM), Dask scheduler (processamento distribuído)

### 🐍 Ambiente Virtual Python
- **PyTorch** com suporte GPU apropriado detectado automaticamente
- **Bibliotecas ML**: numpy, pandas, scikit-learn, matplotlib, seaborn
- **Frameworks**: FastAPI (APIs), JupyterLab (notebooks), Dask client
- **Ferramentas desenvolvimento**: pytest, httpx, uvicorn

## 🚀 Como Usar

### 📥 Instalação Completa (Recomendado)
```bash
# Clone o repositório (substitua pela URL real)
git clone https://github.com/seu-usuario/cluster-ai.git
cd cluster-ai

# Instalação universal completa
sudo ./install_cluster_universal.sh
```

### 🔧 Instalação Modular
```bash
# Apenas sistema base + Docker
sudo ./scripts/installation/universal_install.sh

# Apenas ambiente Python com ML
./scripts/installation/venv_setup.sh

# Apenas VSCode otimizado
sudo ./scripts/installation/vscode_optimized.sh
```

### ✅ Verificação do Sistema
```bash
# Verificar saúde completa do sistema
./scripts/utils/health_check.sh

# Testar detecção e configuração da GPU
python scripts/utils/test_gpu.py

# Verificar PyTorch e suporte CUDA
python -c "import torch; print(f'PyTorch {torch.__version__}, CUDA: {torch.cuda.is_available()}')"
```

## 🎯 Fluxo de Instalação Recomendado

1. **Instalação Universal**: `sudo ./install_cluster_universal.sh`
2. **Verificação**: `./scripts/utils/health_check.sh`
3. **Configuração do Papel**: `./install_cluster.sh` (opção 2)
4. **Testes**: `./scripts/validation/run_complete_test_modified.sh`

## 🔧 Personalização

### Variáveis de Ambiente
O sistema cria `~/.cluster_ai_env` com:
- Caminho do ambiente virtual
- Aliases úteis (`venv-activate`, `cluster-status`)
- Configurações de performance

### Extensões do VSCode
Apenas 25 extensões essenciais instaladas:
- Python e IA (6)
- Git e Versionamento (3) 
- Docker e Containers (2)
- Web Development (3)
- Markdown e Documentação (2)
- Utilitários Essenciais (6)
- Temas (3)

## 🐛 Solução de Problemas

### Verificar Logs
```bash
# Log da instalação universal
tail -f /var/log/cluster_ai_install/universal_install.log

# Log do ambiente virtual
tail -f /tmp/venv_setup_logs/*
```

### Reinstalação
```bash
# Recriar ambiente virtual
rm -rf ~/venv
./scripts/installation/venv_setup.sh

# Reinstalar VSCode
sudo ./scripts/installation/vscode_optimized.sh
```

## 📊 Distribuições Suportadas

### Totalmente Suportadas
- ✅ Ubuntu 18.04+
- ✅ Debian 10+
- ✅ Arch Linux
- ✅ Manjaro
- ✅ Fedora 30+
- ✅ CentOS 8+
- ✅ RHEL 8+

### Suporte Parcial
- Outras distribuições baseadas nas acima
- Modo fallback com instalação genérica

## 🎉 Resultado Esperado

Um ambiente Cluster AI completo que:
- ✅ Funciona em QUALQUER distribuição Linux
- ✅ Tem suporte completo a GPU (NVIDIA/AMD)  
- ✅ VSCode otimizado com 25 extensões essenciais
- ✅ Separação clara entre sistema e ambiente virtual
- ✅ Sistema de saúde e monitoramento robusto
- ✅ Fácil de usar e manter

---

**📞 Suporte**: Consulte `docs/guides/TROUBLESHOOTING.md` para ajuda adicional
**🐛 Issues**: Reporte problemas no sistema de issues do repositório
**🔄 Atualizações**: Execute `git pull` regularmente para obter as últimas melhorias
