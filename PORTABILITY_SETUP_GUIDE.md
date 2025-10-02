# 🚀 GUIA DE CONFIGURAÇÃO PARA NOVOS AMBIENTES - CLUSTER AI

## 🎯 OBJETIVO
Garantir que o projeto Cluster AI seja totalmente portável e possa ser configurado corretamente em qualquer novo ambiente (computador, servidor, etc.) sem perda de funcionalidade.

## 📋 PRÉ-REQUISITOS DO SISTEMA

### Sistema Operacional
- **Linux:** Ubuntu 20.04+ ou Debian 11+
- **Python:** 3.8 ou superior (recomendado 3.11+)
- **Docker:** 24.0+ com Docker Compose
- **Git:** 2.30+

### Verificação de Pré-requisitos
```bash
# Verificar Python
python3 --version

# Verificar Docker
docker --version
docker compose version

# Verificar Git
git --version

# Verificar espaço em disco (mínimo 10GB)
df -h .
```

## 🛠️ PROCEDIMENTO DE CONFIGURAÇÃO

### 1. Clonagem do Repositório
```bash
git clone https://github.com/[seu-usuario]/cluster-ai.git
cd cluster-ai
```

### 2. Configuração do Ambiente Virtual
```bash
# Executar script de instalação automática
bash install_dependencies.sh
```

**IMPORTANTE:** Este script irá:
- ✅ Verificar versão do Python
- ✅ Criar ambiente virtual `cluster-ai-env`
- ✅ Instalar todas as dependências do `requirements.txt`
- ✅ Instalar dependências de desenvolvimento (se existir `requirements-dev.txt`)
- ✅ Verificar instalação das bibliotecas principais

### 3. Verificação da Configuração
```bash
# Ativar ambiente virtual
source cluster-ai-env/bin/activate

# Verificar bibliotecas principais
python -c "import flask, fastapi, dask, torch, ollama; print('✅ Dependências OK')"

# Verificar versão do Python no ambiente
python --version
which python
```

### 4. Configuração do Docker (se necessário)
```bash
# Verificar Docker
docker info

# Construir/verificar containers
docker compose config
```

### 5. Configuração do Ollama
```bash
# Verificar instalação
ollama --version

# Listar modelos disponíveis
ollama list

# Se necessário, instalar modelos básicos
ollama pull llama2:7b
```

## 🔧 CONFIGURAÇÕES ESPECÍFICAS POR AMBIENTE

### Ambiente de Desenvolvimento (VSCode)
```bash
# Instalar extensões recomendadas
code --install-extension ms-python.python
code --install-extension ms-vscode.vscode-docker
code --install-extension ms-vscode.vscode-json

# Abrir projeto no VSCode
code .
```

### Ambiente de Produção/Servidor
```bash
# Configurar variáveis de ambiente
cp .env.example .env
nano .env  # Editar configurações específicas

# Configurar systemd (opcional)
sudo cp scripts/systemd/cluster-ai.service /etc/systemd/system/
sudo systemctl enable cluster-ai
```

## 📊 VERIFICAÇÃO DE FUNCIONAMENTO

### Teste Básico
```bash
# Ativar ambiente
source cluster-ai-env/bin/activate

# Executar diagnóstico
bash diagnostic_report.sh

# Executar testes básicos
python -m pytest tests/ -v --tb=short
```

### Teste de Serviços
```bash
# Inicializar projeto
bash scripts/auto_init_project.sh

# Verificar status
bash scripts/auto_start_services.sh
```

### Teste de Workers
```bash
# Verificar configuração
cat cluster.yaml

# Testar worker manager
bash scripts/management/worker_manager.sh status
```

## 🚨 PROBLEMAS COMUNS E SOLUÇÕES

### Problema: Ambiente virtual não criado
```bash
# Solução: Verificar permissões e Python
python3 -m venv cluster-ai-env
source cluster-ai-env/bin/activate
pip install -r requirements.txt
```

### Problema: Dependências não instaladas
```bash
# Solução: Reinstalar no ambiente virtual
source cluster-ai-env/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### Problema: Docker não funciona
```bash
# Solução: Verificar instalação e permissões
sudo systemctl start docker
sudo usermod -aG docker $USER
# Reiniciar sessão
```

### Problema: Ollama não encontrado
```bash
# Solução: Instalar Ollama
curl -fsSL https://ollama.ai/install.sh | sh
ollama serve &
```

### Problema: Portas ocupadas
```bash
# Solução: Verificar e liberar portas
netstat -tlnp | grep :5000
sudo fuser -k 5000/tcp
```

## 📁 ESTRUTURA ESPERADA APÓS CONFIGURAÇÃO

```
cluster-ai/
├── cluster-ai-env/          # Ambiente virtual (não versionado)
├── scripts/                 # Scripts de automação
├── ai-ml/                   # Componentes de IA
├── tests/                   # Testes automatizados
├── logs/                    # Logs de execução
├── models/                  # Modelos armazenados
├── docker-compose.yml       # Configuração Docker
├── requirements.txt         # Dependências Python
└── cluster.yaml            # Configuração do cluster
```

## 🔄 MIGRAÇÃO ENTRE AMBIENTES

### Exportar Configurações
```bash
# Salvar configurações específicas
cp cluster.yaml cluster.yaml.backup
cp .env .env.backup 2>/dev/null || true
```

### Importar Configurações
```bash
# Restaurar configurações
cp cluster.yaml.backup cluster.yaml
cp .env.backup .env 2>/dev/null || true
```

### Sincronização de Modelos
```bash
# Exportar lista de modelos
ollama list > models_backup.txt

# Em novo ambiente, instalar modelos
while read model; do ollama pull "$model"; done < models_backup.txt
```

## 📊 MÉTRICAS DE SUCESSO

- ✅ Ambiente virtual criado e ativado
- ✅ Todas as dependências instaladas
- ✅ Scripts executáveis funcionam
- ✅ Serviços básicos inicializam
- ✅ Testes passam (mínimo 80%)
- ✅ Workers configurados corretamente

## 🆘 SUPORTE E TROUBLESHOOTING

### Logs Importantes
- `logs/auto_init_project.log`
- `logs/services_startup.log`
- `ai-ml/model-registry/dashboard/dashboard.log`

### Comandos de Diagnóstico
```bash
# Status completo do sistema
bash scripts/auto_init_project.sh

# Verificar ambiente
python -c "import sys; print(sys.path)"

# Testar conectividade Docker
docker run hello-world
```

### Contato para Suporte
- Verificar logs em `logs/`
- Executar `bash diagnostic_report.sh`
- Documentar ambiente: `uname -a && python --version && docker --version`

---

**Data:** 2025-10-02
**Versão:** 1.0
**Status:** Guia operacional para migração
