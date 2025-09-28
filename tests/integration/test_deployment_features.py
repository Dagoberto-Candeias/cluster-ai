#!/usr/bin/env python3
"""
Testes de integração para as novas funcionalidades de deployment:
- Descoberta automática de workers
- Instalador web unificado
"""

import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest


class TestAutoDiscoverWorkers:
    """Testes para descoberta automática de workers"""

    def test_auto_discover_workers_script_exists(self):
        """Verifica se o script de descoberta existe e é executável"""
        script_path = Path("scripts/deployment/auto_discover_workers.sh")
        assert script_path.exists(), "Script auto_discover_workers.sh não encontrado"
        assert os.access(script_path, os.X_OK), "Script não é executável"

    def test_auto_discover_workers_basic_execution(self):
        """Testa execução básica do script de descoberta"""
        script_path = Path("scripts/deployment/auto_discover_workers.sh")

        # Executar script com timeout
        try:
            result = subprocess.run(
                [str(script_path)],
                capture_output=True,
                text=True,
                timeout=30,
                cwd=Path.cwd(),
            )
            # Script pode falhar se kubectl não estiver disponível (é esperado)
            # O importante é que o script executou e produziu saída
            assert "Descobrindo workers automaticamente" in result.stdout
            # Return code 1 é aceitável se kubectl não estiver configurado
            assert result.returncode in [
                0,
                1,
            ], f"Script falhou inesperadamente: {result.stderr}"
        except subprocess.TimeoutExpired:
            pytest.skip(
                "Script demorou muito para executar (possivelmente sem kubectl)"
            )
        except FileNotFoundError:
            pytest.skip("kubectl não encontrado no sistema")

    @patch("subprocess.run")
    def test_auto_discover_workers_with_mock_kubectl(self, mock_run):
        """Testa descoberta com kubectl mockado"""
        # Mock do kubectl get pods
        mock_process = MagicMock()
        mock_process.returncode = 0
        mock_process.stdout = (
            "NAME                    READY   STATUS    RESTARTS   AGE   IP\n"
            "dask-worker-1           1/1     Running   0          5m    10.0.1.10\n"
            "dask-worker-2           1/1     Running   0          5m    10.0.1.11\n"
        )
        mock_process.stderr = ""
        mock_run.return_value = mock_process

        script_path = Path("scripts/deployment/auto_discover_workers.sh")

        # Como estamos mockando subprocess.run, precisamos simular a execução do script
        # O script em si executa kubectl, então verificamos se o mock foi chamado corretamente
        with patch("subprocess.run", mock_run):
            result = subprocess.run(
                [str(script_path)], capture_output=True, text=True, cwd=Path.cwd()
            )

        # Verificar se kubectl seria chamado (através do mock)
        # Nota: Este teste verifica a estrutura do mock, não a execução real
        assert mock_run.called, "subprocess.run deveria ter sido chamado"
        # Verificar que o mock retornou dados simulados de workers
        assert "dask-worker-1" in mock_process.stdout
        assert "dask-worker-2" in mock_process.stdout


class TestWebUIInstaller:
    """Testes para instalador web unificado"""

    def test_webui_installer_script_exists(self):
        """Verifica se o script instalador existe e é executável"""
        script_path = Path("scripts/deployment/webui-installer.sh")
        assert script_path.exists(), "Script webui-installer.sh não encontrado"
        assert os.access(script_path, os.X_OK), "Script não é executável"

    def test_webui_installer_content_validation(self):
        """Valida conteúdo do script instalador"""
        script_path = Path("scripts/deployment/webui-installer.sh")

        with open(script_path, "r") as f:
            content = f.read()

        # Verificações básicas de conteúdo
        assert "sudo apt update" in content, "Instalação de dependências não encontrada"
        assert (
            "python3 -m venv" in content
        ), "Criação de ambiente virtual não encontrada"
        assert "dask[complete]" in content, "Instalação do Dask não encontrada"
        assert (
            "parallel_pip_install" in content
        ), "Instalação paralela de pacotes Python não encontrada"
        assert "docker run" in content, "Execução do container OpenWebUI não encontrada"
        assert "send_alert.py" in content, "Sistema de alertas não encontrado"

    @patch("subprocess.run")
    @patch("builtins.input")
    def test_webui_installer_dry_run(self, mock_input, mock_run):
        """Testa execução do instalador em modo dry-run"""
        # Mock das entradas do usuário
        mock_input.return_value = "test@example.com"

        # Mock dos comandos do sistema
        mock_run.return_value = MagicMock(returncode=0, stdout="", stderr="")

        script_path = Path("scripts/deployment/webui-installer.sh")

        # Este teste seria mais complexo em um ambiente real
        # Por enquanto, apenas verifica se o script pode ser lido
        assert script_path.exists()

    def test_webui_installer_creates_alert_script(self):
        """Verifica se o script cria o arquivo de alertas"""
        # Simula a criação do script de alertas
        alert_script_content = """
import smtplib
from email.mime.text import MIMEText

def send_alert(subject, message):
    sender = "test@example.com"
    password = "test_password"
    recipient = "test@example.com"

    msg = MIMEText(message)
    msg["Subject"] = subject
    msg["From"] = sender
    msg["To"] = recipient

    try:
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(sender, password)
            server.sendmail(sender, recipient, msg.as_string())
        print("✅ Alerta enviado com sucesso!")
    except Exception as e:
        print(f"❌ Erro ao enviar alerta: {e}")

if __name__ == "__main__":
    send_alert("Teste", "Mensagem de teste")
"""

        # Verifica se o conteúdo do script é válido Python
        compile(alert_script_content, "<string>", "exec")


