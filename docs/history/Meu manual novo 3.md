🚀 Guia Definitivo: Ambientes Virtuais Python e Modelos Ollama
Introdução: Por que Ambientes Virtuais e Modelos de IA?
Ambientes virtuais e modelos de linguagem são ferramentas essenciais para desenvolvedores modernos. Vamos explorar:

Ambientes Virtuais: Isolam dependências por projeto, evitando conflitos de versões

Modelos Ollama: Executam modelos de IA localmente para programação assistida

Parte 1: Ambientes Virtuais Python 🐍
1.1 Conceitos Fundamentais
Problema:

"Projeto A precisa do pandas 1.5, Projeto B precisa do pandas 2.0"

Solução: Ambientes virtuais criam "caixas isoladas" para cada projeto

Ferramentas:

Diagram
Code
graph LR
    A[Ambientes Virtuais] --> B[venv]
    A --> C[conda]
    B --> D[Nativo do Python]
    C --> E[Ideal para ciência de dados]
1.2 Venv - Passo a Passo
Instalação e Configuração
bash
# Verificar instalação do Python
python --version

# Se não instalado: https://www.python.org/downloads/
# Marque 'Add Python to PATH' durante a instalação!
Criando e Ativando Ambientes
bash
# Criar ambiente (Windows/Linux/macOS)
python -m venv meu_ambiente

# Ativar (Windows CMD)
meu_ambiente\Scripts\activate.bat

# Ativar (Windows PowerShell)
& "meu_ambiente\Scripts\Activate.ps1"

# Ativar (Linux/macOS)
source meu_ambiente/bin/activate

# Desativar (todos os sistemas)
deactivate
Gerenciamento de Pacotes
bash
# Instalar pacotes
pip install pandas matplotlib

# Listar pacotes instalados
pip list

# Gerar requirements.txt
pip freeze > requirements.txt

# Instalar de requirements.txt
pip install -r requirements.txt
1.3 Conda - Passo a Passo
Instalação
Miniconda (leve)

Anaconda (completo)

Comandos Essenciais
bash
# Criar ambiente
conda create --name meu_ambiente python=3.11

# Ativar
conda activate meu_ambiente

# Instalar pacotes
conda install numpy pandas

# Listar ambientes
conda env list

# Exportar ambiente
conda env export > environment.yml

# Criar de environment.yml
conda env create -f environment.yml

# Remover ambiente
conda remove --name meu_ambiente --all
1.4 Integração com Ferramentas
Spyder
bash
# Com venv
pip install spyder-kernels
# Configurar: Ferramentas > Preferências > Interpretador Python

# Com conda
conda install spyder
spyder
Jupyter Notebooks
bash
# Registrar kernel
pip install ipykernel
python -m ipykernel install --user --name=meu_ambiente
1.5 Gerenciamento Avançado de Dependências
Arquivo requirements.txt
txt
pandas==1.5.3
matplotlib>=3.5.0
scikit-learn
Arquivo environment.yml
yaml
name: meu_ambiente
channels:
  - defaults
dependencies:
  - python=3.11
  - numpy=1.21
  - pip
  - pip:
    - matplotlib
Boas Práticas
Sempre especifique versões exatas em produção

Atualize pacotes regularmente:

bash
pip list --outdated
pip install --upgrade pacote
Documente dependências opcionais separadamente

Parte 2: Modelos Ollama 🤖
2.1 Instalação e Configuração
bash
# Baixar Ollama: https://ollama.com/download
# Verificar instalação
ollama --version

# Servir em porta alternativa
ollama serve --port 11435
2.2 Modelos de Chat (Conversação)
Modelo	Parâmetros	Empresa	Casos de Uso	Comando Pull
llama3:8b	8B	Meta	Chat geral	ollama pull llama3:8b
phi3	3.8B	Microsoft	Raciocínio lógico	ollama pull phi3
mistral	7B	Mistral AI	Respostas rápidas	ollama pull mistral
deepseek-chat	16B	DeepSeek	Assistência técnica	ollama pull deepseek-chat
Exemplo de uso:

bash
ollama run llama3:8b "Explique teoria quântica para iniciantes"
2.3 Modelos de Codificação
Modelo	Linguagens	Casos de Uso	Comando Pull
deepseek-coder	30+	Autocompletar, debug	ollama pull deepseek-coder
starcoder2:7b	80+	Sugestões avançadas	ollama pull starcoder2:7b
codellama-34b	Python/JS	Refatoração	ollama pull codellama-34b
Exemplo:

