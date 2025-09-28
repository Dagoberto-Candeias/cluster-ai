#!/usr/bin/env python3
"""
Módulo para verificação de workers
"""

import socket
import time
from typing import Any, Dict, Tuple


def verify_worker(ip: str, port: int, timeout: int = 5) -> Tuple[bool, str]:
    """
    Verifica se um worker está acessível e responde

    Args:
        ip: Endereço IP do worker
        port: Porta do worker
        timeout: Timeout em segundos

    Returns:
        Tupla (sucesso, mensagem)
    """
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(timeout)
        result = sock.connect_ex((ip, port))

        if result == 0:
            sock.close()
            return True, "Worker acessível"
        else:
            sock.close()
            return False, f"Porta {port} fechada"

    except socket.timeout:
        return False, f"Timeout após {timeout} segundos"
    except Exception as e:
        return False, f"Erro de conexão: {str(e)}"


def verify_worker_services(worker_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Verifica todos os serviços de um worker

    Args:
        worker_data: Dados do worker

    Returns:
        Dicionário com status dos serviços
    """
    ip = worker_data.get("ip")
    if not ip:
        return {"error": "IP não fornecida"}

    port = worker_data.get("port", 22)
    worker_type = worker_data.get("type", "unknown")

    results = {"ip": ip, "port": port, "type": worker_type, "services": {}}

    # Verificar conectividade básica
    success, message = verify_worker(ip, port)
    results["services"]["connectivity"] = {
        "status": "ok" if success else "error",
        "message": message,
    }

    # Verificações específicas por tipo
    if worker_type == "android":
        # Verificar se é Termux (porta 8022 típica)
        if port == 8022:
            results["services"]["termux"] = {
                "status": "ok",
                "message": "Porta Termux padrão",
            }
        else:
            results["services"]["termux"] = {
                "status": "warning",
                "message": "Porta não padrão para Termux",
            }

    elif worker_type == "linux":
        # Verificar SSH
        if port == 22:
            results["services"]["ssh"] = {
                "status": "ok",
                "message": "SSH na porta padrão",
            }
        else:
            results["services"]["ssh"] = {
                "status": "ok",
                "message": f"SSH na porta {port}",
            }

    # Calcular status geral
    all_ok = all(service["status"] == "ok" for service in results["services"].values())
    results["overall_status"] = "ok" if all_ok else "warning"

    return results


def test_ssh_connection(
    host: str, port: int = 22, timeout: int = 5
) -> Tuple[bool, str]:
    """
    Testa conexão SSH com um host

    Args:
        host: Host para testar
        port: Porta SSH
        timeout: Timeout em segundos

    Returns:
        Tupla (sucesso, mensagem)
    """
    success, message = verify_worker(host, port, timeout)

    if success:
        return True, "Conexão SSH estabelecida"
    else:
        return False, f"Falha na conexão SSH: {message}"


if __name__ == "__main__":
    # Teste do módulo
    test_worker = {"ip": "192.168.1.100", "port": 8022, "type": "android"}

    result = verify_worker_services(test_worker)
    print(f"Verificação do worker {test_worker['ip']}:")
    print(f"Status geral: {result['overall_status']}")

    for service, info in result["services"].items():
        print(f"  {service}: {info['status']} - {info['message']}")
