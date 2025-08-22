Manual Completo do Cluster AI
Índice
Introdução

Visão Geral do Sistema

Pré-requisitos do Sistema

Instalação e Configuração Inicial

Definição de Papéis das Máquinas

Configuração de Rede e SSH

Componentes do Cluster

IDEs e Ferramentas de Desenvolvimento

Gerenciamento e Monitoramento

Backup e Restauração

Solução de Problemas

Manutenção e Atualização

Exemplos de Uso

Considerações de Segurança

FAQ - Perguntas Frequentes

Referências e Links Úteis

Introdução
Bem-vindo ao Manual Completo do Cluster AI, uma solução integrada para processamento distribuído de Inteligência Artificial. Este sistema combina múltiplas tecnologias em uma plataforma unificada que permite aproveitar o poder de várias máquinas para executar tarefas de IA, processamento de dados e desenvolvimento de modelos de forma eficiente.

Este manual abrange desde a instalação básica até operações avançadas, incluindo backup, monitoramento e solução de problemas. Siga as instruções cuidadosamente para configurar seu cluster de forma otimizada.

Visão Geral do Sistema
O Cluster AI é uma plataforma completa que integra os seguintes componentes:

Arquitetura do Sistema
text
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
Componentes Principais
Dask: Framework para computação paralela e distribuída

OpenWebUI: Interface web para interagir com modelos de IA

Ollama: Plataforma para execução de modelos de linguagem localmente

Ambiente Python: Virtualenv com todas as bibliotecas necessárias

Múltiplas IDEs: Spyder, VSCode e PyCharm para desenvolvimento

Fluxo de Dados
O usuário desenvolve código usando uma das IDEs

As tarefas são distribuídas via Dask Scheduler

Os Workers processam as tarefas em paralelo

Modelos de IA são acessados via Ollama quando necessário

Resultados são consolidados e retornados ao usuário

A interface OpenWebUI permite interação com os modelos

Pré-requisitos do Sistema
Requisitos Mínimos
Sistema Operacional: Ubuntu 18.04+, Debian 10+, Manjaro, ou CentOS 7+

Memória RAM: 4 GB (8+ GB recomendado para processamento de IA)

Armazenamento: 20 GB de espaço livre

Conexão Internet: Estável para download de pacotes e modelos

Acesso: Sudo/root para instalação de pacotes

Requisitos Recomendados
RAM: 16+ GB para trabalhos intensivos

GPU: Compatível com CUDA para aceleração de modelos

Armazenamento: SSD para melhor performance

Rede: Local estável (1Gbps recomendado)

CPU: Múltiplos núcleos para melhor paralelização

Verificação do Sistema
Antes da instalação, verifique se seu sistema atende aos requisitos:

bash
# Verificar memória
free -h

# Verificar espaço em disco
df -h

# Verificar versão do sistema
cat /etc/os-release

# Verificar conexão com internet
ping -c 4 google.com

# Verificar arquitetura da CPU
lscpu

# Verificar GPU (se disponível)
nvidia-smi  # Para NVIDIA
lspci | grep -i vga  # Para outras GPUs
Preparação do Ambiente
Atualize o sistema: sudo apt update && sudo apt upgrade (Ubuntu/Debian)

Instale git: sudo apt install git

Crie um usuário dedicado (opcional mas recomendado):

bash
sudo adduser clusteruser
sudo usermod -aG sudo clusteruser
su - clusteruser
Instalação e Configuração Inicial
Download do Script
bash
# Baixar o script de instalação
wget -O install_cluster_ai.sh https://raw.githubusercontent.com/Dagoberto-Candeias/appmotorista/main/install_cluster_ai.sh

# Tornar o script executável
chmod +x install_cluster_ai.sh
Execução do Script
bash
# Executar o script
./install_cluster_ai.sh
Fluxo de Instalação
O script seguirá este fluxo automaticamente:

Detecção da distribuição: Identifica seu sistema operacional

Instalação de dependências: Instala todos os pacotes necessários

Configuração do ambiente Python: Cria virtualenv e instala bibliotecas

Configuração do SSH: Gera chaves e configura acesso seguro

Definição de papéis: Pergunta como você quer configurar a máquina

Verificação da Instalação
Após a instalação, verifique se tudo foi configurado corretamente:

bash
# Verificar ambiente Python
source ~/cluster_env/bin/activate
python --version
pip list | grep -E "dask|numpy|pandas|scipy"
deactivate

