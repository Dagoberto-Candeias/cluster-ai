#!/usr/bin/env bats

# test_downloader.bats
# Testes para o script downloader.sh, com mocking do comando curl.

setup_file() {
    load "$BATS_TEST_DIRNAME/libs/bats-support/load.bash"
    load "$BATS_TEST_DIRNAME/libs/bats-assert/load.bash"

    # Cria um diretório temporário para os "downloads"
    TEST_DIR="$(mktemp -d)"

    # O script que vamos testar
    SCRIPT_TO_TEST="$BATS_TEST_DIRNAME/../../scripts/utils/downloader.sh"
}

teardown_file() {
    rm -rf "$TEST_DIR"
}

@test "downloader: deve baixar um arquivo com sucesso" {
    # --- Mock de curl para SUCESSO ---
    curl() {
        # Imprime os argumentos recebidos para que possamos verificá-los.
        echo "curl_mock: Chamado com os argumentos: $@"

        # Simula a criação do arquivo de saída com conteúdo.
        # O argumento $4 é o arquivo de saída quando se usa 'curl -o <arquivo>'.
        echo "conteúdo do arquivo falso" > "$4"

        # Retorna 0 para simular sucesso.
        return 0
    }
    export -f curl

    local output_path="${TEST_DIR}/downloaded_file.txt"
    run bash "$SCRIPT_TO_TEST" "http://example.com/file.txt" "$output_path"

    assert_success
    # Verifica se o curl foi chamado com os argumentos corretos
    assert_output --partial "curl_mock: Chamado com os argumentos: -fLs -o ${output_path} http://example.com/file.txt"
    # Verifica se o arquivo foi criado
    assert_file_exist "$output_path"
    # Verifica o conteúdo do arquivo
    assert_file_contents --equals "conteúdo do arquivo falso" "$output_path"
}

@test "downloader: deve falhar e limpar o arquivo parcial em caso de erro" {
    # --- Mock de curl para FALHA ---
    curl() {
        # Simplesmente retorna um código de erro para simular uma falha de rede.
        return 22 # Código de erro comum do curl para 404
    }
    export -f curl

    local output_path="${TEST_DIR}/failed_download.txt"
    run bash "$SCRIPT_TO_TEST" "http://example.com/nonexistent.txt" "$output_path"

    assert_failure
    assert_output --partial "Falha no download"
    # Verifica se o script limpou o arquivo parcial que poderia ter sido criado.
    refute_file_exist "$output_path"
}