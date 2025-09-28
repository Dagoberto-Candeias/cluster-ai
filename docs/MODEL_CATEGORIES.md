# 📚 Categorias de Modelos Ollama - Cluster AI

## Visão Geral

Este documento detalha as categorias de modelos recomendados para o Cluster AI, organizados por caso de uso específico. Cada categoria foi cuidadosamente selecionada para otimizar performance, compatibilidade e eficiência.

## 📝 Coding (Programação)

Modelos especializados em desenvolvimento de software, geração de código e análise técnica.

### Modelos Recomendados

| Modelo | Tamanho | Especialização | Uso Recomendado |
|--------|---------|----------------|-----------------|
| `codellama:7b` | 7B | Geração de código Python/Java/JS | Desenvolvimento geral |
| `deepseek-coder:6.7b` | 6.7B | Código avançado, debugging | Desenvolvimento complexo |
| `llama3:8b` | 8B | Chat + código básico | Prototipagem rápida |
| `starcoder:7b` | 7B | Múltiplas linguagens | Desenvolvimento multilíngue |

### Casos de Uso
- ✅ Geração de código
- ✅ Revisão de código
- ✅ Debugging assistido
- ✅ Documentação técnica
- ✅ Refatoração

### Comando de Instalação
```bash
./scripts/ollama/install_additional_models.sh coding
```

## 🎨 Creative (Criativo)

Modelos para geração de conteúdo criativo, storytelling e tarefas artísticas.

### Modelos Recomendados

| Modelo | Tamanho | Especialização | Uso Recomendado |
|--------|---------|----------------|-----------------|
| `llama3:8b` | 8B | Conteúdo criativo geral | Escrita criativa |
| `mistral:7b` | 7B | Análise técnica + criativa | Conteúdo técnico |
| `nous-hermes:13b` | 13B | Raciocínio avançado | Análise complexa |

### Casos de Uso
- ✅ Escrita criativa
- ✅ Geração de ideias
- ✅ Storytelling
- ✅ Análise artística
- ✅ Brainstorming

### Comando de Instalação
```bash
./scripts/ollama/install_additional_models.sh creative
```

## 🌍 Multilingual (Multilíngue)

Modelos com suporte nativo a múltiplos idiomas e tradução.

### Modelos Recomendados

| Modelo | Tamanho | Idiomas | Uso Recomendado |
|--------|---------|---------|-----------------|
| `llama3:8b` | 8B | 10+ idiomas | Tradução geral |
| `mistral:7b` | 7B | Europeus + outros | Idiomas europeus |
| `gemma:7b` | 7B | Multilíngue otimizado | Tradução avançada |

### Casos de Uso
- ✅ Tradução automática
- ✅ Conteúdo multilíngue
- ✅ Comunicação internacional
- ✅ Localização de software

### Comando de Instalação
```bash
./scripts/ollama/install_additional_models.sh multilingual
```

## 🔬 Science (Científico)

Modelos para pesquisa científica, análise matemática e raciocínio lógico.

### Modelos Recomendados

| Modelo | Tamanho | Especialização | Uso Recomendado |
|--------|---------|----------------|-----------------|
| `llama3:8b` | 8B | Análise científica geral | Pesquisa geral |
| `mixtral:8x7b` | 46B | Matemática avançada | Cálculos complexos |
| `nous-hermes:13b` | 13B | Pesquisa + análise | Estudos científicos |

### Casos de Uso
- ✅ Análise de dados
- ✅ Pesquisa acadêmica
- ✅ Modelagem matemática
- ✅ Simulações
- ✅ Validação de hipóteses

### Comando de Instalação
```bash
./scripts/ollama/install_additional_models.sh science
```

## 📦 Compact (Leves)

Modelos otimizados para dispositivos com recursos limitados ou tarefas simples.

### Modelos Recomendados

