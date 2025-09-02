# 📱 PLANO DE TESTE - WORKER ANDROID CLUSTER AI

## 🎯 OBJETIVOS DOS TESTES

Verificar se todas as correções implementadas para suporte a repositórios privados funcionam corretamente no ambiente Android/Termux.

## 🧪 CENÁRIOS DE TESTE

### 1. ✅ Verificação de Sintaxe (CONCLUÍDO)
- [x] Todos os scripts passaram na verificação `bash -n`
- [x] Funções auxiliares (log, success, error, warn) definidas corretamente
- [x] Estruturas de controle (if/else, loops) sintaticamente válidas

### 2. 🔍 Teste de Dependências
- [ ] Verificar se todas as dependências estão listadas corretamente
- [ ] Testar instalação de pacotes via `pkg install`
- [ ] Validar versões mínimas requeridas

### 3. 🔐 Teste de Autenticação SSH
- [ ] Geração automática de chaves SSH
- [ ] Configuração do servidor SSH na porta 8022
- [ ] Teste de conectividade SSH local
- [ ] Validação de permissões de arquivos

### 4. 📥 Teste de Clone de Repositório
- [ ] Teste de clone via SSH (repositório privado)
- [ ] Fallback para HTTPS quando SSH falha
- [ ] Tratamento de erros de autenticação
- [ ] Atualização de repositório existente

### 5. 🔧 Teste de Configuração de Armazenamento
- [ ] Verificação de `termux-setup-storage`
- [ ] Criação de diretórios necessários
- [ ] Permissões de acesso aos arquivos

### 6. 🌐 Teste de Conectividade de Rede
- [ ] Verificação de conectividade com internet
- [ ] Obtenção de endereço IP local
- [ ] Teste de resolução DNS

### 7. 📊 Teste do Script de Diagnóstico
- [ ] Execução completa do `test_android_worker.sh`
- [ ] Validação de todos os checks implementados
- [ ] Geração correta do relatório final

### 8. 🎯 Teste de Integração Completa
- [ ] Execução do script de instalação manual
- [ ] Verificação de todas as etapas em sequência
- [ ] Teste de recuperação de falhas

## 📋 MÉTODOS DE TESTE

### Método 1: Teste em Ambiente Real (Termux)
```bash
# Simular execução no Android
export TERMUX_PREFIX="/data/data/com.termux/files/usr"
mkdir -p "$TERMUX_PREFIX"

# Executar testes
bash scripts/android/test_android_worker.sh
```

### Método 2: Teste com Mock de Ambiente
```bash
# Criar mock do ambiente Termux
mkdir -p /tmp/termux_mock/data/data/com.termux/files/usr
export PREFIX="/tmp/termux_mock/data/data/com.termux/files/usr"

# Executar testes simulados
```

### Método 3: Teste de Componentes Isolados
```bash
# Testar funções individualmente
source scripts/android/setup_android_worker.sh
check_termux  # Deve falhar no mock
```

## 🔍 CRITÉRIOS DE APROVAÇÃO

### ✅ Sucesso
- [ ] Todos os scripts executam sem erros de sintaxe
- [ ] Funções retornam códigos de saída apropriados
- [ ] Mensagens de erro são claras e acionáveis
- [ ] Fallbacks funcionam quando métodos primários falham
- [ ] Logs são informativos e ajudam no diagnóstico

### ❌ Falha
- [ ] Scripts com erros de sintaxe
- [ ] Dependências não verificadas adequadamente
- [ ] Falta de tratamento de erros
- [ ] Mensagens de erro confusas
- [ ] Funcionalidades críticas não implementadas

## 📊 RELATÓRIO DE TESTES

### Resultados Atuais
- ✅ Verificação de sintaxe: APROVADO
- ✅ Correção de timeout em pkg update/upgrade: IMPLEMENTADO
- ✅ Script robusto com melhor tratamento de erros: CRIADO
- ✅ Documentação atualizada com novas opções: ATUALIZADA
- 🔄 Teste em ambiente real: PENDENTE (aguardando feedback do usuário)

### Próximos Passos
1. Executar testes de dependências
2. Testar autenticação SSH
3. Validar clone de repositório
4. Executar teste de integração completa
5. Gerar relatório final com recomendações

## 🛠️ FERRAMENTAS DE TESTE

- `bash -n`: Verificação de sintaxe
- `shellcheck`: Análise estática de scripts
- Ambiente mock do Termux
- Testes de integração manuais

## 📈 MÉTRICAS DE QUALIDADE

- Cobertura de teste: 100% das funções críticas
- Taxa de sucesso: >95% em ambiente simulado
- Tempo de execução: <30 segundos para instalação completa
- Facilidade de uso: Instalação em <5 minutos para usuário final
