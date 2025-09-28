import unittest
from unittest.mock import MagicMock, patch

import scripts.monitoring.resource_monitor as resource_monitor


class TestResourceMonitor(unittest.TestCase):

    @patch("psutil.cpu_percent")
    @patch("psutil.virtual_memory")
    @patch("psutil.disk_usage")
    def test_get_local_resources_success(
        self, mock_disk_usage, mock_virtual_memory, mock_cpu_percent
    ):
        mock_cpu_percent.return_value = 50.5
        mock_virtual_memory.return_value = MagicMock(
            percent=60.5, total=8000, available=3000
        )
        mock_disk_usage.return_value = MagicMock(percent=70.5, total=10000, free=4000)

        result = resource_monitor.get_local_resources()
        self.assertEqual(result["cpu_usage"], 50.5)
        self.assertEqual(result["memory_usage"], 60.5)
        self.assertEqual(result["memory_total"], 8000)
        self.assertEqual(result["memory_available"], 3000)
        self.assertEqual(result["disk_usage"], 70.5)
        self.assertEqual(result["disk_total"], 10000)
        self.assertEqual(result["disk_free"], 4000)
        self.assertIn("timestamp", result)

    @patch("scripts.monitoring.resource_monitor.execute_remote_command")
    def test_get_remote_resources_success(self, mock_exec):
        # Mock successful SSH command outputs
        def side_effect(host, cmd, user):
            if "top" in cmd:
                return True, "20.0", ""
            elif "free" in cmd:
                return True, "30.0", ""
            elif "termux-battery-status" in cmd:
                return True, "80", ""
            elif "ping" in cmd:
                return True, "connected", ""
            return False, "", "error"

        mock_exec.side_effect = side_effect

        result = resource_monitor.get_remote_resources("192.168.1.1", "termux")
        self.assertEqual(result["cpu_usage"], 20.0)
        self.assertEqual(result["memory_usage"], 30.0)
        self.assertEqual(result["battery_level"], 80)
        self.assertEqual(result["network_status"], "connected")
        self.assertEqual(result["host"], "192.168.1.1")

    def test_monitor_worker_resources_local(self):
        worker_data = {"ip": "127.0.0.1", "name": "local-worker", "type": "local"}
        result = resource_monitor.monitor_worker_resources(worker_data)
        self.assertEqual(result["worker_name"], "local-worker")
        self.assertEqual(result["worker_type"], "local")
        self.assertIn("cpu_usage", result)

    @patch("scripts.monitoring.resource_monitor.get_remote_resources")
    def test_monitor_worker_resources_remote(self, mock_get_remote):
        mock_get_remote.return_value = {
            "cpu_usage": 10,
            "worker_name": "remote-worker",
            "worker_type": "remote",
        }
        worker_data = {"ip": "192.168.1.2", "name": "remote-worker", "type": "remote"}
        result = resource_monitor.monitor_worker_resources(worker_data)
        self.assertEqual(result["worker_name"], "remote-worker")
        self.assertEqual(result["worker_type"], "remote")


if __name__ == "__main__":
    unittest.main()
