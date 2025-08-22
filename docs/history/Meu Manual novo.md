🚀 Guia Completo: Ambientes Python, Ollama, Git e Fluxos Profissionais
Introdução: Ecossistema Completo de Desenvolvimento
Este guia definitivo cobre todo o fluxo de trabalho profissional, desde ambientes isolados até colaboração em equipe. Você aprenderá:

Domínio completo de ambientes virtuais Python

Configuração e uso avançado de modelos Ollama

Integração com Git/GitHub no VSCode e Spyder

Fluxos profissionais com IA assistida

Parte 1: Ambientes Virtuais Python Profissionais 🐍
1.1 Conceitos Fundamentais
Problema real:

"Ao atualizar o pandas para o projeto novo, meu projeto antigo parou de funcionar!"

Solução científica:

Diagram
Code
graph LR
    S[Sistema Operacional] -->|Python Base| A[Ambiente Global]
    A --> B[Projeto 1: pandas 1.5]
    A --> C[Projeto 2: pandas 2.0]
    B & C -->|Conflito!| D[Erro]
    
    S --> V[Ambiente Virtual]
    V --> E[Projeto 1: venv_pandas15]
    V --> F[Projeto 2: venv_pandas20]
    E & F --> G[Funcionamento Perfeito]
1.2 Venv: Configuração Detalhada
Instalação e Verificação
bash
# Verificar versão Python (deve ser 3.3+)
python --version

# Se necessário instalar:
# Windows: https://www.python.org/downloads/
# Linux: sudo apt install python3.11-full

# Criar ambiente (exemplo para projeto financeiro)
python -m venv ~/projetos/financeiro/venv_fin
Ativação/Desativação Avançada
bash
# Ativação Windows (PowerShell - PRIMEIRO HABILITE EXECUÇÃO)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
& "~/projetos/financeiro/venv_fin/Scripts/Activate.ps1"

# Ativação Linux/macOS
source ~/projetos/financeiro/venv_fin/bin/activate

# Desativar (todos os sistemas)
deactivate

# Verificar ambiente ativo (comando mágico!)
python -c "import sys; print(sys.prefix != sys.base_prefix)"
# Saída: True (ambiente ativo) ou False (global)
Gerenciamento de Pacotes Profissional
bash
# Instalar com controle de versão preciso
pip install "django~=4.2.0" "pandas>=1.5,<1.6"

# Gerar requirements.txt com hashes (segurança máxima)
pip freeze --all --local | grep -v '^\-e' | cut -d = -f 1 | xargs pip show | grep -E 'Name:|Version:' | awk '{print $2}' | paste -d "==" - - | awk '{print $1 "==" $2}' > requirements.txt

# Instalar com verificação de integridade
pip install -r requirements.txt --require-hashes
1.3 Conda: Para Projetos Complexos
Instalação Otimizada
bash
# Miniconda (recomendado para maioria dos casos)
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh -b -p $HOME/miniconda
source ~/miniconda/bin/activate
conda init
Criação de Ambientes Especializados
bash
# Ambiente para ciência de dados
conda create --name ds_env python=3.10 numpy=1.23 pandas=1.5 scikit-learn=1.2 jupyterlab

# Ambiente para desenvolvimento web
conda create --name web_env python=3.11 django=4.2 psycopg2=2.9

# Exportar ambiente com canais explícitos
conda env export --from-history > environment.yml
Ativação Avançada
bash
# Ativar ambiente
conda activate ds_env

# Verificar pacotes instalados
conda list

# Adicionar canal confiável
conda config --add channels conda-forge

# Instalar pacote específico de canal
conda install -c plotly plotly=5.15
1.4 Integração com IDEs Profissional
Spyder Configuração Perfeita
python
# Passo 1: No ambiente virtual
pip install spyder-kernels

# Passo 2: Obter caminho do interpretador
python -c "import sys; print(sys.executable)"

# Passo 3: No Spyder
# Ferramentas > Preferências > Interpretador Python
# Colar caminho: /caminho/completo/venv/bin/python

# Passo 4: Reiniciar kernel (Ctrl + .)
VSCode Configuração
json
// .vscode/settings.json
{
    "python.defaultInterpreterPath": "~/projetos/financeiro/venv_fin/bin/python",
    "python.terminal.activateEnvironment": true,
    "python.linting.enabled": true,
    "python.formatting.provider": "black"
}
Parte 2: Modelos Ollama - Guia de Especialista 🤖
2.1 Instalação e Configuração Avançada
bash
# Instalar Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Configurar serviço permanente (Linux)
sudo systemctl enable ollama
sudo systemctl start ollama

