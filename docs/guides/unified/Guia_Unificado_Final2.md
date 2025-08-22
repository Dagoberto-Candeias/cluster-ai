# Guia Profissional — Ambientes Virtuais Python & Ollama (Versão Melhorada)

> Versão refinada e consolidada dos seus arquivos. Organização, exemplos práticos, scripts e checklist para usar em projetos profissionais.

---

## Índice

1. Introdução
2. Rápido — Comandos essenciais
3. Ambientes Virtuais Python
   - Conceito e por que usar
   - `venv` (passo a passo)
   - `conda` (passo a passo)
   - Gerenciamento de dependências (requirements.yml / environment.yml)
   - Integração com IDEs (VSCode, Spyder, Jupyter)
   - Script de automação sugerido
4. Ollama — Instalação, modelos e uso prático
   - Instalação e verificação
   - Comandos básicos (pull, run, serve, list)
   - Modelos recomendados por caso de uso
   - Exemplos práticos (terminal e Python)
5. Integração Ollama + VSCode (Continue)
   - Arquivo de configuração de exemplo
   - Prompts úteis para revisão de código e documentação
6. Fluxos de trabalho recomendados
   - Desenvolvimento com IA (exemplo completo)
   - Ciência de dados / experimentação
7. Boas práticas e checklist de produção
8. Resolução de problemas (troubleshooting)
9. Anexos úteis: snippets e templates
   - requirements.txt exemplo
   - environment.yml exemplo
   - .continue/config.json exemplo
   - Script de setup (bash)

---

## 1. Introdução

Este documento reúne e melhora o conteúdo fornecido: explica conceitos, oferece comandos práticos, inclui templates prontos e um fluxo de trabalho integrado entre ambientes virtuais Python e modelos Ollama (IA local). O objetivo é permitir que você configure, reproduza e compartilhe ambientes de forma segura e profissional.

---

## 2. Rápido — Comandos essenciais

```bash
# criar e ativar venv (Linux / macOS)
python3 -m venv .venv
source .venv/bin/activate

# criar e ativar venv (Windows PowerShell)
py -3 -m venv .venv
& ".venv\Scripts\Activate.ps1"

# conda
conda create --name meu_env python=3.11 -y
conda activate meu_env

# Ollama (exemplos)
ollama --version
ollama pull llama3:8b
ollama run llama3:8b "Explique a diferença entre venv e conda"
```

---

## 3. Ambientes Virtuais Python

### Conceito e por que usar

- Isolamento de dependências por projeto
- Reprodutibilidade entre máquinas
- Evita conflitos de versões

### `venv` — Passo a passo

**Criar ambiente**

```bash
python3 -m venv .venv
```

**Ativar**

- Linux/macOS: `source .venv/bin/activate`
- Windows PowerShell: `& ".venv\Scripts\Activate.ps1"`

**Instalar pacotes**

```bash
pip install -r requirements.txt
```

**Gerar requirements**

```bash
pip freeze > requirements.txt
```

**Dica:** sempre crie `.gitignore` com `.venv/` para não versionar o ambiente.

### `conda` — Passo a passo

**Criar**

```bash
conda create --name ds_env python=3.10 -y
```

**Ativar**

```bash
conda activate ds_env
```

**Exportar**

```bash
conda env export > environment.yml
```

**Criar a partir do YAML**

```bash
conda env create -f environment.yml
```

### Gerenciamento de dependências — padrões

**requirements.txt (pip / venv)**

```text
pandas==1.5.3
numpy>=1.21.0,<1.23.0
uvicorn==0.22.0
fastapi==0.95.0
```

**environment.yml (conda)**

```yaml
name: projeto_analise
channels:
  - conda-forge
dependencies:
  - python=3.10
  - numpy=1.23.5
  - pandas=1.5.3
  - pip:
    - fastapi==0.95.0
    - uvicorn==0.22.0
```

### Integração com IDEs

- **VSCode**: instale Python extension; selecione `Python: Select Interpreter` para apontar para `.venv`.
- **Spyder**: execute `pip install spyder-kernels` no ambiente e selecione o interpretador.
- **Jupyter**: registre o kernel do ambiente
  ```bash
  pip install ipykernel
  python -m ipykernel install --user --name=meu_ambiente --display-name "Python (meu_ambiente)"
  ```

### Script de automação (setup.sh)

```bash
#!/usr/bin/env bash
set -e
PROJECT_DIR=${1:-$(pwd)}
PYTHON_VERSION=${2:-3.11}

python${PYTHON_VERSION%.*} -m venv $PROJECT_DIR/.venv
source $PROJECT_DIR/.venv/bin/activate
pip install --upgrade pip
pip install -r $PROJECT_DIR/requirements.txt || true
```

---

## 4. Ollama — Instalação, modelos e uso prático

### Instalação & verificação

