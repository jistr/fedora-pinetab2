Running Fedora on a PineTab2
============================

This repo is disk image build automation to produce a Fedora image
bootable on the PineTab2. The output is a .raw image file that you can
'dd' onto an SD card and boot up Fedora on your PineTab2.

WARNING: This repo content is proof-of-concept, it probably shouldn't
be used by anyone unfamiliar with disk image manipulation, and won't
be of much use to anyone unfamiliar with kernel cross-compilation. If
you just want to get your PineTab2 up and running with the least
amount of friction, you should probably be looking elsewhere :).

WARNING 2: The makefile uses losetup, mounts the image and some files
that it writes are owned by the root user on the BTRFS filesystem of
the disk image. This means the Makefile is making use of sudo in some
places. Read and understand it before using it.

NOTE: This repository is not affiliated with the Fedora Project, nor
with Pine64.


Accompanying blog post
----------------------

There is a comprehensive blog post about building a Fedora image for
the PineTab2 here:

https://www.jistr.com/blog/2023-11-27-fedora-on-pinetab2/

The blog post is probably the best way to get started, but if you just
want condensed info, continue with the readme.


Prerequisites
-------------

* You'll need a U-Boot on your PineTab2 that prioritizes booting an OS
  from an SD card. The build process creates 'extlinux.conf' to
  configure U-Boot behavior but expects the PineTab2 to already have
  U-Boot installed.

* You'll need to build or otherwise provide a Linux kernel which was
  built with the necessary patches for PineTab2. The Makefile here
  expects to be referred to a pre-built kernel, it won't build a
  kernel on its own.

* You'll need to download a Fedora .raw.xz aarch64 image. Gnome and
  KDE images were tried and seemed to work. E.g.

  https://download.fedoraproject.org/pub/fedora/linux/releases/39/Workstation/aarch64/images/Fedora-Workstation-39-1.5.aarch64.raw.xz

* Optional: I think it's a good idea to flash Megi's rk2aw into SPI
  flash before experimenting with custom distros.

  https://xnux.eu/rk2aw/


Building the image
------------------

Point to the source image and the kernel via exported environment variables:

    export SRC_DISK_IMAGE=~/downloads/Fedora-Workstation-39-1.5.aarch64.raw.xz

    export SRC_KERNEL_IMAGE=~/linux/arch/arm64/boot/Image
    export SRC_KERNEL_RELEASE=$(cat ~/linux/include/config/kernel.release)
    export SRC_KERNEL_DTBS=~/linux/tar-install/boot/dtbs/$SRC_KERNEL_RELEASE
    export SRC_KERNEL_MODULES=~/linux/tar-install/lib/modules/$SRC_KERNEL_RELEASE


Build the image:

    make all-pinetab2


Installing
----------

Flash the resulting 'out/image.raw' onto an SD card and boot your
PineTab2. Make sure that the bootloader you are using prefers booting
from the SD card (the one installed in eMMC when shipped does). You
can log in as 'pine' user with default password '1111'.