| Modelo | Tamanho | Performance | Uso Recomendado |
|--------|---------|-------------|-----------------|
| `phi3:3.8b` | 3.8B | Alta eficiência | Tarefas leves |
| `gemma:2b` | 2B | Ultra-compacto | Dispositivos móveis |
| `llama3:1b` | 1B | Mínimo footprint | Workers Android |

### Casos de Uso
- ✅ Dispositivos móveis
- ✅ Workers leves
- ✅ Testes rápidos
- ✅ Prototipagem
- ✅ Ambientes limitados

### Comando de Instalação
```bash
./scripts/ollama/install_additional_models.sh compact
```

## 👁️ Vision (Visão Computacional)

Modelos multimodais para análise de imagens e visão computacional.

### Modelos Recomendados

| Modelo | Tamanho | Capacidades | Uso Recomendado |
|--------|---------|-------------|-----------------|
| `llava:7b` | 7B | Análise de imagens | Descrição de imagens |
| `bakllava:7b` | 7B | Multimodal avançado | Análise complexa |
| `moondream:1.8b` | 1.8B | Leve para imagens | Dispositivos móveis |

### Casos de Uso
- ✅ Análise de imagens
- ✅ Descrição visual
- ✅ OCR assistido
- ✅ Detecção de objetos
- ✅ Análise de documentos

### Comando de Instalação
```bash
./scripts/ollama/install_additional_models.sh vision
```

## 🛠️ Gerenciamento de Modelos

### Comandos Essenciais

```bash
# Listar modelos instalados
./scripts/ollama/model_manager.sh list

# Estatísticas de uso
./scripts/ollama/model_manager.sh stats

# Otimizar armazenamento
./scripts/ollama/model_manager.sh optimize

# Limpar modelos antigos
./scripts/ollama/model_manager.sh cleanup 30

# Atualizar modelo
./scripts/ollama/model_manager.sh update llama3:8b

# Rollback de versão
./scripts/ollama/model_manager.sh rollback llama3
```

### Estratégias de Seleção

#### Por Hardware
- **GPU NVIDIA/AMD**: Modelos grandes (7B-13B)
- **CPU Only**: Modelos médios (3B-7B)
- **Mobile/Termux**: Modelos compactos (1B-3B)

#### Por Caso de Uso
- **Desenvolvimento**: `coding` + `llama3:8b`
- **Pesquisa**: `science` + `creative`
- **Produção**: `compact` + categoria específica

#### Por Performance
- **Velocidade**: Modelos menores
- **Qualidade**: Modelos maiores
- **Balanceamento**: Modelos médios (7B)

## 🔒 Segurança e Validação

### Validações Implementadas
- ✅ **Hash Checks**: Verificação de integridade
- ✅ **Rollback**: Recuperação automática
- ✅ **Auditoria**: Logs de operações
- ✅ **Confirmações**: Validação de ações críticas

### Boas Práticas
- Sempre use `model_manager.sh` para operações
- Verifique espaço em disco antes de instalar
- Monitore uso de recursos durante operação
- Mantenha backups de modelos críticos

## 📊 Métricas de Performance

### Benchmarks Aproximados (GPU RTX 3060)

| Modelo | Velocidade | Memória | Qualidade |
|--------|------------|---------|-----------|
| `llama3:8b` | 25 tok/s | 8GB | Excelente |
| `codellama:7b` | 30 tok/s | 7GB | Muito Boa |
| `phi3:3.8b` | 40 tok/s | 4GB | Boa |
| `gemma:2b` | 50 tok/s | 2GB | Adequada |

*Valores aproximados, variam por hardware e configuração*

## 🚀 Próximos Passos

- [ ] Adicionar mais modelos especializados
- [ ] Implementar testes automatizados de qualidade
- [ ] Otimizar seleção automática por hardware
- [ ] Adicionar métricas de performance em tempo real

---

**Última atualização**: Janeiro 2025
**Versão**: 2.0.0