# Verificar Docker
docker --version
docker ps

# Verificar Ollama
ollama --version

# Verificar IDEs (se instaladas)
code --version
spyder --version  # Necessário ativar o ambiente primeiro
Configuração Pós-Instalação
Configure o e-mail (opcional para notificações):

bash
echo "sua-senha-app" | gpg --symmetric --cipher-algo AES256 -o ~/.gmail_pass.gpg
echo "Teste" | mail -s "Teste Cluster" seu-email@gmail.com
Baixe modelos Ollama:

bash
ollama pull llama2
ollama pull codellama
Teste o cluster:

python
# test_cluster.py
from dask.distributed import Client
client = Client('localhost:8786')  # Use o IP do scheduler se diferente
print(f"Workers ativos: {len(client.scheduler_info()['workers'])}")
print(f"Recursos disponíveis: {client.ncores()}")
client.close()
Definição de Papéis das Máquinas
Tipos de Papéis Disponíveis
1. Servidor Principal (Scheduler + Serviços + Worker)
Função: Coordena todo o cluster e também participa do processamento

Serviços: Dask Scheduler, OpenWebUI, Ollama, Dask Worker

Recomendado para: Máquinas mais potentes ou sempre ligadas

Configuração de IP: Usa "localhost" (não precisa de IP externo)

2. Estação de Trabalho (Worker + IDEs)
Função: Desenvolvimento e processamento

Serviços: Dask Worker, IDEs (Spyder, VSCode, PyCharm)

Recomendado para: Máquinas de desenvolvimento

Configuração de IP: Precisa do IP do servidor principal

3. Apenas Worker (Processamento)
Função: Apenas processamento

Serviços: Dask Worker

Recomendado para: Máquinas dedicadas a processamento

Configuração de IP: Precisa do IP do servidor principal

4. Transformar Estação em Servidor
Função: Converter uma estação em servidor completo

Serviços: Adiciona scheduler e serviços à estação existente

Recomendado para: Expansão do cluster

Configuração de IP: Usa "localhost" (não precisa de IP externo)

Como Escolher o Papel Correto
Para a Primeira Máquina do Cluster
bash
# Escolha a opção 1 (Servidor Principal)
# Esta máquina será o coordenador do cluster
Para Máquinas de Desenvolvimento
bash
# Escolha a opção 2 (Estação de Trabalho)
# Informe o IP do servidor principal quando solicitado
Para Máquinas de Processamento Dedicado
bash
# Escolha a opção 3 (Apenas Worker)
# Informe o IP do servidor principal quando solicitado
Para Expandir o Cluster
bash
# Escolha a opção 4 (Transformar Estação em Servidor)
# Esta máquina se tornará um servidor adicional
Configuração de Múltiplas Máquinas
Exemplo de Configuração Típica
Servidor Principal: 192.168.1.100 (papel: Servidor Principal)

Estação de Desenvolvimento: 192.168.1.101 (papel: Estação de Trabalho)

Worker Dedicado 1: 192.168.1.102 (papel: Apenas Worker)

Worker Dedicado 2: 192.168.1.103 (papel: Apenas Worker)

Script de Implantação Automática
Crie um script deploy_cluster.sh para automatizar a implantação:

bash
#!/bin/bash
SERVER_IP="192.168.1.100"
WORKERS=("192.168.1.101" "192.168.1.102" "192.168.1.103")

echo "Implantando cluster..."

# Configurar scheduler
echo "Configurando scheduler em $SERVER_IP"
ssh usuario@$SERVER_IP "nohup ~/cluster_scripts/start_scheduler.sh > ~/scheduler.log 2>&1 &"

# Configurar workers
for worker_ip in "${WORKERS[@]}"; do
    echo "Configurando worker em $worker_ip"
    ssh usuario@$worker_ip "nohup ~/cluster_scripts/start_worker.sh $SERVER_IP > ~/worker.log 2>&1 &"
done

echo "Cluster implantado. Verifique o status:"
echo "Dashboard: http://$SERVER_IP:8787"
Configuração de Rede e SSH
O Desafio dos IPs Dinâmicos
Em redes com DHCP, os endereços IP podem mudar periodicamente, o que afeta a conectividade do cluster.

Soluções Implementadas
1. Reconexão Automática
Os workers tentam reconectar automaticamente se o scheduler não estiver disponível:

bash
# Script de reconexão automática
while true; do
    if nc -z -w 5 $SERVER_IP 8786; then
        dask-worker $SERVER_IP:8786
        break
    else
        sleep 10
    fi
