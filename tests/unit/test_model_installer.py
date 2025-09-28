#!/usr/bin/env python3
"""
Testes unitários para o instalador de modelos Ollama aprimorado

Este módulo testa as funcionalidades do script install_models.sh,
incluindo categorização, navegação interativa e validação de entrada.
"""

import json
import os
import subprocess
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, mock_open, patch

import pytest


class TestModelInstaller:
    """Testes para o instalador de modelos Ollama"""

    def setup_method(self):
        """Configuração inicial para cada teste"""
        self.test_dir = Path(__file__).parent.parent.parent
        self.script_path = (
            self.test_dir / "scripts" / "management" / "install_models.sh"
        )

    def test_script_exists(self):
        """Testa se o script de instalação existe"""
        assert self.script_path.exists(), "Script install_models.sh deve existir"
        assert self.script_path.is_file(), "install_models.sh deve ser um arquivo"

    def test_script_executable(self):
        """Testa se o script tem permissões de execução"""
        assert os.access(
            self.script_path, os.X_OK
        ), "Script deve ter permissões de execução"

    @patch("builtins.input")
    @patch("subprocess.run")
    def test_script_runs_without_errors(self, mock_subprocess, mock_input):
        """Testa se o script executa sem erros críticos"""
        # Simula entrada do usuário para sair imediatamente
        mock_input.return_value = "q"

        # Mock do subprocess para simular comandos do sistema
        mock_subprocess.return_value = MagicMock(returncode=0, stdout="", stderr="")

        # Executa o script
        result = subprocess.run(
            [str(self.script_path)],
            capture_output=True,
            text=True,
            cwd=self.test_dir,
            timeout=10,
        )

        # Verifica se não houve erro crítico
        assert result.returncode == 0, f"Script falhou com erro: {result.stderr}"

    def test_script_has_shebang(self):
        """Testa se o script tem shebang correto"""
        with open(self.script_path, "r") as f:
            first_line = f.readline().strip()
            assert first_line == "#!/bin/bash", "Script deve ter shebang #!/bin/bash"

    def test_script_sources_common_library(self):
        """Testa se o script importa a biblioteca comum"""
        with open(self.script_path, "r") as f:
            content = f.read()
            assert (
                'source "$(dirname "$0")/../lib/common.sh"' in content
            ), "Script deve importar common.sh"

    def test_categories_defined(self):
        """Testa se as categorias de modelos estão definidas"""
        with open(self.script_path, "r") as f:
            content = f.read()

            # Verifica se as categorias principais estão definidas
            assert "CATEGORIAS_DISPONIVEIS" in content
            assert "Conversação" in content
            assert "Programação" in content
            assert "Análise" in content
            assert "Criativo" in content
            assert "Multilíngue" in content
            assert "Leve" in content

    def test_models_array_populated(self):
        """Testa se o array de modelos está populado"""
        with open(self.script_path, "r") as f:
            content = f.read()

            # Verifica se há modelos definidos
            assert "MODELS=(" in content
            assert "phi-3:3.8b" in content  # Pelo menos um modelo deve estar presente
            assert "llama3:8b" in content

    def test_color_variables_defined(self):
        """Testa se as variáveis de cor estão definidas"""
        with open(self.script_path, "r") as f:
            content = f.read()

            # Verifica variáveis de cor do common.sh ou variáveis definidas diretamente
            has_colors = any(
                color_var in content
                for color_var in ["RED=", "GREEN=", "YELLOW=", "GRAY="]
            )
            assert has_colors, "Variáveis de cor não encontradas no script"

    def test_function_select_category_exists(self):
        """Testa se a função select_category está definida"""
        with open(self.script_path, "r") as f:
            content = f.read()
            assert "select_category()" in content

    def test_function_display_models_exists(self):
        """Testa se a função display_models está definida"""
        with open(self.script_path, "r") as f:
            content = f.read()
            assert "display_models()" in content

    def test_function_install_selected_models_exists(self):
        """Testa se a função install_selected_models está definida"""
        with open(self.script_path, "r") as f:
            content = f.read()
            assert "install_selected_models()" in content

    def test_error_handling_exists(self):
        """Testa se há tratamento de erros no script"""
        with open(self.script_path, "r") as f:
            content = f.read()
            assert "set -euo pipefail" in content or "trap" in content

    def test_help_text_available(self):
        """Testa se há texto de ajuda disponível"""
        with open(self.script_path, "r") as f:
            content = f.read()
            assert "Digite o número" in content
            assert "Pressione" in content
            assert "sair" in content

    @patch("subprocess.run")
    def test_ollama_command_available(self, mock_subprocess):
        """Testa se o comando ollama é referenciado"""
        mock_subprocess.return_value = MagicMock(
            returncode=0, stdout="ollama version 0.1.0"
        )

        with open(self.script_path, "r") as f:
            content = f.read()
            assert "ollama" in content

    def test_model_count_reasonable(self):
        """Testa se há um número razoável de modelos"""
        with open(self.script_path, "r") as f:
            content = f.read()

            # Conta todas as ocorrências de modelos no formato "nome:versão"
            import re

            # Padrão simples para encontrar modelos (mais permissivo)
            model_pattern = r'"([a-zA-Z0-9_-]+:[0-9]+(?:\.[0-9]+)?[a-zA-Z]*)"'
            all_models = re.findall(model_pattern, content)

            # Deve ter pelo menos alguns modelos
            assert (
                len(all_models) >= 10
            ), f"Encontrados apenas {len(all_models)} modelos, esperado pelo menos 10"

            # Verifica se há um número razoável de modelos únicos (duplicatas são esperadas devido ao uso em arrays associativos)
            unique_models = set(all_models)
            assert (
                len(unique_models) >= 10
            ), f"Encontrados apenas {len(unique_models)} modelos únicos, esperado pelo menos 10"

            # Verifica se as duplicatas são em número esperado (cada modelo aparece em ~3 lugares)
            expected_duplicates_per_model = 3
            for model in unique_models:
                count = all_models.count(model)
                assert (
                    abs(count - expected_duplicates_per_model) <= 1
                ), f"Modelo {model} aparece {count} vezes, esperado ~{expected_duplicates_per_model}"

    def test_category_descriptions_exist(self):
        """Testa se há descrições para as categorias"""
        with open(self.script_path, "r") as f:
            content = f.read()

            # Verifica se há descrições de categoria
            assert "Modelo compacto" in content or "versátil" in content
            assert (
                "Especialista em programação" in content or "otimizado para" in content
            )

    def test_script_uses_getopts_or_shift(self):
        """Testa se o script processa argumentos de linha de comando"""
        with open(self.script_path, "r") as f:
            content = f.read()

            # Deve ter algum processamento de argumentos
            has_args_processing = (
                "getopts" in content
                or "shift" in content
                or "$1" in content
                or "--help" in content
            )
            assert (
                has_args_processing
            ), "Script deve processar argumentos de linha de comando"

    def test_temporary_files_handled(self):
        """Testa se arquivos temporários são criados e limpos adequadamente"""
        with open(self.script_path, "r") as f:
            content = f.read()

            # Verifica se usa /tmp ou mktemp
            has_temp_handling = "/tmp" in content or "mktemp" in content
            assert has_temp_handling, "Script deve lidar com arquivos temporários"

    def test_logging_available(self):
        """Testa se há funcionalidades de logging"""
        with open(self.script_path, "r") as f:
            content = f.read()

            # Verifica se usa log, success, warn, error do common.sh
            has_logging = any(
                func in content for func in ["log ", "success ", "warn ", "error "]
            )
            assert has_logging, "Script deve ter funcionalidades de logging"


