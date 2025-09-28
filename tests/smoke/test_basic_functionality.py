"""
Testes de Fumaça - Verificação Básica da Saúde do Sistema

Estes testes garantem que os componentes fundamentais do Cluster AI
estão funcionando corretamente antes de executar testes mais complexos.
"""

import os
import sys
from pathlib import Path

import pytest

# Adicionar diretório raiz do projeto ao path
PROJECT_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


class TestBasicHealth:
    """Testes básicos de saúde do sistema"""

    def test_project_structure_exists(self):
        """Verificar se a estrutura básica do projeto existe"""
        required_dirs = [
            PROJECT_ROOT / "scripts",
            PROJECT_ROOT / "config",
            PROJECT_ROOT / "tests",
            PROJECT_ROOT / "logs",
        ]

        for directory in required_dirs:
            assert (
                directory.exists()
            ), f"Diretório obrigatório não encontrado: {directory}"
            assert directory.is_dir(), f"Caminho não é um diretório: {directory}"

    def test_configuration_files_exist(self):
        """Verificar se arquivos de configuração essenciais existem"""
        config_files = [
            PROJECT_ROOT / "cluster.conf",
            PROJECT_ROOT / "requirements.txt",
            PROJECT_ROOT / "pytest.ini",
        ]

        for config_file in config_files:
            assert (
                config_file.exists()
            ), f"Arquivo de configuração não encontrado: {config_file}"
            assert config_file.is_file(), f"Caminho não é um arquivo: {config_file}"

    def test_python_environment(self):
        """Verificar se o ambiente Python está configurado corretamente"""
        # Verificar se estamos em um ambiente virtual
        in_venv = sys.prefix != sys.base_prefix
        assert in_venv, "Não está executando em um ambiente virtual"

        # Verificar versão do Python
        assert sys.version_info >= (
            3,
            8,
        ), f"Versão do Python muito antiga: {sys.version}"

    def test_import_core_modules(self):
        """Verificar se os módulos core podem ser importados"""
        try:
            import pytest

            assert pytest is not None
        except ImportError:
            pytest.fail("Não foi possível importar pytest")

        # Verificar se podemos importar pathlib (sempre disponível no Python 3.4+)
        try:
            import pathlib

            assert pathlib is not None
        except ImportError:
            pytest.fail("Não foi possível importar pathlib")


class TestScriptHealth:
    """Testes de saúde dos scripts principais"""

    def test_main_scripts_exist(self):
        """Verificar se os scripts principais existem e são executáveis"""
        main_scripts = [
            PROJECT_ROOT / "manager.sh",
            PROJECT_ROOT / "demo_cluster.py",
            PROJECT_ROOT / "install_unified.sh",
        ]

        for script in main_scripts:
            assert script.exists(), f"Script principal não encontrado: {script}"
            assert script.is_file(), f"Caminho não é um arquivo: {script}"

            # Verificar se é executável (para scripts .sh)
            if script.suffix == ".sh":
                assert os.access(script, os.X_OK), f"Script não é executável: {script}"

    def test_script_syntax(self):
        """Verificar se os scripts Python têm sintaxe válida"""
        python_scripts = [
            PROJECT_ROOT / "demo_cluster.py",
            PROJECT_ROOT / "test_installation.py",
        ]

        import py_compile

        for script in python_scripts:
            if script.exists():
                try:
                    py_compile.compile(str(script), doraise=True)
                except py_compile.PyCompileError as e:
                    pytest.fail(f"Erro de sintaxe no script {script}: {e}")


class TestConfigurationHealth:
    """Testes de saúde da configuração"""

    def test_cluster_config_format(self):
        """Verificar se o arquivo de configuração tem formato válido"""
        config_file = PROJECT_ROOT / "cluster.conf"

        if config_file.exists():
            with open(config_file, "r", encoding="utf-8") as f:
                content = f.read()

            # Verificar se não está vazio
            assert len(content.strip()) > 0, "Arquivo de configuração está vazio"

            # Verificar se contém pelo menos algumas configurações básicas
            # Suporte para formato JSON (atual), INI ou variáveis de ambiente (legacy)
            has_basic_config = (
                "node_ip" in content
                or "NODE_IP=" in content
                or "scheduler_port" in content
                or "DASK_SCHEDULER_PORT=" in content
                or "[cluster]" in content
                or "[dask]" in content
                or '"workers"' in content  # JSON format with workers
                or "workers:" in content  # YAML format
            )
            assert (
                has_basic_config
            ), "Configuração básica não encontrada no cluster.conf"

    def test_environment_variables(self):
        """Verificar se variáveis de ambiente críticas estão definidas"""
        # Verificar se estamos no modo de teste
        test_mode = os.environ.get("CLUSTER_AI_TEST_MODE")
        if test_mode:
            assert test_mode == "1", f"Modo de teste inválido: {test_mode}"


class TestSecurityHealth:
    """Testes básicos de saúde da segurança"""

    def test_secure_file_permissions(self):
        """Verificar se arquivos sensíveis têm permissões adequadas"""
        sensitive_files = [
            PROJECT_ROOT / "cluster.conf",
            PROJECT_ROOT / "config" / "cluster.conf",
        ]

        for sensitive_file in sensitive_files:
            if sensitive_file.exists():
                # Verificar se não é world-writable
                permissions = oct(sensitive_file.stat().st_mode)[-3:]
                assert (
                    permissions[2] != "2"
                    and permissions[2] != "3"
                    and permissions[2] != "6"
                    and permissions[2] != "7"
                ), f"Arquivo sensível tem permissões inseguras: {sensitive_file} ({permissions})"

    def test_no_world_writable_files(self):
        """Verificar que não há arquivos world-writable no projeto"""
        for root, dirs, files in os.walk(PROJECT_ROOT):
            # Pular diretórios de backup e cache
            if any(
                skip in root for skip in ["__pycache__", ".pytest_cache", "backups"]
            ):
                continue

            for file in files:
                file_path = Path(root) / file
                try:
                    permissions = oct(file_path.stat().st_mode)[-3:]
                    # Verificar se o último dígito não permite escrita para others
                    assert permissions[2] not in [
                        "2",
                        "3",
                        "6",
                        "7",
                    ], f"Arquivo world-writable encontrado: {file_path} ({permissions})"
                except (OSError, PermissionError):
                    # Ignorar arquivos que não conseguimos verificar
                    continue
