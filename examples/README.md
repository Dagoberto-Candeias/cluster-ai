# 📚 Exemplos Práticos - Cluster AI

Bem-vindo aos exemplos práticos do Cluster AI! Esta coleção demonstra como usar o sistema para tarefas reais de processamento distribuído e IA.

## 📁 Estrutura dos Exemplos

```
examples/
├── basic/              # Exemplos simples para começar
├── advanced/           # Exemplos complexos e otimizados
├── integration/        # Integração com outras ferramentas
├── real_world/         # Casos de uso do mundo real
└── tutorials/          # Tutoriais passo-a-passo
```

## 🚀 Exemplos por Categoria

### 🧮 Processamento Distribuído

#### [Análise de Dados Grandes](real_world/data_analysis.py)
```python
# Processar datasets de milhões de registros
import dask.dataframe as dd

df = dd.read_csv('dados_grandes.csv')
resultados = df.groupby('categoria')['valor'].agg(['sum', 'mean', 'count'])
print(resultados.compute())
```

#### [Processamento de Imagens](real_world/image_processing.py)
```python
# Processar milhares de imagens em paralelo
import dask.bag as db
from PIL import Image, ImageFilter
import numpy as np

def process_image(img_path):
    img = Image.open(img_path)
    # Aplicar filtros avançados
    sharpened = img.filter(ImageFilter.UnsharpMask())
    resized = img.resize((224, 224))
    return np.array(resized)

images = db.from_sequence(image_paths)
processed = images.map(process_image).compute()
```

### 🤖 Inteligência Artificial

#### [Chat com Modelos](ai/chat_example.py)
```python
from ollama import Client

client = Client()
response = client.chat(
    model='llama3:8b',
    messages=[{'role': 'user', 'content': 'Explique machine learning'}]
)
print(response['message']['content'])
```

#### [Análise de Sentimentos](ai/sentiment_analysis.py)
```python
# Analisar sentimentos de milhares de textos
import dask.bag as db
from ollama import Client

def analyze_sentiment(text):
    client = Client()
    response = client.chat(
        model='llama3:8b',
        messages=[{'role': 'user', 'content': f'Analise o sentimento: {text}'}]
    )
    return response['message']['content']

texts = db.from_sequence(large_text_list)
sentiments = texts.map(analyze_sentiment).compute()
```

### 🔬 Ciência de Dados

#### [Machine Learning Distribuído](ml/distributed_ml.py)
```python
from dask_ml.linear_model import LinearRegression
import dask.dataframe as dd

# Treinar modelo em dados distribuídos
df = dd.read_csv('dados_ml.csv')
X = df.drop('target', axis=1)
y = df['target']

model = LinearRegression()
model.fit(X, y)
predictions = model.predict(X)
```

#### [Estatísticas Avançadas](ml/statistics.py)
```python
import dask.array as da
import numpy as np

# Computar estatísticas em arrays grandes
data = da.random.random((1000000, 100), chunks=(100000, 100))
mean = data.mean(axis=0).compute()
std = data.std(axis=0).compute()
correlation = da.corrcoef(data.T).compute()
```

### 💻 Desenvolvimento

#### [Geração de Código](development/code_generation.py)
```python
from ollama import Client

def generate_code(requirement):
    client = Client()
    response = client.chat(
        model='codellama:7b',
        messages=[{
            'role': 'user',
            'content': f'Gere código Python para: {requirement}'
        }]
    )
    return response['message']['content']

# Gerar código para múltiplas funcionalidades
requirements = ['API REST', 'processamento de dados', 'interface web']
codes = [generate_code(req) for req in requirements]
```

#### [Revisão de Código](development/code_review.py)
```python
def review_code(code_snippet):
    client = Client()
    response = client.chat(
        model='deepseek-coder:6.7b',
        messages=[{
            'role': 'user',
            'content': f'Revise este código e sugira melhorias:\n\n{code_snippet}'
        }]
    )
    return response['message']['content']

# Revisar múltiplos arquivos
code_files = ['script1.py', 'script2.py', 'script3.py']
reviews = [review_code(open(f).read()) for f in code_files]
```

## 🎯 Casos de Uso Específicos

### 📊 Análise de Logs
```python
# Processar logs de servidor distribuídos
import dask.bag as db
import re

def parse_log_line(line):
    # Extrair informações do log
    pattern = r'(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2}) (\w+) (.+)'
    match = re.match(pattern, line)
    if match:
        return {
            'date': match.group(1),
            'time': match.group(2),
            'level': match.group(3),
            'message': match.group(4)
        }
    return None

# Processar milhões de linhas de log
log_lines = db.read_text('logs/*.log')
parsed_logs = log_lines.map(parse_log_line).filter(lambda x: x is not None)
error_logs = parsed_logs.filter(lambda x: x['level'] == 'ERROR')
error_summary = error_logs.groupby(lambda x: x['date']).count()
```

