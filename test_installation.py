#!/usr/bin/env python3
"""
Teste de Instalação do PyTorch - Cluster AI

Este script verifica se o PyTorch e suas bibliotecas relacionadas
estão instalados corretamente no ambiente.
"""

import torch
import torchvision
import torchaudio


def test_pytorch_installation():
    """
    Testa a instalação do PyTorch e bibliotecas relacionadas.

    Verifica as versões instaladas do PyTorch, Torchvision e Torchaudio,
    e testa funcionalidades básicas para garantir que a instalação está
    funcionando corretamente.
    """
    print("🔍 Verificando instalação do PyTorch...")

    # Exibir versões
    print(f"✅ PyTorch version: {torch.__version__}")
    print(f"✅ Torchvision version: {torchvision.__version__}")
    print(f"✅ Torchaudio version: {torchaudio.__version__}")

    # Teste básico de funcionalidade
    try:
        # Criar tensor simples
        x = torch.tensor([1.0, 2.0, 3.0])
        print(f"✅ Tensor básico criado: {x}")

        # Verificar se CUDA está disponível
        if torch.cuda.is_available():
            print(f"✅ CUDA disponível: {torch.cuda.get_device_name(0)}")
        else:
            print("ℹ️  CUDA não disponível (usando CPU)")

        print("🎉 Instalação do PyTorch verificada com sucesso!")

    except Exception as e:
        print(f"❌ Erro durante teste: {e}")
        return False

    return True


if __name__ == "__main__":
    success = test_pytorch_installation()
    exit(0 if success else 1)
