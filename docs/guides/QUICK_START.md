# ⚡ Quick Start - Cluster AI

Comece a usar o Cluster AI em **5 minutos** com este guia rápido!

## 🎯 O que você vai conseguir:
- ✅ Cluster Dask funcionando
- ✅ Ollama com modelos de IA  
- ✅ OpenWebUI acessível
- ✅ Ambiente pronto para desenvolvimento

## 📋 Pré-requisitos
- Ubuntu/Debian, CentOS/RHEL, ou Manjaro
- 4GB+ RAM (8GB+ recomendado)
- 20GB+ espaço em disco
- Conexão internet estável
- Acesso sudo/root

## 🚀 Passo a Passo Rápido

### 1. 📥 Download e Instalação

**Opção A: Se você já clonou o repositório (Recomendado para desenvolvimento)**
```bash
# Executar script local
./install_cluster.sh
```

**Opção B: Download do GitHub (para quem não clonou)**
```bash
# Baixar script de instalação
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/installation/main.sh -o install_cluster.sh

# Tornar executável
chmod +x install_cluster.sh

# Executar instalação
./install_cluster.sh
```

### 2. 🎭 Escolher Papel da Máquina
Durante a instalação, selecione:

**Para teste rápido:**
```
1. Servidor Principal (Scheduler + Serviços + Worker)
```
*Recomendado para primeira instalação*

**Para cluster:**
- 1 máquina como **Servidor Principal**
- N máquinas como **Estação de Trabalho** ou **Apenas Worker**

### 3. ⏳ Aguardar Instalação
O script automaticamente:
- Instala dependências do sistema
- Configura Docker e containers
- Instala Ollama e modelos
- Configura ambiente Python
- Configura serviços

### 4. 🌐 Acessar Serviços
Após instalação, acesse:

| Serviço | URL | Descrição |
|---------|-----|-----------|
| OpenWebUI | http://localhost:8080 | Interface web para IA |
| Dask Dashboard | http://localhost:8787 | Monitoramento do cluster |
| Ollama API | http://localhost:11434 | API de modelos |

### 5. 🧪 Testar Funcionamento

#### Testar Cluster Dask
```python
from dask.distributed import Client

# Conectar ao cluster
client = Client('localhost:8786')
print(f"Workers ativos: {len(client.scheduler_info()['workers'])}")
client.close()
```

#### Testar Ollama
```bash
# Verificar modelos instalados
ollama list

# Testar modelo
ollama run llama3 "Explique o que é IA"
```

#### Testar OpenWebUI
1. Acesse http://localhost:8080
2. Selecione um modelo (ex: llama3)
3. Faça uma pergunta!

## 🎯 Primeiros Exemplos

### Exemplo 1: Processamento Distribuído
```python
from dask.distributed import Client
import dask.array as da

# Conectar ao cluster
client = Client('localhost:8786')

# Criar array distribuído (10k x 10k)
x = da.random.random((10000, 10000), chunks=(1000, 1000))

# Operação distribuída
result = (x + x.T).mean().compute()
print(f"Resultado: {result}")

client.close()
```

### Exemplo 2: IA com Ollama
```python
import requests

def ask_ai(pergunta, modelo="llama3"):
    resposta = requests.post(
        'http://localhost:11434/api/generate',
        json={'model': modelo, 'prompt': pergunta, 'stream': False}
    )
    return resposta.json()['response']

# Usar
resposta = ask_ai("Explique blockchain para iniciantes")
print(resposta)
```

### Exemplo 3: Análise de Sentimento em Lote
```python
from dask.distributed import Client
import dask.bag as db

def analisar_sentimento(texto):
    prompt = f"Analise o sentimento: '{texto}'. Responda apenas com POSITIVO, NEGATIVO ou NEUTRO."
    return ask_ai(prompt)

# Textos para análise
textos = [
    "Adorei este produto!",
    "Qualidade horrível, não recomendo.",
    "Funciona conforme esperado."
]

# Processamento paralelo
resultados = db.from_sequence(textos).map(analisar_sentimento).compute()

for texto, sentimento in zip(textos, resultados):
    print(f"'{texto}' -> {sentimento}")
```

## ⚡ Comandos Rápidos

### Status do Sistema
```bash
# Verificar status
./install_cluster.sh --status

# Ou pelo menu
./install_cluster.sh
# depois escolha opção 6
```

### Gerenciamento de Backup
```bash
# Backup completo
./install_cluster.sh --backup

# Restaurar backup
./install_cluster.sh --restore

# Agendar backups automáticos
./install_cluster.sh --schedule
```

### Reiniciar Serviços
```bash
# Pelo menu principal, opção 7
# Ou manualmente:
pkill -f "dask-scheduler"
pkill -f "dask-worker" 
pkill -f "ollama"
./install_cluster.sh
```

## 🚨 Solução Rápida de Problemas

### Ollama não responde
```bash
# Reiniciar serviço
sudo systemctl restart ollama

# Verificar logs
journalctl -u ollama -f
```

### Portas ocupadas
```bash
# Verificar processos nas portas
sudo lsof -i :8786  # Dask Scheduler
sudo lsof -i :8787  # Dask Dashboard
sudo lsof -i :8080  # OpenWebUI
sudo lsof -i :11434 # Ollama

# Encerrar processo específico
sudo kill -9 <PID>
```

### Problemas de permissão Docker
```bash
# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# Reiniciar sessão (logout/login)
```

## 📈 Próximos Passos

1. **Adicionar mais workers**: Instale em outras máquinas
2. **Configurar TLS**: Veja [Deploy Production](deployments/production/README.md)
3. **Personalizar modelos**: Adicione modelos específicos ao Ollama
4. **Integrar com seus dados**: Conecte ao seu banco de dados
5. **Desenvolver aplicações**: Use o cluster para seus projetos

## 🔗 Links Úteis

- [Manual Completo](../manuals/INSTALACAO.md) - Instalação detalhada
- [Configuração Avançada](../manuals/CONFIGURACAO.md) - Configurações customizadas
- [Exemplos](../examples/) - Mais exemplos de código
- [Troubleshooting](../guides/TROUBLESHOOTING.md) - Solução de problemas

---

**🎉 Parabéns!** Seu cluster AI está funcionando. Agora explore as possibilidades!

**💡 Dica**: Use `./install_cluster.sh` para acessar o menu completo de gerenciamento.
