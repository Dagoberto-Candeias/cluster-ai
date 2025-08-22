# Manual Completo - Cluster AI

## Introdução
Bem-vindo ao Cluster AI, um sistema completo para processamento distribuído de IA que combina Dask para computação paralela, Ollama para modelos de linguagem, OpenWebUI para interface web e várias IDEs para desenvolvimento.

## Visão Geral do Sistema
O Cluster AI é uma plataforma integrada que permite:

1. **Processamento Distribuído**: Usando Dask para distribuir tarefas entre múltiplas máquinas
2. **Modelos de IA**: Com Ollama para executar modelos de linguagem localmente
3. **Interface Web**: Com OpenWebUI para interagir com os modelos
4. **Desenvolvimento**: Com IDEs integradas (Spyder, VSCode, PyCharm)
5. **Backup Automático**: Sistema de backup e restauração integrado

### Arquitetura do Sistema
[Servidor Principal]
├── Dask Scheduler (Coordenação)
├── OpenWebUI (Interface Web)
├── Ollama (Modelos de Linguagem)
└── Dask Worker (Processamento)

[Estações de Trabalho]
├── Dask Worker (Processamento)
├── Spyder (IDE)
├── VSCode (IDE)
└── PyCharm (IDE)

[Workers Dedicados]
└── Dask Worker (Processamento)

text

## Pré-requisitos do Sistema

### Requisitos Mínimos
- Sistema Operacional: Ubuntu 18.04+, Debian 10+, Manjaro, ou CentOS 7+
- Memória RAM: 4 GB (8+ GB recomendado para processamento de IA)
- Armazenamento: 20 GB de espaço livre
- Conexão Internet: Estável para download de pacotes e modelos
- Acesso: Sudo/root para instalação de pacotes

### Requisitos Recomendados
- RAM: 16+ GB para trabalhos intensivos
- GPU: Compatível com CUDA para aceleração de modelos
- Armazenamento: SSD para melhor performance
- Rede: Local estável (1Gbps recomendado)
- CPU: Múltiplos núcleos para melhor paralelização

## Instalação e Configuração

