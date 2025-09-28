#!/usr/bin/env python3
"""
Sistema de Descoberta Automática de Workers para Cluster AI
Suporte para IPs dinâmicos através de múltiplas estratégias de descoberta
"""

import json
import logging
import os
import socket
import subprocess
import threading
import time
from typing import Dict, List, Optional

# Configuração de logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class AutoDiscovery:
    """Sistema de descoberta automática de workers"""

    def __init__(self, config_dir: str = "~/.cluster_config"):
        self.config_dir = os.path.expanduser(config_dir)
        self.discovered_workers = {}
        self.known_workers = {}
        self.registration_server = None
        self.discovery_thread = None
        self.running = False

        # Criar diretório de configuração se não existir
        os.makedirs(self.config_dir, exist_ok=True)

        # Arquivos de configuração
        self.workers_file = os.path.join(self.config_dir, "discovered_workers.json")
        self.nodes_file = os.path.join(self.config_dir, "nodes_list.conf")

        # Carregar workers conhecidos
        self._load_known_workers()

    def _load_known_workers(self):
        """Carrega lista de workers conhecidos"""
        if os.path.exists(self.workers_file):
            try:
                with open(self.workers_file, "r") as f:
                    self.known_workers = json.load(f)
            except Exception as e:
                logger.error(f"Erro ao carregar workers conhecidos: {e}")

    def _save_known_workers(self):
        """Salva lista de workers conhecidos"""
        try:
            with open(self.workers_file, "w") as f:
                json.dump(self.known_workers, f, indent=2)
        except Exception as e:
            logger.error(f"Erro ao salvar workers conhecidos: {e}")

    def discover_by_hostname(self, hostname: str) -> Optional[str]:
        """Descobre IP através do hostname"""
        try:
            ip = socket.gethostbyname(hostname)
            logger.info(f"Descoberto {hostname} -> {ip}")
            return ip
        except socket.gaierror:
            logger.debug(f"Não foi possível resolver hostname: {hostname}")
            return None

    def discover_by_arp_scan(self, network: str = "192.168.0.0/24") -> List[Dict]:
        """Escaneia rede usando ARP para descobrir dispositivos"""
        devices = []
        try:
            # Usar arp-scan se disponível
            result = subprocess.run(
                ["arp-scan", "--localnet"], capture_output=True, text=True, timeout=30
            )

            if result.returncode == 0:
                lines = result.stdout.strip().split("\n")
                for line in lines:
                    if "\t" in line:
                        parts = line.split("\t")
                        if len(parts) >= 3:
                            ip = parts[0].strip()
                            mac = parts[1].strip()
                            hostname = parts[2].strip() if len(parts) > 2 else ""

                            devices.append(
                                {
                                    "ip": ip,
                                    "mac": mac,
                                    "hostname": hostname,
                                    "discovery_method": "arp_scan",
                                }
                            )

        except (subprocess.TimeoutExpired, FileNotFoundError):
            logger.debug("arp-scan não disponível ou timeout")

        return devices

    def discover_by_mdns(self) -> List[Dict]:
        """Descoberta usando mDNS/Bonjour"""
        devices = []
        try:
            # Usar avahi-browse se disponível
            result = subprocess.run(
                ["avahi-browse", "-a", "-t"], capture_output=True, text=True, timeout=10
            )

            if result.returncode == 0:
                lines = result.stdout.strip().split("\n")
                for line in lines:
                    if ";IPv4;" in line:
                        parts = line.split(";")
                        if len(parts) >= 8:
                            hostname = parts[6].strip()
                            ip = parts[7].strip()

                            devices.append(
                                {
                                    "ip": ip,
                                    "hostname": hostname,
                                    "discovery_method": "mdns",
                                }
                            )

        except (subprocess.TimeoutExpired, FileNotFoundError):
            logger.debug("mDNS discovery não disponível")

        return devices

    def discover_ssh_hosts(self, port: int = 22) -> List[Dict]:
        """Descobre hosts que respondem em porta SSH"""
        devices = []
        try:
            # Usar nmap se disponível
            result = subprocess.run(
                ["nmap", "-p", str(port), "--open", "192.168.0.0/24"],
                capture_output=True,
                text=True,
                timeout=60,
            )

            if result.returncode == 0:
                lines = result.stdout.strip().split("\n")
                for line in lines:
                    if "Nmap scan report for" in line:
                        ip = line.split()[-1].strip("()")
                        devices.append(
                            {"ip": ip, "port": port, "discovery_method": "ssh_scan"}
                        )

        except (subprocess.TimeoutExpired, FileNotFoundError):
            logger.debug("Nmap não disponível para descoberta SSH")

        return devices

    def start_registration_server(self, port: int = 8080):
        """Inicia servidor de registro para workers se registrarem automaticamente"""
        logger.info(
            f"Servidor de registro seria iniciado na porta {port} (funcionalidade em desenvolvimento)"
        )
        # Servidor HTTP será implementado em versão futura
        # Por enquanto, focamos na descoberta via rede local

    def register_worker(self, worker_info: Dict):
        """Registra worker descoberto"""
        worker_id = worker_info.get("name", f"worker_{len(self.discovered_workers)}")
        self.discovered_workers[worker_id] = worker_info
        self.known_workers[worker_id] = worker_info
        self._save_known_workers()

        logger.info(f"Worker registrado: {worker_id} ({worker_info.get('ip')})")

    def update_configuration(self):
        """Atualiza arquivo de configuração com workers descobertos"""
        try:
            config_lines = [
                "# =============================================================================",
                "# Configuração de Workers - Gerado Automaticamente",
                "# Atualizado em: " + time.strftime("%Y-%m-%d %H:%M:%S"),
                "# =============================================================================",
                "",
            ]

            for worker_id, worker_info in self.discovered_workers.items():
                if worker_info.get("status", "active") == "active":
                    hostname = worker_info.get("hostname", worker_id)
                    ip = worker_info.get("ip", "")
                    user = worker_info.get("user", "user")
                    port = worker_info.get("port", 22)
                    status = worker_info.get("status", "active")

                    line = f"{hostname} {worker_id} {ip} {user} {port} {status}"
                    config_lines.append(line)

            with open(self.nodes_file, "w") as f:
                f.write("\n".join(config_lines))

            logger.info(
                f"Configuração atualizada: {len(self.discovered_workers)} workers"
            )

        except Exception as e:
            logger.error(f"Erro ao atualizar configuração: {e}")

    def discover_all(self) -> Dict[str, List]:
        """Executa todas as estratégias de descoberta"""
        logger.info("Iniciando descoberta automática de workers...")

        results = {
            "arp_scan": self.discover_by_arp_scan(),
            "mdns": self.discover_by_mdns(),
            "ssh_scan": self.discover_ssh_hosts(),
        }

        # Processar resultados
        for method, devices in results.items():
            for device in devices:
                # Tentar identificar se é um worker conhecido
                device_ip = device.get("ip")
                device_hostname = device.get("hostname", "")

                # Verificar se já é um worker conhecido
                for worker_id, worker_info in self.known_workers.items():
                    if (
                        worker_info.get("ip") == device_ip
                        or worker_info.get("hostname") == device_hostname
                    ):
                        # Atualizar informações do worker
                        worker_info.update(device)
                        worker_info["last_seen"] = time.time()
                        self.register_worker(worker_info)
                        break
                else:
                    # Novo dispositivo potencial
                    if device_hostname:
                        # Tentar descobrir mais informações
                        worker_info = device.copy()
                        worker_info["name"] = device_hostname
                        worker_info["user"] = "user"  # padrão
                        worker_info["status"] = "discovered"
                        worker_info["last_seen"] = time.time()
                        self.register_worker(worker_info)

        return results

    def start_auto_discovery(self, interval: int = 300):
        """Inicia descoberta automática periódica"""
        self.running = True

        def discovery_loop():
            while self.running:
                try:
                    self.discover_all()
                    self.update_configuration()
                except Exception as e:
                    logger.error(f"Erro na descoberta automática: {e}")

                time.sleep(interval)

        self.discovery_thread = threading.Thread(target=discovery_loop, daemon=True)
        self.discovery_thread.start()

        # Iniciar servidor de registro em thread separada
        registration_thread = threading.Thread(
            target=self.start_registration_server, daemon=True
        )
        registration_thread.start()

        logger.info(f"Descoberta automática iniciada (intervalo: {interval}s)")

    def stop_auto_discovery(self):
        """Para descoberta automática"""
        self.running = False
        if self.registration_server:
            self.registration_server.shutdown()
        logger.info("Descoberta automática parada")

    def list_discovered_workers(self) -> Dict:
        """Lista todos os workers descobertos"""
        return {"discovered": self.discovered_workers, "known": self.known_workers}


def main():
    """Função principal para teste"""
    discovery = AutoDiscovery()

    print("🔍 CLUSTER AI - Sistema de Descoberta Automática")
    print("=" * 50)

    # Executar descoberta única
    results = discovery.discover_all()

    print(f"\n📊 Resultados da Descoberta:")
    for method, devices in results.items():
        print(f"  {method}: {len(devices)} dispositivos encontrados")

    print(f"\n🤖 Workers Registrados: {len(discovery.discovered_workers)}")
    for worker_id, info in discovery.discovered_workers.items():
        print(
            f"  • {worker_id}: {info.get('ip')} ({info.get('discovery_method', 'unknown')})"
        )

    # Atualizar configuração
    discovery.update_configuration()
    print("\n✅ Configuração atualizada!")
    print(f"📄 Arquivo: {discovery.nodes_file}")

    # Opção para iniciar descoberta automática
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "--auto":
        print("\n🚀 Iniciando descoberta automática...")
        discovery.start_auto_discovery(interval=60)  # 1 minuto para teste

        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            discovery.stop_auto_discovery()
            print("\n👋 Descoberta automática parada")


if __name__ == "__main__":
    main()
