#!/bin/bash
# Script para configurar worker Android a partir do servidor principal
# Este script deve ser executado no servidor Linux, não no Android

set -euo pipefail

# --- Cores para o output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

section() {
    echo ""
    echo -e "${GREEN}=================================================${NC}"
    echo -e "${GREEN} $1 ${NC}"
    echo -e "${GREEN}=================================================${NC}"
}

# Verificar se SSH está instalado e rodando
check_ssh_server() {
    section "Verificando Servidor SSH"

    if ! command -v sshd >/dev/null 2>&1; then
        error "OpenSSH server não está instalado"
        log "Instalando OpenSSH server..."
        sudo apt update && sudo apt install -y openssh-server
    fi

    if ! sudo systemctl is-active --quiet ssh; then
        log "Iniciando serviço SSH..."
        sudo systemctl start ssh
        sudo systemctl enable ssh
    fi

    success "Servidor SSH está ativo"
}

# Configurar chave SSH para o servidor
setup_server_ssh_key() {
    section "Configurando Chave SSH do Servidor"

    local key_file="$HOME/.ssh/id_rsa"

    if [ ! -f "$key_file" ]; then
        log "Gerando chave SSH para o servidor..."
        ssh-keygen -t rsa -b 4096 -N "" -f "$key_file"
        success "Chave SSH gerada"
    else
        log "Chave SSH já existe"
    fi

    # Mostrar chave pública
    echo
    info "Chave pública do servidor (copie para o Android):"
    echo -e "${YELLOW}"
    cat "${key_file}.pub"
    echo -e "${NC}"
}

# Criar arquivo de configuração de workers
create_worker_config() {
    section "Criando Configuração de Workers"

    local config_dir="$HOME/.cluster_config"
    local config_file="$config_dir/nodes_list.conf"

    mkdir -p "$config_dir"

    if [ ! -f "$config_file" ]; then
        cat > "$config_file" << 'EOF'
# Configuração de Workers Android para Cluster AI
# Formato: hostname IP user port
# Exemplo: android-worker 192.168.1.100 u0_a249 8022

# Adicione seus workers Android aqui:
EOF
        success "Arquivo de configuração criado: $config_file"
    else
        log "Arquivo de configuração já existe"
    fi

    echo
    info "Arquivo de configuração: $config_file"
    echo "Conteúdo atual:"
    cat "$config_file"
}

# Função para adicionar worker manualmente
add_worker_manually() {
    section "Adicionando Worker Manualmente"

    local config_file="$HOME/.cluster_config/nodes_list.conf"

    echo "Digite as informações do worker Android:"
    read -p "Nome do worker (ex: android-worker): " worker_name
    read -p "IP do dispositivo Android: " worker_ip
    read -p "Usuário (geralmente u0_a249): " worker_user
    read -p "Porta SSH (padrão 8022): " worker_port

    # Usar valores padrão se não fornecidos
    worker_port=${worker_port:-8022}
    worker_user=${worker_user:-u0_a249}

    # Adicionar ao arquivo de configuração
    echo "$worker_name $worker_ip $worker_user $worker_port" >> "$config_file"

    success "Worker adicionado à configuração"
    log "Testando conexão..."

    # Testar conexão SSH
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "$worker_port" "$worker_user@$worker_ip" "echo 'Worker conectado!'"; then
        success "Conexão SSH estabelecida com sucesso!"
    else
        warn "Falha na conexão SSH. Verifique:"
        echo "  - IP do dispositivo Android está correto"
        echo "  - SSH está rodando no Android (porta $worker_port)"
        echo "  - Chave SSH foi adicionada ao authorized_keys do Android"
        echo "  - Firewall não está bloqueando a conexão"
    fi
}

# Função para detectar workers automaticamente
discover_workers() {
    section "Descoberta Automática de Workers"

    log "Procurando workers Android na rede local..."

    # Verificar se o script de descoberta automática existe
    local auto_discover_script="$PROJECT_ROOT/scripts/deployment/auto_discover_workers.sh"

    if [ -f "$auto_discover_script" ]; then
        log "Executando descoberta automática..."
        bash "$auto_discover_script"
    else
        warn "Script de descoberta automática não encontrado: $auto_discover_script"
        echo "Para usar a descoberta automática, execute:"
        echo "  bash scripts/deployment/auto_discover_workers.sh"
        echo
        echo "Alternativamente, use a opção de adicionar manualmente"
    fi
}

# Mostrar instruções para o Android
show_android_instructions() {
    section "Instruções para Configurar o Android"

    echo "Siga estes passos no seu dispositivo Android (Termux):"
    echo
    echo "1. Instale o Termux se ainda não tiver:"
    echo "   - Baixe da F-Droid ou Google Play Store"
    echo
    echo "2. Configure o armazenamento:"
    echo "   termux-setup-storage"
    echo
    echo "3. Execute o script de configuração:"
    echo "   curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker.sh | bash"
    echo
    echo "4. Copie a chave SSH mostrada acima para o authorized_keys do Android"
    echo
    echo "5. Anote o IP do seu dispositivo Android:"
    echo "   ifconfig | grep 'inet ' | grep -v '127.0.0.1'"
    echo
    echo "6. Volte aqui e use a opção para adicionar worker manualmente"
}

# Menu principal
show_menu() {
    echo
    echo "Opções de Configuração:"
    echo "1) Verificar/Instalar SSH Server"
    echo "2) Configurar Chave SSH do Servidor"
    echo "3) Criar Arquivo de Configuração"
    echo "4) Adicionar Worker Manualmente"
    echo "5) Descobrir Workers Automaticamente"
    echo "6) Mostrar Instruções para Android"
    echo "0) Sair"
    echo
}

main() {
    section "Configurador de Worker Android - Servidor"

    while true; do
        show_menu
        read -p "Digite sua opção: " option

        case $option in
            1) check_ssh_server ;;
            2) setup_server_ssh_key ;;
            3) create_worker_config ;;
            4) add_worker_manually ;;
            5) discover_workers ;;
            6) show_android_instructions ;;
            0)
                success "Configuração concluída!"
                exit 0
                ;;
            *)
                error "Opção inválida"
                ;;
        esac

        echo
        read -p "Pressione Enter para continuar..."
    done
}

main "$@"
