# Plano de Blindagem de Segurança - Cluster AI

## Objetivo
Implementar múltiplas camadas de proteção contra execução acidental de comandos destrutivos, prevenindo corrupção do sistema operacional.

## Scripts Prioritários para Hardening

### 1. scripts/utils/resource_optimizer.sh
**Funções críticas:**
- `cleanup_disk()` - usa `find ... -delete` sem validação de caminhos
- `free_memory()` - usa `sudo` para operações de sistema

### 2. scripts/utils/memory_manager.sh  
**Funções críticas:**
- `create_swap_file()` - usa `rm -f`, `dd`
- `expand_swap()` - usa `dd`, `truncate`
- `reduce_swap()` - usa `truncate`, `rm`
- `cleanup_swap()` - usa `rm -f`

### 3. scripts/utils/health_check_enhanced.sh
**Problemas:**
- Caracteres corrompidos (极速赛车开奖直播)
- Sugestões inseguras de comandos

## Implementação de Sanity Checks

### Função de Validação de Caminhos (safe_path_check)
```bash
# Adicionar ao common.sh
safe_path_check() {
    local path="$1"
    local operation="$2"
    
    # Verificar se o caminho está vazio
    if [ -z "$path" ]; then
        error "ERRO CRÍTICO: Caminho vazio para operação: $operation"
        return 1
    fi
    
    # Verificar se é o diretório raiz
    if [ "$path" = "/" ]; then
        error "ERRO CRÍTICO: Tentativa de operação no diretório raiz: $operation"
        return 1
    fi
    
    # Lista de diretórios críticos do sistema
    local critical_dirs=("/usr" "/bin" "/sbin" "/etc" "/var" "/lib" "/boot" "/root")
    for dir in "${critical_dirs[@]}"; do
        if [[ "$path" == "$dir"* ]]; then
            error "ERRO CRÍTICO: Tentativa de operação em diretório crítico: $dir"
            return 1
        fi
    done
    
    # Verificar se o caminho está dentro do projeto ou home do usuário
    if [[ "$path" != "$HOME"* ]] && [[ "$path" != "$(pwd)"* ]]; then
        warn "AVISO: Operação fora do diretório do projeto ou home: $path"
        # Não é erro crítico, apenas warning
    fi
    
    return 0
}
```

### Função de Confirmação do Usuário (confirm_operation)
```bash
# Adicionar ao common.sh
confirm_operation() {
    local message="$1"
    local default="${2:-n}"
    
    echo -e "${YELLOW}⚠️  $message${NC}"
    read -p "Deseja continuar? (s/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        return 0
    else
        return 1
    fi
}
```

## Plano de Implementação por Arquivo

### 1. resource_optimizer.sh
**Modificações:**
- Adicionar `safe_path_check` antes de operações `find ... -delete`
- Adicionar confirmação do usuário para `cleanup_disk()`
- Validar caminhos em `free_memory()`

### 2. memory_manager.sh  
**Modificações:**
- Adicionar `safe_path_check` antes de todas as operações com `rm`, `truncate`, `dd`
- Validar `$SWAP_FILE` em todas as funções
- Adicionar confirmação para operações destrutivas

### 3. health_check_enhanced.sh
**Modificações:**
- Remover todos os caracteres corrompidos
- Substituir sugestões inseguras por comandos validados
- Adicionar validações de segurança

## Próximos Passos
1. Implementar funções de segurança no `common.sh`
2. Aplicar modificações em cada script prioritário
3. Testar todas as funções com cenários de erro
4. Documentar as novas práticas de segurança
