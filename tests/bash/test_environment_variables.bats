#!/usr/bin/env bats

# test_environment_variables.bats
# Testes para scripts que modificam variáveis de ambiente globais.

setup() {
    # Carrega as bibliotecas de asserção
    load "$BATS_TEST_DIRNAME/libs/bats-support/load.bash"
    load "$BATS_TEST_DIRNAME/libs/bats-assert/load.bash"

    # O script a ser testado
    SCRIPT_TO_TEST="$BATS_TEST_DIRNAME/../../scripts/utils/set_cluster_env.sh"
}

@test "set_cluster_env: deve definir CLUSTER_ENV para 'development' por padrão" {
    # Carrega o script e chama a função diretamente
    run bash -c "source '$SCRIPT_TO_TEST' >/dev/null && set_cluster_env"

    # Verifica se o comando foi bem-sucedido e se a saída é exatamente o que esperamos.
    assert_success
    assert_output "development"
}

@test "set_cluster_env: deve definir CLUSTER_ENV para 'production' quando especificado" {
    # A mesma técnica, mas passando o argumento 'production' para o script.
    run bash -c "source '$SCRIPT_TO_TEST' >/dev/null && set_cluster_env 'production'"

    # Verifica o resultado
    assert_success
    assert_output "production"
}

@test "Verificação de isolamento: CLUSTER_ENV não deve estar definido aqui" {
    # Este teste prova que a variável CLUSTER_ENV definida nos testes anteriores
    # não "vazou" para este teste. A asserção falhará se a variável existir.
    # Esta verificação continua sendo válida e importante.
    run bash -c 'echo "${CLUSTER_ENV:-NOT_SET}"'
    assert_success
    assert_output "NOT_SET"
}
