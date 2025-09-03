# Parte 2 — conda, dependências, IDEs e scripts

## 4. `conda` — Passo a passo
**Criar**
```bash
conda create --name ds_env python=3.10 -y
```

**Ativar**
```bash
conda activate ds_env
```

**Exportar/Importar**
```bash
conda env export > environment.yml
conda env create -f environment.yml
```

## 5. Gerenciamento de dependências — padrões
**requirements.txt** (pip/venv)
```text
pandas==1.5.3
numpy>=1.21.0,<1.23.0
uvicorn==0.22.0
fastapi==0.95.0
```

**environment.yml** (conda)
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

## 6. Integração com IDEs
- **VSCode**: Python extension, `Select Interpreter` → `.venv` ou conda env.
- **Spyder**: `pip install spyder-kernels` no ambiente; selecione o interpretador.
- **Jupyter**: registrar kernel:
```bash
pip install ipykernel
python -m ipykernel install --user --name=meu_ambiente --display-name "Python (meu_ambiente)"
```

## 7. Script de automação (setup.sh)
```bash
#!/usr/bin/env bash
set -e
PROJECT_DIR=${1:-$(pwd)}
PYTHON_VERSION=${2:-3.11}
python${PYTHON_VERSION%.*} -m venv $PROJECT_DIR/.venv
source $PROJECT_DIR/.venv/bin/activate
pip install --upgrade pip
if [ -f $PROJECT_DIR/requirements.txt ]; then
  pip install -r $PROJECT_DIR/requirements.txt
fi
```
