#!/usr/bin/env python3
"""
Auto Worker Provisioning System
Automatically provisions and configures discovered workers
"""

import subprocess
import json
import yaml
import os
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import logging
import paramiko
import socket

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class AutoWorkerProvisioning:
    def __init__(self):
        self.config_dir = Path.home() / ".cluster_config"
        self.config_file = self.config_dir / "nodes_list.conf"
        self.yaml_config = Path("cluster.yaml")
        # Try cluster_ai_key first, fallback to id_rsa
        cluster_key = Path.home() / ".ssh" / "cluster_ai_key"
        id_rsa_key = Path.home() / ".ssh" / "id_rsa"
        self.ssh_key_file = cluster_key if cluster_key.exists() else id_rsa_key
        self.project_root = Path.cwd()

        # Worker requirements
        self.required_packages = [
            "python3", "python3-pip", "python3-venv",
            "dask", "distributed", "paramiko"
        ]

        self.worker_setup_script = """
#!/bin/bash
# Auto worker setup script

set -e

echo "🚀 Setting up Cluster AI Worker..."

# Detect environment and install system dependencies
if command -v pkg >/dev/null 2>&1; then
    # Android/Termux - check first since it might have apt-get but we want pkg
    echo "📱 Detected Termux environment"
    pkg update
    pkg install -y python python-pip
elif command -v apt-get >/dev/null 2>&1; then
    # Ubuntu/Debian
    echo "🐧 Detected Ubuntu/Debian environment"
    apt-get update
    apt-get install -y python3 python3-pip python3-venv
elif command -v yum >/dev/null 2>&1; then
    # CentOS/RHEL
    echo "🐧 Detected CentOS/RHEL environment"
    yum install -y python3 python3-pip
elif command -v apk >/dev/null 2>&1; then
    # Alpine Linux
    echo "🐧 Detected Alpine Linux environment"
    apk add python3 py3-pip
else
    echo "❌ Unsupported package manager. Please install Python manually."
    exit 1
fi

# Create worker directory
mkdir -p ~/cluster_worker
cd ~/cluster_worker

# Setup Python environment
if command -v python3 >/dev/null 2>&1; then
    python3 -m venv venv
    source venv/bin/activate
elif command -v python >/dev/null 2>&1; then
    # Android/Termux
    python -m venv venv
    source venv/bin/activate
else
    echo "❌ Python not found. Please install Python first."
    exit 1
fi

# Install Python packages
pip install dask distributed paramiko

# Create worker service script
cat > worker_service.py << 'EOF'
#!/usr/bin/env python3
import sys
import time
import socket
from distributed import Worker
import logging

logging.basicConfig(level=logging.INFO)

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

def start_worker(scheduler_ip, scheduler_port=8786):
    local_ip = get_local_ip()
    worker = Worker(f"tcp://{scheduler_ip}:{scheduler_port}")
    print(f"Worker started on {local_ip}, connected to {scheduler_ip}:{scheduler_port}")
    worker.start()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python worker_service.py <scheduler_ip> [scheduler_port]")
        sys.exit(1)

    scheduler_ip = sys.argv[1]
    scheduler_port = int(sys.argv[2]) if len(sys.argv) > 2 else 8786

    try:
        start_worker(scheduler_ip, scheduler_port)
    except KeyboardInterrupt:
        print("Worker stopped")
    except Exception as e:
        print(f"Error starting worker: {e}")
        sys.exit(1)
EOF

chmod +x worker_service.py

echo "✅ Worker setup completed!"
"""

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

    def get_scheduler_ip(self) -> str:
        """Get the scheduler IP address"""
        # Try to get from environment or configuration
        scheduler_ip = os.getenv("DASK_SCHEDULER_IP")
        if scheduler_ip:
            return scheduler_ip

        # Get local IP
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
            s.close()
            return local_ip
        except:
            return "127.0.0.1"

    def ssh_connect(self, hostname: str, ip: str, port: int = 22, user: str = None) -> Optional[paramiko.SSHClient]:
        """Establish SSH connection to worker"""
        if user is None:
            user = os.getenv("USER", "root")

        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        try:
            # Try with SSH key first
            if self.ssh_key_file.exists():
                client.connect(ip, port=port, username=user, key_filename=str(self.ssh_key_file), timeout=10)
                logger.info(f"✅ SSH connected to {hostname} ({ip}:{port}) using key")
                return client
            else:
                # Try passwordless (for Android devices)
                client.connect(ip, port=port, username=user, timeout=10)
                logger.info(f"✅ SSH connected to {hostname} ({ip}:{port}) passwordless")
                return client

        except paramiko.AuthenticationException:
            logger.warning(f"❌ SSH authentication failed for {hostname} ({ip}:{port})")
            return None
        except Exception as e:
            logger.error(f"❌ SSH connection failed for {hostname} ({ip}:{port}): {e}")
            return None

    def execute_remote_command(self, ssh_client: paramiko.SSHClient, command: str) -> Tuple[str, str, int]:
        """Execute command on remote host"""
        try:
            stdin, stdout, stderr = ssh_client.exec_command(command, timeout=60)
            output = stdout.read().decode('utf-8')
            error = stderr.read().decode('utf-8')
            returncode = stdout.channel.recv_exit_status()
            return output, error, returncode
        except Exception as e:
            return "", str(e), -1

    def upload_file(self, ssh_client: paramiko.SSHClient, local_path: str, remote_path: str) -> bool:
        """Upload file to remote host"""
        try:
            sftp = ssh_client.open_sftp()
            sftp.put(local_path, remote_path)
            sftp.close()
            return True
        except Exception as e:
            logger.error(f"Failed to upload {local_path} to {remote_path}: {e}")
            return False

    def provision_worker(self, hostname: str, ip: str, port: int = 22, user: str = None) -> bool:
        """Provision a single worker"""
        logger.info(f"🔧 Provisioning worker: {hostname} ({ip}:{port})")

        # Connect via SSH
        ssh_client = self.ssh_connect(hostname, ip, port, user)
        if not ssh_client:
            return False

        try:
            # Upload setup script
            timestamp = int(time.time())
            # Use home directory for temp script on remote since /tmp does not exist
            # Get absolute home path for Android/Termux
            home_path_output, _, _ = self.execute_remote_command(ssh_client, "echo $HOME")
            home_path = home_path_output.strip() if home_path_output else "/data/data/com.termux/files/home"
            setup_script_path = f"{home_path}/cluster_worker_setup_{timestamp}.sh"
            temp_script_path = f"/tmp/remote_setup_{timestamp}.sh"

            logger.info(f"Creating temp script at: {temp_script_path}")

            # Create temporary setup script locally
            try:
                with open(temp_script_path, "w") as f:
                    f.write(self.worker_setup_script)
                os.chmod(temp_script_path, 0o755)
                logger.info(f"✅ Temp script created successfully, size: {os.path.getsize(temp_script_path)} bytes")
            except Exception as e:
                logger.error(f"❌ Failed to create temp script: {e}")
                return False

            # Verify file exists before upload
            if not os.path.exists(temp_script_path):
                logger.error(f"❌ Temp script file does not exist: {temp_script_path}")
                return False

            logger.info(f"Uploading {temp_script_path} to {setup_script_path}")
            if not self.upload_file(ssh_client, temp_script_path, setup_script_path):
                # Clean up local temp file
                os.remove(temp_script_path)
                return False

            # Clean up local temp file
            os.remove(temp_script_path)
            logger.info("✅ Temp script uploaded and cleaned up successfully")

            # Execute setup script
            logger.info(f"📦 Installing dependencies on {hostname}...")
            # Try running without sudo first, then with sudo if fails
            output, error, returncode = self.execute_remote_command(
                ssh_client, f"bash {setup_script_path} || sudo bash {setup_script_path}"
            )

            if returncode != 0:
                logger.error(f"Failed to setup worker {hostname}: {error}")
                return False

            # Get scheduler IP
            scheduler_ip = self.get_scheduler_ip()

            # Start worker service
            logger.info(f"🚀 Starting worker service on {hostname}...")
            worker_cmd = f"cd ~/cluster_worker && source venv/bin/activate && python worker_service.py {scheduler_ip} 8786"
            output, error, returncode = self.execute_remote_command(
                ssh_client, f"nohup {worker_cmd} > worker.log 2>&1 &"
            )

            if returncode != 0:
                logger.warning(f"Failed to start worker service on {hostname}: {error}")
            else:
                logger.info(f"✅ Worker {hostname} provisioned and started successfully!")

            # Clean up
            self.execute_remote_command(ssh_client, f"rm -f {setup_script_path}")

            return True

        finally:
            ssh_client.close()

    def load_worker_config(self) -> List[Dict]:
        """Load worker configuration"""
        workers = []

        if self.config_file.exists():
            with open(self.config_file, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#'):
                        parts = line.split()
                        if len(parts) >= 5:
                            hostname = parts[0]
                            alias = parts[1]
                            ip = parts[2]
                            user = parts[3]
                            port = int(parts[4])
                            status = parts[5] if len(parts) > 5 else "inactive"

                            workers.append({
                                "hostname": hostname,
                                "alias": alias,
                                "ip": ip,
                                "port": port,
                                "user": user,
                                "status": status
                            })

        return workers

    def provision_all_workers(self) -> Dict[str, bool]:
        """Provision all configured workers"""
        logger.info("🚀 Starting auto-provisioning of all workers...")

        workers = self.load_worker_config()
        results = {}

        for worker in workers:
            if worker["status"] == "active":
                success = self.provision_worker(
                    worker["hostname"],
                    worker["ip"],
                    worker["port"],
                    worker["user"]
                )
                results[worker["hostname"]] = success

                if success:
                    logger.info(f"✅ Successfully provisioned {worker['hostname']}")
                else:
                    logger.error(f"❌ Failed to provision {worker['hostname']}")

        # Summary
        successful = sum(1 for success in results.values() if success)
        total = len(results)

        logger.info(f"📊 Provisioning complete: {successful}/{total} workers provisioned successfully")

        return results

    def check_worker_status(self, hostname: str, ip: str, port: int = 22, user: str = None) -> str:
        """Check if worker is properly provisioned and running"""
        ssh_client = self.ssh_connect(hostname, ip, port, user)
        if not ssh_client:
            return "disconnected"

        try:
            # Check if worker directory exists
            output, error, returncode = self.execute_remote_command(
                ssh_client, "ls -la ~/cluster_worker/"
            )

            if returncode != 0:
                return "not_provisioned"

            # Check if worker process is running
            output, error, returncode = self.execute_remote_command(
                ssh_client, "pgrep -f worker_service.py"
            )

            if returncode == 0:
                return "running"
            else:
                return "provisioned_but_stopped"

        finally:
            ssh_client.close()

def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description="Auto Worker Provisioning System")
    parser.add_argument("action", choices=["provision", "status", "all"],
                       help="Action to perform")
    parser.add_argument("--worker", help="Specific worker hostname to provision")
    parser.add_argument("--ip", help="Worker IP address")
    parser.add_argument("--port", type=int, default=22, help="SSH port")
    parser.add_argument("--user", help="SSH username")

    args = parser.parse_args()

    provisioner = AutoWorkerProvisioning()

    try:
        if args.action == "provision":
            if args.worker and args.ip:
                success = provisioner.provision_worker(
                    args.worker, args.ip, args.port, args.user
                )
                if success:
                    print(f"✅ Worker {args.worker} provisioned successfully!")
                else:
                    print(f"❌ Failed to provision worker {args.worker}")
                    sys.exit(1)
            else:
                results = provisioner.provision_all_workers()
                successful = sum(1 for success in results.values() if success)
                total = len(results)
                print(f"📊 Provisioned {successful}/{total} workers successfully")

        elif args.action == "status":
            workers = provisioner.load_worker_config()
            print("Worker Status Report:")
            print("=" * 50)

            for worker in workers:
                if worker["status"] == "active":
                    status = provisioner.check_worker_status(
                        worker["hostname"], worker["ip"],
                        worker["port"], worker["user"]
                    )
                    print(f"{worker['hostname']:<20} {worker['ip']:<15} {worker['port']:<6} {status}")

        elif args.action == "all":
            # Discover and provision all
            print("🔍 Discovering workers...")
            # This would integrate with smart discovery
            print("🔧 Provisioning workers...")
            results = provisioner.provision_all_workers()

    except Exception as e:
        logger.error(f"Error during provisioning: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
