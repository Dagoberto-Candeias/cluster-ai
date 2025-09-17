"""
Exemplo de teste que demonstra a diferença entre
pytest.mark.xfail e pytest.mark.skip.
"""

import pytest


@pytest.mark.skip(reason="Funcionalidade ainda não implementada.")
def test_new_feature():
    """Este teste é pulado e seu código nunca é executado."""
    assert False


@pytest.mark.xfail(reason="Bug #123: Divisão por zero ainda não tratada.")
def test_known_bug_division_by_zero():
    """Este teste é executado, falha como esperado (XFAIL)."""
    result = 1 / 0
    assert result is not None


def test_unexpected_pass():
    """Este teste passa normalmente."""
    assert 1 + 1 == 2
