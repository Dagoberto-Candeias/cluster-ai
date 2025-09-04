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
except ImportError:
    print("ERRO: Dask não está instalado. Execute 'pip install dask distributed'.")
    sys.exit(1)

def main(project_root: Path):
    """Inicia o cluster Dask."""
    print("Iniciando cluster Dask com segurança...")

    # Carregar configurações do cluster.conf
    config_file = project_root / 'cluster.conf'
    config = configparser.ConfigParser()
    if config_file.exists():
        config.read(config_file)

    # Obter configurações ou usar valores padrão
    dask_section = config['dask'] if 'dask' in config else {}
    dashboard_port = dask_section.get('dashboard_port', '8787')
    scheduler_port = dask_section.get('scheduler_port', '8786')
    auth_token = dask_section.get('auth_token', 'default_secure_token')
    n_workers = int(dask_section.get('n_workers', 2))
    threads_per_worker = int(dask_section.get('threads_per_worker', 2))

    # Configurações de segurança TLS (opcional para desenvolvimento local)
    cert_file = project_root / 'certs' / 'dask_cert.pem'
    key_file = project_root / 'certs' / 'dask_key.pem'

    # Verificar se estamos em modo desenvolvimento (sem TLS)
    dev_mode = os.getenv('DASK_DEV_MODE', 'false').lower() == 'true'

    if dev_mode:
        print("Modo desenvolvimento: Iniciando sem TLS...")
        security = None
    elif not cert_file.exists() or not key_file.exists():
        print(f"ERRO: Arquivos de certificado TLS não encontrados em {project_root / 'certs'}")
        print("Para desenvolvimento local, defina DASK_DEV_MODE=true")
        print("Para produção, execute o script de instalação para gerar certificados.")
        sys.exit(1)
    else:
        security = {
            'tls': {'cert': str(cert_file), 'key': str(key_file)},
            'require_encryption': True,
            'auth': { 'token': auth_token }
        }

    cluster = LocalCluster(
        n_workers=n_workers,
        threads_per_worker=threads_per_worker,
        dashboard_address=f':{dashboard_port}',
        scheduler_port=int(scheduler_port),
        security=security,
        processes=False
    )

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