# Releases

Este documento consolida links e referências para os lançamentos do Cluster AI.

## Notas de Versão (changelog)

- Consulte `RELEASE_NOTES.md` na raiz do repositório para detalhes de cada versão.
- Link direto no GitHub: https://github.com/Dagoberto-Candeias/cluster-ai/blob/main/RELEASE_NOTES.md

## Releases no GitHub

- Página de releases: https://github.com/Dagoberto-Candeias/cluster-ai/releases

## Como gerar uma nova release

1. Atualize `RELEASE_NOTES.md` com as mudanças.
2. Gere uma tag anotada e faça push:
   ```bash
   git tag -a vX.Y.Z -m "Release vX.Y.Z"
   git push origin vX.Y.Z
   ```
3. Crie a release no GitHub (opcionalmente a partir da tag), anexe artefatos se necessário.

## Itens relevantes por release
- Saúde do sistema (health-check.json) e integração com CI.
- Ajustes de Docker Compose / Uvicorn / FastAPI.
- Documentação (MkDocs, Pages) e melhorias de DX (pre-commit, Makefile, etc.).
