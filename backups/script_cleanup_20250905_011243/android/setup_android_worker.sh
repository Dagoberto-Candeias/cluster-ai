#!/bin/bash
# =============================================================================
# Local: scripts/android/setup_android_worker.sh
# =============================================================================
# Autor: Dagoberto Candeias <betoallnet@gmail.com>
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: setup_android_worker.sh
# =============================================================================

#!/data/data/com.termux/files/usr/bin/bash
# Local: scripts/android/setup_android_worker.sh
# Autor: Dagoberto Candeias <betoallnet@gmail.com>
# Script para configurar um dispositivo Android como um Worker do Cluster AI via Termux.
#
# INSTRUÇÕES:
# 1. Instale o Termux no seu dispositivo Android.
# 2. Execute o comando: termux-setup-storage
# 3. Execute este script colando o seguinte comando no Termux:
#    curl -fsSL https://raw.githubusercontent.com/Dagoberto-Candeias/cluster-ai/main/scripts/android/setup_android_worker.sh | bash

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

main() {
    section "Configurador de Worker Android para Cluster AI"

    # 1. Atualizar pacotes do Termux
    log "Atualizando pacotes do Termux..."
    pkg update -y && pkg upgrade -y

    # 2. Instalar dependências essenciais
    log "Instalando dependências: openssh, python, git, ncurses-utils..."
    log "Isso pode levar alguns minutos..."

    # Instalar com timeout para evitar travamentos
    if timeout 300 pkg install -y openssh python git ncurses-utils curl >/dev/null 2>&1; then
        success "Dependências instaladas com sucesso"
    else
        error "Falha ao instalar dependências. Verifique sua conexão com a internet."
        exit 1
    fi

    # 3. Configurar e iniciar o servidor SSH
    section "Configurando Servidor SSH"
    if [ ! -f "$HOME/.ssh/id_rsa" ]; then
        log "Gerando chave SSH para o dispositivo..."
        ssh-keygen -t rsa -b 4096 -N "" -f "$HOME/.ssh/id_rsa"
    fi

    log "Iniciando o servidor SSH na porta 8022..."
    sshd

    local user; user=$(whoami)
    local ip; ip=$(ip route get 1 | awk '{print $7; exit}')
    success "Servidor SSH iniciado! Conecte-se com: ssh $user@$ip -p 8022"

    # 4. Clonar o repositório do Cluster AI
    section "Clonando o Projeto Cluster AI"
    if [ ! -d "$HOME/Projetos/cluster-ai" ]; then
        mkdir -p "$HOME/Projetos"

        # Tentar primeiro com SSH (para repositórios privados)
        log "Tentando clonar via SSH..."
        if git clone git@github.com:Dagoberto-Candeias/cluster-ai.git "$HOME/Projetos/cluster-ai" >/dev/null 2>&1; then
            success "Projeto clonado via SSH"
        else
            warn "Falha no SSH, tentando via HTTPS..."
            # Fallback para HTTPS (público ou com token)
            if git clone https://github.com/Dagoberto-Candeias/cluster-ai.git "$HOME/Projetos/cluster-ai" >/dev/null 2>&1; then
                success "Projeto clonado via HTTPS"
            else
                error "Falha ao clonar repositório"
                echo
                echo "🔧 SOLUÇÕES PARA REPOSITÓRIO PRIVADO:"
                echo "1. Configure sua chave SSH no GitHub:"
                echo "   - Vá em: https://github.com/settings/keys"
                echo "   - Adicione a chave pública que será exibida no final."
                echo
                echo "2. Ou use token de acesso pessoal:"
                echo "   - Crie token em: https://github.com/settings/tokens"
                echo "   - Execute: git clone https://TOKEN@github.com/Dagoberto-Candeias/cluster-ai.git"
                echo
                echo "3. Execute este script novamente após configurar a autenticação."
                exit 1
            fi
        fi
    else
        log "Projeto já existe, atualizando..."
        cd "$HOME/Projetos/cluster-ai"
        if ! git pull >/dev/null 2>&1; then
            warn "Falha ao atualizar. Pode ser necessário configurar autenticação."
        else
            success "Projeto atualizado com sucesso."
        fi
    fi

    # 5. Registro automático no servidor
    section "Registro Automático no Servidor"

    log "Tentando detectar e registrar no servidor automaticamente..."

    # Função para detectar servidor na rede
    detect_server() {
        local server_ip=""
        local server_port="22"

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

    # Função para copiar a chave SSH para o servidor
    copy_ssh_key_to_server() {
        local server_ip="$1"
        local server_user="$2"

        if ! command -v ssh-copy-id >/dev/null 2>&1; then
            warn "Comando 'ssh-copy-id' não encontrado. Pulando cópia automática da chave."
            warn "Você precisará registrar o worker manualmente."
            return 1
        fi

        info "Tentando copiar a chave SSH para o servidor $server_ip..."
        info "Você precisará digitar a senha do usuário '${server_user}' no servidor UMA ÚNICA VEZ."
        if ssh-copy-id -p 22 "${server_user}@${server_ip}"; then
            success "Chave SSH copiada com sucesso para o servidor!"
            return 0
        fi
    }

    # Função para registrar worker no servidor
    register_worker() {
        local server_ip="$1"
        local worker_name="android-$(hostname)"
        local worker_ip="$ip"
        local worker_user="$user"
        local worker_port="8022"
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

        local server_user="dcm" # Use a dedicated user on the server for registration

        # Tenta copiar a chave SSH primeiro para automatizar o login
        if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "${server_user}@${server_ip}" "echo 'OK'" >/dev/null 2>&1; then
            copy_ssh_key_to_server "$server_ip" "$server_user"
        fi

        # Enviar registro via SCP
        if scp -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$reg_file" "${server_user}@${server_ip}:/tmp/"; then
            # Executar script de registro no servidor
            if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${server_user}@${server_ip}" "
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

    section "Configuração Concluída!"
    success "Seu dispositivo Android está pronto para ser usado como um worker."
    echo
    info "Informações do worker:"
    echo -e "   • ${YELLOW}Nome:${NC} android-$(hostname)"
    echo -e "   • ${YELLOW}IP:${NC} $ip"
    echo -e "   • ${YELLOW}Usuário:${NC} $user"
    echo -e "   • ${YELLOW}Porta SSH:${NC} 8022"
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
        echo "2. Escolha 'Configurar Cluster' > 'Gerenciar Workers Remotos'"
        echo "3. Adicione o worker com as informações acima"
    fi
}

main
