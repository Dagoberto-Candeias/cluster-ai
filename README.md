# Cluster AI

Projeto para gerenciamento e orquestração de modelos de inteligência artificial em cluster.

## Inicialização dos Serviços

Para iniciar os serviços essenciais do projeto, utilize o script de inicialização automática:

```bash
bash scripts/auto_init_project.sh
```

Este script garante que os serviços principais estejam rodando, incluindo o Dashboard Model Registry, o Web Dashboard Frontend e a Backend API.

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
