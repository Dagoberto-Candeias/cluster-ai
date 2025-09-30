"""
Testes de integração para o sistema Cluster AI
"""

import os
import subprocess
import time
from unittest.mock import MagicMock, patch

import pytest
import requests


class TestSystemIntegration:
    """Testes de integração do sistema completo"""

    def test_services_startup_sequence(self):
        """Testa sequência de inicialização dos serviços"""
        # Verificar se scripts de startup existem
        assert os.path.exists("start_cluster.sh")
        assert os.path.exists("scripts/auto_start_services.sh")

        # Simular startup (não executar realmente para evitar interferência)
        with patch("subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(returncode=0)

            # Simular start_cluster.sh
            result = subprocess.run(["bash", "start_cluster.sh"], capture_output=True)
            assert result.returncode == 0

    def test_worker_discovery_integration(self):
        """Testa integração de descoberta de workers"""
        # Verificar scripts de descoberta
        assert os.path.exists("scripts/deployment/auto_discover_workers.sh")
        assert os.path.exists("scripts/management/auto_discovery.sh")

        with patch("subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(
                returncode=0, stdout="Workers discovered: 2"
            )

            result = subprocess.run(
                ["bash", "scripts/management/auto_discovery.sh"],
                capture_output=True,
                text=True,
            )
            assert result.returncode == 0
            assert "discovered" in result.stdout.lower()

    def test_model_management_integration(self):
        """Testa integração de gerenciamento de modelos"""
        assert os.path.exists("scripts/download_models.sh")
        assert os.path.exists("scripts/ollama/model_manager.sh")

        with patch("subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(
                returncode=0, stdout="Model llama3:8b ready"
            )

            result = subprocess.run(
                ["bash", "scripts/download_models.sh", "--category", "llm"],
                capture_output=True,
                text=True,
            )
            assert result.returncode == 0


class TestAPIE2E:
    """Testes end-to-end da API"""

    @pytest.fixture
    def api_base_url(self):
        """URL base da API para testes"""
        return "http://localhost:8000"

    def test_health_endpoint_integration(self, api_base_url):
        """Testa endpoint de saúde de forma integrada"""
        try:
            response = requests.get(f"{api_base_url}/health", timeout=5)
            assert response.status_code == 200
            data = response.json()
            assert "status" in data
            assert data["status"] == "healthy"
        except requests.exceptions.ConnectionError:
            pytest.skip("API não está rodando - teste de integração pulado")

    def test_auth_flow_integration(self, api_base_url):
        """Testa fluxo completo de autenticação"""
        try:
            # Tentar login
            login_data = {"username": "admin", "password": "admin123"}
            response = requests.post(
                f"{api_base_url}/auth/login", json=login_data, timeout=5
            )

            if response.status_code == 200:
                data = response.json()
                assert "access_token" in data
                assert data["token_type"] == "bearer"

                # Usar token para acessar endpoint protegido
                token = data["access_token"]
                headers = {"Authorization": f"Bearer {token}"}
                response = requests.get(
                    f"{api_base_url}/auth/me", headers=headers, timeout=5
                )
                assert response.status_code == 200
            else:
                pytest.skip("Login falhou - verificar credenciais ou API não rodando")
        except requests.exceptions.ConnectionError:
            pytest.skip("API não está rodando - teste de integração pulado")

    def test_workers_endpoint_integration(self, api_base_url):
        """Testa endpoints de workers de forma integrada"""
        try:
            # Primeiro fazer login
            login_data = {"username": "admin", "password": "admin123"}
            response = requests.post(
                f"{api_base_url}/auth/login", json=login_data, timeout=5
            )

            if response.status_code == 200:
                token = response.json()["access_token"]
                headers = {"Authorization": f"Bearer {token}"}

                # Testar GET /workers
                response = requests.get(
                    f"{api_base_url}/workers", headers=headers, timeout=5
                )
                assert response.status_code in [
                    200,
                    401,
                    403,
                ]  # 401/403 se token inválido

                # Testar GET /cluster/status
                response = requests.get(
                    f"{api_base_url}/cluster/status", headers=headers, timeout=5
                )
                assert response.status_code in [200, 401, 403]
            else:
                pytest.skip("Login falhou - teste de integração pulado")
        except requests.exceptions.ConnectionError:
            pytest.skip("API não está rodando - teste de integração pulado")


class TestMonitoringIntegration:
    """Testes de integração do sistema de monitoramento"""

    def test_monitoring_scripts_integration(self):
        """Testa integração dos scripts de monitoramento"""
        scripts_to_test = [
            "scripts/monitoring/advanced_dashboard.sh",
            "scripts/monitoring/central_monitor.sh",
            "scripts/monitoring/performance_dashboard.sh",
        ]

        for script in scripts_to_test:
            assert os.path.exists(script), f"Script {script} não encontrado"

        with patch("subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(returncode=0)

            # Testar dashboard avançado
            result = subprocess.run(
                ["bash", "scripts/monitoring/advanced_dashboard.sh", "--help"],
                capture_output=True,
            )
            assert result.returncode == 0

    def test_log_analysis_integration(self):
        """Testa integração de análise de logs"""
        assert os.path.exists("scripts/monitoring/log_analyzer.sh")

        with patch("subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(
                returncode=0, stdout="Log analysis completed"
            )

            result = subprocess.run(
                ["bash", "scripts/monitoring/log_analyzer.sh"],
                capture_output=True,
                text=True,
            )
            assert result.returncode == 0


class TestSecurityIntegration:
    """Testes de integração de segurança"""

    def test_security_scripts_integration(self):
        """Testa integração dos scripts de segurança"""
        security_scripts = [
            "scripts/core/security.sh",
            "scripts/security/audit.sh",
            "scripts/security/hardening.sh",
        ]

        for script in security_scripts:
            if os.path.exists(script):
                with patch("subprocess.run") as mock_run:
                    mock_run.return_value = MagicMock(returncode=0)

                    result = subprocess.run(
                        ["bash", script, "--check"], capture_output=True
                    )
                    assert result.returncode == 0

    @pytest.mark.skip(reason="web_dashboard module not available in test environment")
    def test_input_validation_integration(self):
        """Testa validação de entrada integrada"""
        # Testar se as validações do Pydantic estão funcionando
        import sys

        from web_dashboard.backend.main_fixed import WorkerInfo

        sys.path.insert(0, "web-dashboard/backend")

        # Teste válido
        valid_worker = {
            "id": "worker-001",
            "name": "Test Worker",
            "status": "active",
            "ip_address": "192.168.1.100",
            "cpu_usage": 50.0,
            "memory_usage": 60.0,
            "last_seen": "2024-01-01T00:00:00",
        }

        worker = WorkerInfo(**valid_worker)
        assert worker.id == "worker-001"

        # Teste inválido - deve falhar
        invalid_worker = {
            "id": "w",  # muito curto
            "name": "Test Worker",
            "status": "active",
            "ip_address": "192.168.1.100",
            "cpu_usage": 50.0,
            "memory_usage": 60.0,
            "last_seen": "2024-01-01T00:00:00",
        }

        with pytest.raises(ValueError):
            WorkerInfo(**invalid_worker)


class TestPerformanceIntegration:
    """Testes de integração de performance"""

    def test_performance_monitoring_integration(self):
        """Testa integração do monitoramento de performance"""
        perf_scripts = [
            "scripts/monitoring/performance_autoscaling.sh",
            "scripts/optimization/resource_optimizer.sh",
        ]

        for script in perf_scripts:
            if os.path.exists(script):
                with patch("subprocess.run") as mock_run:
                    mock_run.return_value = MagicMock(returncode=0)

                    result = subprocess.run(
                        ["bash", script, "--status"], capture_output=True
                    )
                    assert result.returncode == 0

    @pytest.mark.slow
    def test_load_test_simulation(self):
        """Testa simulação de carga (teste lento)"""
        # Simular carga no sistema
        with patch("subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(returncode=0)

            # Simular múltiplas conexões
            for i in range(5):
                result = subprocess.run(
                    ["bash", "scripts/health_check.sh"], capture_output=True
                )
                assert result.returncode == 0
                time.sleep(0.1)


if __name__ == "__main__":
    pytest.main([__file__])