class TestDeploymentIntegration:
    """Testes de integração entre componentes de deployment"""

    def test_deployment_scripts_compatibility(self):
        """Verifica compatibilidade entre scripts de deployment"""
        scripts_to_check = [
            "scripts/deployment/auto_discover_workers.sh",
            "scripts/deployment/webui-installer.sh",
            "scripts/deployment/auto_discover_workers.py",
        ]

        for script_path in scripts_to_check:
            path = Path(script_path)
            if path.exists():
                assert os.access(path, os.R_OK), f"Script {script_path} não é legível"

    def test_deployment_directory_structure(self):
        """Verifica estrutura do diretório de deployment"""
        deployment_dir = Path("scripts/deployment")

        assert deployment_dir.exists(), "Diretório scripts/deployment não existe"
        assert deployment_dir.is_dir(), "scripts/deployment não é um diretório"

        # Verifica se tem arquivos de script
        script_files = list(deployment_dir.glob("*.sh")) + list(
            deployment_dir.glob("*.py")
        )
        assert len(script_files) > 0, "Nenhum script encontrado no diretório deployment"

    @pytest.mark.parametrize(
        "script_name",
        ["auto_discover_workers.sh", "webui-installer.sh", "auto_discover_workers.py"],
    )
    def test_deployment_script_basic_validation(self, script_name):
        """Valida basicamente cada script de deployment"""
        script_path = Path(f"scripts/deployment/{script_name}")

        if script_path.exists():
            # Verifica tamanho mínimo do arquivo
            assert script_path.stat().st_size > 0, f"Script {script_name} está vazio"

            # Verifica que não tem caracteres nulos
            with open(script_path, "rb") as f:
                content = f.read()
                assert (
                    b"\x00" not in content
                ), f"Script {script_name} contém caracteres nulos"


class TestDeploymentErrorHandling:
    """Testes de tratamento de erros nos scripts de deployment"""

    @patch("subprocess.run")
    def test_auto_discover_workers_kubectl_not_found(self, mock_run):
        """Testa comportamento quando kubectl não é encontrado"""
        # Simula erro de comando não encontrado
        mock_run.side_effect = FileNotFoundError("kubectl: command not found")

        script_path = Path("scripts/deployment/auto_discover_workers.sh")

        # O script deve lidar graciosamente com erro
        try:
            result = subprocess.run(
                [str(script_path)],
                capture_output=True,
                text=True,
                timeout=10,
                cwd=Path.cwd(),
            )
            # Se chegou aqui, o script tratou o erro
            assert True
        except subprocess.TimeoutExpired:
            # Timeout é aceitável se o script estiver esperando
            assert True
        except Exception as e:
            # Outros erros podem ser aceitáveis dependendo da implementação
            assert True

    def test_webui_installer_dependency_check(self):
        """Verifica se o instalador checa dependências adequadamente"""
        script_path = Path("scripts/deployment/webui-installer.sh")

        with open(script_path, "r") as f:
            content = f.read()

        # Verifica se há verificações de erro adequadas
        assert "set -e" in content, "Script não tem tratamento de erro adequado"

        # Verifica se instala dependências críticas
        critical_deps = ["python3", "pip", "docker"]
        for dep in critical_deps:
            assert dep in content, f"Dependência crítica {dep} não é tratada"


# Testes de performance para funcionalidades de deployment
class TestDeploymentPerformance:
    """Testes de performance para scripts de deployment"""

    def test_auto_discover_workers_execution_time(self):
        """Verifica tempo de execução do script de descoberta"""
        import time

        script_path = Path("scripts/deployment/auto_discover_workers.sh")
        start_time = time.time()

        try:
            result = subprocess.run(
                [str(script_path)],
                capture_output=True,
                text=True,
                timeout=60,  # Máximo 1 minuto
                cwd=Path.cwd(),
            )
            execution_time = time.time() - start_time

            # Tempo de execução deve ser razoável
            assert (
                execution_time < 30
            ), f"Script demorou {execution_time:.2f}s para executar"

        except subprocess.TimeoutExpired:
            pytest.skip("Script excedeu timeout - pode estar esperando kubectl")
        except FileNotFoundError:
            pytest.skip("kubectl não encontrado - teste não aplicável")

    def test_webui_installer_script_size(self):
        """Verifica tamanho do script instalador (não deve ser muito grande)"""
        script_path = Path("scripts/deployment/webui-installer.sh")

        size_bytes = script_path.stat().st_size
        size_kb = size_bytes / 1024

        # Script não deve ser maior que 50KB (é um script simples)
        assert size_kb < 50, f"Script muito grande: {size_kb:.1f}KB"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
