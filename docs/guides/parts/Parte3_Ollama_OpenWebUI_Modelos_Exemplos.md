# Parte 3 — Ollama: instalação, modelos, Open WebUI e exemplos

## 8. Instalação & verificação
- Baixe: https://ollama.com/download
- Verifique:
```bash
ollama --version
ollama list
```

## 9. Comandos básicos
```bash
ollama pull llama3:8b
ollama run llama3:8b "Explique programação assíncrona em Python" --temperature 0.2
ollama serve --port 11434 &
ollama list
```

## 10. Modelos recomendados (por caso de uso)
- **Chat**: `llama3:8b`, `llama3.1:8b`
- **Raciocínio**: `phi3`
- **Código/Dev**: `deepseek-coder-v2:16b`, `starcoder2:7b`, `codellama-34b`
- **Visão**: `llava`, `qwen2-vl`
- **Embeddings**: `nomic-embed-text`, `text-embedding-3-large`

## 11. Exemplos práticos
**Terminal**
```bash
ollama run deepseek-coder-v2:16b "Refatore esta função Python para ser mais eficiente: <código>"
```

**Python (cliente)**
```python
from ollama import Client
client = Client(host='http://localhost:11434')
resp = client.chat(model='llama3:8b', messages=[{'role':'user','content':'Explique a regresão linear.'}])
print(resp['message']['content'])
```

## 12. Usando Ollama com Open WebUI (integração)
**Visão geral**: Ollama expõe API em `http://localhost:11434`. Open WebUI é uma UI que pode consumir essa API.

**Pré-requisitos**
- Ollama + modelos instalados
- Docker ou instalação do Open WebUI
- Porta 11434 acessível

**Passos rápidos (Docker)**
```bash
ollama serve --port 11434 &
ollama list

docker run -d --name open-webui -p 3000:3000 open-webui/open-webui:ollama
```
Acesse `http://localhost:3000` e configure endpoint `http://localhost:11434` se necessário.

**Configurações & troubleshooting**
- Verifique `ss -ltnp | grep 11434` se não conectar.
- Use proxy reverso (NGINX) para TLS em servidores públicos.
- Em Open WebUI, ajuste parâmetros do modelo (temperature, max_tokens, etc.) via Settings.

**Exemplo prático (RAG)**
1. Indexe documentos na Open WebUI (upload / apontar para indexador).
2. Selecione modelo Ollama e crie prompt que inclua contexto recuperado.
