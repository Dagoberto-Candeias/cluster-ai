#!/usr//bin/env bats

#
# Teste de Integração: Valida a comunicação entre o manager e um worker simulado.
#

load '/usr/lib/bats/bats-support/load.bash'
load '/usr/lib/bats/bats-assert/load.bash'

DOCKER_IMAGE_NAME="test-worker:latest"
DOCKER_CONTAINER_NAME="test-worker-container"
REMOTE_WORKER_MANAGER_SCRIPT="./scripts/management/remote_worker_manager.sh"

# --- Funções de Setup e Teardown ---

setup() {
    # Executado antes de cada teste
    echo "--- Setting up test environment ---"

    # Construir a imagem do worker simulado
    docker build -t "$DOCKER_IMAGE_NAME" -f tests/integration/Dockerfile.worker .

    # Iniciar o container do worker em background
    docker run -d --rm --name "$DOCKER_CONTAINER_NAME" "$DOCKER_IMAGE_NAME"

    # Obter o IP do container
    WORKER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$DOCKER_CONTAINER_NAME")
    
    # Gerar uma chave SSH para o teste
    ssh-keygen -t rsa -b 2048 -f /tmp/test_ssh_key -N ""

    # Copiar a chave pública para o container do worker
    docker exec "$DOCKER_CONTAINER_NAME" mkdir -p /home/testuser/.ssh
    docker cp /tmp/test_ssh_key.pub "${DOCKER_CONTAINER_NAME}:/home/testuser/.ssh/authorized_keys"
    docker exec "$DOCKER_CONTAINER_NAME" chown testuser:testuser -R /home/testuser/.ssh

    # Adicionar a chave do host do worker ao known_hosts para evitar prompts
    ssh-keyscan -H "$WORKER_IP" >> ~/.ssh/known_hosts

    # Criar arquivo de configuração de nós para o teste
    mkdir -p "$HOME/.cluster_config"
    echo "test-worker $WORKER_IP testuser" > "$HOME/.cluster_config/nodes_list.conf"

    echo "Worker IP: $WORKER_IP"
    echo "Test setup complete."
}

teardown() {
    # Executado após cada teste
    echo "--- Tearing down test environment ---"
    docker stop "$DOCKER_CONTAINER_NAME" || true
    rm -f /tmp/test_ssh_key /tmp/test_ssh_key.pub
    rm -f "$HOME/.cluster_config/nodes_list.conf"
    echo "Teardown complete."
}

# --- Testes ---

@test "Integration: remote_worker_manager.sh - check-ssh should connect successfully" {
    # Executa o comando de verificação de SSH do gerenciador
    run bash "$REMOTE_WORKER_MANAGER_SCRIPT" check-ssh

    # Verifica se a saída contém a mensagem de sucesso
    assert_success
    assert_output --partial "Conexão com test-worker: OK"
}

@test "Integration: remote_worker_manager.sh - exec should run a command on the worker" {
    # Executa um comando 'hostname' no worker remoto
    run bash "$REMOTE_WORKER_MANAGER_SCRIPT" exec "hostname"

    # Verifica se a saída contém o hostname do container (que é seu ID curto)
    assert_success
    assert_output --partial "$(docker inspect --format '{{.Config.Hostname}}' "$DOCKER_CONTAINER_NAME")"
}