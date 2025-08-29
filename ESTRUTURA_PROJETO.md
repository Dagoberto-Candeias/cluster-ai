# 📁 Estrutura do Projeto Cluster AI

Esta é a nova estrutura organizada do projeto Cluster AI após a reorganização completa.

## 🏗️ Visão Geral da Estrutura

```
cluster-ai/
├── 📁 backups/              # Sistema de backup e templates
├── 📁 configs/              # Configurações do sistema
├── 📁 deployments/          # Configurações de deploy
├── 📁 docs/                 # Documentação completa
├── 📁 examples/             # Exemplos de código
├── 📁 scripts/              # Scripts de gerenciamento
├── 📄 README.md             # Documentação principal
├── 📄 CONTRIBUTING.md       # Guia de contribuição
├── 📄 LICENSE.txt           # Licença do projeto
└── 📄 TODO.md               # Tarefas pendentes
```

## 📁 backups/
- **scripts/**: Scripts de backup
- **templates/**: Templates para backups
- **ollama_openwebui_bundle.zip**: Pacote de modelos Ollama + OpenWebUI

## 📁 configs/
- **docker/**: Configurações Docker
  - `compose-basic.yml` - Docker Compose básico
  - `compose-tls.yml` - Docker Compose com TLS
- **nginx/**: Configurações Nginx
  - `nginx-tls.conf` - Configuração Nginx com TLS
- **tls/**: Configurações TLS/SSL
  - `issue-certs-robust.sh` - Script robusto de certificados
  - `issue-certs-simple.sh` - Script simples de certificados
- **packages.microsoft.gpg**: Chave GPG para VSCode

## 📁 deployments/
- **development/**: Configurações de desenvolvimento
- **production/**: Configurações de produção
  - `README.md` - Guia de deploy em produção
  - `TLS_GUIDE.md` - Guia de configuração TLS

## 📁 docs/
- **api/**: Documentação da API
- **arquitetura.txt**: Diagrama de arquitetura
- **guides/**: Guias rápidos
  - `Como Usar Este Script.md` - Instruções de uso
  - `QUICK_START.md` - Guia rápido de início
  - `PROMPTS_DESENVOLVEDORES.md` - Prompts para desenvolvedores
  - **parts/**: Partes dos guias
    - Parte1_Guia_Introducao_venv.md/pdf
    - Parte2_Conda_Dependencias_IDEs_Scripts.md/pdf
    - Parte3_Ollama_OpenWebUI_Modelos_Exemplos.md/pdf
    - Parte4_VSCode_Continue_Fluxos_Checklist_Troubleshooting_Anexos.md/pdf
  - **unified/**: Guias unificados
    - Guia_Unificado_Final.md
    - Guia_Unificado_Final2.md
- **history/**: Histórico e versões antigas
  - Manual antigos (Meu manual novo 2-8.md)
  - Prompts_Desenvolvedores.md
  - completo.md
  - Arquivos deepseek históricos
- **manuals/**: Manuais completos
  - `INSTALACAO.md` - Manual de instalação
  - `OLLAMA.md` - Manual do Ollama
  - **old/**: Manuais antigos
    - manual_cluster*.md
    - manual_install_*.md
    - Manual_OpenWebUI_*.md
    - open_web_ui_manual_instalacao_uso.md
  - **ollama/**: Documentação específica do Ollama
    - `ollama_completo.md` - Manual completo
    - `ollama_models_full.md` - Lista completa de modelos
    - `models-formatted.md` - Modelos formatados
    - `models-to-download.txt` - Modelos para download
    - **parts/**: Partes do manual Ollama
      - ollama_part_00.md a ollama_part_06.md
  - **openwebui/**: Documentação do OpenWebUI

## 📁 examples/
- **advanced/**: Exemplos avançados
- **basic/**: Exemplos básicos
  - `basic_usage.py` - Uso básico do cluster
  - `example_code.py` - Código de exemplo
- **integration/**: Exemplos de integração
  - `ollama_integration.py` - Integração com Ollama

## 📁 scripts/
- **backup/**: Scripts de backup
- **deployment/**: Scripts de deploy
  - `cluster-deploy.sh` - Deploy do cluster
  - `cluster-nodes.sh` - Gerenciamento de nós
  - `multi-machine.sh` - Múltiplas máquinas
  - `webui-*.sh` - Scripts do OpenWebUI
- **history/**: Scripts históricos (deepseek)
- **installation/**: Scripts de instalação
  - `main.sh` - Script principal de instalação
  - `setup_dependencies.sh` - Instalação de dependências do sistema
  - `setup_ollama.sh` - Instalação do Ollama
  - `setup_python_env.sh` - Configuração do ambiente Python
  - `setup_vscode.sh` - Instalação do VSCode
  - `final-install.sh` - Instalação final
  - `roles-install.sh` - Instalação de papéis
  - `legacy-install.sh` - Instalação legada
- **maintenance/**: Scripts de manutenção
  - `clean-cache.sh` - Limpeza de cache
  - `update-models.sh` - Atualização de modelos
- **utils/**: Utilitários
  - `git-clone.sh` - Clone de repositório
  - `git-init.sh` - Inicialização Git

## 🎯 Principais Melhorias

1. **Organização por funcionalidade**: Estrutura clara e lógica
2. **Separação de concerns**: Configurações, scripts e documentação separados
3. **Histórico preservado**: Versões antigas mantidas em /history/
4. **Documentação completa**: Guias, manuais e exemplos organizados
5. **Preparação para produção**: Configurações TLS e deploy incluídas

## 🔄 Como Navegar

- **Para instalação**: `scripts/installation/main.sh`
- **Para documentação**: `docs/README_PRINCIPAL.md`
- **Para exemplos**: `examples/` directory
- **Para configuração**: `configs/` directory
- **Para deploy**: `deployments/production/README.md`

Esta estrutura facilita a manutenção, expansão e compreensão do projeto Cluster AI.
