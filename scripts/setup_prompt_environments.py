#!/usr/bin/env python3
"""
Script to configure prompt with Git branch display for Spyder and PyCharm
"""

import os
import subprocess
import sys
from pathlib import Path


def get_git_branch():
    """Get current Git branch name"""
    try:
        result = subprocess.run(
            ["git", "branch", "--show-current"],
            capture_output=True,
            text=True,
            cwd=os.getcwd(),
        )
        if result.returncode == 0 and result.stdout.strip():
            return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    return ""


def get_venv_name():
    """Get virtual environment name"""
    venv = os.environ.get("VIRTUAL_ENV")
    if venv:
        return os.path.basename(venv)
    return ""


def setup_spyder_prompt():
    """Configure Spyder to use custom prompt"""
    # Spyder uses PYTHONSTARTUP and environment variables
    startup_script = f"""
import sys
import os

def get_git_branch():
    import subprocess
    try:
        result = subprocess.run(
            ['git', 'branch', '--show-current'],
            capture_output=True,
            text=True,
            cwd=os.getcwd()
        )
        if result.returncode == 0 and result.stdout.strip():
            return f"({{result.stdout.strip()}})"
    except:
        pass
    return ""

def get_venv_name():
    venv = os.environ.get('VIRTUAL_ENV')
    if venv:
        return f"({{os.path.basename(venv)}})"
    return ""

class GitPrompt:
    def __init__(self):
        self.branch = get_git_branch()
        self.venv = get_venv_name()

    def __str__(self):
        parts = []
        if self.branch:
            parts.append(f"\\033[33m{{self.branch}}\\033[0m")
        parts.append("$")
        if self.venv:
            parts.append(f"\\033[35m{{self.venv}}\\033[0m")
        return " ".join(parts)

sys.ps1 = GitPrompt()
sys.ps2 = "\\033[34m... \\033[0m"
"""

    # Write startup script for Spyder
    spyder_startup = Path.home() / ".spyder_startup.py"
    spyder_startup.write_text(startup_script)

    # Set environment variable for Spyder
    os.environ["PYTHONSTARTUP"] = str(spyder_startup)

    print("✅ Spyder prompt configured")


def setup_pycharm_prompt():
    """Configure PyCharm to use custom prompt"""
    # PyCharm uses environment variables and startup scripts
    startup_script = f"""
import sys
import os

def get_git_branch():
    import subprocess
    try:
        result = subprocess.run(
            ['git', 'branch', '--show-current'],
            capture_output=True,
            text=True,
            cwd=os.getcwd()
        )
        if result.returncode == 0 and result.stdout.strip():
            return f"({{result.stdout.strip()}})"
    except:
        pass
    return ""

def get_venv_name():
    venv = os.environ.get('VIRTUAL_ENV')
    if venv:
        return f"({{os.path.basename(venv)}})"
    return ""

class GitPrompt:
    def __init__(self):
        self.branch = get_git_branch()
        self.venv = get_venv_name()

    def __str__(self):
        parts = []
        if self.branch:
            parts.append(f"\\033[33m{{self.branch}}\\033[0m")
        parts.append("$")
        if self.venv:
            parts.append(f"\\033[35m{{self.venv}}\\033[0m")
        return " ".join(parts)

sys.ps1 = GitPrompt()
sys.ps2 = "\\033[34m... \\033[0m"
"""

    # Write startup script for PyCharm
    pycharm_startup = Path.home() / ".pycharm_startup.py"
    pycharm_startup.write_text(startup_script)

    # Set environment variable for PyCharm
    os.environ["PYTHONSTARTUP"] = str(pycharm_startup)

    print("✅ PyCharm prompt configured")


def create_postactivate_script():
    """Create postactivate script for virtual environments"""
    postactivate_content = """#!/bin/bash
# Post-activate script for virtual environments
# This script is executed after activating a virtual environment

# Configure prompt for IDEs
python3 /home/dcm/Projetos/cluster-ai/scripts/setup_prompt_environments.py

# Set PYTHONSTARTUP for all Python sessions
export PYTHONSTARTUP="$HOME/.pythonrc"

echo "🔧 Ambiente virtual configurado com prompt personalizado"
"""

    # Find all virtual environments and add postactivate script
    venv_dirs = []
    for root in ["/home/dcm/Projetos", "/home/dcm"]:
        if os.path.exists(root):
            for dirpath, dirnames, filenames in os.walk(root):
                if "bin/activate" in filenames:
                    venv_dirs.append(dirpath)

    for venv_dir in venv_dirs:
        postactivate_path = os.path.join(venv_dir, "bin", "postactivate")
        try:
            with open(postactivate_path, "w") as f:
                f.write(postactivate_content)
            os.chmod(postactivate_path, 0o755)
            print(f"✅ Post-activate configurado: {venv_dir}")
        except Exception as e:
            print(f"❌ Erro ao configurar {venv_dir}: {e}")


def main():
    """Main setup function"""
    print("🚀 Configurando prompt personalizado para IDEs...")

    setup_spyder_prompt()
    setup_pycharm_prompt()
    create_postactivate_script()

    print("\\n✅ Configuração concluída!")
    print("📝 Reinicie o Spyder e PyCharm para aplicar as mudanças")
    print("🔄 Ou ative/desative o ambiente virtual para aplicar imediatamente")


if __name__ == "__main__":
    main()
