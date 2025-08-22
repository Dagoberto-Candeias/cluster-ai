# 📋 Plano de Integração - Ambiente de Desenvolvimento para Cluster AI

## 🎯 Objetivo
Integrar o script de setup de ambiente de desenvolvimento ao projeto Cluster AI, tornando-o compatível com qualquer ambiente desktop (KDE, GNOME, etc.) e focado no desenvolvimento com IA.

## 🔧 Script Original Analisado
- **Arquivo**: `/home/dcm/Downloads/setup_dev_environment/setup_dev_env.sh`
- **Foco**: Ubuntu + KDE + Python + FastAPI + VS Code
- **Ações necessárias**: Remover dependência do KDE, manter compatibilidade universal

## 📦 Componentes a Serem Integrados

### ✅ Manter (Compatíveis com qualquer desktop)
- [ ] Atualização do sistema
- [ ] Ferramentas básicas (curl, wget, git, etc.)
- [ ] Python 3, pip e venv
- [ ] Docker e Docker Compose
- [ ] FastAPI, pytest e dependências
- [ ] Ambiente virtual padrão
- [ ] Visual Studio Code
- [ ] Extensões do VS Code (80+ extensões)

### ❌ Remover (Específico do KDE)
- [ ] Instalação do KDE Plasma (`kde-plasma-desktop`)
- [ ] Mensagens específicas sobre seleção de KDE no login

### 🔄 Adaptar
- [ ] Mensagens e instruções para serem neutras em relação ao desktop
- [ ] Integração com estrutura existente do Cluster AI

## 🗂️ Estrutura de Integração

### Localização Proposta
```
scripts/development/
├── setup_dev_environment.sh      # Script principal
├── vscode_extensions.list       # Lista de extensões
└── README_DEV_ENV.md            # Documentação específica
```

### Integração com Scripts Existentes
- O script pode ser chamado pelo menu principal do `install_cluster.sh`
- Opção adicional para "Configurar Ambiente de Desenvolvimento"

## 🎨 Customizações para Cluster AI

### Extensões Adicionais Sugeridas
- Extensões específicas para Dask, Ollama, IA
- Suporte a Jupyter Notebooks para experimentação
- Ferramentas de monitoramento de cluster

### Configurações Específicas
- Integração com ambiente virtual do cluster (`~/cluster_env`)
- Configuração de atalhos para serviços do cluster
- Templates de código para uso com Dask e Ollama

## 🔄 Fluxo de Integração

1. **Criar diretório**: `scripts/development/`
2. **Adaptar script**: Remover KDE, adicionar compatibilidade universal
3. **Documentar**: Criar README específico
4. **Integrar**: Adicionar opção no menu principal
5. **Testar**: Verificar funcionamento em diferentes ambientes

## 📋 Checklist de Implementação

- [ ] Criar diretório `scripts/development/`
- [ ] Adaptar script removendo KDE
- [ ] Adicionar extensões relevantes para IA/Dask
- [ ] Criar documentação específica
- [ ] Integrar com menu principal
- [ ] Testar em ambiente Ubuntu
- [ ] Testar em ambiente com GNOME
- [ ] Verificar compatibilidade

## ⚠️ Considerações

- **Compatibilidade**: Script deve funcionar em qualquer ambiente desktop
- **Não-destrutivo**: Não deve interferir com instalações existentes
- **Modular**: Pode ser executado independentemente do cluster
- **Documentação**: Instruções claras para diferentes cenários

## 🚀 Próximos Passos

1. Implementar o script adaptado
2. Criar documentação
3. Integrar com sistema existente
4. Testar extensivamente
5. Adicionar ao fluxo de instalação principal
