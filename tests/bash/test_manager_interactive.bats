#!/usr/bin/env bats

# test_manager_interactive.bats
# Testes para funções interativas do manager.sh

setup() {
    # Carrega as bibliotecas de asserção e suporte do BATS.
    # O caminho é relativo ao diretório do arquivo de teste.
    load "$BATS_TEST_DIRNAME/libs/bats-support/load.bash"
    load "$BATS_TEST_DIRNAME/libs/bats-assert/load.bash"

    # Carrega o script que contém as funções a serem testadas.
    # É importante carregar a biblioteca de funções comuns primeiro, pois manager.sh depende dela.
    source "$BATS_TEST_DIRNAME/../../scripts/utils/common_functions.sh"
    source "$BATS_TEST_DIRNAME/../../manager.sh"
}

@test "confirm_operation: deve retornar sucesso (0) quando o usuário digita 's'" {
    # A mágica acontece aqui:
    # Usamos um "Here String" (<<<) para passar a string "s" para o standard input
    # do comando 'run'. O comando 'read' dentro da função irá consumir essa string.
    #
    # Usamos 'bash -c' para garantir que a função seja executada em um shell que a conheça.
    run bash -c "confirm_operation 'Mensagem de teste'" <<< "s"

    # Asserções usando bats-assert para maior clareza
    assert_success
    assert_output --partial "Mensagem de teste Deseja continuar? (s/N)"
}

@test "confirm_operation: deve retornar falha (1) quando o usuário digita 'n'" {
    # Da mesma forma, passamos "n" para o stdin.
    run bash -c "confirm_operation 'Mensagem de teste'" <<< "n"

    # A função deve retornar um código de saída diferente de 0.
    assert_failure
}

@test "confirm_operation: deve retornar falha (1) quando o usuário pressiona Enter (padrão)" {
    # Passamos uma string vazia para simular o usuário apenas pressionando Enter.
    run bash -c "confirm_operation 'Mensagem de teste'" <<< ""

    # A função deve retornar um código de saída diferente de 0.
    assert_failure
}