- Baixe e instale a partir de: [https://ollama.com/download](https://ollama.com/download) (siga instruções para seu SO).
- Verifique:

```bash
ollama --version
ollama list
```

### Comandos básicos

```bash
# Baixar (pull) um modelo
ollama pull llama3:8b

# Executar uma query simples
ollama run llama3:8b "Explique programação assíncrona em Python" --temperature 0.2

# Rodar em modo server (útil para integração)
ollama serve --port 11434 &

# Listar modelos instalados
ollama list
```

### Modelos recomendados (por caso de uso)

- **Chat geral**: `llama3:8b`, `llama3.1:8b`
- **Raciocínio**: `phi3`
- **Código / Dev**: `deepseek-coder-v2:16b`, `starcoder2:7b`, `codellama-34b`
- **Visão multimodal**: `llava`, `qwen2-vl`
- **Embeddings**: `nomic-embed-text`, `text-embedding-3-large`

> Escolha modelos menores (7B-13B) para testes e prototipagem; modelos maiores para produção quando hardware permitir.

### Exemplos práticos — Terminal

```bash
ollama run deepseek-coder-v2:16b "Refatore esta função Python para ser mais eficiente: <código>"
```

### Exemplos práticos — Python (cliente)

```python
from ollama import Client
client = Client(host='http://localhost:11434')
resp = client.chat(model='llama3:8b', messages=[{'role':'user','content':'Explique a regresão linear.'}])
print(resp['message']['content'])
```

---

## 5. Integração Ollama + VSCode (Continue)

### Exemplo `.continue/config.json`

```json
{
  "version": "2.0.0",
  "models": [
    {
      "name": "Assistente Principal",
      "provider": "ollama",
      "model": "llama3.1:8b",
      "roles": ["chat", "edit"],
      "defaultCompletionOptions": {"temperature": 0.6, "maxTokens": 4096}
    },
    {
      "name": "Especialista em Código",
      "provider": "ollama",
      "model": "deepseek-coder-v2:16b",
      "roles": ["edit", "review"],
      "defaultCompletionOptions": {"temperature": 0.2, "maxTokens": 8192}
    }
  ],
  "context": [{"provider":"codebase","params":{"nRetrieve":30,"nFinal":10}}, {"provider":"file"}, {"provider":"terminal"}],
  "prompts": [
    {"name":"revisao-completa","description":"Revisão detalhada de código","prompt":"Analise o código selecionado considerando: qualidade, segurança, performance e sugira melhorias."}
  ]
}
```

### Prompts úteis

- `revisar-seguranca`: identificar SQL injection, XSS, injeção de comandos
- `gerar-tests`: gerar testes pytest cobrindo casos normais e extremos
- `documentar-api`: gerar OpenAPI/Swagger para endpoint selecionado

---

## 6. Fluxos de trabalho recomendados

### Exemplo: projeto FastAPI + Ollama assistente

1. Criar projeto e venv
2. Instalar dependências (`fastapi`, `uvicorn`, `requests`, etc.)
3. Baixar modelo de desenvolvimento (`deepseek-coder-v2:16b`)
4. Usar Continue para gerar documentação e testes
5. Testar endpoints localmente e em staging

**Comandos rápidos**

```bash
python -m venv .venv
source .venv/bin/activate
pip install fastapi uvicorn
pip freeze > requirements.txt
ollama pull deepseek-coder-v2:16b
```

### Ciência de dados / experimentação

- Use `conda` para ambientes com dependências C/C++ (numpy, scipy)
- Gere `environment.yml` com canais `conda-forge`
- Salve experimentos, seeds e o `environment.yml` junto do código

---

## 7. Boas práticas e checklist de produção

**Ambientes**

-

**Modelos / IA**

-

**Código & segurança**

-

---

## 8. Resolução de problemas (troubleshooting)

**Ambiente não ativa (PowerShell)**

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
& ".venv\Scripts\Activate.ps1"
```

``**: modelo não responde**

```bash
ollama list
ollama logs
# Re-pull se necessário
ollama rm <model>
ollama pull <model>
```

**Pacotes faltando após ativar venv**

- Verifique `which python` / `where python` para garantir que aponta para `.venv`
- Recrie ambiente: `python -m venv --clear .venv`

---

## 9. Anexos úteis: snippets e templates

### requirements.txt exemplo

```
fastapi==0.95.0
uvicorn[standard]==0.22.0
pydantic==1.10.7
requests==2.31.0
```

### environment.yml exemplo

```yaml
name: exemplo_proj
channels:
  - conda-forge
dependencies:
  - python=3.10
  - numpy=1.23
  - pandas=1.5
  - pip:
    - fastapi==0.95.0
```

### Script de setup (exemplo completo)

```bash
#!/usr/bin/env bash
# Uso: ./setup.sh <diretorio_projeto>
set -e
DIR=${1:-.}
python3 -m venv $DIR/.venv
source $DIR/.venv/bin/activate
pip install --upgrade pip
if [ -f $DIR/requirements.txt ]; then
  pip install -r $DIR/requirements.txt
fi
```

---

## Próximos passos (sugestões)

- Gerar PDF com formatação profissional (se quiser eu gero)
- Incluir exemplos reais do seu projeto (por exemplo, trecho do FastAPI que você já tem) para gerar prompts e templates específicos
- Adicionar seção de CI/CD (GitHub Actions) para testes e build automatizados

---

*Fim do guia. Se quiser, eu:*

- *Exporto para PDF;*
- *Mesclo este conteúdo com o README do seu repositório;*
- *Gero scripts adicionais (Dockerfile, Compose, GitHub Actions).*

