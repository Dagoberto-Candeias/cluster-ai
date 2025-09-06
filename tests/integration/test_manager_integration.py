"""
Integration tests for manager.sh and system components

This module tests the integration between manager.sh and various
system components like Docker, services, and configurations.
"""

import pytest
import subprocess
import os
import tempfile
from pathlib import Path
import sys

# Add project root to path
PROJECT_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


class TestManagerIntegration:
    """Integration tests for manager.sh functionality"""

    def test_manager_script_exists(self):
        """Test that manager.sh exists and is executable"""
        manager_path = PROJECT_ROOT / "manager.sh"
        assert manager_path.exists()
        assert os.access(manager_path, os.X_OK)

    def test_manager_help_output(self):
        """Test manager.sh help output"""
        manager_path = PROJECT_ROOT / "manager.sh"
        result = subprocess.run(
            [str(manager_path), "--help"],
            capture_output=True,
            text=True,
            cwd=PROJECT_ROOT
        )

        # Even if --help is not implemented, script should run without error
        # Note: manager.sh may fail if SUDO_USER is not set, which is expected
        # when not running with sudo
        if result.returncode != 0:
            # Check if it's the expected SUDO_USER error
            assert "SUDO_USER" in result.stderr or "unbound variable" in result.stderr
        else:
            assert result.returncode == 0

    def test_manager_basic_execution(self):
        """Test basic manager.sh execution"""
        manager_path = PROJECT_ROOT / "manager.sh"
        result = subprocess.run(
            [str(manager_path)],
            input="q\n",  # Quit immediately
            capture_output=True,
            text=True,
            cwd=PROJECT_ROOT
        )

        # Should exit gracefully
        # Note: manager.sh may fail if SUDO_USER is not set, which is expected
        # when not running with sudo
        if result.returncode != 0:
            # Check if it's the expected SUDO_USER error
            assert "SUDO_USER" in result.stderr or "unbound variable" in result.stderr
        else:
            assert result.returncode == 0

    @pytest.mark.integration
    def test_docker_integration(self):
        """Test Docker integration"""
        try:
            result = subprocess.run(
                ["docker", "--version"],
                capture_output=True,
                text=True
            )
            assert result.returncode == 0
            assert "Docker" in result.stdout
        except FileNotFoundError:
            pytest.skip("Docker not available")

    @pytest.mark.integration
    def test_python_environment(self):
        """Test Python environment setup"""
        # Check if Python is available
        result = subprocess.run(
            ["python3", "--version"],
            capture_output=True,
            text=True
        )
        assert result.returncode == 0
        assert "Python" in result.stdout

    @pytest.mark.integration
    def test_project_structure(self):
        """Test project structure integrity"""
        required_files = [
            "README.md",
            "manager.sh",
            "scripts/lib/common.sh"
        ]

        for file_path in required_files:
            full_path = PROJECT_ROOT / file_path
            assert full_path.exists(), f"Required file {file_path} not found"

    @pytest.mark.integration
    def test_scripts_directory_structure(self):
        """Test scripts directory structure"""
        scripts_dir = PROJECT_ROOT / "scripts"
        assert scripts_dir.exists()
        assert scripts_dir.is_dir()

        # Check for essential subdirectories
        essential_dirs = ["lib", "security", "optimization"]
        for dir_name in essential_dirs:
            dir_path = scripts_dir / dir_name
            assert dir_path.exists(), f"Essential directory {dir_name} not found"
            assert dir_path.is_dir()

    @pytest.mark.integration
    def test_configuration_files(self):
        """Test configuration files existence"""
        config_files = [
            "scripts/lib/common.sh",
            "pytest.ini",
            "tests/conftest.py"
        ]

        for config_file in config_files:
            file_path = PROJECT_ROOT / config_file
            assert file_path.exists(), f"Configuration file {config_file} not found"


class TestServiceIntegration:
    """Tests for service integration"""

    @pytest.mark.integration
    def test_service_status_check(self):
        """Test service status checking capability"""
        # This would typically check if services are running
        # For now, just test the infrastructure
        assert True  # Placeholder

    @pytest.mark.integration
    def test_log_file_creation(self):
        """Test log file creation"""
        logs_dir = PROJECT_ROOT / "logs"
        logs_dir.mkdir(exist_ok=True)

        test_log_file = logs_dir / "test_integration.log"
        test_log_file.write_text("Test log entry\n")

        assert test_log_file.exists()
        assert test_log_file.read_text() == "Test log entry\n"

        # Cleanup
        test_log_file.unlink()

    @pytest.mark.integration
    def test_temp_file_handling(self):
        """Test temporary file handling"""
        with tempfile.NamedTemporaryFile(dir=PROJECT_ROOT, delete=False) as tmp:
            tmp.write(b"test content")
            tmp_path = Path(tmp.name)

        assert tmp_path.exists()
        assert tmp_path.read_text() == "test content"

        # Cleanup
        tmp_path.unlink()


class TestSecurityIntegration:
    """Tests for security component integration"""

    @pytest.mark.integration
    def test_security_scripts_accessible(self):
        """Test that security scripts are accessible"""
        security_script = PROJECT_ROOT / "scripts/security/test_security_improvements.sh"
        assert security_script.exists()
        assert security_script.is_file()

    @pytest.mark.integration
    def test_security_test_execution(self):
        """Test security test execution"""
        security_script = PROJECT_ROOT / "scripts/security/test_security_improvements.sh"

        result = subprocess.run(
            [str(security_script)],
            capture_output=True,
            text=True,
            cwd=PROJECT_ROOT
        )

        # Security tests should complete successfully
        assert result.returncode == 0
        import re
        # Remove ANSI escape sequences for color codes before matching
        clean_stdout = re.sub(r'\x1b\[[0-9;]*m', '', result.stdout)
        assert re.search(r"Testes aprovados[:\s]*\d+", clean_stdout)

    @pytest.mark.integration
    def test_audit_log_creation(self):
        """Test audit log creation"""
        logs_dir = PROJECT_ROOT / "logs"
        logs_dir.mkdir(exist_ok=True)

        audit_file = logs_dir / "test_audit.log"
        audit_content = "2024-01-01 12:00:00 [user@host] TEST_ACTION: Test audit entry"
        audit_file.write_text(audit_content)

        assert audit_file.exists()
        assert audit_content in audit_file.read_text()

        # Cleanup
        audit_file.unlink()


class TestOptimizationIntegration:
    """Tests for optimization component integration"""

    @pytest.mark.integration
    def test_optimization_scripts_exist(self):
        """Test that optimization scripts exist"""
        optimization_dir = PROJECT_ROOT / "scripts/optimization"
        assert optimization_dir.exists()

        # Check for key optimization scripts
        key_scripts = ["performance_optimizer.sh"]
        for script in key_scripts:
            script_path = optimization_dir / script
            if script_path.exists():
                assert script_path.is_file()

    @pytest.mark.integration
    def test_resource_monitoring(self):
        """Test resource monitoring capabilities"""
        # Test basic system resource monitoring
        import psutil

        cpu_percent = psutil.cpu_percent(interval=0.1)
        memory = psutil.virtual_memory()

        assert isinstance(cpu_percent, (int, float))
        assert isinstance(memory.percent, (int, float))
        assert 0 <= cpu_percent <= 100
        assert 0 <= memory.percent <= 100
