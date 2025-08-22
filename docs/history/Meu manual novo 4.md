🐍 Guia Definitivo de Ambientes Virtuais Python e Modelos Ollama
🌟 Índice Geral
Ambientes Virtuais Python

Conceitos Fundamentais

Configuração com venv

Configuração com conda

Integração com Spyder

Gerenciamento de Dependências

Fluxos de Trabalho

Modelos Ollama

Modelos de Chat

Modelos Multimodais

Modelos de Codificação

Modelos de Embeddings

Configuração Avançada

🐍 Ambientes Virtuais Python
📚 Conceitos Fundamentais
Por que usar ambientes virtuais?

Isolamento completo: Cada projeto tem suas próprias versões de bibliotecas

Reprodutibilidade: Facilita a replicação exata do ambiente em qualquer máquina

Prevenção de conflitos: Elimina problemas como:

"Projeto X precisa do pandas 1.5 enquanto o Projeto Y precisa do pandas 2.0"

Comparativo das Ferramentas:

Ferramenta	Vantagens	Melhor para	Tamanho
venv	Nativo do Python, leve e simples	Projetos Python puros, desenvolvimento geral	~20MB
conda	Suporte multiplataforma e multi-linguagem	Ciência de dados, machine learning	~500MB (Miniconda)
🛠️ Ambiente Virtual com venv
1. Instalação e Configuração Inicial
bash
# Verificar instalação do Python
python --version
# Se não instalado: https://www.python.org/downloads/
# Marcar "Add Python to PATH" durante a instalação
2. Criação do Ambiente
bash
# Windows
py -3.11 -m venv meu_ambiente

# Linux/macOS
python3.11 -m venv meu_ambiente
3. Ativação/Desativação
Windows:

cmd
:: Command Prompt
meu_ambiente\Scripts\activate.bat

:: PowerShell
& "meu_ambiente\Scripts\Activate.ps1"

:: Desativar
deactivate
Linux/macOS:

bash
source meu_ambiente/bin/activate
deactivate
4. Gerenciamento de Pacotes
bash
# Instalar pacotes
pip install pandas matplotlib

# Listar pacotes
pip list

# Gerar requirements.txt
pip freeze > requirements.txt

# Instalar de requirements.txt
pip install -r requirements.txt
🐍 Ambiente Virtual com conda
1. Instalação
Anaconda Distribution (completo)

Miniconda (versão minimalista)

2. Criação de Ambientes
bash
# Ambiente básico
conda create --name meu_ambiente python=3.11

# Ambiente com pacotes específicos
conda create --name ds_env python=3.9 numpy pandas scikit-learn
3. Gerenciamento
bash
# Ativar/desativar
conda activate meu_ambiente
conda deactivate

# Listar ambientes
conda env list

# Remover ambiente
conda remove --name meu_ambiente --all

# Exportar ambiente
conda env export > environment.yml
🔌 Integração com Spyder
1. Usando venv no Spyder
bash
pip install spyder-kernels
Configuração:

Ative o ambiente virtual

No Spyder: Ferramentas > Preferências > Interpretador Python

Aponte para: caminho/do/ambiente/Scripts/python.exe

2. Usando conda no Spyder
bash
conda install spyder
spyder
3. Configuração de Kernels Jupyter
bash
# Para venv
pip install ipykernel
python -m ipykernel install --user --name=meu_ambiente --display-name "Python (meu_ambiente)"

# Para conda
conda install ipykernel
python -m ipykernel install --user --name=conda_env --display-name "Python (conda_env)"
📦 Gerenciamento Avançado de Dependências
Arquivo requirements.txt (venv)
txt
pandas==1.5.3
matplotlib>=3.5.0
scikit-learn
Arquivo environment.yml (conda)
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
Comandos Úteis:
bash
# Verificar dependências desatualizadas
pip list --outdated

# Atualizar pacotes
pip install --upgrade pacote
🧠 Modelos Ollama
📊 Tabela Comparativa de Modelos
Modelos de Chat
Modelo	Parâmetros	Empresa	Uso Principal	Comando Pull
llama3:8b	8B	Meta	Chat geral	ollama pull llama3:8b
phi3	3.8B	Microsoft	Raciocínio lógico	ollama pull phi3
deepseek-chat	16B	DeepSeek	Assistência técnica	ollama pull deepseek-chat
Modelos Multimodais
Modelo	Capacidade	Comando Pull
llava	Texto + Imagem	ollama pull llava
codegemma	Código + Visual	ollama pull codegemma
Modelos de Codificação
Modelo	Linguagens	Comando Pull
starcoder2:7b	Multi-linguagem	ollama pull starcoder2:7b
deepseek-coder	Python/JS/TS	ollama pull deepseek-coder
⚙️ Configuração para VSCode
yaml
# continue_config.yml
models:
  - name: Assistente de Código
    provider: ollama
    model: deepseek-coder-v2:16b
    roles: [chat, edit]
    temperature: 0.3
    maxTokens: 8192
🎯 Fluxos de Trabalho Recomendados
Desenvolvimento Python:

bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
Ciência de Dados:

bash
conda create --name ds_env python=3.10 pandas numpy matplotlib
conda activate ds_env
Uso com Ollama:

bash
ollama pull llama3:8b
ollama run llama3:8b --prompt "Explique Python para iniciantes"
🔍 Solução de Problemas Comuns
Erros de Ativação
Problema: Scripts não executam no PowerShell
Solução:

powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
Conflitos de Versões
Solução:

Crie novo ambiente limpo

Instale dependências uma por uma para identificar conflitos

Verificação de Ambiente
python
import sys
print(sys.executable)  # Deve mostrar o caminho do ambiente correto
📌 Conclusão
Este guia unificado cobre:

✅ Configuração completa de ambientes Python (venv/conda)

✅ Integração com IDEs como Spyder e VSCode

✅ Gerenciamento profissional de dependências

✅ Utilização avançada dos modelos Ollama

✅ Solução de problemas comuns

Próximos Passos:

Escolha o ambiente virtual conforme seu projeto

Configure seu editor preferido

Utilize os modelos Ollama para produtividade máxima

bash
# Exemplo completo de fluxo
python -m venv meu_projeto
source meu_projeto/bin/activate
pip install pandas matplotlib
ollama pull deepseek-coder
ollama run deepseek-coder
