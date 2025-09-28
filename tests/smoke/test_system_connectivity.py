"""
Testes de Fumaça - Verificação de Conectividade do Sistema

Estes testes verificam se os componentes do sistema podem se comunicar
adequadamente e se os serviços básicos estão acessíveis.
"""

import socket
import subprocess
import sys
from pathlib import Path

import pytest

# Adicionar diretório raiz do projeto ao path
PROJECT_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))


class TestNetworkConnectivity:
    """Testes de conectividade de rede"""

    def test_localhost_connectivity(self):
        """Verificar se localhost está acessível"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1)
            result = sock.connect_ex(("127.0.0.1", 80))
            sock.close()

            # Resultado 0 significa conexão bem-sucedida (mas porta 80 pode não estar aberta)
            # O importante é que não houve erro de rede
            assert result in [0, 111], f"Erro de conectividade localhost: {result}"
        except Exception as e:
            pytest.fail(f"Falha na conectividade localhost: {e}")

    def test_dns_resolution(self):
        """Verificar se resolução DNS está funcionando"""
        try:
            # Tentar resolver um domínio público
            result = socket.gethostbyname("google.com")
            assert result is not None
            assert len(result.split(".")) == 4  # Deve ser um IP válido
        except socket.gaierror:
            pytest.skip("Sem conectividade com internet - pulando teste DNS")
        except Exception as e:
            pytest.fail(f"Falha na resolução DNS: {e}")


class TestPythonEnvironment:
    """Testes do ambiente Python"""

    def test_required_modules_available(self):
        """Verificar se módulos Python essenciais estão disponíveis"""
        required_modules = ["os", "sys", "pathlib", "json", "subprocess"]

        for module in required_modules:
            try:
                __import__(module)
            except ImportError:
                pytest.fail(f"Módulo essencial não encontrado: {module}")

    def test_pytest_functionality(self):
        """Verificar se pytest está funcionando corretamente"""
        # Este teste já passa se chegamos até aqui
        assert True, "Pytest está funcionando"

    def test_virtual_environment(self):
        """Verificar se estamos em um ambiente virtual"""
        in_venv = sys.prefix != sys.base_prefix
        if not in_venv:
            pytest.skip("Não está em ambiente virtual - teste opcional")


class TestFileSystem:
    """Testes do sistema de arquivos"""

    def test_write_permissions(self):
        """Verificar se temos permissões de escrita nos diretórios necessários"""
        test_dirs = [PROJECT_ROOT / "logs", PROJECT_ROOT / "tests" / "reports"]

        for test_dir in test_dirs:
            test_dir.mkdir(parents=True, exist_ok=True)

            test_file = test_dir / "smoke_test.tmp"
            try:
                test_file.write_text("smoke test", encoding="utf-8")
                assert test_file.exists()
                assert test_file.read_text(encoding="utf-8") == "smoke test"
            except Exception as e:
                pytest.fail(f"Erro de permissão de escrita em {test_dir}: {e}")
            finally:
                # Limpar arquivo de teste
                if test_file.exists():
                    test_file.unlink()

    def test_log_directory_accessible(self):
        """Verificar se o diretório de logs é acessível"""
        log_dir = PROJECT_ROOT / "logs"
        log_dir.mkdir(exist_ok=True)

        assert log_dir.exists()
        assert log_dir.is_dir()

        # Verificar se podemos criar um arquivo de log
        log_file = log_dir / "smoke_test.log"
        try:
            log_file.write_text("Test log entry", encoding="utf-8")
            assert log_file.exists()
        except Exception as e:
            pytest.fail(f"Erro ao escrever no diretório de logs: {e}")
        finally:
            if log_file.exists():
                log_file.unlink()


class TestCommandExecution:
    """Testes de execução de comandos"""

    def test_basic_commands(self):
        """Verificar se comandos básicos do sistema funcionam"""
        test_commands = [["echo", "test"], ["pwd"], ["whoami"]]

        for cmd in test_commands:
            try:
                result = subprocess.run(
                    cmd, capture_output=True, text=True, timeout=10, cwd=PROJECT_ROOT
                )
                assert result.returncode == 0, f"Comando falhou: {' '.join(cmd)}"
                assert (
                    len(result.stdout.strip()) > 0
                ), f"Comando não produziu saída: {' '.join(cmd)}"
            except subprocess.TimeoutExpired:
                pytest.fail(f"Comando demorou muito: {' '.join(cmd)}")
            except Exception as e:
                pytest.fail(f"Erro ao executar comando {' '.join(cmd)}: {e}")

    def test_python_execution(self):
        """Verificar se Python pode executar scripts"""
        test_script = """
import sys
print("Python execution test")
sys.exit(0)
"""

        try:
            result = subprocess.run(
                [sys.executable, "-c", test_script],
                capture_output=True,
                text=True,
                timeout=10,
            )
            assert result.returncode == 0
            assert "Python execution test" in result.stdout
        except Exception as e:
            pytest.fail(f"Erro ao executar Python: {e}")


class TestConfigurationLoading:
    """Testes de carregamento de configuração"""

    def test_config_file_accessible(self):
        """Verificar se arquivo de configuração é acessível"""
        config_file = PROJECT_ROOT / "cluster.conf"

        if config_file.exists():
            try:
                content = config_file.read_text(encoding="utf-8")
                assert len(content.strip()) > 0
            except Exception as e:
                pytest.fail(f"Erro ao ler arquivo de configuração: {e}")
        else:
            pytest.skip("Arquivo de configuração não encontrado")

    def test_pytest_config(self):
        """Verificar se configuração do pytest está válida"""
        pytest_config = PROJECT_ROOT / "pytest.ini"

        if pytest_config.exists():
            try:
                content = pytest_config.read_text(encoding="utf-8")
                assert "[tool:pytest]" in content or "[pytest]" in content
            except Exception as e:
                pytest.fail(f"Erro ao ler configuração do pytest: {e}")
        else:
            pytest.skip("Arquivo pytest.ini não encontrado")
