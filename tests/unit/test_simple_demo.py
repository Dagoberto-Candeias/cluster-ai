"""
Testes unitários para simple_demo.py

Este módulo contém testes unitários para as funções de demonstração
do sistema Cluster AI em simple_demo.py.
"""

import sys
from pathlib import Path
from unittest.mock import MagicMock, call, patch

import pytest

# Adicionar diretório raiz ao path
PROJECT_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

# Importar módulos do projeto
try:
    from simple_demo import (
        demo_interativa,
        demo_matrizes,
        demo_rapida,
        main,
        mostrar_banner,
    )
except ImportError:
    pytest.skip(
        "Não foi possível importar os módulos do projeto. Pulando testes unitários.",
        allow_module_level=True,
    )


class TestMostrarBanner:
    """Testes para a função mostrar_banner"""

    @patch("builtins.print")
    def test_mostrar_banner(self, mock_print):
        """Testa exibição do banner"""
        # Act
        mostrar_banner()

        # Assert
        # Verificar se print foi chamado múltiplas vezes
        assert mock_print.call_count > 0
        # Verificar se o banner contém "CLUSTER AI"
        calls = [str(call) for call in mock_print.call_args_list]
        banner_text = " ".join(calls)
        assert "CLUSTER AI" in banner_text


class TestDemoRapida:
    """Testes para a função demo_rapida"""

    @patch("simple_demo.time")
    @patch("simple_demo.LocalCluster")
    @patch("simple_demo.Client")
    def test_demo_rapida_success(
        self, mock_client_class, mock_cluster_class, mock_time
    ):
        """Testa execução bem-sucedida da demo rápida"""
        # Arrange
        mock_cluster_instance = MagicMock()
        mock_cluster_class.return_value.__enter__.return_value = mock_cluster_instance
        mock_cluster_class.return_value.__exit__.return_value = None

        mock_client_instance = MagicMock()
        mock_client_instance.map.return_value = [MagicMock()] * 11  # 11 futures
        mock_client_instance.gather.return_value = [
            x**2 for x in range(1, 12)
        ]  # 1 to 11 squared
        mock_client_class.return_value.__enter__.return_value = mock_client_instance
        mock_client_class.return_value.__exit__.return_value = None

        mock_time.time.side_effect = [
            0.0,
            1.0,
            2.0,
            3.0,
        ]  # start, end parallel, start seq, end seq

        # Act
        demo_rapida()

        # Assert
        mock_cluster_class.assert_called_once()
        mock_client_class.assert_called_once()
        mock_client_instance.map.assert_called_once()
        mock_client_instance.gather.assert_called_once()


class TestDemoMatrizes:
    """Testes para a função demo_matrizes"""

    @patch("simple_demo.da.random")
    @patch("simple_demo.LocalCluster")
    @patch("simple_demo.Client")
    def test_demo_matrizes_success(
        self, mock_client_class, mock_cluster_class, mock_random
    ):
        """Testa execução bem-sucedida da demo de matrizes"""
        # Arrange
        mock_cluster_instance = MagicMock()
        mock_cluster_class.return_value.__enter__.return_value = mock_cluster_instance
        mock_cluster_class.return_value.__exit__.return_value = None

        mock_client_instance = MagicMock()
        mock_client_class.return_value.__enter__.return_value = mock_client_instance
        mock_client_class.return_value.__exit__.return_value = None

        mock_array = MagicMock()
        mock_array.mean.return_value.compute.return_value = 0.5
        mock_array.std.return_value.compute.return_value = 0.3
        mock_random.random.return_value = mock_array

        # Act
        demo_matrizes()

        # Assert
        mock_random.random.assert_called_once_with((5000, 5000), chunks=(1000, 1000))
        mock_array.mean.assert_called_once()
        mock_array.std.assert_called_once()


