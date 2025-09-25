# Guia de Instalação de Modelos - Cluster AI

## Visão Geral

Este guia explica como instalar e gerenciar modelos de IA no Cluster AI, com foco em otimização de recursos e seleção inteligente de modelos.

## Categorias de Modelos

### 🤖 Modelos de Conversação Geral
Modelos versáteis para chat, escrita e tarefas gerais.

#### Recomendados para Iniciantes:
- **llama3.1:8b** - Meta Llama 3.1 (8B parâmetros)
  - Uso: Chat geral, escrita criativa
  - Recursos: ~4.7GB, CPU/GPU
  - Pontos Fortes: Equilibrado, multilíngue

- **llama3:8b** - Meta Llama 3 (8B parâmetros)
  - Uso: Chat geral, análise de texto
  - Recursos: ~4.7GB, CPU/GPU
  - Pontos Fortes: Estável, bem testado

- **mistral:7b** - Mistral AI 7B
  - Uso: Chat técnico, programação
  - Recursos: ~4.1GB, CPU/GPU
  - Pontos Fortes: Código, matemática

### 🎨 Modelos Criativos
Especializados em geração de conteúdo criativo.

#### Modelos Disponíveis:
- **llava:7b** - LLaVA (Large Language and Vision Assistant)
  - Uso: Análise de imagens + texto
  - Recursos: ~4.6GB, GPU recomendado
  - Pontos Fortes: Multimodal, descrições

- **deepseek-coder:6.7b** - DeepSeek Coder
  - Uso: Geração de código, debugging
  - Recursos: ~3.8GB, CPU/GPU
  - Pontos Fortes: Sintaxe perfeita, múltiplas linguagens

### 🧠 Modelos Avançados
Modelos de alta performance para tarefas complexas.

#### Modelos Pesados:
- **mixtral:8x7b** - Mixtral 8x7B
  - Uso: Análise complexa, pesquisa
  - Recursos: ~26GB, GPU obrigatória
  - Pontos Fortes: Raciocínio avançado, multitarefa

- **codellama:13b** - Code Llama 13B
  - Uso: Desenvolvimento avançado
  - Recursos: ~7.4GB, GPU recomendado
  - Pontos Fortes: Arquiteturas complexas, documentação

### 🌍 Modelos Especializados
Modelos otimizados para tarefas específicas.

#### Modelos por Domínio:
- **phi3:3.8b** - Microsoft Phi-3
  - Uso: Matemática, ciência
  - Recursos: ~2.2GB, CPU eficiente
  - Pontos Fortes: Rápido, compacto

- **gemma2:9b** - Google Gemma 2
  - Uso: Pesquisa acadêmica, análise
  - Recursos: ~5.2GB, GPU recomendado
  - Pontos Fortes: Precisão, factualidade

## Instalação Automática

### Método 1: Instalação Inteligente (Recomendado)
```bash
# Executar instalação principal
./install_unified.sh

# Durante a instalação, selecionar modelos:
# - Opção: "Selecionar modelos específicos"
# - Escolher baseado no uso pretendido
```

### Método 2: Instalação Manual
```bash
# Verificar modelos disponíveis
ollama list

# Instalar modelo específico
ollama pull llama3.1:8b

# Verificar instalação
ollama list
```

### Método 3: Instalação em Lote
```bash
# Instalar conjunto recomendado
./scripts/utils/check_models.sh

# Seguir menu interativo para seleção
```

## Seleção de Modelos por Caso de Uso

### 💻 Desenvolvimento de Software
```
Prioridade:
1. deepseek-coder:6.7b (código)
2. codellama:13b (arquiteturas)
3. llama3.1:8b (documentação)
```

### 📊 Análise de Dados
```
Prioridade:
1. llama3.1:8b (análise geral)
2. mixtral:8x7b (complexa)
3. gemma2:9b (precisão)
```

### 🎨 Criação de Conteúdo
```
Prioridade:
1. llama3:8b (escrita criativa)
2. llava:7b (multimodal)
3. mistral:7b (técnico)
```

### 🔬 Pesquisa Acadêmica
```
Prioridade:
1. mixtral:8x7b (raciocínio)
2. gemma2:9b (factual)
3. phi3:3.8b (matemática)
```

## Otimização de Recursos

### Para Hardware Limitado (CPU/RAM)
```bash
# Modelos leves recomendados
ollama pull phi3:3.8b        # 2.2GB
ollama pull gemma2:2b        # 1.6GB
ollama pull llama3:8b        # 4.7GB
```

### Para GPU Disponível
```bash
# Modelos otimizados para GPU
ollama pull llama3.1:8b      # Suporte CUDA
ollama pull mixtral:8x7b     # Alto paralelismo
ollama pull codellama:13b    # Aceleração GPU
```

### Configuração de Memória
```bash
# Ajustar limite de memória por modelo
export OLLAMA_MAX_LOADED_MODELS=2
export OLLAMA_MAX_QUEUE=512
```

## Gerenciamento de Modelos

### Listar Modelos Instalados
```bash
ollama list
```

### Verificar Uso de Espaço
```bash
# Espaço usado pelos modelos
du -sh ~/.ollama/models/

# Detalhes por modelo
ollama list --size
```

