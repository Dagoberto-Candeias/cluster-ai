# Cluster AI

**Sistema Universal de IA Distribuída**

Este projeto é uma plataforma completa para **gerenciamento e orquestração de modelos de inteligência artificial em cluster distribuído**. O foco é exclusivamente em processamento de IA, aprendizado de máquina e computação distribuída.

## 🚫 ESCOPO DO PROJETO

**IMPORTANTE:** Este projeto **NÃO** contém nenhuma funcionalidade relacionada a:
- Mineração de criptomoedas
- Blockchain ou criptografia financeira
- Qualquer tipo de atividade financeira ou monetária

O projeto é dedicado exclusivamente ao processamento distribuído de inteligência artificial, utilizando tecnologias como:
- Ollama para execução de modelos de IA
- Dask para computação distribuída
- OpenWebUI para interfaces de chat
- Docker para containerização
- Monitoramento e métricas com Prometheus/Grafana

## 📋 COMPONENTES PRINCIPAIS

- **Model Registry**: Gerenciamento de modelos de IA
- **Distributed Workers**: Processamento paralelo de tarefas de IA
- **Web Dashboard**: Interface web para monitoramento e controle
- **API Backend**: REST API para integração com sistemas externos
- **Monitoring Stack**: Prometheus, Grafana e alertas
- **Security Layer**: Autenticação, autorização e auditoria

## Inicialização dos Serviços

Para iniciar os serviços essenciais do projeto, utilize o script de inicialização automática:

```bash
bash scripts/auto_init_project.sh
```

Este script garante que os serviços principais estejam rodando, incluindo o Dashboard Model Registry, o Web Dashboard Frontend e a Backend API.

### Scripts de Inicialização

- **`scripts/auto_init_project.sh`**: Script principal que verifica o status do sistema e chama o script de inicialização de serviços.
- **`scripts/auto_start_services.sh`**: Script dedicado à inicialização automática dos serviços essenciais:
  - **Dashboard Model Registry**: Executa `python ai-ml/model-registry/dashboard/app.py` na porta 5000
  - **Web Dashboard Frontend**: Executa `docker compose up -d frontend`
  - **Backend API**: Executa `docker compose up -d backend`

### Funcionalidades dos Scripts

- **Caminhos Absolutos**: Os scripts utilizam caminhos absolutos baseados em `$PROJECT_ROOT` para garantir funcionamento independente do diretório de execução.
- **Verificações de Status**: Antes de iniciar serviços, os scripts verificam se eles já estão rodando para evitar conflitos.
- **Logs Detalhados**: Todos os eventos são registrados em `logs/auto_init_project.log` e `logs/services_startup.log`.
- **Tratamento de Erros**: Em caso de falha, são exibidas mensagens claras com instruções para correção.
- **Retries Automáticos**: Até 3 tentativas de inicialização com delays configuráveis.

## Observações Importantes

- O Dashboard Model Registry é um serviço Flask que pode ser executado diretamente com `python3 ai-ml/model-registry/dashboard/app.py` ou via servidor WSGI como `waitress`.
- O script de inicialização automática detecta se a porta 5000 está ocupada para determinar se o Dashboard está rodando, evitando conflitos.
- Caso a porta 5000 esteja ocupada por outro processo, o script assume que o serviço está ativo e não tenta reiniciá-lo.
- Para iniciar manualmente o Dashboard Model Registry via waitress, utilize o comando:
  ```bash
  waitress-serve --port=5000 ai-ml.model_registry.dashboard.app:app
  ```
- Certifique-se de que os scripts `auto_init_project.sh` e `auto_start_services.sh` tenham permissão de execução (`chmod +x`).
- Em caso de problemas, verifique os logs em `logs/services_startup.log` e `ai-ml/model-registry/dashboard/dashboard.log`.

## Troubleshooting

- Se o Dashboard Model Registry não iniciar corretamente, verifique se a porta 5000 está livre ou se outro processo está utilizando-a.
- Para liberar a porta, identifique o processo com `lsof -i :5000` e finalize-o se necessário.
- Consulte os logs para detalhes de erros.
