🚀 Guia Definitivo: Ambientes Virtuais Python e Modelos Ollama para Desenvolvimento Profissional
Introdução: Domine Seu Ambiente de Desenvolvimento
Este guia completo ensinará você a:

Dominar ambientes virtuais Python (venv e conda)

Instalar, configurar e usar modelos Ollama para IA

Integrar tudo no VSCode com a extensão Continue

Adotar fluxos de trabalho profissionais

Vamos começar do básico e avançar para técnicas avançadas!

Parte 1: Ambientes Virtuais Python 🐍
1.1 Por que Ambientes Virtuais?
Problema comum:

"Meu projeto A precisa do pandas 1.5, mas o projeto B precisa do pandas 2.0 e eles não funcionam juntos!"

Solução: Ambientes virtuais criam espaços isolados para cada projeto:

Diagram
Code
graph LR
    A[Projeto 1] --> B[Pandas 1.5]
    C[Projeto 2] --> D[Pandas 2.0]
    E[Sistema] --> F[Python 3.11]
    A & C --> E
1.2 Venv: Ambiente Nativo do Python
Instalação e Configuração Inicial
bash
# Verifique se o Python está instalado
python --version
# Se não tiver: https://www.python.org/downloads/
# MARQUE "Add Python to PATH" durante a instalação!
Criando e Gerenciando Ambientes
bash
# Criar ambiente (Windows/Linux/macOS)
python -m venv meu_projeto_env

# Ativar ambiente (Windows CMD)
meu_projeto_env\Scripts\activate.bat

# Ativar ambiente (Windows PowerShell - PRIMEIRO PERMITA SCRIPTS)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
& "meu_projeto_env\Scripts\Activate.ps1"

# Ativar ambiente (Linux/macOS)
source meu_projeto_env/bin/activate

# Desativar ambiente (todos os sistemas)
deactivate
Gerenciamento de Pacotes
bash
# Instalar pacotes
pip install pandas==1.5.3 matplotlib

# Instalar com dependências exatas
pip install "scikit-learn>=1.2.0,<1.3.0"

# Listar pacotes instalados
pip list

# Gerar requirements.txt (IMPORTANTE para compartilhar!)
pip freeze > requirements.txt

# Instalar de requirements.txt
pip install -r requirements.txt

# Verificar pacotes desatualizados
pip list --outdated
1.3 Conda: Para Ciência de Dados
Instalação
Miniconda (leve, ~500MB)

Anaconda (completo, ~3GB)

Comandos Essenciais
bash
# Criar ambiente com Python específico
conda create --name ciencia_dados python=3.10

# Criar ambiente com pacotes
conda create --name ml_env python=3.9 numpy pandas scikit-learn

# Ativar ambiente
conda activate ciencia_dados

# Instalar pacotes
conda install matplotlib seaborn

# Listar ambientes
conda env list

# Exportar ambiente (RECOMENDADO para reprodução)
conda env export > environment.yml

# Criar ambiente a partir de YAML
conda env create -f environment.yml

# Remover ambiente
conda remove --name antigo_env --all
1.4 Integração com Ferramentas
Com Spyder
bash
# No ambiente venv
pip install spyder-kernels
# Depois em Spyder: Ferramentas > Preferências > Interpretador Python

# No ambiente conda
conda install spyder
spyder
Com Jupyter Notebooks
bash
# Registrar kernel do ambiente
pip install ipykernel
python -m ipykernel install --user --name=meu_kernel --display-name "Python (Meu Ambiente)"
1.5 Gerenciamento Avançado de Dependências
Arquivo requirements.txt (venv)
txt
# Exemplo completo
pandas==1.5.3
numpy>=1.21.0,<1.22.0
matplotlib==3.7.1
scikit-learn # versão mais recente
Arquivo environment.yml (conda)
yaml
name: projeto_analise
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.10
  - numpy=1.23.5
  - pandas=1.5.3
  - scikit-learn=1.2.2
  - pip:
    - matplotlib==3.7.1
    - seaborn==0.12.2
Boas Práticas
Sempre especifique versões exatas em produção

Teste seu requirements.txt em ambiente limpo:

bash
python -m venv test_env
source test_env/bin/activate
pip install -r requirements.txt
python meu_script.py
Atualize pacotes regularmente com:

bash
pip list --outdated
pip install --upgrade pacote
Parte 2: Modelos Ollama - Poder da IA Local 🤖
2.1 Instalação e Configuração
bash
# Baixe o Ollama: https://ollama.com/download
# Verifique instalação
ollama --version

