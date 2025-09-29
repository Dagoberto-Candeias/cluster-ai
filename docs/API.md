# Cluster AI - API Unificada (FastAPI)

Este documento descreve as rotas da API unificada baseada em FastAPI. O aplicativo canônico é `web-dashboard/backend/main_fixed.py` e roda via `uvicorn main_fixed:app`.

## Saúde e Status
- GET `/health`
  - Health check básico do serviço (sem autenticação).
- GET `/api/health`
  - Alias compatível para health check básico (sem autenticação).
  
  Exemplo:
  ```bash
  curl -sS http://localhost:8000/api/health | jq .
  ```
- GET `/cluster/status` (autenticado)
  - Status abrangente do cluster (CPU, memória, disco, serviços, workers, performance agregada).
- GET `/api/cluster/status` (autenticado)
  - Alias compatível para o status do cluster.
- GET `/monitoring/status` (autenticado)
  - Resumo de monitoramento (resumo de alertas, status de serviços e health geral).

## Métricas (Prometheus)
- GET `/metrics`
  - Exposição de métricas Prometheus do backend (requisições, latências, etc.).
  - Compressão habilitada (gzip) e rota fora do schema OpenAPI.

  Exemplo:
  ```bash
  curl -s http://localhost:8000/metrics | head -n 20
  ```

## Métricas do Sistema
- GET `/metrics/system` (autenticado)
  - Histórico de métricas do sistema com cache (modelo `SystemMetrics`).
- GET `/api/system_metrics` (autenticado)
  - Endpoint de compatibilidade legado. Resumo de CPU, memória, disco, status do Dask (porta 8786) e GPU, quando disponível.

## Alertas
- GET `/alerts` (autenticado)
  - Lista de alertas recentes (modelo `AlertInfo`).
- GET `/api/alerts` (autenticado)
  - Alias unificado para alertas.

  Exemplo (com token via variável de ambiente):
  ```bash
  # Defina JWT_TOKEN no seu ambiente de forma segura (sem hardcode neste arquivo)
  curl -sS -H "Authorization: Bearer ${JWT_TOKEN:?defina JWT_TOKEN}" \
       http://localhost:8000/api/alerts | jq .
  ```

## Workers
- GET `/workers` (autenticado)
  - Lista os workers (modelo `WorkerInfo`).
- GET `/api/workers` (autenticado)
  - Alias unificado para lista de workers.
- GET `/workers/{worker_id}` (autenticado)
  - Obtém informações detalhadas de um worker específico.
- POST `/workers/{worker_id}/stop` (autenticado)
  - Solicita parada do worker.
- POST `/workers/{worker_id}/restart` (autenticado)
  - Solicita reinício do worker.

## Autenticação e Sessão
- POST `/auth/login`
  - Retorna token de acesso (rate-limited).
- GET `/auth/me` (autenticado)
  - Informações do usuário atual.
- GET `/auth/csrf-token` (autenticado)
  - Token CSRF para uso no WebSocket.

## Logs
- GET `/logs` (autenticado)
  - Retorna logs (com filtros opcionais de `level` e `component`).

## Configurações
- GET `/settings` (autenticado)
  - Retorna as configurações atuais do sistema.
- POST `/settings` (autenticado)
  - Atualiza configurações com validações (ex.: intervalos e limites).

## WebSocket
- WS `/ws/{client_id}` (autenticado via CSRF token)
  - Canal de atualizações em tempo real com proteção CSRF.

## Observações
- As rotas legadas sob `/legacy` foram removidas. Consumidores devem migrar para os caminhos sob `/api` indicados acima.
- O health check do Docker aponta para `GET /health` por padrão.
- Para desenvolvimento, a aplicação escuta em `0.0.0.0:8000`.
