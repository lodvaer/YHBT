.PHONY : apps clean cleanapps initramfs
all : initramfs MBR

MBR :
	fasm -s kern.fas loaders/MBR.asm kern

COMBOOT :
	fasm -s kern.fas loaders/COMBOOT.asm /var/tftp/YHBT.cbt

clean :
	rm -f kern kern.fas /tmp/hda
	for d in ./initramfs/src/*; do \
		$(MAKE) clean --directory=$$d; \
	done

q : MBR
	qemu-img create /tmp/hda 50M >/dev/null
	dd if=kern of=/tmp/hda conv=notrunc 2>&1 >/dev/null
	qemu-system-x86_64 -no-reboot -monitor stdio -hda /tmp/hda
	rm -f kern /tmp/hda
b : initramfs MBR
	yes yes|bximage -q -hd -mode=flat -size=50 /tmp/hda
	dd if=kern of=/tmp/hda conv=notrunc 2>&1 >/dev/null
	bochs -q -f ./.bochsrc
	rm -f kern /tmp/hda

initramfs :
	for d in ./initramfs/src/*; do \
		$(MAKE) --directory=$$d; \
	done

