"""
Exemplo de teste que demonstra a interação entre fixtures
com escopos 'session' e 'function'.
"""

import pytest

# Armazenará o ID do objeto da fixture de sessão para comparação
session_fixture_id = None


@pytest.fixture(scope="session")
def my_session_fixture():
    """Uma fixture simples com escopo de sessão."""
    print("\n[SETUP - SESSION] Criando recurso de sessão...")
    data = {"created_at": "start_of_session"}
    yield data
    print("\n[TEARDOWN - SESSION] Limpando recurso de sessão...")


@pytest.fixture(scope="function")
def my_function_fixture():
    """Uma fixture simples com escopo de função."""
    print("\n[SETUP - FUNCTION] Criando recurso de função...")
    yield {"created_at": "start_of_function"}
    print("\n[TEARDOWN - FUNCTION] Limpando recurso de função...")


def test_one(my_session_fixture, my_function_fixture):
    global session_fixture_id
    session_fixture_id = id(my_session_fixture)
    assert id(my_session_fixture) == session_fixture_id


def test_two(my_session_fixture, my_function_fixture):
    # O ID do objeto da fixture de sessão deve ser o MESMO do teste anterior.
    assert id(my_session_fixture) == session_fixture_id
