# 📖 GUIA DO USUÁRIO FINAL - CLUSTER AI

## 🚀 INSTALAÇÃO RÁPIDA

### Pré-requisitos
- Linux (Ubuntu 20.04+, Debian 10+, etc.)
- 8GB RAM mínimo, 16GB recomendado
- 50GB espaço em disco
- Conexão internet

### Instalação Automática
```bash
# Baixar o projeto
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
cd cluster-ai

# Executar instalador unificado
sudo bash install_unified.sh
```

### Instalação Manual
```bash
# Instalar dependências
sudo apt update
sudo apt install python3 python3-pip docker docker-compose

# Instalar Python packages
pip install -r requirements.txt

# Configurar Docker
sudo usermod -aG docker $USER
# Logout e login novamente
```

## 🎯 PRIMEIRO USO

### Iniciar o Sistema
```bash
# Menu principal
./manager.sh

# Ou iniciar diretamente
./manager.sh start
```

### Acessar Interfaces
- **OpenWebUI**: http://localhost:3000 (login: admin/admin123)
- **Dask Dashboard**: http://localhost:8787
- **Grafana**: http://localhost:3001
- **Prometheus**: http://localhost:9090

### Baixar Primeiro Modelo
```bash
# Via menu
./manager.sh models

# Ou diretamente
ollama pull llama3:8b
```

## 🤖 USANDO MODELOS DE IA

### Chat Interativo
1. Abrir http://localhost:3000
2. Fazer login
3. Selecionar modelo (ex: llama3:8b)
4. Digitar mensagem

### Gestão de Modelos
```bash
# Listar modelos
./scripts/ollama/model_manager.sh list

# Instalar categoria
./scripts/ollama/install_additional_models.sh coding

# Limpar modelos antigos
./scripts/ollama/model_manager.sh cleanup 30
```

## 👥 GERENCIANDO WORKERS

### Adicionar Worker Linux
```bash
# Via menu
./manager.sh workers

# Automático
./scripts/deployment/auto_discover_workers.sh --ip 192.168.1.100 --user worker
```

### Worker Android
```bash
# No dispositivo Android (Termux)
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/termux_worker_setup.sh | bash
```

### Monitorar Workers
```bash
./scripts/management/worker_manager.sh status
./scripts/management/worker_manager.sh list
```

## 📊 MONITORAMENTO

### Verificar Saúde
```bash
./scripts/utils/health_check.sh
```

### Visualizar Métricas
- Grafana: http://localhost:3001 (admin/admin)
- Prometheus: http://localhost:9090

### Logs
```bash
tail -f logs/cluster_start.log
```

## 🔧 MANUTENÇÃO

### Atualizações
```bash
./scripts/maintenance/auto_updater.sh
```

### Backup
```bash
./scripts/backup_manager.sh create
```

### Limpeza
```bash
./scripts/management/cleanup_manager_secure.sh all
```

## 🛠️ SOLUÇÃO DE PROBLEMAS

### Sistema Não Inicia
```bash
./manager.sh diag
./scripts/deployment/rollback.sh
```

### Workers Não Conectam
- Verificar SSH: `ssh worker@ip`
- Checar portas abertas
- Reiniciar worker: `./scripts/management/worker_manager.sh restart worker-001`

### Modelos Lentos
- Verificar GPU: `nvidia-smi`
- Aumentar RAM workers
- Otimizar: `./scripts/optimization/worker_optimizer.sh`

## 📞 SUPORTE

- **Documentação Completa**: docs/
- **Issues**: GitHub Issues
- **Comunidade**: GitHub Discussions

### Comandos Úteis
```bash
# Status completo
./manager.sh status

# Parar tudo
./manager.sh stop

# Reiniciar
./manager.sh restart

# Diagnóstico
./manager.sh diag
```

---
*Guia do Usuário - Cluster AI v2.0.0*
