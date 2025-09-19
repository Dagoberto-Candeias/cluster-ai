#!/bin/bash

echo "=== DIAGNÓSTICO COMPLETO DO SSD EXTERNO ==="
echo "Data: $(date)"
echo ""

echo "1. VERIFICANDO DISCOS CONECTADOS:"
echo "----------------------------------"
lsblk -f
echo ""

echo "2. VERIFICANDO DISPOSITIVOS USB:"
echo "--------------------------------"
lsusb
echo ""

echo "3. VERIFICANDO MÓDULOS USB CARREGADOS:"
echo "---------------------------------------"
lsmod | grep usb
echo ""

echo "4. VERIFICANDO LOGS DO SISTEMA (últimas 100 linhas):"
echo "---------------------------------------------------"
sudo dmesg | tail -100 | grep -i usb || echo "Nenhuma mensagem USB recente encontrada"
echo ""

echo "5. VERIFICANDO STATUS DO UDEV:"
echo "------------------------------"
sudo udevadm monitor --udev --subsystem-match=block --property 2>/dev/null &
sleep 2
kill %1 2>/dev/null || true
echo ""

echo "6. TESTANDO PORTAS USB (INSIRA O SSD AGORA):"
echo "---------------------------------------------"
echo "Por favor, conecte o SSD externo agora..."
echo "Monitorando por 30 segundos..."
timeout 30 sudo udevadm monitor --udev --subsystem-match=block || echo "Timeout - nenhum dispositivo detectado"
echo ""

echo "7. VERIFICANDO SUPORTE A FILESYSTEMS:"
echo "-------------------------------------"
lsmod | grep -E "(ext4|ntfs|vfat|exfat|btrfs|xfs)" || echo "Verifique se os módulos de filesystem estão carregados"
echo ""

echo "8. VERIFICANDO USB-CORE STATUS:"
echo "-------------------------------"
cat /sys/module/usbcore/parameters/* 2>/dev/null || echo "Parâmetros do usbcore não disponíveis"
echo ""

echo "=== FIM DO DIAGNÓSTICO ==="
echo ""
echo "PRÓXIMOS PASSOS RECOMENDADOS:"
echo "1. Verifique se o SSD está ligado e tem energia"
echo "2. Teste o SSD em outra porta USB"
echo "3. Teste o SSD em outro computador"
echo "4. Verifique se o cabo USB está funcionando"
echo "5. Execute: sudo apt update && sudo apt install usbutils"
echo "6. Se persistir, pode ser problema de hardware do SSD ou porta USB"
