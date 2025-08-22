# 📋 Instalação Local - Cluster AI

Este documento explica como usar o script de instalação local do Cluster AI, que está disponível diretamente no repositório clonado.

## 🎯 Script de Instalação Local

O projeto agora inclui um script wrapper `install_cluster.sh` no diretório raiz que chama o script principal de instalação localizado em `scripts/installation/main.sh`.

### ⚡ Instalação Rápida (Local)

```bash
# Se você já clonou o repositório, basta executar:
chmod +x install_cluster.sh
./install_cluster.sh
```

### 🔄 Alternativas de Instalação

#### Opção 1: Usando o wrapper (Recomendado)
```bash
./install_cluster.sh
```

#### Opção 2: Diretamente pelo script principal
```bash
chmod +x scripts/installation/main.sh
./scripts/installation/main.sh
```

#### Opção 3: Download do GitHub (para quem não clonou)
```bash
# Para quem não clonou o repositório, ainda pode baixar do GitHub:
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/installation/main.sh -o install_cluster.sh
chmod +x install_cluster.sh
./install_cluster.sh
```

## 📁 Estrutura dos Scripts de Instalação

```
cluster-ai/
├── install_cluster.sh              # Wrapper principal (novo)
├── scripts/
│   └── installation/
│       ├── main.sh                 # Script principal de instalação
│       ├── backup-install.sh       # Script de backup
│       ├── final-install.sh        # Instalação final
│       ├── ides.sh                 # Instalação de IDEs
│       ├── legacy-install.sh       # Instalação legada
│       └── roles-install.sh        # Definição de papéis
```

## 🚀 Funcionalidades do Script

O script `install_cluster.sh` oferece:

- **Instalação completa** do Cluster AI com Dask, Ollama e OpenWebUI
- **Configuração automática** baseada no papel da máquina (servidor, workstation, worker)
- **Sistema de backup e restauração** integrado
- **Menu interativo** para gerenciamento do cluster
- **Suporte a múltiplas distribuições** Linux (Ubuntu, Debian, CentOS, Manjaro)

## 🎭 Papéis Disponíveis

1. **Servidor Principal** - Coordenação + Serviços + Worker
2. **Estação de Trabalho** - Worker + IDEs de desenvolvimento
3. **Apenas Worker** - Processamento dedicado
4. **Converter para Servidor** - Promover estação para servidor

## ⚡ Comandos Rápidos

```bash
# Menu principal interativo
./install_cluster.sh

# Verificar status do sistema
./install_cluster.sh --status

# Fazer backup
./install_cluster.sh --backup

# Restaurar backup
./install_cluster.sh --restore

# Agendar backups automáticos
./install_cluster.sh --schedule

# Ajuda
./install_cluster.sh --help
```

## 🔧 Scripts Relacionados

Além do script principal, o projeto inclui:

- `scripts/development/setup_dev_environment.sh` - Ambiente de desenvolvimento universal
- `scripts/deployment/` - Scripts para deploy em produção
- `scripts/maintenance/` - Scripts de manutenção
- `scripts/backup/` - Scripts de backup avançados

## 📝 Notas Importantes

- O script detecta automaticamente a distribuição Linux
- Configura otimização para GPU NVIDIA/AMD quando disponível
- Inclui sistema de reconexão automática para workers
- Suporte a IPs dinâmicos e configuração de rede

## 🆘 Suporte

Para problemas com a instalação, consulte:
- [Guia de Solução de Problemas](docs/guides/TROUBLESHOOTING.md)
- [Manual Completo de Instalação](docs/manuals/INSTALACAO.md)
- [Issues no GitHub](https://github.com/Dagoberto-Candeias/cluster-ai/issues)

---

**💡 Dica**: Use `./install_cluster.sh` sem argumentos para acessar o menu interativo completo com todas as opções de configuração.
