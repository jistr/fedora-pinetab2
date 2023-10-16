IMAGE := out/image.raw

### VARIABLES ###

# SRC_IMAGE -- The source .raw.xz image to customize. Must be set for
# the 'image-init' target.

# SRC_KERNEL_BOOT_DIR -- The built aarch64 kernel boot directory. Must
# be set for 'install-kernel-*' targets. Usually looks like
# '<linux-repo>/arch/arm64/boot'.

# SRC_KERNEL_VERSION -- Kernel version string to differentiate between
# multiple kernels installed. Must be set for 'install-kernel-*'
# targets.


### E2E BUILD ###

PHONY += all-pinetab2
all-pinetab2: image-init image-mount install-kernel-pinetab2 image-ulosetup

PHONY += clean
clean: image-ulosetup
	rm -r ./mnt
	rm -r ./out

### IMAGE ###

PHONY += image-init
image-init: $(IMAGE)

$(IMAGE):
	test -n "$(SRC_IMAGE)" || { echo "ERROR: SRC_IMAGE is not set"; exit 1; }
	mkdir -p out
	cp $(SRC_IMAGE) $(IMAGE).xz
	unxz $(IMAGE).xz

PHONY += image-losetup
image-losetup:
	LOOPDEV=$$(losetup -a | grep out/image.raw | cut -d: -f1); \
	if [ -z "$$LOOPDEV" ]; then \
		sudo losetup -fP $(IMAGE); \
	fi

PHONY += image-ulosetup
image-ulosetup: image-umount
	LOOPDEV=$$(losetup -a | grep out/image.raw | cut -d: -f1); \
	if [ -n "$$LOOPDEV" ]; then \
		sudo losetup -d $$LOOPDEV; \
	fi

PHONY += image-mount
image-mount: image-losetup
	mkdir -p mnt/fatboot mnt/extboot mnt/btrfs

	LOOPDEV=$$(losetup -a | grep out/image.raw | cut -d: -f1); \
	mount | grep mnt/fatboot || sudo mount $${LOOPDEV}p1 -o uid=$$(id -u) -o gid=$$(id -g) mnt/fatboot; \
	mount | grep mnt/extboot || sudo mount $${LOOPDEV}p2 mnt/extboot; \
	mount | grep mnt/btrfs || sudo mount $${LOOPDEV}p3 mnt/btrfs

PHONY += image-mount
image-umount:
	mount | grep mnt/fatboot && { sudo umount mnt/fatboot || exit 1; } || true
	mount | grep mnt/extboot && { sudo umount mnt/extboot || exit 1; } || true
	mount | grep mnt/btrfs && { sudo umount mnt/btrfs || exit 1; } || true


### KERNEL AND RELATED ###

PHONY += prune-fatboot
prune-fatboot:
	rm -rf mnt/fatboot/EFI
	rm -rf mnt/fatboot/overlays
	rm -f mnt/fatboot/config.txt
	rm -f mnt/fatboot/*.dtb
	rm -f mnt/fatboot/*.bin
	rm -f mnt/fatboot/*.dat
	rm -f mnt/fatboot/*.elf

PHONY += install-kernel-pinetab2
install-kernel-pinetab2: prune-fatboot mnt/fatboot/linux-$(SRC_KERNEL_VERSION)/Image mnt/fatboot/linux-$(SRC_KERNEL_VERSION)/dtb/rockchip generate-extlinux-conf

# mkimage -A arm64 -O linux -T kernel -C gzip -a 0 -e 0 -n Linux -d vmlinux.gz uImage
mnt/fatboot/linux-$(SRC_KERNEL_VERSION)/Image: $(SRC_KERNEL_BOOT_DIR)/Image
	test -n "$(SRC_KERNEL_BOOT_DIR)" || { echo "ERROR: SRC_KERNEL_BOOT_DIR is not set"; exit 1; }
	test -n "$(SRC_KERNEL_VERSION)" || { echo "ERROR: SRC_KERNEL_VERSION is not set"; exit 1; }
	mkdir -p mnt/fatboot/linux-$(SRC_KERNEL_VERSION)
	install "$<" "$@"

PHONY += generate-extlinux-conf
generate-extlinux-conf: mnt/fatboot/generate-extlinux-conf.sh
	cd mnt/fatboot; ./generate-extlinux-conf.sh

mnt/fatboot/generate-extlinux-conf.sh: files/fatboot/generate-extlinux-conf.sh
	install "$<" "$@"

mnt/fatboot/linux-$(SRC_KERNEL_VERSION)/dtb/rockchip: $(SRC_KERNEL_BOOT_DIR)/Image
	if [ ! -e "$(SRC_KERNEL_BOOT_DIR)/dts/rockchip/rk3566-pinetab2-v2.0.dtb" ]; then \
		echo "ERROR: It seems dtbs were not built."; \
		exit 1; \
	fi

	mkdir -p "$@"
	cp -a "$(SRC_KERNEL_BOOT_DIR)/dts/rockchip/"*.dtb "$@/"
