# TODO - Consolidação de Scripts de Instalação

## 🎯 Objetivo
Consolidar e organizar os scripts de instalação do Cluster AI, eliminando duplicações e criando uma estrutura clara e mantível.

## 📋 Tarefas Principais

### 1. ✅ Análise Completa dos Scripts
- [x] Identificar scripts duplicados na raiz vs scripts/installation/
- [x] Mapear funcionalidades sobrepostas
- [x] Documentar inconsistências encontradas

### 2. 🔄 Reorganização Estrutural
- [x] Criar estrutura de diretórios padronizada
- [x] Mover scripts para locais apropriados
- [x] Atualizar referências nos scripts

### 3. 🧹 Limpeza de Scripts Duplicados
- [x] Reorganizar scripts por categoria
- [x] Mover scripts VS Code para scripts/vscode/
- [x] Mover scripts de manutenção para scripts/maintenance/
- [x] Criar backups antes da remoção final ✅ BACKUP CRIADO
- [x] Scripts organizados com sucesso

### 4. 📝 Melhorias no install.sh
- [ ] Adicionar verificação de integridade dos módulos
- [ ] Implementar sistema de rollback
- [ ] Melhorar logging e relatórios

### 5. 🧪 Testes e Validação
- [ ] Testar todos os caminhos de instalação
- [ ] Validar funcionamento após mudanças
- [ ] Atualizar documentação

## 📁 Estrutura Final Organizada

```
scripts/
├── installation/           # Scripts de instalação específicos
│   ├── setup_python_env.sh
│   ├── setup_dependencies.sh
│   ├── setup_docker.sh      ✅ NOVO
│   ├── setup_nginx.sh      ✅ NOVO
│   └── setup_firewall.sh   ✅ NOVO
├── setup/                  # Scripts de configuração geral
│   ├── auto_setup.sh       ✅ MOVIDO
│   └── quick_start.sh      ✅ MOVIDO
├── vscode/                 # Scripts específicos do VS Code
│   ├── clean_vscode_workspace.sh     ✅ MOVIDO
│   ├── complete_vscode_reset.sh      ✅ MOVIDO
│   ├── fix_vscode_gui.sh             ✅ MOVIDO
│   ├── optimize_vscode.sh            ✅ MOVIDO
│   ├── restart_vscode_clean.sh       ✅ MOVIDO
│   ├── vscode_fix_plan.md            ✅ MOVIDO
│   └── vscode_optimized_config.sh    ✅ MOVIDO
├── maintenance/            # Scripts de manutenção
│   ├── backup_scripts.sh             ✅ NOVO
│   ├── generate_performance_report.sh ✅ MOVIDO
│   ├── check_ollama.sh               ✅ MOVIDO
│   └── test_tls_configuration.sh     ✅ MOVIDO
├── utils/                  # Utilitários diversos
└── android/                # Scripts específicos do Android

# Arquivos na raiz (mantidos por propósito)
install.sh                  # Ponto de entrada principal
get-docker.sh              # Script oficial Docker
manager.sh                 # Gerenciador principal
```

## 🔍 Resumo da Reorganização

### ✅ Scripts MOVIDOS com Sucesso:
- **scripts/setup/**: auto_setup.sh, quick_start.sh
- **scripts/vscode/**: 7 scripts relacionados ao VS Code
- **scripts/maintenance/**: 4 scripts de manutenção + backup

### ✅ Scripts CRIADOS:
- scripts/installation/setup_docker.sh
- scripts/installation/setup_nginx.sh
- scripts/installation/setup_firewall.sh
- scripts/maintenance/backup_scripts.sh

### ✅ BACKUP Criado:
- **Diretório**: backups/scripts_backup_20250902_220200/
- **Arquivo**: scripts_backup_20250902_220200.tar.gz
- **Conteúdo**: 88 arquivos (776K)
- **Manifesto**: BACKUP_MANIFEST.txt incluído

## 🎯 Benefícios Alcançados

1. **Organização Clara**: Scripts agrupados por funcionalidade
2. **Manutenibilidade**: Fácil localização e modificação
3. **Segurança**: Backup completo antes de mudanças
4. **Escalabilidade**: Estrutura preparada para novos scripts
5. **Documentação**: TODO.md atualizado com progresso

## 📊 Status Final
- ✅ Análise inicial concluída
- ✅ Reorganização estrutural concluída
- ✅ Organização por categoria concluída
- ✅ Backup completo criado
- ✅ Scripts organizados com sucesso
- 🔄 Pronto para próximas melhorias
