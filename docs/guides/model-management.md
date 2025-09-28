# 📚 Gerenciamento de Modelos - Cluster AI

Este guia detalha como gerenciar modelos de IA no Cluster AI, incluindo instalação, categorização, otimização e monitoramento.

## 🏷️ Categorias de Modelos

O Cluster AI suporta diferentes categorias de modelos para atender a diversos casos de uso:

### 🤖 Modelos LLM (Large Language Models)
- **Uso Principal**: Processamento de linguagem natural, chatbots, geração de texto.
- **Exemplos**:
  - `llama3:8b`: Conversação geral e tarefas cognitivas.
  - `mistral:7b`: Análise técnica e raciocínio lógico.
  - `codellama:7b`: Geração e depuração de código.
  - `deepseek-coder:6.7b`: Desenvolvimento de software avançado.
  - `phi3:3.8b`: Modelo leve para dispositivos com recursos limitados.
- **Requisitos**: 4-16GB RAM, suporte a AVX2 recomendado.

### 👁️ Modelos de Visão
- **Uso Principal**: Análise de imagens, reconhecimento visual, OCR.
- **Exemplos**:
  - `llava:7b`: Descrição e análise de imagens.
  - `bakllava:7b`: Processamento multimodal avançado.
  - `moondream:1.8b`: Análise leve de imagens para mobile.
- **Requisitos**: GPU recomendada para inferência rápida.

### 🔄 Modelos Multimodal
- **Uso Principal**: Combinação de texto e imagem, análise integrada.
- **Exemplos**:
  - `llava-llama3:8b`: Visão + linguagem baseada em Llama3.
  - `llava-mistral:7b`: Capacidades técnicas multimodais.
- **Requisitos**: 8-32GB RAM, suporte a CUDA/ROCm para performance.

### 📊 Modelos Especializados
- **Uso Principal**: Tarefas específicas como embeddings, classificação.
- **Exemplos**:
  - `nomic-embed-text:1.5b`: Geração de embeddings para busca semântica.
  - `all-minilm:384`: Classificação de texto leve.

## 🚀 Instalação de Modelos

### Instalação Automática
```bash
# Instalar por categoria
./scripts/download_models.sh --category llm
./scripts/download_models.sh --category vision
./scripts/download_models.sh --category multimodal

# Instalar pacotes recomendados
./scripts/download_models.sh --category recommended

# Instalar todos os modelos
./scripts/download_models.sh --category all --parallel

# Verificar instalação
ollama list
```

### Instalação Manual
```bash
# Exemplo: Instalar Llama3
ollama pull llama3:8b

# Testar modelo
ollama run llama3:8b "Explique machine learning em uma frase."

# Instalar múltiplos em paralelo (requer configuração)
ollama pull llama3:8b & ollama pull mistral:7b &
```

### Configuração Avançada
- **Parâmetros de Pull**:
  ```bash
  # Especificar tag e plataforma
  ollama pull llama3:8b --platform linux/amd64
  
  # Configurar proxy (se necessário)
  export OLLAMA_PROXY=http://proxy.example.com:8080
  ollama pull mistral:7b
  ```
- **Espaço em Disco**: Modelos ocupam 4-50GB cada. Monitore com `df -h`.

## ⚙️ Configuração e Otimização

### Parâmetros de Execução
Edite `config/ollama.conf` para configurações globais:
```ini
# config/ollama.conf
[ollama]
num_parallel = 4
num_gpu = 1
gpu_memory_limit = 4GB
keep_alive = 5m
```

### Otimização por Hardware
- **CPU Only**:
  ```bash
  ollama run llama3:8b --num-thread 8
  ```
- **GPU NVIDIA**:
  ```bash
  export CUDA_VISIBLE_DEVICES=0
  ollama run llava:7b
  ```
- **GPU AMD**:
  ```bash
  export HSA_OVERRIDE_GFX_VERSION=10.3.0  # Para ROCm
  ollama run mistral:7b
  ```

### Cache e Gerenciamento de Memória
- **Limpeza Automática**:
  ```bash
  # Limpar modelos não usados há 30 dias
  ./scripts/ollama/model_manager.sh cleanup 30
  
  # Otimizar uso de disco
  ./scripts/ollama/model_manager.sh optimize
  ```
- **Cache Distribuído**: Modelos são cacheados em workers para inferência paralela.

## 📊 Monitoramento de Modelos

### Métricas Disponíveis
- **Uso de Memória**: Monitoramento em tempo real via dashboard.
- **Latência de Inferência**: Métricas de resposta por modelo.
- **Taxa de Erro**: Detecção de falhas em prompts.

### Comandos de Monitoramento
```bash
# Listar modelos com métricas
./scripts/ollama/model_manager.sh list --metrics

# Monitorar uso em tempo real
./scripts/monitoring/model_monitor.sh live

# Relatório de performance
./scripts/ollama/model_manager.sh report --format json
```

### Integração com Dashboard
- Acesse `http://localhost:3000/models` para visualização gráfica.
- Alertas automáticos para sobrecarga de modelos.

## 🔧 Solução de Problemas

### Erros Comuns
- **"Out of memory"**:
  - Solução: Reduza `num_parallel` ou use modelo menor.
  - Comando: `ollama run phi3:3.8b` (leve).

- **"Model not found"**:
  - Solução: Verifique `ollama list` e reinstale se necessário.
  - Comando: `ollama pull <modelo> --force`.

- **Performance lenta**:
  - Solução: Ative GPU ou otimize threads.
  - Verifique: `./scripts/optimization/model_optimizer.sh`.

### Logs e Debugging
```bash
# Ver logs do Ollama
tail -f ~/.ollama/logs/server.log

# Logs detalhados
OLLAMA_DEBUG=1 ollama run llama3:8b "Teste"
```

## 🛡️ Melhores Práticas

1. **Comece Pequeno**: Instale modelos leves primeiro (phi3, moondream).
2. **Monitore Recursos**: Use dashboard para evitar sobrecarga.
3. **Atualize Regularmente**: `ollama pull <modelo> --update`.
4. **Backup de Modelos**: `ollama export <modelo> model.tar`.
5. **Segurança**: Use modelos de fontes confiáveis (Ollama oficial).

## 📈 Roadmap de Modelos

- **v1.1**: Suporte a fine-tuning local.
- **v1.2**: Integração com Hugging Face Hub.
- **v2.0**: Modelos customizados via API.

Para mais detalhes, consulte [Ollama Documentation](https://ollama.ai/docs).

*Última atualização: 2025-01-28*
