#!/bin/bash
set -euo pipefail

# This should be generic later, but for now let's hardcode it.

mkdir -p extlinux

cat > extlinux/extlinux.conf <<EOF
default l0
menu title PineTab2 menu
prompt 1
timeout 30

label l0
menu label Linux 6.6.0
linux /linux-6.6.0/Image
fdt /linux-6.6.0/dtb/rockchip/rk3566-pinetab2-v2.0.dtb
append earlycon=uart8250,mmio32,0xfe660000 console=ttyS2,1500000n8 root=/dev/mmcblk0p3 console=tty1 rootfstype=btrfs rw rootwait rootflags=subvol=root loglevel=15 mitigations=off

label l1
menu label Linux 6.6.0 (graphical)
linux /linux-6.6.0/Image
fdt /linux-6.6.0/dtb/rockchip/rk3566-pinetab2-v2.0.dtb
append earlycon=uart8250,mmio32,0xfe660000 console=ttyS2,1500000n8 root=/dev/mmcblk0p3 rootfstype=btrfs rw rootwait rootflags=subvol=root quiet rhgb plymouth.ignore-serial-consoles mitigations=off
EOF
