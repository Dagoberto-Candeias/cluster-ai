markdown
# Modelos e Configurações para Ollama e Continue VSCode

## 📥 Comandos para Baixar Modelos

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
  # === MODELO PRINCIPAL PARA CHAT ===
  - name: Llama 3.1 8B Principal
    provider: ollama
    model: llama3.1:8b
    roles:
      - chat
      - edit
      - apply
    defaultCompletionOptions:
      temperature: 0.7
      maxTokens: 4096
      contextLength: 8192
    chatOptions:
      baseSystemMessage: "Você é um assistente de programação especializado. Forneça respostas concisas, práticas e bem estruturadas em português brasileiro."

  # === MODELO ESPECIALIZADO PARA CÓDIGO ===
  - name: DeepSeek Coder V2 16B
    provider: ollama
    model: deepseek-coder-v2:16b
    roles:
      - chat
      - edit
      - apply
    defaultCompletionOptions:
      temperature: 0.3
      maxTokens: 8192
      contextLength: 16384

  # === MODELOS DE CHAT ALTERNATIVOS ===
  - name: Llama 3.2
    provider: ollama
    model: llama3.2
    roles:
      - chat
      - edit
    defaultCompletionOptions:
      temperature: 0.7
      maxTokens: 4096

  - name: Mistral
    provider: ollama
    model: mistral
    roles:
      - chat
      - edit
      - apply
    defaultCompletionOptions:
      temperature: 0.6
      maxTokens: 4096

  - name: Gemma2 9B
    provider: ollama
    model: gemma2:9b
    roles:
      - chat
      - edit
    defaultCompletionOptions:
      temperature: 0.7
      maxTokens: 4096

  - name: Phi 4
    provider: ollama
    model: phi4
    roles:
      - chat
      - edit
    defaultCompletionOptions:
      temperature: 0.7
      maxTokens: 4096

  - name: Qwen 3
    provider: ollama
    model: qwen3
    roles:
      - chat
      - edit
    defaultCompletionOptions:
      temperature: 0.7
      maxTokens: 4096

  # === MODELOS DEEPSEEK CHAT LITE ===
  - name: DeepSeek Chat V2 Lite IQ4XS
    provider: ollama
    model: akuldatta/deepseek-chat-v2-lite:iq4xs
    roles:
      - chat
    defaultCompletionOptions:
      temperature: 0.7
      maxTokens: 4096

  - name: DeepSeek Chat V2 Lite Q4KM
    provider: ollama
    model: akuldatta/deepseek-chat-v2-lite:q4km
    roles:
      - chat
    defaultCompletionOptions:
      temperature: 0.7
      maxTokens: 4096

  # === MODELO DE VISÃO ===
  - name: LLaVA Vision
    provider: ollama
    model: llava
    capabilities:
      - image_input
    roles:
      - chat
    defaultCompletionOptions:
      temperature: 0.7
      maxTokens: 2048

  # === MODELOS PARA AUTOCOMPLETE ===
  - name: Qwen2.5-Coder 1.5B
    provider: ollama
    model: qwen2.5-coder:1.5b
    roles:
      - autocomplete
    autocompleteOptions:
      debounceDelay: 250
      maxPromptTokens: 1024
      modelTimeout: 150
      onlyMyCode: true
      useCache: true
      useRecentlyEdited: true
    defaultCompletionOptions:
      temperature: 0.2
      maxTokens: 512

  - name: StarCoder2 3B
    provider: ollama
    model: starcoder2:3b
    roles:
      - autocomplete
    autocompleteOptions:
      debounceDelay: 200
      maxPromptTokens: 1024
      modelTimeout: 120
      onlyMyCode: true
    defaultCompletionOptions:
      temperature: 0.2
      maxTokens: 512

  - name: StarCoder2 7B
    provider: ollama
    model: starcoder2:7b
    roles:
      - autocomplete
    autocompleteOptions:
      debounceDelay: 300
      maxPromptTokens: 1024
      modelTimeout: 200
      onlyMyCode: true
    defaultCompletionOptions:
      temperature: 0.2
      maxTokens: 512

  - name: DeepSeek Coder
    provider: ollama
    model: deepseek-coder
    roles:
      - autocomplete
    autocompleteOptions:
      debounceDelay: 250
      maxPromptTokens: 1024
      modelTimeout: 180
      onlyMyCode: true
    defaultCompletionOptions:
      temperature: 0.2
      maxTokens: 512

  # === MODELO DE EMBEDDINGS ===
  - name: Nomic Embed Text
    provider: ollama
    model: nomic-embed-text
    roles:
      - embed
    embedOptions:
      maxChunkSize: 512
      maxBatchSize: 10

