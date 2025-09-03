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

# Criar diretório de configuração se não existir
mkdir -p "$CONFIG_DIR"

# ==================== FUNÇÕES DE AUTENTICAÇÃO ====================

# Função para gerar hash de senha (usando sha256sum)
generate_password_hash() {
    local password="$1"
    echo -n "$password" | sha256sum | cut -d' ' -f1
}

# Função para verificar senha
verify_password() {
    local username="$1"
    local password="$2"

    if [ ! -f "$AUTH_CONFIG" ]; then
        error "Arquivo de configuração de autenticação não encontrado."
        return 1
    fi

    local stored_hash
    stored_hash=$(grep "^${username}:" "$AUTH_CONFIG" | cut -d':' -f2)

    if [ -z "$stored_hash" ]; then
        return 1
    fi

    local input_hash
    input_hash=$(generate_password_hash "$password")

    if [ "$input_hash" = "$stored_hash" ]; then
        return 0
    else
        return 1
    fi
}

# Função para adicionar usuário
add_user() {
    local username="$1"
    local password="$2"
    local role="${3:-user}"

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

# Função para inicializar autenticação (criar usuário admin se não existir)
initialize_auth() {
    if [ ! -f "$AUTH_CONFIG" ] || [ ! -s "$AUTH_CONFIG" ]; then
        section "Inicializando Sistema de Autenticação"
        warn "Nenhum usuário configurado. Criando usuário administrador padrão..."

        local default_admin="admin"
        local default_password="clusterai2024"

        add_user "$default_admin" "$default_password" "admin"

        warn "USUÁRIO ADMINISTRADOR CRIADO:"
        warn "  Usuário: $default_admin"
        warn "  Senha: $default_password"
        warn "  ⚠️  ALTERE A SENHA PADRÃO IMEDIATAMENTE APÓS O PRIMEIRO LOGIN!"
        echo ""
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
