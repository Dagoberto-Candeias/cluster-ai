#!/usr/bin/env bats

# test_manager_mocking.bats
# Testes para demonstrar como mockar (simular) comandos externos em manager.sh

setup() {
    # Carrega as bibliotecas de asserção
    load "$BATS_TEST_DIRNAME/libs/bats-support/load.bash"
    load "$BATS_TEST_DIRNAME/libs/bats-assert/load.bash"

    # Carrega as funções do manager e suas dependências
    source "$BATS_TEST_DIRNAME/../../scripts/utils/common_functions.sh"
    source "$BATS_TEST_DIRNAME/../../manager.sh"
}

@test "install_dependencies: deve tentar instalar pacotes faltando com sudo" {
    # --- Mocks ---

    # 1. Mock 'command_exists' para que ele sempre falhe para 'openssl'
    #    e tenha sucesso para 'pv'.
    command_exists() {
        if [[ "$1" == "openssl" ]]; then
            return 1 # Falha (não encontrado)
        else
            return 0 # Sucesso (encontrado)
        fi
    }

    # 2. Mock 'detect_package_manager' para retornar um valor conhecido.
    detect_package_manager() {
        echo "apt-get"
    }

    # 3. Mock 'sudo'. Esta função simplesmente imprime os argumentos que recebe.
    #    Isso nos permite verificar como 'sudo' foi chamado.
    sudo() {
        echo "sudo_mock: $@"
    }

    # 4. Exporta as funções mockadas para que o subshell do 'run' as veja.
    export -f command_exists
    export -f detect_package_manager
    export -f sudo

    # --- Execução ---

    # Executa a função a ser testada, simulando a resposta 's' para a confirmação.
    run install_dependencies <<< "s"

    # --- Asserções ---

    assert_success
    # Verifica se a saída contém a chamada mockada do sudo com os argumentos corretos.
    assert_output --partial "sudo_mock: apt-get install -y openssl"
}