IMAGE := out/image.raw

### VARIABLES ###

# SRC_DISK_IMAGE -- The source .raw.xz image to customize. Must be set for
# the 'image-init' target.

# SRC_KERNEL_IMAGE -- The built aarch64 kernel image. Usually looks
# like '<linux-repo>/arch/arm64/boot/Image'.

# SRC_KERNEL_DTBS -- The built kernel device trees. Usually looks like
# '<linux-repo>/tar-install/boot/dtbs/<kernel-version>'.

# SRC_KERNEL_MODULES -- The built aarch64 kernel image. Usually looks
# like '<linux-repo>/tar-install/lib/modules/<kernel-version>'.

# SRC_KERNEL_RELEASE -- The release string for the kernel. Usually
# is the content of the file '<linux-repo>/include/config/kernel.release'.

### E2E BUILD ###

PHONY += all-pinetab2
all-pinetab2: image-init image-mount install-kernel-pinetab2 install-first-boot-pinetab2 image-ulosetup

PHONY += clean
clean: image-ulosetup
	rmdir ./mnt/fatboot
	rmdir ./mnt/extboot
	rmdir ./mnt/btrfs
	rmdir ./mnt
	rm -r ./out

### IMAGE ###

PHONY += image-init
image-init: $(IMAGE)

$(IMAGE):
	test -n "$(SRC_DISK_IMAGE)" || { echo "ERROR: SRC_DISK_IMAGE is not set"; exit 1; }
	mkdir -p out
	cp $(SRC_DISK_IMAGE) $(IMAGE).xz
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
install-kernel-pinetab2: prune-fatboot mnt/fatboot/linux-$(SRC_KERNEL_RELEASE)/Image mnt/fatboot/linux-$(SRC_KERNEL_RELEASE)/dtbs/rockchip mnt/btrfs/root/lib/modules/$(SRC_KERNEL_RELEASE) generate-extlinux-conf

mnt/fatboot/linux-$(SRC_KERNEL_RELEASE)/Image: $(SRC_KERNEL_IMAGE)
	test -n "$(SRC_KERNEL_IMAGE)" || { echo "ERROR: SRC_KERNEL_IMAGE is not set"; exit 1; }
	test -n "$(SRC_KERNEL_RELEASE)" || { echo "ERROR: SRC_KERNEL_RELEASE is not set"; exit 1; }
	echo "Kernel version: '$(SRC_KERNEL_RELEASE)' at $(SRC_KERNEL_IMAGE)"
	mkdir -p mnt/fatboot/linux-$(SRC_KERNEL_RELEASE)
	install "$<" "$@"

PHONY += generate-extlinux-conf
generate-extlinux-conf: mnt/fatboot/generate-extlinux-conf.sh
	cd mnt/fatboot; ./generate-extlinux-conf.sh

mnt/fatboot/generate-extlinux-conf.sh: files/fatboot/generate-extlinux-conf.sh
	install "$<" "$@"

mnt/fatboot/linux-$(SRC_KERNEL_RELEASE)/dtbs/rockchip: $(SRC_KERNEL_IMAGE)
	test -n "$(SRC_KERNEL_DTBS)" || { echo "ERROR: SRC_KERNEL_DTBS is not set"; exit 1; }
	test -n "$(SRC_KERNEL_RELEASE)" || { echo "ERROR: SRC_KERNEL_RELEASE is not set"; exit 1; }
	if [ ! -e "$(SRC_KERNEL_DTBS)/rockchip/rk3566-pinetab2-v2.0.dtb" ]; then \
		echo "ERROR: It seems dtbs were not built."; \
		exit 1; \
	fi

	mkdir -p "$@"
	cp -a "$(SRC_KERNEL_DTBS)/rockchip/"*.dtb "$@/"

mnt/btrfs/root/lib/modules/$(SRC_KERNEL_RELEASE): $(SRC_KERNEL_IMAGE)
	test -n "$(SRC_KERNEL_MODULES)" || { echo "ERROR: SRC_KERNEL_MODULES is not set"; exit 1; }
	test -n "$(SRC_KERNEL_RELEASE)" || { echo "ERROR: SRC_KERNEL_RELEASE is not set"; exit 1; }
	sudo cp -aT "$(SRC_KERNEL_MODULES)" "$@"
	sudo chown root:root "$@"


### FIRST BOOT ###

PHONY += install-first-boot-pinetab2
install-first-boot-pinetab2: mnt/btrfs/root/usr/local/sbin/pine-first-boot mnt/btrfs/root/etc/systemd/system/pine-first-boot.service mnt/btrfs/root/etc/systemd/system/multi-user.target.wants/pine-first-boot.service

mnt/btrfs/root/usr/local/sbin/pine-first-boot: files/btrfs/root/usr/local/sbin/pine-first-boot
	sudo install -m 0700 "$<" "$@"

mnt/btrfs/root/etc/systemd/system/pine-first-boot.service: files/btrfs/root/etc/systemd/system/pine-first-boot.service
	sudo install -m 0644 "$<" "$@"

mnt/btrfs/root/etc/systemd/system/multi-user.target.wants/pine-first-boot.service:
	sudo ln -sf /etc/systemd/system/pine-first-boot.service "$@"
