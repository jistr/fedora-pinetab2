Running Fedora on a PineTab 2
=============================

WARNING: This repo content is proof-of-concept, it probably shouldn't
be used by anyone unfamiliar with disk image manipulation, and won't
be of much use to anyone unfamiliar with kernel cross-compilation. If
you just want to get your PineTab 2 up and running with the least
amount of friction, you should be looking elsewhere :).

The output of the repo scripts is a .raw image file that you can 'dd'
onto a SD card and boot up Fedora on your PineTab 2.

Prerequisites
-------------

* You'll need a uboot bootloader on your PineTab 2. The image just
  configures '/boot/config.txt' to configure uboot behavior.

* I think it's a good idea to flash Megi's rk2aw into SPI before
  experimenting with custom distros.

  https://xnux.eu/rk2aw/
  https://xff.cz/kernels/rk2aw/rk2aw-rk3566-pinetab2/

* You'll need to build a Linux kernel for the PineTab 2. The scripts
  here expect to be referred to a pre-built kernel, they won't build
  one automatically.

  PineTab 2 patches for Linux 6.6 are at:

  https://megous.com/git/linux/log/?h=pt2-6.6
  https://xff.cz/kernels/6.6/patches/

* You'll need to download a Fedora .raw.xz image and refer to it.

  https://download.fedoraproject.org/pub/fedora/linux/releases/39/Workstation/aarch64/images/Fedora-Workstation-39-1.5.aarch64.raw.xz

Building the image
------------------

Point to the source image and the kernel. Note that the kernel must
already be patched with the pt2 patches and (cross-)compiled.

    export SRC_IMAGE=~/tmp/Fedora-Workstation-39-20231016.n.0.aarch64.raw.xz
    export SRC_KERNEL_BOOT_DIR=/var/home/jistr/proj/contrib/linux/arch/arm64/boot

Build the image:

    make all-pinetab2

Installing
----------

Flash the resulting 'out/image.raw' onto an SD card and boot your
PineTab 2. Make sure that the bootloader you are using prefers booting
from the SD card (the one installed in eMMC when shipped does).
