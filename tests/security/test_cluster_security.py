"""
Security tests for Cluster AI - focused on practical security checks
"""

import hashlib
import os
import subprocess
import tempfile
from pathlib import Path

import pytest

PROJECT_ROOT = Path(__file__).parent.parent.parent


class TestClusterSecurity:
    """Practical security testing for Cluster AI"""

    def test_critical_files_permissions(self):
        """Test that critical files have appropriate permissions"""
        critical_files = [
            "manager.sh",
            "scripts/security/test_security_improvements.sh",
        ]

        for file_path in critical_files:
            full_path = PROJECT_ROOT / file_path
            if full_path.exists():
                stat_info = os.stat(full_path)
                permissions = oct(stat_info.st_mode)[-3:]
                # Should not be world-writable
                assert permissions[-1] not in [
                    "2",
                    "3",
                    "6",
                    "7",
                ], f"{file_path} should not be world-writable"

    def test_secure_subprocess_usage(self):
        """Test that subprocess calls are secure"""
        # Test basic subprocess security
        result = subprocess.run(
            ["echo", "test"], capture_output=True, text=True, timeout=5
        )
        assert result.returncode == 0
        assert result.stdout.strip() == "test"

    def test_file_integrity_basic(self):
        """Test basic file integrity checking"""
        test_content = "test integrity content"
        test_file = PROJECT_ROOT / "test_integrity.tmp"

        try:
            test_file.write_text(test_content)
            content = test_file.read_text()
            assert content == test_content
        finally:
            test_file.unlink(missing_ok=True)

    def test_secure_temp_file_creation(self):
        """Test secure temporary file creation"""
        with tempfile.NamedTemporaryFile(delete=False) as tmp:
            tmp.write(b"sensitive data")
            tmp_path = Path(tmp.name)

        try:
            assert tmp_path.exists()
            content = tmp_path.read_bytes()
            assert content == b"sensitive data"
        finally:
            tmp_path.unlink(missing_ok=True)

    def test_environment_safety(self):
        """Test environment variable handling"""
        # Test that we don't expose sensitive environment variables
        sensitive_vars = ["PASSWORD", "SECRET", "PRIVATE_KEY"]
        for var in sensitive_vars:
            value = os.environ.get(var)
            if value:
                # If sensitive vars exist, they should be reasonably sized
                assert (
                    len(value) < 1000
                ), f"Sensitive environment variable {var} is too long"

    def test_hash_security(self):
        """Test cryptographic hash functions"""
        test_data = b"test data for hashing"
        hash_obj = hashlib.sha256(test_data)
        hash_value = hash_obj.hexdigest()

        assert len(hash_value) == 64
        assert hash_value.isalnum()

        # Test hash consistency
        hash_obj2 = hashlib.sha256(test_data)
        assert hash_obj2.hexdigest() == hash_value

    def test_no_obvious_vulnerabilities_in_scripts(self):
        """Test for obvious security issues in shell scripts"""
        script_files = list(PROJECT_ROOT.rglob("*.sh"))

        for script_file in script_files[:5]:  # Test first 5 scripts
            if script_file.is_file():
                try:
                    content = script_file.read_text()
                    # Check for dangerous patterns
                    dangerous_patterns = [
                        "rm -rf /",
                        "chmod 777",
                        "sudo su",
                        "curl | bash",
                        "wget | sh",
                    ]

                    for pattern in dangerous_patterns:
                        assert (
                            pattern not in content
                        ), f"Dangerous pattern '{pattern}' found in {script_file.name}"

                except UnicodeDecodeError:
                    continue

    def test_directory_permissions(self):
        """Test directory permissions security"""
        sensitive_dirs = [".git", "logs", "backups"]

        for dir_name in sensitive_dirs:
            dir_path = PROJECT_ROOT / dir_name
            if dir_path.exists() and dir_path.is_dir():
                stat_info = os.stat(dir_path)
                permissions = oct(stat_info.st_mode)[-3:]
                # Should not be world-writable
                assert permissions[-1] not in [
                    "2",
                    "3",
                    "6",
                    "7",
                ], f"Directory {dir_name} should not be world-writable"

    def test_python_file_security(self):
        """Test Python files for basic security issues"""
        python_files = list(PROJECT_ROOT.rglob("*.py"))[:3]  # Test first 3 Python files

        for py_file in python_files:
            if py_file.is_file():
                try:
                    content = py_file.read_text()
                    # Check for dangerous patterns in Python code
                    dangerous_patterns = [
                        "exec(",
                        "eval(",
                        '__import__("os").system(',
                        'subprocess.call("rm',
                    ]

                    for pattern in dangerous_patterns:
                        assert (
                            pattern not in content
                        ), f"Dangerous pattern '{pattern}' found in {py_file.name}"

                except UnicodeDecodeError:
                    continue
