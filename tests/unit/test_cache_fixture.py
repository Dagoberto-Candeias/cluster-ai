"""
Exemplo de teste que demonstra o uso da fixture 'cache'
para armazenar resultados de computações caras.
"""

import time

import pytest


def perform_expensive_computation(data):
    """Simula uma função que demora muito para executar."""
    print("\nExecutando computação cara...")
    time.sleep(2)  # Simula 2 segundos de trabalho
    return sum(data)


def test_expensive_computation_with_cache(cache):
    """
    Este teste usa o cache para evitar re-executar um cálculo caro.
    Na primeira vez, ele demorará 2 segundos. Nas execuções seguintes,
    será quase instantâneo.
    """
    input_data = list(range(100))
    # Tenta obter o resultado do cache. Se não existir, executa o cálculo.
    result = cache.get("expensive_result/sum_100", None)
    if result is None:
        result = perform_expensive_computation(input_data)
        cache.set("expensive_result/sum_100", result)

    assert result == 4950
