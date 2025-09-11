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
import socket
import time
import argparse
import configparser
from pathlib import Path

try:
    from dask.distributed import LocalCluster
    from distributed.security import Security
except ImportError:
    print("ERRO: Dask não está instalado. Execute 'pip install dask[complete]'.")
    sys.exit(1)


def is_port_in_use(port: int) -> bool:
    """Verifica se uma porta TCP está em uso."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            # Tenta vincular a todas as interfaces para uma verificação mais robusta
            s.bind(("", port))
            return False
        except OSError:
            return True


def find_available_port(start_port: int, max_attempts: int = 100) -> int:
    """
    Encontra uma porta TCP livre, começando de start_port.
    """
    for i in range(max_attempts):
        port_to_check = start_port + i
        if not is_port_in_use(port_to_check):
            return port_to_check
    raise RuntimeError(
        f"Não foi possível encontrar uma porta livre após {max_attempts} "
        f"tentativas a partir de {start_port}"
    )


def main(project_root: str):
    """Inicia o cluster Dask."""
    project_root_path = Path(project_root)
    print("Iniciando cluster Dask com segurança...")

    # Carregar configurações do cluster.conf
    config_file = project_root_path / "cluster.conf"
    config = configparser.ConfigParser()
    if config_file.exists():
        config.read(config_file)

    # Obter configurações ou usar valores padrão
    dask_section = config["dask"] if "dask" in config else {}
    dashboard_port_config = int(dask_section.get("dashboard_port", "8787"))
    scheduler_port_config = int(dask_section.get("scheduler_port", "8786"))
    auth_token = dask_section.get("auth_token", "default_secure_token")
    n_workers = int(dask_section.get("n_workers", 2))
    threads_per_worker = int(dask_section.get("threads_per_worker", 2))
    spill_directory = dask_section.get("spill_directory", "/tmp/dask-spill")

    # --- Verificação de Portas ---
    final_scheduler_port = scheduler_port_config
    if is_port_in_use(final_scheduler_port):
        print(
            f"AVISO: A porta do scheduler configurada ({final_scheduler_port}) está em uso."
        )
        final_scheduler_port = find_available_port(final_scheduler_port)
        print(f"       Usando a próxima porta livre: {final_scheduler_port}")

    final_dashboard_port = dashboard_port_config
    if is_port_in_use(final_dashboard_port):
        print(
            f"AVISO: A porta do dashboard configurada ({final_dashboard_port}) está em uso."
        )
        final_dashboard_port = find_available_port(final_dashboard_port)
        print(f"       Usando a próxima porta livre: {final_dashboard_port}")

    # Garantir que as portas sejam diferentes
    if final_dashboard_port == final_scheduler_port:
        print(f"AVISO: Porta do dashboard conflita com scheduler. Ajustando...")
        final_dashboard_port = find_available_port(final_dashboard_port + 1)
        print(f"       Dashboard usando porta: {final_dashboard_port}")

    # Configurações de segurança TLS (opcional para desenvolvimento local)
    cert_file = project_root_path / "certs" / "dask_cert.pem"
    key_file = project_root_path / "certs" / "dask_key.pem"

    # Verificar se estamos em modo desenvolvimento (sem TLS)
    dev_mode = (
        os.getenv("DASK_DEV_MODE", "true").lower() == "true"
    )  # Padrão: desenvolvimento

    if dev_mode:
        print("Modo desenvolvimento: Iniciando sem TLS...")
        security = None
    elif not cert_file.exists() or not key_file.exists():
        print(
            f"AVISO: Arquivos de certificado TLS não encontrados em {project_root_path / 'certs'}"
        )
        print("Iniciando em modo desenvolvimento sem TLS...")
        security = None
    else:
        try:
            security = Security(tls_ca_file=str(cert_file), require_encryption=True)
        except Exception as e:
            print(f"ERRO na configuração TLS: {e}")
            print("Iniciando em modo desenvolvimento sem TLS...")
            security = None

    # Garantir que o diretório de spill exista
    os.makedirs(spill_directory, exist_ok=True)

    cluster = LocalCluster(
        n_workers=n_workers,
        threads_per_worker=threads_per_worker,
        dashboard_address=f":{final_dashboard_port}",
        scheduler_port=final_scheduler_port,
        security=security,
        processes=False,
        memory_limit=dask_section.get("memory_limit", None),
        local_directory=spill_directory,
    )

    print("\nCluster Dask iniciado. Pressione Ctrl+C para parar.")
    print(f"  Dashboard: http://localhost:{final_dashboard_port}/status")
    print(f"  Scheduler: {cluster.scheduler_address}")
    print(f"  Auth Token: {auth_token}")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nEncerrando Dask...")
        cluster.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Inicia um cluster Dask local com configurações de segurança."
    )
    parser.add_argument(
        "project_root", type=str, help="O caminho raiz do projeto cluster-ai."
    )
    args = parser.parse_args()
    main(str(Path(args.project_root).resolve()))