# Servir em porta alternativa (útil para múltiplas instâncias)
ollama serve --port 11435 &
2.2 Modelos de Chat (Conversação)
Tabela Completa de Modelos
Modelo	Parâmetros	Empresa	Casos de Uso	Comando Pull	Exemplo de Uso
llama3:8b	8B	Meta	Chat geral	ollama pull llama3:8b	ollama run llama3:8b "Explique teoria quântica em termos simples"
llama3.1:8b	8B	Meta	Diálogos complexos	ollama pull llama3.1:8b	ollama run llama3.1:8b "Crie uma história sobre exploração espacial"
phi3	3.8B	Microsoft	Raciocínio lógico	ollama pull phi3	ollama run phi3 "Resolva: Se A é irmão de B, e B é mãe de C, qual relação entre A e C?"
mistral	7B	Mistral AI	Respostas rápidas	ollama pull mistral	ollama run mistral "Traduza este texto técnico para francês: ..."
deepseek-chat	16B	DeepSeek	Assistência técnica	ollama pull deepseek-chat	ollama run deepseek-chat "Explique o algoritmo de Dijkstra com exemplos"
gemma2:9b	9B	Google	Conversas multi-turno	ollama pull gemma2:9b	ollama run gemma2:9b "Converse sobre as últimas inovações em IA"
qwen3	14B	Alibaba	Q&A longo	ollama pull qwen3	ollama run qwen3 "Resuma este artigo científico sobre CRISPR: ..."
llama2	7B	Meta	NLP tradicional	ollama pull llama2	ollama run llama2 "Gere ideias para um app de sustentabilidade"
vicuna-13b	13B	LMSys	Diálogo natural	ollama pull vicuna-13b	ollama run vicuna-13b "Simule uma entrevista com Einstein"
chatglm-6b	6B	THUDM	Chat em chinês/inglês	ollama pull chatglm-6b	ollama run chatglm-6b "Traduza e explique este provérbio chinês"
2.3 Modelos de Codificação
Tabela Detalhada
Modelo	Linguagens	Casos de Uso	Comando Pull	Exemplo de Uso
deepseek-coder-v2:16b	30+	Debug, autocompletar	ollama pull deepseek-coder-v2:16b	ollama run deepseek-coder-v2:16b "Otimize esta função Python para grande volume de dados: [código]"
starcoder2:7b	80+	Sugestões avançadas	ollama pull starcoder2:7b	ollama run starcoder2:7b "Complete este código React: function Component() {"
codellama-34b	Python/JS	Refatoração	ollama pull codellama-34b	ollama run codellama-34b "Refatore este código para usar padrão Observer: [código]"
qwen2.5-coder:1.5b	Python	Autocomplete rápido	ollama pull qwen2.5-coder:1.5b	ollama run qwen2.5-coder:1.5b "Sugira código para conectar ao PostgreSQL"
mpt-30b-code	20+	Geração complexa	ollama pull mpt-30b-code	ollama run mpt-30b-code "Gere um microserviço em Go para processamento de pagamentos"
2.4 Modelos Multimodais (Imagem + Texto)
Modelo	Recursos	Casos de Uso	Comando Pull	Exemplo de Uso
llava	Imagens	Análise visual	ollama pull llava	ollama run llava "Descreva esta imagem: diagrama_arquitetura.png"
codegemma	Código + Imagens	Diagramas técnicos	ollama pull codegemma	ollama run codegemma "Explique este diagrama de sequência UML: imagem.png"
qwen2-vl	Multimodal avançado	Visão computacional	ollama pull qwen2-vl	ollama run qwen2-vl "Analise esta imagem médica: raio_x.jpg"
deepseek-vision	Visão computacional	Análise técnica	ollama pull deepseek-vision	ollama run deepseek-vision "Identifique componentes nesta placa de circuito: circuito.jpg"
2.5 Modelos de Embeddings
Modelo	Dimensões	Casos de Uso	Comando Pull	Exemplo de Uso Python
nomic-embed-text	768	Busca semântica	ollama pull nomic-embed-text	embeddings('nomic-embed-text', 'texto para vetorizar')
text-embedding-3-large	3072	NLP avançado	ollama pull text-embedding-3-large	embeddings('text-embedding-3-large', 'documento longo')
gemma-embed	1024	Embeddings eficientes	ollama pull gemma-embed	embeddings('gemma-embed', 'consultas de busca')
mistral-embed	4096	Clusterização	ollama pull mistral-embed	embeddings('mistral-embed', 'dados para agrupamento')
2.6 Uso Avançado de Modelos
Conversa Persistente
bash
ollama run llama3:8b
>>> Como funciona a blockchain?
>>> Agora explique como se eu tivesse 10 anos
>>> Quais as aplicações práticas?
Gerando Código com Contexto
bash
ollama run deepseek-coder-v2:16b '''
Dado este esquema de banco de dados:

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE
);

Escreva uma função Python usando SQLAlchemy para:
1. Adicionar novo usuário
2. Validar email único
3. Retornar ID do usuário criado
'''
Análise de Imagem Técnica
bash
ollama run llava '''
Analise este diagrama de arquitetura: arquitetura.png

1. Identifique os componentes principais
2. Explique o fluxo de dados
3. Sugira melhorias de performance
'''
API Python para Ollama
python
from ollama import Client

