#!/usr/bin/env python3
"""
Auto Worker Provisioning System
Automatically provisions and configures discovered workers
"""

import json
import logging
import os
import socket
import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import paramiko
import yaml

# Setup logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
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
            "python3",
            "python3-pip",
            "python3-venv",
            "dask",
            "distributed",
            "paramiko",
        ]

        # Use external setup script instead of embedded one
        self.worker_setup_script_path = (
            self.project_root / "scripts" / "android" / "setup_worker_remote.sh"
        )
        if not self.worker_setup_script_path.exists():
            # Fallback to creating a simple setup script
            self.worker_setup_script = self._create_simple_setup_script()
        else:
            with open(self.worker_setup_script_path, "r") as f:
                self.worker_setup_script = f.read()

    def _create_simple_setup_script(self):
        """Create a simple setup script without complex embedded Python"""
        return """#!/bin/bash
# Simple worker setup script

set -e

echo "🚀 Setting up Cluster AI Worker..."

# Create worker directory
mkdir -p ~/cluster_worker
cd ~/cluster_worker

# Worker service script should already be uploaded
if [ -f "worker_service_manual.py" ]; then
    chmod +x worker_service_manual.py
    echo "✅ Worker service script ready"
else
    echo "❌ Worker service script not found"
    exit 1
fi

# Create virtual environment and install dependencies
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install dask distributed paramiko

echo "✅ Worker setup completed!"
echo "📝 To start the worker, run: python worker_service_manual.py <scheduler_ip> [port]"
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

    def ssh_connect(
        self, hostname: str, ip: str, port: int = 22, user: str = None
    ) -> Optional[paramiko.SSHClient]:
        """Establish SSH connection to worker"""
        if user is None:
            user = os.getenv("USER", "root")

        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

        try:
            # Try with SSH key first
            if self.ssh_key_file.exists():
                client.connect(
                    ip,
                    port=port,
                    username=user,
                    key_filename=str(self.ssh_key_file),
                    timeout=10,
                )
                logger.info(f"✅ SSH connected to {hostname} ({ip}:{port}) using key")
                return client
            else:
                # Try passwordless (for Android devices)
                client.connect(ip, port=port, username=user, timeout=10)
                logger.info(
                    f"✅ SSH connected to {hostname} ({ip}:{port}) passwordless"
                )
                return client

        except paramiko.AuthenticationException:
            logger.warning(f"❌ SSH authentication failed for {hostname} ({ip}:{port})")
            return None
        except Exception as e:
            logger.error(f"❌ SSH connection failed for {hostname} ({ip}:{port}): {e}")
            return None

    def execute_remote_command(
        self, ssh_client: paramiko.SSHClient, command: str
    ) -> Tuple[str, str, int]:
        """Execute command on remote host"""
        try:
            stdin, stdout, stderr = ssh_client.exec_command(command, timeout=60)
            output = stdout.read().decode("utf-8")
            error = stderr.read().decode("utf-8")
            returncode = stdout.channel.recv_exit_status()
            return output, error, returncode
        except Exception as e:
            return "", str(e), -1

    def upload_file(
        self, ssh_client: paramiko.SSHClient, local_path: str, remote_path: str
    ) -> bool:
        """Upload file to remote host"""
        try:
            sftp = ssh_client.open_sftp()
            sftp.put(local_path, remote_path)
            sftp.close()
            return True
        except Exception as e:
            logger.error(f"Failed to upload {local_path} to {remote_path}: {e}")
            return False

    def provision_worker(
        self, hostname: str, ip: str, port: int = 22, user: str = None
    ) -> bool:
        """Provision a single worker"""
        logger.info(f"🔧 Provisioning worker: {hostname} ({ip}:{port})")

        # Connect via SSH
        ssh_client = self.ssh_connect(hostname, ip, port, user)
        if not ssh_client:
            return False

        try:
            # Get remote home directory
            output, error, returncode = self.execute_remote_command(
                ssh_client, "echo $HOME"
            )
            if returncode != 0:
                logger.error(f"Failed to get remote home directory: {error}")
                return False
            remote_home = output.strip()

            # Create worker directory on remote host
            remote_worker_dir = f"{remote_home}/cluster_worker"
            output, error, returncode = self.execute_remote_command(
                ssh_client, f"mkdir -p {remote_worker_dir}"
            )
            if returncode != 0:
                logger.error(f"Failed to create worker directory: {error}")
                return False

            # Upload worker service script first
            worker_script_path = self.project_root / "worker_service_manual.py"
            if worker_script_path.exists():
                remote_worker_path = f"{remote_worker_dir}/worker_service_manual.py"
                if not self.upload_file(
                    ssh_client, str(worker_script_path), remote_worker_path
                ):
                    logger.error("Failed to upload worker service script")
                    return False
                # Make it executable
                self.execute_remote_command(
                    ssh_client, f"chmod +x {remote_worker_path}"
                )
                logger.info("✅ Worker service script uploaded")
            else:
                logger.error("Worker service script not found locally")
                return False

            # Create and upload setup script
            timestamp = int(time.time())
            setup_script_path = f"{remote_home}/cluster_worker_setup_{timestamp}.sh"

            # Write setup script to remote host
            output, error, returncode = self.execute_remote_command(
                ssh_client,
                f"cat > {setup_script_path} << 'EOF'\n{self.worker_setup_script}\nEOF",
            )

            if returncode != 0:
                logger.error(f"Failed to create setup script: {error}")
                return False

            # Make it executable and run it
            output, error, returncode = self.execute_remote_command(
                ssh_client,
                f"chmod +x {setup_script_path} && PROJECT_DIR={self.project_root} bash {setup_script_path}",
            )

            if returncode != 0:
                logger.error(f"Failed to setup worker {hostname}: {error}")
                return False

            # Start worker service
            logger.info(f"🚀 Starting worker service on {hostname}...")
            success = self.start_worker_service(ssh_client, hostname)
            if success:
                logger.info(
                    f"✅ Worker {hostname} provisioned and started successfully!"
                )
            else:
                logger.warning(
                    f"⚠️ Worker {hostname} provisioned but failed to start service"
                )

            # Clean up
            self.execute_remote_command(ssh_client, f"rm -f {setup_script_path}")

            return True

        finally:
            ssh_client.close()

    def start_worker_service(
        self, ssh_client: paramiko.SSHClient, hostname: str
    ) -> bool:
        """Start worker service on remote host"""
        try:
            # Get remote home directory
            output, error, returncode = self.execute_remote_command(
                ssh_client, "echo $HOME"
            )
            if returncode != 0:
                logger.error(f"Failed to get remote home directory: {error}")
                return False
            remote_home = output.strip()
            remote_worker_dir = f"{remote_home}/cluster_worker"

            # Get scheduler IP
            scheduler_ip = self.get_scheduler_ip()

            # Create a startup script
            startup_script = f"""#!/bin/bash
