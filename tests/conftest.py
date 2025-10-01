"""
Configuração global para testes do Cluster AI

Este arquivo contém fixtures e configurações compartilhadas
por todos os testes da suíte.
"""

import gc
import os
import shutil
import sys
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import psutil
import pytest

# Adicionar diretório raiz do projeto ao path
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

# Configurações de teste
TEST_CONFIG = {
    "temp_dir": None,
    "test_data_dir": PROJECT_ROOT / "tests" / "fixtures",
    "mock_external_services": True,
    "cleanup_after_tests": True,
}


@pytest.fixture(scope="session", autouse=True)
def setup_test_environment():
    """Configuração global do ambiente de testes"""
    # Criar diretório temporário para testes
    TEST_CONFIG["temp_dir"] = Path(tempfile.mkdtemp(prefix="cluster_ai_test_"))

    # Configurar variáveis de ambiente para testes
    os.environ["CLUSTER_AI_TEST_MODE"] = "1"
    os.environ["CLUSTER_AI_CONFIG_DIR"] = str(TEST_CONFIG["temp_dir"] / "config")
    os.environ["CLUSTER_AI_LOG_DIR"] = str(TEST_CONFIG["temp_dir"] / "logs")

    # Criar diretórios necessários
    (TEST_CONFIG["temp_dir"] / "config").mkdir(parents=True, exist_ok=True)
    (TEST_CONFIG["temp_dir"] / "logs").mkdir(parents=True, exist_ok=True)

    yield

    # Limpeza após todos os testes
    if TEST_CONFIG["cleanup_after_tests"]:
        shutil.rmtree(TEST_CONFIG["temp_dir"], ignore_errors=True)


@pytest.fixture(autouse=True)
def memory_cleanup():
    """Fixture para limpeza de memória entre testes"""
    # Executar coleta de lixo antes do teste
    gc.collect()

    yield

    # Executar coleta de lixo após o teste para liberar memória
    gc.collect()

    # Pequena pausa para permitir que o sistema libere recursos
    import time

    time.sleep(0.01)


@pytest.fixture
def temp_dir(request):
    """Fixture que fornece um diretório temporário para testes"""
    test_name = request.node.name
    test_temp_dir = TEST_CONFIG["temp_dir"] / f"test_{test_name}"
    test_temp_dir.mkdir(parents=True, exist_ok=True)
    return test_temp_dir


@pytest.fixture
def temp_file_with_content(temp_dir):
    """
    Fixture que depende de 'temp_dir' para criar um arquivo temporário
    com conteúdo. Retorna uma tupla (path_do_arquivo, conteudo).
    """
    file_path = temp_dir / "test_data.txt"
    content = "Este é um dado de teste."
    file_path.write_text(content, encoding="utf-8")
    return file_path, content


@pytest.fixture(
    params=[
        pytest.param("admin", marks=pytest.mark.slow, id="admin_user"),
        pytest.param("guest", id="guest_user"),
    ]
)
def user_account(request):
    """
    Fixture parametrizada que cria diferentes tipos de contas de usuário.
    Os testes que a utilizam serão executados uma vez para cada parâmetro.
    O parâmetro 'admin' está marcado como 'slow'.
    """
    user_type = request.param
    print(f"\n[SETUP] Criando usuário do tipo: {user_type}")
    if user_type == "admin":
        user_data = {
            "username": "admin_user",
            "type": "admin",
            "permissions": ["read", "write", "delete"],
        }
    elif user_type == "guest":
        user_data = {"username": "guest_user", "type": "guest", "permissions": ["read"]}

    yield user_data

    print(f"\n[TEARDOWN] Limpando usuário do tipo: {user_type}")


@pytest.fixture
def user_account_factory():
    """
    Fixture que implementa o padrão 'factory as a fixture'.
    Retorna uma função que pode ser usada para criar múltiplos tipos de usuários
    dentro de um mesmo teste.
    """

    def _create_user(user_type="guest", custom_permissions=None):
        if user_type == "admin":
            permissions = ["read", "write", "delete"]
            username = "admin_factory_user"
        else:  # guest
            permissions = ["read"]
            username = "guest_factory_user"

        if custom_permissions is not None:
            permissions = custom_permissions
        return {"username": username, "type": user_type, "permissions": permissions}

    return _create_user