client = Client(host='http://localhost:11434')
response = client.chat(
    model='llama3:8b',
    messages=[{'role': 'user', 'content': 'Explite Física Quântica simplificada'}]
)
print(response['message']['content'])
Parte 3: Configuração Profissional no VSCode 🛠️
3.1 Instalação da Extensão Continue
Abra o VSCode

Vá para Extensions (Ctrl+Shift+X)

Busque por "Continue" e instale

3.2 Configuração Completa (.continue/config.json)
json
{
  "version": "2.0.0",
  "models": [
    {
      "name": "Assistente Principal",
      "provider": "ollama",
      "model": "llama3.1:8b",
      "roles": ["chat", "edit"],
      "defaultCompletionOptions": {
        "temperature": 0.7,
        "maxTokens": 4096
      }
    },
    {
      "name": "Especialista em Código",
      "provider": "ollama",
      "model": "deepseek-coder-v2:16b",
      "roles": ["edit", "review"],
      "defaultCompletionOptions": {
        "temperature": 0.3,
        "maxTokens": 8192
      }
    },
    {
      "name": "Assistente Visual",
      "provider": "ollama",
      "model": "llava",
      "capabilities": ["image_input"],
      "roles": ["chat"]
    }
  ],
  "context": [
    {
      "provider": "codebase",
      "params": {
        "nRetrieve": 30,
        "nFinal": 10
      }
    },
    {"provider": "file"},
    {"provider": "terminal"},
    {"provider": "problems"}
  ],
  "rules": [
    {
      "name": "Padrão de Código",
      "rule": "Sempre siga PEP 8 para Python e Airbnb Style Guide para JavaScript/TypeScript"
    },
    {
      "name": "Segurança",
      "rule": "Verifique vulnerabilidades comuns: SQL injection, XSS, hardcoded secrets"
    }
  ],
  "prompts": [
    {
      "name": "revisao-completa",
      "description": "Revisão detalhada de código",
      "prompt": "Analise o código selecionado considerando:\n1. Qualidade (legibilidade, complexidade ciclomática)\n2. Segurança (OWASP Top 10)\n3. Performance (complexidade algorítmica, operações I/O)\n4. Sugira melhorias com exemplos de código"
    },
    {
      "name": "documentar-api",
      "description": "Gerar documentação Swagger",
      "prompt": "Gere documentação OpenAPI 3.0 para o endpoint selecionado incluindo:\n- Descrição da operação\n- Parâmetros (path, query, body)\n- Responses (sucesso/erro)\n- Exemplos de requisição/resposta"
    }
  ],
  "docs": [
    {
      "name": "Python Official",
      "startUrl": "https://docs.python.org/3/"
    },
    {
      "name": "MDN Web Docs",
      "startUrl": "https://developer.mozilla.org/en-US/"
    },
    {
      "name": "OpenAPI Specification",
      "startUrl": "https://spec.openapis.org/oas/v3.1.0"
    }
  ]
}
3.3 Explicação Detalhada da Configuração
Seção Models
name: Nome amigável para referência

provider: "ollama" para modelos locais

model: Nome exato do modelo no Ollama

roles:

chat: Conversa geral

edit: Edição de código

review: Revisão de código

apply: Aplicação automática de mudanças

defaultCompletionOptions:

temperature: Controle de criatividade (0 = preciso, 1 = criativo)

maxTokens: Tamanho máximo da resposta

Seção Context
codebase: Acesso ao código do projeto

file: Conteúdo do arquivo atual

terminal: Saída do terminal

problems: Problemas identificados pelo VSCode

