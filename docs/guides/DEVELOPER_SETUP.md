# Guia de Setup para Desenvolvedores

Este guia resume o ambiente de desenvolvimento recomendado para o Cluster AI.

## 1) Dependências
- Git, Docker e Docker Compose
- Python 3.11+ (para scripts auxiliares)
- Ferramentas de shell usuais (bash, grep, awk, sed, curl, ssh)
- `yq` v4 (YAML CLI)

## 2) Clonar e preparar o repositório
```bash
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
cd cluster-ai
```

## 3) Variáveis de ambiente locais
Utilize `/.env.local` para configurações específicas da máquina (não versionado). O `scripts/utils/health_check.sh` carrega esse arquivo com filtro seguro.

Exemplo:
```dotenv
DOCKER_SERVICES="azure-cluster-worker azure-cluster-control-plane gcp-cluster-worker gcp-cluster-control-plane gcp-cluster-worker2 aws-cluster-worker2 aws-cluster-worker aws-cluster-control-plane"
```

## 4) Health Check
- Health rápido (sem workers):
```bash
make health-json
```
- Health completo (inclui workers):
```bash
make health-json-full SERVICES="azure-cluster-worker azure-cluster-control-plane gcp-cluster-worker aws-cluster-worker"
```
- Diagnóstico de SSH de workers:
```bash
make health-ssh
```
Saídas geradas:
- `health-check.json`
- `workers-ssh-report.txt`

## 5) Workers (SSH)
- Guia completo: `docs/guides/WORKERS_SSH.md`
- Exemplo: `cluster.yaml.example` → copie para `cluster.yaml` e ajuste `host/user/port`.
- Enquanto um worker estiver ausente ou sem SSH, você pode:
  - Usar `make health-json` (pula workers), ou
  - Usar `--skip-workers` diretamente no script.

## 6) Pre-commit (Qualidade de Código)
- Arquivo: `.pre-commit-config.yaml` (black, isort, flake8, shellcheck, yamllint, prettier)
- Instalação local:
```bash
pip install pre-commit
pre-commit install
# Rodar em todo o repo (opcional)
pre-commit run --all-files
```

## 7) Docker Compose - Dev
- Arquivo: `docker-compose.dev.override.yml` com ajustes para `backend`:
  - `user: "${UID:-1000}:${GID:-1000}"`
  - `uvicorn --reload --reload-exclude logs`
- Para usar explicitamente:
```bash
docker compose -f docker-compose.yml -f docker-compose.dev.override.yml up -d
```

## 8) Troubleshooting rápido
- Uvicorn/watchfiles com problemas de permissão em `logs/`:
  - Garanta que `logs/` exista e tenha permissão adequada
  - Em dev, o override já exclui `logs` do reload
- Backend inacessível:
  - Confirme bind `0.0.0.0:8000`
  - `docker compose logs backend` e `curl http://localhost:8000/api/health`
- Workers com FAIL:
  - Verifique `host/user/port` no `cluster.yaml`
  - `ssh -o BatchMode=yes -o ConnectTimeout=5 -p <PORT> <USER>@<HOST> 'echo OK'`

## 9) CI (GitLab)
- Agendado (não bloqueante, sem workers): `scheduled:health_check_json`
- Manual (com workers): `manual:health_check_full`

## 10) Convenções adicionais
- Python: Black + Isort (PEP8, line length 100)
- Shell: ShellCheck (-x) e cabeçalhos padronizados em `scripts/`
- Documentação: Markdown, `docs/` com guias e exemplos
