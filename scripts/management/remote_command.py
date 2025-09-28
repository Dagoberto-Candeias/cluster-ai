#!/usr/bin/env python3
"""
Módulo para execução de comandos remotos em workers
"""

import shlex
import subprocess
from typing import Optional, Tuple


def execute_remote_command(
    host: str,
    command: str,
    user: str = "termux",
    key_file: Optional[str] = None,
    timeout: int = 30,
) -> Tuple[bool, str, str]:
    """
    Executa um comando remoto via SSH

    Args:
        host: Host remoto
        command: Comando a executar
        user: Usuário SSH
        key_file: Arquivo de chave SSH (opcional)
        timeout: Timeout em segundos

    Returns:
        Tupla (sucesso, stdout, stderr)
    """
    try:
        # Construir comando SSH
        ssh_cmd = [
            "ssh",
            "-o",
            "StrictHostKeyChecking=no",
            "-o",
            "UserKnownHostsFile=/dev/null",
        ]

        if key_file:
            ssh_cmd.extend(["-i", key_file])

        ssh_cmd.extend([f"{user}@{host}", command])

        # Executar comando
        result = subprocess.run(
            ssh_cmd, capture_output=True, text=True, timeout=timeout
        )

        success = result.returncode == 0
        return success, result.stdout, result.stderr

    except subprocess.TimeoutExpired:
        return False, "", f"Comando expirou após {timeout} segundos"
    except Exception as e:
        return False, "", f"Erro ao executar comando remoto: {str(e)}"


def test_ssh_connection(
    host: str, user: str = "termux", key_file: Optional[str] = None, timeout: int = 10
) -> Tuple[bool, str]:
    """
    Testa conexão SSH com um host

    Args:
        host: Host para testar
        user: Usuário SSH
        key_file: Arquivo de chave SSH (opcional)
        timeout: Timeout em segundos

    Returns:
        Tupla (sucesso, mensagem)
    """
    success, stdout, stderr = execute_remote_command(
        host, "echo 'SSH connection test'", user, key_file, timeout
    )

    if success:
        return True, "Conexão SSH estabelecida com sucesso"
    else:
        return False, f"Falha na conexão SSH: {stderr}"


def execute_remote_script(
    host: str,
    script_content: str,
    user: str = "termux",
    key_file: Optional[str] = None,
    timeout: int = 30,
) -> Tuple[bool, str, str]:
    """
    Executa um script remoto via SSH

    Args:
        host: Host remoto
        script_content: Conteúdo do script a executar
        user: Usuário SSH
        key_file: Arquivo de chave SSH (opcional)
        timeout: Timeout em segundos

    Returns:
        Tupla (sucesso, stdout, stderr)
    """
    # Criar comando para executar script remotamente
    remote_cmd = f"bash -c '{script_content.replace(chr(39), chr(92) + chr(39))}'"

    return execute_remote_command(host, remote_cmd, user, key_file, timeout)


if __name__ == "__main__":
    # Teste do módulo
    test_host = "192.168.1.100"

    success, message = test_ssh_connection(test_host)
    print(f"Teste de conexão com {test_host}: {'Sucesso' if success else 'Falha'}")
    print(f"Mensagem: {message}")

    if success:
        # Testar comando remoto
        success, stdout, stderr = execute_remote_command(test_host, "uname -a")
        if success:
            print(f"Comando executado: {stdout.strip()}")
        else:
            print(f"Erro no comando: {stderr}")