Seção Rules
Regras globais que o assistente segue:

json
{
  "name": "Padrão TypeScript",
  "rule": "Sempre use tipagem forte, evite 'any', prefira interfaces sobre tipos"
}
Seção Prompts
Prompts personalizados para tarefas recorrentes:

json
{
  "name": "gerar-testes",
  "prompt": "Gere testes unitários para a função selecionada usando pytest:\n1. Cubra casos normais e extremos\n2. Use mocks para dependências externas\n3. Inclua testes de falha esperada"
}
3.4 Fluxo de Trabalho no VSCode
Abra o painel Continue (Ctrl+Shift+P > "Continue")

Selecione um prompt personalizado

Interaja via chat:

text
/review Revisar segurança deste trecho
Use comandos rápidos:

/edit Refatorar para usar async/await

/test Gerar testes unitários

Parte 4: Fluxos de Trabalho Profissionais 🚀
4.1 Fluxo de Desenvolvimento com IA
Diagram
Code
graph TD
    A[Criar Ambiente] --> B[Instalar Dependências]
    B --> C[Desenvolver com Assistente]
    C --> D[Testar e Validar]
    D --> E[Documentar]
    E --> F[Congelar Dependências]
    F --> G[Compartilhar Projeto]
4.2 Exemplo Completo: Projeto de Análise de Dados
bash
# Criar ambiente
python -m venv analise_dados_env
source analise_dados_env/bin/activate

# Instalar dependências
pip install pandas numpy matplotlib scikit-learn

# Baixar modelos Ollama
ollama pull llama3:8b
ollama pull deepseek-coder-v2:16b

# Iniciar VSCode
code .

# No VSCode:
# 1. Configurar Continue com o arquivo acima
# 2. Abrir script Python
# 3. Usar prompt: "/review Revisar qualidade e performance"
4.3 Boas Práticas Essenciais
Para Ambientes Virtuais:

✅ Sempre crie ambiente com nome descritivo (projeto_analise_env)

✅ Documente dependências com versões exatas

✅ Teste em ambiente limpo antes de compartilhar

❌ Nunca instale pacotes globalmente

Para Modelos Ollama:

✅ Comece com modelos menores (7B-13B) para testes

✅ Use modelos especializados por tarefa (código, chat, visão)

✅ Ajuste temperatura conforme necessidade:

0.2-0.4: Tarefas técnicas

0.5-0.7: Brainstorming criativo

❌ Não confie cegamente em saídas de código - sempre valide

Para VSCode/Continue:

✅ Configure prompts personalizados para tarefas recorrentes

✅ Use regras de contexto para manter padrões

✅ Atualize documentação técnica regularmente

4.4 Solução de Problemas Detalhada
Problema: Ambiente não ativa no PowerShell

powershell
# Passo 1: Permitir scripts
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Passo 2: Executar script de ativação
.\.venv\Scripts\Activate.ps1

# Se falhar: Recriar ambiente
python -m venv .venv --clear
Problema: Modelo não responde como esperado

bash
# Verificar versão do modelo
ollama list

# Experimentar diferentes parâmetros:
ollama run model --temperature 0.3 --max-tokens 512

# Se problema persistir:
ollama rm model
ollama pull model
Problema: Continue não reconhece contexto

Verifique permissões do VSCode

Atualize configuração de contexto:

json
"context": [
  {
    "provider": "codebase",
    "params": {
      "nRetrieve": 50,
      "nFinal": 15
    }
  }
]
Conclusão: Seu Novo Fluxo de Trabalho
Dominando estas ferramentas, você poderá:

Isolar projetos com ambientes virtuais seguros

Acelerar desenvolvimento com IA especializada

Manter padrões de qualidade com revisão automatizada

Documentar profissionalmente com prompts específicos

Exemplo Final Integrado:

bash
# Criar ambiente para novo projeto
python -m venv fintech_env
source fintech_env/bin/activate

# Instalar dependências
pip install pandas numpy fastapi uvicorn

# Baixar modelos Ollama essenciais
ollama pull deepseek-coder-v2:16b
ollama pull llama3:8b

# Iniciar VSCode com Continue
code .

# Durante desenvolvimento:
# 1. Usar /review para análise de código
# 2. Consultar modelo com /ask "Como implementar autenticação JWT?"
# 3. Gerar documentação com prompt personalizado
Este guia completo oferece desde os fundamentos até técnicas avançadas, transformando você em um desenvolvedor mais produtivo e eficiente! 🚀
