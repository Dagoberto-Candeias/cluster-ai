#!/bin/bash
# =============================================================================
# WebUI Installer - Cluster AI
# =============================================================================
# Instala e configura o OpenWebUI com Dask e sistema de alertas
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: webui-installer.sh
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURAÇÃO
# =============================================================================
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# =============================================================================
# CORES E ESTILOS
# =============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# =============================================================================
# FUNÇÕES DE LOG
# =============================================================================
log_info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] [INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] [SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR]${NC} $1"
}

# =============================================================================
# FUNÇÃO DE INSTALAÇÃO PARALELA DE PIP
# =============================================================================
parallel_pip_install() {
    local packages="$1"
    local max_workers=4

    log_info "Instalando pacotes Python em paralelo: $packages"

    # Dividir pacotes em grupos para instalação paralela
    local package_array=($packages)
    local total_packages=${#package_array[@]}
    local packages_per_worker=$(( (total_packages + max_workers - 1) / max_workers ))

    local temp_files=()
    for ((i=0; i<max_workers; i++)); do
        local start=$((i * packages_per_worker))
        local end=$((start + packages_per_worker - 1))
        if [ $start -lt $total_packages ]; then
            if [ $end -ge $total_packages ]; then
                end=$((total_packages - 1))
            fi

            local group_packages=""
            for ((j=start; j<=end; j++)); do
                group_packages="${group_packages} ${package_array[j]}"
            done

            local temp_file=$(mktemp)
            echo "pip install $group_packages" > "$temp_file"
            temp_files+=("$temp_file")
        fi
    done

    # Executar instalações em paralelo
    for temp_file in "${temp_files[@]}"; do
        bash "$temp_file" &
    done

    # Aguardar conclusão
    wait
    log_success "Instalações paralelas concluídas"

    # Limpar arquivos temporários
    for temp_file in "${temp_files[@]}"; do
        rm -f "$temp_file"
    done
}

# =============================================================================
# FUNÇÃO DE ALERTA
# =============================================================================
create_alert_script() {
    local alert_script_path="$PROJECT_ROOT/scripts/lib/send_alert.py"

    log_info "Criando script de alertas..."

    cat > "$alert_script_path" << 'EOF'
import smtplib
from email.mime.text import MIMEText
import os

def send_alert(subject, message):
    sender = os.getenv("ALERT_EMAIL", "admin@cluster-ai.local")
    password = os.getenv("ALERT_PASSWORD", "")
    recipient = os.getenv("ALERT_RECIPIENT", "admin@cluster-ai.local")

    msg = MIMEText(message)
    msg["Subject"] = subject
    msg["From"] = sender
    msg["To"] = recipient

    try:
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(sender, password)
            server.sendmail(sender, recipient, msg.as_string())
        print("✅ Alerta enviado com sucesso!")
    except Exception as e:
        print(f"❌ Erro ao enviar alerta: {e}")

if __name__ == "__main__":
    send_alert("Teste", "Mensagem de teste")
EOF

    chmod +x "$alert_script_path"
    log_success "Script de alertas criado: $alert_script_path"
}

# =============================================================================
# FUNÇÃO PRINCIPAL
# =============================================================================
main() {
    log_info "Iniciando instalação do WebUI para Cluster AI"

    # 1. Atualizar sistema
    log_info "Atualizando sistema..."
    sudo apt update && sudo apt upgrade -y

    # 2. Instalar dependências do sistema
    log_info "Instalando dependências do sistema..."
    sudo apt install -y python3 python3-pip python3-venv git curl wget docker.io docker-compose

    # 3. Criar ambiente virtual Python
    log_info "Criando ambiente virtual Python..."
    python3 -m venv cluster-ai-env
    source cluster-ai-env/bin/activate

    # 4. Instalar pacotes Python essenciais
    log_info "Instalando pacotes Python essenciais..."
    pip install --upgrade pip setuptools wheel

    # 5. Instalar Dask com todas as dependências
    log_info "Instalando Dask com dependências completas..."
    parallel_pip_install "dask[complete] distributed flask fastapi uvicorn"

    # 6. Instalar dependências para WebUI
    log_info "Instalando dependências para WebUI..."
    parallel_pip_install "openai aiohttp python-multipart"

    # 7. Instalar ferramentas de monitoramento
    log_info "Instalando ferramentas de monitoramento..."
    parallel_pip_install "psutil requests prometheus_client"

    # 8. Criar script de alertas
    create_alert_script

    # 9. Configurar Docker
    log_info "Configurando Docker..."
    sudo systemctl enable docker
    sudo systemctl start docker

    # 10. Criar diretório para dados
    log_info "Criando diretórios de dados..."
    mkdir -p data/openwebui
    mkdir -p logs

    # 11. Executar OpenWebUI com Docker
    log_info "Executando OpenWebUI com Docker..."
    docker run -d \
        --name openwebui \
        -p 3000:8080 \
        -v $(pwd)/data/openwebui:/app/data \
        -e WEBUI_SECRET_KEY="$(openssl rand -hex 32)" \
        ghcr.io/open-webui/open-webui:main

    # 12. Verificar instalação
    log_info "Verificando instalação..."
    sleep 10

    if curl -f http://localhost:3000/health >/dev/null 2>&1; then
        log_success "OpenWebUI instalado e funcionando!"
        log_info "Acesse: http://localhost:3000"
    else
        log_warn "OpenWebUI pode ainda estar iniciando..."
        log_info "Verifique com: docker logs openwebui"
    fi

    # 13. Configurar Dask scheduler
    log_info "Configurando Dask scheduler..."
    nohup dask scheduler --host 0.0.0.0 --port 8786 --dashboard-address :8787 >/dev/null 2>&1 &
    log_success "Dask scheduler iniciado"

    # 14. Criar script de inicialização
    log_info "Criando script de inicialização..."
    cat > start-cluster-ai.sh << 'EOF'
#!/bin/bash
# Script de inicialização do Cluster AI

echo "🚀 Iniciando Cluster AI..."

# Ativar ambiente virtual
source cluster-ai-env/bin/activate

# Iniciar Dask scheduler
echo "📊 Iniciando Dask scheduler..."
dask scheduler --host 0.0.0.0 --port 8786 --dashboard-address :8787 &

# Iniciar OpenWebUI
echo "🌐 Iniciando OpenWebUI..."
docker start openwebui

# Aguardar serviços
sleep 5

echo "✅ Cluster AI iniciado!"
echo "📊 Dask Dashboard: http://localhost:8787"
echo "🌐 OpenWebUI: http://localhost:3000"
EOF

    chmod +x start-cluster-ai.sh
    log_success "Script de inicialização criado"

    log_success "Instalação do WebUI concluída com sucesso!"
    log_info "Para iniciar o cluster: ./start-cluster-ai.sh"
}

# =============================================================================
# EXECUÇÃO
# =============================================================================
main "$@"
