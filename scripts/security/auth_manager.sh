#!/bin/bash
# Sistema de Autenticação para Cluster AI

set -euo pipefail

# ==================== CONFIGURAÇÃO INICIAL ====================

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"
CONFIG_DIR="${PROJECT_ROOT}/config"
AUTH_CONFIG="${CONFIG_DIR}/auth.conf"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# Verificar se função de auditoria existe
if ! type security_audit_log >/dev/null 2>&1; then
    security_audit_log() {
        local action="$1"
        local details="$2"
        local log_file="${PROJECT_ROOT}/logs/security_audit.log"
        mkdir -p "$(dirname "$log_file")"
        echo "$(date '+%Y-%m-%d %H:%M:%S') [$action] $details" >> "$log_file"
    }
fi

# Criar diretório de configuração se não existir
mkdir -p "$CONFIG_DIR"

# Função para verificar integridade do arquivo de configuração
verify_config_integrity() {
    if [ -f "$AUTH_CONFIG" ]; then
        # Verificar permissões do arquivo
        local perms
        perms=$(stat -c '%a' "$AUTH_CONFIG" 2>/dev/null || stat -f '%A' "$AUTH_CONFIG" 2>/dev/null || echo "unknown")

        if [ "$perms" != "600" ]; then
            warn "Permissões inseguras no arquivo de autenticação ($perms). Corrigindo..."
            chmod 600 "$AUTH_CONFIG"
            security_audit_log "CONFIG_PERMS_FIXED" "File: $AUTH_CONFIG, Old perms: $perms, New perms: 600"
        fi

        # Verificar se arquivo contém apenas linhas válidas
        local invalid_lines
        invalid_lines=$(grep -v '^[^:]*:[^:]*:[^:]*$' "$AUTH_CONFIG" | wc -l)

        if [ "$invalid_lines" -gt 0 ]; then
            error "Arquivo de configuração contém linhas inválidas. Backup criado."
            cp "$AUTH_CONFIG" "${AUTH_CONFIG}.backup.$(date +%s)"
            security_audit_log "CONFIG_CORRUPTION_DETECTED" "Invalid lines: $invalid_lines"
        fi
    fi
}

# ==================== FUNÇÕES DE AUTENTICAÇÃO ====================

# Função para gerar hash de senha seguro (usando sha256sum com salt)
generate_password_hash() {
    local password="$1"
    local salt
    salt=$(openssl rand -hex 16 2>/dev/null || head -c 32 /dev/urandom | od -An -tx1 | tr -d ' ')
    echo -n "${salt}${password}" | sha256sum | cut -d' ' -f1 | sed "s/$/:${salt}/"
}

# Função para verificar senha
verify_password() {
    local username="$1"
    local password="$2"

    if [ ! -f "$AUTH_CONFIG" ]; then
        error "Arquivo de configuração de autenticação não encontrado."
        return 1
    fi

    local stored_data
    stored_data=$(grep "^${username}:" "$AUTH_CONFIG" | cut -d':' -f2-3)

    if [ -z "$stored_data" ]; then
        return 1
    fi

    local stored_hash stored_salt
    IFS=':' read -r stored_hash stored_salt <<< "$stored_data"

    if [ -z "$stored_hash" ] || [ -z "$stored_salt" ]; then
        return 1
    fi

    local input_hash
    input_hash=$(echo -n "${stored_salt}${password}" | sha256sum | cut -d' ' -f1)

    if [ "$input_hash" = "$stored_hash" ]; then
        return 0
    else
        return 1
    fi
}

