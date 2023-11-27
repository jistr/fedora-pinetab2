#!/bin/bash
set -euo pipefail

mkdir -p extlinux

KERNELS=$(ls -dv linux-* | tac)
NEWEST_KERNEL=$(ls -dv linux-* | tail -n1)

cat > extlinux/extlinux.conf <<EOF
default $NEWEST_KERNEL
menu title PineTab2 menu
prompt 1
timeout 30
EOF

for KERNEL in $KERNELS; do

cat >> extlinux/extlinux.conf <<EOF

label $KERNEL
menu label $KERNEL
linux /$KERNEL/Image
fdt /$KERNEL/dtbs/rockchip/rk3566-pinetab2-v2.0.dtb
append earlycon=uart8250,mmio32,0xfe660000 console=ttyS2,1500000n8 root=/dev/mmcblk0p3 console=tty1 rootfstype=btrfs rw rootwait rootflags=subvol=root loglevel=15 mitigations=off
EOF

done
