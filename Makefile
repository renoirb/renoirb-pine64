

IMAGE_NAME:=xenial-pine64-bspkernel-20161218-1.img.xz
IMAGE_HREF:=https://www.stdin.xyz/downloads/people/longsleep/pine64-images/ubuntu/


packages/${IMAGE_NAME}: packages
	curl -s -S -L ${IMAGE_HREF}${IMAGE_NAME} -o packages/${IMAGE_NAME}


packages:
	@mkdir -p packages


.PHONY: help
help:
	@curl -s -S -L ${IMAGE_HREF}README.txt
	@echo "\nSee also:\n  - http://linux-sunxi.org/UEnv.txt\n  - http://www.denx.de/wiki/view/DULG/UBootEnvVariables\n  - https://github.com/longsleep/build-pine64-image\n\n"
	@diskutil list
	@echo "\n\nThen craft the following command yourself, plz:\n    xzcat packages/${IMAGE_NAME}|pv|sudo dd bs=1m of=...\n\n----"
	@echo "\nOnce done, also copy:\n    cp scripts/*sh /Volumes/BOOT\n\n----"
	@echo "\nOn the new node, initialize like so:\n    cd /boot ; sudo -HE bash -l"
	@echo "    # Imagine it is node2, we expect private IP to be 242\n    NODE_NUMBER=2 NODE_FIRST_POS=240 bash virtual_interface_network.sh"
	@echo "    # Finish up personalizing image\n    bash initialize.sh"