# Função para validar força da senha
validate_password_strength() {
    local password="$1"

    # Verificar comprimento mínimo
    if [ ${#password} -lt 8 ]; then
        error "Senha deve ter pelo menos 8 caracteres."
        return 1
    fi

    # Verificar se contém letras maiúsculas, minúsculas, números e caracteres especiais
    if ! echo "$password" | grep -q '[A-Z]' || ! echo "$password" | grep -q '[a-z]' || ! echo "$password" | grep -q '[0-9]'; then
        error "Senha deve conter pelo menos uma letra maiúscula, uma minúscula e um número."
        return 1
    fi

    return 0
}

# Função para adicionar usuário
add_user() {
    local username="$1"
    local password="$2"
    local role="${3:-user}"

    # Validar força da senha
    if ! validate_password_strength "$password"; then
        return 1
    fi

    if [ ! -f "$AUTH_CONFIG" ]; then
        touch "$AUTH_CONFIG"
        chmod 600 "$AUTH_CONFIG"
    fi

    # Verificar se usuário já existe
    if grep -q "^${username}:" "$AUTH_CONFIG"; then
        error "Usuário '$username' já existe."
        return 1
    fi

    local password_hash
    password_hash=$(generate_password_hash "$password")

    echo "${username}:${password_hash}:${role}" >> "$AUTH_CONFIG"
    success "Usuário '$username' adicionado com sucesso."
    security_audit_log "USER_ADD" "Username: $username, Role: $role"
}

# Função para remover usuário
remove_user() {
    local username="$1"

    if [ ! -f "$AUTH_CONFIG" ]; then
        error "Arquivo de configuração de autenticação não encontrado."
        return 1
    fi

    if ! grep -q "^${username}:" "$AUTH_CONFIG"; then
        error "Usuário '$username' não encontrado."
        return 1
    fi

    sed -i "/^${username}:/d" "$AUTH_CONFIG"
    success "Usuário '$username' removido com sucesso."
    security_audit_log "USER_REMOVE" "Username: $username"
}

# Função para alterar senha
change_password() {
    local username="$1"
    local new_password="$2"

    if [ ! -f "$AUTH_CONFIG" ]; then
        error "Arquivo de configuração de autenticação não encontrado."
        return 1
    fi

    if ! grep -q "^${username}:" "$AUTH_CONFIG"; then
        error "Usuário '$username' não encontrado."
        return 1
    fi

    local role
    role=$(grep "^${username}:" "$AUTH_CONFIG" | cut -d':' -f3)

    local new_hash
    new_hash=$(generate_password_hash "$new_password")

    sed -i "s/^${username}:.*$/${username}:${new_hash}:${role}/" "$AUTH_CONFIG"
    success "Senha do usuário '$username' alterada com sucesso."
    security_audit_log "PASSWORD_CHANGE" "Username: $username"
}

# Função para autenticar usuário
authenticate_user() {
    local username="$1"
    local password="$2"

    if verify_password "$username" "$password"; then
        success "Autenticação bem-sucedida para usuário '$username'."
        security_audit_log "AUTH_SUCCESS" "Username: $username"
        return 0
    else
        error "Falha na autenticação para usuário '$username'."
        security_audit_log "AUTH_FAILURE" "Username: $username"
        return 1
    fi
}

# Função para obter papel do usuário
get_user_role() {
    local username="$1"

    if [ ! -f "$AUTH_CONFIG" ]; then
        echo "none"
        return 1
    fi

    local role
    role=$(grep "^${username}:" "$AUTH_CONFIG" | cut -d':' -f3)
    echo "${role:-none}"
}

# Função para listar usuários
list_users() {
    if [ ! -f "$AUTH_CONFIG" ]; then
        warn "Nenhum usuário configurado."
        return 0
    fi

    section "Usuários Configurados"
    while IFS=':' read -r username hash role; do
        echo "Usuário: $username | Papel: ${role:-user}"
    done < "$AUTH_CONFIG"
}

# Função para gerar senha segura aleatória
generate_secure_password() {
    local length="${1:-12}"
    openssl rand -base64 48 2>/dev/null | tr -d "=+/" | cut -c1-"$length" || {
        # Fallback se openssl não estiver disponível
        head -c 32 /dev/urandom | base64 | tr -d "=+/" | cut -c1-"$length"
    }
}

# Função para inicializar autenticação (criar usuário admin se não existir)
initialize_auth() {
    if [ ! -f "$AUTH_CONFIG" ] || [ ! -s "$AUTH_CONFIG" ]; then
        section "Inicializando Sistema de Autenticação"
        warn "Nenhum usuário configurado. Criando usuário administrador..."

        local default_admin="admin"
        local secure_password
        secure_password=$(generate_secure_password 16)

        # Criar usuário sem validação de força (uma vez só para setup inicial)
        if [ ! -f "$AUTH_CONFIG" ]; then
            touch "$AUTH_CONFIG"
            chmod 600 "$AUTH_CONFIG"
        fi

        local password_hash
        password_hash=$(generate_password_hash "$secure_password")

        echo "${default_admin}:${password_hash}:admin" >> "$AUTH_CONFIG"

        success "USUÁRIO ADMINISTRADOR CRIADO:"
        info "  Usuário: $default_admin"
        info "  Senha: $secure_password"
        warn "  ⚠️  ANOTE ESTA SENHA E ALTERE-A IMEDIATAMENTE APÓS O PRIMEIRO LOGIN!"
        warn "  ⚠️  ESTA É A ÚNICA VEZ QUE A SENHA SERÁ EXIBIDA!"
        echo ""

        # Log de segurança para criação do usuário inicial
        security_audit_log "ADMIN_USER_CREATED" "Username: $default_admin"
    fi
}

# ==================== MENU INTERATIVO ====================

show_auth_menu() {
    section "Gerenciador de Autenticação - Cluster AI"
    echo "1. ➕ Adicionar usuário"
    echo "2. ➖ Remover usuário"
    echo "3. 🔑 Alterar senha"
    echo "4. 📋 Listar usuários"
    echo "5. 🔐 Testar autenticação"
    echo "---"
    echo "6. ↩️ Voltar"
    echo ""
}

process_auth_menu_choice() {
    local choice="$1"
    case $choice in
        1)
            read -p "Nome do usuário: " username
            if ! validate_username "$username"; then
                error "Nome de usuário inválido. Use apenas letras, números, underscore e hífen."
                return 1
            fi

            read -s -p "Senha: " password
            echo ""
            read -s -p "Confirme a senha: " password_confirm
            echo ""

            if [ "$password" != "$password_confirm" ]; then
                error "As senhas não coincidem."
                return 1
            fi

            read -p "Papel (admin/user) [user]: " role
            role="${role:-user}"

            if [[ "$role" != "admin" && "$role" != "user" ]]; then
                error "Papel inválido. Use 'admin' ou 'user'."
                return 1
            fi

            add_user "$username" "$password" "$role"
            ;;
        2)
            read -p "Nome do usuário a remover: " username
            if confirm_operation "Tem certeza que deseja remover o usuário '$username'?"; then
                remove_user "$username"
            fi
            ;;
        3)
            read -p "Nome do usuário: " username
            read -s -p "Nova senha: " new_password
            echo ""
            read -s -p "Confirme a nova senha: " new_password_confirm
            echo ""

            if [ "$new_password" != "$new_password_confirm" ]; then
                error "As senhas não coincidem."
                return 1
            fi

            change_password "$username" "$new_password"
            ;;
        4)
            list_users
            ;;
        5)
            read -p "Nome do usuário: " username
            read -s -p "Senha: " password
            echo ""
            authenticate_user "$username" "$password"
            ;;
        6) return 0 ;;
        *) warn "Opção inválida"; return 1 ;;
    esac
}

