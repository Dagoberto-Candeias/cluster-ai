#!/usr/bin/env python3
"""
Testes unitários para demo_cluster.py

Este módulo contém testes para as funções do script de demonstração
do Cluster AI.
"""

import pytest
import time
from unittest.mock import patch, MagicMock
from demo_cluster import (
    processamento_pesado,
    calcular_fibonacci,
    demo_basica,
    demo_avancada,
    demo_data_science
)


class TestProcessamentoPesado:
    """Testes para a função processamento_pesado"""

    def test_processamento_basico(self):
        """Testa processamento básico com valor simples"""
        resultado = processamento_pesado(5)
        assert resultado == 25

    def test_processamento_zero(self):
        """Testa processamento com zero"""
        resultado = processamento_pesado(0)
        assert resultado == 0

    def test_processamento_negativo(self):
        """Testa processamento com número negativo"""
        resultado = processamento_pesado(-3)
        assert resultado == 9


class TestCalcularFibonacci:
    """Testes para a função calcular_fibonacci"""

    def test_fibonacci_base(self):
        """Testa casos base do Fibonacci"""
        assert calcular_fibonacci(0) == 0
        assert calcular_fibonacci(1) == 1

    def test_fibonacci_pequeno(self):
        """Testa valores pequenos do Fibonacci"""
        assert calcular_fibonacci(2) == 1
        assert calcular_fibonacci(3) == 2
        assert calcular_fibonacci(4) == 3
        assert calcular_fibonacci(5) == 5

    def test_fibonacci_medio(self):
        """Testa valores médios do Fibonacci"""
        assert calcular_fibonacci(10) == 55
        assert calcular_fibonacci(15) == 610


class TestDemoBasica:
    """Testes para demo_basica"""

    @patch('demo_cluster.LocalCluster')
    @patch('demo_cluster.Client')
    def test_demo_basica_sucesso(self, mock_client, mock_cluster):
        """Testa execução bem-sucedida da demo básica"""
        # Configurar mocks
        mock_cluster_instance = MagicMock()
        mock_client_instance = MagicMock()
        mock_cluster.return_value.__enter__.return_value = mock_cluster_instance
        mock_client.return_value.__enter__.return_value = mock_client_instance

        # Configurar retorno do map
        mock_client_instance.map.return_value = [0, 1, 4, 9, 16]  # quadrados de 0,1,2,3,4

        # Executar demo
        resultado = demo_basica()

        # Verificar se foi chamado corretamente
        assert mock_cluster.called
        assert mock_client.called
        assert resultado == [0, 1, 4, 9, 16]


class TestDemoAvancada:
    """Testes para demo_avancada"""

    @patch('demo_cluster.LocalCluster')
    @patch('demo_cluster.Client')
    def test_demo_avancada_sucesso(self, mock_client, mock_cluster):
        """Testa execução bem-sucedida da demo avançada"""
        # Configurar mocks
        mock_cluster_instance = MagicMock()
        mock_client_instance = MagicMock()
        mock_cluster.return_value.__enter__.return_value = mock_cluster_instance
        mock_client.return_value.__enter__.return_value = mock_client_instance

        # Configurar retornos
        mock_client_instance.submit.return_value = MagicMock()
        mock_client_instance.gather.return_value = [1, 1, 2, 3, 5]  # Fibonacci simplificado

        # Executar demo
        demo_avancada()

        # Verificar se foi chamado corretamente
        assert mock_cluster.called
        assert mock_client.called


class TestDemoDataScience:
    """Testes para demo_data_science"""

    @patch('demo_cluster.LocalCluster')
    @patch('demo_cluster.Client')
    @patch('demo_cluster.da')
    def test_demo_data_science_sucesso(self, mock_da, mock_client, mock_cluster):
        """Testa execução bem-sucedida da demo de data science"""
        # Configurar mocks
        mock_cluster_instance = MagicMock()
        mock_client_instance = MagicMock()
        mock_cluster.return_value.__enter__.return_value = mock_cluster_instance
        mock_client.return_value.__enter__.return_value = mock_client_instance

        # Configurar array mock
        mock_array = MagicMock()
        mock_array.mean.return_value.compute.return_value = 0.5
        mock_array.std.return_value.compute.return_value = 0.3
        mock_array.sum.return_value.compute.return_value = 50000.0
        mock_da.random.random.return_value = mock_array

        # Executar demo
        demo_data_science()

        # Verificar se foi chamado corretamente
        assert mock_cluster.called
        assert mock_client.called
        assert mock_da.random.random.called


if __name__ == "__main__":
    pytest.main([__file__])