@pytest.fixture
def mock_dask_cluster():
    """Fixture que mocka um cluster Dask para testes"""
    with patch("dask.distributed.LocalCluster") as mock_cluster_class:
        mock_cluster_instance = MagicMock()
        mock_client_instance = MagicMock()

        # Configurar comportamento padrão
        mock_cluster_instance.__enter__.return_value = mock_cluster_instance
        mock_cluster_instance.__exit__.return_value = None
        mock_cluster_instance.dashboard_link = "http://localhost:8787"

        mock_client_instance.__enter__.return_value = mock_client_instance
        mock_client_instance.__exit__.return_value = None
        mock_client_instance.map.return_value = [1, 4, 9, 16, 25]  # quadrados
        mock_client_instance.submit.return_value = MagicMock()
        mock_client_instance.gather.return_value = [1, 1, 2, 3, 5]  # fibonacci

        mock_cluster_class.return_value = mock_cluster_instance

        with patch("dask.distributed.Client") as mock_client_class:
            mock_client_class.return_value = mock_client_instance

            yield {
                "cluster": mock_cluster_instance,
                "client": mock_client_instance,
                "cluster_class": mock_cluster_class,
                "client_class": mock_client_class,
            }


@pytest.fixture(scope="module")
def real_dask_cluster():
    """
    Fixture que inicia um cluster Dask real (LocalCluster) para testes de integração
    e garante seu encerramento ao final dos testes do módulo.
    """
    from dask.distributed import Client, LocalCluster

    cluster = None
    client = None
    try:
        cluster = LocalCluster(n_workers=2, threads_per_worker=2, processes=False)
        client = Client(cluster)
        print(f"\nCluster Dask de integração iniciado em: {cluster.scheduler_address}")
        yield client  # Disponibiliza o cliente para os testes
    finally:
        print("\nEncerrando cluster Dask de integração...")
        if client:
            client.close()
        if cluster:
            cluster.close()


@pytest.fixture
def mock_pytorch():
    """Fixture que mocka PyTorch para testes"""
    with patch("torch.tensor") as mock_tensor, patch(
        "torch.randn"
    ) as mock_randn, patch("torch.cuda.is_available") as mock_cuda_available:

        # Configurar mocks
        mock_tensor.return_value = MagicMock()
        mock_tensor.return_value.__mul__ = MagicMock(return_value=MagicMock())
        mock_tensor.return_value.__add__ = MagicMock(return_value=MagicMock())

        mock_randn.return_value = MagicMock()
        mock_cuda_available.return_value = False  # CPU only para testes

        yield {
            "tensor": mock_tensor,
            "randn": mock_randn,
            "cuda_available": mock_cuda_available,
        }


@pytest.fixture
def sample_config_data():
    """Fixture com dados de configuração de exemplo"""
    return {
        "cluster": {
            "name": "test_cluster",
            "workers": 2,
            "threads_per_worker": 2,
            "memory_limit": "1GB",
        },
        "services": {
            "dask_scheduler_port": 8786,
            "dask_dashboard_port": 8787,
            "ollama_port": 11434,
            "openwebui_port": 3000,
        },
        "paths": {
            "project_root": str(PROJECT_ROOT),
            "logs_dir": str(PROJECT_ROOT / "logs"),
            "config_dir": str(PROJECT_ROOT / "config"),
        },
    }


@pytest.fixture
def mock_subprocess():
    """Fixture que mocka subprocess para testes de comandos do sistema"""
    with patch("subprocess.run") as mock_run, patch(
        "subprocess.Popen"
    ) as mock_popen, patch("subprocess.call") as mock_call:

        # Configurar comportamento padrão (sucesso)
        mock_run.return_value = MagicMock()
        mock_run.return_value.returncode = 0
        mock_run.return_value.stdout = "Command executed successfully"
        mock_run.return_value.stderr = ""

        mock_popen.return_value = MagicMock()
        mock_popen.return_value.communicate.return_value = ("output", "")
        mock_popen.return_value.returncode = 0

        mock_call.return_value = 0

        yield {"run": mock_run, "Popen": mock_popen, "call": mock_call}


@pytest.fixture
def mock_file_operations():
    """Fixture que mocka operações de arquivo"""
    with patch("pathlib.Path.exists") as mock_exists, patch(
        "pathlib.Path.is_file"
    ) as mock_is_file, patch("pathlib.Path.is_dir") as mock_is_dir, patch(
        "pathlib.Path.mkdir"
    ) as mock_mkdir, patch(
        "pathlib.Path.write_text"
    ) as mock_write_text, patch(
        "pathlib.Path.read_text"
    ) as mock_read_text:

        # Configurar comportamento padrão
        mock_exists.return_value = True
        mock_is_file.return_value = True
        mock_is_dir.return_value = False
        mock_mkdir.return_value = None
        mock_write_text.return_value = None
        mock_read_text.return_value = "file content"

        yield {
            "exists": mock_exists,
            "is_file": mock_is_file,
            "is_dir": mock_is_dir,
            "mkdir": mock_mkdir,
            "write_text": mock_write_text,
            "read_text": mock_read_text,
        }


