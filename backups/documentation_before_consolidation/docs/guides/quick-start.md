# 🚀 Guia de Início Rápido - Cluster AI

## 📋 Visão Geral

Este guia fornece instruções rápidas para começar a usar o Cluster AI em minutos. Se você é novo no projeto, siga estes passos para ter um ambiente funcional rapidamente.

## ⚡ Instalação Expressa

### Pré-requisitos
- Linux (Ubuntu/Debian/Fedora/Arch)
- Pelo menos 4GB RAM e 20GB espaço
- Conexão com internet

### Comando Único de Instalação
```bash
# Clone e instale automaticamente
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
cd cluster-ai
bash install.sh --auto-role
```

O instalador irá:
- ✅ Detectar seu hardware automaticamente
- ✅ Instalar todas as dependências do sistema
- ✅ Configurar Python, Ollama e OpenWebUI
- ✅ Iniciar todos os serviços

### Verificação da Instalação
```bash
# Verificar se tudo está funcionando
./manager.sh --status
```

## 🛠️ Primeiro Uso

### 1. Acesse as Interfaces Web
Após a instalação, acesse:
- **OpenWebUI** (Interface IA): http://localhost:3000
- **Dask Dashboard** (Monitoramento): http://localhost:8787
- **Ollama API**: http://localhost:11434

### 2. Baixe um Modelo de IA
```bash
# Modelo recomendado para começar
ollama pull llama3:8b

# Teste o modelo
ollama run llama3:8b "Olá! Explique o que é machine learning em uma frase."
```

### 3. Teste o Processamento Distribuído
```python
# Crie um arquivo test_cluster.py
from dask.distributed import Client
import dask.array as da

# Conectar ao cluster
client = Client('localhost:8786')

# Criar array grande distribuído
x = da.random.random((5000, 5000), chunks=(1000, 1000))
resultado = (x + x.T).mean().compute()

print(f"Processamento distribuído funcionando! Resultado: {resultado}")
client.close()
```

Execute:
```bash
python test_cluster.py
```

## 🎯 Casos de Uso Rápidos

### Desenvolvimento com IA
```bash
# Baixar modelo de programação
ollama pull deepseek-coder-v2:16b

# Usar no terminal
ollama run deepseek-coder-v2:16b "Crie uma função Python para calcular fibonacci recursivamente"
```

### Ciência de Dados
```python
import dask.dataframe as dd
import pandas as pd

# Processar arquivo grande com Dask
df = dd.read_csv('dados_grandes.csv')
resultado = df.groupby('categoria')['valor'].mean().compute()
print(resultado)
```

### Automação de Tarefas
```bash
# Usar manager.sh para controle completo
./manager.sh

# Opções principais:
# 1. Iniciar todos os serviços
# 2. Verificar status do sistema
# 3. Gerenciar workers remotos
# 4. Executar backup
# 5. Otimizar recursos
```

## 🔧 Configurações Essenciais

### Para GPU NVIDIA
```bash
# Verificar GPU
nvidia-smi

# Configurar Ollama para usar GPU
echo 'export OLLAMA_GPU_LAYERS=35' >> ~/.bashrc
source ~/.bashrc
```

### Para GPU AMD
```bash
# Verificar GPU AMD
rocm-smi

# Configurar camadas GPU
export OLLAMA_GPU_LAYERS=20
```

### Rede e Segurança
```bash
# Abrir portas necessárias (se firewall ativo)
sudo ufw allow 3000/tcp  # OpenWebUI
sudo ufw allow 8786/tcp  # Dask Scheduler
sudo ufw allow 8787/tcp  # Dask Dashboard
sudo ufw allow 11434/tcp # Ollama API
```

## 📊 Monitoramento Básico

### Verificar Status dos Serviços
```bash
# Status completo
./scripts/utils/health_check.sh

# Apenas processos principais
ps aux | grep -E "(dask|ollama|openwebui)"
```

### Logs Importantes
```bash
# Logs do sistema
journalctl -u ollama -f

# Logs Docker (se usando containers)
docker logs openwebui

# Logs Dask
tail -f ~/.dask-worker.log
```

## 🚨 Solução de Problemas Rápida

### Serviço Não Inicia
```bash
# Reiniciar tudo
./manager.sh
# Selecionar opção 1 (Iniciar Serviços)
```

