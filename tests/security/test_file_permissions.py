"""
Testes de segurança para permissões de arquivos no Cluster AI
"""

import os
import stat
from pathlib import Path
from unittest.mock import mock_open, patch

import pytest


@pytest.mark.security
class TestFilePermissions:
    """Testes para verificar permissões de arquivos críticos"""

    def test_config_file_permissions(self, tmp_path):
        """Testa se arquivos de configuração têm permissões seguras"""
        config_file = tmp_path / "test_config.conf"
        config_file.write_text("test=config")

        # Permissões devem ser 600 (owner read/write only)
        config_file.chmod(0o600)

        st = config_file.stat()
        assert (
            st.st_mode & 0o777 == 0o600
        ), "Arquivo de configuração deve ter permissões 600"

    def test_log_file_permissions(self, tmp_path):
        """Testa se arquivos de log têm permissões apropriadas"""
        log_file = tmp_path / "test.log"
        log_file.write_text("test log entry")

        # Permissões devem ser 644 (owner read/write, group/other read)
        log_file.chmod(0o644)

        st = log_file.stat()
        assert st.st_mode & 0o777 == 0o644, "Arquivo de log deve ter permissões 644"

    def test_ssh_key_permissions(self, tmp_path):
        """Testa se chaves SSH têm permissões seguras"""
        ssh_key = tmp_path / "id_rsa"
        ssh_key.write_text(
            "-----BEGIN OPENSSH PRIVATE KEY-----\ntest\n-----END OPENSSH PRIVATE KEY-----"
        )

        # Permissões devem ser 600 (owner read/write only)
        ssh_key.chmod(0o600)

        st = ssh_key.stat()
        assert st.st_mode & 0o777 == 0o600, "Chave SSH privada deve ter permissões 600"

    def test_directory_permissions(self, tmp_path):
        """Testa se diretórios têm permissões apropriadas"""
        test_dir = tmp_path / "test_dir"
        test_dir.mkdir()

        # Permissões devem ser 755 (owner read/write/execute, group/other read/execute)
        test_dir.chmod(0o755)

        st = test_dir.stat()
        assert st.st_mode & 0o777 == 0o755, "Diretório deve ter permissões 755"

    def test_executable_permissions(self, tmp_path):
        """Testa se executáveis têm permissões corretas"""
        script_file = tmp_path / "test_script.sh"
        script_file.write_text("#!/bin/bash\necho 'test'")

        # Permissões devem ser 755 (owner read/write/execute, group/other read/execute)
        script_file.chmod(0o755)

        st = script_file.stat()
        assert st.st_mode & 0o777 == 0o755, "Script executável deve ter permissões 755"


@pytest.mark.security
class TestFileSecurity:
    """Testes para segurança geral de arquivos"""

    def test_no_world_writable_files(self, tmp_path):
        """Testa que arquivos não são world-writable"""
        test_file = tmp_path / "test.txt"
        test_file.write_text("test")

        # Remove world-writable permission
        current_perms = test_file.stat().st_mode
        test_file.chmod(current_perms & ~stat.S_IWOTH)

        st = test_file.stat()
        assert not (st.st_mode & stat.S_IWOTH), "Arquivos não devem ser world-writable"

    def test_secure_temp_file_creation(self, tmp_path):
        """Testa criação segura de arquivos temporários"""
        import tempfile

        with tempfile.NamedTemporaryFile(mode="w", delete=False, dir=tmp_path) as f:
            f.write("sensitive data")
            temp_path = Path(f.name)

        try:
            # Arquivo temporário deve existir
            assert temp_path.exists(), "Arquivo temporário deve ser criado"

            # Deve ter permissões seguras
            st = temp_path.stat()
            # Pelo menos owner deve ter acesso
            assert st.st_mode & stat.S_IRUSR, "Owner deve ter permissão de leitura"

        finally:
            # Limpeza
            if temp_path.exists():
                temp_path.unlink()

    def test_config_file_not_executable(self, tmp_path):
        """Testa que arquivos de configuração não são executáveis"""
        config_file = tmp_path / "config.txt"
        config_file.write_text("key=value")

        st = config_file.stat()
        assert not (
            st.st_mode & stat.S_IXUSR
        ), "Arquivos de configuração não devem ser executáveis pelo owner"
        assert not (
            st.st_mode & stat.S_IXGRP
        ), "Arquivos de configuração não devem ser executáveis pelo group"
        assert not (
            st.st_mode & stat.S_IXOTH
        ), "Arquivos de configuração não devem ser executáveis por others"
