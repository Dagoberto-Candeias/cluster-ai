#!/usr/bin/env python3
"""
Módulo para monitoramento de saúde dos workers
"""

import time
from typing import Any, Dict, List

import psutil

from scripts.management.remote_command import execute_remote_command


def check_worker_health(worker_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Verifica a saúde de um worker

    Args:
        worker_data: Dados do worker

    Returns:
        Dicionário com status de saúde
    """
    ip = worker_data.get("ip")
    port = worker_data.get("port", 22)
    worker_type = worker_data.get("type", "unknown")
    user = worker_data.get("user", "termux")

    health_status = {
        "worker": worker_data.get("name", ip),
        "ip": ip,
        "port": port,
        "type": worker_type,
        "timestamp": time.time(),
        "checks": {},
    }

    # Verificar conectividade
    if worker_type == "android":
        # Para Android/Termux, verificar conectividade básica
        health_status["checks"]["connectivity"] = {
            "status": "ok",
            "message": "Worker Android registrado",
        }
    else:
        # Para outros tipos, tentar conexão SSH
        if ip:
            success, stdout, stderr = execute_remote_command(
                ip, "echo 'health check'", user
            )
            health_status["checks"]["connectivity"] = {
                "status": "ok" if success else "error",
                "message": "Conectado" if success else f"Erro: {stderr}",
            }
        else:
            health_status["checks"]["connectivity"] = {
                "status": "error",
                "message": "IP não fornecida",
            }

    # Verificar recursos locais (se for worker local)
    if ip in ["localhost", "127.0.0.1"]:
        try:
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()

            health_status["checks"]["cpu"] = {
                "status": "ok" if cpu_percent < 90 else "warning",
                "value": cpu_percent,
                "message": f"CPU: {cpu_percent:.1f}%",
            }

            health_status["checks"]["memory"] = {
                "status": "ok" if memory.percent < 90 else "warning",
                "value": memory.percent,
                "message": f"Memória: {memory.percent:.1f}%",
            }
        except:
            health_status["checks"]["resources"] = {
                "status": "error",
                "message": "Não foi possível verificar recursos",
            }

    # Calcular status geral
    all_checks = health_status["checks"].values()
    if any(check["status"] == "error" for check in all_checks):
        overall_status = "error"
    elif any(check["status"] == "warning" for check in all_checks):
        overall_status = "warning"
    else:
        overall_status = "ok"

    health_status["overall_status"] = overall_status

    return health_status


def check_multiple_workers(workers: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Verifica a saúde de múltiplos workers

    Args:
        workers: Lista de dados dos workers

    Returns:
        Lista com status de saúde de cada worker
    """
    results = []

    for worker in workers:
        try:
            health = check_worker_health(worker)
            results.append(health)
        except Exception as e:
            results.append(
                {
                    "worker": worker.get("name", worker.get("ip", "unknown")),
                    "error": str(e),
                    "overall_status": "error",
                }
            )

    return results


def check_android_worker_health(worker_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Verifica a saúde específica de um worker Android

    Args:
        worker_data: Dados do worker Android

    Returns:
        Dicionário com status de saúde específico para Android
    """
    health_status = check_worker_health(worker_data)

    # Verificações específicas para Android
    ip = worker_data.get("ip")
    if not ip:
        return {"error": "IP não fornecida para worker Android"}

    user = worker_data.get("user", "termux")

    # Verificar se é Termux
    success, stdout, stderr = execute_remote_command(ip, "echo $TERMUX_VERSION", user)

    if success and stdout.strip():
        health_status["checks"]["termux_version"] = {
            "status": "ok",
            "message": f"Termux detectado: {stdout.strip()}",
        }
    else:
        health_status["checks"]["termux_version"] = {
            "status": "warning",
            "message": "Termux não detectado ou inacessível",
        }

    # Verificar bateria (específico para Android)
    success, stdout, stderr = execute_remote_command(
        ip,
        "termux-battery-status 2>/dev/null | grep percentage | cut -d: -f2 | tr -d ' ,' || echo 'N/A'",
        user,
    )

    if success and stdout.strip() and stdout.strip() != "N/A":
        try:
            battery_level = int(stdout.strip())
            health_status["checks"]["battery"] = {
                "status": "ok" if battery_level > 20 else "warning",
                "value": battery_level,
                "message": f"Bateria: {battery_level}%",
            }
        except:
            health_status["checks"]["battery"] = {
                "status": "error",
                "message": "Erro ao ler nível de bateria",
            }
    else:
        health_status["checks"]["battery"] = {
            "status": "warning",
            "message": "Informação de bateria não disponível",
        }

    # Recalcular status geral
    all_checks = health_status["checks"].values()
    if any(check["status"] == "error" for check in all_checks):
        overall_status = "error"
    elif any(check["status"] == "warning" for check in all_checks):
        overall_status = "warning"
    else:
        overall_status = "ok"

    health_status["overall_status"] = overall_status

    return health_status


if __name__ == "__main__":
    import configparser
    import os

    # Ler configuração do cluster
    config = configparser.ConfigParser()
    config_path = os.path.join(
        os.path.dirname(__file__), "..", "..", "config", "cluster.conf"
    )

    if os.path.exists(config_path):
        config.read(config_path)

        # Construir lista de workers a partir da configuração
        test_workers = []
        if "workers" in config:
            for key, value in config["workers"].items():
                if key.endswith("_ip"):
                    worker_num = key.split("_")[1]
                    worker_data = {
                        "name": f"worker_{worker_num}",
                        "ip": value,
                        "port": int(
                            config["workers"].get(f"worker_{worker_num}_port", 22)
                        ),
                        "type": "android" if "192.168" in value else "linux",
                        "user": config["workers"].get(
                            f"worker_{worker_num}_user", "termux"
                        ),
                    }
                    test_workers.append(worker_data)
    else:
        # Fallback para configuração hardcoded se arquivo não existir
        test_workers = [
            {
                "name": "local-worker",
                "ip": "localhost",
                "port": 22,
                "type": "linux",
                "user": "dcm",
            },
            {
                "name": "android-worker",
                "ip": "192.168.0.14",
                "port": 8022,
                "type": "android",
                "user": "termux",
            },
        ]

    results = check_multiple_workers(test_workers)

    for result in results:
        print(f"Worker: {result['worker']}")
        print(f"Status: {result.get('overall_status', 'unknown')}")
        if "checks" in result:
            for check_name, check_info in result["checks"].items():
                print(
                    f"  {check_name}: {check_info['status']} - {check_info['message']}"
                )
        print()
