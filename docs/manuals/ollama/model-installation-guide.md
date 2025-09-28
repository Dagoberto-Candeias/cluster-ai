# 🧠 Guia de Instalação de Modelos Ollama

Este guia fornece instruções completas para instalar e gerenciar modelos Ollama no Cluster AI.

## 📋 Pré-requisitos

Antes de instalar modelos, certifique-se de que:

1. **Ollama está instalado**:
   ```bash
   curl -fsSL https://ollama.com/install.sh | sh
   ```

2. **Ollama está rodando**:
   ```bash
   ollama serve
   ```

3. **Verificar instalação**:
   ```bash
   ollama --version
   ```

## 🚀 Métodos de Instalação

### 1. Instalação Interativa (Recomendado)

Use o script interativo para seleção personalizada:

```bash
# Via script dedicado
./scripts/utils/check_models.sh

# Ou via manager
./manager.sh models
```

**Recursos do menu interativo:**
- ✅ Seleção múltipla de modelos
- ✅ Visualização de status (instalado/não instalado)
- ✅ Instalação em lote
- ✅ Modelos personalizados
- ✅ Confirmação antes da instalação

### 2. Instalação Direta

Para instalação rápida de modelos específicos:

```bash
# Modelo principal recomendado
ollama pull llama3.1:8b

# Modelo de código
ollama pull deepseek-coder-v2:16b

# Modelo de visão
ollama pull llava
```

### 3. Instalação em Lote

Para instalar múltiplos modelos de uma vez:

```bash
# Criar script de instalação
cat > install_models.sh << 'EOF'
#!/bin/bash
MODELS=(
    "llama3.1:8b"
    "deepseek-coder-v2:16b"
    "mistral"
    "llava"
    "phi3"
)

for model in "${MODELS[@]}"; do
    echo "Instalando $model..."
    ollama pull "$model"
done

echo "Instalação concluída!"
EOF

chmod +x install_models.sh
./install_models.sh
```

## 📚 Modelos Recomendados

### Modelos Essenciais

| Modelo | Tamanho | Uso Principal | Comando |
|--------|---------|---------------|---------|
| `llama3.1:8b` | ~5GB | Chat geral, assistente | `ollama pull llama3.1:8b` |
| `deepseek-coder-v2:16b` | ~9GB | Desenvolvimento, código | `ollama pull deepseek-coder-v2:16b` |
| `mistral` | ~4GB | Chat avançado | `ollama pull mistral` |

### Modelos por Categoria

#### 🤖 Modelos de Chat
```bash
ollama pull llama3.1:8b      # Principal
ollama pull llama3.2         # Avançado
ollama pull phi3             # Raciocínio
ollama pull gemma2:9b        # Conversação
ollama pull qwen3            # Performance
```

#### 💻 Modelos de Código
```bash
ollama pull deepseek-coder-v2:16b  # Principal
ollama pull qwen2.5-coder:32b      # Grande
ollama pull starcoder2:7b          # Médio
ollama pull deepseek-coder         # Leve
```

#### 👁️ Modelos de Visão
```bash
ollama pull llava             # Visão + chat
```

#### 🔍 Modelos de Embeddings
```bash
ollama pull nomic-embed-text  # Busca semântica
```

## ⚙️ Configuração Avançada

### Otimização para GPU

```bash
# Configurar uso de GPU
export OLLAMA_NUM_GPU_LAYERS=35
export OLLAMA_MAX_LOADED_MODELS=2

# Para sistemas com pouca VRAM
export OLLAMA_NUM_GPU_LAYERS=25
export OLLAMA_MAX_LOADED_MODELS=1
```

### Configuração de Serviço (Linux)

```bash
# Editar configuração do serviço
sudo systemctl edit ollama

# Adicionar configurações
[Service]
Environment="OLLAMA_NUM_GPU_LAYERS=35"
Environment="OLLAMA_MAX_LOADED_MODELS=2"
Environment="OLLAMA_HOST=0.0.0.0:11434"
```

### Configuração Personalizada

```bash
# Arquivo de configuração personalizado
mkdir -p ~/.ollama
cat > ~/.ollama/config.json << EOF
{
  "num_gpu_layers": 35,
  "max_loaded_models": 2,
  "host": "0.0.0.0",
  "port": "11434"
}
EOF
```

## 📊 Gerenciamento de Modelos

### Listar Modelos Instalados

