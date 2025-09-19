"""
Model Registry - Sistema de gerenciamento de modelos de IA para Cluster AI.

Este pacote fornece ferramentas completas para:
- Gerenciamento de modelos de IA
- Versionamento e metadados
- Integração com Dask
- Cache inteligente
- API REST
"""

from model_registry import ModelRegistry, create_registry

__version__ = "1.0.0"
__author__ = "Cluster AI Team"
__description__ = "Sistema de gerenciamento de modelos de IA"

__all__ = [
    "ModelRegistry",
    "create_registry",
    "__version__",
    "__author__",
    "__description__"
]
