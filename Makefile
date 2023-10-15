IMAGE := out/image.raw

### IMAGE ###

PHONY += image-init
image-init: $(IMAGE)

$(IMAGE):
	test -n "$(SRC_IMAGE)" || { echo "SRC_IMAGE is not set"; exit 1; }
	mkdir -p out
	cp $(SRC_IMAGE) $(IMAGE).xz
	unxz $(IMAGE).xz

PHONY += image-mount
image-mount:
	mkdir -p mnt/fatboot mnt/extboot mnt/btrfs

	LOOPDEV=$$(losetup -a | grep out/image.raw | cut -d: -f1); \
	if [ -z "$$LOOPDEV" ]; then \
		sudo losetup -fP $(IMAGE); \
	fi

	LOOPDEV=$$(losetup -a | grep out/image.raw | cut -d: -f1); \
	sudo mount $${LOOPDEV}p1 mnt/fatboot; \
	sudo mount $${LOOPDEV}p2 mnt/extboot; \
	sudo mount $${LOOPDEV}p3 mnt/btrfs

PHONY += image-mount
image-umount:
	sudo umount mnt/fatboot
	sudo umount mnt/extboot
	sudo umount mnt/root

	LOOPDEV=$$(losetup -a | grep out/image.raw | cut -d: -f1); \
	if [ -n "$$LOOPDEV" ]; then \
		sudo losetup -d $$LOOPDEV; \
	fi
