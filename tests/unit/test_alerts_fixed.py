import pytest
from unittest.mock import patch, MagicMock
from datetime import datetime
from backend.api.alerts import router

@pytest.fixture
def client():
    from fastapi.testclient import TestClient
    from fastapi import FastAPI

    app = FastAPI()
    app.include_router(router)
    return TestClient(app)

class TestAlertsAPI:
    """Test cases for alerts API endpoints"""

    @patch('psutil.cpu_percent')
    @patch('psutil.virtual_memory')
    @patch('psutil.disk_usage')
    @patch('dask.distributed.Client')
    @patch('requests.get')
    def test_get_alerts_normal_conditions(self, mock_requests_get, mock_client, mock_disk_usage,
                                         mock_virtual_memory, mock_cpu_percent, client):
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

        response = client.get("/alerts")

        assert response.status_code == 200
        data = response.json()
        assert "alerts" in data
        # Should have system OK alert when everything is normal
        assert len(data["alerts"]) >= 1
        assert any(alert["id"] == "system_ok" for alert in data["alerts"])

    @patch('psutil.cpu_percent')
    @patch('psutil.virtual_memory')
    @patch('psutil.disk_usage')
    def test_get_alerts_high_cpu(self, mock_disk_usage, mock_virtual_memory, mock_cpu_percent, client):
        """Test alerts endpoint with high CPU usage"""
        # Mock high CPU usage
        mock_cpu_percent.return_value = 85.0
        mock_memory = MagicMock()
        mock_memory.percent = 60.0
        mock_virtual_memory.return_value = mock_memory
        mock_disk = MagicMock()
        mock_disk.percent = 70.0
        mock_disk_usage.return_value = mock_disk

        response = client.get("/alerts")

        assert response.status_code == 200
        data = response.json()
        assert "alerts" in data
        # Should have CPU alert
        assert any(alert["id"] == "cpu_high" for alert in data["alerts"])
        cpu_alert = next(alert for alert in data["alerts"] if alert["id"] == "cpu_high")
        assert "85.0%" in cpu_alert["message"]
        assert cpu_alert["severity"] == "warning"

    @patch('psutil.cpu_percent')
    @patch('psutil.virtual_memory')
    @patch('psutil.disk_usage')
    def test_get_alerts_high_memory(self, mock_disk_usage, mock_virtual_memory, mock_cpu_percent, client):
        """Test alerts endpoint with high memory usage"""
        mock_cpu_percent.return_value = 50.0
        mock_memory = MagicMock()
        mock_memory.percent = 90.0
        mock_virtual_memory.return_value = mock_memory
        mock_disk = MagicMock()
        mock_disk.percent = 70.0
        mock_disk_usage.return_value = mock_disk

        response = client.get("/alerts")

        assert response.status_code == 200
        data = response.json()
        # Should have memory alert
        assert any(alert["id"] == "memory_high" for alert in data["alerts"])
        memory_alert = next(alert for alert in data["alerts"] if alert["id"] == "memory_high")
        assert "90.0%" in memory_alert["message"]
        assert memory_alert["severity"] == "warning"

    @patch('psutil.cpu_percent')
    @patch('psutil.virtual_memory')
    @patch('psutil.disk_usage')
    def test_get_alerts_high_disk(self, mock_disk_usage, mock_virtual_memory, mock_cpu_percent, client):
        """Test alerts endpoint with high disk usage"""
        mock_cpu_percent.return_value = 50.0
        mock_memory = MagicMock()
        mock_memory.percent = 60.0
        mock_virtual_memory.return_value = mock_memory
        mock_disk = MagicMock()
        mock_disk.percent = 95.0
        mock_disk_usage.return_value = mock_disk

        response = client.get("/alerts")

        assert response.status_code == 200
        data = response.json()
        # Should have disk alert
        assert any(alert["id"] == "disk_high" for alert in data["alerts"])
        disk_alert = next(alert for alert in data["alerts"] if alert["id"] == "disk_high")
        assert "95.0%" in disk_alert["message"]
        assert disk_alert["severity"] == "critical"

    @patch('psutil.cpu_percent')
    @patch('psutil.virtual_memory')
    @patch('psutil.disk_usage')
    @patch('dask.distributed.Client')
    def test_get_alerts_dask_down(self, mock_client, mock_disk_usage, mock_virtual_memory, mock_cpu_percent, client):
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

        response = client.get("/alerts")

        assert response.status_code == 200
        data = response.json()
        # Should have Dask alert
        assert any(alert["id"] == "dask_down" for alert in data["alerts"])
        dask_alert = next(alert for alert in data["alerts"] if alert["id"] == "dask_down")
        assert dask_alert["severity"] == "critical"

    @patch('psutil.cpu_percent')
    @patch('psutil.virtual_memory')
    @patch('psutil.disk_usage')
    @patch('requests.get')
    def test_get_alerts_ollama_down(self, mock_requests_get, mock_disk_usage, mock_virtual_memory, mock_cpu_percent, client):
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

        response = client.get("/alerts")

        assert response.status_code == 200
        data = response.json()
        # Should have Ollama alert
        assert any(alert["id"] == "ollama_down" for alert in data["alerts"])
        ollama_alert = next(alert for alert in data["alerts"] if alert["id"] == "ollama_down")
        assert ollama_alert["severity"] == "warning"

    @patch('psutil.cpu_percent')
    @patch('psutil.virtual_memory')
    @patch('psutil.disk_usage')
    @patch('requests.get')
    def test_get_alerts_openwebui_down(self, mock_requests_get, mock_disk_usage, mock_virtual_memory, mock_cpu_percent, client):
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

        response = client.get("/alerts")

        assert response.status_code == 200
        data = response.json()
        # Should have OpenWebUI alert
        assert any(alert["id"] == "openwebui_down" for alert in data["alerts"])
        webui_alert = next(alert for alert in data["alerts"] if alert["id"] == "openwebui_down")
        assert webui_alert["severity"] == "warning"

    @patch('psutil.cpu_percent')
    @patch('psutil.virtual_memory')
    @patch('psutil.disk_usage')
    def test_get_alerts_monitoring_error(self, mock_disk_usage, mock_virtual_memory, mock_cpu_percent, client):
        """Test alerts endpoint when monitoring itself fails"""
        # Mock psutil failures
        mock_cpu_percent.side_effect = Exception("Monitoring failed")
        mock_memory = MagicMock()
        mock_memory.percent = 60.0
        mock_virtual_memory.return_value = mock_memory
        mock_disk = MagicMock()
        mock_disk.percent = 70.0
        mock_disk_usage.return_value = mock_disk

        response = client.get("/alerts")

        assert response.status_code == 200
        data = response.json()
        # Should have monitoring error alert
        assert any(alert["id"] == "monitoring_error" for alert in data["alerts"])
        error_alert = next(alert for alert in data["alerts"] if alert["id"] == "monitoring_error")
        assert error_alert["severity"] == "error"
        assert "Monitoring failed" in error_alert["message"]

    def test_alert_structure(self, client):
        """Test that alerts have the correct structure"""
        response = client.get("/alerts")

        assert response.status_code == 200
        data = response.json()
        assert "alerts" in data

        for alert in data["alerts"]:
            required_fields = ["id", "title", "message", "timestamp", "severity"]
            for field in required_fields:
                assert field in alert, f"Alert missing required field: {field}"

            # Check severity values
            assert alert["severity"] in ["info", "warning", "critical", "error"]

            # Check timestamp format
            datetime.fromisoformat(alert["timestamp"])