done
2. Uso de Nomes de Host
Configure nomes de host consistentes na rede local:

bash
# Editar /etc/hostname para definir um nome único
sudo nano /etc/hostname

# Editar /etc/hosts para mapear nomes para IPs
sudo nano /etc/hosts
# Adicionar: 192.168.1.100 server-cluster
3. Configuração de IP Estático (Recomendado)
Para o servidor principal, configure um IP estático:

Ubuntu/Debian:

bash
# Editar configurações de rede
sudo nano /etc/netplan/01-netcfg.yaml

# Exemplo de configuração
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses: [192.168.1.100/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
Manjaro:

bash
# Usar nmtui para configuração de rede
sudo nmtui
Configuração de SSH
Geração de Chaves SSH
O script gera automaticamente chaves SSH se não existirem:

bash
# Chaves são armazenadas em ~/.ssh/
# Pública: ~/.ssh/id_rsa.pub
# Privada: ~/.ssh/id_rsa (permissões 600)
Troca de Chaves Públicas
Para comunicação sem senha entre máquinas:

Na máquina A:

bash
cat ~/.ssh/id_rsa.pub
Na máquina B:

bash
# Colar a chave pública no authorized_keys
echo "CHAVE_PUBLICA" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
Configuração de Segurança SSH
bash
# Editar configurações de segurança
sudo nano /etc/ssh/sshd_config

# Configurações recomendadas:
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
Teste de Conexão SSH
bash
# Testar conexão sem senha
ssh usuario@ip_maquina_remota

# Verificar se a conexão foi bem-sucedida
Verificação de Conectividade
bash
# Verificar IP atual
hostname -I

# Testar conectividade com o servidor
ping -c 4 IP_DO_SERVIDOR

# Testar porta do scheduler
nc -zv IP_DO_SERVIDOR 8786
Componentes do Cluster
Dask - Processamento Distribuído
Configuração do Scheduler
bash
# Iniciar scheduler manualmente
source ~/cluster_env/bin/activate
dask-scheduler --host 0.0.0.0 --port 8786 --dashboard --dashboard-address 0.0.0.0:8787
Configuração do Worker
bash
# Iniciar worker manualmente
source ~/cluster_env/bin/activate
dask-worker IP_DO_SCHEDULER:8786 --nworkers auto --nthreads 2 --name NOME_DA_MAQUINA
Exemplo de Código com Dask
python
from dask.distributed import Client
import dask.array as da

# Conectar ao cluster
client = Client('IP_DO_SCHEDULER:8786')

# Criar array distribuído
x = da.random.random((10000, 10000), chunks=(1000, 1000))

# Operação distribuída
y = x + x.T
z = y.mean()

# Executar computação
result = z.compute()
print(result)
OpenWebUI - Interface Web
Acesso e Configuração
bash
# Acessar a interface
http://IP_DO_SERVIDOR:8080

# Ver logs do container
docker logs open-webui

# Reiniciar o serviço
docker restart open-webui
Configuração de Modelos
Acesse a interface web

Vá para as configurações de modelo

Adicione modelos Ollama disponíveis

Ollama - Modelos de Linguagem
Gerenciamento de Modelos
bash
# Listar modelos disponíveis
ollama list

# Baixar um modelo
ollama pull llama2

# Executar um modelo
ollama run llama2

# Verificar status
curl http://localhost:11434/api/tags
Integração com Python
python
import requests
import json

def ask_ollama(prompt, model="llama2"):
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
IDEs e Ferramentas de Desenvolvimento
Spyder
bash
# Iniciar Spyder com o ambiente do cluster
source ~/cluster_env/bin/activate
spyder
Visual Studio Code
bash
# Iniciar VSCode
code .

# Configurar o interpretador Python
# Selecione: ~/cluster_env/bin/python
PyCharm
bash
# Iniciar PyCharm
/opt/pycharm/bin/pycharm.sh

# Configurar interpretador remoto
# Settings > Project > Python Interpreter
Configuração do Ambiente de Desenvolvimento
Para Spyder
Configure o interpretador para usar o ambiente virtual:

python
# No console do Spyder
import sys
sys.executable
# Deve apontar para ~/cluster_env/bin/python
Para VSCode
Crie um arquivo .vscode/settings.json:

json
{
    "python.defaultInterpreterPath": "~/cluster_env/bin/python",
    "python.analysis.extraPaths": [
        "~/cluster_env/lib/python3.*/site-packages"
    ]
}
Para PyCharm
Configure o interpretador em:

Settings -> Project -> Python Interpreter

Add Interpreter -> Existing Environment

Path: ~/cluster_env/bin/python

Gerenciamento e Monitoramento
Dashboard Dask
Acesse o dashboard em: http://IP_DO_SERVIDOR:8787

Funcionalidades do dashboard:

Monitoramento de tarefas em tempo real

Visualização de utilização de recursos

Informações sobre workers conectados

Logs de execução

Comandos de Gerenciamento
Verificar Status dos Serviços
bash
# Verificar scheduler
ps aux | grep dask-scheduler

# Verificar workers
ps aux | grep dask-worker

# Verificar Ollama
ps aux | grep ollama

# Verificar Docker
docker ps
Reiniciar Serviços
bash
# Parar todos os serviços
pkill -f "dask-scheduler"
pkill -f "dask-worker"
pkill -f "ollama"

# Reiniciar via script
~/cluster_scripts/start_scheduler.sh
~/cluster_scripts/start_worker.sh IP_DO_SERVIDOR
Verificação de Logs
bash
# Logs do scheduler
tail -f ~/scheduler.log

# Logs do worker
tail -f ~/worker.log

# Logs do Ollama
tail -f ~/ollama.log

# Logs do OpenWebUI
docker logs open-webui
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
Backup e Restauração
Tipos de Backup
1. Backup Completo
Inclui todos os componentes do cluster:

Configurações do cluster (~/.cluster_role)

Scripts de gerenciamento (~/cluster_scripts)

Modelos Ollama (~/.ollama)

Dados do OpenWebUI (~/open-webui)

Chaves SSH (~/.ssh)

Ambiente virtual Python (~/cluster_env)

2. Backup de Modelos Ollama
Apenas os modelos de linguagem baixados:

Todos os modelos em ~/.ollama

Ideal para preservar modelos grandes que demoraram para baixar

3. Backup de Configurações
Apenas as configurações do cluster:

Arquivo de configuração (~/.cluster_role)

Scripts de gerenciamento (~/cluster_scripts)

Chaves SSH (~/.ssh)

4. Backup de Dados do OpenWebUI
Apenas os dados da interface web:

Conversas e configurações do OpenWebUI

Dados armazenados em ~/open-webui

Como Fazer Backup
Pelo Menu Interativo
bash
# Executar o script
./install_cluster_ai.sh

# No menu principal, selecione a opção 8 (Backup e Restauração)
# Em seguida, selecione a opção 1 (Fazer backup)
Pela Linha de Comando
bash
# Backup interativo
./install_cluster_ai.sh --backup

# Backup automático (para agendamento)
./install_cluster_ai.sh --backup --auto
Exemplo de Backup Completo
bash
# O backup será criado em: ~/cluster_backups/cluster_backup_20231201_143022.tar.gz
# O nome inclui data e hora para fácil identificação
Como Restaurar Backup
Pelo Menu Interativo
bash
# Executar o script
./install_cluster_ai.sh

# No menu principal, selecione a opção 8 (Backup e Restauração)
# Em seguida, selecione a opção 2 (Restaurar backup)
Pela Linha de Comando
bash
# Restaurar backup
./install_cluster_ai.sh --restore
Processo de Restauração
O script lista todos os backups disponíveis

Selecione o backup que deseja restaurar

Confirme a operação (os arquivos atuais serão substituídos)

O backup será extraído para os locais originais

Após a Restauração
Se restaurou configurações, reinicie os serviços

Se restaurou modelos Ollama, verifique se estão disponíveis:

bash
ollama list
Backups Automáticos
Agendamento de Backups
bash
# Executar o script
./install_cluster_ai.sh

# No menu principal, selecione a opção 8 (Backup e Restauração)
# Em seguida, selecione a opção 3 (Agendar backups automáticos)
Opções de Agendamento
Diário: Executa todos os dias às 2:00 AM

Semanal: Executa todo domingo às 2:00 AM

Mensal: Executa no primeiro dia do mês às 2:00 AM

Verificar Agendamentos
bash
# Verificar agendamentos ativos
crontab -l

# A entrada será similar a:
# 0 2 * * * /caminho/completo/install_cluster_ai.sh --backup --auto
Remover Agendamentos
bash
# Pelo menu interativo
# Ou manualmente: crontab -e
# Remova a linha correspondente ao script
Estrutura de Arquivos de Backup
Conteúdo do Backup Completo
text
~/cluster_backups/
├── cluster_backup_20231201_143022.tar.gz
├── ollama_models_20231201_150045.tar.gz
└── cluster_config_20231201_151022.tar.gz
Conteúdo dos Arquivos de Backup
cluster_backup_*.tar.gz: Contém todos os componentes

ollama_models_*.tar.gz: Contém apenas ~/.ollama

cluster_config_*.tar.gz: Contém configurações e scripts

openwebui_data_*.tar.gz: Contém apenas dados do OpenWebUI

Localização dos Backups
Por padrão, os backups são armazenados em ~/cluster_backups/
Para alterar o diretório:

bash
# Pelo menu interativo: Opção 8 → Opção 4
# Ou edite ~/.cluster_role e modifique BACKUP_DIR
Solução de Problemas
Problemas Comuns e Soluções
1. Conexão com o Scheduler
Problema: Worker não consegue conectar ao scheduler
Solução:

bash
# Verificar se o scheduler está rodando
ps aux | grep dask-scheduler

# Verificar conectividade de rede
ping IP_DO_SCHEDULER
nc -zv IP_DO_SCHEDULER 8786

# Verificar firewall
sudo ufw status
sudo ufw allow 8786
2. Portas Ocupadas
Problema: Erro de porta já em uso
Solução:

bash
# Verificar processos usando a porta
sudo lsof -i :8786

# Encerrar processo específico
sudo kill -9 PID_DO_PROCESSO

# Ou configurar para usar porta diferente
dask-scheduler --port 8787
3. Problemas de Permissão
Problema: Erros de permissão com Docker ou arquivos
Solução:

bash
# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# Verificar permissões de arquivos
chmod 600 ~/.ssh/*
chmod 700 ~/.ssh
4. IP do Servidor Mudou
Problema: Workers não conseguem mais conectar
Solução:

bash
# Atualizar IP no arquivo de configuração
nano ~/.cluster_role
# Alterar SERVER_IP para o novo IP

# Ou reconfigurar a máquina
./install_cluster_ai.sh
Diagnóstico Avançado
Verificar Status do Cluster
python
from dask.distributed import Client

try:
    client = Client('IP_DO_SCHEDULER:8786')
    print(f"Workers ativos: {len(client.scheduler_info()['workers'])}")
    print(f"Recursos disponíveis: {client.ncores()}")
except Exception as e:
    print(f"Erro ao conectar: {e}")
Teste de Performance
python
import dask.array as da
from dask.distributed import Client
import time

client = Client('IP_DO_SCHEDULER:8786')

# Teste de performance
start = time.time()
x = da.random.random((10000, 10000), chunks=(1000, 1000))
y = x + x.T
z = y.mean()
result = z.compute()
end = time.time()

print(f"Tempo de execução: {end - start:.2f} segundos")
Manutenção e Atualização
Atualização do Sistema
bash
# Atualizar dependências do sistema
sudo apt update && sudo apt upgrade  # Ubuntu/Debian
sudo pacman -Syu                    # Manjaro
sudo yum update                     # CentOS

# Atualizar ambiente Python
source ~/cluster_env/bin/activate
pip install --upgrade pip
pip install --upgrade "dask[complete]" distributed numpy pandas scipy
deactivate
Atualização de Serviços
bash
# Atualizar OpenWebUI
docker pull ghcr.io/open-webui/open-webui:main
docker stop open-webui
docker rm open-webui
docker run -d --name open-webui -p 8080:8080 -v $HOME/open-webui:/app/data ghcr.io/open-webui/open-webui:main

# Atualizar Ollama
curl -fsSL https://ollama.com/install.sh | sh
Backup e Restauração
bash
# Backup
tar -czf cluster_backup_$(date +%Y%m%d).tar.gz \
  ~/.cluster_role \
  ~/.ssh/ \
  ~/cluster_scripts/ \
  ~/cluster_env/

# Restaurar
tar -xzf cluster_backup_DATA.tar.gz -C ~/
Exemplos de Uso
Processamento de Dados em Lote
python
from dask.distributed import Client
import dask.dataframe as dd
import time

# Conectar ao cluster
client = Client('IP_DO_SCHEDULER:8786')

# Carregar dados distribuídos
df = dd.read_csv('hdfs:///dados/large_dataset*.csv')

# Processamento distribuído
start = time.time()
result = df.groupby('categoria').valor.mean().compute()
end = time.time()

print(f"Processamento concluído em {end - start:.2f} segundos")
print(result)
Treinamento Distribuído de Modelos
python
from dask_ml.model_selection import train_test_split
from dask_ml.linear_model import LogisticRegression
from dask.distributed import Client
import dask.array as da

# Conectar ao cluster
client = Client('IP_DO_SCHEDULER:8786')

# Dados distribuídos
X, y = da.random.random((100000, 100), chunks=(1000, 100)), da.random.randint(2, size=(100000,), chunks=(1000,))

# Treinamento distribuído
X_train, X_test, y_train, y_test = train_test_split(X, y)
model = LogisticRegression()
model.fit(X_train, y_train)

# Avaliação
score = model.score(X_test, y_test)
print(f"Acurácia: {score:.4f}")
Integração com Ollama para Análise de Texto
python
from dask.distributed import Client
import dask.bag as db
import requests
import json

# Conectar ao cluster
client = Client('IP_DO_SCHEDULER:8786')

# Função para análise de sentimento com Ollama
def analyze_sentiment(text):
    try:
        response = requests.post(
            'http://localhost:11434/api/generate',
            json={
                'model': 'llama2',
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
Considerações de Segurança
Melhores Práticas
Firewall: Configure para permitir apenas portas necessárias

SSH: Use apenas autenticação por chaves, não por senha

Docker: Execute containers com usuários não-root quando possível

Atualizações: Mantenha todos os componentes atualizados

Configuração de Segurança
bash
# Configurar firewall (UFW)
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 8786/tcp  # Dask Scheduler
sudo ufw allow 8787/tcp  # Dask Dashboard
sudo ufw allow 8080/tcp  # OpenWebUI
sudo ufw enable

# Verificar regras
sudo ufw status
Monitoramento de Segurança
bash
# Verificar logs de autenticação
sudo tail -f /var/log/auth.log

# Verificar conexões ativas
sudo netstat -tulpn

# Verificar processos em execução
sudo ps aux
FAQ - Perguntas Frequentes
1. Posso usar este cluster com IPs dinâmicos?
Sim, o sistema inclui mecanismos de reconexão automática para lidar com IPs dinâmicos.

2. Como adicionar mais workers ao cluster?
Basta instalar o script em uma nova máquina e configurá-la como "Apenas Worker" ou "Estação de Trabalho".

3. Posso usar GPUs para acelerar o processamento?
Sim, configure o Docker e Ollama para usar GPUs. Consulte a documentação específica para seu hardware.

4. Como faço backup dos meus modelos Ollama?
Os modelos são armazenados em ~/.ollama/. Faça backup desta pasta regularmente.

5. O cluster funciona offline?
O processamento com Dask funciona offline, mas o download de modelos Ollama requer internet.

6. Como monitorar o desempenho do cluster?
Use o dashboard Dask em http://IP_DO_SERVIDOR:8787 para monitoramento em tempo real.

7. Posso usar outros modelos além do Llama 2?
Sim, o Ollama suporta diversos modelos. Consulte a documentação do Ollama para mais opções.

8. Como escalar o cluster para mais máquinas?
Adicione mais máquinas configuradas como workers. O scheduler Dask gerencia automaticamente a distribuição de tarefas.

9. O que fazer se uma máquina ficar offline?
Os workers tentam reconectar automaticamente. Se um worker ficar offline, as tarefas são realocadas para outros workers.

10. Como personalizar a configuração do cluster?
Edite os scripts em ~/cluster_scripts/ ou modifique o arquivo ~/.cluster_role para ajustar configurações específicas.

Referências e Links Úteis
Documentação Oficial
Dask: https://docs.dask.org/

Ollama: https://ollama.ai/

OpenWebUI: https://docs.openwebui.com/

Docker: https://docs.docker.com/

Tutoriais e Guias
Introdução ao Dask

Como usar Ollama com Python

Configuração de clusters distribuídos

Suporte e Comunidade
Repositório do Projeto

Fórum de Discussão

Reportar Problemas

Ferramentas Relacionadas
JupyterLab: Para notebooks interativos

MLflow: Para acompanhamento de experimentos de ML

Prometheus + Grafana: Para monitoramento avançado

Este manual cobre todos os aspectos do sistema Cluster AI. Para questões específicas não abordadas aqui, consulte a documentação oficial de cada componente ou entre em contato através do repositório do projeto.
