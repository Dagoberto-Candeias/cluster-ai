#!/usr/bin/env bats

# test_install_unified.bats
# Testes unitários para o script install_unified.sh

setup() {
    # Carrega as bibliotecas de asserção e suporte do BATS, que foram adicionadas como submódulos.
    load "$BATS_TEST_DIRNAME/libs/bats-support/load.bash"
    load "$BATS_TEST_DIRNAME/libs/bats-assert/load.bash"

    # Define uma variável de projeto raiz para o teste
    export PROJECT_ROOT="/tmp/test_project"
    mkdir -p "$PROJECT_ROOT"

    # Carrega o script que queremos testar.
    # Isso torna as funções do script disponíveis para os testes.
    source "$BATS_TEST_DIRNAME/../../install_unified.sh"
}

teardown() {
    # Limpa o diretório de teste
    rm -rf "/tmp/test_project"
}

@test "check_disk_space: deve retornar sucesso se houver espaço suficiente" {
    # Mock (simulação) do comando 'df' para retornar um valor alto de espaço disponível.
    # Esta função 'df' só existe dentro deste caso de teste.
    df() {
        echo "Filesystem 1K-blocks      Used Available Use% Mounted on"
        echo "/dev/sda1   1000000000 100000000 900000000  10% /"
    }
    # Exporta a função mockada para que o subshell do script a veja.
    export -f df

    # Executa a função a ser testada
    run check_disk_space

    # Asserções usando bats-assert
    assert_success
    assert_output --partial "Espaço em disco suficiente"
}

@test "check_disk_space: deve retornar falha se não houver espaço suficiente" {
    # Mock do comando 'df' para retornar um valor baixo de espaço disponível (1000 KB = 1MB).
    df() {
        echo "Filesystem 1K-blocks Used Available Use% Mounted on"
        echo "/dev/sda1   100000000 99999000      1000  100% /"
    }
    export -f df

    run check_disk_space

    # Asserções usando bats-assert
    assert_failure
    assert_output --partial "Espaço em disco insuficiente"
}