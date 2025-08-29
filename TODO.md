# TODO - Refatoração do Cluster AI

## Fase 1: Estrutura de Diretórios e Scripts Principais
- [ ] Criar nova estrutura de diretórios organizada
- [ ] Implementar install.sh unificado
- [ ] Implementar manager.sh (painel de controle)
- [ ] Implementar scripts/lib/install_functions.sh
- [ ] Criar cluster.conf.example
- [ ] Refatorar README.md principal

## Fase 2: Organização dos Scripts Existentes
- [ ] Mover scripts para nova estrutura de diretórios
- [ ] Unificar scripts duplicados (health_check, memory_manager, etc.)
- [ ] Atualizar referências entre scripts

## Fase 3: Documentação
- [ ] Consolidar documentação em docs/
- [ ] Criar guias específicos (installation.md, usage.md, etc.)
- [ ] Limpar documentação redundante

## Fase 4: Testes
- [ ] Criar run_tests.sh unificado
- [ ] Atualizar scripts de teste para nova estrutura

## Fase 5: Validação
- [ ] Testar instalação completa
- [ ] Validar funcionamento de todos os scripts
- [ ] Verificar consistência da configuração

## Progresso Detalhado

### Fase 1 - Concluída ✅
- [x] Criar TODO.md
- [x] Refatorar install.sh (versão 2.0)
- [x] Refatorar scripts/lib/install_functions.sh (versão 2.0)
- [x] Criar manager.sh
- [x] Criar cluster.conf.example
- [x] Refatorar README.md

### Fase 2 - Pendente
- [ ] Organizar scripts em scripts/management/
- [ ] Organizar scripts em scripts/validation/
- [ ] Organizar scripts em scripts/utils/
- [ ] Unificar health_check scripts
- [ ] Unificar memory_manager scripts

### Fase 3 - Pendente
- [ ] Consolidar docs/README_PRINCIPAL.md em README.md
- [ ] Criar docs/installation.md
- [ ] Criar docs/usage.md
- [ ] Criar docs/architecture.md
- [ ] Criar docs/troubleshooting.md
- [ ] Criar docs/PROMPTS_FOR_DEVELOPERS.md

### Fase 4 - Pendente
- [ ] Criar run_tests.sh
- [ ] Atualizar scripts de teste

### Fase 5 - Pendente
- [ ] Teste de instalação completa
- [ ] Validação funcional
