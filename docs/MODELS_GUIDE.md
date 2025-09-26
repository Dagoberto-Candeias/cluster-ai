# Guia de Modelos de IA

## Visão Geral
O Cluster AI suporta diversos tipos de modelos de IA através do Ollama, organizados por categoria e caso de uso.

## Categorias de Modelos

### 🤖 Modelos de Linguagem (LLM)
Modelos para processamento de texto, chat e geração de conteúdo.

#### Chat Geral
```bash
# Llama 3 - Meta (Recomendado para português)
ollama pull llama3:8b      # 8B parâmetros, bom equilíbrio
ollama pull llama3:70b     # 70B parâmetros, alta qualidade

# Mistral - Mistral AI
ollama pull mistral:7b     # 7B parâmetros, rápido
ollama pull mixtral:8x7b   # Mixtral 8x7B, excelente qualidade
```

#### Código e Desenvolvimento
```bash
# CodeLlama - Meta
ollama pull codellama:7b   # Geração de código
ollama pull codellama:13b  # Melhor qualidade

# DeepSeek Coder
ollama pull deepseek-coder:6.7b  # Especializado em código
```

#### Análise e Raciocínio
```bash
# Qwen - Alibaba
ollama pull qwen:7b        # Forte em matemática/lógica
ollama pull qwen:72b       # Versão grande

# Phi-2 - Microsoft
ollama pull phi:2.7b       # Modelo compacto, bom raciocínio
```

### 👁️ Modelos Multimodais (Visão + Texto)
Modelos que processam imagens e texto simultaneamente.

```bash
# LLaVA - multimodal
ollama pull llava:7b       # Visão básica
ollama pull llava:13b      # Melhor qualidade

# BakLLaVA
ollama pull bakllava:7b    # Alternativa multimodal
```

### 🎨 Modelos de Geração de Imagens
Para geração de imagens (via integração externa).

```bash
# Stable Diffusion (via WebUI)
# Configurado automaticamente no cluster
# Acesse: http://localhost:3000
```

## Instalação Automatizada
```bash
# Instalar modelos por categoria
./scripts/download_models.sh --category llm
./scripts/download_models.sh --category vision
./scripts/download_models.sh --category code

# Instalar modelo específico
./scripts/download_models.sh --model llama3:8b

# Listar modelos instalados
ollama list
```

## Uso dos Modelos

### Via OpenWebUI (Interface Web)
```bash
# Acesse: http://localhost:3000
# Selecione modelo no dropdown
# Digite sua pergunta/conversa
```

### Via API REST
```python
from ollama import Client

client = Client(host='http://localhost:11434')

# Chat simples
response = client.chat(
    model='llama3:8b',
    messages=[{'role': 'user', 'content': 'Olá!'}]
)

# Streaming
for chunk in client.chat(
    model='llama3:8b',
    messages=[{'role': 'user', 'content': 'Conte uma história'}],
    stream=True
):
    print(chunk['message']['content'], end='')
```

### Via Dask (Processamento Distribuído)
```python
from dask.distributed import Client
import ollama

# Conectar ao cluster
client = Client('localhost:8786')

def process_with_ai(text, model='llama3:8b'):
    response = ollama.chat(
        model=model,
        messages=[{'role': 'user', 'content': text}]
    )
    return response['message']['content']

# Processar múltiplos textos em paralelo
texts = ["Texto 1", "Texto 2", "Texto 3"]
futures = client.map(process_with_ai, texts)
results = client.gather(futures)
```

## Gerenciamento de Modelos

### Verificar Status
```bash
# Listar modelos
ollama list

# Ver informações detalhadas
ollama show llama3:8b

# Ver uso de disco
du -sh ~/.ollama/models/
```

### Limpeza e Otimização
```bash
# Remover modelo específico
ollama rm llama3:8b

# Limpar modelos não usados (30+ dias)
./scripts/ollama/model_manager.sh cleanup 30

# Otimizar cache
./scripts/ollama/model_manager.sh optimize
```

### Cache e Performance
```bash
# Pré-carregar modelos frequentemente usados
ollama pull llama3:8b
ollama pull mistral:7b

# Verificar cache hits
./scripts/monitoring/advanced_dashboard.sh live
```

## Recomendações por Caso de Uso

### 💬 Chat e Assistente Virtual
- **Primário**: llama3:8b ou mistral:7b
- **Backup**: qwen:7b
- **Para português**: Prefira llama3 (treinado em múltiplos idiomas)

### 👨‍💻 Desenvolvimento de Software
- **Primário**: codellama:7b ou deepseek-coder:6.7b
- **Backup**: llama3:8b
- **Para debugging**: Use modelos com contexto longo

### 📊 Análise de Dados
- **Primário**: qwen:7b (forte em matemática)
- **Backup**: llama3:8b
- **Para visualização**: Combine com modelos de visão

### 🎨 Criação de Conteúdo
- **Primário**: llama3:70b ou mixtral:8x7b
- **Backup**: qwen:72b
- **Para imagens**: llava + Stable Diffusion

## Solução de Problemas

### Modelo Não Carrega
```bash
# Verificar espaço em disco
df -h

# Verificar RAM disponível
free -h

# Reiniciar Ollama
systemctl restart ollama

# Limpar cache
ollama prune
```

### Performance Lenta
```bash
# Usar modelo menor
ollama pull llama3:8b  # ao invés de 70b

# Verificar recursos do sistema
./scripts/monitoring/resource_monitor.py

# Otimizar worker
dask-worker --memory-limit 4GB --nthreads 4
```

### Erro de Memória
```bash
# Reduzir contexto
ollama run llama3:8b --format json '{"options": {"num_ctx": 2048}}'

# Usar quantização
ollama pull llama3:8b-q4_0  # Versão quantizada
```

## Próximos Passos
- Explore integração com Dask para processamento paralelo
- Teste combinações de modelos para tarefas complexas
- Monitore uso de recursos e otimize conforme necessário
- Considere fine-tuning para casos específicos
