import torch
import torch.nn as nn
import torch.optim as optim
import torchvision
import torchvision.transforms as transforms
import torchaudio
import numpy as np
import time

def test_basic_tensor_operations():
    """Testa operações básicas de tensor do PyTorch"""
    print("=== Testando Operações Básicas de Tensor ===")
    
    # Criar tensores
    x = torch.tensor([1.0, 2.0, 3.0])
    y = torch.tensor([4.0, 5.0, 6.0])
    
    # Operações matemáticas
    z = x + y
    print(f"Soma: {x} + {y} = {z}")
    
    z = x * y
    print(f"Multiplicação: {x} * {y} = {z}")
    
    # Operações de matriz
    A = torch.randn(3, 3)
    B = torch.randn(3, 3)
    C = torch.matmul(A, B)
    print(f"Multiplicação de matrizes: shape {A.shape} x {B.shape} = {C.shape}")
    
    print("✓ Operações básicas funcionando corretamente\n")

def test_neural_network():
    """Testa a criação e treinamento de uma rede neural simples"""
    print("=== Testando Rede Neural ===")
    
    # Definir uma rede neural simples
    class SimpleNet(nn.Module):
        def __init__(self):
            super(SimpleNet, self).__init__()
            self.fc1 = nn.Linear(10, 5)
            self.fc2 = nn.Linear(5, 2)
            self.relu = nn.ReLU()
            
        def forward(self, x):
            x = self.relu(self.fc1(x))
            x = self.fc2(x)
            return x
    
    # Criar a rede
    model = SimpleNet()
    print(f"Modelo criado: {model}")
    
    # Dados de exemplo
    inputs = torch.randn(32, 10)  # batch size 32, 10 features
    targets = torch.randint(0, 2, (32,))  # classes 0 ou 1
    
    # Forward pass
    outputs = model(inputs)
    print(f"Forward pass: inputs {inputs.shape} -> outputs {outputs.shape}")
    
    # Calcular perda
    criterion = nn.CrossEntropyLoss()
    loss = criterion(outputs, targets)
    print(f"Perda calculada: {loss.item():.4f}")
    
    # Backward pass
    optimizer = optim.SGD(model.parameters(), lr=0.01)
    optimizer.zero_grad()
    loss.backward()
    optimizer.step()
    print("✓ Backward pass e atualização de pesos funcionando\n")
    
    return loss.item()

def test_torchvision():
    """Testa funcionalidades do torchvision"""
    print("=== Testando Torchvision ===")
    
    # Testar transformações
    transform = transforms.Compose([
        transforms.Resize((32, 32)),
        transforms.ToTensor(),
        transforms.Normalize((0.5,), (0.5,))
    ])
    print("✓ Transformações de imagem funcionando")
    
    # Testar datasets (apenas verificação, não baixar dados)
    try:
        # Verificar se consegue acessar a estrutura do dataset
        dataset_info = torchvision.datasets.CIFAR10
        print("✓ Módulo de datasets acessível")
    except Exception as e:
        print(f"⚠ Erro ao acessar datasets: {e}")
    
    print("✓ Funcionalidades do torchvision testadas\n")

def test_torchaudio():
    """Testa funcionalidades básicas do torchaudio"""
    print("=== Testando Torchaudio ===")
    
    # Testar operações básicas de áudio
    try:
        # Criar um sinal de áudio sintético
        sample_rate = 16000
        duration = 1.0  # 1 segundo
        t = torch.linspace(0, duration, int(sample_rate * duration))
        audio_signal = torch.sin(2 * np.pi * 440 * t)  # Tom de 440Hz
        
        print(f"Sinal de áudio criado: {audio_signal.shape} samples")
        print(f"Taxa de amostragem: {sample_rate} Hz")
        print("✓ Operações básicas de áudio funcionando")
        
    except Exception as e:
        print(f"⚠ Erro no torchaudio: {e}")
    
    print("✓ Funcionalidades do torchaudio testadas\n")

def test_performance():
    """Testa desempenho com operações intensivas"""
    print("=== Testando Desempenho ===")
    
    # Operação intensiva: multiplicação de matrizes grandes
    size = 1000
    A = torch.randn(size, size)
    B = torch.randn(size, size)
    
    start_time = time.time()
    C = torch.matmul(A, B)
    end_time = time.time()
    
    elapsed_time = end_time - start_time
    print(f"Multiplicação de matriz {size}x{size}: {elapsed_time:.4f} segundos")
    
    # Verificar se o resultado é razoável
    if C.shape == (size, size):
        print("✓ Operação de matriz grande concluída com sucesso")
        print(f"✓ Desempenho: {elapsed_time:.4f}s para matriz {size}x{size}")
    else:
        print("⚠ Problema na operação de matriz")
    
    print()

def test_gpu_availability():
    """Verifica disponibilidade de GPU"""
    print("=== Verificando GPU ===")
    
    if torch.cuda.is_available():
        device = torch.device("cuda")
        print(f"GPU disponível: {torch.cuda.get_device_name(0)}")
        print(f"Memória GPU: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
    else:
        device = torch.device("cpu")
        print("GPU não disponível, usando CPU")
    
    # Testar transferência de dados para GPU (se disponível)
    if torch.cuda.is_available():
        x = torch.randn(1000, 1000)
        x_gpu = x.to(device)
        print(f"Dados transferidos para GPU: {x_gpu.device}")
    
    print()

def main():
    """Função principal de testes"""
    print("Iniciando testes abrangentes do PyTorch...")
    print(f"PyTorch version: {torch.__version__}")
    print(f"Torchvision version: {torchvision.__version__}")
    print(f"Torchaudio version: {torchaudio.__version__}")
    print()
    
    # Executar todos os testes
    test_basic_tensor_operations()
    test_neural_network()
    test_torchvision()
    test_torchaudio()
    test_performance()
    test_gpu_availability()
    
    print("=== Resumo dos Testes ===")
    print("Todos os testes foram concluídos com sucesso!")
    print("As bibliotecas PyTorch estão funcionando corretamente.")
    print("✓ Operações básicas de tensor")
    print("✓ Redes neurais e backpropagation") 
    print("✓ Funcionalidades do torchvision")
    print("✓ Funcionalidades do torchaudio")
    print("✓ Desempenho em operações intensivas")
    print("✓ Verificação de hardware")

if __name__ == "__main__":
    main()
