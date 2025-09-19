#!/bin/bash
# =============================================================================
# Instalação do ROCm no Debian 13 (Trixie) - AMD GPUs
# =============================================================================
# Autor: ChatGPT
#
# Autor: Cluster AI Team
# Data: 2025-09-19
# Versão: 1.0.0
# Arquivo: install_rocm.sh
# =============================================================================

#!/usr/bin/env bash
# Instalação do ROCm no Debian 13 (Trixie) - AMD GPUs
# Autor: ChatGPT
# Última atualização: 2025-08-26
set -euo pipefail

LOG_DIR="/var/log/rocm-install"
mkdir -p "$LOG_DIR"

echo "[INFO] Atualizando sistema..."
sudo apt update && sudo apt upgrade -y | tee "$LOG_DIR/apt-upgrade.log"

echo "[INFO] Instalando dependências..."
sudo apt install -y wget curl gnupg2 software-properties-common     build-essential dkms linux-headers-$(uname -r) | tee "$LOG_DIR/deps.log"

echo "[INFO] Adicionando chave pública ROCm..."
wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/rocm.gpg

echo "[INFO] Configurando repositório ROCm..."
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/rocm.gpg] http://repo.radeon.com/rocm/apt/latest/ ubuntu main"     | sudo tee /etc/apt/sources.list.d/rocm.list

echo "[INFO] Atualizando repositórios..."
sudo apt update | tee "$LOG_DIR/apt-update.log"

echo "[INFO] Instalando ROCm..."
sudo apt install -y rocm-dev rocm-utils | tee "$LOG_DIR/rocm-install.log"

echo "[INFO] Configurando variáveis de ambiente..."
if ! grep -q "ROCM_PATH" ~/.bashrc; then
cat << 'EOF' >> ~/.bashrc

# ROCm Environment
export ROCM_PATH=/opt/rocm
export PATH=$ROCM_PATH/bin:$PATH
export LD_LIBRARY_PATH=$ROCM_PATH/lib:$ROCM_PATH/lib64:$LD_LIBRARY_PATH
EOF
fi

echo "[INFO] Instalação concluída!"
echo "Reinicie o sistema e valide com: /opt/rocm/bin/rocminfo"