# === CONTEXTO OTIMIZADO ===
context:
  - provider: codebase
    params:
      nRetrieve: 25
      nFinal: 5
  - provider: file
  - provider: code
  - provider: diff
  - provider: folder
  - provider: open
    params:
      onlyPinned: false
  - provider: terminal
  - provider: problems
  - provider: tree

# === REGRAS CONTEXTUAIS ===
rules:
  - name: Idioma Padrão
    rule: "Sempre responda em português brasileiro, exceto quando especificamente solicitado outro idioma"

  - name: Qualidade do Código
    rule: "Priorize código limpo, legível e bem documentado. Use padrões de nomenclatura consistentes e siga as melhores práticas da linguagem"

  - name: Segurança e Performance
    rule: "Sempre considere aspectos de segurança e performance nas soluções propostas. Identifique vulnerabilidades potenciais"

  - name: Explicações Técnicas
    rule: "Forneça explicações claras do raciocínio por trás das soluções, especialmente para código complexo"

  - name: TypeScript
    rule: "Para projetos TypeScript, sempre use tipagem forte, interfaces bem definidas e evite 'any'. Prefira type guards e utility types"
    globs: "**/*.{ts,tsx}"

  - name: Python
    rule: "Para Python, use type hints, siga PEP 8, prefira f-strings e use dataclasses/pydantic para estruturas de dados"
    globs: "**/*.py"

  - name: React
    rule: "Para React, use hooks funcionais, evite prop drilling, implemente error boundaries e otimize re-renders"
    globs: "**/*.{jsx,tsx}"

  - name: Testes
    rule: "Para arquivos de teste, foque em cobertura completa, casos extremos, mocks apropriados e testes legíveis"
    globs: "**/*.{test,spec}.{js,ts,jsx,tsx,py}"

