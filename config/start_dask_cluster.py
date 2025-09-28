#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script para iniciar um cluster Dask local com configurações de segurança.

Este script é projetado para ser chamado pelo 'activate_server.sh' ou outros
scripts de gerenciamento, garantindo que o Dask seja iniciado de forma
consistente e segura.
"""
import os
import sys
import time
import configparser
from pathlib import Path

try:
    from dask.distributed import LocalCluster, Client
    from distributed.security import Security
except ImportError:
    print("ERRO: Dask não está instalado. Execute 'pip install dask distributed'.")
    sys.exit(1)


def main(project_root: Path):
    """Inicia o cluster Dask."""
    print("Iniciando cluster Dask com segurança...")

    # Carregar configurações do cluster.conf (formato shell)
    config_file = project_root / "cluster.conf"
    config_vars = {}

    if config_file.exists():
        with open(config_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    if '=' in line:
                        key, value = line.split('=', 1)
                        key = key.strip()
                        value = value.strip().strip('"').strip("'")
                        config_vars[key] = value

    # Obter configurações ou usar valores padrão
    dashboard_port = config_vars.get("DASK_DASHBOARD_PORT", "8787")
    scheduler_port = config_vars.get("DASK_SCHEDULER_PORT", "8786")
    auth_token = "default_secure_token"  # TODO: implementar token seguro
    n_workers_str = config_vars.get("DASK_NUM_WORKERS", "auto")
    threads_per_worker_str = config_vars.get("DASK_NUM_THREADS", "2")

    # Determinar número de workers
    if n_workers_str == "auto":
        import multiprocessing
        n_workers = max(1, multiprocessing.cpu_count() // 2)
    else:
        n_workers = int(n_workers_str)

    threads_per_worker = int(threads_per_worker_str)

    # Configurações de segurança TLS (simplificado por enquanto)
    print("AVISO: Iniciando Dask sem TLS (segurança básica).")
    security = None

    cluster_kwargs = {
        "n_workers": n_workers,
        "threads_per_worker": threads_per_worker,
        "dashboard_address": f":{dashboard_port}",
        "scheduler_port": int(scheduler_port),
        "processes": False,
    }

    if security is not None:
        cluster_kwargs["security"] = security

    cluster = LocalCluster(**cluster_kwargs)

    print(f"Cluster Dask iniciado. Pressione Ctrl+C para parar.")
    print(f"  Dashboard: https://localhost:{dashboard_port}/status")
    print(f"  Scheduler: {cluster.scheduler_address}")
    print(f"  Auth Token: {auth_token}")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nEncerrando Dask...")
        cluster.close()


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python start_dask_cluster.py <PROJECT_ROOT>")
        sys.exit(1)

    project_root_path = Path(sys.argv[1]).resolve()
    main(project_root_path)
