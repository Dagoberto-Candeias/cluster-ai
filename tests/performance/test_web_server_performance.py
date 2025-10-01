"""
Performance tests for web_server_fixed.sh - Cluster AI

This module contains performance tests for the web server component.
"""

import os
import subprocess
import threading
import time
from pathlib import Path

import psutil
import pytest
import requests

PROJECT_ROOT = Path(__file__).parent.parent.parent
WEB_SERVER_SCRIPT = PROJECT_ROOT / "scripts" / "web_server_fixed.sh"
WEB_DIR = PROJECT_ROOT / "web"
PID_FILE = PROJECT_ROOT / ".web_server_pid"

# Porta configurável via variável de ambiente (padrão: 8080)
PORT = int(os.getenv("WEBSERVER_PORT", "8080"))
BASE_URL = f"http://localhost:{PORT}"


class TestWebServerPerformance:
    """Performance test suite for web server"""

    @pytest.fixture(scope="class", autouse=True)
    def setup_web_server(self):
        """Setup web server for performance tests"""
        # Create web directory and test files
        WEB_DIR.mkdir(exist_ok=True)
        test_html = WEB_DIR / "index.html"
        test_html.write_text("<html><body><h1>Test Page</h1></body></html>")

        # Create large test file for bandwidth tests
        large_file = WEB_DIR / "large_test.bin"
        large_data = b"x" * (1024 * 1024)  # 1MB file
        large_file.write_bytes(large_data)

        yield

        # Cleanup
        self.stop_web_server()
        test_html.unlink(missing_ok=True)
        large_file.unlink(missing_ok=True)

    def start_web_server(self):
        """Start web server"""
        if PID_FILE.exists():
            self.stop_web_server()

        env = dict(os.environ)
        env["WEBSERVER_PORT"] = str(PORT)
        result = subprocess.run(
            [str(WEB_SERVER_SCRIPT), "start"],
            capture_output=True,
            text=True,
            timeout=30,
            env=env,
        )
        assert result.returncode == 0, f"Failed to start web server: {result.stderr}"

        # Wait for server to be ready
        time.sleep(2)

        # Verify it's running
        assert PID_FILE.exists(), "PID file not created"
        pid = int(PID_FILE.read_text().strip())
        assert psutil.pid_exists(pid), "Web server process not running"

        return pid

    def stop_web_server(self):
        """Stop web server"""
        if PID_FILE.exists():
            subprocess.run(
                [str(WEB_SERVER_SCRIPT), "stop"], capture_output=True, timeout=10
            )

    def test_web_server_startup_time(self):
        """Test web server startup time"""
        start_time = time.time()
        pid = self.start_web_server()
        startup_time = time.time() - start_time

        # Should start within 5 seconds
        assert startup_time < 6.0, f"Startup too slow: {startup_time:.2f}s"

        # Verify server is responding
        response = requests.get(f"{BASE_URL}/", timeout=5)
        assert response.status_code == 200

    def test_web_server_response_time(self):
        """Test web server response time"""
        self.start_web_server()

        # Test multiple requests
        response_times = []
        for _ in range(10):
            start_time = time.time()
            response = requests.get(f"{BASE_URL}/", timeout=5)
            response_time = time.time() - start_time

            assert response.status_code == 200
            response_times.append(response_time)

        avg_response_time = sum(response_times) / len(response_times)
        max_response_time = max(response_times)

        # Average response should be under 100ms
        assert (
            avg_response_time < 0.1
        ), f"Average response too slow: {avg_response_time:.3f}s"
        # Max response should be under 500ms
        assert (
            max_response_time < 0.5
        ), f"Max response too slow: {max_response_time:.3f}s"

    def test_concurrent_requests(self):
        """Test web server under concurrent load"""
        self.start_web_server()

        results = []
        errors = []

        def make_request(thread_id):
            try:
                start_time = time.time()
                response = requests.get(f"{BASE_URL}/", timeout=10)
                response_time = time.time() - start_time

                if response.status_code == 200:
                    results.append(response_time)
                else:
                    errors.append(f"Thread {thread_id}: HTTP {response.status_code}")
            except Exception as e:
                errors.append(f"Thread {thread_id}: {e}")

        # Start 20 concurrent threads
        threads = []
        for i in range(20):
            t = threading.Thread(target=make_request, args=(i,))
            threads.append(t)
            t.start()

        # Wait for all threads
        for t in threads:
            t.join(timeout=15)

        # Check results
        assert len(errors) == 0, f"Request errors: {errors}"
        assert len(results) == 20, f"Expected 20 results, got {len(results)}"

        avg_response_time = sum(results) / len(results)
        max_response_time = max(results)

        # Under load, average should still be reasonable
        assert (
            avg_response_time < 1.0
        ), f"Average response under load too slow: {avg_response_time:.3f}s"
        assert (
            max_response_time < 3.0
        ), f"Max response under load too slow: {max_response_time:.3f}s"

    def test_large_file_download(self):
        """Test downloading large files"""
        self.start_web_server()

        start_time = time.time()
        response = requests.get(f"{BASE_URL}/large_test.bin", timeout=30)
        download_time = time.time() - start_time

        assert response.status_code == 200
        assert len(response.content) == 1024 * 1024, "File size mismatch"

        # Should download 1MB within reasonable time (depends on network)
        # Allow up to 10 seconds for slow connections
        assert download_time < 10.0, f"Download too slow: {download_time:.2f}s"

        # Calculate bandwidth (MB/s)
        bandwidth = (1024 * 1024) / download_time / (1024 * 1024)
        assert bandwidth > 0.1, f"Bandwidth too low: {bandwidth:.2f} MB/s"

    def test_memory_usage_during_load(self):
        """Test memory usage during load"""
        pid = self.start_web_server()
        process = psutil.Process(pid)

        initial_memory = process.memory_info().rss / 1024 / 1024  # MB

        # Generate load
        threads = []
        for i in range(50):
            t = threading.Thread(target=lambda: requests.get(f"{BASE_URL}/", timeout=5))
            threads.append(t)
            t.start()

        for t in threads:
            t.join(timeout=10)

        final_memory = process.memory_info().rss / 1024 / 1024  # MB
        memory_increase = final_memory - initial_memory

        # Memory increase should be reasonable (less than 50MB)
        assert (
            memory_increase < 50
        ), f"Memory usage increased too much: +{memory_increase:.1f}MB"

    def test_cpu_usage_during_load(self):
        """Test CPU usage during load"""
        pid = self.start_web_server()
        process = psutil.Process(pid)

        initial_cpu = process.cpu_percent(interval=1)

        # Generate load
        for _ in range(100):
            requests.get(f"{BASE_URL}/", timeout=5)

        final_cpu = process.cpu_percent(interval=1)

        # CPU usage should not exceed 50% during normal load
        assert final_cpu < 50, f"CPU usage too high: {final_cpu}%"

    def test_server_restart_performance(self):
        """Test server restart performance"""
        self.start_web_server()

        start_time = time.time()
        result = subprocess.run(
            [str(WEB_SERVER_SCRIPT), "restart"],
            capture_output=True,
            text=True,
            timeout=20,
        )
        restart_time = time.time() - start_time

        assert result.returncode == 0, f"Restart failed: {result.stderr}"
        assert restart_time < 10.0, f"Restart too slow: {restart_time:.2f}s"

        # Verify server is still responding
        response = requests.get(f"{BASE_URL}/", timeout=5)
        assert response.status_code == 200

    def test_port_conflict_handling(self):
        """Test handling of port conflicts"""
        # Start first server
        pid1 = self.start_web_server()

        # Try to start second server (should find free port)
        result = subprocess.run(
            [str(WEB_SERVER_SCRIPT), "start"],
            capture_output=True,
            text=True,
            timeout=30,
        )

        # Should either fail gracefully or find alternative port
        # (depending on implementation)
        if result.returncode == 0:
            # If successful, should be on different port
            assert "8080" not in result.stdout or "8081" in result.stdout
        else:
            # If failed, should give clear error
            assert (
                "já está rodando" in result.stderr
                or "Address already in use" in result.stderr
            )

    def test_error_handling_performance(self):
        """Test performance of error handling"""
        # Test accessing non-existent file
        start_time = time.time()
        response = requests.get(f"{BASE_URL}/nonexistent.html", timeout=5)
        error_response_time = time.time() - start_time

        assert response.status_code == 404
        assert (
            error_response_time < 0.5
        ), f"Error response too slow: {error_response_time:.3f}s"

    def test_shutdown_performance(self):
        """Test server shutdown performance"""
        self.start_web_server()

        start_time = time.time()
        result = subprocess.run(
            [str(WEB_SERVER_SCRIPT), "stop"], capture_output=True, text=True, timeout=10
        )
        shutdown_time = time.time() - start_time

        assert result.returncode == 0, f"Shutdown failed: {result.stderr}"
        assert shutdown_time < 5.0, f"Shutdown too slow: {shutdown_time:.2f}s"

        # Verify PID file is removed
        assert not PID_FILE.exists(), "PID file not cleaned up"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