### Instalação Rápida
```bash
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/install_cluster_ai_final.sh -o install_cluster_ai.sh
chmod +x install_cluster_ai.sh
./install_cluster_ai.sh
Definição de Papéis
Durante a instalação, você precisará definir o papel da máquina:

Servidor Principal: Coordena o cluster e hospeda serviços

Estação de Trabalho: Conecta ao servidor e inclui IDEs

Apenas Worker: Dedica-se apenas ao processamento

Transformar Estação em Servidor: Converte uma estação em servidor

Configuração do Ollama
Otimização de GPU
O script detecta automaticamente a GPU e configura o Ollama para melhor desempenho:

NVIDIA: Configuração CUDA com até 35 camadas GPU

AMD: Configuração ROCm com até 20 camadas GPU

CPU-only: Configuração otimizada para processamento apenas com CPU

Modelos Pré-instalados
O script baixa automaticamente os seguintes modelos:

llama3

deepseek-coder

mistral

llava

phi3

codellama

Verificação de Saúde
O sistema inclui verificações automáticas de saúde do Ollama:

bash
# Verificar se o Ollama está respondendo
curl http://localhost:11434/api/tags

# Verificar modelos instalados
ollama list
Backup e Restauração
Tipos de Backup
Backup Completo: Todos os componentes do cluster

Backup de Modelos Ollama: Apenos os modelos de IA

Backup de Configurações: Configurações e scripts

Backup do OpenWebUI: Dados da interface web

Agendamento Automático
Os backups podem ser agendados para:

Diário (2:00 AM)

Semanal (Domingo às 2:00 AM)

Mensal (Primeiro dia do mês às 2:00 AM)

Restauração
A restauração é feita através do menu interativo, selecionando o backup desejado.

Solução de Problemas
Problemas Comuns
Conexão com o Scheduler: Verificar firewall e conectividade de rede

Portas Ocupadas: Usar lsof para identificar processos e encerrá-los

Problemas de Permissão: Verificar grupos de usuário (especialmente Docker)

IP do Servidor Mudou: Atualizar arquivo ~/.cluster_role

Verificação de Status
Use o comando de status integrado:

bash
# No menu principal, opção 6
# Ou executar manualmente:
./install_cluster_ai.sh && show_status
Logs do Sistema
Scheduler: ~/scheduler.log

Worker: ~/worker.log

Ollama: Verificar com journalctl -u ollama

OpenWebUI: docker logs open-webui

Exemplos de Uso
Processamento Distribuído com Dask
python
from dask.distributed import Client
import dask.array as da

# Conectar ao cluster
client = Client('IP_DO_SERVIDOR:8786')

# Criar array distribuído
x = da.random.random((10000, 10000), chunks=(1000, 1000))

# Operação distribuída
y = x + x.T
z = y.mean()

# Executar computação
result = z.compute()
print(result)
Integração com Ollama
python
import requests

def ask_ollama(prompt, model="llama3"):
    response = requests.post(
        'http://localhost:11434/api/generate',
        json={
            'model': model,
            'prompt': prompt,
            'stream': False
        }
    )
    return response.json()['response']

# Exemplo de uso
resposta = ask_ollama("Explique o que é machine learning")
print(resposta)
Processamento Distribuído com IA
python
from dask.distributed import Client
import dask.bag as db
import requests

# Função para análise de sentimento com Ollama
def analyze_sentiment(text):
    try:
        response = requests.post(
            'http://localhost:11434/api/generate',
            json={
                'model': 'llama3',
                'prompt': f'Analise o sentimento deste texto: "{text}". Responda apenas com POSITIVO, NEGATIVO ou NEUTRO.',
                'stream': False
            }
        )
        return response.json()['response'].strip()
    except:
        return "ERRO"

# Dados de texto para análise
texts = [
    "Adorei este produto, é incrível!",
    "Péssima qualidade, não recomendo.",
    "Funciona conforme esperado."
]

# Processamento distribuído
bag = db.from_sequence(texts, npartitions=2)
results = bag.map(analyze_sentiment).compute()

for text, sentiment in zip(texts, results):
    print(f"Texto: {text} | Sentimento: {sentiment}")
Manutenção e Atualização
Atualização do Sistema
bash
# Atualizar dependências do sistema
sudo apt update && sudo apt upgrade

# Atualizar ambiente Python
source ~/cluster_env/bin/activate
pip install --upgrade pip
pip install --upgrade "dask[complete]" distributed numpy pandas scipy
deactivate

# Atualizar OpenWebUI
docker pull ghcr.io/open-webui/open-webui:main
docker stop open-webui
docker rm open-webui
docker run -d --name open-webui -p 8080:8080 -v $HOME/open-webui:/app/data ghcr.io/open-webui/open-webui:main

# Atualizar Ollama
curl -fsSL https://ollama.com/install.sh | sh
Monitoramento de Recursos
bash
# Verificar uso de CPU
top

# Verificar uso de memória
free -h

# Verificar uso de disco
df -h

# Verificar uso de rede
iftop

# Dashboard Dask
http://IP_DO_SERVIDOR:8787
Considerações de Segurança
Melhores Práticas
Firewall: Configure para permitir apenas portas necessárias

SSH: Use apenas autenticação por chaves

Docker: Execute containers com usuários não-root

Atualizações: Mantenha todos os componentes atualizados

Configuração de Segurança
bash
# Configurar firewall (UFW)
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 8786/tcp  # Dask Scheduler
sudo ufw allow 8787/tcp  # Dask Dashboard
sudo ufw allow 8080/tcp  # OpenWebUI
sudo ufw allow 11434/tcp # Ollama API
sudo ufw enable
FAQ - Perguntas Frequentes
1. Posso usar este cluster com IPs dinâmicos?
Sim, o sistema inclui mecanismos de reconexão automática para lidar com IPs dinâmicos.

2. Como adicionar mais workers ao cluster?
Basta instalar o script em uma nova máquina e configurá-la como "Apenas Worker".

3. Posso usar GPUs para acelerar o processamento?
Sim, o sistema detecta automaticamente GPUs NVIDIA e AMD e configura o Ollama para usá-las.

4. Como faço backup dos meus modelos Ollama?
Os modelos são incluídos no backup completo ou podem ser backupados separadamente.

5. O cluster funciona offline?
O processamento com Dask funciona offline, mas o download de modelos Ollama requer internet.

Referências e Links Úteis
Dask: https://docs.dask.org/

Ollama: https://ollama.ai/

OpenWebUI: https://docs.openwebui.com/

Docker: https://docs.docker.com/

Repositório: https://github.com/Dagoberto-Candeias/cluster-ai

Este manual cobre todos os aspectos do sistema Cluster AI. Para questões específicas não abordadas aqui, consulte a documentação oficial de cada componente ou entre em contato através do repositório do projeto.

text

## Guia Rápido (`quick_start.md`)

```markdown
# Guia Rápido - Cluster AI

## Instalação em 3 Passos

1. **Baixe o script**:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/install_cluster_ai_final.sh -o install_cluster_ai.sh
Torne executável:

bash
chmod +x install_cluster_ai.sh
Execute:

bash
./install_cluster_ai.sh
Comandos Rápidos
Verificar Status
bash
./install_cluster_ai.sh && show_status
Backup
bash
./install_cluster_ai.sh --backup
Restaurar
bash
./install_cluster_ai.sh --restore
Agendar Backups
bash
./install_cluster_ai.sh --schedule
URLs Importantes
OpenWebUI: http://localhost:8080

Dask Dashboard: http://localhost:8787

Ollama API: http://localhost:11434

Primeiros Passos
Defina o papel da máquina durante a instalação

Configure o e-mail para notificações (opcional)

Teste o cluster com um script Python simples

Acesse o OpenWebUI para interagir com os modelos

Solução Rápida de Problemas
Se encontrar problemas:

Verifique os logs em ~/scheduler.log e ~/worker.log

Execute ./install_cluster_ai.sh para reconfigurar

Consulte a seção de troubleshooting do manual completo

text

Este script final e manual completo incorporam todas as melhorias sugeridas, com foco especial na integração e otimização do Ollama, sistema de backup robusto e documentação abrangente.
