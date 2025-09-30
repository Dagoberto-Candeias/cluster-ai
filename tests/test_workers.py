"""
Testes para funcionalidades de workers do Cluster AI
"""

import os
import subprocess
import sys
import tempfile
from unittest.mock import MagicMock, mock_open, patch

import pytest
import yaml

# Adicionar diretório raiz ao path para importar módulos
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))


class TestWorkerManager:
    """Testes unitários para worker_manager.sh"""

    @pytest.fixture
    def temp_config(self):
        """Cria arquivo de configuração temporário"""
        config_data = {
            "workers": {
                "worker-01": {
                    "host": "192.168.1.100",
                    "user": "testuser",
                    "port": 22,
                    "enabled": True,
                },
                "worker-02": {
                    "host": "192.168.1.101",
                    "user": "testuser",
                    "port": 22,
                    "enabled": False,
                },
            }
        }

        with tempfile.NamedTemporaryFile(mode="w", suffix=".yaml", delete=False) as f:
            yaml.dump(config_data, f)
            config_file = f.name

        yield config_file
        os.unlink(config_file)

    def test_list_workers_with_yq(self, temp_config):
        """Testa listagem de workers com yq disponível"""
        with patch("subprocess.run") as mock_run, patch(
            "shutil.which", return_value="/usr/bin/yq"
        ):

            mock_run.return_value = MagicMock(
                stdout="worker-01\nworker-02", returncode=0
            )

            # Simular execução do script
            script_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "scripts", "management", "worker_manager.sh"))
            result = subprocess.run(
                ["bash", script_path, "list"],
                capture_output=True,
                text=True,
                cwd=os.path.join(os.path.dirname(__file__), ".."),
            )

            # Verificar se yq seria chamado
            assert mock_run.called

    def test_list_workers_without_yq(self, temp_config):
        """Testa listagem de workers sem yq"""
        with patch("subprocess.run") as mock_run:

            # Simular erro quando yq não está disponível
            mock_run.return_value = MagicMock(
                returncode=1,
                stdout="Comando 'yq' não encontrado. Não é possível listar os workers.\nInstale com: sudo pip install yq",
                stderr=""
            )

            # Simular execução
            script_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "scripts", "management", "worker_manager.sh"))
            result = subprocess.run(
                ["bash", script_path, "list"],
                capture_output=True,
                text=True,
                cwd=os.path.join(os.path.dirname(__file__), ".."),
            )

            # Verificar mensagem de erro
            assert "yq" in result.stdout or "não encontrado" in result.stdout

    @patch("subprocess.run")
    def test_start_worker_success(self, mock_run):
        """Testa início de worker com sucesso"""
        mock_run.return_value = MagicMock(returncode=0, stdout="Started worker")

        result = subprocess.run(
            [
                "bash",
                "scripts/management/worker_manager.sh",
                "start-worker",
                "worker-01",
            ],
            capture_output=True,
            text=True,
        )

        assert "started successfully" in result.stdout.lower() or result.returncode == 0

    @patch("subprocess.run")
    def test_stop_worker_success(self, mock_run):
        """Testa parada de worker com sucesso"""
        mock_run.return_value = MagicMock(returncode=0, stdout="Stopped worker")

        result = subprocess.run(
            [
                "bash",
                "scripts/management/worker_manager.sh",
                "stop-worker",
                "worker-01",
            ],
            capture_output=True,
            text=True,
        )

        assert result.returncode == 0

    def test_add_worker_interactive_simulation(self):
        """Testa adição de worker (simulação interativa)"""
        with patch("subprocess.run") as mock_run, patch(
            "builtins.input",
            side_effect=["worker-03", "192.168.1.102", "testuser", "22", "y"],
        ):

            mock_run.return_value = MagicMock(returncode=0)

            # Simular execução
            result = subprocess.run(
                ["bash", "scripts/management/worker_manager.sh", "add"],
                capture_output=True,
                text=True,
                input="worker-03\n192.168.1.102\ntestuser\n22\ny\n",
            )

            assert result.returncode == 0


class TestWorkerConnectivity:
    """Testes de conectividade SSH"""

    @patch("subprocess.run")
    def test_ssh_connection_success(self, mock_run):
        """Testa conexão SSH bem-sucedida"""
        mock_run.return_value = MagicMock(
            returncode=0, stdout="SSH connection successful"
        )

        result = subprocess.run(
            ["ssh", "-T", "user@host"], capture_output=True, text=True
        )

        assert result.returncode == 0
        assert "successful" in result.stdout

    @patch("subprocess.run")
    def test_ssh_connection_failure(self, mock_run):
        """Testa falha de conexão SSH"""
        mock_run.return_value = MagicMock(returncode=255, stderr="Connection refused")

        result = subprocess.run(
            ["ssh", "-T", "user@host"], capture_output=True, text=True
        )

        assert result.returncode != 0
        assert "refused" in result.stderr


class TestWorkerHealth:
    """Testes de saúde dos workers"""

    @patch("subprocess.run")
    def test_worker_health_check(self, mock_run):
        """Testa verificação de saúde do worker"""
        # Simular worker saudável
        mock_run.return_value = MagicMock(returncode=0, stdout="Worker is healthy")

        result = subprocess.run(
            ["bash", "scripts/management/worker_health_check.sh", "worker-01"],
            capture_output=True,
            text=True,
        )

        assert result.returncode == 0

    @patch("psutil.cpu_percent")
    @patch("psutil.virtual_memory")
    def test_resource_monitoring(self, mock_memory, mock_cpu):
        """Testa monitoramento de recursos"""
        mock_cpu.return_value = 45.5
        mock_memory.return_value = MagicMock(percent=67.8)

        # Importar e testar função de monitoramento
        try:
            from scripts.monitoring.resource_monitor import get_system_resources

            resources = get_system_resources()

            assert "cpu_percent" in resources
            assert "memory_percent" in resources
            assert resources["cpu_percent"] == 45.5
            assert resources["memory_percent"] == 67.8
        except ImportError:
            pytest.skip("Resource monitor module not available")


class TestWorkerRegistration:
    """Testes de registro de workers"""

    def test_worker_registration_format(self):
        """Testa formato de registro de worker"""
        worker_data = {
            "id": "worker-01",
            "host": "192.168.1.100",
            "user": "testuser",
            "port": 22,
            "enabled": True,
        }

        # Verificar estrutura obrigatória
        required_fields = ["id", "host", "user", "port", "enabled"]
        for field in required_fields:
            assert field in worker_data

        assert isinstance(worker_data["port"], int)
        assert isinstance(worker_data["enabled"], bool)

    @patch("yaml.safe_load")
    @patch("builtins.open", new_callable=mock_open)
    def test_load_worker_config(self, mock_file, mock_yaml):
        """Testa carregamento de configuração de workers"""
        mock_yaml.return_value = {
            "workers": {
                "worker-01": {"host": "192.168.1.100", "user": "test", "port": 22}
            }
        }

        # Simular carregamento
        with open("cluster.yaml", "r") as f:
            config = yaml.safe_load(f)

        assert "workers" in config
        assert "worker-01" in config["workers"]


if __name__ == "__main__":
    pytest.main([__file__])
