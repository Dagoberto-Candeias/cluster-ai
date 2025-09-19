#!/bin/bash
# =============================================================================
# Instalação do CUDA no Debian 13 (Trixie) - NVIDIA GPUs
# =============================================================================
# Autor: ChatGPT
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: install_cuda.sh
# =============================================================================

#!/usr/bin/env bash
# Instalação do CUDA no Debian 13 (Trixie) - NVIDIA GPUs
# Autor: ChatGPT
# Última atualização: 2025-08-26
set -euo pipefail

LOG_DIR="/var/log/cuda-install"
mkdir -p "$LOG_DIR"

echo "[INFO] Atualizando sistema..."
sudo apt update && sudo apt upgrade -y | tee "$LOG_DIR/apt-upgrade.log"

echo "[INFO] Instalando dependências..."
sudo apt install -y wget curl gnupg software-properties-common     build-essential dkms linux-headers-$(uname -r) | tee "$LOG_DIR/deps.log"

echo "[INFO] Adicionando chave pública NVIDIA..."
wget https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/cuda-keyring_1.1-1_all.deb -O /tmp/cuda-keyring.deb
sudo dpkg -i /tmp/cuda-keyring.deb
sudo apt update | tee "$LOG_DIR/apt-update.log"

echo "[INFO] Instalando CUDA Toolkit..."
sudo apt install -y cuda | tee "$LOG_DIR/cuda-install.log"

echo "[INFO] Configurando variáveis de ambiente..."
if ! grep -q "/usr/local/cuda/bin" ~/.bashrc; then
cat << 'EOF' >> ~/.bashrc

# CUDA Environment
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
EOF
fi

echo "[INFO] Instalação concluída!"
echo "Reinicie o sistema e valide com: nvidia-smi && nvcc --version"
