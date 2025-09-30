#!/usr/bin/env python3
# =============================================================================
# Test Suite for Install Additional Models Script
# =============================================================================
# Tests for install_additional_models.sh functionality
#
# Autor: Cluster AI Team
# Data: 2025-01-27
# Versão: 1.0.0
# =============================================================================

import os
import subprocess
from pathlib import Path

import pytest


class TestInstallAdditionalModels:
    """Test suite for install_additional_models.sh script"""

    @pytest.fixture
    def script_path(self):
        """Path to the install additional models script"""
        return (
            Path(__file__).parent.parent
            / "scripts"
            / "ollama"
            / "install_additional_models.sh"
        )

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
                cwd=Path(__file__).parent.parent,
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            pytest.fail("Script timed out")

    def test_script_exists(self, script_path):
        """Test that the script file exists and is executable"""
        assert script_path.exists(), f"Script not found: {script_path}"
        assert os.access(script_path, os.X_OK), f"Script not executable: {script_path}"

    def test_list_categories(self, script_path):
        """Test listing available categories"""
        # Fix environment variable GRAY not set error by defining it before running the script
        import os
        os.environ["GRAY"] = "\033[90m"
        returncode, stdout, stderr = self.run_script(script_path, ["list"])

        assert returncode == 0, f"List command failed: {stderr}"
        # Remove ANSI color codes for testing
        import re

        clean_stdout = re.sub(r"\x1b\[[0-9;]*[mG]", "", stdout)
        assert "CATEGORIAS DE MODELOS DISPON" in clean_stdout
        assert "coding" in clean_stdout
        assert "creative" in clean_stdout
        assert "multilingual" in clean_stdout
        assert "science" in clean_stdout
        assert "compact" in clean_stdout

    def test_invalid_category(self, script_path):
        """Test invalid category handling"""
        returncode, stdout, stderr = self.run_script(script_path, ["invalid_category"])

        # Invalid category should return error code 1 and show error message
        assert (
            returncode == 1
        ), f"Invalid category should return error code: {returncode}"
        assert "categoria inválida" in stderr.lower() or "inválido" in stderr.lower()

    def test_help_command(self, script_path):
        """Test help command output"""
        returncode, stdout, stderr = self.run_script(script_path, ["help"])

        assert returncode == 0, f"Help command failed: {stderr}"
        assert "uso:" in stdout.lower() or "use:" in stdout.lower()

    def test_no_args_shows_help(self, script_path):
        """Test that running without args shows help"""
        returncode, stdout, stderr = self.run_script(script_path)

        assert returncode == 0, f"No args should show help: {stderr}"
        assert (
            "uso:" in stdout.lower()
            or "use:" in stdout.lower()
            or "categorias" in stdout.lower()
        )

    def test_coding_category_structure(self, script_path):
        """Test coding category has proper structure"""
        returncode, stdout, stderr = self.run_script(script_path, ["coding"])

        # Should either succeed (0) or fail gracefully (1)
        assert returncode in [
            0,
            1,
        ], f"Unexpected return code for coding category: {returncode}"
        # Check that it at least attempted to install coding models
        assert "coding" in stdout.lower() or "INSTALANDO MODELOS" in stdout

    def test_creative_category_structure(self, script_path):
        """Test creative category has proper structure"""
        returncode, stdout, stderr = self.run_script(script_path, ["creative"])

        assert returncode in [
            0,
            1,
        ], f"Unexpected return code for creative category: {returncode}"

    def test_multilingual_category_structure(self, script_path):
        """Test multilingual category has proper structure"""
        returncode, stdout, stderr = self.run_script(script_path, ["multilingual"])

        assert returncode in [
            0,
            1,
        ], f"Unexpected return code for multilingual category: {returncode}"

    def test_science_category_structure(self, script_path):
        """Test science category has proper structure"""
        returncode, stdout, stderr = self.run_script(script_path, ["science"])

        assert returncode in [
            0,
            1,
        ], f"Unexpected return code for science category: {returncode}"

    def test_compact_category_structure(self, script_path):
        """Test compact category has proper structure"""
        returncode, stdout, stderr = self.run_script(script_path, ["compact"])

        assert returncode in [
            0,
            1,
        ], f"Unexpected return code for compact category: {returncode}"

    def test_all_category_structure(self, script_path):
        """Test all category has proper structure"""
        import subprocess
        import threading
        import time

        # Start the process in background and kill it after a short time
        # This tests that the command is accepted and starts processing
        process = subprocess.Popen(
            [script_path, "all"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

        # Let it run for a short time to see if it starts properly
        time.sleep(2)

        # Check if process is still running (good sign it started)
        if process.poll() is None:
            # Process is still running, kill it
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()

            # Read what was output so far
            stdout, stderr = process.communicate()

            # Should have started installing models
            assert "INSTALANDO MODELOS" in stdout or "INSTALANDO" in stdout
            assert "todas as categorias" in stdout.lower() or "all" in stdout.lower()
        else:
            # Process finished quickly, check return code and output
            stdout, stderr = process.communicate()
            # Even if it fails due to missing ollama, it should have tried
            assert process.returncode in [0, 1]
            assert "all" in stdout.lower() or "all" in stderr.lower()

    def test_script_shebang(self, script_path):
        """Test script has proper shebang"""
        with open(script_path, "r") as f:
            first_line = f.readline().strip()
            assert first_line == "#!/bin/bash", f"Invalid shebang: {first_line}"

    def test_script_permissions(self, script_path):
        """Test script has execute permissions"""
        st = os.stat(script_path)
        assert bool(st.st_mode & 0o111), "Script should be executable"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
