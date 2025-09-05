#!/bin/bash
# Script genérico para configurar um dispositivo Linux/Unix como worker do Cluster AI
# Autor: Dagoberto Candeias <betoallnet@gmail.com>

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

# Detectar gerenciador de pacotes
detect_package_manager() {
    if command_exists apt-get; then
        echo "apt-get"
    elif command_exists yum; then
        echo "yum"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists zypper; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# Instalar pacote usando o gerenciador detectado
install_package() {
    local package="$1"
    local pm
    pm=$(detect_package_manager)

    case $pm in
        apt-get)
            sudo apt-get update && sudo apt-get install -y "$package"
            ;;
        yum)
            sudo yum install -y "$package"
            ;;
        dnf)
            sudo dnf install -y "$package"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$package"
            ;;
        zypper)
            sudo zypper install -y "$package"
            ;;
        *)
            error "Gerenciador de pacotes não suportado"
            return 1
            ;;
    esac
}

# Verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

main() {
    section "Configurador de Worker Genérico para Cluster AI"

    # Verificar se está rodando como root (não recomendado)
    if [ "$EUID" -eq 0 ]; then
        warn "Este script não deve ser executado como root"
        warn "Será executado como usuário normal"
        echo
    fi

    # 1. Verificar e instalar dependências
    section "Verificando Dependências"

    local deps=("openssh-client" "curl" "wget" "git")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing_deps+=("$dep")
        else
            success "$dep: OK"
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log "Instalando dependências faltantes: ${missing_deps[*]}"
        for dep in "${missing_deps[@]}"; do
            if install_package "$dep"; then
                success "$dep instalado"
            else
                error "Falha ao instalar $dep"
                exit 1
            fi
        done
    fi

    # 2. Configurar SSH
    section "Configurando SSH"

    # Criar diretório .ssh se não existir
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # Gerar chave SSH se não existir
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        log "Gerando chave SSH para o dispositivo..."
        ssh-keygen -t rsa -b 4096 -N "" -f "$HOME/.ssh/id_rsa"
        success "Chave SSH gerada"
    else
        log "Chave SSH já existe"
    fi

    # Obter informações do sistema
    local hostname
    hostname=$(hostname)
    local user
    user=$(whoami)
    local ip
    ip=$(hostname -I | awk '{print $1}')

    if [ -z "$ip" ]; then
        # Fallback para ip route
        ip=$(ip route get 1 | awk '{print $7; exit}')
    fi

    success "Informações do worker:"
    info "  • Nome: $hostname"
    info "  • Usuário: $user"
    info "  • IP: $ip"

    # 3. Clonar repositório do Cluster AI
    section "Clonando Projeto Cluster AI"

    local repo_dir="$HOME/Projetos/cluster-ai"

    if [ ! -d "$repo_dir" ]; then
        mkdir -p "$HOME/Projetos"

        # Tentar HTTPS primeiro
        log "Clonando repositório..."
        if git clone https://github.com/Dagoberto-Candeias/cluster-ai.git "$repo_dir" >/dev/null 2>&1; then
            success "Repositório clonado via HTTPS"
        else
            warn "Falha no HTTPS, tentando SSH..."
            if git clone git@github.com:Dagoberto-Candeias/cluster-ai.git "$repo_dir" >/dev/null 2>&1; then
                success "Repositório clonado via SSH"
            else
                error "Falha ao clonar repositório"
                echo
                echo "🔧 SOLUÇÕES PARA AUTENTICAÇÃO:"
                echo "1. Configure sua chave SSH no GitHub:"
                echo "   - Vá em: https://github.com/settings/keys"
                echo "   - Adicione a chave pública que será exibida no final."
                echo
                echo "2. Ou clone manualmente após configurar autenticação."
                echo
                echo "3. Execute este script novamente após configurar a autenticação."
                exit 1
            fi
        fi
    else
        log "Repositório já existe, atualizando..."
        cd "$repo_dir"
        if git pull >/dev/null 2>&1; then
            success "Repositório atualizado"
        else
            warn "Falha ao atualizar. Pode ser necessário configurar autenticação."
        fi
    fi

    # 4. Registro automático no servidor
    section "Registro Automático no Servidor"

    log "Tentando detectar e registrar no servidor automaticamente..."

    # Função para detectar servidor na rede
    detect_server() {
        local server_ip=""

        # Tentar descobrir via mDNS/Bonjour se disponível
        if command_exists avahi-browse; then
            log "Procurando servidor via mDNS..."
            server_ip=$(avahi-browse -t _cluster-ai._tcp | grep "IPv4" | head -1 | awk '{print $8}' | cut -d';' -f1)
            if [ -n "$server_ip" ]; then
                success "Servidor encontrado via mDNS: $server_ip"
                return 0
            fi
        fi

        # Fallback: tentar IPs comuns na rede local
        local network_prefix
        network_prefix=$(echo "$ip" | cut -d'.' -f1-3)

        log "Escaneando rede local por servidores..."
        for i in {1..254}; do
            local test_ip="${network_prefix}.${i}"
            if [ "$test_ip" != "$ip" ]; then
                # Testar se há um servidor SSH na porta padrão
                if timeout 2 bash -c "echo >/dev/tcp/$test_ip/22" 2>/dev/null; then
                    # Verificar se é um servidor do cluster-ai
                    if ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=no "root@$test_ip" "test -f /opt/cluster-ai/manager.sh" 2>/dev/null; then
                        server_ip="$test_ip"
                        success "Servidor encontrado: $server_ip"
                        break
                    fi
                fi
            fi
        done

        if [ -n "$server_ip" ]; then
            echo "$server_ip"
            return 0
        else
            return 1
        fi
    }

    # Função para registrar worker no servidor
    register_worker() {
        local server_ip="$1"
        local worker_name="${hostname}-worker"
        local worker_ip="$ip"
        local worker_user="$user"
        local worker_port="22"
        local pub_key
        pub_key=$(cat "$HOME/.ssh/id_rsa.pub")

        log "Registrando worker no servidor $server_ip..."

        # Criar arquivo de registro temporário
        local reg_file="/tmp/worker_registration_${worker_name}.json"
        cat > "$reg_file" << EOF
{
    "worker_name": "$worker_name",
    "worker_ip": "$worker_ip",
    "worker_user": "$worker_user",
    "worker_port": "$worker_port",
    "public_key": "$pub_key",
    "timestamp": "$(date +%s)"
}
EOF

        # Enviar registro via SCP
        if scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$reg_file" "root@$server_ip:/tmp/"; then
            # Executar script de registro no servidor
            if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "root@$server_ip" "
                if [ -f /opt/cluster-ai/scripts/management/worker_registration.sh ]; then
                    bash /opt/cluster-ai/scripts/management/worker_registration.sh /tmp/worker_registration_${worker_name}.json
                    rm -f /tmp/worker_registration_${worker_name}.json
                    echo 'SUCCESS'
                else
                    echo 'REGISTRATION_SCRIPT_NOT_FOUND'
                fi
            " 2>/dev/null; then
                success "Worker registrado com sucesso no servidor!"
                return 0
            else
                warn "Falha no registro automático. Você pode registrar manualmente."
                return 1
            fi
        else
            warn "Não foi possível conectar ao servidor para registro automático."
            return 1
        fi

        # Limpar arquivo temporário
        rm -f "$reg_file"
    }

    # Tentar detecção e registro automático
    if server_ip=$(detect_server); then
        if register_worker "$server_ip"; then
            success "✅ Worker registrado automaticamente!"
            info "O servidor agora pode se conectar a este worker automaticamente."
        else
            warn "⚠️  Registro automático falhou, mas o worker está configurado."
        fi
    else
        warn "⚠️  Nenhum servidor detectado automaticamente."
    fi

    # 5. Configuração final
    section "Configuração Concluída!"
    success "Seu dispositivo Linux/Unix está pronto para ser usado como um worker."
    echo
    info "Informações do worker:"
    echo -e "   • ${YELLOW}Nome:${NC} ${hostname}-worker"
    echo -e "   • ${YELLOW}IP:${NC} $ip"
    echo -e "   • ${YELLOW}Usuário:${NC} $user"
    echo -e "   • ${YELLOW}Porta SSH:${NC} 22"
    echo
    echo -e "${YELLOW}Chave SSH pública:${NC}"
    echo "--------------------------------------------------"
    cat "$HOME/.ssh/id_rsa.pub"
    echo "--------------------------------------------------"
    echo
    if [ -n "$server_ip" ]; then
        info "✅ Registrado automaticamente no servidor: $server_ip"
    else
        info "Para registrar manualmente no servidor:"
        echo "1. Execute no servidor: ./manager.sh"
        echo "2. Escolha 'Configurar Cluster' > 'Gerenciar Workers Registrados Automaticamente'"
        echo "3. Adicione o worker com as informações acima"
    fi

    echo
    info "Para testar a conexão:"
    echo "ssh -o StrictHostKeyChecking=no $user@$ip"
}

main "$@"