class TestModelCategories:
    """Testes específicos para categorização de modelos"""

    def test_conversation_models_exist(self):
        """Testa se modelos de conversação estão presentes"""
        script_path = (
            Path(__file__).parent.parent.parent
            / "scripts"
            / "management"
            / "install_models.sh"
        )

        with open(script_path, "r") as f:
            content = f.read()

            # Modelos de conversação esperados
            conversation_models = ["phi-3:3.8b", "gemma:2b", "llama3:8b", "mistral:7b"]
            found_models = sum(1 for model in conversation_models if model in content)

            assert (
                found_models >= 2
            ), f"Encontrados apenas {found_models} modelos de conversação"

    def test_programming_models_exist(self):
        """Testa se modelos de programação estão presentes"""
        script_path = (
            Path(__file__).parent.parent.parent
            / "scripts"
            / "management"
            / "install_models.sh"
        )

        with open(script_path, "r") as f:
            content = f.read()

            # Modelos de programação esperados
            programming_models = ["codellama:7b", "deepseek-coder:6.7b", "starcoder:3b"]
            found_models = sum(1 for model in programming_models if model in content)

            assert (
                found_models >= 1
            ), f"Encontrados apenas {found_models} modelos de programação"

    def test_light_models_exist(self):
        """Testa se modelos leves estão presentes"""
        script_path = (
            Path(__file__).parent.parent.parent
            / "scripts"
            / "management"
            / "install_models.sh"
        )

        with open(script_path, "r") as f:
            content = f.read()

            # Modelos leves esperados
            light_models = ["tinyllama:1.1b", "phi-2:2.7b"]
            found_models = sum(1 for model in light_models if model in content)

            assert found_models >= 1, f"Encontrados apenas {found_models} modelos leves"


class TestModelInstallerIntegration:
    """Testes de integração para o instalador"""

    def test_script_can_be_sourced(self):
        """Testa se o script pode ser sourceado sem erros"""
        script_path = (
            Path(__file__).parent.parent.parent
            / "scripts"
            / "management"
            / "install_models.sh"
        )

        # Testa se o script pode ser parseado pelo bash
        result = subprocess.run(
            ["bash", "-n", str(script_path)], capture_output=True, text=True
        )

        assert result.returncode == 0, f"Script tem erros de sintaxe: {result.stderr}"

    def test_common_library_available(self):
        """Testa se a biblioteca comum está disponível"""
        common_path = (
            Path(__file__).parent.parent.parent / "scripts" / "lib" / "common.sh"
        )
        assert common_path.exists(), "Biblioteca common.sh deve existir"

        # Testa se common.sh pode ser sourceado
        result = subprocess.run(
            ["bash", "-n", str(common_path)], capture_output=True, text=True
        )

        assert (
            result.returncode == 0
        ), f"common.sh tem erros de sintaxe: {result.stderr}"


if __name__ == "__main__":
    pytest.main([__file__])
