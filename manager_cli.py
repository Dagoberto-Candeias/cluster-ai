#!/usr/bin/env python3
import subprocess
import typer
from pathlib import Path

app = typer.Typer(help="Gerenciador do Cluster-AI (substitui manager.sh)")


def run(cmd: str):
    typer.echo(f"⟲ Executando: {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        typer.echo(f"⚠️  Comando falhou: {result.stderr}")
        typer.echo(f"⚠️  Código de saída: {result.returncode}")
        return False
    else:
        typer.echo(result.stdout)
        return True


@app.command()
def start(service: str = "all"):
    if service == "all":
        run("./start_cluster.sh")
    else:
        run(f"systemctl start {service}")


@app.command()
def stop(service: str = "all"):
    if service == "all":
        run("./stop_cluster.sh")
    else:
        run(f"systemctl stop {service}")


@app.command()
def restart(service: str = "all"):
    if service == "all":
        run("./restart_cluster.sh")
    else:
        run(f"systemctl restart {service}")


@app.command()
def discover():
    script = Path("scripts/deployment/auto_discover_workers.sh")
    if script.exists():
        run(f"bash {script}")
    else:
        typer.echo("⚠️  Script de descoberta não encontrado.")


@app.command()
def health():
    script = Path("scripts/utils/health_check.sh")
    if script.exists():
        run(f"bash {script}")
    else:
        typer.echo("⚠️  Script de healthcheck não encontrado.")


@app.command()
def backup():
    script = Path("scripts/maintenance/backup_manager.sh")
    if script.exists():
        run(f"bash {script}")
    else:
        typer.echo("⚠️  Script de backup não encontrado.")


@app.command()
def restore():
    script = Path("scripts/maintenance/restore_manager.sh")
    if script.exists():
        run(f"bash {script}")
    else:
        typer.echo("⚠️  Script de restore não encontrado.")


@app.command()
def scale(
    workers: int = typer.Argument(..., help="Número de workers"),
    backend: str = typer.Option("docker", help="Backend: docker | k8s | helm"),
):
    if backend == "docker":
        run(f"docker compose up -d --scale dask-worker={workers}")
    elif backend == "k8s":
        run(f"kubectl scale deployment dask-worker --replicas={workers}")
    elif backend == "helm":
        run(f"helm upgrade cluster-ai ./cluster-ai --set worker.replicas={workers}")
    else:
        typer.echo("⚠️ Backend inválido. Use 'docker', 'k8s' ou 'helm'.")


if __name__ == "__main__":
    app()
