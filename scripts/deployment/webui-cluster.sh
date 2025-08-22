#!/bin/bash
# ================================================================
# Open WebUI + Ollama Cluster Installer & Manager
# Autor: Dagoberto Candeias
# Email: betoallnet@gmail.com
# ================================================================

# Diretórios e variáveis
CLUSTER_ENV="$HOME/cluster_env"
DATA_DIR="$HOME/open-webui"
CONTAINER_NAME="open-webui"
IMAGE_NAME="ghcr.io/open-webui/open-webui:main"
EMAIL="betoallnet@gmail.com"

# Detecta IP do host para o Ollama
detect_ollama_url() {
    if curl -s http://host.docker.internal:11434/api/tags >/dev/null 2>&1; then
        echo "http://host.docker.internal:11434"
    else
        echo "http://172.17.0.1:11434"
    fi
}

OLLAMA_URL=$(detect_ollama_url)

# Funções auxiliares
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo "⚠️ Docker não encontrado. Instalando..."
        sudo apt update && sudo apt install -y docker.io
        sudo systemctl enable docker --now
    fi
}

check_python() {
    if ! command -v python3 &>/dev/null; then
        echo "⚠️ Python3 não encontrado. Instalando..."
        sudo apt update && sudo apt install -y python3 python3-venv python3-pip
    fi
}

create_env() {
    if [ ! -d "$CLUSTER_ENV" ]; then
        echo "📦 Criando ambiente virtual..."
        python3 -m venv "$CLUSTER_ENV"
    fi
}

activate_env() {
    echo "✅ Ativando ambiente..."
    source "$CLUSTER_ENV/bin/activate"
}

deactivate_env() {
    echo "🚪 Desativando ambiente..."
    deactivate 2>/dev/null || true
}

install_dependencies() {
    activate_env
    pip install --upgrade pip
    pip install dask[complete] distributed numpy pandas scipy mpi4py
    deactivate_env
}

run_openwebui() {
    check_docker
    if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        echo "⚠️ Container já existe. Removendo..."
        docker stop $CONTAINER_NAME >/dev/null 2>&1
        docker rm $CONTAINER_NAME >/dev/null 2>&1
    fi

    mkdir -p "$DATA_DIR"

    echo "🚀 Iniciando Open WebUI com Ollama URL: $OLLAMA_URL"
    docker run -d --name $CONTAINER_NAME         -p 8080:8080         -v $DATA_DIR:/app/data         -e OLLAMA_BASE_URL=$OLLAMA_URL         $IMAGE_NAME
}

stop_openwebui() {
    echo "🛑 Parando container..."
    docker stop $CONTAINER_NAME || echo "⚠️ Container não encontrado."
    docker rm $CONTAINER_NAME || true
}

status() {
    echo "📊 Status do Open WebUI:"
    docker ps --filter "name=$CONTAINER_NAME"
}

send_test_email() {
    echo "Teste de alerta OpenWebUI" | mail -s "Teste OK" $EMAIL || echo "⚠️ Falha ao enviar email."
}

# Menu interativo
while true; do
    clear
    echo "======================================="
    echo "  OPEN WEBUI + OLLAMA CLUSTER MANAGER  "
    echo "======================================="
    echo "1) Instalar dependências"
    echo "2) Criar ambiente virtual"
    echo "3) Ativar ambiente"
    echo "4) Desativar ambiente"
    echo "5) Instalar pacotes no ambiente"
    echo "6) Iniciar Open WebUI"
    echo "7) Parar Open WebUI"
    echo "8) Ver status do Open WebUI"
    echo "9) Testar envio de email"
    echo "0) Sair"
    echo "---------------------------------------"
    read -rp "Escolha uma opção: " choice

    case $choice in
        1) check_python && check_docker ;;
        2) create_env ;;
        3) activate_env ;;
        4) deactivate_env ;;
        5) install_dependencies ;;
        6) run_openwebui ;;
        7) stop_openwebui ;;
        8) status ;;
        9) send_test_email ;;
        0) echo "👋 Saindo..."; exit 0 ;;
        *) echo "⚠️ Opção inválida!";;
    esac
    echo "Pressione ENTER para continuar..."
    read
done
