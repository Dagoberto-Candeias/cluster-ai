import sys
from datetime import datetime
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest


@pytest.fixture
def client():
    from fastapi.testclient import TestClient

    # Ensure backend directory is on sys.path for absolute imports inside main_fixed.py
    project_root = Path(__file__).resolve().parents[2]
    backend_dir = project_root / "web-dashboard" / "backend"
    sys.path.insert(0, str(backend_dir))

    from dependencies import get_current_active_user  # type: ignore
    from main_fixed import app  # type: ignore

    from models import User  # type: ignore

    # Override auth for tests (bypass JWT)
    def _override_current_active_user():
        return User(
            username="test",
            email="test@example.com",
            full_name="Tester",
            disabled=False,
        )

    app.dependency_overrides[get_current_active_user] = _override_current_active_user

    return TestClient(app)


class TestAlertsAPI:
    """Test cases for alerts API endpoints"""

    @patch("psutil.cpu_percent")
    @patch("psutil.virtual_memory")
    @patch("psutil.disk_usage")
    @patch("dask.distributed.Client")
    @patch("requests.get")
    def test_get_alerts_normal_conditions(
        self,
        mock_requests_get,
        mock_client,
        mock_disk_usage,
        mock_virtual_memory,
        mock_cpu_percent,
        client,
    ):
        """Test alerts endpoint under normal system conditions"""
        # Mock normal system conditions
        mock_cpu_percent.return_value = 50.0
        mock_memory = MagicMock()
        mock_memory.percent = 60.0
        mock_virtual_memory.return_value = mock_memory
        mock_disk = MagicMock()
        mock_disk.percent = 70.0
        mock_disk_usage.return_value = mock_disk

        # Mock successful service checks
        mock_dask_client = MagicMock()
        mock_client.return_value = mock_dask_client

        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_requests_get.return_value = mock_response

        response = client.get("/api/alerts")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        # Validate structure according to AlertInfo model
        for alert in data:
            assert set(alert.keys()) >= {
                "timestamp",
                "severity",
                "component",
                "message",
            }
            assert alert["severity"].upper() in ["INFO", "WARNING", "CRITICAL", "ERROR"]

    @patch("psutil.cpu_percent")
    @patch("psutil.virtual_memory")
    @patch("psutil.disk_usage")
    def test_get_alerts_high_cpu(
        self, mock_disk_usage, mock_virtual_memory, mock_cpu_percent, client
    ):
        """Test alerts endpoint with high CPU usage"""
        # Mock high CPU usage
        mock_cpu_percent.return_value = 85.0
        mock_memory = MagicMock()
        mock_memory.percent = 60.0
        mock_virtual_memory.return_value = mock_memory
        mock_disk = MagicMock()
        mock_disk.percent = 70.0
        mock_disk_usage.return_value = mock_disk

        response = client.get("/api/alerts")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        for alert in data:
            assert set(alert.keys()) >= {
                "timestamp",
                "severity",
                "component",
                "message",
            }
            assert alert["severity"].upper() in ["INFO", "WARNING", "CRITICAL", "ERROR"]

    @patch("psutil.cpu_percent")
    @patch("psutil.virtual_memory")
    @patch("psutil.disk_usage")
    def test_get_alerts_high_memory(
        self, mock_disk_usage, mock_virtual_memory, mock_cpu_percent, client
    ):
        """Test alerts endpoint with high memory usage"""
        mock_cpu_percent.return_value = 50.0
        mock_memory = MagicMock()
        mock_memory.percent = 90.0
        mock_virtual_memory.return_value = mock_memory
        mock_disk = MagicMock()
        mock_disk.percent = 70.0
        mock_disk_usage.return_value = mock_disk

        response = client.get("/api/alerts")

        assert response.status_code == 200
        data = response.json()
        for alert in data:
            assert set(alert.keys()) >= {
                "timestamp",
                "severity",
                "component",
                "message",
            }
            assert alert["severity"].upper() in ["INFO", "WARNING", "CRITICAL", "ERROR"]

    @patch("psutil.cpu_percent")
    @patch("psutil.virtual_memory")
    @patch("psutil.disk_usage")
    def test_get_alerts_high_disk(
        self, mock_disk_usage, mock_virtual_memory, mock_cpu_percent, client
    ):
        """Test alerts endpoint with high disk usage"""
        mock_cpu_percent.return_value = 50.0
        mock_memory = MagicMock()
        mock_memory.percent = 60.0
        mock_virtual_memory.return_value = mock_memory
        mock_disk = MagicMock()
        mock_disk.percent = 95.0
        mock_disk_usage.return_value = mock_disk

        response = client.get("/api/alerts")

        assert response.status_code == 200
        data = response.json()
        for alert in data:
            assert set(alert.keys()) >= {
                "timestamp",
                "severity",
                "component",
                "message",
            }
            assert alert["severity"].upper() in ["INFO", "WARNING", "CRITICAL", "ERROR"]

    @patch("psutil.cpu_percent")
    @patch("psutil.virtual_memory")
    @patch("psutil.disk_usage")
    @patch("dask.distributed.Client")
    def test_get_alerts_dask_down(
        self,
        mock_client,
        mock_disk_usage,
        mock_virtual_memory,
        mock_cpu_percent,
        client,
    ):
        """Test alerts endpoint when Dask is down"""
        mock_cpu_percent.return_value = 50.0
        mock_memory = MagicMock()
        mock_memory.percent = 60.0
        mock_virtual_memory.return_value = mock_memory
        mock_disk = MagicMock()
        mock_disk.percent = 70.0
        mock_disk_usage.return_value = mock_disk

        # Mock Dask connection failure
        mock_client.side_effect = Exception("Connection failed")

        response = client.get("/api/alerts")

        assert response.status_code == 200
        data = response.json()
        for alert in data:
            assert set(alert.keys()) >= {
                "timestamp",
                "severity",
                "component",
                "message",
            }
            assert alert["severity"].upper() in ["INFO", "WARNING", "CRITICAL", "ERROR"]

    @patch("psutil.cpu_percent")
    @patch("psutil.virtual_memory")
    @patch("psutil.disk_usage")
    @patch("requests.get")
    def test_get_alerts_ollama_down(
        self,
        mock_requests_get,
        mock_disk_usage,
        mock_virtual_memory,
        mock_cpu_percent,
        client,
    ):
        """Test alerts endpoint when Ollama is down"""
        mock_cpu_percent.return_value = 50.0
        mock_memory = MagicMock()
        mock_memory.percent = 60.0
        mock_virtual_memory.return_value = mock_memory
        mock_disk = MagicMock()
        mock_disk.percent = 70.0
        mock_disk_usage.return_value = mock_disk

        # Mock Ollama request failure
        mock_requests_get.side_effect = Exception("Connection failed")

        response = client.get("/api/alerts")

        assert response.status_code == 200
        data = response.json()
        for alert in data:
            assert set(alert.keys()) >= {
                "timestamp",
                "severity",
                "component",
                "message",
            }
            assert alert["severity"].upper() in ["INFO", "WARNING", "CRITICAL", "ERROR"]

    @patch("psutil.cpu_percent")
    @patch("psutil.virtual_memory")
    @patch("psutil.disk_usage")
    @patch("requests.get")
    def test_get_alerts_openwebui_down(
        self,
        mock_requests_get,
        mock_disk_usage,
        mock_virtual_memory,
        mock_cpu_percent,
        client,
    ):
        """Test alerts endpoint when OpenWebUI is down"""
        mock_cpu_percent.return_value = 50.0
        mock_memory = MagicMock()
        mock_memory.percent = 60.0
        mock_virtual_memory.return_value = mock_memory
        mock_disk = MagicMock()
        mock_disk.percent = 70.0
        mock_disk_usage.return_value = mock_disk

        # Mock OpenWebUI request failure
        mock_requests_get.side_effect = Exception("Connection failed")

        response = client.get("/api/alerts")

        assert response.status_code == 200
        data = response.json()
        for alert in data:
            assert set(alert.keys()) >= {
                "timestamp",
                "severity",
                "component",
                "message",
            }
            assert alert["severity"].upper() in ["INFO", "WARNING", "CRITICAL", "ERROR"]

    @patch("psutil.cpu_percent")
    @patch("psutil.virtual_memory")
    @patch("psutil.disk_usage")
    def test_get_alerts_monitoring_error(
        self, mock_disk_usage, mock_virtual_memory, mock_cpu_percent, client
    ):
        """Test alerts endpoint when monitoring itself fails"""
        # Mock psutil failures
        mock_cpu_percent.side_effect = Exception("Monitoring failed")
        mock_memory = MagicMock()
        mock_memory.percent = 60.0
        mock_virtual_memory.return_value = mock_memory
        mock_disk = MagicMock()
        mock_disk.percent = 70.0
        mock_disk_usage.return_value = mock_disk

        response = client.get("/api/alerts")

        assert response.status_code == 200
        data = response.json()
        for alert in data:
            assert set(alert.keys()) >= {
                "timestamp",
                "severity",
                "component",
                "message",
            }
            assert alert["severity"].upper() in ["INFO", "WARNING", "CRITICAL", "ERROR"]

    def test_alert_structure(self, client):
        """Test that alerts have the correct structure"""
        response = client.get("/api/alerts")

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, list)
        for alert in data:
            required_fields = ["message", "timestamp", "severity", "component"]
            for field in required_fields:
                assert field in alert, f"Alert missing required field: {field}"
            assert alert["severity"].upper() in ["INFO", "WARNING", "CRITICAL", "ERROR"]
            datetime.fromisoformat(alert["timestamp"])
