# 🧠 Modelos Ollama: Guia Completo

Este documento descreve os principais **modelos disponíveis no Ollama**, suas características, usos e comandos para **baixar** e **rodar** diretamente.

---

## 1️⃣ Modelos de Chat

Modelos voltados para **conversação, geração de texto natural e assistentes virtuais**.

| Modelo                  | Descrição                 | Uso Principal                        | Comando Pull                        | Comando Rodar                      |
| ----------------------- | ------------------------- | ------------------------------------ | ----------------------------------- | ---------------------------------- |
| `llama3.1:8b`           | LLaMA 3.1, 8B parâmetros  | Conversa geral, chatbots             | `ollama pull llama3.1:8b`           | `ollama run llama3.1:8b`           |
| `llama3.2`              | LLaMA 3.2                 | Chat avançado, respostas contextuais | `ollama pull llama3.2`              | `ollama run llama3.2`              |
| `llama3:8b`             | LLaMA 3 padrão            | Assistentes virtuais                 | `ollama pull llama3:8b`             | `ollama run llama3:8b`             |
| `phi3`                  | Modelo de raciocínio      | QA, lógica, inferência               | `ollama pull phi3`                  | `ollama run phi3`                  |
| `phi4`                  | Phi versão avançada       | Inferência complexa                  | `ollama pull phi4`                  | `ollama run phi4`                  |
| `qwen3`                 | Alta performance          | Conversa longa, coerência            | `ollama pull qwen3`                 | `ollama run qwen3`                 |
| `mistral`               | Modelo rápido open-weight | Chat interativo                      | `ollama pull mistral`               | `ollama run mistral`               |
| `gemma2:9b`             | 9B parâmetros             | Conversa multi-turn                  | `ollama pull gemma2:9b`             | `ollama run gemma2:9b`             |
| `deepseek-coder-v2:16b` | Focado em programação     | Assistente de código técnico         | `ollama pull deepseek-coder-v2:16b` | `ollama run deepseek-coder-v2:16b` |
| `deepseek-chat`         | Chat DeepSeek             | Conversa técnica especializada       | `ollama pull deepseek-chat`         | `ollama run deepseek-chat`         |
| `llama2`                | LLaMA 2 da Meta           | Chat e NLP                           | `ollama pull llama2`                | `ollama run llama2`                |

---

## 2️⃣ Modelo de Visão

| Modelo  | Descrição                   | Uso Principal                        | Comando Pull        | Comando Rodar      |
| ------- | --------------------------- | ------------------------------------ | ------------------- | ------------------ |
| `llava` | Multimodal (texto + imagem) | Q&A visual, interpretação de imagens | `ollama pull llava` | `ollama run llava` |

---

## 3️⃣ Modelos de Autocomplete

Indicados para **programação, autocompletar código e sugestões inteligentes**.

| Modelo               | Descrição           | Uso Principal                       | Comando Pull                     | Comando Rodar                   |
| -------------------- | ------------------- | ----------------------------------- | -------------------------------- | ------------------------------- |
| `starcoder2:3b`      | StarCoder 2, 3B     | Autocomplete de código              | `ollama pull starcoder2:3b`      | `ollama run starcoder2:3b`      |
| `starcoder2:7b`      | StarCoder 2, 7B     | Sugestões avançadas                 | `ollama pull starcoder2:7b`      | `ollama run starcoder2:7b`      |
| `qwen2.5-coder:1.5b` | Código leve         | Autocomplete, suporte a programação | `ollama pull qwen2.5-coder:1.5b` | `ollama run qwen2.5-coder:1.5b` |
| `deepseek-coder`     | Assistente DeepSeek | Completamento e sugestão de funções | `ollama pull deepseek-coder`     | `ollama run deepseek-coder`     |

---

## 4️⃣ Modelo de Embeddings

Transforma texto em **vetores** para buscas semânticas, clustering e recomendação.

| Modelo             | Descrição           | Uso Principal                            | Comando Pull                   | Comando Rodar                 |
| ------------------ | ------------------- | ---------------------------------------- | ------------------------------ | ----------------------------- |
| `nomic-embed-text` | Embeddings textuais | Busca semântica, vetorização, clustering | `ollama pull nomic-embed-text` | `ollama run nomic-embed-text` |

---

## ⚡ Observações

- Use `ollama pull <modelo>` **uma vez** para baixar o modelo localmente.
- Use `ollama run <modelo>` para **executar o modelo localmente**.
- Para **modelos de chat**, é possível adicionar prompts diretamente:

```bash
ollama run llama2 --prompt "Explique a física quântica de forma simples"
```

- Para **autocomplete ou embeddings**, use o modelo para gerar código ou vetores conforme a aplicação.
- Para evitar conflito de porta com o daemon do Ollama:

```bash
ollama serve --port 11435
```

---

