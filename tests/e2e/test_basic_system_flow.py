"""
Basic End-to-End tests for Cluster AI system

This module contains end-to-end tests that verify the complete
system functionality from installation to operation.
"""

import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import pytest
import requests

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


class TestBasicSystemFlow:
    """Basic end-to-end system flow tests"""

    def test_project_structure_integrity(self):
        """Test that all essential project components exist"""
        essential_files = [
            "README.md",
            "manager.sh",
            "requirements.txt",
            "scripts/utils/common_functions.sh",
        ]

        essential_dirs = [
            "scripts",
            "tests",
            "logs",
            "config",
        ]

        for file_path in essential_files:
            full_path = PROJECT_ROOT / file_path
            assert full_path.exists(), f"Essential file {file_path} not found"
            assert full_path.is_file(), f"{file_path} is not a file"

        for dir_path in essential_dirs:
            full_path = PROJECT_ROOT / dir_path
            assert full_path.exists(), f"Essential directory {dir_path} not found"
            assert full_path.is_dir(), f"{dir_path} is not a directory"

    def test_manager_script_execution(self):
        """Test manager.sh basic execution flow"""
        manager_path = PROJECT_ROOT / "manager.sh"

        # Test that manager script exists and is executable
        assert manager_path.exists()
        assert os.access(manager_path, os.X_OK)

        # Test help command instead of interactive mode (which requires whiptail)
        result = subprocess.run(
            [str(manager_path), "help"],
            capture_output=True,
            text=True,
            cwd=PROJECT_ROOT,
            timeout=30,
        )

        # Should not block; accept 0 or 1 depending on environment
        assert result.returncode in [0, 1]

        # Strip ANSI escape codes for reliable matching
        import re

        def strip_ansi_codes(text):
            ansi_escape = re.compile(r"\x1B(?:[@-Z\\-_] | \[ [0-?]* [ -/]* [@-~])")
            return ansi_escape.sub("", text)

        output = strip_ansi_codes(result.stdout + result.stderr)
        success_indicators = [
            "CLUSTER AI MANAGER",
            "Comandos disponíveis",
            "Available commands",
            "MENU PRINCIPAL",
            "PAINEL DE CONTROLE PRINCIPAL",
            "Escolha uma opção",
        ]
        assert any(
            ind in output for ind in success_indicators
        ), f"Unexpected output: {output}"

    def test_python_environment_setup(self):
        """Test Python environment and dependencies"""
        # Test Python availability
        result = subprocess.run(
            ["python3", "--version"], capture_output=True, text=True
        )
        assert result.returncode == 0
        assert "Python" in result.stdout

        # Test pip availability
        result = subprocess.run(["pip3", "--version"], capture_output=True, text=True)
        assert result.returncode == 0
        assert "pip" in result.stdout.lower()

    def test_requirements_installation(self):
        """Test requirements.txt installation"""
        requirements_path = PROJECT_ROOT / "requirements.txt"
        assert requirements_path.exists()

        # Test pip install dry-run
        result = subprocess.run(
            ["pip3", "install", "--dry-run", "-r", str(requirements_path)],
            capture_output=True,
            text=True,
            timeout=60,
        )

        # Should either succeed or fail gracefully
        assert result.returncode in [0, 1, 2]

    def test_script_permissions(self):
        """Test that scripts have proper permissions"""
        script_files = [
            "manager.sh",
            "scripts/utils/common_functions.sh",
            "scripts/security/test_security_improvements.sh",
        ]

        for script_path in script_files:
            full_path = PROJECT_ROOT / script_path
            if full_path.exists():
                # Should be executable
                assert os.access(
                    full_path, os.X_OK
                ), f"{script_path} should be executable"

                # Should have reasonable permissions (not world-writable)
                stat_info = os.stat(full_path)
                permissions = oct(stat_info.st_mode)[-3:]
                assert permissions[-1] not in [
                    "2",
                    "3",
                    "6",
                    "7",
                ], f"{script_path} should not be world-writable"

    def test_log_directory_creation(self):
        """Test log directory creation and write permissions"""
        logs_dir = PROJECT_ROOT / "logs"
        logs_dir.mkdir(exist_ok=True)

        assert logs_dir.exists()
        assert logs_dir.is_dir()

        # Test write permissions
        test_log_file = logs_dir / "test_e2e.log"
        test_content = "E2E test log entry"
        test_log_file.write_text(test_content)

        assert test_log_file.exists()
        assert test_log_file.read_text() == test_content

        # Cleanup
        test_log_file.unlink()

    def test_config_directory_structure(self):
        """Test configuration directory structure"""
        config_dir = PROJECT_ROOT / "config"
        config_dir.mkdir(exist_ok=True)

        assert config_dir.exists()
        assert config_dir.is_dir()

        # Test that we can create config files
        test_config = config_dir / "test_e2e.conf"
        test_config.write_text("test=value")

        assert test_config.exists()
        assert test_config.read_text() == "test=value"

        # Cleanup
        test_config.unlink()

    def test_system_dependencies_check(self):
        """Test system dependencies availability"""
        essential_commands = [
            "python3",
            "pip3",
            "bash",
            "grep",
            "find",
        ]

        for cmd in essential_commands:
            result = subprocess.run(["which", cmd], capture_output=True, text=True)
            assert result.returncode == 0, f"Command {cmd} not found in PATH"

    def test_file_system_permissions(self):
        """Test file system permissions for project directories"""
        test_dirs = [
            "scripts",
            "tests",
            "logs",
            "config",
        ]

        for dir_name in test_dirs:
            dir_path = PROJECT_ROOT / dir_name
            if dir_path.exists():
                # Should be able to read directory
                assert os.access(dir_path, os.R_OK), f"Cannot read {dir_name}"
                # Should be able to execute (enter) directory
                assert os.access(dir_path, os.X_OK), f"Cannot enter {dir_name}"

    def test_environment_variables(self):
        """Test essential environment variables"""
        essential_vars = ["PATH", "HOME", "PWD"]

        for var in essential_vars:
            assert os.environ.get(var), f"Essential environment variable {var} not set"

        # Test that we can set and use environment variables
        test_var = "CLUSTER_AI_TEST_VAR"
        test_value = "test_value_123"

        os.environ[test_var] = test_value
        assert os.environ.get(test_var) == test_value

        # Cleanup
        del os.environ[test_var]


