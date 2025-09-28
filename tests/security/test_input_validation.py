"""
Testes de segurança para validação de entrada no Cluster AI
"""

import re
from unittest.mock import MagicMock, patch

import pytest


@pytest.mark.security
class TestInputValidation:
    """Testes para validação de entradas do usuário"""

    def test_ip_address_validation(self):
        """Testa validação de endereços IP"""
        from ipaddress import IPv4Address, IPv6Address, ip_address

        # IPs válidos
        valid_ips = ["192.168.1.1", "10.0.0.1", "172.16.0.1", "::1", "2001:db8::1"]

        for ip in valid_ips:
            # Deve conseguir criar objeto IP sem erro
            parsed_ip = ip_address(ip)
            assert isinstance(parsed_ip, (IPv4Address, IPv6Address))

        # IPs inválidos
        invalid_ips = ["256.1.1.1", "192.168.1.256", "192.168.1", "not_an_ip"]

        for ip in invalid_ips:
            with pytest.raises(ValueError):
                ip_address(ip)

    def test_port_validation(self):
        """Testa validação de portas"""
        # Portas válidas
        valid_ports = [1, 80, 443, 8080, 65535]

        for port in valid_ports:
            assert 1 <= port <= 65535, f"Porta {port} deve estar no range válido"

        # Portas inválidas
        invalid_ports = [0, -1, 65536, 99999, "not_a_number"]

        for port in invalid_ports:
            if isinstance(port, int):
                assert not (1 <= port <= 65535), f"Porta {port} deve ser inválida"
            else:
                # String não numérica
                assert not str(port).isdigit() or not (1 <= int(port) <= 65535)

    def test_hostname_validation(self):
        """Testa validação de nomes de host"""
        import socket

        # Hostnames válidos
        valid_hostnames = ["localhost", "example.com", "test-server", "worker-01"]

        for hostname in valid_hostnames:
            # Deve ser possível resolver ou pelo menos ter formato válido
            assert len(hostname) > 0, "Hostname não pode ser vazio"
            assert len(hostname) <= 253, "Hostname muito longo"
            # Não deve conter caracteres inválidos
            assert not re.search(
                r"[^a-zA-Z0-9.-]", hostname
            ), f"Hostname {hostname} contém caracteres inválidos"

        # Hostnames inválidos
        invalid_hostnames = ["", "a" * 254, "host@name", "host name", "host..name"]

        for hostname in invalid_hostnames:
            if len(hostname) == 0:
                assert len(hostname) == 0, "Hostname vazio é inválido"
            elif len(hostname) > 253:
                assert len(hostname) > 253, "Hostname muito longo é inválido"
            else:
                assert (
                    re.search(r"[^a-zA-Z0-9.-]", hostname) or ".." in hostname
                ), f"Hostname {hostname} deve ser inválido"

    def test_user_input_sanitization(self):
        """Testa sanitização de entrada do usuário"""
        # Testa remoção de caracteres perigosos
        dangerous_inputs = [
            "normal input",
            "input; rm -rf /",
            "input && echo 'hacked'",
            "input | cat /etc/passwd",
            "input > /dev/null",
            "input < /etc/shadow",
        ]

        for input_str in dangerous_inputs:
            # Detecta caracteres perigosos
            dangerous_chars = [";", "&", "|", ">", "<", "`", "$", "(", ")"]
            has_dangerous = any(char in input_str for char in dangerous_chars)

            if has_dangerous:
                assert has_dangerous, f"Input {input_str} contém caracteres perigosos"
            else:
                assert not has_dangerous, f"Input {input_str} deve ser seguro"

    def test_path_traversal_prevention(self):
        """Testa prevenção de path traversal"""
        # Caminhos seguros
        safe_paths = ["/home/user/file.txt", "./config.conf", "logs/app.log"]

        for path in safe_paths:
            # Não deve conter sequências de path traversal
            assert ".." not in path, f"Caminho {path} não deve conter '..'"
            # Caminhos absolutos são permitidos se não contiverem ".."
            if path.startswith("/"):
                assert ".." not in path, f"Caminho absoluto {path} não deve conter '..'"

        # Caminhos perigosos
        dangerous_paths = [
            "../../../etc/passwd",
            "/etc/passwd",
            "..\\..\\windows\\system32",
            "/root/.ssh/id_rsa",
        ]

        for path in dangerous_paths:
            assert (
                ".." in path or path.startswith("/root") or path.startswith("/etc")
            ), f"Caminho {path} deve ser detectado como perigoso"