### Modelo Não Carrega
```bash
# Verificar modelos disponíveis
ollama list

# Remover e baixar novamente
ollama rm llama3:8b
ollama pull llama3:8b
```

### Porta Ocupada
```bash
# Verificar quem está usando a porta
sudo lsof -i :3000

# Matar processo se necessário
sudo kill -9 <PID>
```

### Memória Insuficiente
```bash
# Verificar uso de memória
free -h

# Usar modelo menor
ollama pull llama3:8b  # Em vez de 70b
```

## 📚 Próximos Passos

### Para Usuários Iniciantes
1. ✅ **Instalação completa** - Feito!
2. 🔄 **Explorar interfaces web** - OpenWebUI e Dask Dashboard
3. 🔄 **Experimentar diferentes modelos** - Teste vários tamanhos
4. 🔄 **Ler documentação específica** - docs/manuals/INSTALACAO.md

### Para Usuários Avançados
1. ✅ **Instalação completa** - Feito!
2. 🔄 **Configurar workers remotos** - Adicione mais máquinas
3. 🔄 **Otimizar para produção** - TLS, backup, monitoramento
4. 🔄 **Integrar com aplicações** - API REST e SDKs

### Para Desenvolvedores
1. ✅ **Instalação completa** - Feito!
2. 🔄 **Ver código fonte** - scripts/ e examples/
3. 🔄 **Contribuir** - Leia CONTRIBUTING.md
4. 🔄 **Executar testes** - ./run_tests.sh

## 🎯 Exemplos Práticos por Área

### Machine Learning
```python
from dask_ml.model_selection import train_test_split
from dask_ml.linear_model import LinearRegression
import dask.dataframe as dd

# Dados distribuídos
df = dd.read_csv('dados_ml.csv')
X_train, X_test, y_train, y_test = train_test_split(df.drop('target', axis=1), df['target'])

# Modelo distribuído
model = LinearRegression()
model.fit(X_train, y_train)
score = model.score(X_test, y_test)
print(f"Acurácia: {score}")
```

### Processamento de Texto
```python
import dask.bag as db
from ollama import Client

def analisar_sentimento(texto):
    client = Client()
    response = client.chat(
        model='llama3:8b',
        messages=[{'role': 'user', 'content': f'Analise o sentimento: {texto}'}]
    )
    return response['message']['content']

# Processamento paralelo
textos = ['Texto positivo', 'Texto negativo', 'Texto neutro']
resultados = db.from_sequence(textos).map(analisar_sentimento).compute()
```

### Análise de Dados
```python
import dask.dataframe as dd
import matplotlib.pyplot as plt

# Dados grandes
df = dd.read_csv('dados_analise.csv')

# Análise distribuída
estatisticas = df.describe().compute()
correlacao = df.corr().compute()

# Visualização
estatisticas.plot(kind='bar')
plt.savefig('estatisticas.png')
```

## 🔗 Recursos Adicionais

### Documentação Completa
- **[Manual de Instalação](docs/manuals/INSTALACAO.md)** - Detalhes completos
- **[Guia de Desenvolvimento](docs/guides/development-plan.md)** - Para contribuidores
- **[Manual do Ollama](docs/manuals/ollama/)** - Modelos e configurações
- **[Backup e Restauração](docs/manuals/BACKUP.md)** - Estratégias de backup

### Comunidade e Suporte
- **GitHub Issues**: Para bugs e solicitações
- **Discussions**: Para perguntas gerais
- **Wiki**: Tutoriais e exemplos avançados

### Configurações Avançadas
- **Produção com TLS**: deployments/production/
- **Workers Android**: docs/manuals/ANDROID.md
- **Otimização de Performance**: scripts/optimization/

---

## 🎉 Parabéns!

Você concluiu o guia de início rápido! Agora você tem:
- ✅ Cluster AI instalado e funcionando
- ✅ Interfaces web acessíveis
- ✅ Modelo de IA baixado e testado
- ✅ Processamento distribuído operacional
- ✅ Conhecimento básico para próximos passos

**Próximo**: Explore a documentação completa em `docs/` ou experimente os exemplos em `examples/`.

**Precisa de ajuda?** Abra uma issue no GitHub ou consulte os manuais em `docs/manuals/`.

---

*Última atualização: $(date +%Y-%m-%d)*
*Versão: 1.0.0*
