# TODO - Revisão e Limpeza do Projeto Cluster AI

## ✅ Etapa 1: Análise Completa (Concluída)
- [x] Analisar toda documentação (README, manuais, planos, TODOs)
- [x] Revisar estrutura de diretórios
- [x] Verificar .gitignore e requirements.txt
- [x] Identificar scripts redundantes e oportunidades de consolidação

## 🔄 Etapa 2: Consolidação de Scripts Redundantes
- [ ] Identificar todos os scripts duplicados/redundantes
- [ ] Consolidar health checks (health_check.sh, health_check_enhanced.sh, etc.)
- [ ] Consolidar memory managers (memory_manager.sh, memory_manager_secure.sh)
- [ ] Atualizar referências nos scripts que usam versões antigas
- [ ] Remover scripts redundantes após consolidação

## 🔄 Etapa 3: Limpeza e Unificação da Documentação
- [ ] Consolidar arquivos README duplicados
- [ ] Unificar guias fragmentados
- [ ] Atualizar docs/INDEX.md com estrutura limpa
- [ ] Remover documentação obsoleta
- [ ] Garantir consistência entre todos os arquivos de documentação

## 🔄 Etapa 4: Separação Projeto vs Sistema
- [ ] Verificar que todos os arquivos do projeto estão dentro do diretório do projeto
- [ ] Confirmar que configurações do sistema permanecem fora (/etc/, /var/, etc.)
- [ ] Atualizar scripts para respeitar essa separação
- [ ] Documentar claramente a separação nos manuais

## 🔄 Etapa 5: Atualização de .gitignore e requirements.txt
- [ ] Revisar .gitignore para cobrir novos padrões se necessário
- [ ] Verificar requirements.txt para dependências não utilizadas
- [ ] Adicionar dependências identificadas durante análise
- [ ] Remover dependências obsoletas

## 🔄 Etapa 6: Melhorias de Segurança
- [ ] Implementar melhorias sugeridas em docs/security/SECURITY_MEASURES.md
- [ ] Reforçar validação de caminhos (safe_path_check)
- [ ] Melhorar sanitização de entrada do usuário
- [ ] Atualizar configurações de segurança

## 🔄 Etapa 7: Validação e Testes
- [ ] Executar testes de instalação
- [ ] Validar funcionamento dos scripts consolidados
- [ ] Testar integração entre componentes
- [ ] Verificar documentação atualizada

## 🔄 Etapa 8: Finalização
- [ ] Atualizar TODO.md principal com status final
- [ ] Criar relatório de mudanças implementadas
- [ ] Validar projeto limpo e funcional
- [ ] Preparar para commit das mudanças

## 📊 Status Atual
- **Scripts Redundantes Identificados**: health_check variants, memory_manager variants
- **Documentação Duplicada**: Múltiplos READMEs, guias fragmentados
- **Separação Projeto/Sistema**: Precisa verificação detalhada
- **Segurança**: Melhorias pendentes conforme docs/security/SECURITY_MEASURES.md

## 🎯 Prioridades
1. **Alta**: Consolidação de scripts (impacta manutenção)
2. **Alta**: Limpeza de documentação (impacta usabilidade)
3. **Média**: Separação projeto/sistema (impacta organização)
4. **Média**: Atualização .gitignore/requirements (impacta desenvolvimento)
5. **Baixa**: Melhorias de segurança (já bem implementado)
