#!/usr/bin/env python3
"""
Smart Worker Discovery and Auto-Configuration System
Automatically discovers, configures, and manages cluster workers
"""

import ipaddress
import json
import logging
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import yaml

# Setup logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class SmartWorkerDiscovery:
    def __init__(self):
        self.config_dir = Path.home() / ".cluster_config"
        self.config_file = self.config_dir / "nodes_list.conf"
        self.yaml_config = Path("cluster.yaml")
        self.network_ranges = ["192.168.0.0/24", "10.0.0.0/24"]
        self.ssh_ports = [22, 8022, 2222]
        self.discovered_workers = {}

    def run_command(self, cmd: List[str], timeout: int = 30) -> Tuple[str, str, int]:
        """Run shell command with timeout"""
        try:
            result = subprocess.run(
                cmd, capture_output=True, text=True, timeout=timeout
            )
            return result.stdout, result.stderr, result.returncode
        except subprocess.TimeoutExpired:
            return "", "Command timed out", -1
        except Exception as e:
            return "", str(e), -1

    def ping_host(self, ip: str) -> bool:
        """Check if host is reachable via ping"""
        stdout, stderr, returncode = self.run_command(
            ["ping", "-c", "1", "-W", "2", ip]
        )
        return returncode == 0

    def test_ssh_connection(self, ip: str, port: int = 22, user: str = None) -> bool:
        """Test SSH connection to host"""
        if user is None:
            user = os.getenv("USER", "root")

        cmd = [
            "ssh",
            "-o",
            "BatchMode=yes",
            "-o",
            "ConnectTimeout=5",
            "-o",
            "StrictHostKeyChecking=no",
            "-p",
            str(port),
            f"{user}@{ip}",
            "echo 'SSH OK'",
        ]

        stdout, stderr, returncode = self.run_command(cmd, timeout=10)
        return returncode == 0

    def get_hostname_from_ip(self, ip: str) -> Optional[str]:
        """Get hostname from IP address"""
        try:
            import socket

            hostname = socket.gethostbyaddr(ip)[0]
            return hostname
        except:
            # Fallback to nslookup
            stdout, stderr, returncode = self.run_command(["nslookup", ip])
            if returncode == 0:
                for line in stdout.split("\n"):
                    if "name =" in line:
                        return line.split("=")[1].strip().rstrip(".")
            return None

    def scan_network_range(self, network_range: str) -> List[Dict]:
        """Scan a network range for potential workers"""
        logger.info(f"🔍 Scanning network: {network_range}")

        discovered = []
        try:
            network = ipaddress.ip_network(network_range)

            # Use nmap if available for faster scanning
            if self.is_tool_available("nmap"):
                return self.scan_with_nmap(network_range)
            else:
                return self.scan_with_ping(network)

        except Exception as e:
            logger.error(f"Error scanning network {network_range}: {e}")
            return []

    def scan_with_nmap(self, network_range: str) -> List[Dict]:
        """Scan network using nmap"""
        discovered = []

        # Scan for SSH services
        cmd = ["nmap", "-sn", "--host-timeout", "2s", network_range]
        stdout, stderr, returncode = self.run_command(cmd, timeout=60)

        if returncode == 0:
            for line in stdout.split("\n"):
                if "Nmap scan report" in line:
                    ip = line.split()[-1].strip("()")
                    if ip != self.get_local_ip():
                        hostname = self.get_hostname_from_ip(ip)

                        # Test SSH on common ports
                        for port in self.ssh_ports:
                            if self.test_ssh_connection(ip, port):
                                worker_info = {
                                    "hostname": hostname
                                    or f"worker-{ip.replace('.', '-')}",
                                    "ip": ip,
                                    "port": port,
                                    "user": os.getenv("USER", "root"),
                                    "status": "active",
                                    "discovered_at": time.time(),
                                }
                                discovered.append(worker_info)
                                logger.info(
                                    f"✅ Found SSH worker: {hostname or 'unknown'} ({ip}:{port})"
                                )
                                break

        return discovered

    def scan_with_ping(self, network) -> List[Dict]:
        """Scan network using ping (fallback method)"""
        discovered = []

        for ip in network.hosts():
            ip_str = str(ip)
            if ip_str == self.get_local_ip():
                continue

            if self.ping_host(ip_str):
                hostname = self.get_hostname_from_ip(ip_str)

                # Test SSH on common ports
                for port in self.ssh_ports:
                    if self.test_ssh_connection(ip_str, port):
                        worker_info = {
                            "hostname": hostname
                            or f"worker-{ip_str.replace('.', '-')}",
                            "ip": ip_str,
                            "port": port,
                            "user": os.getenv("USER", "root"),
                            "status": "active",
                            "discovered_at": time.time(),
                        }
                        discovered.append(worker_info)
                        logger.info(
                            f"✅ Found SSH worker: {hostname or 'unknown'} ({ip_str}:{port})"
                        )
                        break

        return discovered

    def get_local_ip(self) -> str:
        """Get local IP address"""
        try:
            import socket

            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
            s.close()
            return local_ip
        except:
            return "127.0.0.1"

    def is_tool_available(self, tool: str) -> bool:
        """Check if a tool is available"""
        stdout, stderr, returncode = self.run_command(["which", tool])
        return returncode == 0

    def load_existing_config(self) -> Dict[str, Dict]:
        """Load existing worker configuration"""
        existing_workers = {}

        if self.config_file.exists():
            with open(self.config_file, "r") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#"):
                        parts = line.split()
                        if len(parts) >= 5:
                            hostname = parts[0]
                            alias = parts[1]
                            ip = parts[2]
                            user = parts[3]
                            port = parts[4]
                            status = parts[5] if len(parts) > 5 else "inactive"
                            existing_workers[hostname] = {
                                "alias": alias,
                                "ip": ip,
                                "port": int(port),
                                "user": user,
                                "status": status,
                            }

        return existing_workers

    def update_worker_config(self, new_workers: List[Dict]):
        """Update worker configuration with newly discovered workers"""
        existing_workers = self.load_existing_config()

        # Ensure config directory exists
        self.config_dir.mkdir(parents=True, exist_ok=True)

        # Merge existing and new workers
        updated_workers = existing_workers.copy()

        for worker in new_workers:
            hostname = worker["hostname"]
            if hostname not in updated_workers:
                # New worker discovered
                updated_workers[hostname] = {
                    "alias": hostname.replace("-", "").replace("_", ""),
                    "ip": worker["ip"],
                    "port": worker["port"],
                    "user": worker["user"],
                    "status": worker["status"],
                }
                logger.info(
                    f"🆕 New worker added: {hostname} ({worker['ip']}:{worker['port']})"
                )
            else:
                # Check if IP changed
                existing_ip = updated_workers[hostname]["ip"]
                new_ip = worker["ip"]
                if existing_ip != new_ip:
                    logger.info(
                        f"🔄 Worker {hostname} IP changed: {existing_ip} -> {new_ip}"
                    )
                    updated_workers[hostname]["ip"] = new_ip

        # Write updated configuration
        with open(self.config_file, "w") as f:
            f.write(
                "# =============================================================================\n"
            )
            f.write("# Configuração de Workers - Gerado Automaticamente\n")
            f.write(f"# Atualizado em: {time.strftime('%a %d %b %Y %H:%M:%S %Z')}\n")
            f.write(
                "# =============================================================================\n"
            )
            f.write("\n")

            for hostname, config in updated_workers.items():
                f.write(
                    f"{hostname} {config['alias']} {config['ip']} {config['user']} {config['port']} {config['status']}\n"
                )

        logger.info(
            f"✅ Worker configuration updated: {len(updated_workers)} workers configured"
        )

        return updated_workers

    def sync_yaml_config(self):
        """Sync configuration to YAML format"""
        if not self.config_file.exists():
            logger.warning("Configuration file not found")
            return

        existing_workers = self.load_existing_config()

        # Convert to YAML format
        yaml_data = {"workers": {}}

        for hostname, config in existing_workers.items():
            yaml_data["workers"][hostname] = {
                "ip": config["ip"],
                "port": config["port"],
                "user": config["user"],
                "status": config["status"],
            }

        # Write YAML configuration
        with open(self.yaml_config, "w") as f:
            yaml.dump(yaml_data, f, default_flow_style=False, sort_keys=False)

        logger.info("✅ YAML configuration synchronized")

    def discover_and_configure(self):
        """Main discovery and configuration method"""
        logger.info("🚀 Starting smart worker discovery...")

        all_discovered = []

        # Scan all network ranges
        for network_range in self.network_ranges:
            discovered = self.scan_network_range(network_range)
            all_discovered.extend(discovered)

        if all_discovered:
            logger.info(f"📊 Discovery complete: {len(all_discovered)} workers found")

            # Update configuration
            updated_workers = self.update_worker_config(all_discovered)

            # Sync to YAML
            self.sync_yaml_config()

            # Report results
            logger.info("🎉 Smart discovery complete!")
            logger.info(f"   • Workers configured: {len(updated_workers)}")
            logger.info(f"   • New workers added: {len(all_discovered)}")

            return True
        else:
            logger.info("⚠️  No new workers discovered")
            return False


def main():
    """Main entry point"""
    try:
        discovery = SmartWorkerDiscovery()
        success = discovery.discover_and_configure()

        if success:
            print("\n✅ Worker discovery and configuration completed successfully!")
        else:
            print("\n⚠️  No changes made to worker configuration")

    except Exception as e:
        logger.error(f"Error during worker discovery: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
