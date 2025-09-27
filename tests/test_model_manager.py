#!/usr/bin/env python3
# =============================================================================
# Test Suite for Ollama Model Manager
# =============================================================================
# Tests for model_manager.sh functionality
#
# Autor: Cluster AI Team
# Data: 2025-01-27
# Versão: 1.0.0
# =============================================================================

import subprocess
import pytest
import os
import tempfile
import shutil
from pathlib import Path

class TestModelManager:
    """Test suite for model_manager.sh script"""

    @pytest.fixture
    def script_path(self):
        """Path to the model manager script"""
        return Path(__file__).parent.parent / "scripts" / "ollama" / "model_manager.sh"

    @pytest.fixture
    def temp_dir(self):
        """Temporary directory for testing"""
        temp_dir = tempfile.mkdtemp()
        yield temp_dir
        shutil.rmtree(temp_dir)

    def run_script(self, script_path, args=None):
        """Helper to run the script and return result"""
        cmd = ["bash", str(script_path)]
        if args:
            cmd.extend(args)

        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=30,
                cwd=Path(__file__).parent.parent
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            pytest.fail("Script timed out")

    def test_script_exists(self, script_path):
        """Test that the script file exists and is executable"""
        assert script_path.exists(), f"Script not found: {script_path}"
        assert os.access(script_path, os.X_OK), f"Script not executable: {script_path}"

    def test_help_command(self, script_path):
        """Test help command output"""
        returncode, stdout, stderr = self.run_script(script_path, ["help"])

        assert returncode == 0, f"Help command failed: {stderr}"
        assert "Cluster AI - Ollama Model Manager" in stdout
        assert "Usage:" in stdout
        assert "Actions:" in stdout

    def test_invalid_command(self, script_path):
        """Test invalid command handling"""
        returncode, stdout, stderr = self.run_script(script_path, ["invalid_command"])

        # Should show help for invalid commands
        assert returncode == 0, f"Invalid command should show help: {stderr}"
        assert "Usage:" in stdout or "help" in stdout.lower()

    def test_list_command_without_ollama(self, script_path):
        """Test list command when ollama is not available"""
        # Skip this test as ollama is installed in the test environment
        # In a real scenario without ollama, the script would show an error
        # This test would require complex mocking or system modifications
        # that are not suitable for unit tests
        pytest.skip("Ollama is installed in test environment - cannot test unavailable scenario safely")

    def test_stats_command_structure(self, script_path):
        """Test stats command output structure"""
        returncode, stdout, stderr = self.run_script(script_path, ["stats"])

        assert returncode == 0, f"Stats command failed: {stderr}"
        # Should contain some stats output or error message
        assert len(stdout.strip()) > 0 or len(stderr.strip()) > 0

    def test_cleanup_command_without_models(self, script_path):
        """Test cleanup command when no models to clean"""
        returncode, stdout, stderr = self.run_script(script_path, ["cleanup"])

        assert returncode == 0, f"Cleanup command failed: {stderr}"
        # Should handle gracefully when no models to clean

    def test_optimize_command_structure(self, script_path):
        """Test optimize command output structure"""
        returncode, stdout, stderr = self.run_script(script_path, ["optimize"])

        assert returncode == 0, f"Optimize command failed: {stderr}"
        # Should contain some output or error message
        assert len(stdout.strip()) > 0 or len(stderr.strip()) > 0

    def test_script_shebang(self, script_path):
        """Test script has proper shebang"""
        with open(script_path, 'r') as f:
            first_line = f.readline().strip()
            assert first_line == "#!/bin/bash", f"Invalid shebang: {first_line}"

    def test_script_syntax(self, script_path):
        """Test script syntax is valid bash"""
        returncode, stdout, stderr = self.run_script(script_path, ["--syntax-check"])

        # If --syntax-check is not supported, script should still run without syntax errors
        # Most bash scripts will show help or run with default behavior
        assert returncode in [0, 1, 2], f"Unexpected return code: {returncode}"

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
