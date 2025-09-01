#!/usr/bin/env python3
"""
Demonstração Simples do Cluster AI

Script interativo para mostrar o funcionamento básico do processamento distribuído.
"""

import time
import numpy as np
from dask.distributed import Client, LocalCluster
import threading


def mostrar_banner():
    """Mostra banner colorido"""
    print("🎯" * 40)
    print("🎯          CLUSTER AI - DEMONSTRAÇÃO INTERATIVA          🎯")
    print("🎯" * 40)
    print()


def demo_rapida():
    """Demonstração rápida de processamento paralelo"""
    print("🚀 DEMONSTRAÇÃO RÁPIDA")
    print("=" * 50)

    with LocalCluster(n_workers=2) as cluster:
        with Client(cluster) as client:
            print(f"✅ Cluster iniciado: {cluster.dashboard_link}")

            # Função simples para processamento
            def quadrado(x):
                time.sleep(0.5)  # Simula trabalho
                return x * x

            # Processar números em paralelo
            numeros = list(range(1, 11))
            print(f"📊 Processando: {numeros}")

            inicio = time.time()
            resultados = client.map(quadrado, numeros)
            resultados_finais = client.gather(resultados)
            fim = time.time()

            print(f"✅ Resultados: {resultados_finais}")
            print(f"⏱️  Tempo paralelo: {fim - inicio:.2f}s")

            # Comparar com sequencial
            inicio_seq = time.time()
            resultados_seq = [quadrado(n) for n in numeros]
            fim_seq = time.time()

            print(f"⏱️  Tempo sequencial: {fim_seq - inicio_seq:.2f}s")
            print(f"🚀 Speedup: {(fim_seq - inicio_seq) / (fim - inicio):.1f}x")
            print()


def demo_matrizes():
    """Demonstração com matrizes grandes"""
    print("🧮 DEMONSTRAÇÃO COM MATRIZES GRANDES")
    print("=" * 50)

    with LocalCluster() as cluster:
        with Client(cluster) as client:
            print("📊 Criando matriz 5000x5000 (25 milhões de elementos)...")

            import dask.array as da

            # Criar matriz grande distribuída
            matriz = da.random.random((5000, 5000), chunks=(1000, 1000))

            print("🧮 Calculando estatísticas...")

            # Operações distribuídas
            inicio = time.time()
            media = matriz.mean().compute()
            std = matriz.std().compute()
            fim = time.time()

            print(f"📈 Média: {media:.6f}")
            print(f"📊 Desvio padrão: {std:.6f}")
            print(f"⏱️  Tempo cálculo: {fim - inicio:.2f}s")
            print()


def demo_interativa():
    """Demonstração interativa"""
    print("🎮 DEMONSTRAÇÃO INTERATIVA")
    print("=" * 50)

    print("Escolha uma operação:")
    print("1. Calcular quadrados (rápido)")
    print("2. Processar matriz (médio)")
    print("3. Fibonacci paralelo (lento)")
    print()

    escolha = input("Digite sua escolha (1-3): ").strip()

    with LocalCluster(n_workers=4) as cluster:
        with Client(cluster) as client:
            print(f"🌐 Dashboard: {cluster.dashboard_link}")

            if escolha == "1":
                # Quadrados
                n = int(input("Quantos números? (1-100): ") or "20")
                numeros = list(range(1, n + 1))

                def quadrado(x):
                    time.sleep(0.1)
                    return x * x

                resultados = client.map(quadrado, numeros)
                print(f"✅ Resultados: {client.gather(resultados)}")

            elif escolha == "2":
                # Matriz
                tamanho = int(input("Tamanho da matriz? (1000-10000): ") or "3000")
                matriz = da.random.random((tamanho, tamanho), chunks=(500, 500))
                print(f"📊 Média: {matriz.mean().compute():.6f}")

            elif escolha == "3":
                # Fibonacci
                def fib(n):
                    if n <= 1:
                        return n
                    return fib(n - 1) + fib(n - 2)

                numeros = [30, 31, 32, 33]
                print(f"🧮 Calculando Fibonacci para {numeros}...")
                resultados = client.map(fib, numeros)
                print(f"✅ Resultados: {client.gather(resultados)}")

            else:
                print("❌ Escolha inválida")


def main():
    """Função principal"""
    mostrar_banner()

    try:
        demo_rapida()
        demo_matrizes()

        continuar = input("Deseja tentar a demo interativa? (s/N): ").strip().lower()
        if continuar in ["s", "sim", "y", "yes"]:
            demo_interativa()

        print("\n" + "🎉" * 20)
        print("🎉 DEMONSTRAÇÃO CONCLUÍDA COM SUCESSO! 🎉")
        print("🎉" * 20)
        print("\nO Cluster AI está funcionando perfeitamente!")
        print("Você pode acessar o dashboard para monitoramento.")

    except Exception as e:
        print(f"❌ Erro: {e}")
        return 1

    return 0


if __name__ == "__main__":
    exit(main())
