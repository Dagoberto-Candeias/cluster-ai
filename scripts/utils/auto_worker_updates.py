#!/usr/bin/env python3
"""
Auto Worker Updates System
Automatically updates workers with latest project changes
"""

import hashlib
import json
import logging
import os
import subprocess
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import git
import paramiko
import yaml

# Setup logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


class AutoWorkerUpdates:
    def __init__(self):
        self.config_dir = Path.home() / ".cluster_config"
        self.config_file = self.config_dir / "nodes_list.conf"
        self.project_root = Path.cwd()
        self.checksum_file = self.config_dir / "project_checksum.txt"
        self.last_update_file = self.config_dir / "last_worker_update.txt"

        # Files/directories to sync (exclude patterns)
        self.exclude_patterns = [
            ".git",
            "__pycache__",
            "*.pyc",
            ".pytest_cache",
            "logs",
            "data",
            "models",
            "backups",
            "venv",
            "node_modules",
            ".vscode",
            "*.log",
            "nohup.out",
        ]

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

    def calculate_project_checksum(self) -> str:
        """Calculate checksum of project files"""
        checksums = []

        for file_path in self.project_root.rglob("*"):
            if file_path.is_file():
                # Check if file should be excluded
                should_exclude = False
                for pattern in self.exclude_patterns:
                    if pattern in str(file_path):
                        should_exclude = True
                        break

                if not should_exclude:
                    try:
                        with open(file_path, "rb") as f:
                            file_hash = hashlib.md5(f.read()).hexdigest()
                            checksums.append(
                                f"{file_path.relative_to(self.project_root)}:{file_hash}"
                            )
                    except:
                        pass  # Skip files that can't be read

        # Sort for consistent checksum
        checksums.sort()
        final_checksum = hashlib.md5("\n".join(checksums).encode()).hexdigest()
        return final_checksum

    def has_project_changed(self) -> bool:
        """Check if project has changed since last update"""
        current_checksum = self.calculate_project_checksum()

        if self.checksum_file.exists():
            with open(self.checksum_file, "r") as f:
                last_checksum = f.read().strip()

            if current_checksum == last_checksum:
                return False

        # Save new checksum
        with open(self.checksum_file, "w") as f:
            f.write(current_checksum)

        return True

    def get_git_changes(self) -> List[str]:
        """Get list of changed files from git"""
        try:
            repo = git.Repo(self.project_root)
            changed_files = []

            # Get staged and unstaged changes
            for item in repo.index.diff(None):
                changed_files.append(item.a_path)

            # Get untracked files
            for item in repo.untracked_files:
                changed_files.append(item)

            return changed_files
        except:
            return []

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
            ssh_key_file = Path.home() / ".ssh" / "id_rsa"
            if ssh_key_file.exists():
                client.connect(
                    ip,
                    port=port,
                    username=user,
                    key_filename=str(ssh_key_file),
                    timeout=10,
                )
                logger.info(f"✅ SSH connected to {hostname} ({ip}:{port}) using key")
                return client
            else:
                # Try passwordless
                client.connect(ip, port=port, username=user, timeout=10)
                logger.info(
                    f"✅ SSH connected to {hostname} ({ip}:{port}) passwordless"
                )
                return client

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

    def sync_project_to_worker(
        self, ssh_client: paramiko.SSHClient, hostname: str
    ) -> bool:
        """Sync project files to worker using rsync"""
        try:
            # Create exclude args for rsync
            exclude_args = []
            for pattern in self.exclude_patterns:
                exclude_args.extend(["--exclude", pattern])

            # Use rsync to sync project to worker
            worker_project_path = "~/cluster_ai_project"

            # Ensure worker directory exists
            self.execute_remote_command(ssh_client, f"mkdir -p {worker_project_path}")

            # Build rsync command
            rsync_cmd = (
                [
                    "rsync",
                    "-avz",
                    "--delete",
                    "--rsync-path",
                    f"mkdir -p {worker_project_path} && rsync",
                ]
                + exclude_args
                + [
                    "-e",
                    f"ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null",
                    f"{str(self.project_root)}/",
                    f"{os.getenv('USER', 'root')}@{hostname}:{worker_project_path}/",
                ]
            )

            logger.info(f"🔄 Syncing project to {hostname}...")
            stdout, stderr, returncode = self.run_command(
                rsync_cmd, timeout=300
            )  # 5 minutes timeout

            if returncode == 0:
                logger.info(f"✅ Project synced successfully to {hostname}")
                return True
            else:
                logger.error(f"❌ Failed to sync project to {hostname}: {stderr}")
                return False

        except Exception as e:
            logger.error(f"❌ Error syncing to {hostname}: {e}")
            return False

    def update_worker_services(
        self, ssh_client: paramiko.SSHClient, hostname: str
    ) -> bool:
        """Update and restart worker services"""
        try:
            worker_project_path = "~/cluster_ai_project"
            worker_dir = "~/cluster_worker"

            logger.info(f"🔄 Updating services on {hostname}...")

            # Stop existing worker service
            self.execute_remote_command(ssh_client, "pkill -f worker_service.py")

            # Update Python environment
            commands = [
                f"cd {worker_project_path}",
                "python3 -m venv venv --clear",
                "source venv/bin/activate",
                "pip install -r requirements.txt",
                f"mkdir -p {worker_dir}",
                f"cp -r * {worker_dir}/ 2>/dev/null || true",
            ]

            update_script = " && ".join(commands)
            output, error, returncode = self.execute_remote_command(
                ssh_client, update_script
            )

            if returncode != 0:
                logger.warning(f"⚠️  Some update steps failed on {hostname}: {error}")
                return False

            # Restart worker service
            scheduler_ip = self.get_scheduler_ip()
            start_cmd = f"cd {worker_dir} && source venv/bin/activate && nohup python worker_service.py {scheduler_ip} 8786 > worker.log 2>&1 &"

            output, error, returncode = self.execute_remote_command(
                ssh_client, start_cmd
            )

            if returncode == 0:
                logger.info(f"✅ Services updated and restarted on {hostname}")
                return True
            else:
                logger.error(f"❌ Failed to restart services on {hostname}: {error}")
                return False

        except Exception as e:
            logger.error(f"❌ Error updating services on {hostname}: {e}")
            return False

    def get_scheduler_ip(self) -> str:
        """Get the scheduler IP address"""
        scheduler_ip = os.getenv("DASK_SCHEDULER_IP")
        if scheduler_ip:
            return scheduler_ip

        # Get local IP
        try:
            import socket

            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
            s.close()
            return local_ip
        except:
            return "127.0.0.1"

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

    def update_all_workers(self) -> Dict[str, bool]:
        """Update all active workers with latest project changes"""
        if not self.has_project_changed():
            logger.info(
                "📋 Project unchanged since last update. Skipping worker updates."
            )
            return {}

        logger.info("🚀 Starting automatic worker updates...")

        workers = self.load_worker_config()
        results = {}

        for worker in workers:
            if worker["status"] == "active":
                success = self.update_worker(
                    worker["hostname"], worker["ip"], worker["port"], worker["user"]
                )
                results[worker["hostname"]] = success

        # Update timestamp
        with open(self.last_update_file, "w") as f:
            f.write(str(time.time()))

        # Summary
        successful = sum(1 for success in results.values() if success)
        total = len(results)

        logger.info(
            f"📊 Update complete: {successful}/{total} workers updated successfully"
        )

        return results

    def update_worker(
        self, hostname: str, ip: str, port: int = 22, user: str = None
    ) -> bool:
        """Update a single worker"""
        logger.info(f"🔄 Updating worker: {hostname} ({ip}:{port})")

        # Connect via SSH
        ssh_client = self.ssh_connect(hostname, ip, port, user)
        if not ssh_client:
            return False

        try:
            # Sync project files
            if not self.sync_project_to_worker(ssh_client, hostname):
                return False

            # Update services
            if not self.update_worker_services(ssh_client, hostname):
                return False

            logger.info(f"✅ Worker {hostname} updated successfully!")
            return True

        finally:
            ssh_client.close()


def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description="Auto Worker Updates System")
    parser.add_argument(
        "action", choices=["update", "check", "force"], help="Action to perform"
    )
    parser.add_argument("--worker", help="Specific worker hostname to update")

    args = parser.parse_args()

    updater = AutoWorkerUpdates()

    try:
        if args.action == "check":
            if updater.has_project_changed():
                print("🔄 Project has changes - workers need updates")
                sys.exit(1)
            else:
                print("✅ Project unchanged - no updates needed")
                sys.exit(0)

        elif args.action == "update" or args.action == "force":
            if args.action == "force":
                # Force update by removing checksum
                if updater.checksum_file.exists():
                    updater.checksum_file.unlink()

            results = updater.update_all_workers()

            if not results:
                print("ℹ️  No updates needed")
            else:
                successful = sum(1 for success in results.values() if success)
                total = len(results)
                print(f"📊 Updated {successful}/{total} workers")

                if successful < total:
                    sys.exit(1)

    except Exception as e:
        logger.error(f"Error during updates: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
