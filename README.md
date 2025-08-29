# 🚀 Cluster AI - Sistema de IA Local e Distribuído

O **Cluster AI** é um projeto completo para criar, gerenciar e otimizar um ambiente de desenvolvimento e execução de Inteligência Artificial localmente. Ele integra ferramentas poderosas como **Ollama**, **OpenWebUI** e **Dask** em um sistema coeso, robusto e com capacidades de auto-gerenciamento.

## ✨ Principais Funcionalidades

- **Instalação Automatizada Unificada:** Script único `install.sh` para configurar todo o ambiente
- **Painel de Controle Central:** `manager.sh` para gerenciar todos os serviços do cluster
- **Interface Web Intuitiva:** Integração com **OpenWebUI** para interagir facilmente com modelos Ollama
- **Processamento Distribuído:** Cluster **Dask** pré-configurado para processamento paralelo
- **Configuração Centralizada:** Arquivo único `cluster.conf` para todas as configurações
- **Monitoramento e Auto-Cura:** Sistema de monitoramento contínuo com reinício automático de serviços
- **Otimização de Performance:** Ajustes dinâmicos baseados no hardware disponível
- **Verificação de Saúde Completa:** Scripts de diagnóstico para validar toda a instalação

## 🚀 Guia de Início Rápido

### 1. Clonar o Repositório
```bash
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
cd cluster-ai
```

### 2. Executar o Instalador Unificado
```bash
chmod +x install.sh
./install.sh
```

### 3. Configurar o Cluster
Siga o menu interativo para definir o papel da máquina no cluster.

### 4. Usar o Painel de Controle
```bash
chmod +x manager.sh
./manager.sh
```

### 5. Validar a Instalação
```bash
./manager.sh
# Selecione a opção 14 - Testar Instalação
```

## 📋 Estrutura do Projeto

```
cluster-ai/
├── install.sh              # Instalador unificado principal
├── manager.sh              # Painel de controle central
├── cluster.conf.example    # Template de configuração
├── cluster.conf            # Configuração do cluster (gerado)
├── scripts/
│   ├── lib/                # Bibliotecas de funções
│   │   ├── common.sh       # Funções comuns
│   │   └── install_functions.sh  # Funções de instalação
│   ├── management/         # Scripts de gerenciamento
│   │   ├── health_check.sh # Verificação de saúde
│   │   ├── memory_manager.sh # Gerenciamento de memória
│   │   └── resource_optimizer.sh # Otimização de recursos
│   ├── validation/         # Scripts de teste
│   ├── backup/             # Scripts de backup
│   ├── deployment/         # Scripts de implantação
│   └── utils/              # Utilitários diversos
├── logs/                   # Logs do sistema
├── backups/                # Backups automáticos
└── docs/                   # Documentação completa
```

## 🎯 Papéis do Cluster

### Servidor Principal (`server`)
- Coordenação central do cluster
- Executa scheduler Dask
- Hospeda interface OpenWebUI
- Gerencia workers locais

### Estação de Trabalho (`workstation`)
- Worker Dask conectado ao servidor
- Ferramentas de desenvolvimento (VSCode, Spyder)
- Ideal para desenvolvedores

### Worker Dedicado (`worker`)
- Focado apenas em processamento
- Máxima performance para tarefas pesadas
- Conectado ao servidor principal

## ⚙️ Configuração

### Arquivo de Configuração
Copie o template e edite conforme necessário:
```bash
cp cluster.conf.example cluster.conf
nano cluster.conf  # ou seu editor preferido
```

### Principais Configurações
- **CLUSTER_ROLE**: Papel da máquina (server, workstation, worker)
- **CLUSTER_SERVER_IP**: IP do servidor principal
- **OLLAMA_HOST/PORT**: Configurações do Ollama
- **DASK_***: Configurações do cluster Dask
- **OPENWEBUI_***: Configurações da interface web

## 🛠️ Comandos Principais

### Instalação e Configuração
```bash
./install.sh              # Instalação completa
./install.sh --minimal    # Instalação mínima
./manager.sh              # Painel de controle
```

### Gerenciamento de Serviços
```bash
./manager.sh              # Menu interativo
# Ou comandos diretos:
./manager.sh start        # Iniciar serviços
./manager.sh stop         # Parar serviços
./manager.sh status       # Ver status
./manager.sh restart      # Reiniciar serviços
```

### Monitoramento e Otimização
```bash
./manager.sh health       # Verificar saúde do sistema
./manager.sh optimize     # Otimizar recursos
./manager.sh backup       # Executar backup
```

## 🔧 Scripts de Gerenciamento

### Health Check
```bash
./scripts/management/health_check.sh      # Verificação completa
./scripts/management/health_check.sh quick # Verificação rápida
```

### Resource Optimizer
```bash
./scripts/management/resource_optimizer.sh optimize   # Otimizar
./scripts/management/resource_optimizer.sh clean-disk # Limpeza
./scripts/management/resource_optimizer.sh monitor    # Monitorar
```

### Backup Manager
```bash
./scripts/backup/backup_manager.sh        # Backup completo
./scripts/backup/backup_manager.sh restore # Restaurar backup
```

## 🌐 Acesso aos Serviços

### OpenWebUI Interface
```
http://localhost:3000
```
Interface web para interagir com modelos Ollama.

### Dask Dashboard
```
http://localhost:8787
```
Dashboard para monitorar o cluster Dask.

### Ollama API
```
http://localhost:11434
```
API REST do Ollama para integração programática.

## 🚨 Solução de Problemas

### Serviços Não Iniciam
```bash
./manager.sh status       # Verificar status
./manager.sh restart      # Tentar reiniciar
./scripts/management/health_check.sh # Diagnóstico completo
```

### Problemas de Conexão
```bash
# Verificar conectividade com servidor
ping <server-ip>
# Verificar portas abertas
./manager.sh status
```

### Performance Lenta
```bash
./scripts/management/resource_optimizer.sh optimize
./manager.sh optimize
```

## 📊 Monitoramento

### Logs do Sistema
```bash
./manager.sh logs        # Menu de logs
journalctl -u ollama     # Logs do Ollama
tail -f logs/*.log       # Logs em tempo real
```

### Métricas de Performance
```bash
./scripts/management/memory_manager.sh   # Monitorar recursos
./scripts/utils/resource_optimizer.sh monitor # Monitoramento contínuo
```

## 🔄 Backup e Restauração

### Backup Automático
Os backups são executados automaticamente conforme configurado no `cluster.conf`.

### Backup Manual
```bash
./manager.sh backup      # Via manager
./scripts/backup/backup_manager.sh # Direto
```

### Restauração
```bash
./scripts/backup/backup_manager.sh restore
```

## 📚 Documentação Detalhada

Consulte a documentação completa em `docs/` para:
- 📖 **Guia de Instalação Detalhada** (`docs/installation.md`)
- 🎯 **Manual de Uso** (`docs/usage.md`)
- 🏗️ **Arquitetura do Sistema** (`docs/architecture.md`)
- 🔧 **Solução de Problemas** (`docs/troubleshooting.md`)
- 💡 **Prompts para Desenvolvedores** (`docs/PROMPTS_FOR_DEVELOPERS.md`)

## 🤝 Contribuição

Contribuições são bem-vindas! Para contribuir:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 🆘 Suporte

Para suporte e dúvidas:
- 📖 Consulte a documentação em `docs/`
- 🐛 Reporte bugs via Issues do GitHub
- 💬 Discuta no Discussions do projeto

---

**Cluster AI** - Transformando máquinas locais em poderosos clusters de IA 🚀
