"""
Exemplo de teste que utiliza o plugin pytest-timeout.
"""

import pytest
import time


@pytest.mark.timeout(1)
def test_should_fail_due_to_timeout():
    """
    Este teste está marcado para falhar se demorar mais de 1 segundo.
    Como ele dorme por 2 segundos, o pytest-timeout o interromperá.
    """
    time.sleep(2)
    assert True  # Esta linha nunca será alcançada


def test_should_pass_quickly():
    """Este teste é rápido e não tem timeout, então deve passar."""
    assert 1 + 1 == 2
