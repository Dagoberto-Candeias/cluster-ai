"""
Testes unitários para test_installation.py

Este módulo contém testes para verificar a instalação do PyTorch e bibliotecas relacionadas.
"""

import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

# Adicionar diretório raiz ao path
PROJECT_ROOT = Path(__file__).parent.parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

try:
    from test_installation import test_pytorch_installation
except ImportError:
    pytest.skip(
        "Não foi possível importar os módulos do projeto. Pulando testes unitários.",
        allow_module_level=True,
    )


class TestPyTorchInstallation:
    @patch("test_installation.torch")
    @patch("test_installation.torchvision")
    @patch("test_installation.torchaudio")
    def test_versions_and_basic_functionality(
        self, mock_torchaudio, mock_torchvision, mock_torch
    ):
        # Configurar versões
        mock_torch.__version__ = "1.12.0"
        mock_torchvision.__version__ = "0.13.0"
        mock_torchaudio.__version__ = "0.12.0"

        # Configurar CUDA disponível
        mock_torch.cuda.is_available.return_value = True
        mock_torch.cuda.get_device_name.return_value = "Mock GPU"

        # Configurar tensor
        mock_torch.tensor.return_value = "tensor"

        # Executar teste
        result = test_pytorch_installation()

        # Verificar resultado
        assert result is True
        mock_torch.tensor.assert_called_once_with([1.0, 2.0, 3.0])
        mock_torch.cuda.is_available.assert_called_once()
        mock_torch.cuda.get_device_name.assert_called_once_with(0)

    @patch("test_installation.torch")
    def test_exception_handling(self, mock_torch):
        # Configurar exceção ao criar tensor
        mock_torch.tensor.side_effect = Exception("Erro")

        # Executar teste
        result = test_pytorch_installation()

        # Verificar resultado
        assert result is False
