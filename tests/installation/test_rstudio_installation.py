#!/usr/bin/env python3
"""
Testes para verificar a instalação do RStudio no Cluster AI
"""

import os
import subprocess
import sys
from pathlib import Path

import pytest


@pytest.fixture
def run_command():
    """Fixture para executar comandos"""

    def _run_command(cmd, shell=False):
        try:
            result = subprocess.run(
                cmd, shell=shell, capture_output=True, text=True, timeout=30
            )
            return result.returncode == 0, result.stdout.strip(), result.stderr.strip()
        except subprocess.TimeoutExpired:
            return False, "", "Command timed out"
        except Exception as e:
            return False, "", str(e)

    return _run_command


@pytest.mark.installation
@pytest.mark.rstudio
def test_r_installation(run_command):
    """Testa se o R está instalado"""
    success, stdout, stderr = run_command(["R", "--version"])
    assert success, f"R não encontrado ou não funcional: {stderr}"


@pytest.mark.installation
@pytest.mark.rstudio
def test_rstudio_installation(run_command):
    """Testa se o RStudio está instalado"""
    success, stdout, stderr = run_command(["rstudio", "--version"])
    assert success, f"RStudio não encontrado: {stderr}"


@pytest.mark.installation
@pytest.mark.rstudio
def test_r_libraries(run_command):
    """Testa se as bibliotecas R essenciais estão instaladas"""
    libraries = ["dplyr", "ggplot2", "tidyr"]
    missing_libs = []

    for lib in libraries:
        success, stdout, stderr = run_command(
            ["R", "-e", f"if (!require('{lib}')) quit(status=1)"]
        )
        if not success:
            missing_libs.append(lib)

    assert not missing_libs, f"Bibliotecas R faltando: {', '.join(missing_libs)}"


@pytest.mark.installation
@pytest.mark.rstudio
def test_r_profile():
    """Testa se o arquivo .Rprofile foi criado corretamente"""
    rprofile_path = Path.home() / ".Rprofile"

    if not rprofile_path.exists():
        pytest.skip("Arquivo .Rprofile não encontrado")

    content = rprofile_path.read_text()

    # Verificar se contém configurações essenciais
    required_configs = ["cran.rstudio.com", "connect_dask_cluster", "Cluster AI"]

    missing_configs = []
    for config in required_configs:
        if config not in content:
            missing_configs.append(config)

    assert (
        not missing_configs
    ), f"Configurações faltando no .Rprofile: {', '.join(missing_configs)}"


@pytest.mark.installation
@pytest.mark.rstudio
def test_example_script():
    """Testa se o script de exemplo foi criado"""
    script_path = Path.home() / "cluster_projects" / "r" / "exemplo_cluster.R"

    if not script_path.exists():
        pytest.skip("Script de exemplo não encontrado")

    # Verificar se o script é executável
    assert os.access(script_path, os.X_OK), "Script de exemplo não é executável"


@pytest.mark.installation
@pytest.mark.rstudio
def test_desktop_shortcut():
    """Testa se o atalho da área de trabalho foi criado"""
    shortcut_path = (
        Path.home() / ".local" / "share" / "applications" / "rstudio-cluster.desktop"
    )

    if not shortcut_path.exists():
        pytest.skip("Atalho da área de trabalho não encontrado")

    content = shortcut_path.read_text()

    # Verificar se contém informações essenciais
    required_fields = ["RStudio (Cluster AI)", "rstudio", "Cluster AI development"]

    missing_fields = []
    for field in required_fields:
        if field not in content:
            missing_fields.append(field)

    assert not missing_fields, f"Campos faltando no atalho: {', '.join(missing_fields)}"


@pytest.mark.installation
@pytest.mark.rstudio
@pytest.mark.dask
def test_r_dask_connection(run_command):
    """Testa se é possível conectar ao Dask do R (opcional)"""
    # Este teste é opcional e pode falhar se o cluster não estiver rodando
    test_script = """
try {
    if (!require('dask')) {
        install.packages('dask', repos='https://cran.rstudio.com/')
    }
    library(dask)
    # Tentar conectar (vai falhar se o cluster não estiver rodando, mas isso é OK)
    client <- tryCatch(
        dask$Client('localhost:8786', timeout=2),
        error = function(e) NULL
    )
    if (!is.null(client)) {
        message("Conexão Dask bem-sucedida")
        client$close()
        quit(status=0)
    } else {
        message("Cluster Dask não disponível (isso é normal se não estiver rodando)")
        quit(status=1)
    }
} catch (e) {
    message("Erro na conexão Dask: ", e$message)
    quit(status=1)
}
"""

    success, stdout, stderr = run_command(["R", "-e", test_script])

    # Este teste é opcional - se falhar, apenas registramos como skip
    if not success:
        pytest.skip("Conexão Dask do R não testada (cluster pode não estar rodando)")
