# Cluster AI - Documentação

Bem-vindo à documentação do Cluster AI. Aqui você encontra guias de instalação, operação diária, saúde do sistema (health checks), configuração de workers (Linux/Android) e integração com CI/CD.

## Sumário rápido

- Guia de Setup do Desenvolvedor: `guides/DEVELOPER_SETUP.md`
- Configuração de Workers (SSH): `guides/WORKERS_SSH.md`
- API e exemplos: `API.md`
- Monitoramento (Prometheus/Grafana): `guides/monitoring.md`
- Otimizações e boas práticas: `guides/OPTIMIZATION.md`

## Uso diário

- Health rápido (sem workers):
  ```bash
  make health-json
  ```
- Health completo (inclui workers):
  ```bash
  make health-json-full SERVICES="azure-cluster-worker azure-cluster-control-plane gcp-cluster-worker aws-cluster-worker"
  ```
- Diagnóstico SSH de workers:
  ```bash
  make health-ssh
  ```

- Dashboard Model Registry (Flask):
  - URL: http://localhost:5000
  - Health check:
    ```bash
    curl -i ${DASHBOARD_HEALTH_URL:-http://127.0.0.1:5000/health}
    ```
  - Variáveis opcionais:
    ```dotenv
    DASHBOARD_HEALTH_URL=http://127.0.0.1:5000/health
    DASHBOARD_HEALTH_TIMEOUT=3
    ```

- Web Server (scripts/web_server_fixed.sh):
  - Porta padrão: 8080
  - Para evitar conflitos locais/CI, use variável de ambiente:
    ```bash
    export WEBSERVER_PORT=8081
    bash scripts/web_server_fixed.sh start
    ```
  - Os testes de performance usam `WEBSERVER_PORT` (padrão 8080)

## Variáveis de ambiente locais

Crie `/.env.local` para definir serviços do Docker a monitorar (o script carrega com filtro seguro):
```dotenv
DOCKER_SERVICES="azure-cluster-worker azure-cluster-control-plane gcp-cluster-worker gcp-cluster-control-plane gcp-cluster-worker2 aws-cluster-worker2 aws-cluster-worker aws-cluster-control-plane"
```

## CI/CD

- Lint (pre-commit) com cache (não bloqueante)
- Health agendado (JSON) e manual (full)
- Publicação automática desta documentação via GitHub Pages

Para detalhes completos, consulte o `README.md` na raiz do projeto.