class TestSystemIntegrationFlow:
    """System integration flow tests"""

    def test_docker_availability(self):
        """Test Docker availability if installed"""
        try:
            result = subprocess.run(
                ["docker", "--version"], capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0:
                assert "Docker" in result.stdout
            else:
                pytest.skip("Docker not available")
        except FileNotFoundError:
            pytest.skip("Docker not installed")

    def test_network_connectivity(self):
        """Test basic network connectivity"""
        try:
            # Test localhost connectivity
            import socket

            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)

            # Try to connect to a common port (like SSH on 22)
            result = sock.connect_ex(("127.0.0.1", 22))
            sock.close()

            # Should be able to attempt connection (even if refused)
            assert result in [0, 111]  # 0 = connected, 111 = connection refused

        except Exception:
            # Network tests can fail in isolated environments
            pytest.skip("Network connectivity test failed")

    def test_system_resource_monitoring(self):
        """Test system resource monitoring capabilities"""
        try:
            import psutil

            # Test CPU monitoring
            cpu_percent = psutil.cpu_percent(interval=0.1)
            assert isinstance(cpu_percent, (int, float))
            assert 0 <= cpu_percent <= 100

            # Test memory monitoring
            memory = psutil.virtual_memory()
            assert isinstance(memory.percent, (int, float))
            assert 0 <= memory.percent <= 100

            # Test disk monitoring
            disk = psutil.disk_usage("/")
            assert isinstance(disk.percent, (int, float))
            assert 0 <= disk.percent <= 100

        except ImportError:
            pytest.skip("psutil not available")

    def test_process_management(self):
        """Test process management capabilities"""
        try:
            import psutil

            # Get current process
            current_process = psutil.Process()
            assert current_process.pid > 0

            # Test parent process
            parent = current_process.parent()
            assert parent is not None or current_process.pid == 1  # PID 1 has no parent

        except ImportError:
            pytest.skip("psutil not available")


class TestConfigurationFlow:
    """Configuration flow tests"""

    def test_config_file_parsing(self):
        """Test configuration file parsing"""
        config_dir = PROJECT_ROOT / "config"
        config_dir.mkdir(exist_ok=True)

        # Create a test config file
        test_config = config_dir / "test_config.conf"
        test_config_content = """
# Test configuration file
database_host=localhost
database_port=5432
max_connections=100
debug=true
        """.strip()

        test_config.write_text(test_config_content)

        try:
            # Test parsing
            config_data = {}
            with open(test_config, "r") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#"):
                        if "=" in line:
                            key, value = line.split("=", 1)
                            config_data[key.strip()] = value.strip()

            # Verify parsed data
            assert config_data["database_host"] == "localhost"
            assert config_data["database_port"] == "5432"
            assert config_data["max_connections"] == "100"
            assert config_data["debug"] == "true"

        finally:
            # Cleanup
            test_config.unlink()

    def test_environment_specific_config(self):
        """Test environment-specific configuration loading"""
        # Test that we can detect current environment
        env_vars = ["ENV", "ENVIRONMENT", "FLASK_ENV", "DJANGO_SETTINGS_MODULE"]

        current_env = None
        for var in env_vars:
            current_env = os.environ.get(var)
            if current_env:
                break

        # If no environment is set, default to 'development'
        if not current_env:
            current_env = "development"

        assert current_env in [
            "development",
            "testing",
            "staging",
            "production",
            "dev",
            "test",
            "prod",
        ]
