#!/usr/bin/env python3
"""
Módulo para monitoramento de recursos dos workers
"""

import os
import sys
import time
from typing import Any, Dict, Optional

import psutil

sys.path.append(os.path.join(os.path.dirname(__file__), "..", "management"))
from remote_command import execute_remote_command


def get_local_resources() -> Dict[str, Any]:
    """
    Obtém recursos do sistema local

    Returns:
        Dicionário com informações de recursos
    """
    try:
        cpu_percent = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage("/")

        return {
            "cpu_usage": round(cpu_percent, 1),
            "memory_usage": round(memory.percent, 1),
            "memory_total": memory.total,
            "memory_available": memory.available,
            "disk_usage": round(disk.percent, 1),
            "disk_total": disk.total,
            "disk_free": disk.free,
            "timestamp": time.time(),
        }
    except Exception as e:
        return {
            "error": f"Erro ao obter recursos locais: {str(e)}",
            "timestamp": time.time(),
        }


def get_remote_resources(host: str, user: str = "termux") -> Dict[str, Any]:
    """
    Obtém recursos de um worker remoto via SSH

    Args:
        host: Host remoto
        user: Usuário SSH

    Returns:
        Dicionário com informações de recursos
    """
    if not host:
        return {"error": "Host não fornecido"}

    resources = {"host": host, "timestamp": time.time()}

    try:
        # Obter uso de CPU
        success, stdout, stderr = execute_remote_command(
            host,
            "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1}'",
            user,
        )
        if success and stdout.strip():
            try:
                cpu_usage = float(stdout.strip())
                resources["cpu_usage"] = round(cpu_usage, 1)
            except:
                resources["cpu_usage"] = 0.0
        else:
            resources["cpu_usage"] = 0.0

        # Obter uso de memória
        success, stdout, stderr = execute_remote_command(
            host, "free | grep Mem | awk '{printf \"%.1f\", $3/$2 * 100.0}'", user
        )
        if success and stdout.strip():
            try:
                memory_usage = float(stdout.strip())
                resources["memory_usage"] = round(memory_usage, 1)
            except:
                resources["memory_usage"] = 0.0
        else:
            resources["memory_usage"] = 0.0

        # Obter nível de bateria (para Android)
        success, stdout, stderr = execute_remote_command(
            host,
            "termux-battery-status | grep percentage | cut -d: -f2 | tr -d ' ,' 2>/dev/null || echo 'N/A'",
            user,
        )
        if success and stdout.strip() and stdout.strip() != "N/A":
            try:
                battery_level = int(stdout.strip())
                resources["battery_level"] = battery_level
            except:
                resources["battery_level"] = None
        else:
            resources["battery_level"] = None

        # Status de rede
        success, stdout, stderr = execute_remote_command(
            host,
            "ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo 'connected' || echo 'disconnected'",
            user,
        )
        resources["network_status"] = stdout.strip() if success else "unknown"

    except Exception as e:
        resources["error"] = f"Erro ao obter recursos remotos: {str(e)}"

    return resources


def monitor_worker_resources(worker_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Monitora recursos de um worker específico

    Args:
        worker_data: Dados do worker

    Returns:
        Dicionário com informações de recursos
    """
    ip = worker_data.get("ip")
    if not ip:
        return {"error": "IP não fornecida para worker"}

    user = worker_data.get("user", "termux")
    worker_name = worker_data.get("name", ip)

    if ip in ["localhost", "127.0.0.1"]:
        # Worker local
        resources = get_local_resources()
        resources["worker_name"] = worker_name
        resources["worker_type"] = "local"
    else:
        # Worker remoto
        resources = get_remote_resources(ip, user)
        resources["worker_name"] = worker_name
        resources["worker_type"] = worker_data.get("type", "remote")

    return resources


def get_android_resources(host: str, user: str = "termux") -> Dict[str, Any]:
    """
    Obtém recursos específicos de um dispositivo Android via Termux

    Args:
        host: Host Android
        user: Usuário (normalmente 'termux')

    Returns:
        Dicionário com recursos do Android
    """
    resources = {"host": host, "device_type": "android", "timestamp": time.time()}

    try:
        # Obter uso de CPU
        success, stdout, stderr = execute_remote_command(
            host,
            "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1}'",
            user,
        )
        if success and stdout.strip():
            try:
                cpu_usage = float(stdout.strip())
                resources["cpu_usage"] = round(cpu_usage, 1)
            except:
                resources["cpu_usage"] = 0.0
        else:
            resources["cpu_usage"] = 0.0

        # Obter uso de memória
        success, stdout, stderr = execute_remote_command(
            host, "free | grep Mem | awk '{printf \"%.1f\", $3/$2 * 100.0}'", user
        )
        if success and stdout.strip():
            try:
                memory_usage = float(stdout.strip())
                resources["memory_usage"] = round(memory_usage, 1)
            except:
                resources["memory_usage"] = 0.0
        else:
            resources["memory_usage"] = 0.0

        # Obter nível de bateria (específico para Android)
        success, stdout, stderr = execute_remote_command(
            host,
            "termux-battery-status | grep percentage | cut -d: -f2 | tr -d ' ,' 2>/dev/null || echo 'N/A'",
            user,
        )
        if success and stdout.strip() and stdout.strip() != "N/A":
            try:
                battery_level = int(stdout.strip())
                resources["battery_level"] = battery_level
            except:
                resources["battery_level"] = None
        else:
            resources["battery_level"] = None

        # Status de rede
        success, stdout, stderr = execute_remote_command(
            host,
            "ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo 'connected' || echo 'disconnected'",
            user,
        )
        resources["network_status"] = stdout.strip() if success else "unknown"

        # Informações do dispositivo
        success, stdout, stderr = execute_remote_command(
            host,
            "getprop ro.product.model 2>/dev/null || echo 'Unknown Android Device'",
            user,
        )
        resources["device_model"] = (
            stdout.strip() if success else "Unknown Android Device"
        )

    except Exception as e:
        resources["error"] = f"Erro ao obter recursos Android: {str(e)}"

    return resources


if __name__ == "__main__":
    # Teste do módulo
    print("Recursos locais:")
    local_resources = get_local_resources()
    for key, value in local_resources.items():
        print(f"  {key}: {value}")

    print("\nTestando worker remoto (simulado):")
    test_worker = {
        "name": "test-worker",
        "ip": "192.168.1.100",
        "type": "android",
        "user": "termux",
    }

    resources = monitor_worker_resources(test_worker)
    print(f"Worker: {resources.get('worker_name')}")
    print(f"Tipo: {resources.get('worker_type')}")
    for key, value in resources.items():
        if key not in ["worker_name", "worker_type", "timestamp"]:
            print(f"  {key}: {value}")
