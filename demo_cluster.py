#!/usr/bin/env python3
"""
Demo Cluster Module

Este módulo contém funções para demonstração do sistema de cluster AI.
Inclui processamento distribuído com Dask e cálculos matemáticos.
"""

import time
from dask.distributed import LocalCluster, Client


def calcular_fibonacci(n):
    """
    Calcula o n-ésimo número da sequência de Fibonacci.

    Args:
        n (int): Posição na sequência (deve ser >= 0)

    Returns:
        int: O n-ésimo número de Fibonacci

    Raises:
        ValueError: Se n for negativo
    """
    if n < 0:
        raise ValueError("Fibonacci não está definido para números negativos")

    if n == 0:
        return 0
    elif n == 1:
        return 1

    a, b = 0, 1
    for _ in range(2, n + 1):
        a, b = b, a + b
    return b


def processamento_pesado(x):
    """
    Função de processamento "pesado" - calcula o quadrado de um número.

    Args:
        x (int or float): Número a ser elevado ao quadrado

    Returns:
        int or float: Quadrado do número
    """
    return x * x


def create_cluster():
    """
    Cria um cluster local Dask com cliente.

    Returns:
        tuple: (cluster, client) - Instâncias do LocalCluster e Client
    """
    cluster = LocalCluster()
    client = Client(cluster)
    return cluster, client


def process_with_dask(client, data, func):
    """
    Processa uma lista de dados usando Dask de forma distribuída.

    Args:
        client: Instância do cliente Dask
        data (list): Lista de dados a processar
        func (callable): Função a aplicar a cada elemento

    Returns:
        list: Resultados do processamento
    """
    if not data:
        return []

    futures = client.map(func, data)
    return client.gather(futures)


def demo_avancada():
    """
    Demonstração avançada do processamento distribuído.
    Calcula números de Fibonacci grandes usando Dask.

    Returns:
        dict: Resultado da demonstração com status, resultados e tempo
    """
    try:
        start_time = time.time()

        with LocalCluster() as cluster:
            with Client(cluster) as client:
                # Calcular Fibonacci para valores grandes
                fib_numbers = [30, 31, 32, 33, 34]
                futures = client.map(calcular_fibonacci, fib_numbers)
                results = client.gather(futures)

        computation_time = time.time() - start_time

        return {
            "status": "success",
            "results": results,
            "computation_time": computation_time
        }

    except Exception as e:
        return {
            "status": "error",
            "error": str(e)
        }


def demo_basica():
    """
    Demonstração básica do processamento distribuído.
    Calcula quadrados de números usando Dask.

    Returns:
        dict: Resultado da demonstração
    """
    try:
        with LocalCluster() as cluster:
            with Client(cluster) as client:
                numbers = list(range(1, 11))
                results = process_with_dask(client, numbers, processamento_pesado)

        return {
            "status": "success",
            "results": results
        }

    except Exception as e:
        return {
            "status": "error",
            "error": str(e)
        }


if __name__ == "__main__":
    # Exemplo de uso
    print("Demonstrando demo_cluster.py")

    # Teste fibonacci
    print(f"Fibonacci(10) = {calcular_fibonacci(10)}")

    # Teste processamento pesado
    print(f"Quadrado(5) = {processamento_pesado(5)}")

    # Demo básica
    result = demo_basica()
    print(f"Demo básica: {result}")

    # Demo avançada
    result = demo_avancada()
    print(f"Demo avançada: {result}")
