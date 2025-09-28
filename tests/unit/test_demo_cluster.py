"""
Testes unitários para demo_cluster.py

Este módulo contém testes unitários para as funções principais
do sistema de cluster demonstrado em demo_cluster.py.
"""

import sys
from pathlib import Path
from unittest.mock import MagicMock, mock_open, patch

import pytest

# Adicionar diretório raiz ao path
PROJECT_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

# Importar módulos do projeto
try:
    from demo_cluster import calcular_fibonacci as fibonacci_task
    from demo_cluster import create_cluster
    from demo_cluster import demo_avancada as run_demo
    from demo_cluster import process_with_dask
    from demo_cluster import processamento_pesado as square_task
except ImportError:
    pytest.skip(
        "Não foi possível importar os módulos do projeto. Pulando testes unitários.",
        allow_module_level=True,
    )


class TestFibonacciTask:
    """Testes para a função fibonacci_task"""

    def test_fibonacci_base_cases(self):
        """Testa casos base da função fibonacci"""
        assert fibonacci_task(0) == 0
        assert fibonacci_task(1) == 1

    def test_fibonacci_small_values(self):
        """Testa valores pequenos da sequência de Fibonacci"""
        assert fibonacci_task(2) == 1
        assert fibonacci_task(3) == 2
        assert fibonacci_task(4) == 3
        assert fibonacci_task(5) == 5
        assert fibonacci_task(6) == 8

    def test_fibonacci_larger_values(self):
        """Testa valores maiores da sequência de Fibonacci"""
        assert fibonacci_task(10) == 55
        assert fibonacci_task(15) == 610

    @pytest.mark.parametrize(
        "n,expected",
        [
            (0, 0),
            (1, 1),
            (2, 1),
            (3, 2),
            (4, 3),
            (5, 5),
            (6, 8),
            (7, 13),
            (8, 21),
            (9, 34),
            (10, 55),
        ],
    )
    def test_fibonacci_parametrized(self, n, expected):
        """Testa fibonacci com parâmetros variados"""
        assert fibonacci_task(n) == expected


class TestSquareTask:
    """Testes para a função square_task"""

    def test_square_positive_numbers(self):
        """Testa quadrado de números positivos"""
        assert square_task(1) == 1
        assert square_task(2) == 4
        assert square_task(3) == 9
        assert square_task(5) == 25

    def test_square_zero(self):
        """Testa quadrado de zero"""
        assert square_task(0) == 0

    def test_square_negative_numbers(self):
        """Testa quadrado de números negativos"""
        assert square_task(-1) == 1
        assert square_task(-2) == 4
        assert square_task(-3) == 9

    @pytest.mark.parametrize(
        "input_val,expected",
        [(0, 0), (1, 1), (2, 4), (3, 9), (4, 16), (-1, 1), (-2, 4), (-3, 9), (-4, 16)],
    )
    def test_square_parametrized(self, input_val, expected):
        """Testa square com parâmetros variados"""
        assert square_task(input_val) == expected


class TestProcessWithDask:
    """Testes para a função process_with_dask"""

    def test_process_with_square_function(self, mock_dask_cluster):
        """Testa processamento com função quadrado"""
        # Arrange
        client = mock_dask_cluster["client"]
        mock_future = MagicMock()
        client.submit.side_effect = [mock_future] * 5  # 5 futures para 5 números
        client.gather.return_value = [1, 4, 9, 16, 25]  # Resultado esperado
        numbers = [1, 2, 3, 4, 5]
        expected = [1, 4, 9, 16, 25]

        # Act
        result = process_with_dask(client, numbers, square_task)

        # Assert
        assert client.submit.call_count == 5  # Deve ser chamado 5 vezes
        client.gather.assert_called_once_with([mock_future] * 5)
        assert result == expected

    def test_process_empty_list(self, mock_dask_cluster):
        """Testa processamento de lista vazia"""
        # Arrange
        client = mock_dask_cluster["client"]

        # Act
        result = process_with_dask(client, [], square_task)

        # Assert
        assert result == []
        # Para lista vazia, submit e gather não devem ser chamados
        client.submit.assert_not_called()
        client.gather.assert_not_called()


