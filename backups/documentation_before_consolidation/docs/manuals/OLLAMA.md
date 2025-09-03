# 🤖 Manual Completo do Ollama - Modelos de IA Local

Guia completo para instalação, configuração e uso dos modelos Ollama no Cluster AI.

## 📋 Índice
- [🤖 Manual Completo do Ollama - Modelos de IA Local](#-manual-completo-do-ollama---modelos-de-ia-local)
  - [📋 Índice](#-índice)
  - [🎯 Introdução](#-introdução)
    - [O que é o Ollama?](#o-que-é-o-ollama)
    - [Casos de Uso no Cluster AI](#casos-de-uso-no-cluster-ai)
  - [🚀 Instalação e Configuração](#-instalação-e-configuração)
    - [Instalação Automática](#instalação-automática)
    - [Instalação Manual](#instalação-manual)
    - [Configuração Básica](#configuração-básica)
    - [Verificação da Instalação](#verificação-da-instalação)
  - [📊 Modelos Disponíveis](#-modelos-disponíveis)
    - [📝 Modelos de Chat (Conversação)](#-modelos-de-chat-conversação)
    - [💻 Modelos de Codificação](#-modelos-de-codificação)

## 🎯 Introdução

### O que é o Ollama?
O Ollama é uma plataforma para executar modelos de linguagem grandes (LLMs) localmente, oferecendo:

- ✅ **Execução Local**: Sem dependência de internet após download
- ✅ **Multi-modelos**: Suporte a diversos modelos de IA
- ✅ **Otimização**: Configuração automática para CPU/GPU
- ✅ **API REST**: Interface padrão para integração

### Casos de Uso no Cluster AI
- **Assistência à Programação**: Geração e revisão de código
- **Análise de Dados**: Processamento e interpretação de textos
- **Chat e Q&A**: Interface conversacional com modelos
- **Processamento Distribuído**: Integração com Dask para tasks em paralelo

## 🚀 Instalação e Configuração

### Instalação Automática
```bash
# Via script do Cluster AI (recomendado)
./install_cluster.sh

# O script automaticamente:
# 1. Instala o Ollama
# 2. Configura o serviço
# 3. Baixa modelos essenciais
# 4. Otimiza para hardware disponível
```

### Instalação Manual
```bash
# Instalar Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Configurar serviço
sudo systemctl enable ollama
sudo systemctl start ollama

# Verificar instalação
ollama --version
```

### Configuração Básica
```bash
# Configurar para aceitar conexões externas
sudo mkdir -p /etc/systemd/system/ollama.service.d/
sudo tee /etc/systemd/system/ollama.service.d/environment.conf > /dev/null << EOL
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_NUM_GPU_LAYERS=35"
EOL

sudo systemctl daemon-reload
sudo systemctl restart ollama
```

### Verificação da Instalação
```bash
# Verificar se o serviço está rodando
systemctl status ollama

# Testar API
curl http://localhost:11434/api/tags

# Verificar modelos instalados
ollama list
```

## 📊 Modelos Disponíveis

### 📝 Modelos de Chat (Conversação)

| Modelo | Tamanho | Empresa | Melhor para | Comando |
|--------|---------|---------|-------------|---------|
| **llama3:8b** | 8B | Meta | Chat geral | `ollama pull llama3:8b` |
| **llama3.1:8b** | 8B | Meta | Diálogos complexos | `ollama pull llama3.1:8b` |
| **phi3** | 3.8B | Microsoft | Raciocínio lógico | `ollama pull phi3` |
| **mistral** | 7B | Mistral AI | Respostas rápidas | `ollama pull mistral` |
| **deepseek-chat** | 16B | DeepSeek | Assistência técnica | `ollama pull deepseek-chat` |
| **gemma2:9b** | 9B | Google | Conversas multi-turno | `ollama pull gemma2:9b` |
| **qwen3** | 14B | Alibaba | Q&A longo | `ollama pull qwen3` |
| **llama2** | 7B | Meta | NLP tradicional | `ollama pull llama2` |
| **vicuna-13b** | 13B | LMSys | Diálogo natural | `ollama pull vicuna-13b` |
| **chatglm-6b** | 6B | THUDM | Chinês/Inglês | `ollama pull chatglm-6b` |

### 💻 Modelos de Codificação

| Modelo | Linguagens | Casos de Uso | Comando |
|--------|------------|-------------|---------|
| **deepseek-coder-v2:16b** | 30+ | Debug, autocompletar | `ollama pull deepseek-coder-v2:16b` |
| **starcoder2:7b** | 80+ | Sugestões avançadas | `ollama pull starcoder2:7b` |
| **codellama-34b** | Python/JS | Refatoração | `ollama pull codellama-34b` |
| **qwen2.5-coder:1.5b** | Python | Autocomplete rápido | `ollama pull qwen2.5-coder:1.5b` |
| **mpt-30b-code** | 20+ | Geração complexa | `ollama pull mpt-30b-code` |

### 🖼️ Modelos Multimodais (Imagem + Texto)

| Modelo | Recursos | Casos de Uso | Comando |
|--------|----------|-------------|---------|
| **llava** | Imagens | Análise visual | `ollama pull llava` |
| **codegemma** | Código + Imagens | Diagramas técnicos | `ollama pull codegemma` |
| **qwen2-vl** | Multimodal avançado | Visão computacional | `ollama pull qwen2-vl` |
| **deepseek-vision** | Visão computacional | Análise técnica | `ollama pull deepseek-vision` |

### 🔤 Modelos de Embeddings

| Modelo | Dimensões | Casos de Uso | Comando |
|--------|-----------|-------------|---------|
| **nomic-embed-text** | 768 | Busca semântica | `ollama pull nomic-embed-text` |
| **text-embedding-3-large** | 3072 | NLP avançado | `ollama pull text-embedding-3-large` |
| **gemma-embed** | 1024 | Embeddings eficientes | `ollama pull gemma-embed` |
| **mistral-embed** | 4096 | Clusterização | `ollama pull mistral-embed` |

### Download de Modelos
```bash
# Download individual
ollama pull llama3:8b
ollama pull deepseek-coder-v2:16b

# Download em lote (background)
for model in llama3:8b mistral deepseek-coder; do
    ollama pull $model &
done

# Verificar progresso
ollama list

# Listar modelos disponíveis
ollama list
```

## ⚙️ Configuração Avançada

### Configuração de GPU
```bash
# Detectar tipo de GPU
lspci | grep -i nvidia && echo "NVIDIA detectada" || echo "NVIDIA não detectada"
lspci | grep -i amd/ati && echo "AMD detectada" || echo "AMD não detectada"

# Configuração automática no Cluster AI
# O script detecta automaticamente e configura:
# - NVIDIA: Até 35 camadas GPU
# - AMD: Até 20 camadas GPU  
# - CPU-only: Configuração otimizada
```

### Configuração Manual de GPU
```bash
# Criar diretório de configuração
mkdir -p ~/.ollama

# Configuração para NVIDIA
cat > ~/.ollama/config.json << 'EOL'
{
    "runners": {
        "nvidia": {
            "url": "https://github.com/ollama/ollama/blob/main/gpu/nvidia/runner.cu"
        }
    },
    "environment": {
        "OLLAMA_NUM_GPU_LAYERS": "35",
        "OLLAMA_MAX_LOADED_MODELS": "3",
        "OLLAMA_KEEP_ALIVE": "24h"
    }
}
EOL

# Configuração para AMD
cat > ~/.ollama/config.json << 'EOL'
{
    "runners": {
        "rocm": {
            "url": "https://github.com/ollama/ollama/blob/main/gpu/rocm/runner.cc"
        }
    },
    "environment": {
        "OLLAMA_NUM_GPU_LAYERS": "20",
        "OLLAMA_MAX_LOADED_MODELS": "2"
    }
}
EOL

# Configuração CPU-only
cat > ~/.ollama/config.json << 'EOL'
{
    "environment": {
        "OLLAMA_MAX_LOADED_MODELS": "1",
        "OLLAMA_KEEP_ALIVE": "1h"
    }
}
EOL

# Reiniciar serviço
sudo systemctl restart ollama
```

### Parâmetros de Execução
```bash
# Executar com parâmetros específicos
ollama run llama3:8b --temperature 0.7 --max-tokens 1024

# Parâmetros comuns:
# --temperature: 0.0-1.0 (criatividade)
# --max-tokens: 1-4096 (tamanho da resposta)
# --top-p: 0.0-1.0 (diversidade)
# --top-k: 1-100 (seleção de tokens)
```

### Configuração de Memória
```bash
# Limitar uso de memória por modelo
export OLLAMA_MAX_LOADED_MODELS=2
export OLLAMA_NUM_PARALLEL=1

# Para modelos grandes, ajustar memória
export OLLAMA_MMAP=1  # Memory mapping para modelos grandes
```

## 🐍 Integração com Python

### API Básica
```python
import requests
import json

def ask_ollama(prompt, model="llama3", host="localhost", port=11434):
    """
    Consulta o Ollama via API
    """
    url = f"http://{host}:{port}/api/generate"
    
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.7,
            "max_tokens": 1024
        }
    }
    
    try:
        response = requests.post(url, json=payload, timeout=30)
        response.raise_for_status()
        return response.json()['response']
    except requests.exceptions.RequestException as e:
        return f"Erro: {str(e)}"

# Exemplo de uso
resposta = ask_ollama("Explique o que é machine learning")
print(resposta)
```

### API com Streaming
```python
def ask_ollama_stream(prompt, model="llama3", callback=None):
    """
    Consulta com streaming para respostas longas
    """
    url = "http://localhost:11434/api/generate"
    
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": True
    }
    
    full_response = ""
    
    try:
        response = requests.post(url, json=payload, stream=True, timeout=60)
        
        for line in response.iter_lines():
            if line:
                data = json.loads(line)
                if 'response' in data:
                    chunk = data['response']
                    full_response += chunk
                    if callback:
                        callback(chunk)
                
                if data.get('done', False):
                    break
                    
        return full_response
        
    except Exception as e:
        return f"Erro: {str(e)}"

# Exemplo com callback
def print_chunk(chunk):
    print(chunk, end='', flush=True)

resposta = ask_ollama_stream("Explique IA", callback=print_chunk)
```

### Biblioteca Ollama Python
```python
# Instalar biblioteca oficial
# pip install ollama

import ollama

# Uso simples
response = ollama.chat(
    model='llama3',
    messages=[{'role': 'user', 'content': 'Por que o céu é azul?'}]
)
print(response['message']['content'])

# Com opções
response = ollama.chat(
    model='llama3',
    messages=[{'role': 'user', 'content': 'Explique quantum computing'}],
    options={
        'temperature': 0.3,
        'max_tokens': 512
    }
)

# Gerar embeddings
response = ollama.embeddings(
    model='nomic-embed-text',
    prompt='Texto para embed'
)
embeddings = response['embeddings']
```

### Integração com Dask (Processamento Distribuído)
```python
from dask.distributed import Client
import dask.bag as db

def analyze_with_ollama(text):
    """
    Função para processamento distribuído com Ollama
    """
    prompt = f"""
    Analise o texto abaixo e retorne JSON com:
    - sentimento (POSITIVO/NEGATIVO/NEUTRO)
    - tópicos principais (lista)
    - resumo (máximo 50 palavras)
    
    Texto: {text}
    """
    
    try:
        response = requests.post(
            'http://localhost:11434/api/generate',
            json={
                'model': 'llama3',
                'prompt': prompt,
                'stream': False,
                'format': 'json'
            },
            timeout=30
        )
        return response.json()['response']
    except:
        return "{}"

# Processamento paralelo
texts = ["Texto 1", "Texto 2", "Texto 3"]  # Sua lista de textos
bag = db.from_sequence(texts, npartitions=2)
results = bag.map(analyze_with_ollama).compute()

for text, result in zip(texts, results):
    print(f"Texto: {text}")
    print(f"Análise: {result}")
    print("-" * 50)
```

## 🔧 Otimização de Performance

### Otimização para Hardware
```bash
# Verificar hardware disponível
nvidia-smi  # Para NVIDIA
rocm-smi    # Para AMD
lscpu       # Informações da CPU
free -h     # Memória disponível

# Ajustar número de camadas GPU
# (Quanto mais camadas na GPU, melhor a performance)
export OLLAMA_NUM_GPU_LAYERS=35  # NVIDIA high-end
export OLLAMA_NUM_GPU_LAYERS=20  # NVIDIA mid-range  
export OLLAMA_NUM_GPU_LAYERS=10  # NVIDIA entry-level
export OLLAMA_NUM_GPU_LAYERS=8   # AMD
```

### Gerenciamento de Memória
```bash
# Limitar modelos em memória
export OLLAMA_MAX_LOADED_MODELS=2

# Para sistemas com pouca RAM
export OLLAMA_MMAP=1      # Memory mapping
export OLLAMA_F16=0       # Usar float32 (mais preciso, mais memória)
export OLLAMA_KEEP_ALIVE="30m"  # Tempo para manter modelo na memória
```

### Benchmark de Performance
```python
import time
import requests

def benchmark_ollama(model="llama3", prompt="Hello", repetitions=5):
    """
    Teste de performance do Ollama
    """
    times = []
    
    for i in range(repetitions):
        start_time = time.time()
        
        response = requests.post(
            'http://localhost:11434/api/generate',
            json={'model': model, 'prompt': prompt, 'stream': False}
        )
        
        end_time = time.time()
        times.append(end_time - start_time)
        
        if response.status_code != 200:
            print(f"Erro na iteração {i+1}")
            continue
    
    avg_time = sum(times) / len(times)
    tokens_per_second = len(response.json()['response'].split()) / avg_time
    
    print(f"Modelo: {model}")
    print(f"Tempo médio: {avg_time:.2f}s")
    print(f"Tokens por segundo: {tokens_per_second:.2f}")
    print(f"Latência mínima: {min(times):.2f}s")
    print(f"Latência máxima: {max(times):.2f}s")
    
    return times

# Executar benchmark
benchmark_ollama("llama3", "Explique machine learning em 50 palavras")
```

## 🚨 Solução de Problemas

### Problemas Comuns

#### Ollama Não Inicia
```bash
# Verificar status
systemctl status ollama

# Verificar logs
journalctl -u ollama -f

# Reiniciar serviço
sudo systemctl restart ollama

# Verificar portas
sudo lsof -i :11434
```

#### Modelos Não Carregam
```bash
# Verificar espaço em disco
df -h

# Limpar cache
ollama rm --all
ollama pull llama3:8b

# Verificar permissões
ls -la ~/.ollama/
```

#### Performance Ruim
```bash
# Verificar uso GPU
nvidia-smi

# Verificar uso CPU
top

# Verificar uso memória
free -h

# Reduzir camadas GPU (se muita memória)
export OLLAMA_NUM_GPU_LAYERS=20
sudo systemctl restart ollama
```

#### Erro de CUDA/GPU
```bash
# Verificar drivers NVIDIA
nvidia-smi

# Verificar CUDA
nvcc --version

# Instalar drivers (Ubuntu)
sudo apt install nvidia-driver-535 nvidia-cuda-toolkit

# Forçar modo CPU
export OLLAMA_NUM_GPU_LAYERS=0
sudo systemctl restart ollama
```

### Comandos de Diagnóstico
```bash
# Health check completo
curl http://localhost:11434/api/tags
curl http://localhost:11434/api/version

# Verificar modelos
ollama list
ollama ps

# Verificar informações do sistema
ollama info

# Limpar cache
ollama rm --all
ollama pull llama3:8b
```

### Logs Detalhados
```bash
# Modo verbose
OLLAMA_DEBUG=1 ollama serve

# Logs do sistema
journalctl -u ollama -f -n 100

# Logs específicos
sudo tail -f /var/log/syslog | grep ollama
```

## 🎯 Exemplos Práticos

### Assistente de Código
```python
def ask_code_assistant(code, task="explain", model="deepseek-coder"):
    """
    Assistente para análise de código
    """
    prompts = {
        "explain": f"Explique este código:\n\n{code}",
        "debug": f"Encontre bugs neste código:\n\n{code}",
        "optimize": f"Otimize este código:\n\n{code}",
        "document": f"Documente este código:\n\n{code}"
    }
    
    prompt = prompts.get(task, prompts["explain"])
    
    response = requests.post(
        'http://localhost:11434/api/generate',
        json={
            'model': model,
            'prompt': prompt,
            'stream': False,
            'options': {'temperature': 0.3}
        }
    )
    
    return response.json()['response']

# Exemplo
code = """
def calculate_sum(numbers):
    total = 0
    for num in numbers:
        total = total + num
    return total
"""

explicacao = ask_code_assistant(code, "explain")
print(explicacao)
```

### Análise de Sentimento em Lote
```python
from dask.distributed import Client
import dask.bag as db

def analyze_sentiment_batch(texts, model="llama3"):
    """
    Análise de sentimento distribuída
    """
    def analyze_single(text):
        prompt = f"""
        Analise o sentimento do texto abaixo.
        Responda apenas com: POSITIVO, NEGATIVO ou NEUTRO.
        
        Texto: {text}
        """
        
        try:
            response = requests.post(
                'http://localhost:11434/api/generate',
                json={
                    'model': model,
                    'prompt': prompt,
                    'stream': False,
                    'options': {'temperature': 0.1}
                },
                timeout=10
            )
            return response.json()['response'].strip()
        except:
            return "ERROR"
    
    # Processamento paralelo com Dask
    client = Client('localhost:8786')
    bag = db.from_sequence(texts, npartitions=4)
    results = bag.map(analyze_single).compute()
    client.close()
    
    return results

# Exemplo
texts = [
    "Adorei este produto! Entrega rápida e qualidade excelente.",
    "Péssimo atendimento, nunca mais compro aqui.",
    "Produto conforme descrito, entrega no prazo.",
    "Qualidade inferior ao esperado para o preço pago."
]

sentimentos = analyze_sentiment_batch(texts)
for texto, sentimento in zip(texts, sentimentos):
    print(f"{sentimento}: {texto[:50]}...")
```

### Chat Persistente com Histórico
```python
class ChatSession:
    def __init__(self, model="llama3"):
        self.model = model
        self.history = []
    
    def add_message(self, role, content):
        self.history.append({"role": role, "content": content})
    
    def ask(self, prompt):
        self.add_message("user", prompt)
        
        response = requests.post(
            'http://localhost:11434/api/chat',
            json={
                'model': self.model,
                'messages': self.history,
                'stream': False
            }
        )
        
        assistant_response = response.json()['message']['content']
        self.add_message("assistant", assistant_response)
        
        return assistant_response
    
    def clear_history(self):
        self.history = []

# Exemplo de uso
chat = ChatSession("llama3")
print(chat.ask("Olá! Como você pode me ajudar?"))
print(chat.ask("Me explique sobre machine learning"))
print(chat.ask("Agora fale sobre deep learning"))
```

### Geração de Conteúdo
```python
def generate_content(topic, style="formal", length="short", model="llama3"):
    """
    Geração de conteúdo com parâmetros controlados
    """
    length_map = {
        "short": "50 palavras",
        "medium": "150 palavras", 
        "long": "300 palavras"
    }
    
    prompt = f"""
    Escreva um texto {style} sobre {topic}.
    O texto deve ter aproximadamente {length_map[length]}.
    Mantenha o conteúdo informativo e bem estruturado.
    """
    
    response = requests.post(
        'http://localhost:11434/api/generate',
        json={
            'model': model,
            'prompt': prompt,
            'stream': False,
            'options': {
                'temperature': 0.7 if style == "creative" else 0.3,
                'max_tokens': 500 if length == "long" else 200
            }
        }
    )
    
    return response.json()['response']

# Exemplos
texto_curto = generate_content("inteligência artificial", "formal", "short")
texto_longo = generate_content("história da computação", "creative", "long")
```

---

**🎯 Próximos Passos**:
- Explore [Integração com OpenWebUI](../manuals/OPENWEBUI.md)
- Configure [Backup de Modelos](../manuals/BACKUP.md)
- Otimize para [Produção](../../deployments/production/README.md)