# ==================== FUNÇÃO PRINCIPAL ====================

main() {
    # Verificar se está rodando como root
    check_root_user "Gerenciador de Autenticação" || exit 1

    # Verificar integridade da configuração
    verify_config_integrity

    # Inicializar autenticação se necessário
    initialize_auth

    case "${1:-menu}" in
        add-user)
            if [ $# -lt 3 ]; then
                error "Uso: $0 add-user <username> <password> [role]"
                exit 1
            fi
            add_user "$2" "$3" "${4:-user}"
            ;;
        remove-user)
            if [ $# -lt 2 ]; then
                error "Uso: $0 remove-user <username>"
                exit 1
            fi
            remove_user "$2"
            ;;
        change-password)
            if [ $# -lt 3 ]; then
                error "Uso: $0 change-password <username> <new_password>"
                exit 1
            fi
            change_password "$2" "$3"
            ;;
        authenticate)
            if [ $# -lt 3 ]; then
                error "Uso: $0 authenticate <username> <password>"
                exit 1
            fi
            authenticate_user "$2" "$3"
            ;;
        list-users)
            list_users
            ;;
        menu)
            while true; do
                show_auth_menu
                read -p "Selecione uma opção [1-6]: " choice
                if process_auth_menu_choice "$choice"; then
                    success "Operação concluída."
                else
                    warn "Operação falhou ou foi cancelada."
                fi

                if [ "$choice" = "6" ]; then
                    break
                fi

                echo ""
                read -p "Pressione Enter para continuar..."
            done
            ;;
        *)
            error "Comando desconhecido: $1"
            echo "Comandos disponíveis: add-user, remove-user, change-password, authenticate, list-users, menu"
            exit 1
            ;;
    esac
}

main "$@"
