#!/usr/bin/env python3
"""
Teste Abrangente do Sistema Cluster AI
=====================================

Este script testa todos os componentes do sistema Cluster AI:
- Dask Scheduler e Workers
- Ollama API e modelos
- PyTorch e GPU
- Conectividade de rede
- Performance do sistema
"""

import asyncio
import time
import requests
import subprocess
import sys
import os
from datetime import datetime

# Adicionar o diretório raiz ao path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


class SystemTester:
    def __init__(self):
        self.results = {}
        self.start_time = time.time()

    def log(self, message, level="INFO"):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] [{level}] {message}")

    def test_dask_scheduler(self):
        """Testa a conectividade com o Dask Scheduler"""
        self.log("Testando Dask Scheduler...")
        try:
            from dask.distributed import Client

            client = Client("tcp://localhost:8786", timeout=5)
            info = client.scheduler_info()
            client.close()
            self.results["dask_scheduler"] = {
                "status": "PASS",
                "workers": len(info["workers"]),
                "scheduler_address": info["address"],
            }
            self.log("✅ Dask Scheduler: OK")
            return True
        except Exception as e:
            self.results["dask_scheduler"] = {"status": "FAIL", "error": str(e)}
            self.log(f"❌ Dask Scheduler: FALHA - {e}")
            return False

    def test_dask_dashboard(self):
        """Testa o acesso ao Dashboard do Dask"""
        self.log("Testando Dask Dashboard...")
        try:
            response = requests.get("http://localhost:8787/status", timeout=5)
            if response.status_code == 200:
                self.results["dask_dashboard"] = {
                    "status": "PASS",
                    "response_time": response.elapsed.total_seconds(),
                }
                self.log("✅ Dask Dashboard: OK")
                return True
            else:
                self.results["dask_dashboard"] = {
                    "status": "FAIL",
                    "status_code": response.status_code,
                }
                self.log(f"❌ Dask Dashboard: Status {response.status_code}")
                return False
        except Exception as e:
            self.results["dask_dashboard"] = {"status": "FAIL", "error": str(e)}
            self.log(f"❌ Dask Dashboard: FALHA - {e}")
            return False

    def test_ollama_api(self):
        """Testa a API do Ollama"""
        self.log("Testando Ollama API...")
        try:
            response = requests.get("http://localhost:11434/api/tags", timeout=5)
            if response.status_code == 200:
                data = response.json()
                model_count = len(data.get("models", []))
                self.results["ollama_api"] = {
                    "status": "PASS",
                    "models_count": model_count,
                    "models": [m["name"] for m in data.get("models", [])],
                }
                self.log(f"✅ Ollama API: OK ({model_count} modelos)")
                return True
            else:
                self.results["ollama_api"] = {
                    "status": "FAIL",
                    "status_code": response.status_code,
                }
                self.log(f"❌ Ollama API: Status {response.status_code}")
                return False
        except Exception as e:
            self.results["ollama_api"] = {"status": "FAIL", "error": str(e)}
            self.log(f"❌ Ollama API: FALHA - {e}")
            return False

    def test_pytorch_gpu(self):
        """Testa PyTorch e GPU"""
        self.log("Testando PyTorch e GPU...")
        try:
            import torch

            # Verificar versão
            version = torch.__version__
            self.log(f"PyTorch version: {version}")

            # Verificar GPU
            gpu_available = torch.cuda.is_available()
            if gpu_available:
                gpu_count = torch.cuda.device_count()
                gpu_name = torch.cuda.get_device_name(0)
                self.log(f"GPU disponível: {gpu_name} ({gpu_count} GPUs)")
            else:
                self.log("GPU não disponível, usando CPU")

            # Teste básico de tensor
            x = torch.randn(1000, 1000)
            y = torch.randn(1000, 1000)
            start_time = time.time()
            z = torch.mm(x, y)
            end_time = time.time()

            self.results["pytorch"] = {
                "status": "PASS",
                "version": version,
                "gpu_available": gpu_available,
                "gpu_count": torch.cuda.device_count() if gpu_available else 0,
                "matrix_mult_time": end_time - start_time,
            }
            self.log("✅ PyTorch: OK")
            return True
        except Exception as e:
            self.results["pytorch"] = {"status": "FAIL", "error": str(e)}
            self.log(f"❌ PyTorch: FALHA - {e}")
            return False

    def test_dask_computation(self):
        """Testa computação distribuída com Dask"""
        self.log("Testando computação distribuída...")
        try:
            from dask.distributed import Client
            import dask.array as da

            client = Client("tcp://localhost:8786", timeout=10)

            # Criar array grande
            x = da.random.random((10000, 10000), chunks=(1000, 1000))
            start_time = time.time()
            result = x.mean().compute()
            end_time = time.time()

            client.close()

            self.results["dask_computation"] = {
                "status": "PASS",
                "result": float(result),
                "computation_time": end_time - start_time,
            }
            self.log(f"✅ Dask Computation: OK (tempo: {end_time - start_time:.4f}s)")
            return True
        except Exception as e:
            self.results["dask_computation"] = {"status": "FAIL", "error": str(e)}
            self.log(f"❌ Dask Computation: FALHA - {e}")
            return False

    def test_system_resources(self):
        """Testa recursos do sistema"""
        self.log("Testando recursos do sistema...")
        try:
            import psutil

            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage("/")

            self.results["system_resources"] = {
                "status": "PASS",
                "cpu_percent": cpu_percent,
                "memory_percent": memory.percent,
                "memory_available_gb": memory.available / (1024**3),
                "disk_percent": disk.percent,
                "disk_free_gb": disk.free / (1024**3),
            }
            self.log("✅ System Resources: OK")
            return True
        except Exception as e:
            self.results["system_resources"] = {"status": "FAIL", "error": str(e)}
            self.log(f"❌ System Resources: FALHA - {e}")
            return False

    def run_all_tests(self):
        """Executa todos os testes"""
        self.log("🚀 INICIANDO TESTES ABRANGENTES DO SISTEMA CLUSTER AI")
        self.log("=" * 60)

        tests = [
            self.test_dask_scheduler,
            self.test_dask_dashboard,
            self.test_ollama_api,
            self.test_pytorch_gpu,
            self.test_dask_computation,
            self.test_system_resources,
        ]

        passed = 0
        total = len(tests)

        for test in tests:
            if test():
                passed += 1
            time.sleep(0.5)  # Pequena pausa entre testes

        # Resumo final
        self.log("\n" + "=" * 60)
        self.log("📊 RESUMO DOS TESTES")
        self.log("=" * 60)

        for test_name, result in self.results.items():
            status = result["status"]
            if status == "PASS":
                self.log(f"✅ {test_name}: {status}")
            else:
                self.log(f"❌ {test_name}: {status}")
                if "error" in result:
                    self.log(f"   Erro: {result['error']}")

        self.log(f"\n🎯 RESULTADO FINAL: {passed}/{total} testes passaram")

        end_time = time.time()
        duration = end_time - self.start_time
        self.log(f"Duração total dos testes: {duration:.2f} segundos")
        if passed == total:
            self.log("🎉 SISTEMA TOTALMENTE FUNCIONAL!")
            return True
        else:
            self.log("⚠️  SISTEMA COM PROBLEMAS - Verificar falhas acima")
            return False


def main():
    tester = SystemTester()
    success = tester.run_all_tests()
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
