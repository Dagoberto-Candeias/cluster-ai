"""
Exemplo de teste de timeout usando pytest nativo.
"""

import time

import pytest


def test_should_pass_quickly():
    """Este teste é rápido e deve passar."""
    assert 1 + 1 == 2


def test_timeout_simulation():
    """
    Este teste simula um timeout usando pytest nativo.
    Em um cenário real, você usaria o plugin pytest-timeout.
    """
    # Simular uma operação que pode demorar
    start_time = time.time()
    time.sleep(0.1)  # Dorme por 100ms (bem abaixo do limite)
    elapsed = time.time() - start_time

    # Verificar que a operação foi rápida
    assert elapsed < 1.0, f"Operação demorou {elapsed:.2f}s, esperado < 1.0s"
    assert True
