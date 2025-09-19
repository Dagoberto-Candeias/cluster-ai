#!/usr/bin/env python3
"""
Script de inicialização do Model Registry do Cluster AI.

Este script:
1. Cria a estrutura de diretórios necessária
2. Valida a configuração
3. Inicializa o registry
4. Executa testes básicos
"""

import os
import sys
from pathlib import Path
import yaml
import json
from datetime import datetime

def load_config():
    """Carregar configuração do Model Registry."""
    config_path = Path(__file__).parent.parent / "config" / "model_registry.yaml"
    with open(config_path, "r") as f:
        return yaml.safe_load(f)

def create_directories(config):
    """Criar estrutura de diretórios necessária."""
    base_path = Path(config["storage"]["base_path"])

    directories = [
        base_path,
        base_path / "models" / "pytorch",
        base_path / "models" / "tensorflow",
        base_path / "models" / "onnx",
        base_path / "metadata",
        base_path / "versions",
        base_path / "cache",
        base_path / "logs",
        base_path / "backups"
    ]

    print("📁 Criando estrutura de diretórios...")

    for directory in directories:
        directory.mkdir(parents=True, exist_ok=True)
        print(f"   ✅ {directory}")

def validate_configuration(config):
    """Validar configuração do Model Registry."""
    print("🔧 Validando configuração...")

    issues = []

    # Verificar caminhos
    base_path = Path(config["storage"]["base_path"])
    if not base_path.exists():
        issues.append(f"Caminho base não existe: {base_path}")

    # Verificar frameworks suportados
    required_frameworks = ["pytorch", "tensorflow", "onnx"]
    for framework in required_frameworks:
        if framework not in config.get("frameworks", {}):
            issues.append(f"Framework não configurado: {framework}")

    # Verificar configurações de storage
    storage_config = config.get("storage", {})
    if "cache_size" not in storage_config:
        issues.append("Configuração de cache_size ausente")

    if "backup_enabled" not in storage_config:
        issues.append("Configuração de backup_enabled ausente")

    if issues:
        print("❌ Problemas encontrados na configuração:")
        for issue in issues:
            print(f"   - {issue}")
        return False

    print("   ✅ Configuração válida")
    return True

def create_registry_info(config):
    """Criar arquivo de informações do registry."""
    base_path = Path(config["storage"]["base_path"])
    info_file = base_path / "registry_info.json"

    info = {
        "name": "Cluster AI Model Registry",
        "version": config["general"]["version"],
        "created_at": datetime.utcnow().isoformat() + "Z",
        "base_path": str(base_path),
        "frameworks_supported": list(config["frameworks"].keys()),
        "features": [
            "versioning",
            "metadata_management",
            "dask_integration",
            "cache_system",
            "backup_system"
        ]
    }

    with open(info_file, "w") as f:
        json.dump(info, f, indent=4)

    print(f"📄 Arquivo de informações criado: {info_file}")

def test_basic_functionality():
    """Executar testes básicos de funcionalidade."""
    print("🧪 Executando testes básicos...")

    try:
        # Testar import do módulo
        sys.path.insert(0, str(Path(__file__).parent.parent))
        from model_registry import ModelRegistry

        # Criar instância
        registry = ModelRegistry()

        # Testar listagem (deve retornar lista vazia)
        models = registry.list_models()
        print(f"   ✅ Listagem de modelos: {len(models)} modelos")

        # Testar estatísticas
        stats = registry.get_registry_stats()
        print(f"   ✅ Estatísticas: {stats['total_models']} modelos")

        print("   ✅ Todos os testes básicos passaram")
        return True

    except Exception as e:
        print(f"   ❌ Erro nos testes: {e}")
        return False

def create_example_config():
    """Criar arquivo de configuração de exemplo."""
    config_path = Path(__file__).parent.parent / "config"
    example_config = config_path / "model_registry.example.yaml"

    example = {
        "general": {
            "name": "Cluster AI Model Registry",
            "version": "1.0.0",
            "description": "Sistema de gerenciamento de modelos de IA"
        },
        "storage": {
            "base_path": "/opt/cluster-ai/models",
            "cache_size": "10GB",
            "backup_enabled": True,
            "compression_enabled": True
        },
        "frameworks": {
            "pytorch": {
                "supported_versions": ["1.9+", "2.0+"],
                "extensions": [".pth", ".pt"]
            },
            "tensorflow": {
                "supported_versions": ["2.8+", "2.9+"],
                "extensions": [".h5", ".pb"]
            },
            "onnx": {
                "supported_versions": ["1.10+", "1.11+"],
                "extensions": [".onnx"]
            }
        }
    }

    with open(example_config, "w") as f:
        yaml.dump(example, f, default_flow_style=False)

    print(f"📝 Arquivo de exemplo criado: {example_config}")

def main():
    print("🚀 Inicializando Model Registry - Cluster AI")
    print("=" * 50)

    try:
        # Carregar configuração
        print("\n1. Carregando configuração...")
        config = load_config()
        print("   ✅ Configuração carregada")

        # Validar configuração
        print("\n2. Validando configuração...")
        if not validate_configuration(config):
            print("❌ Inicialização abortada devido a problemas na configuração")
            sys.exit(1)

        # Criar diretórios
        print("\n3. Criando estrutura de diretórios...")
        create_directories(config)

        # Criar arquivo de informações
        print("\n4. Criando arquivo de informações...")
        create_registry_info(config)

        # Executar testes
        print("\n5. Executando testes básicos...")
        if not test_basic_functionality():
            print("❌ Inicialização abortada devido a falhas nos testes")
            sys.exit(1)

        # Criar configuração de exemplo
        print("\n6. Criando arquivos auxiliares...")
        create_example_config()

        print("\n🎉 Model Registry inicializado com sucesso!")
        print("\n📋 PRÓXIMOS PASSOS:")
        print("   1. Registre seu primeiro modelo:")
        print("      python scripts/register_model.py --model-path /path/to/model.pth --name my_model --framework pytorch --version 1.0.0")
        print("   2. Liste modelos registrados:")
        print("      python scripts/list_models.py")
        print("   3. Execute o exemplo:")
        print("      python examples/usage_example.py")

    except Exception as e:
        print(f"\n❌ Erro durante inicialização: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
