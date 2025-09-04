# 🔄 Guia de Migração - Documentação Organizada

## 📋 Sobre a Reorganização

A documentação do Cluster-AI foi reorganizada para melhorar a navegação e manutenção. Todos os arquivos foram consolidados em uma estrutura organizada em `docs/organized/`.

## 📁 Nova Estrutura

### Antes (Estrutura Antiga)
```
docs/
├── manuals/
│   ├── ANDROID_GUIA_RAPIDO.md
│   ├── ANDROID_INSTALACAO_WORKER.md
│   └── ...
├── guides/
│   ├── prompts_desenvolvedores_cluster_ai.md
│   ├── prompts_administradores_cluster_ai.md
│   └── ...
├── security/
│   └── SECURITY_MEASURES.md
└── templates/
    └── script_comments_template.sh
```

### Depois (Estrutura Nova)
```
docs/
├── organized/
│   ├── installation/
│   │   ├── ANDROID_GUIA_RAPIDO.md
│   │   ├── ANDROID_INSTALACAO_WORKER.md
│   │   └── INSTALACAO.md
│   ├── usage/
│   │   ├── OLLAMA.md
│   │   └── OPENWEBUI.md
│   ├── prompts/
│   │   ├── prompts_desenvolvedores_cluster_ai.md
│   │   ├── openwebui_integration.md
│   │   └── openwebui_personas.json
│   ├── maintenance/
│   │   ├── BACKUP.md
│   │   └── CONFIGURACAO.md
│   ├── security/
│   │   └── SECURITY_MEASURES.md
│   ├── templates/
│   │   └── script_comments_template.sh
│   └── guides/
│       ├── TROUBLESHOOTING.md
│       ├── OPTIMIZATION.md
│       └── ...
└── MIGRATION_GUIDE.md (este arquivo)
```

## 🔗 Mapeamento de Arquivos

| Arquivo Antigo | Novo Local |
|---|---|
| `docs/manuals/ANDROID_GUIA_RAPIDO.md` | `docs/organized/installation/ANDROID_GUIA_RAPIDO.md` |
| `docs/guides/prompts_desenvolvedores_cluster_ai.md` | `docs/organized/prompts/prompts_desenvolvedores_cluster_ai.md` |
| `docs/security/SECURITY_MEASURES.md` | `docs/organized/security/SECURITY_MEASURES.md` |
| `docs/templates/script_comments_template.sh` | `docs/organized/templates/script_comments_template.sh` |

## 📖 Como Navegar na Nova Estrutura

### Para Novos Usuários
1. **Instalação**: `docs/organized/installation/README.md`
2. **Uso Básico**: `docs/organized/usage/`
3. **Prompts**: `docs/organized/prompts/README.md`

### Para Desenvolvedores
1. **Arquitetura**: `docs/organized/development/`
2. **Guias Técnicos**: `docs/organized/guides/`
3. **Templates**: `docs/organized/templates/`

### Para Administradores
1. **Manutenção**: `docs/organized/maintenance/`
2. **Segurança**: `docs/organized/security/`
3. **Troubleshooting**: `docs/organized/guides/TROUBLESHOOTING.md`

## 🔍 Localizando Documentação Específica

### Busca por Tópico
- **Android**: `docs/organized/installation/` (todos os arquivos ANDROID*)
- **Prompts**: `docs/organized/prompts/` (todos os arquivos prompts*)
- **Segurança**: `docs/organized/security/`
- **Backup**: `docs/organized/maintenance/BACKUP.md`

### Busca por Tipo
- **Guias de Instalação**: `docs/organized/installation/`
- **Guias de Uso**: `docs/organized/usage/`
- **Guias Técnicos**: `docs/organized/guides/`
- **Documentação de API**: `docs/organized/api/` (quando disponível)

## ⚠️ Importante

- **Arquivos Originais**: Os arquivos originais em `docs/manuals/`, `docs/guides/`, etc. foram mantidos para compatibilidade
- **Novos Arquivos**: Todos os novos arquivos devem ser criados na estrutura organizada
- **Links**: Links internos devem ser atualizados para apontar para a nova estrutura quando possível

## 🚀 Benefícios da Nova Estrutura

### ✅ Melhor Organização
- Documentação agrupada por função/purpose
- Navegação intuitiva por categoria
- Índices em cada pasta para orientação

### ✅ Manutenção Facilitada
- Localização rápida de arquivos relacionados
- Atualização consistente da documentação
- Estrutura escalável para novos conteúdos

### ✅ Experiência do Usuário
- Navegação lógica e previsível
- Índices detalhados em cada categoria
- Documentação mais acessível

## 📞 Suporte

Se encontrar algum link quebrado ou dificuldade na navegação:
1. Consulte o índice da categoria: `docs/organized/{categoria}/README.md`
2. Verifique o índice principal: `docs/organized/README.md`
3. Use este guia de migração como referência

---

**Data da Migração**: Outubro 2024
**Status**: ✅ Completa
**Compatibilidade**: Arquivos originais mantidos
