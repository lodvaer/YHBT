.PHONY : apps clean cleanapps
all : MBR

MBR :
	fasm -s kern.fas loaders/MBR.asm kern
clean :
	rm -f kern /tmp/hda

q : MBR
	qemu-img create /tmp/hda 50M >/dev/null
	dd if=kern of=/tmp/hda conv=notrunc 2>&1 >/dev/null
	qemu-system-x86_64 -monitor stdio -hda /tmp/hda
	rm -f kern /tmp/hda
b : MBR
	yes yes|bximage -q -hd -mode=flat -size=50 /tmp/hda
	dd if=kern of=/tmp/hda conv=notrunc 2>&1 >/dev/null
	bochs -q -f ./.bochsrc
	rm -f kern /tmp/hda
