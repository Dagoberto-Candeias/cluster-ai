"""
Exemplo de teste que demonstra o uso de pytest.skip e pytest.mark.skipif.
"""

import os
import sys

import pytest


def test_unconditional_skip():
    """
    Este teste será sempre pulado porque a funcionalidade
    ainda não foi implementada.
    """
    pytest.skip("Funcionalidade de relatórios avançados ainda não implementada.")
    # Código do teste que nunca será executado
    assert False


@pytest.mark.skipif(
    sys.version_info < (3, 10),
    reason="Este teste requer o 'match-case' do Python 3.10+",
)
def test_feature_requiring_python310():
    """Testa uma funcionalidade que só existe no Python 3.10 ou superior."""
    # Exemplo de código que usaria match-case
    status = 404
    match status:
        case 404:
            assert True
        case _:
            assert False


@pytest.mark.skipif(
    os.getenv("RUN_HEAVY_TESTS") != "true",
    reason="A variável de ambiente RUN_HEAVY_TESTS não está definida como 'true'",
)
def test_heavy_computation():
    """Um teste pesado que só deve rodar quando explicitamente solicitado."""
    # Simula um teste pesado
    assert sum(range(100_000_000)) > 0
