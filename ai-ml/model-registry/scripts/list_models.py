#!/usr/bin/env python3
"""
Script para listar modelos registrados no Model Registry do Cluster AI.
"""

import json
import os
from pathlib import Path
from datetime import datetime
import yaml

CONFIG_PATH = Path(__file__).parent.parent / "config" / "model_registry.yaml"


def load_config():
    with open(CONFIG_PATH, "r") as f:
        return yaml.safe_load(f)


def format_size(bytes_size):
    """Formatar tamanho de arquivo em formato legível."""
    for unit in ["B", "KB", "MB", "GB"]:
        if bytes_size < 1024.0:
            return f"{bytes_size:.1f}{unit}"
        bytes_size /= 1024.0
    return f"{bytes_size:.1f}TB"


def format_date(date_str):
    """Formatar data para exibição."""
    try:
        dt = datetime.fromisoformat(date_str.replace("Z", "+00:00"))
        return dt.strftime("%Y-%m-%d %H:%M:%S")
    except:
        return date_str


def list_models(args):
    config = load_config()
    base_path = Path(config["storage"]["base_path"])
    metadata_path = base_path / "metadata"

    if not metadata_path.exists():
        print("Nenhum modelo registrado ainda.")
        return

    # Coletar todos os metadados
    models = []
    for metadata_file in metadata_path.glob("*.json"):
        try:
            with open(metadata_file, "r") as f:
                metadata = json.load(f)
                models.append(metadata)
        except Exception as e:
            print(f"Erro ao ler {metadata_file}: {e}")

    if not models:
        print("Nenhum modelo encontrado.")
        return

    # Ordenar por data de criação (mais recente primeiro)
    models.sort(key=lambda x: x.get("created_at", ""), reverse=True)

    # Filtrar por framework se especificado
    if args.framework:
        models = [m for m in models if m.get("framework") == args.framework]

    # Filtrar por nome se especificado
    if args.name:
        models = [m for m in models if args.name.lower() in m.get("name", "").lower()]

    # Exibir cabeçalho
    print("\n🧠 MODELOS REGISTRADOS NO CLUSTER AI")
    print("=" * 80)
    print(
        f"{'Nome':<20} {'Versão':<10} {'Framework':<12} {'Tamanho':<10} {'Criado em':<20} {'Descrição':<50}"
    )
    print("-" * 80)

    # Exibir modelos
    for model in models:
        name = model.get("name", "N/A")
        version = model.get("version", "N/A")
        framework = model.get("framework", "N/A")
        size = format_size(model.get("file_size", 0))
        created = format_date(model.get("created_at", "N/A"))
        description = model.get("description", "")[:50]

        print(
            f"{name:<20} {version:<10} {framework:<12} {size:<10} {created:<20} {description:<50}"
        )

    print("-" * 80)
    print(f"Total de modelos: {len(models)}")


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Listar modelos registrados")
    parser.add_argument(
        "--framework",
        choices=["pytorch", "tensorflow", "onnx"],
        help="Filtrar por framework",
    )
    parser.add_argument("--name", help="Filtrar por nome do modelo")

    args = parser.parse_args()
    list_models(args)


if __name__ == "__main__":
    main()