# === PROMPTS PERSONALIZADOS ===
prompts:
  - name: revisar-codigo-completo
    description: "Análise completa de código com foco em qualidade, segurança e performance"
    prompt: |
      Analise o código selecionado de forma abrangente e sistemática:
      ## 🔍 ANÁLISE DE QUALIDADE
      - **Erros de sintaxe e lógica**: Identifique problemas imediatos
      - **Padrões de código**: Verifique conformidade com convenções
      - **Legibilidade**: Avalie clareza e manutenibilidade
      - **Estrutura**: Analise organização e arquitetura
      ## 🛡️ ANÁLISE DE SEGURANÇA
      - **Vulnerabilidades**: Identifique riscos de segurança
      - **Validação de entrada**: Verifique sanitização de dados
      - **Autenticação/Autorização**: Analise controles de acesso
      - **Exposição de dados**: Identifique vazamentos potenciais
      ## ⚡ ANÁLISE DE PERFORMANCE
      - **Complexidade algorítmica**: Avalie eficiência
      - **Uso de memória**: Identifique vazamentos ou uso excessivo
      - **Operações custosas**: Localize gargalos
      - **Otimizações**: Sugira melhorias específicas
      ## 📋 SUGESTÕES DE MELHORIA
      Para cada problema identificado, forneça:
      - Explicação clara do problema
      - Impacto potencial
      - Solução específica com exemplo de código
      - Prioridade (Alta/Média/Baixa)
      Organize a resposta de forma estruturada e priorize os problemas mais críticos.

  - name: documentar-api
    description: "Gerar documentação completa para APIs e funções"
    prompt: |
      Crie documentação técnica completa para o código selecionado:
      ## 📖 DOCUMENTAÇÃO PRINCIPAL
      - **Descrição**: Funcionalidade principal e propósito
      - **Responsabilidades**: O que o código faz e não faz
      - **Contexto de uso**: Quando e como usar
      ## 🔧 ESPECIFICAÇÃO TÉCNICA
      - **Parâmetros**: Tipos, descrições e validações
      - **Retorno**: Tipo, estrutura e possíveis valores
      - **Exceções**: Erros possíveis e quando ocorrem
      - **Dependências**: Bibliotecas e módulos necessários
      ## 💡 EXEMPLOS PRÁTICOS
      - **Uso básico**: Exemplo simples e direto
      - **Casos avançados**: Cenários complexos
      - **Tratamento de erros**: Como lidar com falhas
      - **Integração**: Como usar com outros componentes
      ## 📊 INFORMAÇÕES ADICIONAIS
      - **Performance**: Complexidade e considerações
      - **Limitações**: Restrições conhecidas
      - **Versioning**: Compatibilidade e mudanças
      - **Testes**: Como testar a funcionalidade
      Use o formato de documentação apropriado para a linguagem (JSDoc, docstring, etc.).

  - name: criar-testes-abrangentes
    description: "Gerar suite completa de testes unitários e de integração"
    prompt: |
      Crie uma suite abrangente de testes para o código selecionado:
      ## 🧪 ESTRUTURA DOS TESTES
      - **Setup/Teardown**: Configuração e limpeza necessárias
      - **Mocks e Stubs**: Dependências simuladas apropriadas
      - **Fixtures**: Dados de teste reutilizáveis
      - **Helpers**: Funções auxiliares para testes
      ## ✅ COBERTURA DE CENÁRIOS
      - **Happy Path**: Casos de sucesso principais
      - **Edge Cases**: Casos extremos e limites
      - **Error Cases**: Cenários de falha e exceções
      - **Boundary Testing**: Valores limítrofes
      ## 🔄 TIPOS DE TESTE
      - **Unitários**: Testes isolados de funções/métodos
      - **Integração**: Testes de interação entre componentes
      - **Performance**: Testes de tempo e memória (se relevante)
      - **Regressão**: Testes para bugs conhecidos
      ## 📝 ORGANIZAÇÃO
      - **Describe/Context**: Agrupamento lógico dos testes
      - **Test Names**: Nomes descritivos e claros
      - **Assertions**: Verificações específicas e múltiplas
      - **Comments**: Explicações para lógica complexa
      ## 🎯 QUALIDADE DOS TESTES
      - **Independência**: Testes não devem depender uns dos outros
      - **Determinismo**: Resultados consistentes
      - **Velocidade**: Execução rápida
      - **Manutenibilidade**: Fácil de atualizar
      Use o framework de teste apropriado e inclua instruções de execução.

  - name: otimizar-performance
    description: "Análise e otimização detalhada de performance"
    prompt: |
      Analise e otimize a performance do código selecionado:
      ## 📊 ANÁLISE ATUAL
      - **Profiling**: Identifique gargalos de performance
      - **Complexidade**: Analise Big O de algoritmos
      - **Recursos**: Avalie uso de CPU, memória e I/O
      - **Benchmarks**: Estabeleça métricas atuais
      ## 🚀 OTIMIZAÇÕES ALGORÍTMICAS
      - **Estruturas de dados**: Sugira alternativas mais eficientes
      - **Algoritmos**: Implemente versões otimizadas
      - **Caching**: Identifique oportunidades de cache
      - **Lazy loading**: Implemente carregamento sob demanda
      ## 💾 OTIMIZAÇÕES DE MEMÓRIA
      - **Memory leaks**: Identifique e corrija vazamentos
      - **Object pooling**: Reutilize objetos quando apropriado
      - **Garbage collection**: Otimize para GC eficiente
      - **Data structures**: Use estruturas memory-efficient
      ## 🔄 OTIMIZAÇÕES DE I/O
      - **Batch operations**: Agrupe operações similares
      - **Async/await**: Implemente operações assíncronas
      - **Connection pooling**: Reutilize conexões
      - **Compression**: Reduza tamanho de dados transferidos
      ## 📈 MÉTRICAS E MONITORAMENTO
      - **KPIs**: Defina métricas de performance
      - **Logging**: Adicione logs de performance
      - **Monitoring**: Sugira ferramentas de monitoramento
      - **Alertas**: Configure alertas para degradação
      Para cada otimização, forneça:
      - Código antes/depois
      - Impacto esperado
      - Trade-offs envolvidos
      - Métricas para validação.

  - name: refatorar-codigo
    description: "Refatoração sistemática para melhor arquitetura"
    prompt: |
      Refatore o código selecionado seguindo princípios de clean code:
      ## 🏗️ ANÁLISE ARQUITETURAL
      - **SOLID Principles**: Verifique conformidade
      - **Design Patterns**: Identifique padrões aplicáveis
      - **Separation of Concerns**: Analise responsabilidades
      - **Coupling/Cohesion**: Avalie dependências
      ## 🔧 REFATORAÇÕES ESTRUTURAIS
      - **Extract Method**: Separe funcionalidades complexas
      - **Extract Class**: Crie classes para responsabilidades distintas
      - **Move Method**: Reorganize métodos em classes apropriadas
      - **Rename**: Melhore nomes de variáveis, funções e classes
      ## 📦 ORGANIZAÇÃO DE CÓDIGO
      - **Modularização**: Divida em módulos coesos
      - **Interfaces**: Defina contratos claros
      - **Abstrações**: Crie camadas de abstração apropriadas
      - **Dependencies**: Organize e minimize dependências
      ## 🎯 MELHORIAS ESPECÍFICAS
      - **Error Handling**: Implemente tratamento robusto de erros
      - **Logging**: Adicione logs estruturados
      - **Configuration**: Externalize configurações
      - **Testing**: Torne o código mais testável
      ## 📋 PLANO DE REFATORAÇÃO
      1. **Fase 1**: Refatorações seguras (renomeação, extração)
      2. **Fase 2**: Mudanças estruturais (classes, interfaces)
      3. **Fase 3**: Otimizações arquiteturais
      4. **Validação**: Testes para cada fase
      Mantenha a funcionalidade original e forneça um plano de migração gradual.

  - name: explicar-imagem-tecnica
    description: "Análise técnica detalhada de imagens (usar com LLaVA)"
    prompt: |
      Analise a imagem fornecida com foco técnico detalhado:
      ## 👁️ ANÁLISE VISUAL GERAL
      - **Elementos principais**: Identifique componentes visuais
      - **Layout e estrutura**: Analise organização espacial
      - **Texto visível**: Transcreva e interprete textos
      - **Cores e design**: Avalie esquema visual
      ## 💻 ANÁLISE TÉCNICA ESPECÍFICA
      Se for código/diagrama:
      - **Linguagem/Framework**: Identifique tecnologias
      - **Padrões**: Reconheça design patterns
      - **Arquitetura**: Analise estrutura do sistema
      - **Fluxo de dados**: Trace o fluxo de informações
      Se for interface/UI:
      - **UX/UI Patterns**: Identifique padrões de interface
      - **Responsividade**: Avalie adaptabilidade
      - **Acessibilidade**: Verifique conformidade
      - **Performance**: Analise otimizações visuais
      Se for diagrama/arquitetura:
      - **Componentes**: Identifique elementos do sistema
      - **Relacionamentos**: Analise conexões e dependências
      - **Fluxos**: Trace processos e comunicações
      - **Escalabilidade**: Avalie capacidade de crescimento
      ## 🔍 INSIGHTS TÉCNICOS
      - **Boas práticas**: Identifique implementações corretas
      - **Problemas potenciais**: Aponte possíveis issues
      - **Melhorias**: Sugira otimizações específicas
      - **Alternativas**: Proponha abordagens diferentes
      ## 📚 CONTEXTO E RECOMENDAÇÕES
      - **Documentação**: Sugira documentação relevante
      - **Ferramentas**: Recomende tools apropriadas
      - **Próximos passos**: Indique ações de follow-up
      - **Recursos**: Aponte materiais de aprendizado
      Forneça insights acionáveis baseados na análise visual.