class TestCreateCluster:
    """Testes para a função create_cluster"""

    def test_create_cluster_success(self, mock_dask_cluster):
        """Testa criação bem-sucedida do cluster usando fixture."""
        # Act
        cluster, client = create_cluster()

        # Assert
        assert cluster is not None
        assert client is not None

    @patch("demo_cluster.LocalCluster")
    def test_create_cluster_failure(self, mock_cluster):
        """Testa falha na criação do cluster"""
        # Configurar mock para falhar
        mock_cluster.side_effect = Exception("Erro ao criar cluster")

        # Verificar se a exceção é propagada
        with pytest.raises(Exception, match="Erro ao criar cluster"):
            create_cluster()


class TestRunDemo:
    """Testes para a função run_demo"""

    @patch("demo_cluster.Client")
    @patch("demo_cluster.LocalCluster")
    def test_run_demo_success(self, mock_cluster_class, mock_client_class):
        """Testa execução bem-sucedida da demo"""
        # Arrange: Configurar mocks para simular Dask
        mock_cluster_instance = MagicMock()
        mock_cluster_class.return_value.__enter__.return_value = mock_cluster_instance

        mock_client_instance = MagicMock()
        expected_fib = [832040, 1346269, 2178309, 3524578, 5702887]
        mock_client_instance.gather.return_value = expected_fib
        mock_client_class.return_value.__enter__.return_value = mock_client_instance

        # Executar função
        result = run_demo()

        # Verificar resultado
        assert result["status"] == "success"
        assert result["results"] == expected_fib
        assert "computation_time" in result

    @patch("demo_cluster.LocalCluster")
    def test_run_demo_cluster_failure(self, mock_local_cluster):
        """Testa falha na criação do cluster durante demo"""
        # Configurar mock para falhar
        mock_local_cluster.side_effect = Exception("Falha no cluster")

        # Executar função
        result = run_demo()

        # Verificar resultado de erro
        assert result["status"] == "error"
        assert "error" in result

    @patch("demo_cluster.LocalCluster")
    @patch("demo_cluster.Client")
    def test_run_demo_processing_failure(self, mock_client_class, mock_cluster_class):
        """Testa falha no processamento durante demo"""
        # Configurar mocks
        mock_cluster_instance = MagicMock()
        mock_cluster_class.return_value.__enter__.return_value = mock_cluster_instance
        mock_cluster_class.return_value.__exit__.return_value = None

        mock_client_instance = MagicMock()
        mock_client_instance.submit.side_effect = Exception("Erro no processamento")
        mock_client_class.return_value.__enter__.return_value = mock_client_instance
        mock_client_class.return_value.__exit__.return_value = None

        # Executar função
        result = run_demo()

        # Verificar resultado de erro
        assert result["status"] == "error"
        assert "error" in result


class TestIntegration:
    """Testes de integração entre componentes"""

    @pytest.mark.integration
    def test_full_workflow(self):
        """Testa o workflow de fibonacci e square juntos."""
        fib_results = [fibonacci_task(n) for n in range(6)]
        square_of_fib_results = [square_task(n) for n in fib_results]
        assert square_of_fib_results == [0, 1, 1, 4, 9, 25]


# Testes de performance
class TestPerformance:
    """Testes de performance"""

    @pytest.mark.performance
    def test_fibonacci_performance(self, benchmark):
        """Testa performance da função fibonacci"""
        # A fixture 'benchmark' do pytest-benchmark executa a função
        # várias vezes para obter uma medição precisa.
        result = benchmark(fibonacci_task, 20)
        # A verificação do resultado ainda é importante
        assert result == 6765, "O resultado do benchmark de Fibonacci está incorreto"


# Testes de edge cases
class TestEdgeCases:
    """Testes de casos extremos"""

    def test_very_large_fibonacci(self):
        """Testa fibonacci com valor grande (limite para teste rápido)"""
        result = fibonacci_task(30)
        assert result == 832040

    def test_fibonacci_negative_values(self):
        """
        Testa fibonacci com valores negativos.
        Deve levantar ValueError para entradas negativas.
        """
        with pytest.raises(
            ValueError, match="Fibonacci não está definido para números negativos"
        ):
            fibonacci_task(-1)
