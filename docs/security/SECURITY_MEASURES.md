# Medidas de Segurança do Cluster AI

## Visão Geral
Este documento descreve as medidas de segurança implementadas no projeto Cluster AI para garantir operação segura, isolamento adequado e prevenção de interferência no sistema.

## 1. Isolamento do Ambiente

### 1.1 Ambiente Virtual Python
- **Localização**: `~/cluster_env` (será movido para `$PROJECT_ROOT/.venv`)
- **Propósito**: Isolar completamente as dependências Python do projeto
- **Vantagens**:
  - Não interfere com pacotes do sistema
  - Permite versões específicas de bibliotecas
  - Fácil remoção sem afetar o sistema

### 1.2 Estrutura de Diretórios
```
cluster-ai/
├── scripts/          # Scripts do projeto
├── logs/            # Logs específicos
├── backups/         # Backups do projeto  
├── .venv/           # Ambiente virtual (futuro)
└── configs/         # Configurações
```

## 2. Proteção contra Operações Perigosas

### 2.1 Função safe_path_check
Implementada em `scripts/utils/common_functions.sh`:

```bash
# Bloqueia operações em diretórios críticos do sistema
critical_dirs=("/bin" "/boot" "/dev" "/etc" "/lib" "/lib64" "/proc" "/root" "/run" "/sbin" "/sys" "/usr" "/var")

# Permite apenas subdiretórios seguros de /var (como /var/log)
if [[ "$resolved_path" == "/var/log"* ]]; then
    continue
fi
```

### 2.2 Verificação de Comandos
```bash
check_command() {
    local cmd="$1" name="$2" install_cmd="$3"
    if ! command_exists "$cmd"; then
        warn "$name não encontrado: $cmd"
        info "Instalar com: $install_cmd"
        return 1
    fi
    info "$name encontrado: $(which "$cmd")"
    return 0
}
```

## 3. Controle de Execução

### 3.1 Prevenção de Execução como Root
```bash
check_root() {
    if [ "$EUID" -eq 0 ]; then
        error "Este script não deve ser executado como root"
        echo "   💡 Execute como usuário normal: bash $0"
        exit 1
    fi
}
```

### 3.2 Confirmação para Operações Críticas
```bash
confirm_operation() {
    local message="$1"
    read -p "$(echo -e "${YELLOW}AVISO:${NC} $message Deseja continuar? (s/N) ")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        return 0
    else
        return 1
    fi
}
```

## 4. Sistema de Logs e Monitoramento

### 4.1 Logs Centralizados
- **Local**: `logs/` directory dentro do projeto
- **Formato**: Timestamp + nível + mensagem
- **Rotação**: Logs separados por data e função

### 4.2 Monitoramento de Recursos
Script `memory_monitor.sh` monitora:
- Uso de CPU e memória
- Espaço em disco
- Serviços essenciais (Ollama, Docker)

## 5. Configuração Segura

### 5.1 Arquivo de Configuração
- **Local**: `cluster.conf` (baseado em `cluster.conf.example`)
- **Permissões**: `chmod 600` (apenas usuário)
- **Variáveis sensíveis**: Nenhuma senha em claro

### 5.2 Papéis do Cluster
- **server**: Coordenação + serviços
- **workstation**: Desenvolvimento + worker  
- **worker**: Apenas processamento

## 6. Próximas Melhorias de Segurança

### 6.1 ✅ Movimentar Ambiente Virtual
- De: `~/cluster_env`
- Para: `$PROJECT_ROOT/.venv`

### 6.2 ✅ Reforçar safe_path_check
Adicionar proteção para:
- `/sbin`, `/lib32`, `/libx32`
- Diretórios home de outros usuários
- Partições de sistema montadas

### 6.3 ✅ Validação de Entrada do Usuário
Sanitizar inputs em funções interativas

### 6.4 ✅ Backup Seguro
Implementar criptografia para backups sensíveis

## 7. Boas Práticas Recomendadas

### 7.1 Para Desenvolvedores
- Sempre usar `safe_path_check` para operações de arquivo
- Validar existência de comandos com `command_exists`
- Usar `confirm_operation` para ações destrutivas

### 7.2 Para Administradores
- Revisar `cluster.conf` antes da implantação
- Monitorar logs regularmente
- Manter backups em local seguro

### 7.3 Para Usuários
- Não executar como root
- Verificar permissões de arquivos
- Reportar comportamentos inesperados

## 8. Resposta a Incidentes

### 8.1 Identificação
- Verificar logs em `logs/`
- Executar `./manager.sh status`

### 8.2 Contenção
- Parar serviços: `./manager.sh stop`
- Isolar máquina se necessário

### 8.3 Recuperação
- Restaurar from backup: `./manager.sh backup restore`
- Reinstalar se necessário: `./install.sh`

---

*Última atualização: $(date +%Y-%m-%d)*
