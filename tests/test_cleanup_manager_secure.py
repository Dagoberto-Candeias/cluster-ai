#!/usr/bin/env python3
# =============================================================================
# Test Suite for Secure Cleanup Manager
# =============================================================================
# Tests for cleanup_manager_secure.sh functionality
#
# Autor: Cluster AI Team
# Data: 2025-01-27
# Versão: 1.0.0
# =============================================================================

import os
import subprocess
import tempfile
from pathlib import Path

import pytest


class TestCleanupManagerSecure:
    """Test suite for cleanup_manager_secure.sh script"""

    @pytest.fixture
    def script_path(self):
        """Path to the secure cleanup manager script"""
        return (
            Path(__file__).parent.parent
            / "scripts"
            / "management"
            / "cleanup_manager_secure.sh"
        )

    def run_script(self, script_path, args=None, input_text=None):
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
                input=input_text or "",
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
        assert "Cluster AI - Secure Cleanup Manager" in stdout
        assert "Uso:" in stdout
        assert "Ações:" in stdout

    def test_stats_command(self, script_path):
        """Test stats command output"""
        returncode, stdout, stderr = self.run_script(script_path, ["stats"])

        assert returncode == 0, f"Stats command failed: {stderr}"
        assert "ESTATÍSTICAS DE LIMPEZA" in stdout
        assert "Backups antigos" in stdout
        assert "Logs antigos" in stdout
        assert "Arquivos temporários" in stdout
        assert "Diretórios de cache" in stdout

    def test_invalid_command(self, script_path):
        """Test invalid command handling"""
        returncode, stdout, stderr = self.run_script(script_path, ["invalid_command"])

        assert returncode == 0, f"Invalid command should show help: {stderr}"
        assert "Uso:" in stdout or "help" in stdout.lower()

    def test_no_args_shows_help(self, script_path):
        """Test that running without args shows help"""
        returncode, stdout, stderr = self.run_script(script_path)

        assert returncode == 0, f"No args should show help: {stderr}"
        assert "Uso:" in stdout or "help" in stdout.lower()

    def test_backups_command_no_backups(self, script_path):
        """Test backups command when no old backups exist"""
        returncode, stdout, stderr = self.run_script(script_path, ["backups"])

        assert returncode == 0, f"Backups command failed: {stderr}"
        # Should handle gracefully when no backups to clean

    def test_logs_command_no_logs(self, script_path):
        """Test logs command when no old logs exist"""
        returncode, stdout, stderr = self.run_script(script_path, ["logs"])

        assert returncode == 0, f"Logs command failed: {stderr}"
        # Should handle gracefully when no logs to clean

    def test_temp_command_no_temp_files(self, script_path):
        """Test temp command when no old temp files exist"""
        returncode, stdout, stderr = self.run_script(script_path, ["temp"])

        assert returncode == 0, f"Temp command failed: {stderr}"
        # Should handle gracefully when no temp files to clean

    def test_cache_command_structure(self, script_path):
        """Test cache command output structure"""
        returncode, stdout, stderr = self.run_script(script_path, ["cache"])

        assert returncode == 0, f"Cache command failed: {stderr}"
        # Should contain some output about cache cleaning

    def test_script_shebang(self, script_path):
        """Test script has proper shebang"""
        with open(script_path, "r") as f:
            first_line = f.readline().strip()
            assert first_line == "#!/bin/bash", f"Invalid shebang: {first_line}"

    def test_script_permissions(self, script_path):
        """Test script has execute permissions"""
        st = os.stat(script_path)
        assert bool(st.st_mode & 0o111), "Script should be executable"

    def test_script_uses_common_library(self, script_path):
        """Test script sources the common library"""
        with open(script_path, "r") as f:
            content = f.read()
            assert (
                'source "${PROJECT_ROOT}/scripts/utils/common_functions.sh"' in content
            ), "Script should source consolidated common_functions.sh library"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
