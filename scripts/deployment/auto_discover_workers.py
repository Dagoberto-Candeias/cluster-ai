#!/usr/bin/env python3
"""
Módulo para descoberta automática de workers na rede
"""

import ipaddress
import json
import platform
import re
import socket
import subprocess
from typing import Any, Dict, List


def get_mac_address(ip: str) -> str:
    """
    Obtém o endereço MAC de um IP na rede local usando o comando 'arp'.

    Args:
        ip: Endereço IP do dispositivo

    Returns:
        Endereço MAC como string ou vazio se não encontrado
    """
    try:
        if platform.system().lower() == "windows":
            output = subprocess.check_output(f"arp -a {ip}", shell=True).decode()
            mac = re.search(r"([0-9a-f]{2}[:-]){5}([0-9a-f]{2})", output, re.I)
            return mac.group(0) if mac else ""
        else:
            output = subprocess.check_output(["arp", "-n", ip]).decode()
            mac = re.search(r"(([a-f\d]{1,2}:){5}[a-f\d]{1,2})", output, re.I)
            return mac.group(0) if mac else ""
    except Exception:
        return ""


def get_hostname(ip: str) -> str:
    """
    Obtém o hostname de um IP usando reverse DNS lookup.

    Args:
        ip: Endereço IP do dispositivo

    Returns:
        Hostname como string ou vazio se não encontrado
    """
    try:
        return socket.gethostbyaddr(ip)[0]
    except Exception:
        return ""


def discover_workers(network_ranges: List[str] = None) -> List[Dict[str, Any]]:
    """
    Descobre workers automaticamente na rede

    Args:
        network_ranges: Lista de faixas de rede para escanear

    Returns:
        Lista de workers descobertos
    """
    if network_ranges is None:
        network_ranges = ["192.168.0.0/24", "10.0.0.0/24"]

    workers = []

    def is_ip_in_network(ip: str, network: str) -> bool:
        try:
            return ipaddress.ip_address(ip) in ipaddress.ip_network(network)
        except ValueError:
            return False

    try:
        # Simular descoberta de workers
        # Em produção, isso faria scan real da rede
        mock_workers = [
            {
                "ip": "10.0.0.9",
                "port": 22,
                "type": "linux",
                "name": "startprocloud",
            },
            {
                "ip": "10.0.0.5",
                "port": 22,
                "type": "unknown",
                "name": "unknown-device-1",
            },
            {
                "ip": "10.0.0.4",
                "port": 22,
                "type": "linux",
                "name": "note-dago",
            },
            {
                "ip": "10.0.0.7",
                "port": 22,
                "type": "unknown",
                "name": "unknown-device-2",
            },
            {
                "ip": "10.0.0.8",
                "port": 22,
                "type": "linux",
                "name": "pc-dago",
            },
            {
                "ip": "10.0.0.10",
                "port": 22,
                "type": "unknown",
                "name": "unknown-device-3",
            },
            {
                "ip": "10.0.0.11",
                "port": 8022,
                "type": "android",
                "name": "M2101K7BI",
            },
            {
                "ip": "10.0.0.12",
                "port": 22,
                "type": "unknown",
                "name": "unknown-device-4",
            },
        ]

        # Verificar conectividade básica e se o IP está na faixa de rede
        for worker in mock_workers:
            for network in network_ranges:
                if is_ip_in_network(worker["ip"], network):
                    try:
                        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                        sock.settimeout(1)
                        result = sock.connect_ex((worker["ip"], worker["port"]))
                        if result == 0:
                            # Obter hostname e MAC
                            hostname = get_hostname(worker["ip"])
                            mac = get_mac_address(worker["ip"])
                            worker["hostname"] = hostname
                            worker["mac"] = mac
                            workers.append(worker)
                        sock.close()
                    except:
                        pass
                    break

    except Exception as e:
        print(f"Erro na descoberta de workers: {e}")

    return workers


def verify_worker_connection(ip: str, port: int) -> bool:
    """
    Verifica se um worker está acessível

    Args:
        ip: Endereço IP do worker
        port: Porta do worker

    Returns:
        True se acessível, False caso contrário
    """
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((ip, port))
        sock.close()
        return result == 0
    except:
        return False


if __name__ == "__main__":
    # Teste do módulo
    workers = discover_workers()
    print(f"Workers descobertos: {len(workers)}")
    for worker in workers:
        print(f"  - {worker['name']}: {worker['ip']}:{worker['port']}")