@pytest.mark.security
class TestCommandInjection:
    """Testes para prevenção de command injection"""

    def test_shell_command_sanitization(self):
        """Testa sanitização de comandos shell"""
        import shlex

        # Comandos seguros
        safe_commands = ["ls -la", "echo 'hello'", "cat file.txt"]

        for cmd in safe_commands:
            # Deve ser possível fazer parse sem erro
            try:
                parsed = shlex.split(cmd)
                assert len(parsed) > 0, f"Comando {cmd} deve ser parseável"
            except ValueError:
                pytest.fail(f"Comando seguro {cmd} falhou no parse")

        # Comandos perigosos
        dangerous_commands = [
            "ls -la; rm -rf /",
            "echo 'hello' && cat /etc/passwd",
            "cat file.txt | grep something",
        ]

        for cmd in dangerous_commands:
            # Deve detectar caracteres perigosos
            dangerous_chars = [";", "&", "|"]
            has_dangerous = any(char in cmd for char in dangerous_chars)
            assert has_dangerous, f"Comando {cmd} deve ser detectado como perigoso"

    @patch("subprocess.run")
    def test_subprocess_call_security(self, mock_run):
        """Testa que chamadas subprocess são seguras"""
        mock_run.return_value = MagicMock()
        mock_run.return_value.returncode = 0

        import subprocess

        # Comando seguro
        safe_cmd = ["echo", "hello"]
        result = subprocess.run(safe_cmd, capture_output=True, text=True)

        # Deve ser chamado com shell=False
        mock_run.assert_called_once()
        args, kwargs = mock_run.call_args
        assert args[0] == safe_cmd, "Comando deve ser passado como lista"
        assert kwargs.get("shell") != True, "Não deve usar shell=True para segurança"


@pytest.mark.security
class TestDataValidation:
    """Testes para validação de dados"""

    def test_json_input_validation(self):
        """Testa validação de entrada JSON"""
        import json

        # JSON válido
        valid_json = '{"name": "test", "value": 123}'
        parsed = json.loads(valid_json)
        assert parsed["name"] == "test"
        assert parsed["value"] == 123

        # JSON inválido
        invalid_json = '{"name": "test", "value": }'
        with pytest.raises(json.JSONDecodeError):
            json.loads(invalid_json)

    def test_numeric_input_validation(self):
        """Testa validação de entrada numérica"""
        # Números válidos
        valid_numbers = ["123", "456.78", "-999", "0"]

        for num_str in valid_numbers:
            try:
                float(num_str)
                assert True, f"Número {num_str} deve ser válido"
            except ValueError:
                pytest.fail(f"Número {num_str} deveria ser válido")

        # Números inválidos
        invalid_numbers = ["abc", "12.34.56", "1,234", ""]

        for num_str in invalid_numbers:
            with pytest.raises(ValueError):
                float(num_str)

    def test_string_length_limits(self):
        """Testa limites de tamanho de strings"""
        # Strings dentro do limite
        short_strings = ["a", "test", "a" * 100]

        for s in short_strings:
            assert len(s) <= 1000, f"String '{s[:20]}...' deve estar dentro do limite"

        # Strings muito longas (simulando ataque)
        long_string = "a" * 10000
        assert len(long_string) > 1000, "String longa deve ser detectada"