def pytest_collection_modifyitems(config, items):
    """Modificar itens de teste coletados"""
    for item in items:
        # Adicionar marcador 'unit' automaticamente para testes em tests/unit/
        if "tests/unit/" in str(item.fspath):
            item.add_marker(pytest.mark.unit)

        # Adicionar marcador 'integration' automaticamente para testes em tests/integration/
        elif "tests/integration/" in str(item.fspath):
            item.add_marker(pytest.mark.integration)

        # Adicionar marcador 'e2e' automaticamente para testes em tests/e2e/
        elif "tests/e2e/" in str(item.fspath):
            item.add_marker(pytest.mark.e2e)

        # Adicionar marcador 'performance' automaticamente para testes em tests/performance/
        elif "tests/performance/" in str(item.fspath):
            item.add_marker(pytest.mark.performance)

        # Adicionar marcador 'security' automaticamente para testes em tests/security/
        elif "tests/security/" in str(item.fspath):
            item.add_marker(pytest.mark.security)

        # Adicionar marcador 'smoke' automaticamente para testes em tests/smoke/
        elif "tests/smoke/" in str(item.fspath):
            item.add_marker(pytest.mark.smoke)


def pytest_configure(config):
    """Configurar pytest com marcadores customizados"""
    config.addinivalue_line("markers", "unit: Testes unitários")
    config.addinivalue_line("markers", "integration: Testes de integração")
    config.addinivalue_line("markers", "e2e: Testes end-to-end")
    config.addinivalue_line("markers", "performance: Testes de performance")
    config.addinivalue_line("markers", "security: Testes de segurança")
    config.addinivalue_line("markers", "slow: Testes que demoram mais")
    config.addinivalue_line(
        "markers", "smoke: Testes de fumaça para saúde básica da aplicação"
    )
    config.addinivalue_line("markers", "skip_ci: Testes para pular em ambientes de CI")
    config.addinivalue_line(
        "markers", "monitoring: Testes relacionados ao monitoramento do sistema"
    )
    config.addinivalue_line(
        "markers", "alerts: Testes relacionados ao sistema de alertas"
    )
    config.addinivalue_line(
        "markers", "recovery: Testes relacionados à recuperação de falhas"
    )
    config.addinivalue_line(
        "markers", "timeout: Testes com configuração de timeout específica"
    )
    config.addinivalue_line("markers", "bash: Testes relacionados a scripts bash")
    config.addinivalue_line("markers", "installation: Testes de instalação")
    config.addinivalue_line("markers", "deployment: Testes de deployment")
    config.addinivalue_line("markers", "model: Testes relacionados a modelos")
    config.addinivalue_line("markers", "api: Testes de API")
    config.addinivalue_line("markers", "ui: Testes de interface de usuário")
    config.addinivalue_line("markers", "database: Testes de banco de dados")
    config.addinivalue_line("markers", "network: Testes de rede")
    config.addinivalue_line("markers", "file: Testes de operações de arquivo")
    config.addinivalue_line("markers", "config: Testes de configuração")
    config.addinivalue_line("markers", "auth: Testes de autenticação")
    config.addinivalue_line("markers", "session: Testes de sessão")
    config.addinivalue_line("markers", "access: Testes de controle de acesso")
    config.addinivalue_line(
        "markers", "input_validation: Testes de validação de entrada"
    )
    config.addinivalue_line(
        "markers", "command_injection: Testes de proteção contra injeção de comandos"
    )
    config.addinivalue_line("markers", "data_validation: Testes de validação de dados")
    config.addinivalue_line("markers", "cluster: Testes relacionados ao cluster")
    config.addinivalue_line("markers", "dask: Testes relacionados ao Dask")
    config.addinivalue_line("markers", "rstudio: Testes relacionados ao RStudio")
    config.addinivalue_line("markers", "demo: Testes de demonstração")
    config.addinivalue_line("markers", "benchmark: Testes de benchmark")
    config.addinivalue_line("markers", "caching: Testes de cache")
    config.addinivalue_line("markers", "memory: Testes de memória")
    config.addinivalue_line("markers", "io: Testes de I/O")
    config.addinivalue_line("markers", "concurrent: Testes de operações concorrentes")
    config.addinivalue_line("markers", "scalability: Testes de escalabilidade")
    config.addinivalue_line("markers", "fault_tolerance: Testes de tolerância a falhas")
    config.addinivalue_line(
        "markers", "data_transfer: Testes de transferência de dados"
    )
    config.addinivalue_line("markers", "disk: Testes de disco")
    config.addinivalue_line("markers", "webui: Testes de interface web")
    config.addinivalue_line("markers", "auto_discover: Testes de descoberta automática")
    config.addinivalue_line(
        "markers", "cache_performance: Testes de performance de cache"
    )
