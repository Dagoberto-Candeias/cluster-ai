#!/usr/bin/env python3
"""
Módulo para registro de workers no cluster
"""

import json
import os
from typing import Any, Dict, Optional


class WorkerRegistration:
    """Classe para gerenciar registro de workers"""

    def __init__(self, config_file: str = "configs/cluster_workers.json"):
        self.config_file = config_file
        self.workers = self._load_workers()

    def _load_workers(self) -> Dict[str, Any]:
        """Carrega lista de workers do arquivo de configuração"""
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, "r") as f:
                    config = json.load(f)
                    return config.get("workers", {})
            except:
                pass
        return {}

    def _save_workers(self):
        """Salva lista de workers no arquivo de configuração"""
        config = {}
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, "r") as f:
                    config = json.load(f)
            except:
                pass

        config["workers"] = self.workers

        with open(self.config_file, "w") as f:
            json.dump(config, f, indent=2)

    def register_worker(self, worker_data: Dict[str, Any]) -> bool:
        """
        Registra um novo worker

        Args:
            worker_data: Dados do worker (name, ip, port, type)

        Returns:
            True se registrado com sucesso
        """
        try:
            worker_id = worker_data.get("name", f"worker_{len(self.workers)}")
            self.workers[worker_id] = worker_data
            self._save_workers()
            return True
        except Exception as e:
            print(f"Erro ao registrar worker: {e}")
            return False

    def unregister_worker(self, worker_id: str) -> bool:
        """
        Remove um worker do registro

        Args:
            worker_id: ID do worker a ser removido

        Returns:
            True se removido com sucesso
        """
        if worker_id in self.workers:
            del self.workers[worker_id]
            self._save_workers()
            return True
        return False

    def get_worker(self, worker_id: str) -> Optional[Dict[str, Any]]:
        """
        Obtém dados de um worker específico

        Args:
            worker_id: ID do worker

        Returns:
            Dados do worker ou None se não encontrado
        """
        return self.workers.get(worker_id)

    def list_workers(self) -> Dict[str, Any]:
        """
        Lista todos os workers registrados

        Returns:
            Dicionário com todos os workers
        """
        return self.workers.copy()


# Função de compatibilidade para importação direta
def register_worker(worker_data: Dict[str, Any]) -> bool:
    """
    Função de compatibilidade para registro de worker

    Args:
        worker_data: Dados do worker

    Returns:
        True se registrado com sucesso
    """
    registration = WorkerRegistration()
    return registration.register_worker(worker_data)


if __name__ == "__main__":
    # Teste do módulo
    registration = WorkerRegistration()

    # Registrar worker de teste
    test_worker = {
        "name": "test-worker",
        "ip": "192.168.1.100",
        "port": 8022,
        "type": "android",
    }

    if registration.register_worker(test_worker):
        print("Worker registrado com sucesso")
        print("Workers registrados:", list(registration.list_workers().keys()))
    else:
        print("Falha ao registrar worker")