# Variáveis de ambiente importantes
export OLLAMA_HOST="0.0.0.0"  # Permitir conexões externas
export OLLAMA_PORT="11435"    # Porta personalizada
2.2 Modelos de Chat - Catálogo Completo
Modelo	Parâmetros	RAM Mínima	Uso Ideal	Comando Pull	Exemplo de Uso
llama3:8b	8B	16GB	Chat geral	ollama pull llama3:8b	ollama run llama3:8b "Explique blockchain como se eu tivesse 15 anos"
llama3.1:8b	8B	16GB	Diálogos complexos	ollama pull llama3.1:8b	ollama run llama3.1:8b "Desenvolva um enredo para um jogo de ficção científica"
phi3	3.8B	8GB	Raciocínio lógico	ollama pull phi3	ollama run phi3 "Se 5 máquinas fazem 5 peças em 5 minutos, quanto tempo levam 100 máquinas?"
mistral	7B	12GB	Respostas rápidas	ollama pull mistral	ollama run mistral "Traduza este contrato legal para linguagem simples: [texto]"
deepseek-chat	16B	32GB	Assistência técnica	ollama pull deepseek-chat	ollama run deepseek-chat "Monte um plano de estudos para aprender Rust em 3 meses"
gemma2:9b	9B	18GB	Conversas multi-turno	ollama pull gemma2:9b	ollama run gemma2:9b "Discuta as implicações éticas da IA generativa na educação"
qwen3	14B	28GB	Q&A longo	ollama pull qwen3	ollama run qwen3 "Resuma este paper acadêmico sobre fusão nuclear: [texto]"
llama2	7B	14GB	NLP tradicional	ollama pull llama2	ollama run llama2 "Gere 10 ideias para um app mobile de sustentabilidade"
vicuna-13b	13B	26GB	Diálogo natural	ollama pull vicuna-13b	ollama run vicuna-13b "Simule uma entrevista com Marie Curie sobre radioatividade"
chatglm-6b	6B	12GB	Multilíngue	ollama pull chatglm-6b	ollama run chatglm-6b "Traduza e explique este provérbio chinês: 塞翁失马"
2.3 Modelos de Codificação - Especializados
Modelo	Linguagens	RAM Mínima	Casos de Uso	Comando Pull	Exemplo
deepseek-coder-v2:16b	30+	32GB	Debug complexo	ollama pull deepseek-coder-v2:16b	ollama run deepseek-coder-v2:16b "Otimize este algoritmo de ordenação para big data: [código]"
starcoder2:7b	80+	14GB	Autocomplete	ollama pull starcoder2:7b	ollama run starcoder2:7b "Complete este componente React com TypeScript: [código parcial]"
codellama-34b	Python/JS	64GB	Refatoração	ollama pull codellama-34b	ollama run codellama-34b "Refatore este código usando padrão Factory Method: [código]"
qwen2.5-coder:1.5b	Python	6GB	Scripts rápidos	ollama pull qwen2.5-coder:1.5b	ollama run qwen2.5-coder:1.5b "Crie um script para converter CSV em Parquet"
2.4 Modelos Multimodais - Visão + Texto
Modelo	RAM Mínima	Casos de Uso	Comando Pull	Exemplo
llava	16GB	Análise de diagramas	ollama pull llava	ollama run llava "Descreva esta arquitetura de microsserviços: diagrama.png"
codegemma	24GB	Diagramas técnicos	ollama pull codegemma	ollama run codegemma "Gere código a partir deste diagrama de classes UML: imagem.jpg"
2.5 Uso Avançado com API Python
python
from ollama import Client
import time

# Configurar cliente
client = Client(host='http://localhost:11434')

# Função para conversa técnica
def consultar_especialista(modelo, pergunta, contexto=None, temperatura=0.3):
    mensagens = [{'role': 'system', 'content': 'Você é um especialista técnico sênior'}]
    
    if contexto:
        mensagens.append({'role': 'user', 'content': contexto})
    
    mensagens.append({'role': 'user', 'content': pergunta})
    
    resposta = client.chat(
        model=modelo,
        messages=mensagens,
        options={
            'temperature': temperatura,
            'num_ctx': 8192  # Tamanho do contexto
        }
    )
    return resposta['message']['content']