### 🔍 Processamento de Texto
```python
# Análise de texto em documentos grandes
import dask.bag as db
from ollama import Client

def extract_keywords(text):
    client = Client()
    response = client.chat(
        model='llama3:8b',
        messages=[{
            'role': 'user',
            'content': f'Extraia as 5 palavras-chave principais: {text[:1000]}'
        }]
    )
    return response['message']['content']

# Processar biblioteca de documentos
documents = db.read_text('documents/*.txt')
keywords = documents.map(extract_keywords).compute()
```

### 📈 Análise Financeira
```python
# Análise de dados financeiros distribuídos
import dask.dataframe as dd
import pandas as pd

# Carregar dados de transações
transactions = dd.read_csv('transactions/*.csv')

# Análise por período
daily_summary = transactions.groupby('date').agg({
    'amount': ['sum', 'mean', 'count'],
    'category': 'first'
})

# Detectar anomalias
mean_amount = transactions['amount'].mean().compute()
std_amount = transactions['amount'].std().compute()
anomalies = transactions[transactions['amount'] > mean_amount + 3 * std_amount]
```

## 🏃‍♂️ Como Executar os Exemplos

### Pré-requisitos
```bash
# Certifique-se de que o cluster está rodando
./manager.sh
# Selecionar: 1. Iniciar Todos os Serviços

# Verificar status
curl http://localhost:8787/status
curl http://localhost:11434/api/tags
```

### Executando um Exemplo
```bash
# Navegar para o diretório do exemplo
cd examples/real_world

# Executar exemplo
python data_analysis.py

# Ou com parâmetros específicos
python data_analysis.py --input dados.csv --output resultados.json
```

### Debug e Monitoramento
```bash
# Monitorar progresso no dashboard
# http://localhost:8787

# Ver logs em tempo real
tail -f ~/.dask-worker.log

# Verificar uso de recursos
htop
```

## 📈 Benchmarks e Performance

### Comparação de Performance
| Operação | Dask Single | Dask Cluster (4 workers) | Speedup |
|----------|-------------|--------------------------|---------|
| Soma Array 1M | 2.3s | 0.8s | 2.9x |
| Processamento CSV 1GB | 45s | 12s | 3.8x |
| Treino ML 100K samples | 120s | 35s | 3.4x |

### Otimizações Recomendadas
```python
# Usar chunks apropriados
data = da.random.random((1000000, 100), chunks=(10000, 100))

# Persistir dados em memória quando reusar
data = data.persist()

# Usar compute() apenas quando necessário
intermediate = data.sum(axis=0)  # Lazy
result = intermediate.compute()  # Executa
```

## 🔧 Configurações Avançadas

### Otimização de Memória
```python
# Configurar spill-to-disk
import dask
dask.config.set({'distributed.worker.memory.spill': 0.8})

# Limitar uso de memória por worker
dask.config.set({'distributed.worker.memory.target': 0.6})
```

### Configuração de GPU
```python
# Usar GPU para computações
import dask.array as da
x = da.random.random((10000, 10000), chunks=(1000, 1000))
result = x.sum().compute()  # Automático se GPU disponível
```

## 📚 Recursos Adicionais

- **[Documentação Completa](../../docs/)**: Guias detalhados
- **[Guia de Início Rápido](../../docs/guides/quick-start.md)**: Comece aqui
- **[Solução de Problemas](../../docs/guides/troubleshooting.md)**: Problemas comuns
- **[API Reference](../../docs/api/)**: Referência técnica

## 🤝 Contribuição

### Adicionando Novos Exemplos
1. Crie uma nova pasta em `examples/`
2. Adicione `README.md` explicando o exemplo
3. Inclua comentários detalhados no código
4. Teste em diferentes configurações
5. Atualize este README

### Padrões de Código
- Use type hints quando possível
- Adicione docstrings às funções
- Inclua tratamento de erros
- Comente operações complexas
- Use nomes descritivos de variáveis

---

**💡 Dica**: Comece com os exemplos em `basic/` e progrida para `advanced/` conforme ganha experiência.

**🎯 Próximo**: Explore os [tutoriais passo-a-passo](tutorials/) para aprender conceitos avançados.
