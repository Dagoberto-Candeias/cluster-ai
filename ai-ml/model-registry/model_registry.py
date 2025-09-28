"""
Model Registry - Sistema de gerenciamento de modelos de IA para Cluster AI.

Este módulo fornece uma interface Python completa para gerenciar modelos de IA,
com integração nativa ao cluster Dask e suporte a múltiplos frameworks.
"""

import os
import json
import hashlib
import shutil
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional, Any, Union
import yaml
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ModelRegistry:
    """
    Classe principal para gerenciamento de modelos de IA.

    Fornece funcionalidades completas para:
    - Registrar modelos
    - Carregar modelos
    - Gerenciar versões
    - Integração com Dask
    """

    def __init__(self, config_path: Optional[str] = None):
        """
        Inicializar o Model Registry.

        Args:
            config_path: Caminho para arquivo de configuração YAML
        """
        if config_path is None:
            config_path = Path(__file__).parent / "config" / "model_registry.yaml"

        self.config = self._load_config(config_path)
        self.base_path = Path(self.config["storage"]["base_path"])

        # Criar diretórios necessários
        self._create_directories()

        logger.info(f"Model Registry inicializado em {self.base_path}")

    def _load_config(self, config_path: str) -> Dict[str, Any]:
        """Carregar configuração do arquivo YAML."""
        with open(config_path, "r") as f:
            return yaml.safe_load(f)

    def _create_directories(self):
        """Criar estrutura de diretórios necessária."""
        directories = [
            self.base_path / "models" / "pytorch",
            self.base_path / "models" / "tensorflow",
            self.base_path / "models" / "onnx",
            self.base_path / "metadata",
            self.base_path / "versions",
            self.base_path / "cache"
        ]

        for directory in directories:
            directory.mkdir(parents=True, exist_ok=True)

    def _compute_sha256(self, file_path: Path) -> str:
        """Calcular hash SHA256 de um arquivo."""
        sha256_hash = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256_hash.update(byte_block)
        return sha256_hash.hexdigest()

    def register_model(
        self,
        model_path: Union[str, Path],
        name: str,
        framework: str,
        version: str,
        description: str = "",
        custom_metadata: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Registrar um novo modelo no registry.

        Args:
            model_path: Caminho para o arquivo do modelo
            name: Nome do modelo
            framework: Framework (pytorch, tensorflow, onnx)
            version: Versão do modelo
            description: Descrição opcional
            custom_metadata: Metadados customizados

        Returns:
            Dicionário com informações do modelo registrado
        """
        model_file = Path(model_path)
        if not model_file.exists():
            raise FileNotFoundError(f"Arquivo do modelo não encontrado: {model_file}")

        # Verificar framework suportado
        if framework not in self.config["frameworks"]:
            raise ValueError(f"Framework não suportado: {framework}")

        # Calcular hash
        model_hash = self._compute_sha256(model_file)

        # Definir caminhos
        models_path = self.base_path / "models" / framework
        metadata_path = self.base_path / "metadata"
        dest_file = models_path / f"{name}_{version}{model_file.suffix}"
        metadata_file = metadata_path / f"{name}_{version}.json"

        # Copiar arquivo do modelo
        shutil.copy2(model_file, dest_file)

        # Criar metadados
        metadata = {
            "name": name,
            "framework": framework,
            "version": version,
            "description": description,
            "file_name": dest_file.name,
            "file_size": model_file.stat().st_size,
            "sha256": model_hash,
            "created_at": datetime.utcnow().isoformat() + "Z",
            "custom_metadata": custom_metadata or {}
        }

        # Salvar metadados
        with open(metadata_file, "w") as f:
            json.dump(metadata, f, indent=4)

        logger.info(f"Modelo '{name}' versão '{version}' registrado com sucesso")
        return metadata

    def list_models(
        self,
        framework: Optional[str] = None,
        name_filter: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Listar modelos registrados.

        Args:
            framework: Filtrar por framework específico
            name_filter: Filtrar por nome (case insensitive)

        Returns:
            Lista de metadados dos modelos
        """
        metadata_path = self.base_path / "metadata"
        if not metadata_path.exists():
            return []

        models = []
        for metadata_file in metadata_path.glob("*.json"):
            try:
                with open(metadata_file, "r") as f:
                    metadata = json.load(f)
                    models.append(metadata)
            except Exception as e:
                logger.warning(f"Erro ao ler {metadata_file}: {e}")

        # Ordenar por data de criação (mais recente primeiro)
        models.sort(key=lambda x: x.get("created_at", ""), reverse=True)

        # Aplicar filtros
        if framework:
            models = [m for m in models if m.get("framework") == framework]

        if name_filter:
            models = [m for m in models if name_filter.lower() in m.get("name", "").lower()]

        return models

    def get_model_info(self, name: str, version: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """
        Obter informações de um modelo específico.

        Args:
            name: Nome do modelo
            version: Versão específica (se None, retorna a mais recente)

        Returns:
            Metadados do modelo ou None se não encontrado
        """
        models = self.list_models(name_filter=name)

        if not models:
            return None

        if version:
            for model in models:
                if model.get("version") == version:
                    return model
            return None

        # Retornar versão mais recente
        return models[0]

    def load_model(self, name: str, version: Optional[str] = None, framework: Optional[str] = None):
        """
        Carregar um modelo no cluster Dask.

        Args:
            name: Nome do modelo
            version: Versão específica
            framework: Framework (auto-detectado se None)

        Returns:
            Modelo carregado pronto para uso
        """
        model_info = self.get_model_info(name, version)
        if not model_info:
            raise ValueError(f"Modelo '{name}' não encontrado")

        framework = framework or model_info["framework"]
        model_path = self.base_path / "models" / framework / model_info["file_name"]

        if not model_path.exists():
            raise FileNotFoundError(f"Arquivo do modelo não encontrado: {model_path}")

        # Carregar modelo baseado no framework
        if framework == "pytorch":
            return self._load_pytorch_model(model_path)
        elif framework == "tensorflow":
            return self._load_tensorflow_model(model_path)
        elif framework == "onnx":
            return self._load_onnx_model(model_path)
        else:
            raise ValueError(f"Framework não suportado: {framework}")

    def _load_pytorch_model(self, model_path: Path):
        """Carregar modelo PyTorch."""
        try:
            import torch
            # Para modelos de exemplo, permitir carregamento completo
            # Em produção, considere usar weights_only=True para segurança
            return torch.load(model_path, weights_only=False)
        except ImportError:
            raise ImportError("PyTorch não está instalado")

    def _load_tensorflow_model(self, model_path: Path):
        """Carregar modelo TensorFlow."""
        try:
            import tensorflow as tf
            return tf.saved_model.load(str(model_path))
        except ImportError:
            raise ImportError("TensorFlow não está instalado")

    def _load_onnx_model(self, model_path: Path):
        """Carregar modelo ONNX."""
        try:
            import onnxruntime as ort
            return ort.InferenceSession(str(model_path))
        except ImportError:
            raise ImportError("ONNX Runtime não está instalado")

    def delete_model(self, name: str, version: Optional[str] = None) -> bool:
        """
        Remover um modelo do registry.

        Args:
            name: Nome do modelo
            version: Versão específica (se None, remove todas as versões)

        Returns:
            True se removido com sucesso
        """
        models = self.list_models(name_filter=name)
        if not models:
            return False

        if version:
            models = [m for m in models if m.get("version") == version]

        for model in models:
            # Remover arquivo do modelo
            framework = model["framework"]
            model_path = self.base_path / "models" / framework / model["file_name"]
            if model_path.exists():
                model_path.unlink()

            # Remover metadados
            metadata_file = self.base_path / "metadata" / f"{name}_{model['version']}.json"
            if metadata_file.exists():
                metadata_file.unlink()

        logger.info(f"Modelo '{name}' removido com sucesso")
        return True

    def get_registry_stats(self) -> Dict[str, Any]:
        """
        Obter estatísticas do registry.

        Returns:
            Dicionário com estatísticas
        """
        models = self.list_models()
        total_size = sum(m.get("file_size", 0) for m in models)

        frameworks = {}
        for model in models:
            fw = model.get("framework", "unknown")
            frameworks[fw] = frameworks.get(fw, 0) + 1

        return {
            "total_models": len(models),
            "total_size_bytes": total_size,
            "frameworks": frameworks,
            "last_updated": max((m.get("created_at", "") for m in models), default=None)
        }

# Função de conveniência para uso direto
def create_registry(config_path: Optional[str] = None) -> ModelRegistry:
    """Criar uma instância do Model Registry."""
    return ModelRegistry(config_path)

# Exemplo de uso
if __name__ == "__main__":
    # Criar registry
    registry = ModelRegistry()

    # Listar modelos
    models = registry.list_models()
    print(f"Modelos registrados: {len(models)}")

    # Obter estatísticas
    stats = registry.get_registry_stats()
    print(f"Estatísticas: {stats}")
