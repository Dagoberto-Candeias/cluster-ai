import torch
import torchvision
import torchaudio


def test_pytorch_installation():
    print("PyTorch version:", torch.__version__)
    print("Torchvision version:", torchvision.__version__)
    print("Torchaudio version:", torchaudio.__version__)


if __name__ == "__main__":
    test_pytorch_installation()
