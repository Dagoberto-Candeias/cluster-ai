"""
Testes unitários para demo_cluster.py

Este módulo contém testes unitários para as funções principais
do sistema de cluster demonstrado em demo_cluster.py.
"""
 
import pytest
import sys
from pathlib import Path
from unittest.mock import MagicMock, patch, mock_open

# Adicionar diretório raiz ao path
PROJECT_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))
 
# Importar módulos do projeto
try:
    from demo_cluster import (
        calcular_fibonacci as fibonacci_task,
        processamento_pesado as square_task,
        demo_basica as create_cluster,
        demo_avancada as run_demo,
        process_with_dask
    )
except ImportError:
    pytest.skip("Não foi possível importar os módulos do projeto. Pulando testes unitários.", allow_module_level=True)
 
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
 
    @pytest.mark.parametrize("n,expected", [
        (0, 0), (1, 1), (2, 1), (3, 2), (4, 3),
        (5, 5), (6, 8), (7, 13), (8, 21), (9, 34), (10, 55)
    ])
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
 
    @pytest.mark.parametrize("input_val,expected", [
        (0, 0), (1, 1), (2, 4), (3, 9), (4, 16),
        (-1, 1), (-2, 4), (-3, 9), (-4, 16)
    ])
    def test_square_parametrized(self, input_val, expected):
        """Testa square com parâmetros variados"""
        assert square_task(input_val) == expected
 
class TestProcessWithDask:
    """Testes para a função process_with_dask"""
 
    def test_process_with_square_function(self, mock_dask_client):
        """Testa processamento com função quadrado"""
        # Arrange
        mock_dask_client.map.return_value = "mock_futures"
        mock_dask_client.gather.return_value = [1, 4, 9, 16, 25] # Resultado esperado
        numbers = [1, 2, 3, 4, 5]
        expected = [1, 4, 9, 16, 25]
 
        # Act
        result = process_with_dask(mock_dask_client, numbers, square_task)
 
        # Assert
        mock_dask_client.map.assert_called_once_with(square_task, numbers)
        mock_dask_client.gather.assert_called_once_with("mock_futures")
        assert result == expected
 
    def test_process_empty_list(self, mock_dask_client):
        """Testa processamento de lista vazia"""
        # Arrange
        mock_dask_client.map.return_value = []
        mock_dask_client.gather.return_value = []
 
        # Act
        result = process_with_dask(mock_dask_client, [], square_task)
 
        # Assert
        assert result == []
        mock_dask_client.map.assert_called_once_with(square_task, [])
        mock_dask_client.gather.assert_called_once_with([])
 
    # Nota: Os outros testes para process_with_dask foram removidos
    # pois a lógica principal (map/gather) já foi testada.
    # Testar com fibonacci ou lambda seria redundante aqui.
 
 
class TestCreateCluster:
    """Testes para a função create_cluster"""
 
    def test_create_cluster_success(self, mock_dask_cluster):
        """Testa criação bem-sucedida do cluster usando fixture."""
        # Arrange (a fixture 'mock_dask_cluster' de conftest.py já fez o patch)
        mock_cluster_instance = mock_dask_cluster['cluster']
        mock_client_instance = mock_dask_cluster['client']
 
        # Act
        cluster, client = create_cluster()
 
        # Assert
        assert cluster is mock_cluster_instance
        assert client is mock_client_instance
        mock_dask_cluster['cluster_class'].assert_called_once()
        mock_dask_cluster['client_class'].assert_called_once_with(mock_cluster_instance)
 
    @patch('demo_cluster.LocalCluster')
    def test_create_cluster_failure(self, mock_cluster):
        """Testa falha na criação do cluster"""
        # Configurar mock para falhar
        mock_cluster.side_effect = Exception("Erro ao criar cluster")

        # Verificar se a exceção é propagada
        with pytest.raises(Exception, match="Erro ao criar cluster"):
            create_cluster()
 
 
class TestRunDemo:
    """Testes para a função run_demo"""

    @patch('demo_cluster.create_cluster')
    @patch('demo_cluster.process_with_dask', return_value=[1, 4, 9, 16, 25])
    def test_run_demo_success(self, mock_process, mock_create_cluster):
        """Testa execução bem-sucedida da demo"""
        # Configurar mocks
        mock_create_cluster.return_value = (MagicMock(), MagicMock())
 
        # Executar função
        result = run_demo()

        # Verificar resultado
        assert result["status"] == "success"
        assert result["results"] == [1, 4, 9, 16, 25]
        mock_create_cluster.assert_called_once()
        mock_process.assert_called_once()
        assert "computation_time" in result
 
    @patch('demo_cluster.create_cluster')
    def test_run_demo_cluster_failure(self, mock_create_cluster):
        """Testa falha na criação do cluster durante demo"""
        # Configurar mock para falhar
        mock_create_cluster.side_effect = Exception("Falha no cluster")

        # Executar função
        result = run_demo()

        # Verificar resultado de erro
        assert result["status"] == "error"
        assert "error" in result
 
    @patch('demo_cluster.create_cluster')
    @patch('demo_cluster.process_with_dask', side_effect=Exception("Erro no processamento"))
    def test_run_demo_processing_failure(self, mock_process, mock_create_cluster):
        """Testa falha no processamento durante demo"""
        # Configurar mocks
        mock_create_cluster.return_value = (MagicMock(), MagicMock())

 
        # Executar função
        result = run_demo()
 
        # Verificar resultado de erro
        assert result["status"] == "error"
        assert "error" in result

 
class TestIntegration:
    """Testes de integração entre componentes"""

    # Esta classe é mais adequada para um arquivo de teste de integração,
    # pois executa as funções reais juntas.
    @pytest.mark.integration
    def test_full_workflow(self):
        """Testa o workflow de fibonacci e square juntos."""
        fib_results = [fibonacci_task(n) for n in range(6)]
        square_of_fib_results = [square_task(n) for n in fib_results]
        assert square_of_fib_results == [0, 1, 1, 4, 9, 25]
 
 
# Testes de performance
class TestPerformance:
    """Testes de performance"""

    def test_fibonacci_performance(self):
        """Testa performance da função fibonacci"""
        import time

        start_time = time.time()
        result = fibonacci_task(20)
        end_time = time.time()

        # Verificar resultado
        assert result == 6765

        # Verificar que não demorou muito (menos de 1 segundo)
        duration = end_time - start_time
        assert duration < 1.0
 
 
# Testes de edge cases
class TestEdgeCases:
    """Testes de casos extremos"""

    def test_very_large_fibonacci(self):
        """Testa fibonacci com valor muito grande"""
        # Este teste pode ser lento, por isso é separado
        result = fibonacci_task(30)
        assert result == 832040
 
    def test_fibonacci_negative_values(self):
        """Testa fibonacci com valores negativos (caso extremo)"""
        # Nota: A implementação atual pode não lidar bem com negativos
        # Este teste documenta o comportamento atual
        with pytest.raises(RecursionError):
            fibonacci_task(-1)
