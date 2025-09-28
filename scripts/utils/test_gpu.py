#!/usr/bin/env python3
"""
Script de teste para validação de GPU no Cluster AI
Testa PyTorch, TensorFlow e funcionalidades básicas de GPU
"""

import os
import subprocess
import sys
from datetime import datetime

import torch


def run_command(cmd):
    """Executa comando e retorna resultado"""
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=30
        )
        return result.returncode == 0, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return False, "", "Timeout"
    except Exception as e:
        return False, "", str(e)


def test_system_gpu():
    """Testa detecção de GPU no sistema"""
    print("=== TESTE DE DETECÇÃO DE GPU NO SISTEMA ===")

    # Testar lspci
    success, stdout, stderr = run_command(
        "lspci -nn | grep -i 'nvidia\\|amd' | head -10"
    )
    if success and stdout.strip():
        print("✅ GPUs detectadas:")
        for line in stdout.strip().split("\n"):
            print(f"   {line}")
    else:
        print("❌ Nenhuma GPU dedicada detectada")

    # Testar nvidia-smi se disponível
    success, stdout, stderr = run_command("which nvidia-smi")
    if success:
        success, stdout, stderr = run_command("nvidia-smi")
        if success:
            print("✅ NVIDIA-SMI funcionando:")
            print(stdout[:200] + "..." if len(stdout) > 200 else stdout)
        else:
            print("❌ NVIDIA-SMI falhou")

    # Testar ROCm se disponível
    if os.path.exists("/opt/rocm/bin/rocminfo"):
        success, stdout, stderr = run_command("/opt/rocm/bin/rocminfo --version")
        if success:
            print("✅ ROCm detectado:", stdout.strip())
        else:
            print("❌ ROCm presente mas rocminfo falhou")


def test_pytorch_gpu():
    """Testa PyTorch com GPU"""
    print("\n=== TESTE PyTorch GPU ===")

    print(f"PyTorch version: {torch.__version__}")
    print(f"CUDA available: {torch.cuda.is_available()}")

    if torch.cuda.is_available():
        print(f"CUDA version: {torch.version.cuda}")  # type: ignore
        print(f"Number of GPUs: {torch.cuda.device_count()}")

        for i in range(torch.cuda.device_count()):
            print(f"GPU {i}: {torch.cuda.get_device_name(i)}")
            print(
                f"  Memory: {torch.cuda.get_device_properties(i).total_memory / 1024**3:.1f} GB"
            )

        # Teste básico de tensor na GPU
        try:
            x = torch.randn(1000, 1000).cuda()
            y = torch.randn(1000, 1000).cuda()
            z = torch.matmul(x, y)
            print("✅ Operações matriciais na GPU funcionando")
            print(f"  Result shape: {z.shape}, Device: {z.device}")
        except Exception as e:
            print(f"❌ Erro em operações GPU: {e}")
    else:
        print("ℹ️  PyTorch usando CPU apenas")

        # Teste básico na CPU
        try:
            x = torch.randn(1000, 1000)
            y = torch.randn(1000, 1000)
            z = torch.matmul(x, y)
            print("✅ Operações matriciais na CPU funcionando")
        except Exception as e:
            print(f"❌ Erro em operações CPU: {e}")


def test_performance():
    """Teste de performance básico"""
    print("\n=== TESTE DE PERFORMANCE ===")

    if torch.cuda.is_available():
        # Teste de velocidade GPU vs CPU
        size = 2000
        repetitions = 10

        # CPU
        start = datetime.now()
        for _ in range(repetitions):
            a = torch.randn(size, size)
            b = torch.randn(size, size)
            c = torch.matmul(a, b)
        cpu_time = (datetime.now() - start).total_seconds()

        # GPU
        start = datetime.now()
        for _ in range(repetitions):
            a = torch.randn(size, size).cuda()
            b = torch.randn(size, size).cuda()
            c = torch.matmul(a, b)
            torch.cuda.synchronize()  # Esperar GPU terminar
        gpu_time = (datetime.now() - start).total_seconds()

        print(f"CPU time: {cpu_time:.2f}s")
        print(f"GPU time: {gpu_time:.2f}s")
        if gpu_time > 0:
            speedup = cpu_time / gpu_time
            print(f"Speedup: {speedup:.1f}x")
        else:
            print("Speedup: N/A")
    else:
        print("ℹ️  Teste de performance apenas CPU")
        size = 2000
        repetitions = 5

        start = datetime.now()
        for _ in range(repetitions):
            a = torch.randn(size, size)
            b = torch.randn(size, size)
            c = torch.matmul(a, b)
        cpu_time = (datetime.now() - start).total_seconds()

        print(f"CPU time: {cpu_time:.2f}s")


def test_memory():
    """Teste de memória GPU"""
    print("\n=== TESTE DE MEMÓRIA ===")

    if torch.cuda.is_available():
        try:
            # Alocar memória
            torch.cuda.empty_cache()
            free_memory = torch.cuda.memory_allocated()
            print(f"Memória GPU alocada: {free_memory / 1024**2:.1f} MB")

            # Alocar um tensor grande
            large_tensor = torch.randn(5000, 5000).cuda()
            allocated = torch.cuda.memory_allocated()
            print(f"Após alocar tensor: {allocated / 1024**2:.1f} MB")

            # Liberar
            del large_tensor
            torch.cuda.empty_cache()
            print("✅ Gerenciamento de memória funcionando")

        except Exception as e:
            print(f"❌ Erro no teste de memória: {e}")
    else:
        print("ℹ️  Teste de memória GPU não disponível")


def main():
    """Função principal"""
    print("🧪 CLUSTER AI - TESTE DE GPU")
    print("=" * 50)

    try:
        test_system_gpu()
        test_pytorch_gpu()
        test_memory()
        test_performance()

        print("\n" + "=" * 50)
        print("✅ Teste de GPU concluído!")

    except Exception as e:
        print(f"❌ Erro durante os testes: {e}")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
