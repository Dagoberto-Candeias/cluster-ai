#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script corrigido para iniciar um cluster Dask local com configurações de segurança.
Configurado para usar SSD externo automaticamente.
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
            s.bind(("", port))
            return False
        except OSError:
            return True


def find_available_port(start_port: int, max_attempts: int = 100) -> int:
    """Encontra uma porta TCP livre."""
    for i in range(max_attempts):
        port_to_check = start_port + i
        if not is_port_in_use(port_to_check):
            return port_to_check
    raise RuntimeError(f"Não foi possível encontrar uma porta livre após {max_attempts} tentativas")


def setup_external_ssd():
    """Configura o uso do SSD externo automaticamente."""
    external_ssd = "/mnt/external_ssd"

    # Verificar se SSD externo está montado
    if not os.path.exists(external_ssd):
        print(f"AVISO: SSD externo não encontrado em {external_ssd}")
        return "/tmp/dask-spill"

    # Criar diretórios no SSD externo
    dask_spill_dir = os.path.join(external_ssd, "dask-spill")
    swap_dir = os.path.join(external_ssd, "swap")

    os.makedirs(dask_spill_dir, exist_ok=True)
    os.makedirs(swap_dir, exist_ok=True)

    print(f"✅ SSD externo configurado: {external_ssd}")
    print(f"   Spill directory: {dask_spill_dir}")
    print(f"   Swap directory: {swap_dir}")

    return dask_spill_dir


def main(project_root: str):
    """Inicia o cluster Dask."""
    project_root_path = Path(project_root)
    print("🚀 Iniciando cluster Dask com SSD externo...")

    # Configurar SSD externo
    spill_directory = setup_external_ssd()

    # Carregar configurações do cluster.conf.ini
    config_file = project_root_path / "cluster.conf.ini"
    config = configparser.ConfigParser()
    if config_file.exists():
        config.read(config_file)

    # Obter configurações ou usar valores padrão
    dask_section = config["dask"] if "dask" in config else {}
    dashboard_port_config = int(dask_section.get("dashboard_port", "8787"))
    scheduler_port_config = int(dask_section.get("scheduler_port", "8786"))
    n_workers = int(dask_section.get("n_workers", 2))
    threads_per_worker = int(dask_section.get("threads_per_worker", 2))

    # Verificação de Portas
    final_scheduler_port = scheduler_port_config
    if is_port_in_use(final_scheduler_port):
        final_scheduler_port = find_available_port(final_scheduler_port)
        print(f"📡 Scheduler usando porta: {final_scheduler_port}")

    final_dashboard_port = dashboard_port_config
    if is_port_in_use(final_dashboard_port):
        final_dashboard_port = find_available_port(final_dashboard_port)
        print(f"📊 Dashboard usando porta: {final_dashboard_port}")

    # Garantir que scheduler e dashboard usem portas diferentes
    if final_scheduler_port == final_dashboard_port:
        final_dashboard_port = find_available_port(final_dashboard_port + 1)
        print(f"📊 Dashboard ajustado para porta: {final_dashboard_port}")

    # Configurar TLS se certificados estiverem disponíveis
    cert_file = project_root_path / "certs" / "dask_cert.pem"
    key_file = project_root_path / "certs" / "dask_key.pem"

    if cert_file.exists() and key_file.exists():
        print("🔒 TLS configurado: Usando certificados existentes")
        security = Security(
            tls_ca_file=str(cert_file),
            tls_cert=str(cert_file),
            tls_key=str(key_file)
        )
    else:
        print("⚠️  TLS não configurado: Certificados não encontrados")
        print("   Execute: bash scripts/security/generate_certificates.sh")
        security = None

    # Criar cluster
    cluster = LocalCluster(
        n_workers=n_workers,
        threads_per_worker=threads_per_worker,
        dashboard_address=f"{socket.gethostbyname(socket.gethostname())}:{final_dashboard_port}",
        scheduler_port=final_scheduler_port,
        ip=socket.gethostbyname(socket.gethostname()),
        security=security,
        processes=False,
        memory_limit="4GB",  # Limite de memória por worker
        local_directory=spill_directory,
    )

    print("\n✅ Cluster Dask iniciado com sucesso!")
    print(f"   📊 Dashboard: http://localhost:{final_dashboard_port}/status")
    print(f"   🎯 Scheduler: {cluster.scheduler_address}")
    print(f"   👷 Workers: {n_workers} (threads: {threads_per_worker})")
    print(f"   💾 Spill dir: {spill_directory}")
    print("\n   Pressione Ctrl+C para parar.")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n🛑 Encerrando Dask...")
        cluster.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Inicia cluster Dask com SSD externo")
    parser.add_argument("project_root", type=str, help="Caminho raiz do projeto cluster-ai")
    args = parser.parse_args()
    main(str(Path(args.project_root).resolve()))