```bash
# Listar todos os modelos
ollama list

# Ver informações detalhadas
ollama show llama3.1:8b
```

### Remover Modelos

```bash
# Remover modelo específico
ollama rm llama3.1:8b

# Limpar cache
ollama clean
```

### Verificar Uso de Recursos

```bash
# Ver modelos carregados
ollama ps

# Monitorar uso de GPU
nvidia-smi
```

## 🔧 Solução de Problemas

### Problema: Download lento

```bash
# Usar mirror alternativo
export OLLAMA_REGISTRY=https://registry.ollama.ai

# Ou configurar proxy
export HTTP_PROXY=http://proxy.company.com:8080
```

### Problema: Falta de espaço

```bash
# Verificar espaço disponível
df -h ~/.ollama

# Limpar modelos não usados
ollama ps | awk 'NR>1 {print $1}' | xargs ollama rm
```

### Problema: GPU não detectada

```bash
# Verificar drivers NVIDIA
nvidia-smi

# Instalar drivers se necessário
sudo apt update && sudo apt install nvidia-driver-XXX
```

## 📈 Otimização de Performance

### Para Sistemas com GPU

```bash
# Máximo de camadas GPU
export OLLAMA_NUM_GPU_LAYERS=99

# Múltiplos modelos carregados
export OLLAMA_MAX_LOADED_MODELS=3
```

### Para Sistemas CPU-only

```bash
# Otimizar para CPU
export OLLAMA_NUM_THREAD=8
export OLLAMA_MAX_LOADED_MODELS=1
```

### Configuração por Modelo

```bash
# Para modelos grandes
ollama run llama3:70b --num-gpu-layers 50

# Para modelos pequenos
ollama run phi3 --num-thread 4
```

## 🔄 Atualização de Modelos

```bash
# Atualizar modelo específico
ollama pull llama3.1:8b  # Baixa versão mais recente

# Verificar atualizações disponíveis
ollama list | grep -E "(llama3|mistral|phi)" | sort
```

## 📝 Scripts de Automação

### Script de Backup de Modelos

```bash
#!/bin/bash
# backup_models.sh

BACKUP_DIR="$HOME/ollama_models_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Fazendo backup dos modelos Ollama..."
cp -r ~/.ollama/models "$BACKUP_DIR/"

echo "Backup concluído: $BACKUP_DIR"
```

### Script de Restauração

```bash
#!/bin/bash
# restore_models.sh

BACKUP_DIR="$1"

if [ -z "$BACKUP_DIR" ]; then
    echo "Uso: $0 <diretório_de_backup>"
    exit 1
fi

echo "Restaurando modelos..."
cp -r "$BACKUP_DIR/models" ~/.ollama/

echo "Restauração concluída!"
```

## 🎯 Recomendações por Caso de Uso

### Desenvolvimento de Software
```bash
ollama pull deepseek-coder-v2:16b
ollama pull qwen2.5-coder:32b
ollama pull starcoder2:7b
```

### Chat e Assistência Geral
```bash
ollama pull llama3.1:8b
ollama pull mistral
ollama pull gemma2:9b
```

### Análise de Imagens
```bash
ollama pull llava
ollama pull llama3.1:8b  # Para descrição
```

### Processamento de Linguagem Natural
```bash
ollama pull llama3.1:8b
ollama pull nomic-embed-text
ollama pull phi3
```

## 📚 Recursos Adicionais

- [Documentação Oficial Ollama](https://github.com/ollama/ollama)
- [Modelos Disponíveis](https://ollama.com/library)
- [Guia de Otimização](https://github.com/ollama/ollama/blob/main/docs/faq.md)
- [Configurações Avançadas](https://github.com/ollama/ollama/blob/main/docs/modelfile.md)

---

## ❓ FAQ

**P: Quanto espaço em disco preciso?**
R: Modelos variam de 1GB (phi3) a 40GB+ (modelos grandes). Planeje 50-100GB para uma coleção completa.

**P: Posso usar múltiplos modelos simultaneamente?**
R: Sim, mas considere a memória disponível. Use `OLLAMA_MAX_LOADED_MODELS` para controlar.

**P: Como acelerar downloads?**
R: Use conexões rápidas, considere mirrors alternativos, ou baixe durante horários de menor tráfego.

**P: Modelos funcionam offline?**
R: Sim, após o download inicial, todos os modelos funcionam completamente offline.

Para suporte adicional, consulte a documentação do Cluster AI ou abra uma issue no repositório.
