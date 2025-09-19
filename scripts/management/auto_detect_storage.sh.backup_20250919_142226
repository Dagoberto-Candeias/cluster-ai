#!/bin/bash
# Script para detectar e configurar automaticamente dispositivos de armazenamento externos
# para uso como memória auxiliar no Cluster AI

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/cluster.conf"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função de log
log() {
    echo -e "${BLUE}[AUTO-STORAGE]${NC} $1"
}

success() {
    echo -e "${GREEN}[AUTO-STORAGE]${NC} ✅ $1"
}

warn() {
    echo -e "${YELLOW}[AUTO-STORAGE]${NC} ⚠️  $1"
}

error() {
    echo -e "${RED}[AUTO-STORAGE]${NC} ❌ $1"
}

# Função para detectar dispositivos externos
detect_external_devices() {
    log "Detectando dispositivos de armazenamento externos..."

    # Lista dispositivos não montados ou montados externamente
    local devices
    mapfile -t devices < <(lsblk -ndo NAME,TYPE | grep -E 'disk|part' | grep -vE 'nvme0n1|loop' | awk '{print "/dev/"$1}')

    if [ ${#devices[@]} -eq 0 ]; then
        warn "Nenhum dispositivo externo detectado"
        return 1
    fi

    success "Dispositivos detectados: ${devices[*]}"
    echo "${devices[@]}"
}

# Função para verificar se dispositivo está formatado
check_device_format() {
    local device="$1"
    local fs_type

    fs_type=$(sudo blkid -o value -s TYPE "$device" 2>/dev/null || echo "")

    if [ -z "$fs_type" ]; then
        warn "Dispositivo $device não está formatado"
        return 1
    fi

    success "Dispositivo $device formatado como $fs_type"
    echo "$fs_type"
}

# Função para montar dispositivo
mount_device() {
    local device="$1"
    local mount_point="$2"

    if mount | grep -q "$device"; then
        warn "Dispositivo $device já está montado"
        return 0
    fi

    sudo mkdir -p "$mount_point"
    if sudo mount "$device" "$mount_point"; then
        success "Dispositivo $device montado em $mount_point"
        return 0
    else
        error "Falha ao montar $device em $mount_point"
        return 1
    fi
}

# Função para configurar swap
setup_swap() {
    local mount_point="$1"
    local swap_size_gb="${2:-32}"  # Tamanho padrão 32GB
    local swap_file="${mount_point}/swap/swapfile"

    sudo mkdir -p "${mount_point}/swap"

    # Verifica se swapfile já existe
    if [ -f "$swap_file" ]; then
        warn "Swapfile já existe: $swap_file"
        return 0
    fi

    log "Criando swapfile de ${swap_size_gb}GB..."
    sudo dd if=/dev/zero of="$swap_file" bs=1G count="$swap_size_gb" status=progress
    sudo chmod 0600 "$swap_file"
    sudo mkswap "$swap_file"
    sudo swapon "$swap_file"

    success "Swap configurado: $swap_file"
}

# Função para configurar Dask spill
setup_dask_spill() {
    local mount_point="$1"
    local spill_dir="${mount_point}/dask_spill"

    sudo mkdir -p "$spill_dir"
    sudo chown -R "$USER:$USER" "$spill_dir"

    # Atualiza configuração Dask
    python3 -c "
import dask
dask.config.set({
    'temporary-directory': '$spill_dir',
    'distributed.worker.memory.spill': 0.8,
    'distributed.worker.memory.target': 0.6,
    'distributed.worker.memory.terminate': 0.95
})
print('Dask configurado para usar: $spill_dir')
"

    success "Dask spill configurado: $spill_dir"
}

# Função principal
main() {
    log "Iniciando detecção automática de armazenamento..."

    local devices
    devices=$(detect_external_devices)

    if [ $? -ne 0 ]; then
        exit 1
    fi

    for device in $devices; do
        log "Processando dispositivo: $device"

        # Verifica formato
        local fs_type
        fs_type=$(check_device_format "$device")

        if [ $? -ne 0 ]; then
            warn "Pulando dispositivo não formatado: $device"
            continue
        fi

        # Define ponto de montagem
        local mount_point="/mnt/external_$(basename "$device")"

        # Monta dispositivo
        if mount_device "$device" "$mount_point"; then
            # Configura swap
            setup_swap "$mount_point" 32

            # Configura Dask spill
            setup_dask_spill "$mount_point"

            # Adiciona ao fstab para montagem automática
            if ! grep -q "$device" /etc/fstab; then
                echo "$device $mount_point ext4 defaults 0 2" | sudo tee -a /etc/fstab
                success "Adicionado ao fstab para montagem automática"
            fi
        fi
    done

    # Verifica configuração final
    log "Verificando configuração final..."
    free -h
    df -h | grep -E "(external|mnt)"
    cat /proc/swaps

    success "Configuração automática de armazenamento concluída!"
}

# Executa função principal
main "$@"