class TestDemoInterativa:
    """Testes para a função demo_interativa"""

    @patch("builtins.input")
    @patch("simple_demo.da")
    @patch("simple_demo.LocalCluster")
    @patch("simple_demo.Client")
    def test_demo_interativa_choice_1(
        self, mock_client_class, mock_cluster_class, mock_da, mock_input
    ):
        """Testa demo interativa com escolha 1 (quadrados)"""
        # Arrange
        mock_input.side_effect = ["1", "5"]  # escolha 1, n=5

        mock_cluster_instance = MagicMock()
        mock_cluster_class.return_value.__enter__.return_value = mock_cluster_instance
        mock_cluster_class.return_value.__exit__.return_value = None

        mock_client_instance = MagicMock()
        mock_client_instance.map.return_value = [MagicMock()] * 5
        mock_client_instance.gather.return_value = [1, 4, 9, 16, 25]
        mock_client_class.return_value.__enter__.return_value = mock_client_instance
        mock_client_class.return_value.__exit__.return_value = None

        # Act
        demo_interativa()

        # Assert
        mock_client_instance.map.assert_called_once()
        mock_client_instance.gather.assert_called_once()

    @patch("builtins.input")
    @patch("simple_demo.da")
    @patch("simple_demo.LocalCluster")
    @patch("simple_demo.Client")
    def test_demo_interativa_choice_2(
        self, mock_client_class, mock_cluster_class, mock_da, mock_input
    ):
        """Testa demo interativa com escolha 2 (matriz)"""
        # Arrange
        mock_input.side_effect = ["2", "1000"]  # escolha 2, tamanho=1000

        mock_cluster_instance = MagicMock()
        mock_cluster_class.return_value.__enter__.return_value = mock_cluster_instance
        mock_cluster_class.return_value.__exit__.return_value = None

        mock_client_instance = MagicMock()
        mock_client_class.return_value.__enter__.return_value = mock_client_instance
        mock_client_class.return_value.__exit__.return_value = None

        mock_array = MagicMock()
        mock_array.mean.return_value.compute.return_value = 0.5
        mock_da.random.random.return_value = mock_array

        # Act
        demo_interativa()

        # Assert
        mock_da.random.random.assert_called_once_with((1000, 1000), chunks=(500, 500))

    @patch("builtins.input")
    @patch("simple_demo.LocalCluster")
    @patch("simple_demo.Client")
    def test_demo_interativa_choice_3(
        self, mock_client_class, mock_cluster_class, mock_input
    ):
        """Testa demo interativa com escolha 3 (fibonacci)"""
        # Arrange
        mock_input.side_effect = ["3"]  # escolha 3

        mock_cluster_instance = MagicMock()
        mock_cluster_class.return_value.__enter__.return_value = mock_cluster_instance
        mock_cluster_class.return_value.__exit__.return_value = None

        mock_client_instance = MagicMock()
        mock_client_instance.map.return_value = [MagicMock()] * 4
        mock_client_instance.gather.return_value = [1, 1, 2, 3]  # fibonacci results
        mock_client_class.return_value.__enter__.return_value = mock_client_instance
        mock_client_class.return_value.__exit__.return_value = None

        # Act
        demo_interativa()

        # Assert
        mock_client_instance.map.assert_called_once()
        mock_client_instance.gather.assert_called_once()

    @patch("builtins.input")
    @patch("simple_demo.LocalCluster")
    @patch("simple_demo.Client")
    def test_demo_interativa_invalid_choice(
        self, mock_client_class, mock_cluster_class, mock_input
    ):
        """Testa demo interativa com escolha inválida"""
        # Arrange
        mock_input.side_effect = ["invalid"]  # escolha inválida

        mock_cluster_instance = MagicMock()
        mock_cluster_class.return_value.__enter__.return_value = mock_cluster_instance
        mock_cluster_class.return_value.__exit__.return_value = None

        mock_client_instance = MagicMock()
        mock_client_class.return_value.__enter__.return_value = mock_client_instance
        mock_client_class.return_value.__exit__.return_value = None

        # Act
        demo_interativa()

        # Assert - should not crash, just print invalid choice


class TestMain:
    """Testes para a função main"""

    @patch("simple_demo.demo_interativa")
    @patch("simple_demo.demo_matrizes")
    @patch("simple_demo.demo_rapida")
    @patch("simple_demo.mostrar_banner")
    @patch("builtins.input")
    def test_main_success_with_interactive(
        self, mock_input, mock_banner, mock_rapida, mock_matrizes, mock_interativa
    ):
        """Testa main com sucesso e demo interativa"""
        # Arrange
        mock_input.return_value = "s"

        # Act
        result = main()

        # Assert
        assert result == 0
        mock_banner.assert_called_once()
        mock_rapida.assert_called_once()
        mock_matrizes.assert_called_once()
        mock_interativa.assert_called_once()

    @patch("simple_demo.demo_matrizes")
    @patch("simple_demo.demo_rapida")
    @patch("simple_demo.mostrar_banner")
    @patch("builtins.input")
    def test_main_success_without_interactive(
        self, mock_input, mock_banner, mock_rapida, mock_matrizes
    ):
        """Testa main com sucesso sem demo interativa"""
        # Arrange
        mock_input.return_value = "n"

        # Act
        result = main()

        # Assert
        assert result == 0
        mock_banner.assert_called_once()
        mock_rapida.assert_called_once()
        mock_matrizes.assert_called_once()

    @patch("simple_demo.demo_rapida")
    @patch("simple_demo.mostrar_banner")
    def test_main_exception(self, mock_banner, mock_rapida):
        """Testa main com exceção"""
        # Arrange
        mock_rapida.side_effect = Exception("Test error")

        # Act
        result = main()

        # Assert
        assert result == 1
