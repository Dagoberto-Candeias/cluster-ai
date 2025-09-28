#!/usr/bin/env python3
"""
Script para registrar um modelo no Model Registry do Cluster AI.
"""

import argparse
import os
import shutil
import hashlib
import json
from datetime import datetime
from pathlib import Path
import yaml

CONFIG_PATH = Path(__file__).parent.parent / "config" / "model_registry.yaml"

def load_config():
    with open(CONFIG_PATH, "r") as f:
        return yaml.safe_load(f)

def compute_sha256(file_path):
    sha256_hash = hashlib.sha256()
    with open(file_path,"rb") as f:
        for byte_block in iter(lambda: f.read(4096),b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def register_model(args):
    config = load_config()
    base_path = Path(config["storage"]["base_path"])
    models_path = base_path / "models" / args.framework.lower()
    metadata_path = base_path / "metadata"
    versions_path = base_path / "versions"

    # Criar diretórios se não existirem
    models_path.mkdir(parents=True, exist_ok=True)
    metadata_path.mkdir(parents=True, exist_ok=True)
    versions_path.mkdir(parents=True, exist_ok=True)

    # Verificar se o arquivo do modelo existe
    model_file = Path(args.model_path)
    if not model_file.exists():
        print(f"Erro: arquivo do modelo não encontrado: {model_file}")
        return

    # Calcular hash SHA256
    model_hash = compute_sha256(model_file)

    # Definir nome do arquivo destino
    dest_file = models_path / f"{args.name}_{args.version}{model_file.suffix}"

    # Copiar arquivo do modelo
    shutil.copy2(model_file, dest_file)

    # Criar metadados
    metadata = {
        "name": args.name,
        "framework": args.framework,
        "version": args.version,
        "description": args.description,
        "file_name": dest_file.name,
        "file_size": model_file.stat().st_size,
        "sha256": model_hash,
        "created_at": datetime.utcnow().isoformat() + "Z",
        "custom_metadata": {}
    }

    # Adicionar metadados customizados
    if args.metadata:
        try:
            custom_meta = json.loads(args.metadata)
            metadata["custom_metadata"] = custom_meta
        except Exception as e:
            print(f"Erro ao parsear metadados customizados: {e}")

    # Salvar metadados em arquivo JSON
    metadata_file = metadata_path / f"{args.name}_{args.version}.json"
    with open(metadata_file, "w") as f:
        json.dump(metadata, f, indent=4)

    print(f"Modelo '{args.name}' versão '{args.version}' registrado com sucesso.")
    print(f"Arquivo salvo em: {dest_file}")
    print(f"Metadados salvos em: {metadata_file}")

def main():
    parser = argparse.ArgumentParser(description="Registrar modelo no Model Registry")
    parser.add_argument("--model-path", required=True, help="Caminho para o arquivo do modelo")
    parser.add_argument("--name", required=True, help="Nome do modelo")
    parser.add_argument("--framework", required=True, choices=["pytorch", "tensorflow", "onnx"], help="Framework do modelo")
    parser.add_argument("--version", required=True, help="Versão do modelo")
    parser.add_argument("--description", default="", help="Descrição do modelo")
    parser.add_argument("--metadata", default="", help="Metadados customizados em JSON")

    args = parser.parse_args()
    register_model(args)

if __name__ == "__main__":
    main()
