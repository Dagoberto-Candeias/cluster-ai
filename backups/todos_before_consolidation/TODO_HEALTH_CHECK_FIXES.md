# TODO - Correções do Health Check

## Problemas Críticos Identificados

### 1. ✅ Erro de Sintaxe Corrigido
- [x] Erro na linha 609: expressão numérica inválida no cálculo de memória
- [x] Erro na linha 37: comando 'info' não encontrado no setup_monitor_service.sh
- [x] Erro de formatação printf com números decimais

### 2. 🚨 Problemas de Latência Ollama
- [ ] Modelos mistral:latest, codellama:latest, llama2:latest com latência > 20s
- [ ] Testes de latência falhando com timeout
- [ ] Possível problema de configuração ou recursos insuficientes

### 3. ⚠️ Dask Não Executando
- [ ] Scheduler Dask não está rodando
- [ ] Workers Dask não estão executando
- [ ] Dashboard Dask inacessível na porta 8787

### 4. 📦 Containers Docker Ausentes
- [ ] Container open-webui não encontrado
- [ ] Container openwebui-nginx não encontrado
- [ ] Falta configuração docker-compose

### 5. 🎮 GPU Não Detectada
- [ ] Sistema rodando apenas em modo CPU
- [ ] Drivers NVIDIA/AMD não instalados
- [ ] PyTorch sem suporte CUDA

### 6. 🔧 Extensões VSCode Ausentes
- [ ] streetsidesoftware.code-spell-checker-portuguese-brazilian
- [ ] aaron-bond.better-comments
- [ ] ms-vsliveshare.vsliveshare

### 7. 📊 Carga de CPU Crítica
- [ ] Carga de CPU: 55.00/núcleo (muito alta)
- [ ] Possível processo consumindo recursos excessivos

### 8. 📚 Documentação Desatualizada
- [ ] README.md não gerado dinamicamente
- [ ] Documentação desatualizada em relação aos scripts

## Plano de Correção Priorizado

### Fase 1: Correções Críticas (Sintaxe) ✅ CONCLUÍDA
- [x] Corrigir erros de sintaxe no health_check.sh
- [x] Corrigir erros no setup_monitor_service.sh
- [x] Testar script corrigido
- [x] Performance optimizer executado

### Fase 2: Otimização de Recursos
- [ ] Investigar e resolver carga alta de CPU
- [ ] Otimizar uso de memória
- [ ] Verificar processos em execução

### Fase 3: Serviços Essenciais ✅ CONCLUÍDA
- [x] Configurar e iniciar Dask Scheduler
- [x] Configurar Dask Workers
- [ ] Resolver problemas de latência Ollama

### Fase 4: Containers e GPU
- [ ] Configurar containers Docker (open-webui, nginx)
- [ ] Instalar drivers GPU
- [ ] Configurar PyTorch com CUDA

### Fase 5: Ambiente de Desenvolvimento
- [ ] Instalar extensões VSCode ausentes
- [ ] Atualizar documentação README.md

### Fase 6: Testes Finais
- [ ] Executar health check completo
- [ ] Validar todas as correções
- [ ] Documentar melhorias implementadas

## Comandos para Correção

### CPU Alta
```bash
# Verificar processos com alta CPU
ps aux --sort=-%cpu | head -10

# Matar processos problemáticos (se necessário)
kill -9 <PID>

# Otimizar sistema
./scripts/optimization/performance_optimizer.sh
```

### Dask
```bash
# Iniciar scheduler
dask scheduler --port 8786 &

# Iniciar workers
dask worker tcp://localhost:8786 --nworkers 4 &
```

### Ollama
```bash
# Verificar status
systemctl status ollama

# Reiniciar se necessário
sudo systemctl restart ollama

# Testar modelo manualmente
curl -X POST http://localhost:11434/api/generate -d '{"model": "mistral:latest", "prompt": "Test", "stream": false}'
```

### Docker
```bash
# Verificar containers
docker ps -a

# Iniciar containers se existirem
docker-compose -f configs/docker/compose-basic.yml up -d
```

### GPU
```bash
# Verificar GPU
nvidia-smi

# Instalar drivers se necessário
./scripts/installation/gpu_setup.sh
```

## Status Atual
- ✅ Correções de sintaxe aplicadas
- 🔄 Aguardando testes dos scripts corrigidos
- 📋 Próximos passos: investigar carga de CPU e otimizar serviços