cd {remote_worker_dir} || exit 1
source venv/bin/activate || exit 1
export PYTHONPATH=$PYTHONPATH:{remote_worker_dir}
python worker_service_manual.py {scheduler_ip} 8786 > worker.log 2>&1 &
echo $! > worker.pid
"""

            # Upload and execute startup script
            timestamp = int(time.time())
            startup_path = f"{remote_home}/worker_startup_{timestamp}.sh"

            # Write startup script to remote host
            output, error, returncode = self.execute_remote_command(
                ssh_client, f"cat > {startup_path} << 'EOF'\n{startup_script}\nEOF"
            )

            if returncode != 0:
                logger.error(f"Failed to create startup script: {error}")
                return False

            # Make it executable and run it
            output, error, returncode = self.execute_remote_command(
                ssh_client, f"chmod +x {startup_path} && bash {startup_path}"
            )

            if returncode != 0:
                logger.warning(f"Failed to start worker service: {error}")
                # Clean up startup script
                self.execute_remote_command(ssh_client, f"rm -f {startup_path}")
                return False

            # Clean up startup script
            self.execute_remote_command(ssh_client, f"rm -f {startup_path}")

            # Verify worker is running
            time.sleep(2)  # Give it time to start
            output, error, returncode = self.execute_remote_command(
                ssh_client, "pgrep -f worker_service_manual.py"
            )

            return returncode == 0

        except Exception as e:
            logger.error(f"Error starting worker service: {e}")
            return False

    def start_worker(
        self, hostname: str, ip: str, port: int = 22, user: str = None
    ) -> bool:
        """Start a worker that is already provisioned but stopped"""
        logger.info(f"🚀 Starting worker: {hostname} ({ip}:{port})")

        ssh_client = self.ssh_connect(hostname, ip, port, user)
        if not ssh_client:
            return False

        try:
            # Get remote home directory
            output, error, returncode = self.execute_remote_command(
                ssh_client, "echo $HOME"
            )
            if returncode != 0:
                logger.error(f"Failed to get remote home directory: {error}")
                return False
            remote_home = output.strip()
            remote_worker_dir = f"{remote_home}/cluster_worker"

            # Check if worker is already provisioned
            output, error, returncode = self.execute_remote_command(
                ssh_client, f"ls -la {remote_worker_dir}/"
            )

            if returncode != 0:
                logger.error(f"Worker {hostname} is not provisioned")
                return False

            # Check if worker is already running
            output, error, returncode = self.execute_remote_command(
                ssh_client, "pgrep -f worker_service_manual.py"
            )

            if returncode == 0:
                logger.info(f"Worker {hostname} is already running")
                return True

            # Start the worker service
            success = self.start_worker_service(ssh_client, hostname)
            if success:
                logger.info(f"✅ Worker {hostname} started successfully!")
            else:
                logger.error(f"❌ Failed to start worker {hostname}")

            return success

        finally:
            ssh_client.close()

    def load_worker_config(self) -> List[Dict]:
        """Load worker configuration"""
        workers = []

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
                            port = int(parts[4])
                            status = parts[5] if len(parts) > 5 else "inactive"

                            workers.append(
                                {
                                    "hostname": hostname,
                                    "alias": alias,
                                    "ip": ip,
                                    "port": port,
                                    "user": user,
                                    "status": status,
                                }
                            )

        return workers

    def provision_all_workers(self) -> Dict[str, bool]:
        """Provision all configured workers"""
        logger.info("🚀 Starting auto-provisioning of all workers...")

        workers = self.load_worker_config()
        results = {}

        for worker in workers:
            if worker["status"] == "active":
                success = self.provision_worker(
                    worker["hostname"], worker["ip"], worker["port"], worker["user"]
                )
                results[worker["hostname"]] = success

                if success:
                    logger.info(f"✅ Successfully provisioned {worker['hostname']}")
                else:
                    logger.error(f"❌ Failed to provision {worker['hostname']}")

        # Summary
        successful = sum(1 for success in results.values() if success)
        total = len(results)

        logger.info(
            f"📊 Provisioning complete: {successful}/{total} workers provisioned successfully"
        )

        return results

    def check_worker_status(
        self, hostname: str, ip: str, port: int = 22, user: str = None
    ) -> str:
        """Check if worker is properly provisioned and running"""
        ssh_client = self.ssh_connect(hostname, ip, port, user)
        if not ssh_client:
            return "disconnected"

        try:
            # Get remote home directory
            output, error, returncode = self.execute_remote_command(
                ssh_client, "echo $HOME"
            )
            if returncode != 0:
                return "error_getting_home"
            remote_home = output.strip()
            remote_worker_dir = f"{remote_home}/cluster_worker"

            # Check if worker directory exists
            output, error, returncode = self.execute_remote_command(
                ssh_client, f"ls -la {remote_worker_dir}/"
            )

            if returncode != 0:
                return "not_provisioned"

            # Check if worker process is running
            output, error, returncode = self.execute_remote_command(
                ssh_client, "pgrep -f worker_service_manual.py"
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
    parser.add_argument(
        "action",
        choices=["provision", "status", "all", "start"],
        help="Action to perform",
    )
    parser.add_argument("--worker", help="Specific worker hostname to provision/start")
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
                        worker["hostname"], worker["ip"], worker["port"], worker["user"]
                    )
                    print(
                        f"{worker['hostname']:<20} {worker['ip']:<15} {worker['port']:<6} {status}"
                    )

        elif args.action == "start":
            if args.worker and args.ip:
                success = provisioner.start_worker(
                    args.worker, args.ip, args.port, args.user
                )
                if success:
                    print(f"✅ Worker {args.worker} started successfully!")
                else:
                    print(f"❌ Failed to start worker {args.worker}")
                    sys.exit(1)
            else:
                print("❌ Worker hostname and IP required for start action")
                sys.exit(1)

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