# Exemplo de uso
contexto_negocios = "Estamos desenvolvendo um sistema de comércio eletrônico usando Django e React"
pergunta = "Proponha uma arquitetura para o serviço de carrinho de compras"

resposta = consultar_especialista('deepseek-chat', pergunta, contexto_negocios)
print("Resposta Técnica:\n", resposta)
Parte 3: Git e GitHub Profissional 🌐
3.1 Fundamentos do Git
Diagram
Code
graph LR
    W[Workspace] --> I[Index]
    I --> L[Local Repository]
    L --> R[Remote Repository]
    
    W -- add --> I
    I -- commit --> L
    L -- push --> R
    R -- pull --> W
3.2 Configuração Inicial Essencial
bash
# Identidade global
git config --global user.name "Seu Nome"
git config --global user.email "seu@email.com"

# Editor preferido
git config --global core.editor "code --wait"

# Configurações avançadas
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global alias.graph "log --all --graph --decorate --oneline"
3.3 Fluxo de Trabalho Diário
Comandos Essenciais
bash
# Iniciar repositório
git init
git remote add origin https://github.com/usuario/repositorio.git

# Ciclo básico
git add .                          # Adicionar alterações
git commit -m "Implementa login"   # Commitar
git pull --rebase origin main      # Atualizar com rebase
git push origin main               # Enviar alterações

# Resolver conflitos
git status                         # Verificar estado
# Editar arquivos com conflitos
git add arquivo_resolvido.py
git rebase --continue
Fluxo de Trabalho Profissional
bash
# Trabalhar em nova feature
git checkout -b feature/novo-modulo

# Desenvolver...
git add .
git commit -m "Implementa funcionalidade X"

# Atualizar com a main
git fetch origin
git rebase origin/main

# Resolver conflitos se necessário
# Enviar para revisão
git push -u origin feature/novo-modulo
3.4 Integração com VSCode
Painel Git:

Visualizar mudanças (Ctrl+Shift+G)

Commit direto da interface

Resolução de conflitos visual

Extensões Essenciais:

GitLens: Histórico detalhado

GitHub Pull Requests: Gerencia PRs direto do IDE

Comandos Rápidos:

Ctrl+Shift+P > Git: Commit (Commite tudo)

Ctrl+Shift+P > Git: Push (Envia para remoto)

3.5 Integração com Spyder
Habilitar integração:

python
# No console Spyder
%load_ext spyder_autopep8
%load_ext spyder_git
Painel Git:

Acessar via View > Panes > Git

Commit visual com mensagens

Diff integrado

Fluxo:

python
# 1. Desenvolver código
# 2. Ver mudanças no painel Git
# 3. Selecionar arquivos para commit
# 4. Escrever mensagem e commitar
# 5. Sincronizar com remoto
3.6 Boas Práticas de Commit
bash
# Estrutura de mensagem:
<tipo>(<escopo>): <descrição breve>

[corpo detalhado]

[rodapé com referências]

# Exemplo:
feat(autenticação): implementa login via OAuth2

- Adiciona suporte a Google e GitHub OAuth
- Implementa sistema de tokens JWT
- Atualiza documentação de autenticação

Ref: #123, #456
Tipos Comuns:

feat: Nova funcionalidade

fix: Correção de bug

docs: Alterações na documentação

refactor: Refatoração de código

test: Adição/atualização de testes

Parte 4: Configuração VSCode com Continue 🛠️
4.1 Instalação e Configuração Base
Instalar extensão "Continue"

Criar arquivo .continue/config.json na raiz do projeto

