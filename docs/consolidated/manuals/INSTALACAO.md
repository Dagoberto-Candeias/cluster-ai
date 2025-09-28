# 📦 Guia de Instalação - Cluster AI

## 🎯 Visão Geral

Este guia fornece as instruções para instalar o Cluster AI usando o script unificado `install.sh`. O processo é automatizado e se adapta ao seu hardware.

## 📋 Pré-requisitos

- **Sistema Operacional**: Ubuntu, Debian, CentOS ou RHEL
- **RAM**: Mínimo de 4GB (8GB recomendado)
- **Espaço em Disco**: Mínimo de 20GB
- **Conexão de Internet**: Estável
- **Acesso Sudo**: Você precisará de permissões de administrador

## 🚀 Instalação

### 1. 📥 Baixar o Repositório

Se você ainda não clonou o repositório, faça isso agora:

```bash
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git
cd cluster-ai
```

### 2. 📦 Executar o Script de Instalação

O `install.sh` é o único ponto de entrada para a instalação.

```bash
# Executa o instalador interativo
bash install.sh
```

### 3. 🎭 Escolher o Papel da Máquina

Durante a instalação, você será solicitado a escolher o papel da máquina:

- **Servidor Principal**: Para a primeira instalação, escolha esta opção.
- **Estação de Trabalho**: Para máquinas que atuarão como workers.

### 4. ⏳ Aguardar a Conclusão da Instalação

O script instalará todas as dependências necessárias, configurará o Docker e os containers, e instalará o Ollama e os modelos.

### 5. 🌐 Acessar os Serviços

Após a instalação, você pode acessar os seguintes serviços:

| Serviço | URL | Descrição |
|---------|-----|-----------|
| OpenWebUI | http://localhost:8080 | Interface web para IA |
| Dask Dashboard | http://localhost:8787 | Monitoramento do cluster |
| Ollama API | http://localhost:11434 | API de modelos |

## 🔧 Configurações Adicionais

### Configuração de Rede

Para ambientes de produção, é recomendável configurar um IP estático para o servidor principal.

### Configuração de TLS

Consulte o guia de [Deploy Production](../deployments/production/README.md) para configurar TLS e garantir a segurança da comunicação.

## 🚨 Solução de Problemas

Se você encontrar problemas durante a instalação, consulte o [Guia de Solução de Problemas](../TROUBLESHOOTING.md) para obter assistência.

---

**🎉 Parabéns!** Você instalou com sucesso o Cluster AI. Agora você pode começar a explorar suas funcionalidades!

**💡 Dica**: Use `./install_cluster.sh` para acessar o menu completo de gerenciamento.
