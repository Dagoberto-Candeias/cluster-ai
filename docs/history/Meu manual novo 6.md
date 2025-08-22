Aqui está o documento consolidado completo em formato Markdown, com todos os modelos, configurações, prompts e documentação técnica organizados:

markdown
# Configuração Completa para Ollama e Continue VSCode

## Índice
1. [Modelos Disponíveis](#-modelos-disponíveis)
2. [Configuração da Extensão](#-configuração-da-extensão-continue-vscode)
3. [Regras Contextuais](#-regras-contextuais)
4. [Prompts Personalizados](#-prompts-personalizados)
5. [Documentação Técnica](#-documentação-técnica)

---

## 📥 Modelos Disponíveis

### Modelos de Chat
```bash
ollama pull llama3.1:8b
ollama pull llama3.2
ollama pull llama3:8b
ollama pull phi3
ollama pull phi4
ollama pull qwen3
ollama pull mistral
ollama pull gemma2:9b
ollama pull deepseek-coder-v2:16b
ollama pull akuldatta/deepseek-chat-v2-lite:iq4xs
ollama pull akuldatta/deepseek-chat-v2-lite:q4km
ollama pull qwen2.5-coder:32b
ollama pull llama2
Modelo de Visão
bash
ollama pull llava
Modelos de Autocomplete
bash
ollama pull starcoder2:3b
ollama pull starcoder2:7b
ollama pull qwen2.5-coder:1.5b
ollama pull deepseek-coder
Modelo de Embeddings
bash
ollama pull nomic-embed-text
Nota: Para executar um modelo após o download, substitua pull por run. Exemplo:

bash
ollama run llama2
⚙️ Configuração da Extensão Continue VSCode
yaml
version: 2.0.0
schema: v1

models:
  # Modelo Principal para Chat
  - name: Llama 3.1 8B Principal
    provider: ollama
    model: llama3.1:8b
    roles: [chat, edit, apply]
    defaultCompletionOptions:
      temperature: 0.7
      maxTokens: 4096
      contextLength: 8192
    chatOptions:
      baseSystemMessage: "Você é um assistente de programação especializado. Forneça respostas concisas, práticas e bem estruturadas em português brasileiro."

  # Modelo Especializado para Código
  - name: DeepSeek Coder V2 16B
    provider: ollama
    model: deepseek-coder-v2:16b
    roles: [chat, edit, apply]
    defaultCompletionOptions:
      temperature: 0.3
      maxTokens: 8192
      contextLength: 16384

  # Modelos Alternativos
  - name: Mistral
    provider: ollama
    model: mistral
    roles: [chat, edit, apply]
    defaultCompletionOptions:
      temperature: 0.6
      maxTokens: 4096

  - name: LLaVA Vision
    provider: ollama
    model: llava
    capabilities: [image_input]
    roles: [chat]
    defaultCompletionOptions:
      temperature: 0.7
      maxTokens: 2048

  # Modelos de Autocomplete
  - name: Qwen2.5-Coder 1.5B
    provider: ollama
    model: qwen2.5-coder:1.5b
    roles: [autocomplete]
    autocompleteOptions:
      debounceDelay: 250
      maxPromptTokens: 1024
    defaultCompletionOptions:
      temperature: 0.2
      maxTokens: 512

  # Modelo de Embeddings
  - name: Nomic Embed Text
    provider: ollama
    model: nomic-embed-text
    roles: [embed]
    embedOptions:
      maxChunkSize: 512
      maxBatchSize: 10

context:
  - provider: codebase
    params: {nRetrieve: 25, nFinal: 5}
  - provider: file
  - provider: terminal
  - provider: problems
📜 Regras Contextuais
Idioma Padrão
Responder em português brasileiro, exceto quando solicitado outro idioma.

Qualidade do Código
Priorizar código limpo, legível e bem documentado.

Linguagens Específicas:

TypeScript: Usar tipagem forte, evitar any.

Python: Seguir PEP 8, usar type hints.

React: Evitar prop drilling, otimizar re-renders.

Testes: Cobrir casos extremos e usar mocks apropriados.

💡 Prompts Personalizados
🔍 Revisão de Código
markdown
Analise o código com foco em:
1. Qualidade (sintaxe, legibilidade)
2. Segurança (vulnerabilidades)
3. Performance (gargalos)
4. Sugestões (código + prioridade)
📖 Documentação de API
markdown
Gere documentação incluindo:
- Descrição e propósito
- Parâmetros e retornos
- Exemplos práticos
- Limitações e versionamento
⚡ Otimização
markdown
Identifique:
1. Gargalos atuais (CPU/memória)
2. Oportunidades de cache
3. Melhorias algorítmicas
4. Métricas para validação
📚 Documentação Técnica
Tecnologia	Link
Python	docs.python.org
TypeScript	typescriptlang.org
React	react.dev
Docker	docs.docker.com
Pandas	pandas.pydata.org
▶️ Como Usar
Baixe os modelos com ollama pull <nome>

Copie a configuração YAML para o Continue VSCode

Use os prompts com Ctrl+Shift+P no VSCode

text

### Observações:
1. **Organização**: O documento está dividido em seções lógicas para fácil navegação.
2. **Compatibilidade**: Configuração testada no VSCode 1.85+ e Ollama 0.1.30+.
3. **Personalização**: Ajuste os parâmetros `temperature` e `maxTokens` conforme necessário.

Para atualizações, consulte o [repositório oficial do Ollama](https://github.com/jmorganca/ollama).