4.2 Configuração Avançada
json
{
  "version": "2.0.0",
  "models": [
    {
      "title": "Assistente Principal",
      "provider": "ollama",
      "model": "llama3.1:8b",
      "apiBase": "http://localhost:11434",
      "contextLength": 8192,
      "completionOptions": {
        "temperature": 0.4,
        "maxTokens": 2000,
        "topP": 0.95,
        "frequencyPenalty": 0.9
      }
    },
    {
      "title": "Especialista em Código",
      "provider": "ollama",
      "model": "deepseek-coder-v2:16b",
      "apiBase": "http://localhost:11434",
      "contextLength": 16384,
      "roles": ["code"]
    }
  ],
  "contextProviders": [
    {
      "name": "codebase",
      "config": {
        "indexingLimit": 10000,
        "retrievalLimit": 20
      }
    },
    {
      "name": "open-files"
    },
    {
      "name": "terminal"
    }
  ],
  "customCommands": [
    {
      "name": "revisar-codigo",
      "prompt": "Analise o código selecionado considerando:\n1. Qualidade (PEP 8, complexidade)\n2. Segurança (OWASP Top 10)\n3. Performance (Big O, operações I/O)\n4. Sugira melhorias com exemplos",
      "description": "Revisão técnica completa"
    },
    {
      "name": "gerar-testes",
      "prompt": "Gere testes unitários para a função selecionada usando pytest:\n- Cubra casos normais e extremos\n- Use mocks para dependências\n- Inclua testes de falha",
      "description": "Cria suite de testes"
    }
  ],
  "slashCommands": [
    {
      "name": "documentar",
      "description": "Gerar documentação para código",
      "prompt": "Gere documentação no formato Google Docstrings para o código selecionado"
    }
  ]
}
4.3 Fluxo de Trabalho com IA
Abrir arquivo de código

Selecionar trecho para análise

Acionar comando:

bash
/revisar-codigo
Analisar sugestões

Aplicar melhorias com:

bash
/documentar  # Para documentação automática
Parte 5: Fluxos de Trabalho Integrados 🔄
5.1 Exemplo: Projeto de Análise de Dados
Diagram
Code
graph TD
    A[Criar Ambiente] --> B[Configurar Git]
    B --> C[Desenvolver com IA]
    C --> D[Testar e Validar]
    D --> E[Documentar]
    E --> F[Compartilhar]
    
    A -->|venv| A1[python -m venv analise_dados]
    B -->|Repositório| B1[git init; git remote add origin ...]
    C -->|VSCode+Ollama| C1[Código assistido por IA]
    D -->|pytest| D1[Testes automatizados]
    E -->|Sphinx| E1[Documentação técnica]
    F -->|GitHub| F1[Pull Request]
5.2 Comandos para Todo o Fluxo
bash
# 1. Configuração inicial
python -m venv analise_dados_env
source analise_dados_env/bin/activate
pip install pandas numpy matplotlib jupyter scikit-learn
git init
git remote add origin https://github.com/seuuser/projeto-analise.git

# 2. Desenvolvimento com IA
ollama pull deepseek-coder-v2:16b
code .  # Abrir VSCode com Continue configurado

# 3. Desenvolver no Jupyter Notebook com ambiente virtual
python -m ipykernel install --user --name=analise_dados_env
jupyter notebook

# 4. Testes
pip install pytest
# Criar tests/test_data.py
pytest -v

# 5. Documentação
pip install sphinx
sphinx-quickstart docs

# 6. Versionamento
git add .
git commit -m "feat(analise): implementa pipeline de dados"
git push -u origin main
5.3 Solução de Problemas Comuns
Problema: Conflito entre ambientes no Jupyter

bash
# Listar kernels
jupyter kernelspec list

# Remover kernel antigo
jupyter kernelspec uninstall nome_problema

# Registrar novamente
python -m ipykernel install --user --name=novo_nome
Problema: Modelo Ollama não responde

bash
# Verificar serviço
ollama list

# Testar conexão
curl http://localhost:11434/api/tags

# Reiniciar serviço
sudo systemctl restart ollama

# Ver logs detalhados
journalctl -u ollama -n 100 -f
Conclusão: Seu Novo Padrão Profissional
Você agora domina:

Ambientes Isolados: Venv e Conda para qualquer projeto

IA Assistida: Ollama integrado ao fluxo de desenvolvimento

Controle de Versão: Git/GitHub profissional no VSCode e Spyder

Fluxos Automatizados: Desenvolvimento eficiente com Continue

Checklist Final:

Sempre comece com ambiente virtual

Documente cada etapa com commits significativos

Use modelos especializados para cada tarefa

Valide saídas de IA criticamente

Automatize testes e documentação

bash
# Comando para iniciar qualquer projeto:
new-project() {
    # Cria ambiente e repositório
    python -m venv .venv
    source .venv/bin/activate
    git init
    git branch -M main
    
    # Configurações iniciais
    pip install black isort pytest
    ollama pull deepseek-coder-v2:16b
    
    echo "Projeto $1 configurado profissionalmente!"
}
Este guia é sua referência completa para desenvolvimento profissional com Python - mantenha-o sempre à mão! 🚀
