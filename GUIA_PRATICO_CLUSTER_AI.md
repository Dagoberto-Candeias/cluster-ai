# 🚀 GUIA PRÁTICO - Cluster AI

## 📋 ÍNDICE RÁPIDO
- [⚡ Comandos Essenciais](#-comandos-essenciais)
- [🤖 Modelos Ollama](#-modelos-ollama)
- [🔧 Configurações](#-configurações)
- [🚀 Exemplos Práticos](#-exemplos-práticos)
- [🛠️ Troubleshooting](#-troubleshooting)
- [🚀 CI/CD](#-cicd)
- [📊 Monitoramento](#-monitoramento)

## ⚡ COMANDOS ESSENCIAIS

### Instalação
```bash
# Instalação completa (recomendado)
sudo ./install_cluster_universal.sh

# Instalação tradicional com menu
./install_cluster.sh

# Instalação modular
sudo ./install_universal.sh  # Sistema
./scripts/installation/setup_python_env.sh              # Ambiente Python
sudo ./scripts/installation/setup_vscode.sh    # VSCode
```

### Verificação do Sistema
```bash
# Health check completo
./scripts/utils/health_check.sh

# Teste de GPU
python scripts/utils/test_gpu.py

# Verificar modelos instalados
./scripts/utils/check_models.sh

# Validação completa
./scripts/validation/validate_installation.sh
```

### Gerenciamento
```bash
# Status do cluster
./install_cluster.sh --status

# Backup completo
./install_cluster.sh --backup

# Restaurar backup
./install_cluster.sh --restore

# Agendar backups
./install_cluster.sh --schedule
```

## 🤖 MODELOS OLLAMA

### Modelos Recomendados
```bash
# Chat geral
ollama pull llama3:8b
ollama pull llama3.1:8b

# Codificação
ollama pull deepseek-coder-v2:16b
ollama pull starcoder2:7b

# Multimodal
ollama pull llava
```

### Download em Lote
```bash
# Baixar modelos essenciais
for model in llama3:8b mistral deepseek-coder-v2:16b; do
    ollama pull $model &
done
```

### Verificação
```bash
# Listar modelos instalados
ollama list

# Verificar espaço
du -sh ~/.ollama/

# Testar modelo
ollama run llama3 "Explique machine learning"
```

## 🔧 CONFIGURAÇÕES

### GPU Automática
```bash
# Verificar GPU detectada
nvidia-smi    # NVIDIA
rocm-smi      # AMD

# Configurar camadas GPU (arquivo ~/.ollama/config.json)
{
  "environment": {
    "OLLAMA_NUM_GPU_LAYERS": "35",  # NVIDIA high-end
    "OLLAMA_NUM_GPU_LAYERS": "20",  # NVIDIA mid-range
    "OLLAMA_NUM_GPU_LAYERS": "8"    # AMD
  }
}
```

### Variáveis de Ambiente Úteis
```bash
# Limitar uso de memória
export OLLAMA_MAX_LOADED_MODELS=2
export OLLAMA_KEEP_ALIVE="24h"

# Otimização performance
export OLLAMA_MMAP=1      # Memory mapping
export OLLAMA_F16=0       # Float32 (mais preciso)
```

## 🚀 EXEMPLOS PRÁTICOS

### Processamento Distribuído
```python
from dask.distributed import Client
import dask.array as da

# Conectar ao cluster
client = Client('localhost:8786')

# Array distribuído 10k x 10k
x = da.random.random((10000, 10000), chunks=(1000, 1000))
result = (x + x.T).mean().compute()
print(f"Resultado: {result}")

client.close()
```

### Integração Ollama + Dask
```python
from dask.distributed import Client
import dask.bag as db
import requests

def analyze_with_ai(text):
    prompt = f"Analise sentimento: '{text}'. Responda POSITIVO/NEGATIVO/NEUTRO."
    response = requests.post(
        'http://localhost:11434/api/generate',
        json={'model': 'llama3', 'prompt': prompt, 'stream': False}
    )
    return response.json()['response'].strip()

# Processamento paralelo
texts = ["Texto positivo", "Texto negativo", "Texto neutro"]
results = db.from_sequence(texts).map(analyze_with_ai).compute()
```

### API Python para Ollama
```python
import requests

def ask_ollama(prompt, model="llama3", temperature=0.7):
    response = requests.post(
        'http://localhost:11434/api/generate',
        json={
            'model': model,
            'prompt': prompt,
            'stream': False,
            'options': {'temperature': temperature}
        }
    )
    return response.json()['response']

# Uso
resposta = ask_ollama("Explique blockchain")
print(resposta)
```

## 🛠️ TROUBLESHOOTING

### Problemas Comuns

#### Ollama Não Inicia
```bash
# Reiniciar serviço
sudo systemctl restart ollama

# Verificar logs
journalctl -u ollama -f

# Executar manualmente
ollama serve &
```

#### Portas Ocupadas
```bash
# Verificar processos
sudo lsof -i :8786  # Dask Scheduler
sudo lsof -i :8787  # Dask Dashboard  
sudo lsof -i :8080  # OpenWebUI
sudo lsof -i :11434 # Ollama

# Encerrar processo específico
sudo kill -9 <PID>
```

#### Permissão Docker
```bash
# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER
newgrp docker
```

### Diagnóstico Rápido
```bash
#!/bin/bash
echo "=== DIAGNÓSTICO RÁPIDO ==="

# Serviços
echo "📦 Serviços:"
systemctl status docker | grep Active
systemctl status ollama | grep Active

# Rede  
echo "🌐 Portas:"
netstat -tlnp | grep -E '(8786|8787|8080|11434)'

# Recursos
echo "💾 Recursos:"
free -h
df -h ~/

echo "✅ Diagnóstico concluído!"
```

## 🚀 CI/CD

### Configuração do CI/CD
O Cluster AI agora possui um pipeline de CI/CD configurado com GitHub Actions. Isso permite que você execute testes automatizados, verifique a qualidade do código e implemente o sistema de forma contínua.

### Como Funciona
1. **Testes Automatizados**: Ao fazer push ou pull request, os testes são executados automaticamente em várias distribuições Linux.
2. **Verificação de Qualidade**: O código é verificado quanto a erros e problemas de segurança.
3. **Deploy Automatizado**: O sistema é implantado automaticamente após a validação bem-sucedida.

### Comandos para Interagir com CI/CD
```bash
# Executar testes em múltiplas distribuições
./scripts/validation/test_multiple_distros.sh

# Executar otimização de performance
./scripts/optimization/performance_optimizer.sh

# Consolidação da documentação
./scripts/documentation/consolidate_docs.sh

# Deploy automatizado
./scripts/deployment/auto_deploy.sh
```

### Notificações
Notificações sobre o status do deploy e testes são enviadas para o canal configurado no Slack.

### Exemplos de Uso
- **Testar o código**: Faça um push para o repositório e verifique os resultados dos testes no GitHub.
- **Monitorar o status do deploy**: Acesse o log de deploy para verificar se houve falhas ou se o deploy foi bem-sucedido.

## 📊 MONITORAMENTO

### Dashboard e Interfaces
- **OpenWebUI**: http://localhost:8080
- **Dask Dashboard**: http://localhost:8787
- **Ollama API**: http://localhost:11434

### Comandos de Monitoramento
```bash
# Verificar workers Dask
python -c "from dask.distributed import Client; c=Client('localhost:8786'); print(f'Workers: {len(c.scheduler_info()[\\\"workers\\\"])}'); c.close()"

# Status Ollama
curl http://localhost:11434/api/tags

# Uso de recursos
htop
glances
nvidia-smi
```

### Logs Importantes
```bash
# Logs do sistema
journalctl -xe

# Logs Docker
docker logs <container_name>

# Logs Ollama
journalctl -u ollama -f
```

## 🔧 CONFIGURAÇÃO AVANÇADA

### Produção com TLS
```bash
# Configurar TLS
cd deployments/production/
./setup_tls.sh

# Verificar certificados
sudo certbot certificates
```

### Backup Automático
```bash
# Configurar agendamento
crontab -e
# Adicionar: 0 2 * * * /path/to/cluster-ai/install_cluster.sh --backup

# Backup manual
./install_cluster.sh --backup
```

### Otimização Performance
```bash
# Ajustar chunks Dask (para grandes datasets)
import dask.array as da
x = da.random.random((50000, 50000), chunks=(5000, 5000))

# Usar persist() para dados reutilizados
data = data.persist()

# Limitar recursos por container
docker run --cpus=2 --memory=4g ...
```

## 🎯 FLUXO DE TRABALHO RECOMENDADO

1. **Instalação**: `sudo ./install_cluster_universal.sh`
2. **Verificação**: `./scripts/utils/health_check.sh`
3. **Modelos**: `./scripts/utils/check_models.sh`
4. **Testes**: Exemplos básicos → avançados
5. **Produção**: Configurar TLS + Backup
6. **CI/CD**: Configurar GitHub Actions para deploy contínuo

## 📞 SUPORTE RÁPIDO

### Documentação Completa
- **Instalação**: `docs/manuals/INSTALACAO.md`
- **Ollama**: `docs/manuals/OLLAMA.md` 
- **Troubleshooting**: `docs/guides/TROUBLESHOOTING.md`
- **Otimização**: `docs/guides/OPTIMIZATION.md`
- **CI/CD**: `.github/workflows/ci-cd.yml`

### Issues Comuns
1. 🔄 Reiniciar serviços primeiro
2. 📖 Verificar logs detalhadamente  
3. 🔧 Testar configuração mínima
4. 🐛 Reportar com logs completos

---

**💡 Dica**: Use `./install_cluster.sh` para acesso rápido ao menu completo!

**🚨 Emergência**: Em caso de problemas críticos, execute:
```bash
pkill -f "dask-"
pkill -f "ollama"
sudo systemctl restart docker
./install_cluster.sh --role server
```

**📚 Para mais detalhes**: Consulte a documentação completa em `docs/`

*Última atualização: $(date +%Y-%m-%d)*
