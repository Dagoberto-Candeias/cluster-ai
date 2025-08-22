# Parte 1 — Introdução + Comandos Essenciais + venv

## 1. Introdução
Breve visão geral: objetivos, público‑alvo (desenvolvedores Python, cientistas de dados, engenheiros ML) e escopo (ambientes, Ollama, integração com ferramentas).

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

## 3. `venv` — Passo a passo
**Criar**
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

**Boas práticas rápidas**
- Adicione `.venv/` ao `.gitignore`.
- Nunca commit secrets ou `pip cache`.
