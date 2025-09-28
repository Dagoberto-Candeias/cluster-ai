# Sistema Plug-and-Play de Workers - Cluster AI

## Visão Geral

Este documento descreve o novo sistema plug-and-play implementado para facilitar a instalação e conexão automática de workers no Cluster AI. O sistema permite que workers sejam detectados automaticamente na rede e registrados no servidor sem intervenção manual.

## Funcionalidades Implementadas

### ✅ 1. Scripts de Instalação Automática

#### Worker Android (Termux)
- **Arquivo**: `scripts/android/setup_android_worker.sh`
- **Funcionalidades**:
  - Detecção automática de servidor na rede
  - Geração automática de chaves SSH
  - Registro automático no servidor
  - Suporte a mDNS/Bonjour para descoberta
  - Fallback para escaneamento de rede local

#### Worker Genérico (Linux/Unix)
- **Arquivo**: `scripts/installation/setup_generic_worker.sh`
- **Funcionalidades**:
  - Detecção automática de gerenciador de pacotes
  - Instalação automática de dependências
  - Configuração SSH automática
  - Registro automático no servidor
  - Suporte multiplataforma (apt, yum, dnf, pacman, zypper)

### ✅ 2. Sistema de Registro no Servidor

#### Script de Registro
- **Arquivo**: `scripts/management/worker_registration.sh`
- **Funcionalidades**:
  - Validação de dados do worker
  - Armazenamento seguro de chaves SSH
  - Prevenção de registros duplicados
  - Logs detalhados de registro

#### Gerenciamento no Manager
- **Arquivo**: `manager.sh` (nova opção no menu)
- **Funcionalidades**:
  - Menu dedicado para workers registrados automaticamente
  - Verificação de status em tempo real
  - Conexão direta aos workers
  - Limpeza de workers inativos
  - Exportação de configurações

### ✅ 3. Descoberta de Rede Aprimorada

#### Detecção Automática
- **Arquivo**: `scripts/management/network_discovery.sh`
- **Funcionalidades**:
  - Detecção de workers do cluster na rede
  - Registro automático durante descoberta
  - Integração com sistema de workers

## Como Usar

### Para Workers Android

1. **Instalação**:
   ```bash
   # No Termux do dispositivo Android
   curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker.sh | bash
   ```

2. **O que acontece automaticamente**:
   - Instala dependências (openssh, python, git)
   - Gera chave SSH
   - Inicia servidor SSH na porta 8022
   - Clona o repositório do cluster
   - Detecta servidor automaticamente
   - Registra worker no servidor

### Para Workers Linux/Unix

1. **Instalação**:
   ```bash
   # Baixe e execute o script
   wget https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/installation/setup_generic_worker.sh
   chmod +x setup_generic_worker.sh
   ./setup_generic_worker.sh
   ```

2. **O que acontece automaticamente**:
   - Detecta e instala dependências
   - Configura SSH
   - Gera chave SSH
   - Clona repositório
   - Registra no servidor automaticamente

### Gerenciamento no Servidor

1. **Acesse o menu de workers**:
   ```bash
   ./manager.sh
   # Escolha: 12) Configurar Cluster
   # Escolha: 3) Gerenciar Workers Registrados Automaticamente
   ```

2. **Opções disponíveis**:
   - Listar workers registrados
   - Verificar status de conectividade
   - Conectar a worker específico
   - Remover worker
   - Limpar workers inativos
   - Exportar configuração

## Arquitetura de Segurança

### Autenticação SSH
- Chaves RSA de 4096 bits geradas automaticamente
- Armazenamento seguro no servidor
- Verificação de integridade das chaves

### Validação de Workers
- Verificação de formato de chaves públicas
- Validação de IPs e portas
- Prevenção de registros duplicados

### Comunicação Segura
- Uso de SSH para troca de informações
- Timeout configurável para conexões
- Verificação de conectividade antes do registro

## Estrutura de Arquivos

```
~/.cluster_config/
├── workers.conf              # Configuração dos workers registrados
└── authorized_keys/          # Chaves SSH dos workers
    ├── android-worker1.pub
    ├── linux-worker2.pub
    └── ...

/opt/cluster-ai/scripts/
├── android/setup_android_worker.sh
├── installation/setup_generic_worker.sh
└── management/
    ├── worker_registration.sh
    └── network_discovery.sh
```

## Resolução de Problemas

### Worker não detecta servidor
- Verifique se o servidor está na mesma rede
- Confirme que o servidor tem SSH rodando na porta 22
- Verifique firewall do servidor

### Falha no registro automático
- Verifique conectividade SSH entre worker e servidor
- Confirme que o script de registro existe no servidor
- Verifique permissões de arquivo

### Chaves SSH não funcionam
- Regere chaves no worker: `rm ~/.ssh/id_rsa* && ssh-keygen`
- Reexecute o script de instalação
- Verifique se as chaves foram copiadas corretamente

## Próximas Implementações

### Monitoramento Contínuo
- Serviço em background para detectar novos workers
- Notificações automáticas de novos registros
- Health checks periódicos

### API REST Segura
- Endpoint HTTPS para registro de workers
- Autenticação baseada em tokens
- Interface web para gerenciamento

### Suporte a Containers
- Workers baseados em Docker
- Orquestração automática com Docker Compose
- Escalabilidade horizontal

## Logs e Monitoramento

### Logs de Registro
- Localização: `~/.cluster_config/worker_registration.log`
- Contém: timestamps, IPs, status de registro
- Útil para auditoria e troubleshooting

### Status dos Workers
- Verificação em tempo real via manager
- Status: active, inactive, pending
- Última verificação registrada

## Conclusão

O sistema plug-and-play implementado simplifica significativamente o processo de adição de workers ao cluster, reduzindo de horas para minutos o tempo de configuração. A detecção automática e registro seguro tornam o sistema mais robusto e fácil de usar, especialmente em ambientes com múltiplos dispositivos.

Para feedback ou sugestões de melhorias, entre em contato com a equipe de desenvolvimento.
