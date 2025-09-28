#!/usr/bin/env bats

# test_file_operations.bats
# Testes para funções que manipulam arquivos, como logs e backups.

setup_file() {
    # Esta função é executada UMA VEZ antes de todos os testes neste arquivo.
    # Ideal para setups caros e que não mudam entre os testes.
    load "$BATS_TEST_DIRNAME/libs/bats-support/load.bash"
    load "$BATS_TEST_DIRNAME/libs/bats-assert/load.bash"

    # 1. Cria o ambiente de teste temporário UMA VEZ.
    TEST_ROOT="$(mktemp -d)"

    # 2. Sobrescreve e exporta a variável de projeto UMA VEZ.
    PROJECT_ROOT="$TEST_ROOT"
    export PROJECT_ROOT

    # 3. Carrega os scripts pesados UMA VEZ.
    source "$BATS_TEST_DIRNAME/../../scripts/utils/common_functions.sh"
    source "$BATS_TEST_DIRNAME/../../manager.sh"

    # 4. Cria a estrutura de diretórios base UMA VEZ.
    mkdir -p "${PROJECT_ROOT}/logs"
    mkdir -p "${PROJECT_ROOT}/backups"
}

teardown_file() {
    # Esta função é executada UMA VEZ após todos os testes neste arquivo.
    # Limpa o ambiente de teste criado em setup_file.
    rm -rf "$TEST_ROOT"
}

setup() {
    # Esta função é executada ANTES DE CADA teste.
    # Ideal para recriar o estado que cada teste modifica.
    echo "dask log entry" > "${PROJECT_ROOT}/logs/dask_cluster.log"
    echo "nginx log entry" > "${PROJECT_ROOT}/logs/nginx.log"
    # Garante que o diretório de backups esteja vazio antes de cada teste.
    rm -f "${PROJECT_ROOT}/backups/*"
}

@test "archive_logs: deve criar um arquivo .tar.gz e limpar os logs originais" {
    # --- Execução ---
    # Executa a função. Passamos "--force" para evitar o prompt de confirmação interativo.
    run archive_logs --force

    # --- Asserções ---
    assert_success

    # 1. Verifica se o arquivo de arquivamento foi criado no diretório de backups
    # Usamos 'find' para encontrar o arquivo, já que o nome contém um timestamp.
    local archive_file
    archive_file=$(find "${PROJECT_ROOT}/backups" -name "logs_archive_*.tar.gz")
    assert_file_exist "$archive_file"

    # 2. Verifica o conteúdo do arquivo de arquivamento
    # Extraímos a lista de arquivos dentro do .tar.gz e verificamos se os logs estão lá.
    local archive_content
    archive_content=$(tar -tzf "$archive_file")
    assert_output --string "$archive_content" --partial "dask_cluster.log"
    assert_output --string "$archive_content" --partial "nginx.log"

    # 3. Verifica se os arquivos de log originais foram limpos (tamanho 0)
    assert_file_exist "${PROJECT_ROOT}/logs/dask_cluster.log"
    local log_size
    log_size=$(stat -c %s "${PROJECT_ROOT}/logs/dask_cluster.log")
    assert_equal "$log_size" "0"

    assert_file_exist "${PROJECT_ROOT}/logs/nginx.log"
    log_size=$(stat -c %s "${PROJECT_ROOT}/logs/nginx.log")
    assert_equal "$log_size" "0"
}