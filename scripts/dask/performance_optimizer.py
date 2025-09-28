#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Dask Performance Optimizer - Cluster AI

Este script otimiza automaticamente as configurações do Dask baseado no
hardware disponível e tipo de workload detectado.

Uso:
    python performance_optimizer.py [workload_type] [options]

Workload types:
    - ai_inference: Otimizado para geração de texto e inferência IA
    - data_science: Otimizado para análise de dados e computação científica
    - image_processing: Otimizado para processamento de imagens
    - mixed: Configuração balanceada para workloads diversos
    - auto: Detecção automática baseada no sistema
"""

import argparse
import json
import logging
import os
import sys
from pathlib import Path
from typing import Any, Dict, Optional

import psutil
import yaml

# Configuração de logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class DaskPerformanceOptimizer:
    """Otimizador de performance para Dask"""

    def __init__(self, config_path: Optional[str] = None):
        self.config_path = config_path or self._find_config_file()
        self.system_info = self._detect_system()
        self.config = self._load_config()
        self.workload_profiles = self.config.get("workloads", {})

    def _find_config_file(self) -> str:
        """Encontra o arquivo de configuração de performance"""
        search_paths = [
            Path(__file__).parent.parent.parent
            / "config"
            / "dask_performance_config.yaml",
            Path.cwd() / "config" / "dask_performance_config.yaml",
            Path.home() / ".cluster-ai" / "dask_performance_config.yaml",
        ]

        for path in search_paths:
            if path.exists():
                return str(path)

        # Fallback para configuração padrão
        return str(Path(__file__).parent / "default_performance_config.yaml")

    def _detect_system(self) -> Dict[str, Any]:
        """Detecta características do sistema"""
        system_info = {
            "cpu_count": psutil.cpu_count(),
            "cpu_count_logical": psutil.cpu_count(logical=True),
            "memory_total": psutil.virtual_memory().total,
            "memory_available": psutil.virtual_memory().available,
            "has_gpu": self._detect_gpu(),
            "disk_info": self._get_disk_info(),
            "network_info": self._get_network_info(),
        }

        # Classificação do sistema
        memory_gb = system_info["memory_total"] / (1024**3)
        if memory_gb < 8:
            system_info["class"] = "light"
        elif memory_gb < 32:
            system_info["class"] = "medium"
        else:
            system_info["class"] = "heavy"

        return system_info

    def _detect_gpu(self) -> bool:
        """Detecta se há GPU disponível"""
        try:
            import torch

            return torch.cuda.is_available()
        except ImportError:
            try:
                # Verificar NVIDIA GPU
                result = os.popen(
                    "nvidia-smi --query-gpu=name --format=csv,noheader"
                ).read()
                return bool(result.strip())
            except:
                return False

    def _get_disk_info(self) -> Dict[str, Any]:
        """Obtém informações sobre discos"""
        disk_info = {}
        for partition in psutil.disk_partitions():
            if partition.mountpoint == "/":
                usage = psutil.disk_usage(partition.mountpoint)
                disk_info["root"] = {
                    "total": usage.total,
                    "free": usage.free,
                    "type": partition.fstype,
                }
                break
        return disk_info

    def _get_network_info(self) -> Dict[str, Any]:
        """Obtém informações sobre rede"""
        net_info = psutil.net_if_addrs()
        return {
            "interfaces": list(net_info.keys()),
            "has_ethernet": any(
                "eth" in iface or "en" in iface for iface in net_info.keys()
            ),
        }

    def _load_config(self) -> Dict[str, Any]:
        """Carrega configuração de performance"""
        try:
            with open(self.config_path, "r") as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            logger.warning(
                f"Arquivo de configuração não encontrado: {self.config_path}"
            )
            return self._get_default_config()
        except Exception as e:
            logger.error(f"Erro ao carregar configuração: {e}")
            return self._get_default_config()

    def _get_default_config(self) -> Dict[str, Any]:
        """Retorna configuração padrão"""
        return {
            "dask": {
                "worker": {"memory_limit": "4GB", "threads": 4},
                "scheduler": {"pool_size": 20},
            }
        }

    def detect_workload(self) -> str:
        """Detecta automaticamente o tipo de workload"""
        # Análise baseada no sistema
        if self.system_info.get("has_gpu"):
            return "ai_inference"
        elif self.system_info["cpu_count"] >= 8:
            return "data_science"
        else:
            return "mixed"

    def optimize_for_workload(self, workload: str) -> Dict[str, Any]:
        """Otimiza configurações para um tipo específico de workload"""
        if workload not in self.workload_profiles:
            logger.warning(f"Workload '{workload}' não encontrado, usando 'mixed'")
            workload = "mixed"

        profile = self.workload_profiles[workload]
        optimized_config = self._scale_config_for_system(profile)

        logger.info(f"Configuração otimizada para workload '{workload}':")
        logger.info(
            f"  Sistema detectado: {self.system_info['class']} ({self.system_info['cpu_count']} CPUs, {self.system_info['memory_total'] // (1024**3)}GB RAM)"
        )
        logger.info(
            f"  Workers: {optimized_config['worker']['threads']} threads, {optimized_config['worker']['memory_limit']}"
        )

        return optimized_config

    def _scale_config_for_system(self, profile: Dict[str, Any]) -> Dict[str, Any]:
        """Ajusta configuração baseada nas capacidades do sistema"""
        system_class = self.system_info["class"]
        cpu_count = self.system_info["cpu_count"]
        memory_gb = self.system_info["memory_total"] / (1024**3)

        # Ajuste baseado na classe do sistema
        scale_factors = {"light": 0.5, "medium": 1.0, "heavy": 1.5}

        scale_factor = scale_factors.get(system_class, 1.0)

        # Configuração otimizada
        optimized = {
            "worker": {
                "threads": min(
                    int(profile["worker"]["threads"] * scale_factor), cpu_count
                ),
                "memory_limit": self._calculate_memory_limit(
                    profile["worker"].get("memory_limit", "4GB"), memory_gb
                ),
                "compute_pool_size": min(
                    int(profile["worker"].get("compute_pool_size", 8) * scale_factor),
                    cpu_count * 2,
                ),
            },
            "scheduler": profile.get("scheduler", {}),
            "system_info": self.system_info,
        }

        return optimized

    def _calculate_memory_limit(self, base_limit: str, total_memory_gb: float) -> str:
        """Calcula limite de memória otimizado"""
        # Parse base limit
        if isinstance(base_limit, str):
            if base_limit.endswith("GB"):
                base_gb = float(base_limit[:-2])
            elif base_limit.endswith("MB"):
                base_gb = float(base_limit[:-2]) / 1024
            else:
                base_gb = 4.0  # Default
        else:
            base_gb = float(base_limit)

        # Ajuste baseado na memória disponível
        available_gb = total_memory_gb * 0.8  # 80% da memória total
        max_workers = max(1, total_memory_gb // base_gb)

        # Limite por worker
        worker_limit = min(base_gb, available_gb / max_workers)

        return f"{int(worker_limit)}GB"

    def apply_config(self, config: Dict[str, Any], output_file: Optional[str] = None):
        """Aplica configuração ao Dask"""
        # Configurar variáveis de ambiente
        self._set_dask_environment(config)

        # Salvar configuração se especificado
        if output_file:
            self._save_config_file(config, output_file)

        logger.info("Configuração de performance aplicada com sucesso")

    def _set_dask_environment(self, config: Dict[str, Any]):
        """Define variáveis de ambiente do Dask"""
        worker_config = config.get("worker", {})

        # Configurações de worker
        if "threads" in worker_config:
            os.environ["DASK_WORKER_THREADS"] = str(worker_config["threads"])

        if "memory_limit" in worker_config:
            os.environ["DASK_WORKER_MEMORY_LIMIT"] = worker_config["memory_limit"]

        if "compute_pool_size" in worker_config:
            os.environ["DASK_WORKER_COMPUTE_POOL_SIZE"] = str(
                worker_config["compute_pool_size"]
            )

        # Configurações de scheduler
        scheduler_config = config.get("scheduler", {})
        if "pool_size" in scheduler_config:
            os.environ["DASK_SCHEDULER_POOL_SIZE"] = str(scheduler_config["pool_size"])

        # Configurações gerais
        os.environ["DASK_COMPRESSION"] = "lz4"
        os.environ["DASK_SCHEDULER_WORK_STEALING"] = "True"

    def _save_config_file(self, config: Dict[str, Any], output_file: str):
        """Salva configuração em arquivo"""
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        with open(output_path, "w") as f:
            json.dump(config, f, indent=2)

        logger.info(f"Configuração salva em: {output_path}")

    def benchmark_system(self) -> Dict[str, Any]:
        """Executa benchmark do sistema para otimização"""
        logger.info("Executando benchmark do sistema...")

        results = {
            "cpu_performance": self._benchmark_cpu(),
            "memory_performance": self._benchmark_memory(),
            "disk_performance": self._benchmark_disk(),
            "network_performance": self._benchmark_network(),
        }

        logger.info("Benchmark concluído")
        return results

    def _benchmark_cpu(self) -> Dict[str, Any]:
        """Benchmark de CPU"""
        import time

        def cpu_intensive_task(n):
            return sum(i * i for i in range(n))

        # Teste de performance
        start_time = time.time()
        results = [
            cpu_intensive_task(100000) for _ in range(self.system_info["cpu_count"])
        ]
        end_time = time.time()

        return {
            "execution_time": end_time - start_time,
            "tasks_completed": len(results),
        }

    def _benchmark_memory(self) -> Dict[str, Any]:
        """Benchmark de memória"""
        import numpy as np

        try:
            # Teste de alocação de memória
            size_mb = 100
            arrays = []
            for _ in range(5):
                arr = np.random.random((size_mb * 1024 * 1024 // 8))  # ~100MB
                arrays.append(arr)

            return {
                "allocation_success": True,
                "arrays_created": len(arrays),
                "total_memory_mb": size_mb * len(arrays),
            }
        except MemoryError:
            return {"allocation_success": False, "error": "Memory limit reached"}

    def _benchmark_disk(self) -> Dict[str, Any]:
        """Benchmark de disco"""
        import tempfile
        import time

        try:
            with tempfile.NamedTemporaryFile(delete=False) as f:
                test_data = b"0" * (10 * 1024 * 1024)  # 10MB

                # Teste de escrita
                start_time = time.time()
                f.write(test_data)
                f.flush()
                write_time = time.time() - start_time

                # Teste de leitura
                f.seek(0)
                start_time = time.time()
                data = f.read()
                read_time = time.time() - start_time

                # Cleanup
                os.unlink(f.name)

                return {
                    "write_speed_mbs": len(test_data) / (1024 * 1024) / write_time,
                    "read_speed_mbs": len(test_data) / (1024 * 1024) / read_time,
                    "test_size_mb": len(test_data) / (1024 * 1024),
                }
        except Exception as e:
            return {"error": str(e)}

    def _benchmark_network(self) -> Dict[str, Any]:
        """Benchmark de rede (simples)"""
        import socket
        import time

        try:
            # Teste de latência local
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            start_time = time.time()
            sock.connect(("127.0.0.1", 80))
            latency = time.time() - start_time
            sock.close()

            return {"local_latency_ms": latency * 1000, "network_available": True}
        except:
            return {"network_available": False}


def main():
    parser = argparse.ArgumentParser(description="Dask Performance Optimizer")
    parser.add_argument(
        "workload",
        nargs="?",
        choices=["ai_inference", "data_science", "image_processing", "mixed", "auto"],
        default="auto",
        help="Tipo de workload para otimização",
    )
    parser.add_argument(
        "--config", type=str, help="Caminho para arquivo de configuração personalizado"
    )
    parser.add_argument(
        "--output", type=str, help="Arquivo para salvar configuração otimizada"
    )
    parser.add_argument(
        "--benchmark", action="store_true", help="Executar benchmark do sistema"
    )
    parser.add_argument(
        "--apply", action="store_true", help="Aplicar configuração imediatamente"
    )

    args = parser.parse_args()

    # Inicializar otimizador
    optimizer = DaskPerformanceOptimizer(args.config)

    # Detectar workload se auto
    if args.workload == "auto":
        detected_workload = optimizer.detect_workload()
        logger.info(f"Workload detectado automaticamente: {detected_workload}")
        workload = detected_workload
    else:
        workload = args.workload

    # Executar benchmark se solicitado
    if args.benchmark:
        benchmark_results = optimizer.benchmark_system()
        logger.info("Resultados do benchmark:")
        for key, value in benchmark_results.items():
            logger.info(f"  {key}: {value}")

    # Otimizar configuração
    optimized_config = optimizer.optimize_for_workload(workload)

    # Aplicar ou salvar configuração
    if args.apply:
        optimizer.apply_config(optimized_config, args.output)
    elif args.output:
        optimizer._save_config_file(optimized_config, args.output)
    else:
        # Mostrar configuração
        print("\nConfiguração Otimizada:")
        print(json.dumps(optimized_config, indent=2))


if __name__ == "__main__":
    main()
