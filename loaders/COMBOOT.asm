include "include/boot.h"
org 100h
COMBOOT:
	cli

	in al, 092h
	or al, 2	; Enable A20
	out 092h, al

	mov ax, 0Ch
	xor dx, dx	; Disable SYSLINUX
	int 22h

	mov ax, KERN_SEG
	mov es, ax

	mov si, .OS
	mov di, KERN_ORIG

	xor cx, cx
.loop:
	mov al, [ds:si]
	mov [es:di], al	; Copy kernel to the correct location
	inc si
	inc di
	inc cx
	cmp cx, _END - _START
	jle .loop
	
	mov ax, KERN_SEG
	mov ds, ax

	jmp KERN_SEG:KERN_ORIG
.OS:
include "../OS.asm"

; vim: ts=8 sw=8 syn=fasm
