# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

## [2.0.0] - 2025-09-28

### Destaques
- Unificação completa do backend em FastAPI (`web-dashboard/backend/main_fixed.py`) com rotas canônicas sob `/api`.
- Remoção do legado `backend/api/` e atualização de referências em testes e docs.
- Script de Health Check reforçado (`scripts/utils/health_check.sh`):
  - Modo JSON (`--json`) para CI/CD com código de saída refletindo o status geral.
  - Checagem de pré-requisitos com avisos e fallbacks.
  - Comparações de ponto flutuante portáveis (awk → bc → inteiro com aviso).
- CI GitLab: job agendado `scheduled:health_check_json` que publica `health-check.json` (não bloqueante).
- README atualizado com badge do GitLab para `dagoberto-candeias/cluster-ai` e seção de Health Check (JSON/CI).

### Qualidade de Código
- Linters executados e corrigidos: `flake8`, `black`, `isort` (todos OK).
- Ajustes ShellCheck em scripts-chave (lote inicial):
  - `scripts/utils/system_status_dashboard.sh`: SC2155 e SC2004.
  - `scripts/web_server_fixed.sh`: SC2155, SC2181, anotações SC2034/SC1091.
  - `scripts/verify_syntax.sh`: SC2155, SC2295.

### Testes
- Unitários: 127 passed, 5 skipped.
- Integração: 70 passed.
- E2E: 16 passed.

### Alterações de Repositório
- Reescrita do histórico (orphan) consolidando em um único commit limpo na `main`.
- Remoção de todas as tags anteriores (locais e remotas).
- Criação da tag `v2.0.0` no histórico limpo.

### Notas de Migração
- Quem já clonou o repositório deve executar:
  - `git fetch`
  - `git reset --hard origin/main`
  - ou preferencialmente, reclonar o repositório.

---

## Histórico anterior
- O histórico anterior foi substituído pela consolidação do release 2.0.0.

