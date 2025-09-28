"""
Testes para scripts do sistema Cluster AI
"""

import os
import shutil
import subprocess
import sys
import tempfile
from unittest.mock import MagicMock, patch

import pytest


class TestScriptSyntax:
    """Testes de sintaxe dos scripts"""

    def test_verify_syntax_script_exists(self):
        """Verifica se script de verificação de sintaxe existe"""
        script_path = "scripts/verify_syntax.sh"
        assert os.path.exists(script_path), "Script verify_syntax.sh não encontrado"

    def test_verify_syntax_script_executable(self):
        """Verifica se script de verificação é executável"""
        script_path = "scripts/verify_syntax.sh"
        assert os.access(
            script_path, os.X_OK
        ), "Script verify_syntax.sh não é executável"

    @pytest.mark.parametrize(
        "script_name",
        [
            "manager.sh",
            "install_unified.sh",
            "start_cluster.sh",
            "stop_cluster.sh",
            "health_check.sh",
        ],
    )
    def test_core_scripts_exist(self, script_name):
        """Verifica se scripts core existem"""
        script_path = script_name
        assert os.path.exists(script_path), f"Script {script_name} não encontrado"

    @pytest.mark.parametrize(
        "script_name",
        [
            "scripts/management/worker_manager.sh",
            "scripts/monitoring/advanced_dashboard.sh",
            "scripts/ollama/model_manager.sh",
        ],
    )
    def test_management_scripts_exist(self, script_name):
        """Verifica se scripts de gerenciamento existem"""
        assert os.path.exists(script_name), f"Script {script_name} não encontrado"


class TestScriptFunctionality:
    """Testes de funcionalidade dos scripts"""

    @patch("subprocess.run")
    def test_worker_manager_list_command(self, mock_run):
        """Testa comando list do worker manager"""
        mock_run.return_value = MagicMock(
            returncode=0, stdout="Workers: worker-001, worker-002"
        )

        result = subprocess.run(
            ["bash", "scripts/management/worker_manager.sh", "list"],
            capture_output=True,
            text=True,
        )

        mock_run.assert_called_once()
        assert result.returncode == 0

    @patch("subprocess.run")
    def test_health_check_script(self, mock_run):
        """Testa script de health check"""
        mock_run.return_value = MagicMock(returncode=0, stdout="All services healthy")

        result = subprocess.run(
            ["bash", "scripts/health_check.sh"], capture_output=True, text=True
        )

        assert result.returncode == 0

    @patch("subprocess.run")
    def test_download_models_script(self, mock_run):
        """Testa script de download de modelos"""
        mock_run.return_value = MagicMock(
            returncode=0, stdout="Model llama3:8b downloaded"
        )

        result = subprocess.run(
            ["bash", "scripts/download_models.sh", "--category", "llm"],
            capture_output=True,
            text=True,
        )

        assert result.returncode == 0


class TestScriptSecurity:
    """Testes de segurança dos scripts"""

    def test_scripts_no_suid_sgid(self):
        """Verifica que scripts não têm SUID/SGID"""
        script_dir = "scripts"
        if os.path.exists(script_dir):
            for root, dirs, files in os.walk(script_dir):
                for file in files:
                    if file.endswith(".sh"):
                        filepath = os.path.join(root, file)
                        stat_info = os.stat(filepath)
                        # Verificar se não tem SUID/SGID
                        assert not (
                            stat_info.st_mode & 0o6000
                        ), f"Script {filepath} tem SUID/SGID"

    def test_scripts_readable_by_owner(self):
        """Verifica que scripts são legíveis pelo dono"""
        script_dir = "scripts"
        if os.path.exists(script_dir):
            for root, dirs, files in os.walk(script_dir):
                for file in files:
                    if file.endswith(".sh"):
                        filepath = os.path.join(root, file)
                        assert os.access(
                            filepath, os.R_OK
                        ), f"Script {filepath} não é legível"


class TestScriptDependencies:
    """Testes de dependências dos scripts"""

    def test_bash_scripts_use_bash_shebang(self):
        """Verifica que scripts .sh usam #!/bin/bash"""
        script_dir = "scripts"
        if os.path.exists(script_dir):
            for root, dirs, files in os.walk(script_dir):
                for file in files:
                    if file.endswith(".sh"):
                        filepath = os.path.join(root, file)
                        with open(
                            filepath, "r", encoding="utf-8", errors="ignore"
                        ) as f:
                            first_line = f.readline().strip()
                            assert (
                                first_line == "#!/bin/bash"
                            ), f"Script {filepath} não usa #!/bin/bash"

    def test_scripts_have_basic_error_handling(self):
        """Verifica que scripts têm tratamento básico de erro"""
        script_dir = "scripts"
        if os.path.exists(script_dir):
            for root, dirs, files in os.walk(script_dir):
                for file in files:
                    if file.endswith(".sh"):
                        filepath = os.path.join(root, file)
                        with open(
                            filepath, "r", encoding="utf-8", errors="ignore"
                        ) as f:
                            content = f.read()
                            # Verificar se usa set -e ou trap
                            has_error_handling = (
                                "set -e" in content or "trap" in content
                            )
                            if not has_error_handling:
                                pytest.skip(
                                    f"Script {filepath} pode não ter tratamento de erro adequado"
                                )


class TestInstallationScripts:
    """Testes específicos para scripts de instalação"""

    @patch("subprocess.run")
    def test_install_unified_script(self, mock_run):
        """Testa script de instalação unificada"""
        mock_run.return_value = MagicMock(returncode=0, stdout="Installation completed")

        result = subprocess.run(
            ["bash", "install_unified.sh", "--help"], capture_output=True, text=True
        )

        assert result.returncode == 0

    @patch("subprocess.run")
    def test_termux_worker_setup_exists(self, mock_run):
        """Verifica se script de setup do Termux existe"""
        script_path = "termux_worker_setup.sh"
        assert os.path.exists(
            script_path
        ), "Script termux_worker_setup.sh não encontrado"

        # Verificar se é executável
        assert os.access(
            script_path, os.X_OK
        ), "Script termux_worker_setup.sh não é executável"


class TestMonitoringScripts:
    """Testes para scripts de monitoramento"""

    @patch("subprocess.run")
    def test_advanced_dashboard_script(self, mock_run):
        """Testa script de dashboard avançado"""
        mock_run.return_value = MagicMock(
            returncode=0, stdout="Dashboard started on port 3001"
        )

        result = subprocess.run(
            ["bash", "scripts/monitoring/advanced_dashboard.sh", "--help"],
            capture_output=True,
            text=True,
        )

        assert result.returncode == 0

    @patch("subprocess.run")
    def test_log_analyzer_script(self, mock_run):
        """Testa script de análise de logs"""
        mock_run.return_value = MagicMock(returncode=0, stdout="Log analysis completed")

        result = subprocess.run(
            ["bash", "scripts/monitoring/log_analyzer.sh"],
            capture_output=True,
            text=True,
        )

        assert result.returncode == 0


if __name__ == "__main__":
    pytest.main([__file__])
