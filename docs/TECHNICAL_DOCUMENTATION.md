# 📚 DOCUMENTAÇÃO TÉCNICA CONSOLIDADA - CLUSTER AI

## 🏗️ ARQUITETURA GERAL

### Componentes Principais
- **Dask Scheduler**: Coordenação de tarefas distribuídas (porta 8786)
- **Dask Workers**: Execução paralela em múltiplos nós
- **Ollama API**: Servidor de modelos IA locais (porta 11434)
- **OpenWebUI**: Interface web conversacional (porta 3000)
- **Backend FastAPI**: APIs de gerenciamento (porta 8000)
- **Frontend React**: Dashboard web responsivo
- **PostgreSQL/Redis**: Persistência e cache
- **Prometheus/Grafana**: Monitoramento e métricas

### Fluxo de Dados
```
Usuário → OpenWebUI → Ollama API → Modelo IA → Resposta
                    ↓
            Backend API → Dask Scheduler → Workers
                    ↓
            PostgreSQL/Redis ← Monitoramento
```

## 🔧 APIs E ENDPOINTS

### Backend FastAPI (/backend)
- `GET /health` - Status do sistema
- `POST /workers` - Gerenciar workers
- `GET /models` - Listar modelos Ollama
- `POST /models/{model}/pull` - Baixar modelo
- `DELETE /models/{model}` - Remover modelo

### Dask
- Dashboard: http://localhost:8787
- API: http://localhost:8786

### Ollama
- API: http://localhost:11434
- Modelos: Lista via `ollama list`

### Monitoramento
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3001
- Kibana: http://localhost:5601

## 🛠️ SCRIPTS PRINCIPAIS

### Gerenciamento
- `manager.sh` - Menu principal interativo
- `scripts/management/worker_manager.sh` - Gestão de workers
- `scripts/ollama/model_manager.sh` - Gestão de modelos

### Instalação
- `install_unified.sh` - Instalador universal
- `scripts/deployment/auto_discover_workers.sh` - Descoberta automática

### Segurança
- `scripts/security/auth_manager.sh` - Autenticação
- `scripts/security/firewall_manager.sh` - Firewall
- `scripts/security/generate_certificates.sh` - Certificados TLS

### Monitoramento
- `scripts/utils/health_check.sh` - Verificação saúde
- `scripts/monitoring/central_monitor.sh` - Monitor central

## 📊 ESTRUTURA DE DIRETÓRIOS

```
cluster-ai/
├── scripts/           # Scripts de automação
│   ├── management/    # Gestão de sistema
│   ├── ollama/        # Modelos IA
│   ├── security/      # Segurança
│   ├── utils/         # Utilitários
│   └── deployment/    # Deploy
├── docs/              # Documentação
├── backend/           # API FastAPI
├── web-dashboard/     # Frontend React
├── config/            # Configurações
├── logs/              # Logs do sistema
├── tests/             # Testes
└── docker-compose.yml # Orquestração
```

## 🔒 SEGURANÇA

### Validações Implementadas
- Entradas sanitizadas em todos os scripts
- Confirmações para operações críticas
- Logs de auditoria para ações perigosas
- Rollback automático para falhas

### Autenticação
- JWT para APIs web
- SSH keys para workers (sem senha)
- TLS/SSL para comunicações

## 🧪 TESTES

### Cobertura
- Unitários: pytest em tests/
- Integração: Testes E2E
- Segurança: Validações de vulnerabilidades
- Performance: Benchmarks de carga

### Execução
```bash
pytest tests/ -v --cov
```

## 🚀 DEPLOYMENT

### Docker Compose
```bash
docker compose up -d
```

### Produção
- Usar docker-compose.prod.yml
- Configurar TLS/SSL
- Backup automático habilitado

## 📈 MONITORAMENTO

### Métricas
- CPU/Memória por worker
- Latência de modelos IA
- Uso de rede
- Status de saúde

### Alertas
- Prometheus rules
- Notificações por email/Slack
- Auto-escalabilidade

## 🔄 ATUALIZAÇÕES

### Sistema Automático
- Verificação periódica via cron
- Backup antes de updates
- Rollback em falha
- Notificações de disponibilidade

### Manual
```bash
./scripts/maintenance/auto_updater.sh
```

## 📞 SUPORTE

- Logs: `/logs/`
- Diagnóstico: `./manager.sh diag`
- Recuperação: `./scripts/deployment/rollback.sh`

---
*Documentação Técnica - Cluster AI v2.0.0*
