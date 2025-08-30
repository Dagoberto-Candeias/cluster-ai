#!/bin/bash
# Script para automatizar a configuração de um novo worker remoto.
# Descrição: Copia chaves SSH, clona o projeto e executa a instalação básica para um nó worker.

set -euo pipefail

# --- Configuração Inicial ---
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
UTILS_DIR="${PROJECT_ROOT}/scripts/utils"

# Carregar funções comuns
if [ ! -f "${UTILS_DIR}/common.sh" ]; then
    echo "ERRO CRÍTICO: Script de funções comuns não encontrado."
    exit 1
fi
source "${UTILS_DIR}/common.sh"

# --- Constantes ---
LOCAL_SSH_KEY="$HOME/.ssh/id_rsa.pub"
NODES_LIST_FILE="$HOME/.cluster_config/nodes_list.conf"
REMOTE_PROJECT_PATH="~/Projetos/cluster-ai" # Caminho onde o projeto será clonado no worker

# --- Funções ---

check_local_deps() {
    if ! command_exists ssh-copy-id; then
        error "'ssh-copy-id' não encontrado. Instale com: sudo apt install openssh-client"
        return 1
    fi
    if ! command_exists sshpass; then
        error "'sshpass' não encontrado. É necessário para a cópia da chave SSH sem prompt."
        info "Instale com: sudo apt install sshpass"
        return 1
    fi
    return 0
}

generate_ssh_key_if_needed() {
    if [ ! -f "$LOCAL_SSH_KEY" ]; then
        warn "Chave SSH local não encontrada em $LOCAL_SSH_KEY."
        if confirm_operation "Deseja gerar uma nova chave SSH agora?"; then
            ssh-keygen -t rsa -b 4096 -N "" -f "${LOCAL_SSH_KEY%.pub}"
            success "Nova chave SSH gerada."
        else
            error "A chave SSH é necessária para continuar. Abortando."
            return 1
        fi
    fi
    return 0
}

add_node_to_list() {
    local hostname="$1"
    local user="$2"
    
    log "Adicionando nó à lista de workers conhecidos..."
    local ip
    ip=$(ssh "$user@$hostname" "hostname -I | awk '{print \$1}'" 2>/dev/null || echo "IP_N/A")

    if [ "$ip" == "IP_N/A" ]; then
        error "Não foi possível obter o IP do nó remoto. Adicione-o manualmente."
        return 1
    fi

    mkdir -p "$(dirname "$NODES_LIST_FILE")"
    touch "$NODES_LIST_FILE"

    if grep -q -E "($hostname|$ip)" "$NODES_LIST_FILE"; then
        info "Nó '$hostname' ($ip) já existe na lista."
    else
        echo "$hostname $ip $user" >> "$NODES_LIST_FILE"
        success "Nó '$hostname' ($ip) adicionado a $NODES_LIST_FILE."
    fi
}

# --- Script Principal ---
main() {
    section "Configurador de Novo Worker Remoto"
    if ! check_local_deps; then return 1; fi
    if ! generate_ssh_key_if_needed; then return 1; fi

    read -p "Digite o nome de usuário do novo worker: " remote_user
    read -p "Digite o hostname ou IP do novo worker: " remote_host
    read -s -p "Digite a senha de '$remote_user@$remote_host' (para cópia da chave SSH): " remote_password
    echo ""

    if [ -z "$remote_user" ] || [ -z "$remote_host" ] || [ -z "$remote_password" ]; then
        error "Usuário, host e senha são obrigatórios. Abortando."
        return 1
    fi

    subsection "1. Copiando Chave SSH para Acesso sem Senha"
    if sshpass -p "$remote_password" ssh-copy-id -o StrictHostKeyChecking=no "$remote_user@$remote_host"; then
        success "Chave SSH copiada com sucesso para $remote_host."
    else
        error "Falha ao copiar a chave SSH. Verifique a senha e a conectividade."
        return 1
    fi

    subsection "2. Executando Script de Instalação Remota"
    log "Conectando a $remote_host para instalar dependências e clonar o projeto..."

    # Script que será executado no host remoto
    local remote_script
    remote_script=$(cat <<'EOF'
set -e
echo "--- Executando no host remoto: $(hostname) ---"

# Instalar dependências básicas
echo "Instalando dependências (git, python, etc.)..."
if command -v apt-get >/dev/null; then sudo apt-get update -qq && sudo apt-get install -y -qq git python3-pip python3-venv build-essential; elif command -v dnf >/dev/null; then sudo dnf install -y -q git python3-pip python3-venv @development-tools; elif command -v pacman >/dev/null; then sudo pacman -Syu --noconfirm --needed git python-pip python-virtualenv base-devel; else echo "Gerenciador de pacotes não suportado."; exit 1; fi

# Clonar o repositório do projeto
echo "Clonando o projeto Cluster AI..."
if [ ! -d "Projetos/cluster-ai" ]; then mkdir -p Projetos && git clone https://github.com/Dagoberto-Candeias/cluster-ai.git Projetos/cluster-ai; else echo "Diretório do projeto já existe."; fi
cd Projetos/cluster-ai

# Executar scripts de setup para um worker
echo "Configurando ambiente Python..."; bash scripts/installation/setup_python_env.sh
echo "Configurando drivers de GPU (opcional)..."; sudo bash scripts/installation/gpu_setup.sh || echo "AVISO: Setup de GPU falhou ou foi pulado."
echo "Configurando scripts de runtime..."; mkdir -p "$HOME/cluster_scripts" && cp "scripts/runtime/start_worker.sh" "$HOME/cluster_scripts/" && chmod +x "$HOME/cluster_scripts/start_worker.sh"
echo "--- Configuração remota concluída com sucesso! ---"
EOF
)

    # Executar o script no host remoto
    if ssh "$remote_user@$remote_host" 'bash -s' <<< "$remote_script"; then
        success "Instalação remota em $remote_host concluída."
    else
        error "Ocorreu um erro durante a instalação remota. Verifique os logs acima."
        return 1
    fi

    subsection "3. Adicionando Nó à Lista Local"
    add_node_to_list "$remote_host" "$remote_user"

    echo ""
    success "🎉 Novo worker '$remote_host' configurado e adicionado ao cluster!"
    info "Você já pode iniciar os workers remotos a partir do menu do manager.sh."
}

main "$@"