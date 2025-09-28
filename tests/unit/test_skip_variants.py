"""
Exemplo de teste que demonstra a diferença entre
pytest.mark.skip e pytest.skip().
"""

import os

import pytest


@pytest.mark.skip(
    reason="Este teste está desativado permanentemente por decisão da equipe."
)
def test_declarative_skip():
    """
    Este teste usa o decorador e seu código nunca é executado.
    """
    print("\nEsta mensagem nunca aparecerá.")
    assert False


def test_imperative_skip():
    """
    Este teste usa a chamada de função e é pulado com base em uma condição de runtime.
    """
    if "CI" in os.environ:
        pytest.skip("Este teste não deve ser executado em ambientes de CI.")
    print("\nEsta mensagem só aparece se não estiver em um ambiente de CI.")
    assert True
