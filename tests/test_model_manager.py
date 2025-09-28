#!/usr/bin/env python3
# =============================================================================
# Testes para Model Manager - Cluster AI
# =============================================================================
# Testa as funcionalidades de gerenciamento de modelos Ollama
#
# Autor: Cluster AI Team
# Versão: 1.0.0
# =============================================================================

import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import MagicMock, patch

# Adicionar o diretório raiz ao path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))


class TestModelManager(unittest.TestCase):
    """Testes para o gerenciador de modelos Ollama"""

    def setUp(self):
        """Configurar ambiente de teste"""
        self.project_root = os.path.join(os.path.dirname(__file__), "..")
        self.script_path = os.path.join(
            self.project_root, "scripts", "ollama", "model_manager.sh"
        )

        # Verificar se o script existe
        self.assertTrue(
            os.path.exists(self.script_path), "Script model_manager.sh não encontrado"
        )

        # Criar diretório temporário para testes
        self.temp_dir = tempfile.mkdtemp()
        self.log_dir = os.path.join(self.temp_dir, "logs")
        os.makedirs(self.log_dir, exist_ok=True)

    def tearDown(self):
        """Limpar ambiente de teste"""
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def run_script(self, args):
        """Executar script com argumentos"""
        cmd = ["bash", self.script_path] + args
        try:
            result = subprocess.run(
                cmd, cwd=self.project_root, capture_output=True, text=True, timeout=30
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            self.fail("Script timeout")

    def test_script_exists_and_executable(self):
        """Testar se o script existe e é executável"""
        self.assertTrue(os.path.exists(self.script_path))
        self.assertTrue(os.access(self.script_path, os.X_OK))

    def test_model_name_validation(self):
        """Testar validação de nomes de modelo"""
        valid_names = [
            "llama3:8b",
            "mistral-7b-instruct-v0.2",
            "codellama:13b",
            "gemma:2b",
        ]

        for name in valid_names:
            with self.subTest(model_name=name):
                result = subprocess.run(
                    [
                        "bash",
                        "-c",
                        f'source scripts/utils/common_functions.sh; validate_model_name "{name}"',
                    ],
                    cwd=self.project_root,
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(
                    result.returncode, 0, f"Model name '{name}' should be valid"
                )

    def test_model_name_validation_invalid(self):
        """Testar validação de nomes de modelo inválidos"""
        invalid_names = [
            "",
            "model@name",
            "model with spaces",
            "model;rm -rf /",
            "a" * 101,
        ]

        for name in invalid_names:
            with self.subTest(model_name=name):
                result = subprocess.run(
                    [
                        "bash",
                        "-c",
                        f'source scripts/utils/common_functions.sh; validate_model_name "{name}"',
                    ],
                    cwd=self.project_root,
                    capture_output=True,
                    text=True,
                )
                self.assertNotEqual(
                    result.returncode, 0, f"Model name '{name}' should be invalid"
                )

    def test_worker_id_validation(self):
        """Testar validação de IDs de worker"""
        valid_ids = ["worker-01", "worker_02", "worker123", "dask-node-1"]

        for worker_id in valid_ids:
            with self.subTest(worker_id=worker_id):
                result = subprocess.run(
                    [
                        "bash",
                        "-c",
                        f'source scripts/utils/common_functions.sh; validate_worker_id "{worker_id}"',
                    ],
                    cwd=self.project_root,
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(
                    result.returncode, 0, f"Worker ID '{worker_id}' should be valid"
                )

    def test_worker_id_validation_invalid(self):
        """Testar validação de IDs de worker inválidos"""
        invalid_ids = [
            "",
            "worker@01",
            "worker with spaces",
            "worker;rm -rf /",
            "a" * 51,
        ]

        for worker_id in invalid_ids:
            with self.subTest(worker_id=worker_id):
                result = subprocess.run(
                    [
                        "bash",
                        "-c",
                        f'source scripts/utils/common_functions.sh; validate_worker_id "{worker_id}"',
                    ],
                    cwd=self.project_root,
                    capture_output=True,
                    text=True,
                )
                self.assertNotEqual(
                    result.returncode, 0, f"Worker ID '{worker_id}' should be invalid"
                )

    def test_secure_password_generation(self):
        """Testar geração de senha segura"""
        result = subprocess.run(
            [
                "bash",
                "-c",
                "source scripts/utils/common_functions.sh; generate_secure_password 16",
            ],
            cwd=self.project_root,
            capture_output=True,
            text=True,
        )

        self.assertEqual(result.returncode, 0)
        password = result.stdout.strip()
        self.assertEqual(len(password), 16)

        has_upper = any(c.isupper() for c in password)
        has_lower = any(c.islower() for c in password)
        has_digit = any(c.isdigit() for c in password)
        has_special = any(c in "!@#$%^&*" for c in password)
        self.assertTrue(
            has_upper or has_lower or has_digit or has_special,
            "Password should contain varied characters",
        )


if __name__ == "__main__":
    unittest.main()
