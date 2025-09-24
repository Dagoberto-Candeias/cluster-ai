# Sistema Multi-Plataforma - Workers Cluster AI

Este sistema permite configurar e testar workers do Cluster AI em múltiplas plataformas automaticamente.

## Plataformas Suportadas

- **Termux** (Android)
- **Debian** (Linux)
- **Manjaro** (Linux)
- **Ubuntu** (Linux)
- **CentOS** (Linux)
- **Arch Linux**
- **Outras distribuições Linux**

## Scripts Disponíveis

### 1. `detect_platform.sh`
Detecta automaticamente a plataforma onde está rodando.

```bash
bash scripts/workers/detect_platform.sh
```

### 2. `setup_worker_multiplatform.sh`
Configura automaticamente o worker para a plataforma detectada.

```bash
bash scripts/workers/setup_worker_multiplatform.sh
```

### 3. `test_worker_multiplatform.sh`
Testa se o worker está configurado corretamente.

```bash
bash scripts/workers/test_worker_multiplatform.sh
```

### 4. `worker_config.sh`
Exibe as configurações atuais do worker.

```bash
bash scripts/workers/worker_config.sh
```

## Como Usar

### Configuração Automática

1. **Clone o projeto** (se ainda não fez):
   ```bash
   git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
   cd cluster-ai
   ```

2. **Execute o setup**:
   ```bash
   bash scripts/workers/setup_worker_multiplatform.sh
   ```

3. **Teste a configuração**:
   ```bash
   bash scripts/workers/test_worker_multiplatform.sh
   ```

### Configuração Manual por Plataforma

#### Termux (Android)

1. Instale o Termux no seu dispositivo Android
2. Execute no Termux:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/workers/setup_worker_multiplatform.sh | bash
   ```

#### Linux (Debian/Ubuntu)

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências
sudo apt install -y openssh-server python3 python3-pip git

# Executar setup
bash scripts/workers/setup_worker_multiplatform.sh
```

#### Linux (Manjaro/Arch)

```bash
# Atualizar sistema
sudo pacman -Syu

# Instalar dependências
sudo pacman -S openssh python python-pip git

# Executar setup
bash scripts/workers/setup_worker_multiplatform.sh
```

## Funcionalidades

### Detecção Automática
- Identifica automaticamente a plataforma
- Adapta comandos e configurações
- Otimizações específicas por plataforma

### Configuração SSH
- Gera chaves SSH automaticamente
- Configura servidor SSH na porta 8022
- Funciona em todas as plataformas

### Instalação Dask
- Instala Dask Distributed automaticamente
- Configura worker com otimizações
- Dashboard web incluído

### Testes Completos
- Verifica todas as dependências
- Testa conectividade SSH
- Valida configuração do projeto
- Testa conectividade de rede

## Configurações

### Portas Padrão
- SSH: 8022
- Dask Scheduler: 8786
- Dask Dashboard: 8787

### Recursos do Worker
- Memória: 2GB (configurável)
- Threads: 2 (configurável)
- Dashboard: Habilitado

## Solução de Problemas

### SSH não funciona
```bash
# Verificar se SSH está rodando
sudo systemctl status ssh

# Reiniciar SSH
sudo systemctl restart ssh

# Verificar logs
sudo journalctl -u ssh -f
```

### Dask não inicia
```bash
# Verificar instalação do Python
python3 --version

# Reinstalar Dask
pip install --upgrade dask[distributed]

# Verificar se há conflitos de porta
netstat -tlnp | grep 8786
```

### Problemas de rede
```bash
# Testar conectividade
ping 8.8.8.8

# Verificar IP local
ip route get 1 | awk '{print $7}'
```

## Próximos Passos

1. **Configure no servidor principal**:
   ```bash
   ./manager.sh
   # Escolha: Configurar Cluster > Gerenciar Workers Remotos
   ```

2. **Registre o worker**:
   - Copie a chave SSH pública mostrada no final do setup
   - Cole no servidor quando solicitado
   - Digite o IP e porta do worker

3. **Teste a conexão**:
   - O servidor deve conseguir conectar via SSH
   - O worker deve aparecer como disponível

## Suporte

Para problemas ou dúvidas:
1. Execute o teste: `bash scripts/workers/test_worker_multiplatform.sh`
2. Verifique os logs em `logs/`
3. Consulte a documentação específica da sua plataforma

---

**Versão**: 1.0.0
**Última atualização**: 2025-09-23
**Autor**: Cluster AI Team
