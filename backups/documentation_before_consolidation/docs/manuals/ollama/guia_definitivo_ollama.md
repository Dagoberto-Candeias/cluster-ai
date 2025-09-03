# 🧠 Guia Definitivo Ollama para Programação e IA

Este guia consolida **todos os modelos, configurações e integrações** discutidas, com instruções completas para instalação, gerenciamento e uso avançado do Ollama em desenvolvimento de software.

---

## 📌 Índice

1. [Instalação e Configuração Básica](#-instalação-e-configuração-básica)
2. [Modelos Disponíveis por Categoria](#-modelos-disponíveis-por-categoria)
3. [Comandos Essenciais](#-comandos-essenciais)
4. [Integração com Open WebUI](#-integração-com-open-webui)
5. [Integração com VSCode (Continue)](#-integração-com-vscode-continue)
6. [Prompts Especializados para Devs](#-prompts-especializados-para-devs)
7. [Otimização de Performance](#-otimização-de-performance)
8. [Solução de Problemas](#-solução-de-problemas)
9. [Scripts de Automação](#-scripts-de-automação)
10. [Recursos Adicionais](#-recursos-adicionais)

---

## 🛠️ Instalação e Configuração Básica

### Pré-requisitos
```bash
# Verificar se tem curl
curl --version

# Verificar espaço em disco (recomendado: 50GB+)
df -h
```

### Instalação no Linux/macOS
```bash
# Download e instalação automática
curl -fsSL https://ollama.com/install.sh | sh

# Verificar instalação
ollama --version

# Iniciar serviço
ollama serve

# Verificar se está rodando
curl http://localhost:11434/api/tags
```

### Instalação no Windows
```powershell
# Download do instalador
irm https://ollama.com/download/OllamaSetup.exe -OutFile .\OllamaSetup.exe

# Executar instalador
.\OllamaSetup.exe

# Verificar instalação
ollama --version
```

### Configuração de Ambiente
```bash
# Adicionar ao ~/.bashrc ou ~/.zshrc
export OLLAMA_NUM_GPU_LAYERS=35
export OLLAMA_MAX_LOADED_MODELS=2
export OLLAMA_HOST=0.0.0.0:11434

# Para sistemas com pouca memória
export OLLAMA_NUM_GPU_LAYERS=25
export OLLAMA_MAX_LOADED_MODELS=1
```

---

## 📚 Modelos Disponíveis por Categoria

### 1️⃣ Modelos de Chat (Conversação Geral)

| Modelo | Tamanho | Destaque | Comando Pull | Comando Run |
|--------|---------|----------|--------------|-------------|
| `llama3.1:8b` | ~5GB | Melhor equilíbrio geral | `ollama pull llama3.1:8b` | `ollama run llama3.1:8b` |
| `llama3.2` | ~5GB | Contexto avançado | `ollama pull llama3.2` | `ollama run llama3.2` |
| `llama3:8b` | ~5GB | Assistente virtual | `ollama pull llama3:8b` | `ollama run llama3:8b` |
| `phi3` | ~2GB | Raciocínio lógico | `ollama pull phi3` | `ollama run phi3` |
| `phi4` | ~9GB | Inferência complexa | `ollama pull phi4` | `ollama run phi4` |
| `qwen3` | ~5GB | Performance alta | `ollama pull qwen3` | `ollama run qwen3` |
| `mistral` | ~4GB | Chat interativo | `ollama pull mistral` | `ollama run mistral` |
| `gemma2:9b` | ~5GB | Conversa multi-turn | `ollama pull gemma2:9b` | `ollama run gemma2:9b` |
| `deepseek-chat` | ~9GB | Técnico especializado | `ollama pull deepseek-chat` | `ollama run deepseek-chat` |
| `llama2` | ~4GB | NLP e chat | `ollama pull llama2` | `ollama run llama2` |

### 2️⃣ Modelos de Programação (Código)

| Modelo | Tamanho | Destaque | Comando Pull | Comando Run |
|--------|---------|----------|--------------|-------------|
| `deepseek-coder-v2:16b` | ~9GB | **MELHOR PARA DEV** - 128K contexto | `ollama pull deepseek-coder-v2:16b` | `ollama run deepseek-coder-v2:16b` |
| `codellama-34b` | ~34GB | Alta precisão (92.3% HumanEval) | `ollama pull codellama-34b` | `ollama run codellama-34b` |
| `codellama-7b` | ~4GB | Versão leve | `ollama pull codellama-7b` | `ollama run codellama-7b` |
| `starcoder2:7b` | ~4GB | Autocomplete IDE | `ollama pull starcoder2:7b` | `ollama run starcoder2:7b` |
| `starcoder2:3b` | ~2GB | Autocomplete leve | `ollama pull starcoder2:3b` | `ollama run starcoder2:3b` |
| `qwen2.5-coder:1.5b` | ~1GB | CPU-friendly | `ollama pull qwen2.5-coder:1.5b` | `ollama run qwen2.5-coder:1.5b` |
| `deepseek-coder` | ~800MB | Leve e rápido | `ollama pull deepseek-coder` | `ollama run deepseek-coder` |

### 3️⃣ Modelos Multimodais (Visão + Texto)

| Modelo | Tamanho | Destaque | Comando Pull | Comando Run |
|--------|---------|----------|--------------|-------------|
| `llava` | ~5GB | Análise de imagens + chat | `ollama pull llava` | `ollama run llava` |
| `qwen2-vl` | ~6GB | Multimodal avançado | `ollama pull qwen2-vl` | `ollama run qwen2-vl` |
| `granite3-moe` | ~7GB | Visão + NLP | `ollama pull granite3-moe` | `ollama run granite3-moe` |
| `minicpm-v` | ~3GB | Compacto | `ollama pull minicpm-v` | `ollama run minicpm-v` |
| `deepseek-vision` | ~9GB | OCR técnico | `ollama pull deepseek-vision` | `ollama run deepseek-vision` |
| `gemma2:27b` | ~14GB | Multimodal grande | `ollama pull gemma2:27b` | `ollama run gemma2:27b` |
| `codegemma` | ~5GB | Código + visão | `ollama pull codegemma` | `ollama run codegemma` |

### 4️⃣ Modelos de Embeddings

| Modelo | Tamanho | Destaque | Comando Pull | Comando Run |
|--------|---------|----------|--------------|-------------|
| `nomic-embed-text` | ~300MB | Busca semântica | `ollama pull nomic-embed-text` | `ollama run nomic-embed-text` |
| `text-embedding-3-large` | ~2GB | Embeddings grandes | `ollama pull text-embedding-3-large` | `ollama run text-embedding-3-large` |
| `text-embedding-3-small` | ~500MB | Embeddings leves | `ollama pull text-embedding-3-small` | `ollama run text-embedding-3-small` |
| `gemma-embed` | ~3GB | Embeddings Gemma | `ollama pull gemma-embed` | `ollama run gemma-embed` |
| `qwen-embed` | ~2GB | Embeddings Qwen | `ollama pull qwen-embed` | `ollama run qwen-embed` |
| `mistral-embed` | ~2GB | Embeddings Mistral | `ollama pull mistral-embed` | `ollama run mistral-embed` |
| `llama-embed-7b` | ~4GB | Embeddings LLaMA | `ollama pull llama-embed-7b` | `ollama run llama-embed-7b` |
| `phi-embed` | ~2GB | Embeddings Phi | `ollama pull phi-embed` | `ollama run phi-embed` |

### 5️⃣ Modelos Leves (Edge/CPU)

| Modelo | Tamanho | Destaque | Comando Pull | Comando Run |
|--------|---------|----------|--------------|-------------|
| `tinyllama:1b` | ~1GB | Raspberry Pi | `ollama pull tinyllama:1b` | `ollama run tinyllama:1b` |
| `phi3` | ~2GB | Laptops/CPU | `ollama pull phi3` | `ollama run phi3` |

---

## ⚡ Comandos Essenciais

### Gerenciamento Básico
```bash
# Listar modelos instalados
ollama list

# Baixar modelo
ollama pull <modelo>

# Executar modelo interativo
ollama run <modelo>

# Executar com prompt direto
ollama run phi3 --prompt "Explique este código Python"

# Remover modelo
ollama rm <modelo>

# Ver informações do modelo
ollama show <modelo>

# Listar modelos carregados
ollama ps

# Limpar cache
ollama clean
```

### Comandos Avançados
```bash
# Executar em porta específica
ollama serve --port 11435

# Forçar uso de CPU
OLLAMA_NO_CUDA=1 ollama run <modelo>

# Limitar camadas GPU
OLLAMA_NUM_GPU_LAYERS=25 ollama run <modelo>

# Atualizar todos os modelos
ollama list | awk '{print $1}' | xargs -I {} ollama pull {}
```

---

## 🖥️ Integração com Open WebUI

### Instalação do Open WebUI
```bash
# Via Docker (recomendado)
docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main

# Ou via script
curl -fsSL https://raw.githubusercontent.com/open-webui/open-webui/main/install.sh | sh
```

### Configuração Básica
1. Acesse http://localhost:3000
2. Vá em **Settings** → **Models**
3. Configure:
   - **Backend**: Ollama
   - **API URL**: http://localhost:11434
   - **Model**: deepseek-coder-v2:16b (ou outro)

### Configuração Avançada
```yaml
# Parâmetros recomendados
temperature: 0.3          # Precisão para código
max_tokens: 8192          # Contexto longo
top_p: 0.9               # Criatividade controlada
frequency_penalty: 0.1    # Evitar repetições
presence_penalty: 0.1     # Diversidade
```

### Modelos Recomendados por Uso
```bash
# Desenvolvimento
ollama pull deepseek-coder-v2:16b

# Chat geral
ollama pull llama3.1:8b

# Análise de imagens
ollama pull llava

# Processamento de texto
ollama pull nomic-embed-text
```

---

## 💻 Integração com VSCode (Continue)

### Instalação da Extensão
1. Abra VSCode
2. Extensions → Busque "Continue"
3. Instale e reinicie

### Configuração Completa (.continue/config.json)
```json
{
  "models": [
    {
      "name": "Assistente Principal",
      "provider": "ollama",
      "model": "deepseek-coder-v2:16b",
      "temperature": 0.3,
      "maxTokens": 8192,
      "contextLength": 131072,
      "roles": ["chat", "edit", "apply"],
      "systemMessage": "Você é um engenheiro de software sênior. Responda em PT-BR com código funcional."
    },
    {
      "name": "Revisor Rápido",
      "provider": "ollama",
      "model": "phi3",
      "temperature": 0.2,
      "maxTokens": 4096,
      "roles": ["review"]
    },
    {
      "name": "Vision Assistant",
      "provider": "ollama",
      "model": "llava",
      "capabilities": ["image_input"],
      "roles": ["chat"],
      "temperature": 0.7,
      "maxTokens": 2048
    }
  ],
  "tabAutocomplete": {
    "model": "starcoder2:7b",
    "temperature": 0.2,
    "maxTokens": 512,
    "debounceDelay": 250
  },
  "context": [
    {
      "provider": "codebase",
      "params": {
        "nRetrieve": 25,
        "nFinal": 5
      }
    },
    {
      "provider": "file"
    },
    {
      "provider": "code"
    },
    {
      "provider": "diff"
    },
    {
      "provider": "folder"
    },
    {
      "provider": "open",
      "params": {
        "onlyPinned": false
      }
    },
    {
      "provider": "terminal"
    },
    {
      "provider": "problems"
    },
    {
      "provider": "tree"
    }
  ],
  "rules": [
    {
      "name": "Idioma Padrão",
      "rule": "Sempre responda em português brasileiro, exceto quando especificamente solicitado outro idioma"
    },
    {
      "name": "Qualidade do Código",
      "rule": "Priorize código limpo, legível e bem documentado. Use padrões de nomenclatura consistentes e siga as melhores práticas da linguagem"
    },
    {
      "name": "Segurança e Performance",
      "rule": "Sempre considere aspectos de segurança e performance nas soluções propostas. Identifique vulnerabilidades potenciais"
    },
    {
      "name": "Explicações Técnicas",
      "rule": "Forneça explicações claras do raciocínio por trás das soluções, especialmente para código complexo"
    },
    {
      "name": "Python",
      "rule": "Para Python, use type hints, siga PEP 8, prefira f-strings e use dataclasses/pydantic para estruturas de dados",
      "globs": ["**/*.py"]
    },
    {
      "name": "TypeScript",
      "rule": "Para projetos TypeScript, sempre use tipagem forte, interfaces bem definidas e evite 'any'. Prefira type guards e utility types",
      "globs": ["**/*.{ts,tsx}"]
    },
    {
      "name": "React",
      "rule": "Para React, use hooks funcionais, evite prop drilling, implemente error boundaries e otimize re-renders",
      "globs": ["**/*.{jsx,tsx}"]
    },
    {
      "name": "Testes",
      "rule": "Para arquivos de teste, foque em cobertura completa, casos extremos, mocks apropriados e testes legíveis",
      "globs": ["**/*.{test,spec}.{js,ts,jsx,tsx,py}"]
    }
  ]
}
```

### Atalhos Úteis no VSCode
- `Ctrl+Shift+G`: Gerar código
- `Ctrl+Shift+R`: Refatorar
- `Ctrl+Shift+D`: Documentar
- `Ctrl+Shift+B`: Debug assist

---

## 💡 Prompts Especializados para Devs

### Revisão de Código Completa
```
Analise este código considerando:

## 🔍 ANÁLISE DE QUALIDADE
- Erros de sintaxe e lógica
- Padrões de código
- Legibilidade e manutenibilidade
- Estrutura e arquitetura

## 🛡️ ANÁLISE DE SEGURANÇA
- Vulnerabilidades (OWASP Top 10)
- Validação de entrada
- Autenticação/autorização
- Exposição de dados

## ⚡ ANÁLISE DE PERFORMANCE
- Complexidade algorítmica
- Uso de memória
- Operações custosas
- Otimizações possíveis

## 📋 SUGESTÕES DE MELHORIA
Para cada problema identificado, forneça:
- Explicação clara
- Impacto potencial
- Solução específica com exemplo
- Prioridade (Alta/Média/Baixa)

Organize a resposta estruturada e priorize problemas críticos.
```

### Geração de Testes Abrangentes
```
Crie uma suite completa de testes para o código selecionado:

## 🧪 ESTRUTURA DOS TESTES
- Setup/teardown necessários
- Mocks e stubs apropriados
- Fixtures reutilizáveis
- Helpers para testes

## ✅ COBERTURA DE CENÁRIOS
- Happy path principais
- Edge cases e limites
- Error cases e exceções
- Boundary testing

## 🔄 TIPOS DE TESTE
- Unitários (funções/métodos isolados)
- Integração (interação entre componentes)
- Performance (tempo/memória se relevante)
- Regressão (bugs conhecidos)

## 📝 ORGANIZAÇÃO
- Describe/context lógico
- Test names descritivos
- Assertions específicas
- Comments para lógica complexa

## 🎯 QUALIDADE DOS TESTES
- Independência entre testes
- Determinismo consistente
- Velocidade de execução
- Manutenibilidade

Use o framework apropriado e inclua instruções de execução.
```

### Refatoração Sistemática
```
Refatore o código seguindo princípios de clean code:

## 🏗️ ANÁLISE ARQUITETURAL
- SOLID Principles
- Design Patterns aplicáveis
- Separation of Concerns
- Coupling/Cohesion

## 🔧 REFATORAÇÕES ESTRUTURAIS
- Extract Method (funcionalidades complexas)
- Extract Class (responsabilidades distintas)
- Move Method (classes apropriadas)
- Rename (nomes melhores)

## 📦 ORGANIZAÇÃO DE CÓDIGO
- Modularização coesa
- Interfaces claras
- Abstrações apropriadas
- Dependencies minimizadas

## 🎯 MELHORIAS ESPECÍFICAS
- Error handling robusto
- Logging estruturado
- Configuration externalizada
- Testing facilitado

## 📋 PLANO DE REFATORAÇÃO
1. Fase 1: Refatorações seguras (renomeação, extração)
2. Fase 2: Mudanças estruturais (classes, interfaces)
3. Fase 3: Otimizações arquiteturais
4. Validação: Testes para cada fase

Mantenha funcionalidade original e forneça plano de migração gradual.
```

### Análise de Imagens Técnicas
```
Analise a imagem com foco técnico detalhado:

## 👁️ ANÁLISE VISUAL GERAL
- Elementos principais visuais
- Layout e estrutura espacial
- Texto visível (transcrever e interpretar)
- Cores e design visual

## 💻 ANÁLISE TÉCNICA ESPECÍFICA
Se for código/diagrama:
- Linguagem/framework identificados
- Padrões reconhecidos
- Arquitetura do sistema
- Fluxo de dados

Se for interface/UI:
- UX/UI patterns identificados
- Responsividade avaliada
- Acessibilidade verificada
- Performance visual otimizada

Se for diagrama/arquitetura:
- Componentes identificados
- Relacionamentos analisados
- Fluxos traçados
- Escalabilidade avaliada

## 🔍 INSIGHTS TÉCNICOS
- Boas práticas identificadas
- Problemas potenciais apontados
- Melhorias sugeridas específicas
- Alternativas propostas

## 📚 CONTEXTO E RECOMENDAÇÕES
- Documentação relevante sugerida
- Ferramentas apropriadas recomendadas
- Próximos passos indicados
- Recursos de aprendizado apontados

Forneça insights acionáveis baseados na análise visual.
```

---

## ⚡ Otimização de Performance

### Configurações por Hardware

#### GPU Alta Performance
```bash
export OLLAMA_NUM_GPU_LAYERS=50
export OLLAMA_MAX_LOADED_MODELS=3
export OLLAMA_FLASH_ATTENTION=true
```

#### GPU Média
```bash
export OLLAMA_NUM_GPU_LAYERS=35
export OLLAMA_MAX_LOADED_MODELS=2
```

#### CPU/Sistema Limitado
```bash
export OLLAMA_NUM_THREAD=8
export OLLAMA_MAX_LOADED_MODELS=1
export OLLAMA_NO_CUDA=1
```

### Otimização de Memória
```bash
# Aumentar swap se necessário
sudo fallocate -l 8G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Verificar uso
free -h
```

### Configurações por Modelo
```bash
# Modelos grandes
ollama run codellama-34b --num-gpu-layers 50

# Modelos médios
ollama run deepseek-coder-v2:16b --num-gpu-layers 35

# Modelos pequenos
ollama run phi3 --num-thread 4
```

---

## 🔧 Solução de Problemas

### Problemas Comuns

#### "Model not found"
```bash
# Verificar nome exato
ollama list

# Baixar novamente
ollama pull <modelo-exato>
```

#### Download Lento
```bash
# Usar mirror alternativo
export OLLAMA_REGISTRY=https://registry.ollama.ai

# Ou configurar proxy
export HTTP_PROXY=http://proxy.company.com:8080
```

#### GPU não Detectada
```bash
# Verificar drivers
nvidia-smi

# Instalar drivers se necessário
sudo apt update && sudo apt install nvidia-driver-XXX
```

#### Memória Insuficiente
```bash
# Reduzir camadas GPU
OLLAMA_NUM_GPU_LAYERS=25 ollama run <modelo>

# Usar CPU
OLLAMA_NO_CUDA=1 ollama run <modelo>
```

#### Porta Ocupada
```bash
# Usar porta diferente
ollama serve --port 11435

# Verificar processos
lsof -i :11434
```

### Diagnóstico Avançado
```bash
# Ver logs detalhados
ollama serve 2>&1 | tee ollama.log

# Testar conectividade
curl -X POST http://localhost:11434/api/generate -d '{"model": "llama3.1:8b", "prompt": "test"}'

# Verificar GPU
nvidia-smi --query-gpu=memory.used,memory.total --format=csv
```

---

## 📜 Scripts de Automação

### Script de Instalação em Lote
```bash
#!/bin/bash
# install_models_batch.sh

MODELS=(
    "llama3.1:8b"
    "deepseek-coder-v2:16b"
    "mistral"
    "llava"
    "phi3"
    "starcoder2:7b"
    "nomic-embed-text"
)

echo "Instalando ${#MODELS[@]} modelos..."

for model in "${MODELS[@]}"; do
    echo "📥 Baixando $model..."
    if ollama pull "$model"; then
        echo "✅ $model instalado com sucesso"
    else
        echo "❌ Falha ao instalar $model"
    fi
done

echo "🎉 Instalação concluída!"
echo "Modelos instalados:"
ollama list
```

### Script de Backup e Restauração
```bash
#!/bin/bash
# backup_models.sh

BACKUP_DIR="$HOME/ollama_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📦 Fazendo backup dos modelos..."
cp -r ~/.ollama/models "$BACKUP_DIR/"

echo "✅ Backup concluído: $BACKUP_DIR"
ls -lh "$BACKUP_DIR/models"
```

```bash
#!/bin/bash
# restore_models.sh

BACKUP_DIR="$1"

if [ -z "$BACKUP_DIR" ]; then
    echo "Uso: $0 <diretório_de_backup>"
    exit 1
fi

echo "🔄 Restaurando modelos..."
cp -r "$BACKUP_DIR/models" ~/.ollama/

echo "✅ Restauração concluída!"
ollama list
```

### Script de Monitoramento
```bash
#!/bin/bash
# monitor_ollama.sh

while true; do
    echo "=== $(date) ==="
    echo "Modelos carregados:"
    ollama ps
    echo ""
    echo "Uso de GPU:"
    nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits
    echo ""
    sleep 30
done
```

### Script de Otimização Automática
```bash
#!/bin/bash
# optimize_ollama.sh

# Detectar hardware
if command -v nvidia-smi &> /dev/null; then
    GPU_MEMORY=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -1)
    
    if [ "$GPU_MEMORY" -gt 8000 ]; then
        export OLLAMA_NUM_GPU_LAYERS=50
        export OLLAMA_MAX_LOADED_MODELS=3
        echo "🎮 Configurado para GPU alta performance"
    elif [ "$GPU_MEMORY" -gt 4000 ]; then
        export OLLAMA_NUM_GPU_LAYERS=35
        export OLLAMA_MAX_LOADED_MODELS=2
        echo "💻 Configurado para GPU média"
    else
        export OLLAMA_NUM_GPU_LAYERS=25
        export OLLAMA_MAX_LOADED_MODELS=1
        echo "🖥️ Configurado para GPU básica"
    fi
else
    CPU_CORES=$(nproc)
    export OLLAMA_NUM_THREAD=$CPU_CORES
    export OLLAMA_MAX_LOADED_MODELS=1
    export OLLAMA_NO_CUDA=1
    echo "💾 Configurado para CPU-only ($CPU_CORES cores)"
fi

echo "🚀 Iniciando Ollama otimizado..."
ollama serve
```

---

## 📚 Recursos Adicionais

### Documentação Oficial
- [Ollama GitHub](https://github.com/ollama/ollama)
- [Modelos Disponíveis](https://ollama.com/library)
- [Open WebUI](https://github.com/open-webui/open-webui)
- [Continue VSCode](https://continue.dev/)

### Tutoriais e Guias
- [Guia de Modelfiles](https://github.com/ollama/ollama/blob/main/docs/modelfile.md)
- [FAQ Ollama](https://github.com/ollama/ollama/blob/main/docs/faq.md)
- [Otimização de Performance](https://github.com/ollama/ollama/blob/main/docs/performance.md)

### Comunidades
- [Discord Ollama](https://discord.gg/ollama)
- [Reddit r/ollama](https://reddit.com/r/ollama)
- [Discord Open WebUI](https://discord.gg/open-webui)

### Ferramentas Relacionadas
- [LM Studio](https://lmstudio.ai/) - Alternativa GUI
- [Ollama Web UI](https://github.com/jmorganca/ollama) - Interface web simples
- [Continue](https://continue.dev/) - Extensão VSCode

---

## 🎯 Recomendações por Caso de Uso

### Desenvolvimento Full-Stack
```bash
ollama pull deepseek-coder-v2:16b  # Principal
ollama pull starcoder2:7b          # Autocomplete
ollama pull llava                  # Análise visual
ollama pull nomic-embed-text       # Busca semântica
```

### Ciência de Dados
```bash
ollama pull llama3.1:8b           # Análise geral
ollama pull deepseek-coder-v2:16b # Código Python
ollama pull phi3                  # Raciocínio matemático
ollama pull nomic-embed-text      # Clustering
```

### DevOps/Infrastructure
```bash
ollama pull deepseek-chat         # Scripts e automação
ollama pull codellama-34b         # IaC e configurações
ollama pull llava                 # Diagramas de arquitetura
```

### Mobile Development
```bash
ollama pull deepseek-coder-v2:16b # React Native/Flutter
ollama pull starcoder2:7b         # Autocomplete mobile
ollama pull llava                 # UI/UX analysis
```

---

## ❓ FAQ

**P: Quanto espaço preciso para uma coleção completa?**
R: 50-100GB. Modelos variam de 1GB (tinyllama) a 40GB+ (codellama-34b).

**P: Posso usar múltiplos modelos simultaneamente?**
R: Sim, mas considere memória. Configure `OLLAMA_MAX_LOADED_MODELS`.

**P: Como acelerar downloads?**
R: Use conexões rápidas, considere mirrors, baixe em horários de menor tráfego.

**P: Modelos funcionam offline?**
R: Sim, após download inicial, funcionam completamente offline.

**P: Qual a diferença entre pull e run?**
R: `pull` baixa o modelo, `run` executa interativamente.

**P: Como atualizar modelos?**
R: Execute `ollama pull <modelo>` novamente para versão mais recente.

**P: Posso criar modelos customizados?**
R: Sim, usando Modelfiles. Veja documentação oficial.

---

## 📞 Suporte

Para suporte adicional:
- Consulte documentação oficial
- Abra issues no repositório do projeto
- Participe das comunidades Discord/Reddit
- Verifique logs com `ollama serve 2>&1 | tee debug.log`

---

**Última atualização:** $(date)
**Versão do guia:** 2.0
**Compatibilidade:** Ollama v0.1.0+

---

*Este guia foi criado para consolidar todas as informações sobre Ollama discutidas na conversa, incluindo modelos, configurações, prompts e soluções de problemas. Mantenha-o atualizado conforme novas versões são lançadas.*
