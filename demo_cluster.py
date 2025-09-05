#!/usr/bin/env python3
# Local: demo_cluster.py
# Autor: Dagoberto Candeias <betoallnet@gmail.com>
"""
Demonstração do Cluster AI - Processamento Distribuído com Dask

Este script demonstra o funcionamento básico de um cluster Dask
com processamento distribuído de tarefas.
"""

import time
import numpy as np
import dask
from dask.distributed import Client, LocalCluster
import logging

# Configurar logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


def processamento_pesado(x):
    """Função que simula processamento intensivo de CPU"""
    logger.info(f"Processando elemento {x}")
    time.sleep(0.1)  # Simula processamento
    return x * x


def calcular_fibonacci(n):
    """Calcula Fibonacci de forma recursiva (intensiva em CPU)"""
    if n < 0:
        raise ValueError("Fibonacci não está definido para números negativos")
    if n <= 1:
        return n
    return calcular_fibonacci(n - 1) + calcular_fibonacci(n - 2)


def process_with_dask(client, numbers, operation):
    """
    Processa uma lista de números usando uma operação distribuída com Dask

    Args:
        client: Cliente Dask
        numbers: Lista de números para processar
        operation: Função a ser aplicada a cada número

    Returns:
        Lista com os resultados processados
    """
    if not numbers:
        return []

    # Submeter tarefas para processamento distribuído
    futures = [client.submit(operation, num) for num in numbers]

    # Coletar resultados
    results = client.gather(futures)

    return results


def create_cluster():
    """
    Cria um cluster Dask local e retorna cluster e cliente

    Returns:
        tuple: (cluster, client) - Instâncias do cluster e cliente Dask
    """
    cluster = LocalCluster(n_workers=2, threads_per_worker=2, processes=False)
    client = Client(cluster)
    return cluster, client


def demo_basica():
    """Demonstração básica do Dask"""
    logger.info("=== DEMONSTRAÇÃO BÁSICA DASK ===")

    # Criar um cluster local
    cluster = LocalCluster(n_workers=2, threads_per_worker=2)
    client = Client(cluster)
    try:
        logger.info(f"Cluster criado: {cluster}")
        logger.info(f"Dashboard disponível em: {cluster.dashboard_link}")

        # Criar uma lista de tarefas
        dados = list(range(20))
        logger.info(f"Processando {len(dados)} elementos...")

        # Processar em paralelo
        inicio = time.time()
        resultados = client.map(processamento_pesado, dados)
        resultados = client.gather(resultados)
        fim = time.time()

        logger.info(f"Resultados: {resultados}")
        logger.info(f"Tempo total: {fim - inicio:.2f} segundos")

        return resultados
    finally:
        client.close()
        cluster.close()


def demo_avancada():
    """Demonstração avançada com computação distribuída"""
    logger.info("\n=== DEMONSTRAÇÃO AVANÇADA ===")

    try:
        with LocalCluster(n_workers=4, threads_per_worker=1) as cluster:
            with Client(cluster) as client:
                logger.info(f"Cluster avançado criado: {cluster}")

                # Calcular Fibonacci para vários números em paralelo
                numeros = [30, 31, 32, 33, 34]
                logger.info(f"Calculando Fibonacci para: {numeros}")

                inicio = time.time()
                futuros = [client.submit(calcular_fibonacci, n) for n in numeros]
                resultados = client.gather(futuros)
                fim = time.time()

                for n, resultado in zip(numeros, resultados):
                    logger.info(f"Fibonacci({n}) = {resultado}")

                logger.info(f"Tempo paralelo: {fim - inicio:.2f} segundos")

                # Comparar com tempo sequencial
                inicio_seq = time.time()
                resultados_seq = [calcular_fibonacci(n) for n in numeros]
                fim_seq = time.time()

                logger.info(f"Tempo sequencial: {fim_seq - inicio_seq:.2f} segundos")
                logger.info(f"Speedup: {(fim_seq - inicio_seq) / (fim - inicio):.2f}x")

                return {
                    "status": "success",
                    "results": resultados,
                    "computation_time": fim - inicio
                }
    except Exception as e:
        logger.error(f"Erro na demonstração avançada: {e}")
        return {
            "status": "error",
            "error": str(e)
        }


def demo_data_science():
    """Demonstração com operações de data science"""
    logger.info("\n=== DEMONSTRAÇÃO DATA SCIENCE ===")

    with LocalCluster() as cluster:
        with Client(cluster) as client:
            logger.info("Processamento de dados com Dask Arrays")

            # Criar um array grande distribuído
            import dask.array as da

            array_grande = da.random.random((10000, 10000), chunks=(1000, 1000))
            logger.info(f"Array criado: {array_grande}")

            # Operações distribuídas
            media = array_grande.mean()
            std = array_grande.std()
            soma = array_grande.sum()

            logger.info(f"Média: {media.compute()}")
            logger.info(f"Desvio padrão: {std.compute():.4f}")
            logger.info(f"Soma: {soma.compute():.4f}")


def main():
    """Função principal"""
    logger.info("🚀 INICIANDO DEMONSTRAÇÃO DO CLUSTER AI 🚀")
    logger.info("=" * 50)

    try:
        # Demo básica
        demo_basica()

        # Demo avançada
        demo_avancada()

        # Demo data science
        demo_data_science()

        logger.info("\n✅ DEMONSTRAÇÃO CONCLUÍDA COM SUCESSO!")
        logger.info("O cluster Dask está funcionando perfeitamente!")

    except Exception as e:
        logger.error(f"Erro durante a demonstração: {e}")
        return 1

    return 0


if __name__ == "__main__":
    exit(main())
