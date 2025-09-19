#!/usr/bin/env python3
"""
Exemplo de uso do Model Registry do Cluster AI.

Este script demonstra como:
1. Registrar modelos
2. Listar modelos
3. Carregar modelos
4. Usar modelos com Dask
"""

import sys
import os
from pathlib import Path

# Adicionar o diretório do model registry ao path
sys.path.insert(0, str(Path(__file__).parent.parent))

from model_registry import ModelRegistry
import tempfile
import torch
import torch.nn as nn

import torch.nn as nn

class SimpleModel(nn.Module):
    def __init__(self):
        super().__init__()
        self.linear = nn.Linear(10, 1)

    def forward(self, x):
        return self.linear(x)

def create_sample_model():
    """Criar um modelo PyTorch simples para exemplo."""
    return SimpleModel()

def main():
    print("🧠 Exemplo de Uso do Model Registry - Cluster AI")
    print("=" * 60)

    # Inicializar registry
    print("\n1. Inicializando Model Registry...")
    registry = ModelRegistry()

    # Criar modelo de exemplo
    print("\n2. Criando modelo de exemplo...")
    model = create_sample_model()

    # Salvar modelo temporariamente
    with tempfile.NamedTemporaryFile(suffix='.pth', delete=False) as f:
        torch.save(model, f.name)
        model_path = f.name

    try:
        # Registrar modelo
        print("\n3. Registrando modelo...")
        metadata = registry.register_model(
            model_path=model_path,
            name="exemplo_regressao",
            framework="pytorch",
            version="1.0.0",
            description="Modelo de exemplo para regressão linear",
            custom_metadata={
                "accuracy": 0.95,
                "dataset": "synthetic",
                "architecture": "Linear"
            }
        )
        print(f"✅ Modelo registrado: {metadata['name']} v{metadata['version']}")

        # Listar modelos
        print("\n4. Listando modelos registrados...")
        models = registry.list_models()
        print(f"📋 Total de modelos: {len(models)}")

        for model_info in models:
            print(f"   - {model_info['name']} v{model_info['version']} ({model_info['framework']})")

        # Obter informações específicas
        print("\n5. Obtendo informações do modelo...")
        model_info = registry.get_model_info("exemplo_regressao")
        if model_info:
            print(f"📄 Nome: {model_info['name']}")
            print(f"🏷️  Versão: {model_info['version']}")
            print(f"🔧 Framework: {model_info['framework']}")
            print(f"📏 Tamanho: {model_info['file_size']} bytes")
            print(f"📅 Criado em: {model_info['created_at']}")
            print(f"📝 Descrição: {model_info['description']}")

        # Carregar modelo
        print("\n6. Carregando modelo...")
        loaded_model = registry.load_model("exemplo_regressao")
        print(f"✅ Modelo carregado: {type(loaded_model)}")

        # Testar modelo
        print("\n7. Testando modelo...")
        test_input = torch.randn(5, 10)
        with torch.no_grad():
            output = loaded_model(test_input)
        print(f"📊 Entrada: {test_input.shape}")
        print(f"📊 Saída: {output.shape}")

        # Exemplo com Dask (se disponível)
        print("\n8. Exemplo de uso com Dask...")
        try:
            from dask.distributed import Client, LocalCluster

            # Iniciar cluster local
            cluster = LocalCluster(n_workers=2, threads_per_worker=1, processes=False)
            client = Client(cluster)

            print("🚀 Cluster Dask iniciado")

            # Função que usa o modelo
            def predict_with_model(data, model_name):
                """Função para executar predição distribuída."""
                from model_registry import ModelRegistry

                registry = ModelRegistry()
                model = registry.load_model(model_name)

                import torch
                data_tensor = torch.tensor(data)
                with torch.no_grad():
                    return model(data_tensor).numpy()

            # Dados de exemplo
            sample_data = [[1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
                          [2, 3, 4, 5, 6, 7, 8, 9, 10, 11]]

            # Executar predição distribuída
            futures = [client.submit(predict_with_model, data, "exemplo_regressao")
                      for data in sample_data]

            results = client.gather(futures)
            print(f"🎯 Resultados da predição distribuída: {len(results)} predições")

            client.close()

        except ImportError:
            print("⚠️  Dask não está disponível. Instale com: pip install dask distributed")
        except Exception as e:
            print(f"⚠️  Erro no exemplo Dask: {e}")

        # Estatísticas do registry
        print("\n9. Estatísticas do Registry...")
        stats = registry.get_registry_stats()
        print(f"📊 Estatísticas:")
        print(f"   - Total de modelos: {stats['total_models']}")
        print(f"   - Tamanho total: {stats['total_size_bytes']} bytes")
        print(f"   - Frameworks: {stats['frameworks']}")

        print("\n✅ Exemplo concluído com sucesso!")

    finally:
        # Limpar arquivo temporário
        if os.path.exists(model_path):
            os.unlink(model_path)

if __name__ == "__main__":
    main()
