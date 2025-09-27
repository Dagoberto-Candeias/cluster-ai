#!/usr/bin/env bats
# =============================================================================
# Testes para Funções de Validação - Cluster AI
# =============================================================================
# Testa as funções de validação de entrada do common.sh
#
# Autor: Cluster AI Team
# Versão: 1.0.0
# =============================================================================

setup() {
    # Configurar ambiente de teste
    export PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/.." && pwd)"
    export SCRIPT_DIR="${PROJECT_ROOT}/scripts"

    # Carregar funções comuns
    source "${SCRIPT_DIR}/lib/common.sh"
}

@test "validate_input ip - aceita IP válido privado" {
    run validate_input "ip" "192.168.1.1"

    [ "$status" -eq 0 ]
    [[ "$output" == "192.168.1.1" ]]
}

@test "validate_input ip - aceita IP válido público" {
    run validate_input "ip" "8.8.8.8"

    [ "$status" -eq 0 ]
    [[ "$output" == "8.8.8.8" ]]
}

@test "validate_input ip - rejeita IP de loopback" {
    run validate_input "ip" "127.0.0.1"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "IP de loopback não permitido" ]]
}

@test "validate_input ip - rejeita IP multicast" {
    run validate_input "ip" "224.0.0.1"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "IP multicast não permitido" ]]
}

@test "validate_input ip - rejeita IP de broadcast" {
    run validate_input "ip" "255.255.255.255"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "IP de broadcast não permitido" ]]
}

@test "validate_input ip - rejeita IP de rede" {
    run validate_input "ip" "0.0.0.0"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "IP de rede não permitido" ]]
}

@test "validate_input ip - rejeita IP classe E" {
    run validate_input "ip" "240.0.0.1"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "IP de classe E não permitido" ]]
}

@test "validate_input ip - rejeita formato inválido" {
    run validate_input "ip" "192.168.1.256"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "IP inválido" ]]
}

@test "validate_input ip - rejeita entrada vazia" {
    run validate_input "ip" ""

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Entrada vazia não permitida" ]]
}

@test "validate_input port - aceita porta válida" {
    run validate_input "port" "8080"

    [ "$status" -eq 0 ]
    [[ "$output" == "8080" ]]
}

@test "validate_input port - aceita porta mínima" {
    run validate_input "port" "1"

    [ "$status" -eq 0 ]
    [[ "$output" == "1" ]]
}

@test "validate_input port - aceita porta máxima" {
    run validate_input "port" "65535"

    [ "$status" -eq 0 ]
    [[ "$output" == "65535" ]]
}

@test "validate_input port - rejeita porta zero" {
    run validate_input "port" "0"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Porta inválida" ]]
}

@test "validate_input port - rejeita porta acima do máximo" {
    run validate_input "port" "65536"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Porta inválida" ]]
}

@test "validate_input port - rejeita entrada não numérica" {
    run validate_input "port" "abc"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Porta inválida" ]]
}

@test "validate_input hostname - aceita hostname válido" {
    run validate_input "hostname" "example.com"

    [ "$status" -eq 0 ]
    [[ "$output" == "example.com" ]]
}

@test "validate_input hostname - aceita hostname com hífen" {
    run validate_input "hostname" "my-server"

    [ "$status" -eq 0 ]
    [[ "$output" == "my-server" ]]
}

@test "validate_input hostname - rejeita hostname muito longo" {
    local long_hostname="a123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789.com"
    run validate_input "hostname" "$long_hostname"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Hostname inválido" ]]
}

@test "validate_input hostname - rejeita hostname com caracteres inválidos" {
    run validate_input "hostname" "invalid@host"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Hostname inválido" ]]
}

@test "validate_input service_name - aceita nome válido" {
    run validate_input "service_name" "my_service"

    [ "$status" -eq 0 ]
    [[ "$output" == "my_service" ]]
}

@test "validate_input service_name - aceita nome com hífen" {
    run validate_input "service_name" "my-service"

    [ "$status" -eq 0 ]
    [[ "$output" == "my-service" ]]
}

@test "validate_input service_name - rejeita nome muito longo" {
    local long_name="this_is_a_very_long_service_name_that_exceeds_the_fifty_character_limit"
    run validate_input "service_name" "$long_name"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Nome de serviço inválido" ]]
}

@test "validate_input service_name - rejeita caracteres especiais" {
    run validate_input "service_name" "service@name"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Nome de serviço inválido" ]]
}

@test "validate_input filepath - sanitiza caminho com caracteres perigosos" {
    run validate_input "filepath" "/path/to/file;rm -rf /"

    [ "$status" -eq 0 ]
    [[ "$output" == "/path/to/file rm -rf /" ]]
}

@test "validate_input filepath - aceita caminho normal" {
    run validate_input "filepath" "/home/user/file.txt"

    [ "$status" -eq 0 ]
    [[ "$output" == "/home/user/file.txt" ]]
}

@test "validate_input filepath - rejeita entrada vazia após sanitização" {
    run validate_input "filepath" ";`rm -rf /`"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Caminho de arquivo inválido" ]]
}

@test "validate_input model_name - aceita nome válido" {
    run validate_input "model_name" "llama3:8b"

    [ "$status" -eq 0 ]
    [[ "$output" == "llama3:8b" ]]
}

@test "validate_input model_name - aceita nome com versão" {
    run validate_input "model_name" "mistral-7b-instruct-v0.2"

    [ "$status" -eq 0 ]
    [[ "$output" == "mistral-7b-instruct-v0.2" ]]
}

@test "validate_input model_name - rejeita nome vazio" {
    run validate_input "model_name" ""

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Model name cannot be empty" ]]
}

@test "validate_input model_name - rejeita caracteres inválidos" {
    run validate_input "model_name" "model@name"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid model name" ]]
}

@test "validate_input model_name - rejeita nome muito longo" {
    local long_name="a123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789.com"
    run validate_input "model_name" "$long_name"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid model name" ]]
}

@test "validate_input worker_id - aceita ID válido" {
    run validate_input "worker_id" "worker-01"

    [ "$status" -eq 0 ]
    [[ "$output" == "worker-01" ]]
}

@test "validate_input worker_id - aceita ID alfanumérico" {
    run validate_input "worker_id" "worker123"

    [ "$status" -eq 0 ]
    [[ "$output" == "worker123" ]]
}

@test "validate_input worker_id - rejeita ID vazio" {
    run validate_input "worker_id" ""

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Worker ID cannot be empty" ]]
}

@test "validate_input worker_id - rejeita caracteres especiais" {
    run validate_input "worker_id" "worker@01"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid worker ID" ]]
}

@test "validate_input worker_id - rejeita ID muito longo" {
    local long_id="this_is_a_very_long_worker_id_that_exceeds_the_fifty_character_limit"
    run validate_input "worker_id" "$long_id"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid worker ID" ]]
}

@test "validate_input - rejeita tipo desconhecido" {
    run validate_input "unknown_type" "value"

    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown validation type" ]]
}
