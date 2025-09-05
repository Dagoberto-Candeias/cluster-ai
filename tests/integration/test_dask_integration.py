"""
Testes de integração para componentes Dask

Este módulo testa a integração entre diferentes componentes
do sistema distribuído usando Dask.
"""

import pytest
import sys
from pathlib import Path

# Adicionar diretório raiz ao path
PROJECT_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


class TestDaskClusterIntegration:
    """Testes de integração REAL do cluster Dask"""

    @pytest.mark.integration
    @pytest.mark.slow  # Marcar como lento, pois inicia um cluster real
    def test_real_cluster_computation(self, real_dask_cluster):
        """
        Testa a execução de uma computação distribuída em um cluster Dask real,
        gerenciado pela fixture 'real_dask_cluster'.
        """
        # O cliente Dask é injetado pela fixture
        client = real_dask_cluster
        assert client is not None
        assert not client.status == "closed"

        # Importar as funções a serem usadas
        from demo_cluster import process_with_dask, processamento_pesado as square_task

        # Act: Executar uma tarefa distribuída real
        numbers = list(range(10))
        results = process_with_dask(client, numbers, square_task)

        # Assert: Verificar se o resultado está correto
        expected_results = [x * x for x in numbers]
        assert results == expected_results

    @pytest.mark.integration
    @pytest.mark.slow
    def test_real_cluster_fibonacci_computation(self, real_dask_cluster):
        """
        Testa a execução da tarefa de Fibonacci em um cluster Dask real,
        demonstrando a reutilização da fixture.
        """
        # Arrange
        client = real_dask_cluster
        assert client is not None

        from demo_cluster import process_with_dask, calcular_fibonacci as fibonacci_task

        numbers = [10, 15, 20]
        expected_results = [fibonacci_task(n) for n in numbers]  # [55, 610, 6765]

        # Act
        results = process_with_dask(client, numbers, fibonacci_task)

        # Assert
        assert results == expected_results
