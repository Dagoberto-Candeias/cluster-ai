"""
Smoke Tests - Testes de Fumaça

Estes testes verificam se a aplicação pode ser iniciada e se os
componentes mais críticos estão disponíveis, sem testar a lógica de negócio.
"""

import pytest


def test_import_main_modules():
    """
    Verifica se os módulos principais do projeto podem ser importados sem erros.
    """
    try:
        import simple_demo
        import test_installation
        from demo_cluster import demo_avancada, demo_basica
    except ImportError as e:
        pytest.fail(f"Falha ao importar módulo crítico: {e}")


def test_critical_services_can_be_mocked(mock_dask_cluster, mock_pytorch):
    """Verifica se as fixtures de mock para serviços críticos estão funcionando."""
    assert mock_dask_cluster is not None
    assert mock_pytorch is not None