### Remover Modelos Não Usados
```bash
# Listar modelos
ollama list

# Remover modelo específico
ollama rm modelo-nome:tag

# Limpar cache
ollama cache clean
```

### Atualizar Modelos
```bash
# Verificar atualizações disponíveis
ollama list --updates

# Atualizar modelo específico
ollama pull modelo-nome:tag --update
```

## Configuração Avançada

### Personalização de Parâmetros
```bash
# Arquivo de configuração
~/.ollama/config.yaml

# Exemplo de configuração
models:
  - name: llama3.1:8b
    parameters:
      num_ctx: 4096
      num_thread: 8
      num_gpu: 1
```

### Otimização de Performance
```bash
# Variáveis de ambiente
export OLLAMA_NUM_THREAD=8
export OLLAMA_NUM_GPU=1
export OLLAMA_MAX_LOADED_MODELS=3
export OLLAMA_HOST=0.0.0.0:11434
```

### Configuração para Cluster
```bash
# Configuração distribuída
export OLLAMA_LOAD_TIMEOUT=300
export OLLAMA_RUNNERS_DIR=/opt/ollama/runners
export OLLAMA_TMPDIR=/tmp/ollama
```

## Solução de Problemas

### Modelo Não Carrega
```bash
# Verificar logs
tail -f ~/.ollama/logs/server.log

# Verificar recursos
free -h
nvidia-smi  # se GPU

# Reiniciar serviço
systemctl restart ollama
```

### Performance Lenta
```bash
# Otimizar threads
export OLLAMA_NUM_THREAD=4

# Usar GPU se disponível
export OLLAMA_NUM_GPU=1

# Reduzir contexto
export OLLAMA_NUM_CTX=2048
```

### Erro de Memória
```bash
# Limitar modelos carregados
export OLLAMA_MAX_LOADED_MODELS=1

# Usar modelos menores
ollama pull phi3:3.8b
ollama pull gemma2:2b
```

### Problemas de Rede
```bash
# Configurar proxy se necessário
export HTTP_PROXY=http://proxy:port
export HTTPS_PROXY=http://proxy:port

# Verificar conectividade
curl -I https://registry.ollama.ai
```

## Monitoramento e Manutenção

### Scripts de Monitoramento
```bash
# Verificar status dos modelos
./scripts/ollama/model_manager.sh status

# Limpeza automática
./scripts/ollama/model_manager.sh cleanup

# Otimização de cache
./scripts/ollama/model_manager.sh optimize
```

### Logs e Diagnóstico
```bash
# Logs do Ollama
tail -f ~/.ollama/logs/server.log

# Logs do Cluster AI
tail -f logs/ollama_download.log

# Diagnóstico completo
./scripts/health_check_enhanced_fixed.sh
```

## Recomendações por Perfil

### 👨‍💻 Desenvolvedor Solo
```
Modelos Essenciais:
- deepseek-coder:6.7b (código)
- llama3:8b (documentação)

Recursos: 8GB RAM, CPU moderno
```

### 🏢 Equipe de Desenvolvimento
```
Modelos Essenciais:
- codellama:13b (arquiteturas)
- mixtral:8x7b (análise)
- deepseek-coder:6.7b (código)

Recursos: 16GB+ RAM, GPU recomendada
```

### 🔬 Pesquisador/Acadêmico
```
Modelos Essenciais:
- mixtral:8x7b (raciocínio complexo)
- gemma2:9b (precisão factual)
- phi3:3.8b (matemática)

Recursos: 32GB+ RAM, GPU obrigatória
```

### 🎯 Usuário Geral
```
Modelos Essenciais:
- llama3.1:8b (conversação)
- llava:7b (multimodal)
- mistral:7b (tarefas gerais)

Recursos: 8GB RAM mínimo
```

## Atualizações e Manutenção

### Verificar Atualizações
```bash
# Atualizações do Ollama
ollama --version

# Modelos desatualizados
ollama list --outdated
```

### Backup de Modelos
```bash
# Backup do diretório de modelos
tar -czf ollama_models_backup.tar.gz ~/.ollama/models/

# Restauração
tar -xzf ollama_models_backup.tar.gz -C ~/
```

### Limpeza Regular
```bash
# Remover modelos não usados há 30+ dias
./scripts/ollama/model_manager.sh cleanup --older-than 30

# Otimizar armazenamento
./scripts/ollama/model_manager.sh optimize
```

---

**📋 Checklist de Instalação:**
- [ ] Avaliar recursos disponíveis (CPU, RAM, GPU)
- [ ] Definir caso de uso principal
- [ ] Selecionar modelos apropriados
- [ ] Verificar espaço em disco necessário
- [ ] Executar instalação
- [ ] Testar funcionalidade
- [ ] Configurar otimização de performance

**🔗 Links Úteis:**
- [Documentação Ollama](https://github.com/ollama/ollama)
- [Modelos Disponíveis](https://ollama.ai/library)
- [Guia de Performance](https://github.com/ollama/ollama/blob/main/docs/faq.md)

**📞 Suporte:**
Para problemas específicos, consulte os logs em `logs/ollama_download.log` e `~/.ollama/logs/`
