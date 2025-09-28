# 🧪 PLANO DE TESTE - WORKER ANDROID CLUSTER AI

## 🎯 OBJETIVO
Validar as melhorias implementadas nos scripts de instalação do Android worker, especialmente os timeouts para evitar travamentos durante a atualização de pacotes.

## 📋 TESTES A SEREM EXECUTADOS

### 1. 🏠 TESTE LOCAL (Computador) - Validação Básica

#### 1.1 Verificação de Sintaxe dos Scripts
```bash
# Verificar se scripts são executáveis
ls -la scripts/android/*.sh

# Verificar sintaxe bash
bash -n scripts/android/setup_android_worker_robust.sh
bash -n scripts/android/setup_android_worker_simple.sh
bash -n scripts/android/setup_android_worker.sh
```

#### 1.2 Teste de Timeout (Simulação)
```bash
# Simular comando que pode travar
timeout 10s sleep 30  # Deve terminar em 10s
echo "Timeout funcionou: $?"
```

### 2. 📱 TESTE NO ANDROID (Dispositivo Real)

#### Pré-requisitos no Android:
- ✅ Termux instalado (F-Droid)
- ✅ Armazenamento configurado (`termux-setup-storage`)
- ✅ Conexão Wi-Fi estável
- ✅ Bateria > 20%

#### 2.1 Teste do Script Robusto (Recomendado)
```bash
# No Termux, executar:
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker_robust.sh -o setup.sh
chmod +x setup.sh
./setup.sh
```

**O que deve acontecer:**
- ✅ Script inicia sem erros
- ✅ Verificação do ambiente Termux
- ✅ Configuração de armazenamento
- ✅ **Atualização de pacotes com timeout (não deve travar)**
- ✅ Instalação de dependências com timeout
- ✅ Configuração SSH
- ✅ Clone do projeto (com fallback HTTPS se SSH falhar)
- ✅ Exibição das informações de conexão

#### 2.2 Teste do Script Simples
```bash
# No Termux, executar:
curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker_simple.sh -o setup.sh
chmod +x setup.sh
./setup.sh
```

#### 2.3 Teste de Conectividade
Após instalação bem-sucedida:
```bash
# No servidor principal, testar conexão:
ssh usuario@ip_do_android -p 8022
```

### 3. 🔧 TESTES DE FUNCIONALIDADES ESPECÍFICAS

#### 3.1 Teste de Timeout em pkg update
```bash
# Simular no Android:
time timeout 300 pkg update -y
echo "Código de saída: $?"
```

#### 3.2 Teste de Fallback Git
```bash
# Testar clone SSH primeiro
git clone git@github.com:Dagoberto-Candeias/cluster-ai.git test_ssh

# Se falhar, testar HTTPS
git clone https://github.com/Dagoberto-Candeias/cluster-ai.git test_https
```

#### 3.3 Teste de Geração de Chave SSH
```bash
# Verificar geração automática
ls -la ~/.ssh/
cat ~/.ssh/id_rsa.pub
```

### 4. 📊 TESTES DE PERFORMANCE

#### 4.1 Tempo de Instalação
- ⏱️ **Meta**: Instalação completa em menos de 10 minutos
- 📈 **Métricas**: Tempo por etapa, sucesso/falha

#### 4.2 Uso de Recursos
- 🔋 **Bateria**: Monitorar consumo durante instalação
- 📶 **Rede**: Testar com diferentes velocidades de internet
- 💾 **Armazenamento**: Verificar espaço necessário

### 5. 🚨 TESTES DE ERRO E RECUPERAÇÃO

#### 5.1 Cenários de Falha
- ❌ **Sem internet**: Deve informar erro claramente
- ❌ **Pouco espaço**: Deve verificar espaço antes de começar
- ❌ **Termux não instalado**: Deve detectar e informar
- ❌ **Pacotes corrompidos**: Deve tentar recuperar ou informar

#### 5.2 Recuperação de Erros
```bash
# Simular recuperação após falha
rm -rf ~/Projetos/cluster-ai
./setup.sh  # Deve detectar e continuar
```

## 📝 CHECKLIST DE VALIDAÇÃO

### ✅ Sucesso da Instalação
- [ ] Script executa sem erros de sintaxe
- [ ] Ambiente Termux detectado corretamente
- [ ] Armazenamento configurado
- [ ] Pacotes atualizados (com timeout funcionando)
- [ ] Dependências instaladas (openssh, python, git, etc.)
- [ ] SSH configurado e funcionando
- [ ] Projeto clonado com sucesso
- [ ] Chave SSH gerada e exibida
- [ ] Informações de conexão mostradas

### ✅ Funcionalidades do Worker
- [ ] Conexão SSH do servidor principal funciona
- [ ] Worker pode executar tarefas básicas
- [ ] Comunicação com scheduler Dask
- [ ] Processamento distribuído operacional

### ✅ Robustez
- [ ] Script não trava em pkg update
- [ ] Fallback HTTPS funciona se SSH falhar
- [ ] Timeouts impedem travamentos
- [ ] Mensagens de erro são claras

## 🐛 POSSÍVEIS PROBLEMAS E SOLUÇÕES

### Problema: "pkg update travando"
**Solução**: Verificar se timeout está funcionando
```bash
# Teste isolado
timeout 60 pkg update -y
```

### Problema: "Falha no clone Git"
**Solução**: Verificar conectividade e permissões
```bash
ping github.com
curl -I https://github.com
```

### Problema: "SSH não conecta"
**Solução**: Verificar configuração
```bash
# No Android
sshd
netstat -tlnp | grep 8022

# No servidor
ssh usuario@ip_android -p 8022
```

## 📊 RELATÓRIO DE TESTES

### Resultados Esperados:
```
✅ Instalação: 100% sucesso
✅ Tempo médio: < 10 minutos
✅ Timeout funcionando: Sim
✅ Fallback Git: Funcional
✅ Conectividade: Estabelecida
```

### Métricas de Qualidade:
- **Taxa de Sucesso**: > 95%
- **Tempo Médio**: < 10 minutos
- **Erros Comuns**: Identificados e documentados
- **Recuperação**: Automática quando possível

## 🎯 PRÓXIMOS PASSOS APÓS TESTES

1. **Correções**: Implementar fixes para problemas encontrados
2. **Otimização**: Melhorar performance baseado nos testes
3. **Documentação**: Atualizar guias com lições aprendidas
4. **Automação**: Criar testes automatizados para CI/CD

---

**📱 Dispositivo de Teste**: [Seu dispositivo Android]
**📅 Data do Teste**: [Data atual]
**👤 Testador**: [Seu nome]
**📊 Status**: [Pendente/Em Andamento/Concluído]