# === DOCUMENTAÇÃO TÉCNICA ===
docs:
  - name: Python Official
    startUrl: https://docs.python.org/3/
  - name: JavaScript MDN
    startUrl: https://developer.mozilla.org/en-US/docs/Web/JavaScript
  - name: TypeScript
    startUrl: https://www.typescriptlang.org/docs/
  - name: React
    startUrl: https://react.dev/
  - name: Node.js
    startUrl: https://nodejs.org/docs/
  - name: Vue.js
    startUrl: https://vuejs.org/guide/
  - name: FastAPI
    startUrl: https://fastapi.tiangolo.com/
  - name: Django
    startUrl: https://docs.djangoproject.com/
  - name: Flask
    startUrl: https://flask.palletsprojects.com/
  - name: Express.js
    startUrl: https://expressjs.com/
  - name: Pandas
    startUrl: https://pandas.pydata.org/docs/
  - name: NumPy
    startUrl: https://numpy.org/doc/
  - name: Pytest
    startUrl: https://docs.pytest.org/
  - name: Jest
    startUrl: https://jestjs.io/docs/
  - name: Docker
    startUrl: https://docs.docker.com/
📌 Resumo
Modelos disponíveis: Chat, Visão, Autocomplete e Embeddings.

Configuração: YAML para a extensão Continue VSCode com modelos otimizados por função.

Regras contextuais: Diretrizes para qualidade de código, segurança e linguagens específicas.

Prompts personalizados: Para revisão de código, documentação, testes, otimização e refatoração.

Documentação técnica: Links para referências oficiais das principais tecnologias.