bash
ollama run deepseek-coder "Como otimizar esta função Python?"
2.4 Modelos Multimodais (Texto + Imagem)
Modelo	Recursos	Casos de Uso	Comando Pull
llava	Imagens	Análise visual	ollama pull llava
codegemma	Código + Imagens	Diagramas técnicos	ollama pull codegemma
Uso:

bash
ollama run llava "Descreva esta imagem: diagrama.png"
2.5 Modelos de Embeddings
Modelo	Dimensões	Casos de Uso	Comando Pull
nomic-embed-text	768	Busca semântica	ollama pull nomic-embed-text
text-embedding-3-large	3072	NLP avançado	ollama pull text-embedding-3-large
Aplicação:

python
from ollama import embeddings

result = embeddings('nomic-embed-text', 'Texto para vetorizar')
print(result['embedding'])
2.6 Configuração para VSCode (Extensão Continue)
yaml
# .continue/config.yml
version: 2.0.0
models:
  - name: Assistente de Código
    provider: ollama
    model: deepseek-coder-v2:16b
    roles: [chat, edit]
    temperature: 0.3
    maxTokens: 8192

context:
  - provider: codebase
    params: {nRetrieve: 25}

prompts:
  - name: revisar-codigo
    prompt: |
      Analise o código selecionado com foco em:
      1. Qualidade (sintaxe, legibilidade)
      2. Segurança (vulnerabilidades)
      3. Performance (gargalos)
      4. Sugestões (código + prioridade)
Parte 3: Fluxos de Trabalho Integrados 🔄
3.1 Desenvolvimento Python com IA
bash
# Criar ambiente
python -m venv .venv
source .venv/bin/activate

# Instalar dependências
pip install pandas numpy

# Consultar IA
ollama run deepseek-coder "Como otimizar leitura de CSV grande com pandas?"
3.2 Documentação Técnica Automatizada
bash
# Gerar documentação de função
ollama run codellama-34b '''
Documente esta função:

def calcular_imposto(valor, taxa):
    return valor * (taxa / 100)
'''
3.3 Análise de Código com Prompts Especializados
yaml
# Continue VSCode prompt
- name: analise-seguranca
  prompt: |
    Verifique vulnerabilidades no código:
    - SQL Injection
    - XSS
    - Injeção de comandos
    Sugira correções com exemplos
Parte 4: Solução de Problemas 🛠️
4.1 Problemas Comuns com Ambientes
Problema: Scripts não executam no PowerShell
Solução:

powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
Problema: Pacotes não encontrados após ativação
Solução:

bash
# Verificar caminho do Python
which python  # Linux/macOS
where python  # Windows

# Recriar ambiente
python -m venv --clear .venv
4.2 Problemas com Ollama
Problema: Modelo não responde
Solução:

bash
# Verificar serviço
ollama list

# Reiniciar serviço
ollama serve --port 11435 &

# Verificar logs
ollama logs
Problema: Baixa performance
Solução:

Use modelos menores (7B em vez de 34B)

Ajuste parâmetros:

yaml
defaultCompletionOptions:
  temperature: 0.3  # Menos criativo
  maxTokens: 512    # Respostas mais curtas
Parte 5: Melhores Práticas e Conclusão 🏆
5.1 Checklist de Boas Práticas
Ambientes Virtuais:

Sempre criar ambiente por projeto

Documentar dependências (requirements.txt/environment.yml)

Ativar ambiente antes de trabalhar

Testar em ambiente limpo antes de deploy

Modelos Ollama:

Escolher modelo especializado por tarefa

Ajustar temperatura para criatividade vs precisão

Usar prompts específicos para melhores resultados

Validar saídas da IA criticamente

5.2 Fluxo de Trabalho Completo
Diagram
Code
graph TD
    A[Criar Ambiente] --> B[Instalar Dependências]
    B --> C[Desenvolver com IA Assistida]
    C --> D[Testar e Validar]
    D --> E[Documentar]
    E --> F[Congelar Dependências]
    F --> G[Compartilhar Projeto]
5.3 Recursos para Aprofundamento
Documentação Python

Repositório Ollama

Biblioteca de Modelos

Continue VSCode Docs

bash
# Exemplo Final Integrado
python -m venv .venv
source .venv/bin/activate
pip install pandas
ollama pull deepseek-coder
ollama run deepseek-coder "Como criar um DataFrame pandas a partir de dicionário?"
Este guia completo cobre desde os fundamentos até técnicas avançadas, permitindo que você trabalhe com eficiência e aproveite ao máximo as ferramentas modernas de desenvolvimento! 🚀

