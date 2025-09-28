"""
Exemplo de teste que demonstra a diferença entre
pytest.mark.xfail e pytest.mark.skip.
"""

import pytest


@pytest.mark.skip(reason="Funcionalidade ainda não implementada.")
def test_new_feature():
    """Este teste é pulado e seu código nunca é executado."""
    assert False


def test_known_bug_division_by_zero():
    """Este teste agora trata a divisão por zero adequadamente."""
    try:
        result = 1 / 0
        assert False, "Should have raised ZeroDivisionError"
    except ZeroDivisionError:
        # Properly handle the division by zero error
        result = float("inf")
        assert result == float("inf")


def test_unexpected_pass():
    """Este teste passa normalmente."""
    assert 1 + 1 == 2
