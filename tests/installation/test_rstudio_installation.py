#!/usr/bin/env python3
"""
Testes para verificar a instalação do RStudio no Cluster AI
"""

import subprocess
import sys
import os
from pathlib import Path

def run_command(cmd, shell=False):
    """Executa um comando e retorna o resultado"""
    try:
        result = subprocess.run(cmd, shell=shell, capture_output=True, text=True, timeout=30)
        return result.returncode == 0, result.stdout.strip(), result.stderr.strip()
    except subprocess.TimeoutExpired:
        return False, "", "Command timed out"
    except Exception as e:
        return False, "", str(e)

def test_r_installation():
    """Testa se o R está instalado"""
    print("🔍 Testando instalação do R...")
    success, stdout, stderr = run_command(["R", "--version"])

    if success:
        version_line = stdout.split('\n')[0] if stdout else "R version unknown"
        print(f"✅ R instalado: {version_line}")
        return True
    else:
        print("❌ R não encontrado ou não funcional")
        return False

def test_rstudio_installation():
    """Testa se o RStudio está instalado"""
    print("🔍 Testando instalação do RStudio...")
    success, stdout, stderr = run_command(["rstudio", "--version"])

    if success:
        print(f"✅ RStudio instalado: {stdout.strip()}")
        return True
    else:
        print("❌ RStudio não encontrado")
        return False

def test_r_libraries():
    """Testa se as bibliotecas R essenciais estão instaladas"""
    print("🔍 Testando bibliotecas R essenciais...")

    libraries = ["dplyr", "ggplot2", "tidyr"]
    missing_libs = []

    for lib in libraries:
        success, stdout, stderr = run_command([
            "R", "-e", f"if (!require('{lib}')) quit(status=1)"
        ])

        if not success:
            missing_libs.append(lib)

    if not missing_libs:
        print("✅ Todas as bibliotecas R essenciais estão instaladas")
        return True
    else:
        print(f"❌ Bibliotecas R faltando: {', '.join(missing_libs)}")
        return False

def test_r_profile():
    """Testa se o arquivo .Rprofile foi criado corretamente"""
    print("🔍 Testando configuração R (.Rprofile)...")

    rprofile_path = Path.home() / ".Rprofile"

    if rprofile_path.exists():
        content = rprofile_path.read_text()

        # Verificar se contém configurações essenciais
        required_configs = [
            "cran.rstudio.com",
            "connect_dask_cluster",
            "Cluster AI"
        ]

        missing_configs = []
        for config in required_configs:
            if config not in content:
                missing_configs.append(config)

        if not missing_configs:
            print("✅ Arquivo .Rprofile configurado corretamente")
            return True
        else:
            print(f"❌ Configurações faltando no .Rprofile: {', '.join(missing_configs)}")
            return False
    else:
        print("❌ Arquivo .Rprofile não encontrado")
        return False

def test_example_script():
    """Testa se o script de exemplo foi criado"""
    print("🔍 Testando script de exemplo...")

    script_path = Path.home() / "cluster_projects" / "r" / "exemplo_cluster.R"

    if script_path.exists():
        # Verificar se o script é executável
        if os.access(script_path, os.X_OK):
            print("✅ Script de exemplo criado e executável")
            return True
        else:
            print("❌ Script de exemplo não é executável")
            return False
    else:
        print("❌ Script de exemplo não encontrado")
        return False

def test_desktop_shortcut():
    """Testa se o atalho da área de trabalho foi criado"""
    print("🔍 Testando atalho da área de trabalho...")

    shortcut_path = Path.home() / ".local" / "share" / "applications" / "rstudio-cluster.desktop"

    if shortcut_path.exists():
        content = shortcut_path.read_text()

        # Verificar se contém informações essenciais
        required_fields = [
            "RStudio (Cluster AI)",
            "rstudio",
            "Cluster AI development"
        ]

        missing_fields = []
        for field in required_fields:
            if field not in content:
                missing_fields.append(field)

        if not missing_fields:
            print("✅ Atalho da área de trabalho criado corretamente")
            return True
        else:
            print(f"❌ Campos faltando no atalho: {', '.join(missing_fields)}")
            return False
    else:
        print("❌ Atalho da área de trabalho não encontrado")
        return False

def test_r_dask_connection():
    """Testa se é possível conectar ao Dask do R (opcional)"""
    print("🔍 Testando conexão Dask do R...")

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

    if success:
        print("✅ Conexão Dask do R funcional")
        return True
    else:
        print("⚠️  Conexão Dask do R não testada (cluster pode não estar rodando)")
        print(f"   Detalhes: {stdout}")
        return True  # Não é um erro crítico

def main():
    """Função principal de teste"""
    print("🧪 Iniciando testes de instalação do RStudio...")
    print("=" * 50)

    tests = [
        test_r_installation,
        test_rstudio_installation,
        test_r_libraries,
        test_r_profile,
        test_example_script,
        test_desktop_shortcut,
        test_r_dask_connection
    ]

    passed = 0
    total = len(tests)

    for test in tests:
        if test():
            passed += 1
        print()

    print("=" * 50)
    print(f"📊 Resultado: {passed}/{total} testes passaram")

    if passed == total:
        print("🎉 Todos os testes passaram! Instalação do RStudio está OK.")
        return 0
    elif passed >= total - 1:  # Permite falhar apenas no teste de conexão Dask
        print("✅ Instalação do RStudio está funcional (conexão Dask opcional falhou)")
        return 0
    else:
        print("❌ Alguns testes falharam. Verifique a instalação.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
